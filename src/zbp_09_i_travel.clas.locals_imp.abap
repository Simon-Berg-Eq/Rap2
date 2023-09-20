CLASS lhc_item DEFINITION INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS determineSemanticKey FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Item~determineSemanticKey.
    METHODS validateFlightClass FOR VALIDATE ON SAVE
      IMPORTING keys FOR Item~validateFlightClass.

ENDCLASS.

CLASS lhc_item IMPLEMENTATION.

  METHOD determineSemanticKey.
* read semantic key data of all affected travel items
**********************************************************************
    read entity in local mode z09_i_travelitem
    fields ( agencyid travelid itemid )
    with corresponding #( keys )
    result data(lt_items).
* Loop over all affected travel items
**********************************************************************
    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
* Retrieve AgencyID and TravelID if not initial
**********************************************************************
      IF <ls_item>-agencyid IS INITIAL
      OR <ls_item>-travelid IS INITIAL.
        " Read parent entity data (travel)
        "for this child entity (travel item) by association
        READ ENTITY IN LOCAL MODE z09_i_travelitem
        BY \_travel FIELDS ( agencyid travelid )
        WITH VALUE #( ( %tky = <ls_item>-%tky ) )
        RESULT DATA(lt_travels).
        <ls_item>-agencyid = lt_travels[ 1 ]-agencyid.
        <ls_item>-travelid = lt_travels[ 1 ]-travelid.
      ENDIF.
* Retrieve ItemID if not initial
**********************************************************************
      IF <ls_item>-itemid IS INITIAL.
        " read all child entities (travel items)
        " assigned to the same parent entity (travel) by association
        READ ENTITY IN LOCAL MODE z09_i_travel
        BY \_travelitem FIELDS ( itemid )
        WITH VALUE #( ( %tky = lt_travels[ 1 ]-%tky ) )
        RESULT DATA(lt_other_items).
        " find maximum item number
        LOOP AT lt_other_items ASSIGNING FIELD-SYMBOL(<ls_other_item>).
          IF <ls_other_item>-itemid > <ls_item>-itemid.
            <ls_item>-itemid = <ls_other_item>-itemid.
          ENDIF.
        ENDLOOP.
        "
        <ls_item>-itemid = <ls_item>-itemid + 10.
      ENDIF.
    ENDLOOP.
* Update flight travel items with new data
**********************************************************************
    MODIFY ENTITY IN LOCAL MODE z09_i_travelitem
    UPDATE FIELDS ( agencyid travelid itemid )
    WITH CORRESPONDING #( lt_items ).
  ENDMETHOD.

  METHOD validateFlightClass.
    CONSTANTS c_area TYPE string VALUE `FLIGHTCLASS`.
    READ ENTITY IN LOCAL MODE z09_i_travelitem
    FIELDS ( flightclass trguid )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_items).
    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<ls_item>).
      APPEND VALUE #( %tky = <ls_item>-%tky
      %state_area = c_area )
      TO reported-item.
      IF <ls_item>-flightclass IS INITIAL.
        APPEND CORRESPONDING #( <ls_item> )
        TO failed-item.
        APPEND VALUE #(
        %tky = <ls_item>-%tky
        %element = VALUE #( flightclass = if_abap_behv=>mk-on )
        %msg = NEW cm_devs4d437(
         textid = cm_devs4d437=>field_empty
        severity = cm_devs4d437=>severity-error
        )
        %state_area = c_area
        %path = VALUE #( travel-%is_draft = <ls_item>-%is_draft
        travel-trguid = <ls_item>-trguid ) )
        TO reported-item.
      ELSE.
        "existence check for flight class
        SELECT SINGLE @abap_true
        FROM d437_i_flightclass
        WHERE flightclass = @<ls_item>-flightclass
        INTO @DATA(lv_exists)
        .
        IF lv_exists <> abap_true.
          APPEND CORRESPONDING #( <ls_item> )
          TO failed-item.
          APPEND VALUE #(
          %tky = <ls_item>-%tky
          %element = VALUE #( flightclass = if_abap_behv=>mk-on )
          %msg = NEW cm_devs4d437(
          textid = cm_devs4d437=>class_invalid
          severity = cm_devs4d437=>severity-error
          flightclass = <ls_item>-flightclass
          )
          %state_area = c_area
          %path = VALUE #( travel-%is_draft = <ls_item>-%is_draft
          travel-trguid = <ls_item>-trguid )
          )
          TO reported-item.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_authorizations FOR AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS set_to_cancelled FOR MODIFY
      IMPORTING keys FOR ACTION Travel~set_to_cancelled.
    METHODS validateCustomer FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateCustomer.
    METHODS validateStartDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateStartDate.
    METHODS validateEndDate FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateEndDate.
    METHODS validateSequence FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateSequence.
    METHODS determineSemanticKey FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~determineSemanticKey.
    METHODS get_features FOR FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.




  METHOD get_authorizations.
