CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE Booking\_Bookingsuppl.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.

    DATA max_book_suppl_id TYPE /dmo/booking_supplement_id.

    ""Step 1: Get All the travel request and their booking Supplements
    READ ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY booking BY \_BookingSuppl
        FROM CORRESPONDING #( entities )
        LINK DATA(lt_booking_suppl).

    ""Step 2: Cases to handle for Assigning unique Booking Supplement ID
    "1001, 1002, 1005
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking_group>) GROUP BY <booking_group>-%tky-BookingId.

      ""Step 3: Loop at the specific booking supplements of every unique booking id
      ""If there is already the data inside, assign the Booking id to our variable which is max
      "Pass 1 - 10,20
      "Pass 2 - 10
      "Pass 3 - 40,50
      ""Get the highest assigned (already) supplement id number
      LOOP AT lt_booking_suppl INTO DATA(ls_book_suppl) USING KEY entity
                                      WHERE source-Travelid = <booking_group>-TravelId AND
                                            source-BookingId = <booking_group>-BookingId.
        ""Determine the Already created Booking Id which is maximum
        IF max_book_suppl_id < ls_book_suppl-target-BookingId.
          max_book_suppl_id = ls_book_suppl-target-BookingId.
        ENDIF.
      ENDLOOP.

      ""Get the assigned supplement id for incoming request
      LOOP AT entities INTO DATA(ls_entity) USING KEY entity WHERE travelid = <booking_group>-TravelId AND
                                                                  BookingId = <booking_group>-BookingId.
        LOOP AT ls_entity-%target INTO DATA(ls_target).
          IF max_book_suppl_id < ls_target-BookingSupplementId.
            max_book_suppl_id = ls_target-BookingSupplementId.
          ENDIF.
        ENDLOOP.
      ENDLOOP.


      LOOP AT entities ASSIGNING FIELD-SYMBOL(<booking>) USING KEY entity
                                           WHERE travelid = <booking_group>-TravelId AND
                                                 bookingid = <booking_group>-BookingId.

        ""Step 5: Increment the Booking id +10 and assign the new id
        LOOP AT <booking>-%target ASSIGNING FIELD-SYMBOL(<booksuppl_wo_number>).
          APPEND CORRESPONDING #( <booksuppl_wo_number> ) TO mapped-booksuppl
                               ASSIGNING FIELD-SYMBOL(<mapped_book_suppl>).
          ""Determine the Already created Booking Id which is maximum
          ""Assining the +10 as new booking id
          IF <mapped_book_suppl>-BookingSupplementId IS INITIAL.
            max_book_suppl_id += 1.
            <mapped_book_suppl>-BookingSupplementId = max_book_suppl_id.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

    ""Step 4: Loop over all the entities of travel with same travel id and increment the max booking id


  ENDMETHOD.

ENDCLASS.
