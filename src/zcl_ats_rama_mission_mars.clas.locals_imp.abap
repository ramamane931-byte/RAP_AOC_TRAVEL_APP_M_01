*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
*"* use this source file for the definition and implementation of
*"* local helper classes, interface definitions and type
*"* declarations
*Class pools
CLASS lcl_onearth DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS start_engine RETURNING VALUE(r_result) TYPE string.
    CLASS-METHODS reach_space RETURNING VALUE(r_result) TYPE string.
ENDCLASS.

CLASS lcl_onearth IMPLEMENTATION.

  METHOD reach_space.
    r_result = 'Meede, We are out in space'.
  ENDMETHOD.

  METHOD start_engine.
    r_result = 'We start the countdown!'.
  ENDMETHOD.

ENDCLASS.

CLASS lcl_earth_orbit DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS enter_orbit RETURNING VALUE(r_result) TYPE string.
    CLASS-METHODS leave_orbit RETURNING VALUE(r_result) TYPE string.
ENDCLASS.

CLASS lcl_earth_orbit IMPLEMENTATION.

  METHOD leave_orbit.
    r_result = 'Leave orbit and continue mission'.
  ENDMETHOD.

  METHOD enter_orbit.
    r_result = 'We enter orbit, start charging'.
  ENDMETHOD.

ENDCLASS.


CLASS lcl_mars DEFINITION.
  PUBLIC SECTION.
    CLASS-METHODS start_mars_exploration RETURNING VALUE(r_result) TYPE string.
    CLASS-METHODS enter_mars_orbit RETURNING VALUE(r_result) TYPE string.
ENDCLASS.

CLASS lcl_mars IMPLEMENTATION.

  METHOD enter_mars_orbit.
    r_result = 'Orbit Insertion to mars success'.
  ENDMETHOD.

  METHOD start_mars_exploration.
    r_result = 'Roger! we found water on Mars'.
  ENDMETHOD.

ENDCLASS.
