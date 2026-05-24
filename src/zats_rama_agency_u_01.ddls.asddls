@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Agency CDS entity'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define view entity ZATS_RAMA_AGENCY_U_01
  as select from /dmo/agency
  association [1] to I_Country as _country on $projection.CountryCode = _country.Country
{
  key /dmo/agency.agency_id     as AgencyId,
      /dmo/agency.name          as Name,
      /dmo/agency.street        as Street,
      /dmo/agency.postal_code   as PostalCode,
      /dmo/agency.city          as City,
      /dmo/agency.country_code  as CountryCode,
      /dmo/agency.phone_number  as PhoneNumber,
      /dmo/agency.email_address as EmailAddress,
      /dmo/agency.web_address   as WebAddress,
      _country
}
