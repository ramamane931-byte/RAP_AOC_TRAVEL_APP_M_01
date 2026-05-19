CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.
    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR travel RESULT result.
    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR travel RESULT result.

    METHODS earlynumbering_cba_booking FOR NUMBERING
      IMPORTING entities FOR CREATE travel\_booking.

    METHODS copytravel FOR MODIFY
      IMPORTING keys FOR ACTION travel~copytravel.
    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_authorizations.
*    data: lt_failed type response for failed early ZATS_RAMA_R_TRAVEL_01.
*    data: lt_reported type response for REPORTED early ZATS_RAMA_R_TRAVEL_01.
*    data : lt_test type response for MAPPED ZATS_RAMA_R_TRAVEL_01//travel.
    "AUTHORITY-CHECK
  ENDMETHOD.

  METHOD get_global_authorizations.
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

      APPEND VALUE #( %cid = entity-%cid %key = entity-%key ) TO mapped-travel.

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
                                                 %assoc-_Booking = lv_allow ) ).


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

    ENDLOOP.

    ""Step 3: Insert data in DB using EML
    MODIFY ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY travel
         CREATE FIELDS ( agencyid customerid begindate enddate bookingfee totalprice currencycode overallstatus )
           WITH travels
         MAPPED DATA(mapped_data).

    mapped-travel = mapped_data-travel.


  ENDMETHOD.

ENDCLASS.
