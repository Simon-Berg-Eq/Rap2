@EndUserText.label: 'projection view'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@Metadata.allowExtensions: true
@Search.searchable: true
define root view entity Z09_C_Travel2
  as projection on Z09_I_TRAVEL
{
  key Trguid,
      @Search.defaultSearchElement: true
      AgencyID,
      TravelID,
      TravelDescription,
      @Search.defaultSearchElement: true
      @Consumption.valueHelpDefinition: [{
      entity: {
      name: 'D437_I_Customer',
      element: 'Customer'
      }
      }]
      CustomerID,
      StartDate,
      EndDate,
      Status,
      ChangedAt,
      _TravelItem : redirected to composition child Z09_C_TRAVELITEM,
      localChangedAt,
      ChangedBy
}
