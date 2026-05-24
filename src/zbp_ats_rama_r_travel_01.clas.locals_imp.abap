CLASS lsc_ZATS_RAMA_R_TRAVEL_01 DEFINITION INHERITING FROM cl_abap_behavior_saver.

  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

ENDCLASS.

CLASS lsc_ZATS_RAMA_R_TRAVEL_01 IMPLEMENTATION.

  METHOD save_modified.
  """ This method defined from -  Added in the Behaviour Defination: 'with additional save'

    ""call function 'SWDD_WORKFLOW_START'
    DATA: lt_log_data   TYPE STANDARD TABLE OF /dmo/log_travel,
          lt_final_data TYPE STANDARD TABLE OF /dmo/log_travel.

    IF update-travel IS NOT INITIAL.

      "get all changes in our local table done by user
      lt_log_data = CORRESPONDING #( update-travel MAPPING travel_id = TravelId ).

      LOOP AT update-travel ASSIGNING FIELD-SYMBOL(<fs_changes>).

        ASSIGN lt_log_data[ travel_id = <fs_changes>-TravelId ]
            TO FIELD-SYMBOL(<travel_log_db>).

        GET TIME STAMP FIELD <travel_log_db>-created_at.

        IF <fs_changes>-%control-CustomerId = if_abap_behv=>mk-on.

          <travel_log_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
          <travel_log_db>-changed_field_name = 'ramdas_customer'.
          <travel_log_db>-changed_value = <fs_changes>-CustomerId.
          <travel_log_db>-changing_operation = 'update'.

          APPEND <travel_log_db> TO lt_final_data.

        ENDIF.

        IF <fs_changes>-%control-AgencyId = if_abap_behv=>mk-on.

          <travel_log_db>-change_id = cl_system_uuid=>create_uuid_x16_static( ).
          <travel_log_db>-changed_field_name = 'ramdas_agency'.
          <travel_log_db>-changed_value = <fs_changes>-AgencyId.
          <travel_log_db>-changing_operation = 'update'.

          APPEND <travel_log_db> TO lt_final_data.
        ENDIF.

      ENDLOOP.

      INSERT /dmo/log_travel FROM TABLE @lt_final_data.
    ENDIF.

  ENDMETHOD.

ENDCLASS.

CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.

    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~copytravel.

    METHODS recalctotalprice FOR MODIFY
      IMPORTING keys FOR ACTION travel~recalctotalprice.

    METHODS calctotalprice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR travel~calctotalprice.

    METHODS validateheaderdata FOR VALIDATE ON SAVE
      IMPORTING keys FOR travel~validateheaderdata.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR travel RESULT result.

    METHODS accepttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~accepttravel RESULT result.

    METHODS rejecttravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~rejecttravel RESULT result.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE travel.

    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities FOR CREATE travel\_booking.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.

    "declare data types for input and output for my reuse method
    TYPES: t_entity_Create   TYPE TABLE FOR CREATE zats_rama_r_travel_01,
           t_entity_Update   TYPE TABLE FOR UPDATE zats_rama_r_travel_01,
           t_entity_Reported TYPE TABLE FOR REPORTED zats_rama_r_travel_01,
           t_entity_Failed   TYPE TABLE FOR FAILED zats_rama_r_travel_01.

    "reusable method // works well in ODATA V2 service. But, not in ODATA V4 service.
    METHODS precheck_anubhav_reuse
      IMPORTING
        entity_u TYPE t_entity_Update OPTIONAL
        entity_c TYPE t_entity_Create OPTIONAL
      EXPORTING
        reported TYPE t_entity_Reported
        failed   TYPE t_entity_Failed.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_global_authorizations.

    AUTHORITY-CHECK OBJECT 'ZATS_RAMA'
               ID 'ACTVT' FIELD '02'.

  ENDMETHOD.

  METHOD get_instance_authorizations.

*    When a user tries to edit a travel request,
*    if the travel request status is CANCELLED,
*    then we need to check if the given user is a MANAGER.
*    If yes, they can edit the cancelled request also.
*    However else, the user is not allowed to edit cancelled request.


    "Step 1: Define a return data structure of return table
    DATA ls_return LIKE LINE OF result.

    "Step 2: Read the instance of the BO, read overallstatus
    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY travel
        FIELDS ( travelid overallstatus )
        WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travel)
        FAILED DATA(lt_failed).

    "Step 3: Check if the status is CANCELLED
    LOOP AT lt_travel INTO DATA(ls_travel).

      DATA(lv_auth) = abap_false.

      IF ( ls_travel-OverallStatus = 'X' ).

        AUTHORITY-CHECK OBJECT 'ZATS_RAMA'
           ID 'ACTVT' FIELD '02'.

        IF sy-subrc = 0. "PASS user is manager
          lv_auth = abap_true.
        ENDIF.

      ELSE.
        lv_auth = abap_true.
      ENDIF.

      ls_return = VALUE #(  travelid =  ls_travel-TravelId
                         "" ' %action-Edit' work for ODATA V4
                            %action-Edit = COND #(
                                                  WHEN lv_auth EQ abap_false
                                                      THEN if_abap_behv=>auth-unauthorized
                                                      ELSE if_abap_behv=>auth-allowed
                            )
                         "" ' %update' work for ODATA V2
                            %update = COND #(
                                                  WHEN lv_auth EQ abap_false
                                                      THEN if_abap_behv=>auth-unauthorized
                                                      ELSE if_abap_behv=>auth-allowed
                            )
       ).

      APPEND ls_return TO result.

    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA: entity        TYPE STRUCTURE FOR CREATE zats_rama_r_travel_01,
          travel_id_max TYPE /dmo/travel_id.

    ""Step 1: Ensure that the travel id is not passed by user, so we can generate id
    LOOP AT entities INTO entity WHERE travelid IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-travel.
    ENDLOOP.

    ""Step 2: lets take all travel request data in another copy
    ""        filter out record which has travel id, only keep where travel id blank
    DATA(entities_wo_travelid) = entities.
    DELETE entities_wo_travelid WHERE travelid IS NOT INITIAL.

    ""Step 3: Lets use SNRO generator to create travel id
    "" example current no 422 , i want 3 = 426, 426-3 = 423
    "" 423+1 = 424, 424+1 = 425, 425+1 = 426
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = CONV #( '/DMO/TRAVL' )
            quantity          = CONV #( lines( entities_wo_travelid ) )
          IMPORTING
            number            = DATA(number_range_key)
            returncode        = DATA(number_Range_return_code)
            returned_quantity = DATA(number_Range_returned_quantity)
        ).
      CATCH cx_number_ranges INTO DATA(lx_number_ranges).
        ""Step 4: If there is a dump inside, we will just fill failed and reported
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key %msg = lx_number_ranges )
              TO reported-travel.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key )
              TO failed-travel.
        ENDLOOP.
    ENDTRY.

    ""Step 5: handle special cases if no. range exhaused, about to get exhaused
    CASE number_Range_return_code.
      WHEN '1'.
        "About to exhause 99% numbers finished - warning
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                      textid = /dmo/cm_flight_messages=>number_range_depleted
                                      severity = if_abap_behv_message=>severity-warning
                                  ) )
              TO reported-travel.
        ENDLOOP.
      WHEN '2' OR '3'.
        ""last number was retured or no. range exhaused
        APPEND VALUE #( %cid = entity-%cid %key = entity-%key
                            %msg = NEW /dmo/cm_flight_messages(
                                        textid = /dmo/cm_flight_messages=>not_sufficient_numbers
                                        severity = if_abap_behv_message=>severity-warning
                                    ) )
                TO reported-travel.
        APPEND VALUE #( %cid = entity-%cid %key = entity-%key
                        %fail-cause = if_abap_behv=>cause-conflict )
            TO failed-travel.

    ENDCASE.

    ""Step 6 : Final check for all numbers
    ASSERT number_Range_returned_quantity = lines( entities_wo_travelid ).

    ""Step 7 Loop over the incoming data and assign the travel id by incrementing it
    ""       send the data wrapped to RAP framewor
    travel_id_max = number_range_key - number_range_returned_quantity.

    LOOP AT entities_wo_travelid INTO entity.

      travel_id_max += 1.
      entity-TravelId = travel_id_max.

      APPEND VALUE #( %cid = entity-%cid %key = entity-%key
                      %is_draft = entity-%is_draft
       ) TO mapped-travel.

    ENDLOOP.

  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.

    DATA max_booking_id TYPE /dmo/booking_id.

    ""Step 1: Get All the travel request and their bookings
    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY travel BY \_Booking
        FROM CORRESPONDING #( entities )
        LINK DATA(lt_bookings).

    ""Step 2: Cases to handle for Assigning unique Booking ID
    "1001, 1002, 1005
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel_group>) GROUP BY <travel_group>-TravelId.

      ""Step 3: Loop at the specific booking of every unique travel id
      ""If there is already the data inside, assign the Booking id to our variable which is max
      "Pass 1 - 10,20
      "Pass 2 - 10
      "Pass 3 - 40,50
      LOOP AT lt_bookings INTO DATA(ls_bookings) USING KEY entity
                                      WHERE source-Travelid = <travel_group>-TravelId.
        ""Determine the Already created Booking Id which is maximum
        IF max_booking_id < ls_bookings-target-BookingId.
          max_booking_id = ls_bookings-target-BookingId.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    ""Step 4: Loop over all the entities of travel with same travel id and increment the max booking id

    LOOP AT entities ASSIGNING FIELD-SYMBOL(<travel>) GROUP BY <travel>-TravelId.

      ""Step 5: Increment the Booking id +10 and assign the new id
      LOOP AT <travel>-%target ASSIGNING FIELD-SYMBOL(<travel_wo_number>).
        APPEND CORRESPONDING #( <travel_wo_number> ) TO mapped-booking
                             ASSIGNING FIELD-SYMBOL(<mapped_booking>).
        ""Determine the Already created Booking Id which is maximum
        ""Assining the +10 as new booking id
        IF <mapped_booking>-BookingId IS INITIAL.
          max_booking_id += 10.
          <mapped_booking>-BookingId = max_booking_id.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDMETHOD.

  METHOD get_instance_features.

    ""Use case: check the status of the current travel request
    ""          if cancelled, disable the booking creation

    ""Step 1: EML to read the travel status
    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY travel
            FIELDS ( travelid overallstatus )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travel)
        FAILED DATA(lt_failed).

    ""Step 2: Return the result with booking creation is possible or not
    READ TABLE lt_travel INTO DATA(ls_travel) INDEX 1.

    IF ( ls_travel-OverallStatus = 'X' ).
      DATA(lv_allow) = if_abap_behv=>fc-o-disabled.
    ELSE.
      lv_allow = if_abap_behv=>fc-o-enabled.
    ENDIF.



    result = VALUE #(  FOR travel IN lt_travel ( %tky = travel-%tky
                                                 %assoc-_Booking = lv_allow
                                                 %features-%action-acceptTravel =
                                                        COND #( WHEN travel-OverallStatus = 'A'
                                                                    THEN if_abap_behv=>fc-o-disabled
                                                                    ELSE if_abap_behv=>fc-o-enabled )
                                                 %features-%action-rejectTravel =
                                                        COND #( WHEN travel-OverallStatus = 'X'
                                                                    THEN if_abap_behv=>fc-o-disabled
                                                                    ELSE if_abap_behv=>fc-o-enabled )

                                                  ) ).

  ENDMETHOD.

  METHOD copyTravel.

    "Shallow Copy = Header
    "Deep Copy = Header, Items, Sub Items
    ""Step 1: Declare data to store new records
    DATA: travels       TYPE TABLE FOR CREATE zats_rama_r_travel_01\\Travel,
          bookings_cba  TYPE TABLE FOR CREATE zats_rama_r_travel_01\\Travel\_Booking,
          booksuppl_cba TYPE TABLE FOR CREATE zats_rama_r_travel_01\\Booking\_BookingSuppl.


    "Step 1:Validate to make sure no data with blank %cid is allowed
    READ TABLE keys WITH KEY %cid = '' INTO DATA(key_with_initial_cid).
    ASSERT     key_with_initial_cid IS INITIAL.

    "Step 2: Read all the existing data of travel, booking, supplement

    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
    ENTITY travel
        ALL FIELDS WITH CORRESPONDING #( keys )
        RESULT DATA(travel_read_result)
        FAILED failed.

    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
    ENTITY travel BY \_Booking
        ALL FIELDS WITH CORRESPONDING #( travel_read_result )
        RESULT DATA(book_read_result)
        FAILED failed.

    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
    ENTITY booking BY \_BookingSuppl
        ALL FIELDS WITH CORRESPONDING #( book_read_result )
        RESULT DATA(booksuppl_read_result)
        FAILED failed.

    ""Step 2: Prepare the data to be inserted in DB
    LOOP AT travel_read_result ASSIGNING FIELD-SYMBOL(<travel>).

      ""Travel data prepare
      APPEND VALUE #( %cid = keys[ %tky = <travel>-%tky ]-%cid
                      %data = CORRESPONDING #( <travel> EXCEPT travelid )
                    ) TO travels ASSIGNING FIELD-SYMBOL(<new_travel>).

      <new_travel>-BeginDate = cl_abap_context_info=>get_system_date( ).
      <new_travel>-EndDate = cl_abap_context_info=>get_system_date( ) + 30.
      <new_travel>-OverallStatus = 'N'.

      ""Booking data prepration
      "We have to pass %cid_ref to tell system, that the bookings belongs to
      "which travel request - a record was inserted in itab for booking
      APPEND VALUE #( %cid_ref = keys[ KEY entity %tky = <travel>-%tky ]-%cid
                    ) TO bookings_cba ASSIGNING FIELD-SYMBOL(<booking_cba>).

      ""Preapre all the bookings from existing request which needs to be copied
      LOOP AT book_read_result ASSIGNING FIELD-SYMBOL(<booking>) WHERE travelid =  <travel>-TravelId.

        ""Lets pass a unique booking cid - Concatenate the CID of travel with BookingId of existing travel
        APPEND VALUE #( %cid = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId
                        %data = CORRESPONDING #( book_read_result[ KEY entity %tky = <booking>-%tky ] EXCEPT travelid ) )
                TO <booking_cba>-%target ASSIGNING FIELD-SYMBOL(<new_booking>).

        <new_booking>-BookingStatus = 'N'.

        """---start of supplement
        ""Booking data prepration
        "We have to pass %cid_ref to tell system, that the bookings belongs to
        "which travel request - a record was inserted in itab for booking
        APPEND VALUE #( %cid_ref = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId
                      ) TO booksuppl_cba ASSIGNING FIELD-SYMBOL(<booksuppl_cba>).

        ""Preapre all the bookings from existing request which needs to be copied
        LOOP AT booksuppl_read_result ASSIGNING FIELD-SYMBOL(<book_suppl>) USING KEY entity WHERE travelid =  <travel>-TravelId
                                                                             AND bookingid =  <booking>-BookingId.

          ""Lets pass a unique booking cid - Concatenate the CID of travel with BookingId of existing travel
          APPEND VALUE #( %cid = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId && <book_suppl>-BookingSupplementId
                          %data = CORRESPONDING #( <book_suppl> EXCEPT travelid bookingid ) )
                  TO <booksuppl_cba>-%target.
        ENDLOOP.
        """---end of sumpplement

      ENDLOOP.

    ENDLOOP.

    ""Step 3: Insert data in DB using EML
    MODIFY ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY travel
         CREATE FIELDS ( agencyid customerid begindate enddate bookingfee totalprice currencycode overallstatus )
           WITH travels
            CREATE BY \_Booking FIELDS ( bookingid bookingdate customerid carrierid connectionid flightdate flightprice currencycode bookingstatus )
                WITH bookings_cba
                ENTITY booking
                 CREATE BY \_BookingSuppl FIELDS ( BookingSupplementId SupplementId Price CurrencyCode )
                    WITH booksuppl_cba
         MAPPED DATA(mapped_data).

    "mapped-travel = mapped_data-travel.
    mapped = mapped_data.

  ENDMETHOD.

  METHOD reCalcTotalPrice.

*    Define a structure where we can store all the Booking Fees and Currency Code
    TYPES : BEGIN OF ty_total_cost,
              amount   TYPE /dmo/total_price,
              currency TYPE /dmo/currency_code,
            END OF ty_total_cost.

    DATA ls_header_curr TYPE /dmo/currency_code.
    DATA amounts_per_currencycode TYPE STANDARD TABLE OF ty_total_cost.
*    Read all the travel instances, subsequent Bookings inside that using EML
*    Read all the Booking Supplements for each Booking using EML
    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
    ENTITY travel
        FIELDS ( bookingfee currencycode ) WITH CORRESPONDING #( keys )
        RESULT DATA(travel)
        FAILED failed.

    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
    ENTITY travel BY \_Booking
        FIELDS ( flightprice currencycode ) WITH CORRESPONDING #( travel )
        RESULT DATA(booking)
        FAILED failed.

    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
    ENTITY booking BY \_BookingSuppl
        FIELDS ( price currencycode ) WITH CORRESPONDING #( booking )
        RESULT DATA(booksuppl)
        FAILED failed.

    " Delete records where currencycode is empty, optionally throw error
    DELETE travel WHERE currencycode IS INITIAL.
    DELETE booking WHERE currencycode IS INITIAL.
    DELETE booksuppl WHERE currencycode IS INITIAL.

*    Loop at header, item and item childs Total All the amounts in itab for Common currency
    LOOP AT travel ASSIGNING FIELD-SYMBOL(<fs_travel>).

      amounts_per_currencycode = VALUE #( ( amount = <fs_travel>-BookingFee
                                            currency = <fs_travel>-CurrencyCode ) ).
      ls_header_curr = <fs_travel>-CurrencyCode.

      LOOP AT booking INTO DATA(wa_booking) WHERE travelid = <fs_travel>-travelid.

        ""add all numeric column values by comparing non-numeric columns
        COLLECT VALUE ty_total_cost( amount = wa_booking-FlightPrice
                                     currency = wa_booking-CurrencyCode )
                                     INTO amounts_per_currencycode.

        LOOP AT booksuppl INTO DATA(wa_suppl) WHERE travelid = wa_booking-travelid AND
                                                      bookingid = wa_booking-bookingid.
          COLLECT VALUE ty_total_cost( amount = wa_suppl-price
                                   currency = wa_suppl-CurrencyCode )
                                   INTO amounts_per_currencycode.

        ENDLOOP.

      ENDLOOP.
      CLEAR <fs_travel>-TotalPrice.
    ENDLOOP.

*    Compare the currency of Booking and Supplement with header currency
    LOOP AT amounts_per_currencycode INTO DATA(ls_amount_per_currency).
*           If it does not match, perform currency conversion
      IF ls_amount_per_currency-currency = ls_header_curr.
        <fs_travel>-TotalPrice += ls_amount_per_currency-amount.
      ELSE.
        /dmo/cl_flight_amdp=>convert_currency(
          EXPORTING
            iv_amount               = ls_amount_per_currency-amount
            iv_currency_code_source = ls_amount_per_currency-currency
            iv_currency_code_target = ls_header_curr
            iv_exchange_rate_date   = cl_abap_context_info=>get_system_date(  )
          IMPORTING
            ev_amount               =  DATA(total_amt)
        ).

        <fs_travel>-TotalPrice += total_amt.
      ENDIF.

    ENDLOOP.

*    Total all the amount in a variable and set it to the Travel header level using EML
    MODIFY ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
    ENTITY travel
    UPDATE FIELDS ( totalprice )
    WITH CORRESPONDING #( travel ).
*    Return the mapped data as a result of internal action

  ENDMETHOD.

  METHOD calcTotalPrice.

    ""How to call an action using the EML
    MODIFY ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY travel
            EXECUTE reCalcTotalPrice
            FROM CORRESPONDING #( keys ).

  ENDMETHOD.

  METHOD validateHeaderData.

    ""Step 1: Read the data of incoming request from EML
    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY travel
            FIELDS ( agencyid customerid begindate enddate )
            WITH CORRESPONDING #( keys )
            RESULT DATA(lt_travel).

    ""Step 2: Declare sorted table to hold customer ids and agency id
    DATA : lt_customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id,
           lt_agency    TYPE SORTED TABLE OF /dmo/agency   WITH UNIQUE KEY agency_id.

    ""Step 3: Extract the unique customer and agency ids from travel data
    lt_customers = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = customerid EXCEPT * ).
    lt_agency = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING agency_id = agencyid EXCEPT * ).

    DELETE lt_customers WHERE customer_id IS INITIAL.
    DELETE lt_agency WHERE agency_id IS INITIAL.

    ""Step 4: Extract the Customer and Agency Data from Databased based on travel data
    IF lt_customers IS NOT INITIAL.

      SELECT FROM /dmo/customer FIELDS customer_id
          FOR ALL ENTRIES IN @lt_customers
              WHERE customer_id = @lt_customers-customer_id
              INTO TABLE @DATA(lt_cust_db).

    ENDIF.
    IF lt_agency IS NOT INITIAL.

      SELECT FROM /dmo/agency FIELDS agency_id
          FOR ALL ENTRIES IN @lt_agency
              WHERE agency_id = @lt_agency-agency_id
              INTO TABLE @DATA(lt_agency_db).

    ENDIF.

    ""Step 5: Loop at incoming data to validate customer and agency one by one
    LOOP AT lt_travel INTO DATA(ls_travel).
      ""Check if customer id is blank
      ""OR
      ""If in the DB customer does not exist
      IF ( ls_travel-customerid IS INITIAL OR NOT line_exists( lt_cust_db[ customer_id = ls_travel-customerid ] ) ).

        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = ls_travel-%tky
                        %element-customerid = if_abap_behv=>mk-on
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid = /dmo/cm_flight_messages=>customer_unkown
                                                            customer_id = ls_travel-CustomerId
                                                            severity = if_abap_behv_message=>severity-error
                        )
         ) TO reported-travel.

      ENDIF.

      ""Check if customer id is blank
      ""OR
      ""If in the DB customer does not exist
      IF ( ls_travel-agencyid IS INITIAL OR NOT line_exists( lt_agency_db[ agency_id = ls_travel-agencyid ] ) ).

        APPEND VALUE #( %tky = ls_travel-%tky %is_draft = ls_travel-%is_draft ) TO failed-travel.
        APPEND VALUE #( %tky = ls_travel-%tky %is_draft = ls_travel-%is_draft
                        %element-agencyid = if_abap_behv=>mk-on
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid = /dmo/cm_flight_messages=>agency_unkown
                                                            agency_id = ls_travel-agencyid
                                                            severity = if_abap_behv_message=>severity-error
                        )
         ) TO reported-travel.

      ENDIF.

      ""Homework : Add following validations
      "1. Check if the travel start date is >= todays
      "2. Travel End date must be > Begin Date
      "3. Travel begin and end date must not be Initial

    ENDLOOP.

  ENDMETHOD.


  METHOD precheck_anubhav_reuse.

    "step 1: data declaration
    DATA : entities  TYPE t_entity_update,
           operation TYPE if_abap_behv=>t_char01,
           agencies  TYPE SORTED TABLE OF /dmo/agency WITH UNIQUE KEY agency_id,
           customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id.


    ""Step 2: check atleast either create data or update data was passed
    ASSERT NOT ( entity_c IS INITIAL EQUIV entity_u IS INITIAL ).

    ""Step 3: map the data to a single table
    IF entity_c IS NOT INITIAL.
      entities = CORRESPONDING #( entity_c ).
      operation = if_abap_behv=>op-m-create.
    ELSE.
      entities = entity_u.
      operation = if_abap_behv=>op-m-update.
    ENDIF.

    ""Step 4: clear the data in case user modified fields other than agency and customer
    DELETE entities WHERE %control-AgencyId = if_abap_behv=>mk-off
                         AND %control-CustomerId = if_abap_behv=>mk-off.

    ""Step 5: filter only the unique agencies and customers
    agencies = CORRESPONDING #( entities DISCARDING DUPLICATES MAPPING agency_id = agencyid EXCEPT * ).
    customers = CORRESPONDING #( entities DISCARDING DUPLICATES MAPPING customer_id = customerid EXCEPT * ).

    ""Step 6: call db tables for master data to load valid customers and agencies
    SELECT FROM /dmo/agency FIELDS agency_id, country_code
            FOR ALL ENTRIES IN @agencies WHERE agency_id = @agencies-agency_id
            INTO TABLE @DATA(lt_agency_country).
    SELECT FROM /dmo/customer FIELDS customer_id, country_code
            FOR ALL ENTRIES IN @customers WHERE customer_id = @customers-customer_id
            INTO TABLE @DATA(lt_customer_country).

    ""Step 7: loop at all the incoming data for validation and compare the countries of customer and agency
    LOOP AT entities INTO DATA(entity).

      READ TABLE lt_agency_country WITH KEY agency_id = entity-AgencyId INTO DATA(ls_agency_val).
      CHECK sy-subrc = 0.
      READ TABLE lt_customer_country WITH KEY customer_id = entity-customerid INTO DATA(ls_customer_val).
      CHECK sy-subrc = 0.

      ""if condition to check if they both belongs to same country, if not, Throw the error
      IF ls_agency_val-country_code <> ls_customer_val-country_code.

        ""Step 8 : inform the RAP framework that something is fishy
        APPEND VALUE #(
                        %cid = COND #( WHEN operation = if_abap_behv=>op-m-create
                                            THEN entity-%cid_ref
                        )
                        %is_draft = entity-%is_draft
                        %fail-cause = if_abap_behv=>cause-conflict

         ) TO failed.
        APPEND VALUE #(
                        %cid = COND #( WHEN operation = if_abap_behv=>op-m-create
                                            THEN entity-%cid_ref
                        )
                        %is_draft = entity-%is_draft
                        %msg = NEW /dmo/cm_flight_messages(
                                                             textid = VALUE #( msgid = 'SY' msgno = 499
                                                                               attr1 = 'The country code for '
                                                                               attr2 = | { entity-agencyid } and |
                                                                               attr3 = entity-customerid
                                                                               attr4 = 'does not match'
                                                             )
                                                             agency_id = entity-agencyid
                                                             customer_id = entity-customerid
                                                             severity = if_abap_behv_message=>severity-error
                                                          )
                        %element-agencyid = if_abap_behv=>mk-on

         ) TO reported.

      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD acceptTravel.

    "Change the travel status to Approved using EML
    MODIFY ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY travel
        UPDATE FIELDS ( overallstatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                        %is_draft = key-%is_draft
                                        OverallStatus = 'A'
         ) ).

    "Read the data of BO instance again
    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
       ENTITY travel
       ALL FIELDS
       WITH CORRESPONDING #( keys )
       RESULT DATA(lt_result).

    "return the data out
    result = VALUE #( FOR travel IN lt_result ( %tky = travel-%tky %param = travel ) ).

  ENDMETHOD.

  METHOD rejectTravel.

    "Change the travel status to Approved using EML
    MODIFY ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY travel
        UPDATE FIELDS ( overallstatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                        %is_draft = key-%is_draft
                                        OverallStatus = 'X'
         ) ).

    "Read the data of BO instance again
    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
       ENTITY travel
       ALL FIELDS
       WITH CORRESPONDING #( keys )
       RESULT DATA(lt_result).

    "return the data out
    result = VALUE #( FOR travel IN lt_result ( %tky = travel-%tky %param = travel ) ).

  ENDMETHOD.

  METHOD precheck_create.

    precheck_anubhav_reuse(
      EXPORTING
*        entity_u =
        entity_c = entities
      IMPORTING
        reported = reported-travel
        failed   = failed-travel
    ).

  ENDMETHOD.

  METHOD precheck_update.

    precheck_anubhav_reuse(
      EXPORTING
        entity_u = entities
*        entity_c =
      IMPORTING
        reported = reported-travel
        failed   = failed-travel
    ).

  ENDMETHOD.

ENDCLASS.
