@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Customer CDS entity'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZATS_RAMA_CUSTOMER_U_01
  as select from /dmo/customer
  association [1] to I_Country as _country on $projection.CountryCode = _country.Country
{
  key /dmo/customer.customer_id                                             as CustomerId,
      /dmo/customer.first_name                                              as FirstName,
      /dmo/customer.last_name                                               as LastName,
      /dmo/customer.title                                                   as Title,
      concat(concat(title, concat(' ', first_name)),concat(' ', last_name)) as customerName,
      /dmo/customer.street                                                  as Street,
      /dmo/customer.postal_code                                             as PostalCode,
      /dmo/customer.city                                                    as City,
      /dmo/customer.country_code                                            as CountryCode,
      /dmo/customer.phone_number                                            as PhoneNumber,
      /dmo/customer.email_address                                           as EmailAddress,
      _country
}
