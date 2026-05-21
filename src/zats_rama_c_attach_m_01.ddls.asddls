@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection entity for Attachment'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
define view entity ZATS_RAMA_C_ATTACH_M_01
  as projection on ZATS_RAMA_ATTACH_M_01
{
  key TravelId,
  key Id,
      Memo,
      Attachment,
      Filename,
      Filetype,
      LocalCreatedBy,
      LocalCreatedAt,
      LocalLastChangedBy,
      LocalLastChangedAt,
      LastChangedAt,
      
      /* Associations */
      _Travel : redirected to parent ZATS_RAMA_C_TRAVEL_M_01
}