* if requested_authorizations-%update = if_abap_behv=>mk-on
* OR requested_authorizations-%action-set_to_cancelled = if_abap_behv=>mk-on.
    READ ENTITY IN LOCAL MODE z09_i_travel
    FIELDS ( AgencyID ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
      "Use simulation of different roles for different users
      DATA(lv_subrc) = cl_s4d437_model=>authority_check(
      EXPORTING
      iv_agencynum = <ls_travel>-agencyid
      iv_actvt = '02'
      ).
      IF lv_subrc <> 0.
        APPEND VALUE #( %tky = <ls_travel>-%tky
        %update = if_abap_behv=>auth-unauthorized
        %action-set_to_cancelled =
       if_abap_behv=>auth-unauthorized
        )
        TO result.
      ENDIF.
    ENDLOOP.


  ENDMETHOD.



  METHOD set_to_cancelled.


    READ ENTITY IN LOCAL MODE z09_i_travel
 ALL FIELDS WITH CORRESPONDING #( keys )
 RESULT DATA(gt_travel).

    LOOP AT gt_travel ASSIGNING FIELD-SYMBOL(<gs_travel>).
      IF <gs_travel>-status = 'C'. "already cancelled
        APPEND VALUE #( %tky = <gs_travel>-%tky
        %msg = NEW zcm_09_travel(
        textid = zcm_09_travel=>already_cancelled
        severity = if_abap_behv_message=>severity-error ) )
        TO reported-travel.

      ELSE.
        MODIFY ENTITY IN LOCAL MODE z09_i_travel
        UPDATE FIELDS ( status )
        WITH VALUE #(
        ( %tky = <gs_travel>-%tky
        status = 'C'
        )
        )
        FAILED DATA(gs_failed).

        IF gs_failed IS INITIAL.
          APPEND VALUE #( %tky = <gs_travel>-%tky
          %msg = NEW zcm_09_travel(
          textid =
         zcm_09_travel=>cancel_success
          severity =
         if_abap_behv_message=>severity-success
          )
          )
          TO reported-travel.
        ENDIF.


      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD validateCustomer.

* for message object
    DATA lo_msg TYPE REF TO cm_devs4d437.
* work areas for response parameters
    DATA ls_reported_travel LIKE LINE OF reported-travel.
    DATA ls_failed_travel LIKE LINE OF failed-travel.
* Constant for state area (needed for validation messages in draft)
    CONSTANTS c_state TYPE string VALUE `CUSTOMER`.

* read required data
**********************************************************************
    READ ENTITY IN LOCAL MODE z09_i_travel
    FIELDS ( customerid ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
* New for Draft: Add new line to to reported
* to delete previous messages of same state area
**********************************************************************
      CLEAR ls_reported_travel.
      MOVE-CORRESPONDING <ls_travel> TO ls_reported_travel.
      ls_reported_travel-%state_area = c_state .
      APPEND ls_reported_travel TO reported-travel.
      "expression-based alternative
* APPEND VALUE #( %tky = <ls_travel>-%tky
* %state_area = c_state )
* TO reported-travel.

* validate data and create message object in case of error
**********************************************************************
      IF <ls_travel>-customerid IS INITIAL.
        "error because of initial input field
        CREATE OBJECT lo_msg
          EXPORTING
            textid   = cm_devs4d437=>field_empty
            severity = cm_devs4d437=>severity-error.
      ELSE.
        "existence check for customer
        SELECT SINGLE @abap_true
        FROM d437_i_customer
        INTO @DATA(lv_exists)
        WHERE customer = @<ls_travel>-customerid.
        IF lv_exists <> abap_true.
          " error because of non-existent customer
          CREATE OBJECT lo_msg
            EXPORTING
              textid     = cm_devs4d437=>customer_not_exist
              customerid = <ls_travel>-customerid
              severity   = cm_devs4d437=>severity-error.
        ENDIF.
      ENDIF.
