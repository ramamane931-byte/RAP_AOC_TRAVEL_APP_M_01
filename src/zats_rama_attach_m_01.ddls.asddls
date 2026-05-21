@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Attachment CDS entity as child'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE
define view entity ZATS_RAMA_ATTACH_M_01
  as select from zats_rama_attach
  association to parent ZATS_RAMA_R_TRAVEL_01 as _Travel on $projection.TravelId = _Travel.TravelId
{

  key travel_id             as TravelId,
      @EndUserText.label : 'Attachment Id'
  key id                    as Id,
      @EndUserText.label : 'Memo'
      memo                  as Memo,
      @EndUserText.label : 'Attach Content'
      @Semantics.largeObject: {
          mimeType: 'Filetype',
          fileName: 'Filename',
          contentDispositionPreference: #INLINE,
          acceptableMimeTypes: [ 'application/pdf' ]
      }
      attachment            as Attachment,
      @EndUserText.label : 'File Name'
      filename              as Filename,
      @EndUserText.label : 'File Type'
      @Semantics.mimeType: true
      filetype              as Filetype,
      @Semantics.user.createdBy: true
      local_created_by      as LocalCreatedBy,
      @Semantics.systemDateTime.createdAt: true
      local_created_at      as LocalCreatedAt,
      @Semantics.user.lastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt,
      _Travel

}
