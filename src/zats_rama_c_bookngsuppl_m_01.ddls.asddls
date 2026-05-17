@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Supplement processor projection entity'
@Metadata.ignorePropagatedAnnotations: false //// 'FALSE' All the annocations from child the child entity automatically fetch.
@VDM.viewType: #CONSUMPTION
define view entity ZATS_RAMA_C_BOOKNGSUPPL_M_01
  as projection on ZATS_RAMA_BOOKNGSUPPL_M_01
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      SupplementId,
      Price,
      CurrencyCode,
      LastChangedAt,

      /* Associations */
      _Booking : redirected to parent ZATS_RAMA_C_BOOKING_M_01,
      _Supplement,
      _SupplementText,
      _Travel  : redirected to ZATS_RAMA_C_TRAVEL_M_01
}
