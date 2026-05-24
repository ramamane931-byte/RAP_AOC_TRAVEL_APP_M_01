CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE Travel.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE Travel.

    METHODS read FOR READ
      IMPORTING keys FOR READ Travel RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK Travel.

    METHODS set_booked_status FOR MODIFY
      IMPORTING keys FOR ACTION Travel~set_booked_status RESULT result.

    TYPES: tt_travel_failed   TYPE TABLE FOR FAILED zats_rama_travel_u_01,
           tt_travel_reported TYPE TABLE FOR REPORTED zats_rama_travel_u_01.

    ""Reusable method that maps the data
    METHODS map_messages
      IMPORTING
        cid          TYPE string OPTIONAL
        travel_id    TYPE /dmo/travel_id OPTIONAL
        messages     TYPE /dmo/t_message
      EXPORTING
        failed_added TYPE abap_bool
      CHANGING
        failed       TYPE tt_travel_failed
        reported     TYPE tt_travel_reported.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD create.

    ""DO NOT EVER WRITE OR CALL FM/CLASS THAT DOES DIRECT INSERT HERE...
    ""All the code must write data to tx buffer
    DATA : messages   TYPE /dmo/t_message,
           travel_in  TYPE /dmo/s_travel_in,
           travel_out TYPE /dmo/travel.

    ""Loop at the incoming data from fiori app
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel_create>).
*        travel_in = corRESPONDING #( <travel_create> mapping from entity using control ).

      travel_in-agency_id = <travel_create>-AgencyId.
      travel_in-customer_id = <travel_create>-CustomerId.
      travel_in-begin_date = <travel_create>-begindate.
      travel_in-end_date = <travel_create>-enddate.
      travel_in-booking_fee = <travel_create>-bookingfee.
      travel_in-description = <travel_create>-memo.
      travel_in-status = <travel_create>-status.
      travel_in-currency_code = <travel_create>-currencycode.
      travel_in-total_price = <travel_create>-totalprice.


*        if <travel_create>-%control-AgencyId = abap_true.
*            travel_in-agency_id = <travel_create>-AgencyId.
*        endif.
      ""Calling the legacy code to create travel request
      /dmo/cl_flight_legacy=>get_instance(  )->create_travel(
        EXPORTING
          is_travel             = travel_in
*            it_booking            =
*            it_booking_supplement =
*            iv_numbering_mode     = /dmo/if_flight_legacy=>numbering_mode-early
         IMPORTING
           es_travel             =  travel_out
*            et_booking            =
*            et_booking_supplement =
           et_messages           = DATA(lt_messages)
      ).

      ""Convert messages to what our reusable method can understand
      /dmo/cl_flight_legacy=>get_instance(  )->convert_messages(
        EXPORTING
          it_messages = lt_messages
         IMPORTING
           et_messages =  messages
      ).

      ""Preapre return data from create method
      map_messages(
        EXPORTING
          cid          = <travel_create>-%cid
          travel_id    = <travel_create>-TravelId
          messages     = messages
        IMPORTING
          failed_added = DATA(flag_error)
        CHANGING
          failed       = failed-travel
          reported     = reported-travel
      ).

      IF flag_error = abap_false.

        INSERT VALUE #( %cid = <travel_create>-%cid
                        travelid = travel_out-travel_id
         ) INTO TABLE mapped-travel.


      ENDIF.

    ENDLOOP.


  ENDMETHOD.

  METHOD update.
  ENDMETHOD.

  METHOD delete.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD set_booked_status.
  ENDMETHOD.

  METHOD map_messages.

    failed_added = abap_false.

    LOOP AT messages INTO DATA(message).

      IF message-msgty = 'E' OR message-msgty = 'A'.

        APPEND VALUE #( %cid = cid travelid = travel_id
                        %fail-cause = /dmo/cl_travel_auxiliary=>get_cause_from_message(
                                        msgid        =  message-msgid
                                        msgno        =  message-msgno
*                                            is_dependend = abap_false
                                      )
         ) TO failed.

        failed_added = abap_true.

      ENDIF.

      APPEND VALUE #(  %msg = new_message( id =  message-msgid
                                           number = message-msgno
                                           v1 = message-msgv1
                                           v2 = message-msgv2
                                           v3 = message-msgv3
                                           v4 = message-msgv4
                                           severity = if_abap_behv_message=>severity-information )
                                           %cid = cid
                                           travelid = travel_id    ) TO reported.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZATS_RAMA_TRAVEL_U_01 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZATS_RAMA_TRAVEL_U_01 IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
    /dmo/cl_flight_legacy=>get_instance(  )->save(   ).
  ENDMETHOD.

  METHOD cleanup.
    /dmo/cl_flight_legacy=>get_instance(  )->initialize(  ).
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
