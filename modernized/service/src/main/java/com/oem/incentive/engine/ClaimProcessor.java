package com.oem.incentive.engine;

import com.oem.incentive.data.ReferenceDataStore;
import com.oem.incentive.domain.ClaimType;
import com.oem.incentive.domain.IncentiveConstants;
import com.oem.incentive.domain.ReasonCode;
import com.oem.incentive.model.ClaimRequest;
import com.oem.incentive.model.DealerRef;
import com.oem.incentive.model.PayoutResponse;
import com.oem.incentive.model.ProgramRef;

import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Set;

/**
 * Orchestrates the full eligibility + pricing decision for a single claim.
 *
 * Pipeline mirrors the legacy INCMAIN paragraph flow:
 *   structural edit -> reversal branch -> duplicate screen ->
 *   dealer/program eligibility -> pricing -> payout method
 *
 * Duplicate detection is stateful within a processing session (same as
 * the COBOL WS-PAID-TABLE scoped to one batch run).
 */
@Service
public class ClaimProcessor {

    private static final BigDecimal ONE_HUNDRED = new BigDecimal("100");
    private static final String DEFAULT_METHOD = "CREDIT";
    private static final String DEFAULT_PAYEE = "D";

    private final ReferenceDataStore refData;
    private final Set<String> paidKeys =
            Collections.synchronizedSet(new LinkedHashSet<>());

    public ClaimProcessor(ReferenceDataStore refData) {
        this.refData = refData;
    }

    public PayoutResponse process(ClaimRequest claim) {
        String method = DEFAULT_METHOD;
        String payeeType = DEFAULT_PAYEE;
        BigDecimal amount = BigDecimal.ZERO;

        // 1. Structural validation (INCEDIT)
        ReasonCode editResult = validateStructure(claim);
        if (editResult != ReasonCode.OK) {
            return respond(claim, "REJ ", method, payeeType, editResult, amount);
        }

        // 2. Reversal path (INCREV) -- separate from forward path
        ClaimType type = ClaimType.fromLegacy(claim.claimType());
        if (type == ClaimType.REVERSAL) {
            return handleReversal(claim, method, payeeType);
        }

        // 3. Duplicate screen (INCEXC)
        String dupKey = dupKey(claim);
        if (paidKeys.contains(dupKey)) {
            return respond(claim, "HOLD", method, payeeType, ReasonCode.DUP, amount);
        }

        // 4. Dealer eligibility (INCVAL evaluate)
        DealerRef dealer = refData.findDealer(claim.dealerId());
        if (dealer == null) {
            return respond(claim, "HOLD", method, payeeType, ReasonCode.DLRN, amount);
        }
        if (!dealer.enrolled()) {
            return respond(claim, "HOLD", method, payeeType, ReasonCode.DLRE, amount);
        }
        if (dealer.status() == 'I') {
            return respond(claim, "HOLD", method, payeeType, ReasonCode.DLRI, amount);
        }

        // 5. Program lookup
        ProgramRef program = refData.findProgram(claim.programId());
        if (program == null) {
            return respond(claim, "HOLD", method, payeeType, ReasonCode.PRGN, amount);
        }

        // 6. Program eligibility (INCELIG)
        ReasonCode eligResult = checkEligibility(claim, program, dealer);
        if (eligResult != ReasonCode.OK) {
            return respond(claim, "HOLD", method, payeeType, eligResult, amount);
        }

        // 7. Pricing (INCCALC)
        amount = computeAmount(claim, program);

        // 8. Payout method (INCPAY)
        if (program.payee() == 'C') {
            payeeType = "C";
            method = claim.custBank() ? "ACH   " : "CHECK ";
        }

        // 9. Remember as paid (7300-REMEMBER-PAID then bump count)
        paidKeys.add(dupKey);

        return respond(claim, "PAID", method, payeeType, ReasonCode.OK, amount);
    }

    /** Clear the paid-key set between batches. */
    public void resetState() {
        paidKeys.clear();
    }

    // ---- structural validation (mirrors INCEDIT) ----

