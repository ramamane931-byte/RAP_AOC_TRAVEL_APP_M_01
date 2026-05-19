CLASS lhc_BookSuppl DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calcTotalPriceSuppl FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BookSuppl~calcTotalPriceSuppl.

ENDCLASS.

CLASS lhc_BookSuppl IMPLEMENTATION.

  METHOD calcTotalPriceSuppl.

    ""How to call an action using the EML
    MODIFY ENTITIES OF zats_rama_r_travel_01 IN LOCAL MODE
        ENTITY travel
            EXECUTE reCalcTotalPrice
            FROM CORRESPONDING #( keys ).

  ENDMETHOD.

ENDCLASS.
