@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Unmanaged CDS entity root travel'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZATS_RAMA_TRAVEL_U_01
  as select from /dmo/travel
  association [1] to ZATS_RAMA_AGENCY_U_01   as _Agency   on $projection.AgencyId = _Agency.AgencyId
  association [1] to ZATS_RAMA_CUSTOMER_U_01 as _Customer on $projection.CustomerId = _Customer.CustomerId
  association [1] to I_Currency              as _Currency on $projection.CurrencyCode = _Currency.Currency
  association [1] to /DMO/I_Travel_Status_VH as _Status   on $projection.Status = _Status.TravelStatus
{
      @ObjectModel.text.element: [ 'Memo' ]
  key /dmo/travel.travel_id     as TravelId,
      @ObjectModel.text.element: [ 'AgencyName' ]
      @Consumption.valueHelpDefinition: [{
          entity:{
              name: 'ZATS_RAMA_AGENCY_U_01',
              element: 'AgencyId'
          }
       }]
      /dmo/travel.agency_id     as AgencyId,
      _Agency.Name              as AgencyName,
      @ObjectModel.text.element: [ 'CustomerName' ]
      @Consumption.valueHelpDefinition: [{
          entity:{
              name: 'ZATS_RAMA_CUSTOMER_U_01',
              element: 'CustomerId'
          }
       }]
      /dmo/travel.customer_id   as CustomerId,
      _Customer.customerName    as CustomerName,
      /dmo/travel.begin_date    as BeginDate,
      /dmo/travel.end_date      as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      /dmo/travel.booking_fee   as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      /dmo/travel.total_price   as TotalPrice,
      @Consumption.valueHelpDefinition: [{
          entity:{
              name: 'I_Currency',
              element: 'Currency'
          }
       }]
      /dmo/travel.currency_code as CurrencyCode,
      /dmo/travel.description   as Memo,
      @Consumption.valueHelpDefinition: [{
          entity:{
              name: '/DMO/I_Travel_Status_VH',
              element: 'TravelStatus'
          }
       }]
      @ObjectModel.text.element: [ 'TravelStatus' ]
      /dmo/travel.status        as Status,
      _Status._Text.Text        as TravelStatus,
      /dmo/travel.createdby     as Createdby,
      /dmo/travel.createdat     as Createdat,
      /dmo/travel.lastchangedby as Lastchangedby,
      /dmo/travel.lastchangedat as Lastchangedat,
      _Agency,
      _Customer,
      _Currency,
      _Status
}
