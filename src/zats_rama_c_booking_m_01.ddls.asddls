@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Processor projection entity'
@Metadata.ignorePropagatedAnnotations: false //// 'FALSE' All the annocations from child the child entity automatically fetch.
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
define view entity ZATS_RAMA_C_BOOKING_M_01
  as projection on ZATS_RAMA_BOOKING_M_01
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
      _BookingSuppl : redirected to composition child ZATS_RAMA_C_BOOKNGSUPPL_M_01,
      _Carrier,
      _Connection,
      _Customer,
      _Travel       : redirected to parent ZATS_RAMA_C_TRAVEL_M_01
}
