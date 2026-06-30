package com.oem.incentive.web;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.sql.DataSource;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.Types;

import org.apache.struts.action.Action;
import org.apache.struts.action.ActionForm;
import org.apache.struts.action.ActionForward;
import org.apache.struts.action.ActionMapping;

/**
 * ClaimEntryAction - LEGACY STRUTS 1.x ACTION FOR ONLINE CLAIM ENTRY.
 *
 * Persists the claim, then calls the DB2 stored procedure SP_ELIGIBILITY
 * to give the dealer immediate eligibility feedback. The same reason
 * codes (OK / DLRE / DLRI / PRGW / RGNX) flow back from both this online
 * path and the nightly batch (INCMAIN), but the two implementations have
 * drifted - see the note in SP_ELIGIBILITY.sql.
 *
 * This class is part of the Struts estate being migrated to Spring MVC.
 */
public class ClaimEntryAction extends Action {

    private DataSource dataSource;

    @Override
    public ActionForward execute(ActionMapping mapping, ActionForm form,
            HttpServletRequest request, HttpServletResponse response)
            throws Exception {

        ClaimForm cf = (ClaimForm) form;
        String reason;
        String eligible;

        try (Connection con = dataSource.getConnection();
             CallableStatement cs = con.prepareCall(
                 "CALL SP_ELIGIBILITY(?, ?, ?)")) {

            cs.setString(1, cf.getClaimId());
            cs.registerOutParameter(2, Types.CHAR);
            cs.registerOutParameter(3, Types.CHAR);
            cs.execute();

            reason = cs.getString(2).trim();
            eligible = cs.getString(3).trim();
        } catch (Exception e) {
            request.setAttribute("error", e.getMessage());
            return mapping.findForward("failure");
        }

        request.setAttribute("reasonCode", reason);
        if ("Y".equals(eligible)) {
            return mapping.findForward("eligible");
        }
        return mapping.findForward("ineligible");
    }

    public void setDataSource(DataSource dataSource) {
        this.dataSource = dataSource;
    }
}
