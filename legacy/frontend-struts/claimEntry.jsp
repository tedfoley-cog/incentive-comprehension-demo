<%@ taglib uri="http://struts.apache.org/tags-html" prefix="html" %>
<%@ taglib uri="http://struts.apache.org/tags-bean" prefix="bean" %>
<%--
  claimEntry.jsp - LEGACY DEALER CLAIM-ENTRY SCREEN (STRUTS HTML TAGS)

  Submits to /claimEntry.do (ClaimEntryAction). Rendered inside the
  dealer portal frameset. Field labels come from the MessageResources
  bundle. The screen is being rebuilt as a React component against the
  new REST API during the reimagining.
--%>
<html:html locale="true">
<head><title><bean:message key="claim.entry.title"/></title></head>
<body>
  <html:form action="/claimEntry">
    <table>
      <tr>
        <td><bean:message key="claim.id"/></td>
        <td><html:text property="claimId" maxlength="10"/></td>
      </tr>
      <tr>
        <td><bean:message key="claim.vin"/></td>
        <td><html:text property="vin" maxlength="17"/></td>
      </tr>
      <tr>
        <td><bean:message key="claim.dealerId"/></td>
        <td><html:text property="dealerId" maxlength="6"/></td>
      </tr>
      <tr>
        <td><bean:message key="claim.programId"/></td>
        <td><html:text property="programId" maxlength="6"/></td>
      </tr>
      <tr>
        <td><bean:message key="claim.salePrice"/></td>
        <td><html:text property="salePrice"/></td>
      </tr>
    </table>
    <html:submit><bean:message key="button.submit"/></html:submit>
  </html:form>
</body>
</html:html>
