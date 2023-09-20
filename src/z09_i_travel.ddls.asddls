@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: 'Flight Travel'
define root view entity Z09_I_TRAVEL
  as select from z09_travel
  composition[0..*] of Z09_I_TRAVELITEM as _TravelItem
{
  key trguid     as Trguid,
      agencynum  as AgencyID,
      travelid   as TravelID,
      trdesc     as TravelDescription,
      customid   as CustomerID,
      stdat      as StartDate,
      enddat     as EndDate,
      status     as Status,
      @Semantics.systemDateTime.lastChangedAt: true
      changed_at as ChangedAt,
      @Semantics.user.lastChangedBy: true
      changed_by as ChangedBy,
      //      _association_name // Make association public
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      loc_changed_at as localChangedAt,
      _TravelItem
}

    
