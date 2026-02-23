-- -------------------------------------------------------------------
-- UPMC EPIC Database INSERT
-- -------------------------------------------------------------------

INSERT INTO fictitious_epic_training_db.patient_encounter_demo (
    patient_demo_id,
    patient_full_name,
    date_of_birth,
    medical_record_number,
    encounter_id,
    encounter_type,
    attending_provider,
    department_name,
    encounter_start_ts,
    encounter_end_ts,
    encounter_status,
    created_by_system,
    created_timestamp
) VALUES (
    'DEMO-PAT-000123',
    'Jane Q. Example',
    '1985-04-17',
    'MRN-DEMO-456789',
    'ENC-DEMO-20260223-01',
    'Outpatient Visit',
    'Dr. Alex Sample, MD',
    'General Internal Medicine',
    '2026-02-23 09:15:00',
    '2026-02-23 10:05:00',
    'COMPLETED',
    'TRAINING_SIMULATOR',
    CURRENT_TIMESTAMP
);
