CLASS zcl_load_data_kpm DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC .

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun. "Esta interfaz permite ejecutar la clase por consola
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS zcl_load_data_kpm IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.
    DATA: lt_status TYPE TABLE OF zdt_status_kpm,
          lt_prior  TYPE TABLE OF zdt_prior_kpm.

    " 1. Limpiar tablas por si ejecutamos la clase más de una vez
    DELETE FROM zdt_status_kpm.
    DELETE FROM zdt_prior_kpm.
    DELETE FROM zdt_inct_kpm_d.

    " 2. Preparar registros de Estados
    lt_status = VALUE #(
      ( client = sy-mandt status_code = 'OP' status_desc = 'Open' )
      ( client = sy-mandt status_code = 'IP' status_desc = 'In Progress' )
      ( client = sy-mandt status_code = 'PE' status_desc = 'Pending' )
      ( client = sy-mandt status_code = 'CO' status_desc = 'Completed' )
      ( client = sy-mandt status_code = 'CL' status_desc = 'Closed' )
      ( client = sy-mandt status_code = 'CN' status_desc = 'Canceled' )
    ).
    INSERT zdt_status_kpm FROM TABLE @lt_status.

    " 3. Preparar registros de Prioridades
    lt_prior = VALUE #(
      ( client = sy-mandt prior_code = 'H' prior_desc = 'High' )
      ( client = sy-mandt prior_code = 'M' prior_desc = 'Medium' )
      ( client = sy-mandt prior_code = 'L' prior_desc = 'Low' )
    ).
    INSERT zdt_prior_kpm FROM TABLE @lt_prior.

    " 4. Imprimir mensaje en la consola de Eclipse
    out->write( 'Datos maestros insertados correctamente en BTP.' ).
    out->write( sy-uname ).
  ENDMETHOD.
ENDCLASS.
