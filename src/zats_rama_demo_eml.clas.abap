CLASS zats_rama_demo_eml DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.

    INTERFACES if_oo_adt_classrun .
    DATA : lv_ops TYPE c VALUE 'R'.

  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zats_rama_demo_eml IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    CASE lv_ops.
      WHEN 'R'.

        "EML to Read data
        READ ENTITIES OF zats_rama_r_travel_01
            ENTITY Travel
            "BY \_Booking ALL FIELDS
            FIELDS ( travelid agencyid customerid begindate totalprice currencycode ) WITH
            VALUE #(
                        ( travelid = '00000010' )
                        ( travelid = '00000024' )
                        ( travelid = '505585' )
                   )
            RESULT DATA(lt_result)
            FAILED DATA(lt_failed)
            REPORTED DATA(lt_reported)
            .

        ""read dependent booking data fro travel
        READ ENTITIES OF zats_rama_r_travel_01
            ENTITY Travel
            BY \_Booking ALL FIELDS WITH
            CORRESPONDING #( lt_result )
            RESULT DATA(lt_result_book)
            FAILED lt_failed
            REPORTED lt_reported
            .

        out->write(
          EXPORTING
            data   = lt_result
        ).

        out->write(
                     EXPORTING
                       data   = lt_result_book
                   ).

        out->write(
          EXPORTING
            data   = lt_failed
        ).

        out->write(
          EXPORTING
            data   = lt_reported
        ).

      WHEN 'C'.

        "prepare test data for create
        DATA(lv_descr) = 'Anubhav Rocks with ABAP'.
        DATA(lv_agency) = '070016'.
        DATA(lv_cust) = '000697'.


        MODIFY ENTITIES OF zats_rama_r_travel_01
            ENTITY Travel
            CREATE FIELDS ( agencyid customerid begindate enddate totalprice currencycode bookingfee description overallstatus )
            WITH VALUE #(
                            (
                                %cid = 'ANUBHAV'
                                travelid = '00012347'
                                agencyid = lv_agency
                                CustomerId = lv_cust
                                BeginDate = cl_abap_context_info=>get_system_date(  )
                                endDate = cl_abap_context_info=>get_system_date(  ) + 30
                                Description = lv_descr
                                OverallStatus = 'O'
                            )
                            (
                                %cid = 'ANUBHAV-1'
                                travelid = '00012355'
                                agencyid = lv_agency
                                CustomerId = lv_cust
                                BeginDate = cl_abap_context_info=>get_system_date(  )
                                endDate = cl_abap_context_info=>get_system_date(  ) + 30
                                Description = lv_descr
                                OverallStatus = 'O'
                            )
                            (
                                %cid = 'ANUBHAV-2'
                                travelid = '00012347'
                                agencyid = lv_agency
                                CustomerId = lv_cust
                                BeginDate = cl_abap_context_info=>get_system_date(  )
                                endDate = cl_abap_context_info=>get_system_date(  ) + 30
                                Description = lv_descr
                                OverallStatus = 'O'
                            )

                         )
            FAILED lt_failed
            REPORTED lt_reported
            MAPPED DATA(lt_mapped).

        COMMIT ENTITIES.

        out->write(
          EXPORTING
            data   = lt_mapped
*                name   =
*              RECEIVING
*                output =
        ).

        out->write(
          EXPORTING
            data   = lt_failed
*                name   =
*              RECEIVING
*                output =
        ).


      WHEN 'U'.

        "prepare test data for create
        lv_descr = 'Hola amigo! changed'.
        lv_agency = '070022'.

        MODIFY ENTITIES OF zats_rama_r_travel_01
            ENTITY Travel
            UPDATE FIELDS (  agencyid description )
            WITH VALUE #(
                            (
                                travelid = '00012347'
                                agencyid = lv_agency
                                Description = lv_descr
                            )
                            (
                                travelid = '00012355'
                                agencyid = lv_agency
                                Description = lv_descr
                            )
                            (
                                travelid = '0505858'
                                agencyid = lv_agency
                                Description = lv_descr
                            )

                         )
            FAILED lt_failed
            REPORTED lt_reported
            MAPPED lt_mapped.

        COMMIT ENTITIES.

        out->write(
          EXPORTING
            data   = lt_mapped
*                name   =
*              RECEIVING
*                output =
        ).

        out->write(
          EXPORTING
            data   = lt_failed
*                name   =
*              RECEIVING
*                output =
        ).

      WHEN 'D'.

        MODIFY ENTITIES OF zats_rama_r_travel_01
                ENTITY Travel
                DELETE FROM
                VALUE #(
                                (
                                    travelid = '00012347'
                                )
                                (
                                    travelid = '00012355'
                                )
                                (
                                    travelid = '0505858'
                                )

                             )
                FAILED lt_failed
                REPORTED lt_reported
                MAPPED lt_mapped.

        COMMIT ENTITIES.

        out->write(
          EXPORTING
            data   = lt_mapped
*                name   =
*              RECEIVING
*                output =
        ).

        out->write(
          EXPORTING
            data   = lt_failed
*                name   =
*              RECEIVING
*                output =
        ).

    ENDCASE.

  ENDMETHOD.
ENDCLASS.
