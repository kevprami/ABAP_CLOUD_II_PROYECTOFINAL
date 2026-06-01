CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_history,
             inc_uuid    TYPE sysuuid_x16,
             old_status  TYPE c LENGTH 2,
             new_status  TYPE c LENGTH 2,
             observation TYPE c LENGTH 255,
           END OF ty_history.
    CLASS-DATA: mt_history_buffer TYPE TABLE OF ty_history.
ENDCLASS.

CLASS lhc_Incident DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Incident RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Incident RESULT result.

    METHODS setInitialValues FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Incident~setInitialValues.

    METHODS validateDates FOR VALIDATE ON SAVE
      IMPORTING keys FOR Incident~validateDates.

    METHODS validateMandatory FOR VALIDATE ON SAVE
      IMPORTING keys FOR Incident~validateMandatory.

    METHODS validateResponsible FOR VALIDATE ON SAVE
      IMPORTING keys FOR Incident~validateResponsible.

    METHODS validateStatus FOR VALIDATE ON SAVE
      IMPORTING keys FOR Incident~validateStatus.

    METHODS changeStatus FOR MODIFY
      IMPORTING keys FOR ACTION Incident~changeStatus RESULT result.

    METHODS createInitialHistory FOR DETERMINE ON SAVE
      IMPORTING keys FOR Incident~createInitialHistory.
ENDCLASS.

CLASS lsc_ZR_DT_INCT_KPM DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save_modified REDEFINITION.
    METHODS cleanup_finalize REDEFINITION.
ENDCLASS.

