@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for root travel entity'
@Metadata.ignorePropagatedAnnotations: false //// 'FALSE' All the annocations from child the child entity automatically fetch.
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
define root view entity ZATS_RAMA_C_TRAVEL_M_01
  provider contract transactional_query
  as projection on ZATS_RAMA_R_TRAVEL_01
{
  key TravelId,
      AgencyId,
      CustomerId,
      BeginDate,
      EndDate,
      BookingFee,
      TotalPrice,
      CurrencyCode,
      Description,
      OverallStatus,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      AgencyName,
      CustomerName,
      StatusText,
      Minion,
      
      /* Associations */
      _Agency,
      _Booking : redirected to composition child ZATS_RAMA_C_BOOKING_M_01,
      _Currency,
      _Customer,
      _OverallStatus
}
