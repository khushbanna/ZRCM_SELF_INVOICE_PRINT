@EndUserText.label: 'TMG for tax code'
@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
define view entity ZI_TmgForTaxCode
  as select from ZTAX_CODE_NEW
  association to parent ZI_TmgForTaxCode_S as _TmgForTaxCodeAll on $projection.SingletonID = _TmgForTaxCodeAll.SingletonID
{
  key TAXCODE as Taxcode,
  key TRANSACTIONKEY as Transactionkey,
  key CONDITION_TYPE as ConditionType,
  TAXCODEDESCRIPTION as Taxcodedescription,
  GSTRATE as Gstrate,
  @Consumption.hidden: true
  1 as SingletonID,
  _TmgForTaxCodeAll
}