CLASS lhc_Incident IMPLEMENTATION.

  METHOD get_instance_authorizations.
    result = VALUE #( FOR key IN keys (
        %tky    = key-%tky
        %update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed
    ) ).
  ENDMETHOD.

  METHOD get_instance_features.
    " 1. Leemos las llaves de los registros actuales en pantalla
    READ ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
      ENTITY Incident FIELDS ( IncUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_incidents).

    " 2. Buscamos si esos registros ya existen físicamente en la base de datos
    IF lt_incidents IS NOT INITIAL.
      SELECT inc_uuid
        FROM zdt_inct_kpm
        FOR ALL ENTRIES IN @lt_incidents
        WHERE inc_uuid = @lt_incidents-IncUuid
        INTO TABLE @DATA(lt_saved_incidents).
    ENDIF.

    " 3. Evaluamos uno por uno para habilitar o deshabilitar el botón
    result = VALUE #( FOR ls_incident IN lt_incidents (
        %tky                 = ls_incident-%tky
        %action-changeStatus = COND #(
                                 WHEN line_exists( lt_saved_incidents[ inc_uuid = ls_incident-IncUuid ] )
                                 THEN if_abap_behv=>fc-o-enabled
                                 ELSE if_abap_behv=>fc-o-disabled
                               )
    ) ).
  ENDMETHOD.

  METHOD setInitialValues.
    READ ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
      ENTITY Incident FIELDS ( IncidentId ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_incidents).

    " Obtener el máximo ID actual de la tabla
    SELECT SINGLE MAX( incident_id ) FROM zdt_inct_kpm INTO @DATA(lv_max_id).

    DATA lv_next_id_int  TYPE i.
    DATA lv_next_id_char TYPE n LENGTH 8.

    " Si la tabla está vacía o devuelve espacios, iniciamos en 1
    IF lv_max_id IS INITIAL OR lv_max_id = ' '.
      lv_next_id_int = 1.
    ELSE.
      " Protegemos la conversión matemática por si hay basura en la tabla
      TRY.
          lv_next_id_int = lv_max_id.
          lv_next_id_int = lv_next_id_int + 1.
        CATCH cx_sy_conversion_no_number.
          lv_next_id_int = 1.
      ENDTRY.
    ENDIF.

    lv_next_id_char = lv_next_id_int.

    MODIFY ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
      ENTITY Incident UPDATE
          SET FIELDS WITH VALUE #( FOR ls_incident IN lt_incidents (
            %tky         = ls_incident-%tky
            IncidentId   = lv_next_id_char
            Status       = 'OP'
            CreationDate = cl_abap_context_info=>get_system_date( )
          ) )
      REPORTED DATA(update_reported).
  ENDMETHOD.

  METHOD validateMandatory.
    READ ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
      ENTITY Incident FIELDS ( Title Description Priority ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_incidents).

    LOOP AT lt_incidents INTO DATA(ls_incident).
      IF ls_incident-Title IS INITIAL OR ls_incident-Description IS INITIAL OR ls_incident-Priority IS INITIAL.
        APPEND VALUE #( %tky = ls_incident-%tky ) TO failed-incident.
        APPEND VALUE #( %tky = ls_incident-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Título, Descripción y Prioridad obligatorios.' )
                      ) TO reported-incident.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateDates.
    READ ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
      ENTITY Incident FIELDS ( CreationDate ChangedDate ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_incidents).

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    LOOP AT lt_incidents INTO DATA(ls_incident).
      IF ls_incident-CreationDate > lv_today.
        APPEND VALUE #( %tky = ls_incident-%tky ) TO failed-incident.
        APPEND VALUE #( %tky = ls_incident-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'La fecha de creación no puede ser futura.' )
                      ) TO reported-incident.
      ENDIF.
      IF ls_incident-ChangedDate IS NOT INITIAL AND ls_incident-ChangedDate < ls_incident-CreationDate.
        APPEND VALUE #( %tky = ls_incident-%tky ) TO failed-incident.
        APPEND VALUE #( %tky = ls_incident-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Fecha de modif. no puede ser anterior a creación.' )
                      ) TO reported-incident.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateResponsible.
    READ ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
      ENTITY Incident FIELDS ( Status Responsible ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_incidents).

    LOOP AT lt_incidents INTO DATA(ls_incident).
      IF ls_incident-Status = 'IP' AND ls_incident-Responsible IS INITIAL.
        APPEND VALUE #( %tky = ls_incident-%tky ) TO failed-incident.
        APPEND VALUE #( %tky = ls_incident-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Estado IP: Requiere asignar un Responsable.' )
                      ) TO reported-incident.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateStatus.
    READ ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
      ENTITY Incident FIELDS ( Status ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_incidents_new).

    IF lt_incidents_new IS INITIAL. RETURN. ENDIF.

    SELECT inc_uuid, status
      FROM zdt_inct_kpm
      FOR ALL ENTRIES IN @lt_incidents_new
      WHERE inc_uuid = @lt_incidents_new-IncUuid
      INTO TABLE @DATA(lt_old_data).

    LOOP AT lt_incidents_new INTO DATA(ls_new).
      READ TABLE lt_old_data INTO DATA(ls_old) WITH KEY inc_uuid = ls_new-IncUuid.
      IF sy-subrc = 0.
        IF ( ls_old-status = 'CN' OR ls_old-status = 'CO' OR ls_old-status = 'CL' ) AND ls_old-status <> ls_new-Status.
          APPEND VALUE #( %tky = ls_new-%tky ) TO failed-incident.
          APPEND VALUE #( %tky = ls_new-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = 'Un incidente CN, CO o CL no puede modificarse.' )
                        ) TO reported-incident.
        ENDIF.
        IF ls_old-status = 'PE' AND ( ls_new-Status = 'CO' OR ls_new-Status = 'CL' ).
          APPEND VALUE #( %tky = ls_new-%tky ) TO failed-incident.
          APPEND VALUE #( %tky = ls_new-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = 'No puede cerrar o completar un incidente PE.' )
                        ) TO reported-incident.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD changeStatus.
    " 1. Obtenemos Status y Responsible de la base de datos
    READ ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
      ENTITY Incident FIELDS ( Status Responsible ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_incidents).

    DATA(lv_current_user) = cl_abap_context_info=>get_user_technical_name( ).
    " IMPORTANTE: Reemplaza 'TU_USUARIO' por tu ID real
    DATA lv_admin_user TYPE string VALUE 'CB9980000100'.

    LOOP AT keys INTO DATA(ls_key).
      READ TABLE lt_incidents INTO DATA(ls_incident) WITH KEY %tky = ls_key-%tky.
      IF sy-subrc = 0.

        " --- 1ra VALIDACIÓN: AUTORIZACIÓN DE ADMINISTRADOR ---
        IF lv_current_user <> lv_admin_user.
          APPEND VALUE #( %tky = ls_key-%tky ) TO failed-incident.
          APPEND VALUE #( %tky = ls_key-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = 'Solo el administrador puede cambiar el estado.' )
                        ) TO reported-incident.
          CONTINUE.
        ENDIF.

        " --- 2da VALIDACIÓN: ESTADO 'IP' REQUIERE RESPONSABLE ---
        IF ls_key-%param-NewStatus = 'IP' AND ls_incident-Responsible IS INITIAL.
          APPEND VALUE #( %tky = ls_key-%tky ) TO failed-incident.
          APPEND VALUE #( %tky = ls_key-%tky
                          %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                        text     = 'Estado IP: Requiere asignar un Responsable.' )
                        ) TO reported-incident.
          CONTINUE. " Salta a la siguiente iteración, cancelando la modificación
        ENDIF.

        " Lógica normal de modificación si superó todas las barreras
        MODIFY ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
          ENTITY Incident
            UPDATE FIELDS ( Status ChangedDate )
            WITH VALUE #( ( %tky        = ls_key-%tky
                            Status      = ls_key-%param-NewStatus
                            ChangedDate = cl_abap_context_info=>get_system_date( ) ) ).

        APPEND VALUE #( inc_uuid    = ls_incident-IncUuid
                        old_status  = ls_incident-Status
                        new_status  = ls_key-%param-NewStatus
                        observation = ls_key-%param-Observation ) TO lcl_buffer=>mt_history_buffer.
      ENDIF.
    ENDLOOP.

    READ ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
      ENTITY Incident ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_updated_incidents).

    result = VALUE #( FOR ls_updated IN lt_updated_incidents
                      ( %tky = ls_updated-%tky %param = ls_updated ) ).
  ENDMETHOD.

  METHOD createInitialHistory.
    READ ENTITIES OF zr_dt_inct_kpm IN LOCAL MODE
      ENTITY Incident FIELDS ( IncUuid ) WITH CORRESPONDING #( keys )
      RESULT DATA(lt_incidents).

    LOOP AT lt_incidents INTO DATA(ls_incident).
      " Usar el buffer global en lugar de un INSERT directo prohibido
      APPEND VALUE #( inc_uuid    = ls_incident-IncUuid
                      old_status  = ''
                      new_status  = 'OP'
                      observation = 'First Incident' ) TO lcl_buffer=>mt_history_buffer.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZR_DT_INCT_KPM IMPLEMENTATION.
  METHOD save_modified.
    DATA: lt_history_insert TYPE TABLE OF zdt_inct_h_kpm,
          lv_uuid           TYPE sysuuid_x16,
          lv_max_his_id     TYPE zdt_inct_h_kpm-his_id..
    GET TIME STAMP FIELD DATA(lv_timestamp).

    IF lcl_buffer=>mt_history_buffer IS NOT INITIAL.

      LOOP AT lcl_buffer=>mt_history_buffer INTO DATA(ls_buffer).

        " Verificamos si en la tabla temporal (lt_history_insert) ya hay un registro
        " para este mismo incidente en esta transacción y tomamos su ID
        LOOP AT lt_history_insert INTO DATA(ls_existing) WHERE inc_uuid = ls_buffer-inc_uuid.
          IF ls_existing-his_id > lv_max_his_id.
            lv_max_his_id = ls_existing-his_id.
          ENDIF.
        ENDLOOP.

        " 3. Si no encontramos nada en la tabla temporal, buscamos en la base de datos
        " filtrando EXCLUSIVAMENTE por el ID del incidente actual
        IF lv_max_his_id IS INITIAL.
          SELECT SINGLE MAX( his_id )
            FROM zdt_inct_h_kpm
            WHERE inc_uuid = @ls_buffer-inc_uuid
            INTO @lv_max_his_id.
        ENDIF.

        " 4. Aplicamos el incremento +1
        lv_max_his_id += 1.

        " 5. Generación de UUID
        TRY.
            lv_uuid = cl_system_uuid=>create_uuid_x16_static( ).
          CATCH cx_uuid_error.
        ENDTRY.

        " 6. Llenado de la tabla a insertar
        APPEND VALUE #( client                = sy-mandt
                        his_uuid              = lv_uuid
                        his_id                = lv_max_his_id
                        inc_uuid              = ls_buffer-inc_uuid
                        previous_status       = ls_buffer-old_status
                        new_status            = ls_buffer-new_status
                        observation           = ls_buffer-observation
                        local_created_by      = sy-uname
                        local_created_at      = lv_timestamp
                        local_last_changed_by = sy-uname
                        local_last_changed_at = lv_timestamp
                        last_changed_at       = lv_timestamp
                      ) TO lt_history_insert.
      ENDLOOP.

      " 7. Inserción en la base de datos
      INSERT zdt_inct_h_kpm FROM TABLE @lt_history_insert.

      " Limpiamos el buffer para evitar inserciones duplicadas en el futuro
      CLEAR lcl_buffer=>mt_history_buffer.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup_finalize.
    CLEAR lcl_buffer=>mt_history_buffer.
  ENDMETHOD.
ENDCLASS.
