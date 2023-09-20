@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Flight Travel Item'
define view entity Z09_I_TRAVELITEM
  as select from z09_tritem
  association to parent Z09_I_TRAVEL as _Travel
    on $projection.TrGuid = _Travel.Trguid
{
  key itguid         as Itguid,
      agencynum      as AgencyID,
      travelid       as TravelId,
      tritemno       as ItemID,
      trguid         as TrGuid,
      carrid         as CarrierId,
      connid         as ConnectionId,
      fldate         as FlightDate,
      bookid         as BookingId,
      class          as FlightClass,
      passname       as PassengerName,
      @Semantics.systemDateTime.createdAt: true
      created_at     as CreatedAt,
      @Semantics.user.createdBy: true
      created_by     as CreatedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      changed_at     as ChangedAt,
      @Semantics.user.lastChangedBy: true
      changed_by     as ChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      loc_changed_at as LocalChangedAt,
      _Travel
}