* report message and mark flight travel as failed
**********************************************************************
      IF lo_msg IS BOUND.
        CLEAR ls_failed_travel.
        MOVE-CORRESPONDING <ls_travel> TO ls_failed_travel.
        APPEND ls_failed_travel TO failed-travel.

        CLEAR ls_reported_travel.
        MOVE-CORRESPONDING <ls_travel> TO ls_reported_travel.
        ls_reported_travel-%element-customerid = if_abap_behv=>mk-on.
        ls_reported_travel-%msg = lo_msg.
        APPEND ls_reported_travel TO reported-travel.
        CLEAR lo_msg.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.



  METHOD validateStartDate.
    CONSTANTS c_area TYPE string VALUE `STARTDATE`.

    READ ENTITY IN LOCAL MODE z09_i_travel
    FIELDS ( startdate ) WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
      APPEND VALUE #( %tky = <ls_travel>-%tky
   %state_area = c_area )
   TO reported-travel.
      "Start Date
      "----------"
      IF <ls_travel>-startdate IS INITIAL.
        APPEND CORRESPONDING #( <ls_travel> )
        TO failed-travel.
        APPEND VALUE #(
        %tky = <ls_travel>-%tky
        %element = VALUE #( startdate = if_abap_behv=>mk-on )
        %msg = NEW zcm_09_travel(
        textid = cm_devs4d437=>field_empty
        severity = cm_devs4d437=>severity-error
        )
        %state_area = c_area    )

        TO reported-travel.
      ELSEIF <ls_travel>-startdate < sy-datum.
        " or use cl_abap_context_info=>get_system_date( )
        APPEND CORRESPONDING #( <ls_travel> )
        TO failed-travel.
        APPEND VALUE #(
        %tky = <ls_travel>-%tky
        %element = VALUE #( startdate = if_abap_behv=>mk-on )
        %msg = NEW zcm_09_travel(
        textid = cm_devs4d437=>start_date_past
        severity = cm_devs4d437=>severity-error
        )
        %state_area = c_area )
        TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateEndDate.
    CONSTANTS c_area TYPE string VALUE `ENDDATE`.
    READ ENTITY IN LOCAL MODE z09_i_travel
 FIELDS ( enddate ) WITH CORRESPONDING #( keys )
 RESULT DATA(lt_travel).
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).

      APPEND VALUE #( %tky = <ls_travel>-%tky
   %state_area = c_area )
   TO reported-travel.
      "End Date
      "----------"
      IF <ls_travel>-enddate IS INITIAL.
        APPEND CORRESPONDING #( <ls_travel> )
        TO failed-travel.
        APPEND VALUE #(
        %tky = <ls_travel>-%tky
        %element = VALUE #( enddate = if_abap_behv=>mk-on )
        %msg = NEW zcm_09_travel(
        textid = cm_devs4d437=>field_empty
        severity = cm_devs4d437=>severity-error
        )
         %state_area = c_area )
        TO reported-travel.
      ELSEIF <ls_travel>-enddate < sy-datum.
        " or use cl_abap_context_info=>get_system_date( )
        APPEND CORRESPONDING #( <ls_travel> )
        TO failed-travel.
        APPEND VALUE #(
        %tky = <ls_travel>-%tky
        %element = VALUE #( enddate = if_abap_behv=>mk-on )
        %msg = NEW zcm_09_travel(
        textid = cm_devs4d437=>end_date_past
        severity = cm_devs4d437=>severity-error
        )
        %state_area = c_area )
        TO reported-travel.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD validateSequence.
    CONSTANTS c_area TYPE string VALUE `SEQUENCE`.
    READ ENTITY IN LOCAL MODE z09_i_travel
 FIELDS ( startdate enddate ) WITH CORRESPONDING #( keys )
 RESULT DATA(lt_travel).
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
      APPEND VALUE #( %tky = <ls_travel>-%tky
   %state_area = c_area )
   TO reported-travel.
      "Sequence of Dates
      "-----------------"
      IF <ls_travel>-startdate IS INITIAL
      OR <ls_travel>-enddate IS INITIAL.
        " ignore empty fields, already covered above
      ELSEIF <ls_travel>-enddate < <ls_travel>-startdate.
        APPEND CORRESPONDING #( <ls_travel> )
        TO failed-travel.
        APPEND VALUE #(
        %tky = <ls_travel>-%tky
        %element = VALUE #( startdate = if_abap_behv=>mk-on
        enddate = if_abap_behv=>mk-on )
 %msg = NEW zcm_09_travel(
 textid = cm_devs4d437=>dates_wrong_sequence
 severity = cm_devs4d437=>severity-error
 )
 %state_area = c_area )
 TO reported-travel.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD determineSemanticKey.

