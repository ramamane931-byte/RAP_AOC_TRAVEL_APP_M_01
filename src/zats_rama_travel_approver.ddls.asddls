@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Approver Travel Processor projection'
@Metadata.ignorePropagatedAnnotations: false
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
define root view entity ZATS_RAMA_TRAVEL_APPROVER
  provider contract transactional_query
  as projection on ZATS_RAMA_R_TRAVEL_01
{
  key TravelId,
      AgencyId,
      AgencyName,
      CustomerId,
      CustomerName,
      BeginDate,
      EndDate,
      BookingFee,
      TotalPrice,
      CurrencyCode,
      Description,
      OverallStatus,
      Minion,
      StatusText,
      CreatedBy,
      CreatedAt,
      LastChangedBy,
      LastChangedAt,
      
      /* Associations */
      _Agency,
      _Booking : redirected to composition child ZATS_RAMA_BOOKING_APPROVER,
      _Currency,
      _Customer,
      _OverallStatus
}
