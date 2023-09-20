@EndUserText.label: 'Travel Agency Projection'
@AccessControl.authorizationCheck: #CHECK

@Metadata.allowExtensions: true

@Search.searchable: true
define root view entity Z09_C_AGENCY
  as projection on Z09_I_AGENCY
{
  key AgencyID,
      @Search.defaultSearchElement: true
      Name,
      Street,
      Postbox,
      ZIPCode,
      City,
      Country,
      Region,
      Telephone,
      Url,
      Language,
      CurrencyCode
}
