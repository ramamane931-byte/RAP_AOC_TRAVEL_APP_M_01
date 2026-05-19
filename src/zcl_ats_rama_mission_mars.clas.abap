CLASS zcl_ats_rama_mission_mars DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    DATA: itab TYPE TABLE OF string.
    INTERFACES if_oo_adt_classrun .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.



CLASS zcl_ats_rama_mission_mars IMPLEMENTATION.


  METHOD if_oo_adt_classrun~main.

    DATA(lv_str) = lcl_onearth=>start_engine(  ).
    APPEND lv_str TO itab.
    lv_str = lcl_onearth=>reach_space(  ).
    APPEND lv_str TO itab.

    lv_str = lcl_earth_orbit=>enter_orbit(  ).
    APPEND lv_str TO itab.
    lv_str = lcl_earth_orbit=>leave_orbit(  ).
    APPEND lv_str TO itab.

    lv_str = lcl_mars=>enter_mars_orbit(  ).
    APPEND lv_str TO itab.
    lv_str = lcl_mars=>start_mars_exploration(  ).
    APPEND lv_str TO itab.

    out->write(
      EXPORTING
        data   = itab
*        name   =
*      RECEIVING
*        output =
    ).
  ENDMETHOD.
ENDCLASS.
