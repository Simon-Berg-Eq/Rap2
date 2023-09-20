*&---------------------------------------------------------------------*
*& Report d437b_eml_s1
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT z09_eml_1 MESSAGE-ID devs4d437.

PARAMETERS pa_guid TYPE s_trguid DEFAULT '005056044E851EDE95BF7F742F050968'.
PARAMETERS pa_stat TYPE s_status VALUE CHECK.

* Data declarations for read access
DATA gt_read_import TYPE TABLE FOR READ IMPORT z09_i_travel.
DATA gt_read_result TYPE TABLE FOR READ RESULT z09_i_travel.
DATA gt_text TYPE TABLE FOR CREATE z09_i_travel.
DATA gs_text TYPE STRUCTURE FOR CREATE z09_i_travel.
DATA gs_failed TYPE RESPONSE FOR FAILED z09_i_travel.
DATA gs_failed_late TYPE RESPONSE FOR FAILED LATE z09_i_travel.
DATA gt_update_import TYPE TABLE FOR UPDATE z09_i_travel.
*DATA gs_reported.
* Data declarations for update access

* Data declarations for response


START-OF-SELECTION.

  APPEND VALUE #( trguid = pa_guid ) TO gt_read_import.
*  APPEND VALUE #( trguid = pa_guid status = pa_stat ) TO gt_update_import.

* Read the RAP BO entity to check for current status
*---------------------------------------------------*
  READ ENTITIES OF Z09_I_TRAVEL
    ENTITY Z09_I_TRAVEL
        ALL FIELDS WITH gt_read_import
        RESULT gt_read_result
        FAILED gs_failed.

* Update RAP BO with new status
*-------------------------------*
APPEND VALUE #( trguid = pa_guid status = pa_stat ) TO gt_update_import.
  MODIFY ENTITIES OF Z09_I_TRAVEL
    ENTITY z09_i_travel
        UPDATE
            FIELDS ( status ) WITH gt_update_import
         "RESULT gt_read_result
         FAILED gs_failed
         REPORTED DATA(gs_reported).

  WRITE: / 'Status of instance', pa_guid, 'successfully set to', pa_stat.
