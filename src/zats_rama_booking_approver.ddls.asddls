@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Approver Processor projection entity'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
define view entity ZATS_RAMA_BOOKING_APPROVER as projection on ZATS_RAMA_BOOKING_M_01
{
    key TravelId,
    key BookingId,
    BookingDate,
    CustomerId,
    CarrierId,
    ConnectionId,
    FlightDate,
    FlightPrice,
    CurrencyCode,
    BookingStatus,
    LastChangedAt,
    /* Associations */
    _BookingStatus,
    _Carrier,
    _Connection,
    _Customer,
    _Travel: redirected to parent ZATS_RAMA_TRAVEL_APPROVER
}
