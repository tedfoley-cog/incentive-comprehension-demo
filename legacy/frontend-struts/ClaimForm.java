package com.oem.incentive.web;

import javax.servlet.http.HttpServletRequest;

import org.apache.struts.action.ActionErrors;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionMapping;
import org.apache.struts.action.ActionMessage;

/**
 * ClaimForm - STRUTS FORM BEAN BACKING THE CLAIM-ENTRY SCREEN.
 *
 * Field-level validation here partially overlaps the COBOL edit program
 * INCEDIT.cbl (non-blank claim id / vin, positive sale price). The
 * server-side batch remains the system of record, so these rules are a
 * convenience copy - another duplication for comprehension to flag.
 */
public class ClaimForm extends ActionForm {

    private String claimId;
    private String vin;
    private String dealerId;
    private String programId;
    private String saleDate;
    private String salePrice;
    private String claimType;

    @Override
    public ActionErrors validate(ActionMapping mapping,
            HttpServletRequest request) {
        ActionErrors errors = new ActionErrors();
        if (isBlank(claimId)) {
            errors.add("claimId", new ActionMessage("error.claimId.required"));
        }
        if (vin == null || vin.trim().length() != 17) {
            errors.add("vin", new ActionMessage("error.vin.length"));
        }
        if (isBlank(salePrice)) {
            errors.add("salePrice",
                new ActionMessage("error.salePrice.required"));
        }
        return errors;
    }

    private boolean isBlank(String s) {
        return s == null || s.trim().isEmpty();
    }

    public String getClaimId() { return claimId; }
    public void setClaimId(String v) { this.claimId = v; }
    public String getVin() { return vin; }
    public void setVin(String v) { this.vin = v; }
    public String getDealerId() { return dealerId; }
    public void setDealerId(String v) { this.dealerId = v; }
    public String getProgramId() { return programId; }
    public void setProgramId(String v) { this.programId = v; }
    public String getSaleDate() { return saleDate; }
    public void setSaleDate(String v) { this.saleDate = v; }
    public String getSalePrice() { return salePrice; }
    public void setSalePrice(String v) { this.salePrice = v; }
    public String getClaimType() { return claimType; }
    public void setClaimType(String v) { this.claimType = v; }
}
