@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Draft query view for ZATS_RAMA_DTRAV'
@Metadata.ignorePropagatedAnnotations: false
@Metadata.allowExtensions: true
define root view entity ZATS_RAMA_TRAVQ
  as select from zats_rama_dtrav
{
  key travelid                      as Travelid,
      agencyid                      as Agencyid,
      agencyname                    as Agencyname,
      customerid                    as Customerid,
      customername                  as Customername,
      begindate                     as Begindate,
      enddate                       as Enddate,
      bookingfee                    as Bookingfee,
      totalprice                    as Totalprice,
      currencycode                  as Currencycode,
      description                   as Description,
      overallstatus                 as Overallstatus,
      minion                        as Minion,
      statustext                    as Statustext,
      createdby                     as Createdby,
      createdat                     as Createdat,
      lastchangedby                 as Lastchangedby,
      lastchangedat                 as Lastchangedat,
      draftentitycreationdatetime   as Draftentitycreationdatetime,
      draftentitylastchangedatetime as Draftentitylastchangedatetime,
      draftadministrativedatauuid   as Draftadministrativedatauuid,
      draftentityoperationcode      as Draftentityoperationcode,
      hasactiveentity               as Hasactiveentity,
      draftfieldchanges             as Draftfieldchanges
}
