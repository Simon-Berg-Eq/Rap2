@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Travel Agency'
define root view entity Z09_I_AGENCY
  as select from stravelag
{
  key agencynum as AgencyID,
      name      as Name,
      street    as Street,
      postbox   as Postbox,
      postcode  as ZIPCode,
      city      as City,
      country   as Country,
      region    as Region,
      telephone as Telephone,
      url       as Url,
      langu     as Language,
      currency  as CurrencyCode
}
