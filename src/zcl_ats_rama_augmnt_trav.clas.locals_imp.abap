CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS augment_create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD augment_create.

    data travel_create type table for create ZATS_RAMA_R_TRAVEL_01.

    travel_create = corrESPONDING #( entities ).

    loop at travel_create assIGNING fieLD-SYMBOL(<fs_create>).

        <fs_create>-AgencyId = '70004'.
        <fs_create>-OverallStatus = 'O'.
        <fs_create>-%control-AgencyId = if_abap_behv=>mk-on.
        <fs_create>-%control-OverallStatus = if_abap_behv=>mk-on.

    endloop.

    modify augmenting entities of ZATS_RAMA_R_TRAVEL_01
        entity travel
        create from travel_create.

  ENDMETHOD.

ENDCLASS.
