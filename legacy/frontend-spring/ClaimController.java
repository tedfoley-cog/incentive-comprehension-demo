package com.oem.incentive.web;

import java.sql.CallableStatement;
import java.sql.Types;

import javax.sql.DataSource;

import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.ModelAttribute;

/**
 * ClaimController - SPRING MVC PORT OF ClaimEntryAction (IN PROGRESS).
 *
 * This is the half-finished migration of the Struts claim-entry action to
 * Spring MVC. It preserves the call to SP_ELIGIBILITY so online behaviour
 * is unchanged during the lift. It does NOT yet cover the reject screen's
 * exception handling, so the two stacks are not yet at parity - a gap the
 * comprehension pass should record before the platform is reimagined as a
 * REST API + React front end.
 */
@Controller
public class ClaimController {

    private final DataSource dataSource;

    public ClaimController(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @PostMapping("/claims")
    public String submitClaim(@ModelAttribute ClaimDto claim, Model model) {
        try (var con = dataSource.getConnection();
             CallableStatement cs = con.prepareCall(
                 "CALL SP_ELIGIBILITY(?, ?, ?)")) {

            cs.setString(1, claim.getClaimId());
            cs.registerOutParameter(2, Types.CHAR);
            cs.registerOutParameter(3, Types.CHAR);
            cs.execute();

            String reason = cs.getString(2).trim();
            String eligible = cs.getString(3).trim();
            model.addAttribute("reasonCode", reason);
            return "Y".equals(eligible) ? "claimConfirm" : "claimReject";
        } catch (Exception e) {
            model.addAttribute("error", e.getMessage());
            return "error";
        }
    }
}