DATA lt_travel_upd TYPE TABLE FOR UPDATE z09_i_travel.
* get AgencyID for all new travels
**********************************************************************
 DATA(lv_agencyid) =
 cl_s4d437_model=>get_agency_by_user(
* iv_user = SY-UNAME
* iv_user = cl_abap_context_info=>get_user_technical_name( )
 ).
* prepare input for MODIFY ENTITY
**********************************************************************
 lt_travel_upd = CORRESPONDING #( keys ).
 LOOP AT lt_travel_upd ASSIGNING FIELD-SYMBOL(<ls_travel_upd>).
 <ls_travel_upd>-agencyid = lv_agencyid.
 <ls_travel_upd>-travelid =
 cl_s4d437_model=>get_next_travelid_for_agency(
 iv_agencynum = lv_agencyid
 ).
 ENDLOOP.
* Update entities
**********************************************************************
 MODIFY ENTITY IN LOCAL MODE z09_i_travel
 UPDATE FIELDS ( agencyid travelid )
 WITH lt_travel_upd
 REPORTED DATA(ls_reported).
 MOVE-CORRESPONDING ls_reported-travel
 TO reported-travel.

  ENDMETHOD.

  METHOD get_features.
* work area for parameter result
    DATA ls_result LIKE LINE OF result.
* helper objects to shorten the code
    CONSTANTS c_enabled TYPE if_abap_behv=>t_xflag
    VALUE if_abap_behv=>fc-o-enabled.
    CONSTANTS c_disabled TYPE if_abap_behv=>t_xflag
    VALUE if_abap_behv=>fc-o-disabled.
    CONSTANTS c_read_only TYPE if_abap_behv=>t_xflag
    VALUE if_abap_behv=>fc-f-read_only.
    CONSTANTS c_mandatory TYPE if_abap_behv=>t_xflag
    VALUE if_abap_behv=>fc-f-mandatory.
    DATA lv_today TYPE cl_abap_context_info=>ty_system_date.
**********************************************************************
* Get system date
    lv_today = cl_abap_context_info=>get_system_date( ).
* Read data of all affected
    READ ENTITY IN LOCAL MODE z09_i_travel
    FIELDS ( status startdate enddate )
    WITH CORRESPONDING #( keys )
    RESULT DATA(lt_travel).
    LOOP AT lt_travel ASSIGNING FIELD-SYMBOL(<ls_travel>).
      ls_result-%tky = <ls_travel>-%tky.
* for draft: distinguish between active and draft
      IF <ls_travel>-%is_draft = if_abap_behv=>mk-off.
        " active instance
        ASSIGN <ls_travel> TO FIELD-SYMBOL(<ls_for_check>).
      ELSE.
        " draft instance
        READ ENTITY IN LOCAL MODE z09_i_travel
        FIELDS ( status startdate enddate )
        WITH VALUE #( ( %key = <ls_travel>-%key
        %is_draft = if_abap_behv=>mk-off
        ) )
        RESULT DATA(lt_travel_active).
        IF lt_travel_active IS INITIAL.
          " new draft
          ASSIGN <ls_travel> TO <ls_for_check>.
        ELSE.
          " edit draft
          READ TABLE lt_travel_active INDEX 1 ASSIGNING <ls_for_check>.
        ENDIF.
      ENDIF.
* Transfer complete key to result table
      ls_result-%tky = <ls_travel>-%tky.

* Dynamic action control
      IF <ls_travel>-status = 'C'. "already cancelled
        ls_result-%features-%action-set_to_cancelled = c_disabled.
      ELSEIF <ls_travel>-enddate IS NOT INITIAL
      AND <ls_travel>-enddate <= lv_today.
        ls_result-%features-%action-set_to_cancelled = c_disabled.
      ELSE.
        ls_result-%features-%action-set_to_cancelled = c_enabled.
      ENDIF.
* dynamic operation control (udpdate)
      IF <ls_travel>-status = 'C'. "already cancelled
        ls_result-%features-%update = c_disabled.
      ELSEIF <ls_travel>-enddate IS NOT INITIAL
      AND <ls_travel>-enddate <= lv_today.
        ls_result-%features-%update = c_disabled.
      ELSE.
        ls_result-%features-%update = c_enabled.
      ENDIF.
* dynamic field control (Customer, StartDate)
      IF <ls_travel>-startdate IS NOT INITIAL
      AND <ls_travel>-startdate <= lv_today.
        ls_result-%features-%field-startdate = c_read_only.
        ls_result-%features-%field-customerid = c_read_only.
      ELSE.
        ls_result-%features-%field-startdate = c_mandatory.
        ls_result-%features-%field-customerid = c_mandatory.
      ENDIF.
      APPEND ls_result TO result.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