    private ReasonCode validateStructure(ClaimRequest claim) {
        if (isBlank(claim.claimId())) return ReasonCode.EDIT;
        if (isBlank(claim.vin()))     return ReasonCode.EDIT;
        if (claim.saleDate() == 0)    return ReasonCode.EDIT;
        if (claim.salePrice().compareTo(BigDecimal.ZERO) <= 0) {
            return ReasonCode.EDIT;
        }
        if (ClaimType.fromLegacy(claim.claimType()) == null) {
            return ReasonCode.EDIT;
        }
        int month = (claim.saleDate() / 100) % 100;
        int day   = claim.saleDate() % 100;
        if (month < 1 || month > 12 || day < 1 || day > 31) {
            return ReasonCode.EDIT;
        }
        return ReasonCode.OK;
    }

    // ---- eligibility (mirrors INCELIG) ----

    private ReasonCode checkEligibility(ClaimRequest claim,
                                        ProgramRef program,
                                        DealerRef dealer) {
        // 1000-CHECK-WINDOW
        if (claim.saleDate() < program.startDate()
                || claim.saleDate() > program.endDate()) {
            return ReasonCode.PRGW;
        }
        // 2000-CHECK-REGION
        if (!"ALL".equals(program.region())
                && !program.region().equals(dealer.region())) {
            return ReasonCode.RGNX;
        }
        // 3000-CHECK-LOYALTY (resolves the online/batch drift)
        if (program.reqPriorOwn() && !claim.priorOwn()) {
            return ReasonCode.LOYX;
        }
        return ReasonCode.OK;
    }

    // ---- pricing (mirrors INCCALC) ----

    private BigDecimal computeAmount(ClaimRequest claim, ProgramRef program) {
        BigDecimal gross;

        // 1000-COMPUTE-BASE
        if ("PCT".equals(program.type())) {
            gross = claim.salePrice()
                    .multiply(program.pctRate())
                    .divide(ONE_HUNDRED, 2, RoundingMode.HALF_UP);
        } else {
            gross = program.flatAmount();
        }

        // 2000-APPLY-LOYALTY
        ClaimType type = ClaimType.fromLegacy(claim.claimType());
        if (type == ClaimType.LOYALTY && program.stackable()) {
            gross = gross.add(IncentiveConstants.LOYALTY_BONUS);
        }

        // 3000-APPLY-CAPS
        if (gross.compareTo(program.maxIncentive()) > 0) {
            gross = program.maxIncentive();
        }
        if (gross.compareTo(IncentiveConstants.GLOBAL_PAYOUT_CAP) > 0) {
            gross = IncentiveConstants.GLOBAL_PAYOUT_CAP;
        }

        return gross;
    }

    // ---- reversal (mirrors INCREV) ----

    private PayoutResponse handleReversal(ClaimRequest claim,
                                          String method,
                                          String payeeType) {
        ProgramRef program = refData.findProgram(claim.programId());
        if (program == null) {
            return respond(claim, "HOLD", method, payeeType,
                    ReasonCode.PRGN, BigDecimal.ZERO);
        }
        // Force type to RETAIL before re-pricing (Policy 7.1: loyalty
        // bonus is not clawed back).
        ClaimRequest asRetail = new ClaimRequest(
                claim.claimId(), claim.vin(), claim.dealerId(),
                claim.programId(), claim.saleDate(), claim.salePrice(),
                "RETAIL", claim.priorOwn(), claim.custBank());
        BigDecimal amount = computeAmount(asRetail, program).negate();
        return respond(claim, "RVSD", method, payeeType,
                ReasonCode.OK, amount);
    }

    // ---- helpers ----

    private String dupKey(ClaimRequest claim) {
        return claim.vin() + claim.programId();
    }

    private PayoutResponse respond(ClaimRequest claim, String status,
                                   String method, String payeeType,
                                   ReasonCode reason, BigDecimal amount) {
        return new PayoutResponse(
                claim.claimId(), claim.vin(), claim.dealerId(),
                claim.programId(), status, method, payeeType,
                reason.legacyCode(), amount);
    }

    private boolean isBlank(String s) {
        return s == null || s.isBlank();
    }
}
