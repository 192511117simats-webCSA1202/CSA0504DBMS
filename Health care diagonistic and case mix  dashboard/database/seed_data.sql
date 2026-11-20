-- ============================================================================
-- HEALTHCARE DIAGNOSTIC RECORDS & CASE MIX (CMI) SYSTEM - SEED DATA
-- Generates realistic clinical, diagnostic, and case mix data
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. SEED DEPARTMENTS
-- ----------------------------------------------------------------------------
INSERT INTO departments (dept_id, dept_code, dept_name, target_cmi, bed_capacity) VALUES
(1, 'CARD', 'Cardiovascular Medicine & Surgery', 1.65, 45),
(2, 'NEUR', 'Neurology & Neurosurgery', 1.45, 35),
(3, 'ONCO', 'Medical & Surgical Oncology', 1.80, 50),
(4, 'ORTH', 'Orthopedic Surgery & Traumatology', 1.30, 40),
(5, 'PULM', 'Pulmonology & Critical Care', 1.50, 30),
(6, 'GSUR', 'General Surgery & Gastroenterology', 1.25, 40);

-- ----------------------------------------------------------------------------
-- 2. SEED PHYSICIANS
-- ----------------------------------------------------------------------------
INSERT INTO physicians (physician_id, license_no, first_name, last_name, specialty, dept_id, email, phone) VALUES
(1, 'MD-89211', 'Elena', 'Vance', 'Interventional Cardiology', 1, 'elena.vance@aegiscare.org', '+1-555-0101'),
(2, 'MD-89212', 'Marcus', 'Sterling', 'Cardiothoracic Surgery', 1, 'marcus.sterling@aegiscare.org', '+1-555-0102'),
(3, 'MD-74190', 'Amina', 'Khan', 'Vascular Neurology', 2, 'amina.khan@aegiscare.org', '+1-555-0103'),
(4, 'MD-74191', 'Julian', 'Ross', 'Neurosurgery', 2, 'julian.ross@aegiscare.org', '+1-555-0104'),
(5, 'MD-63201', 'Sophia', 'Chen', 'Hematology-Oncology', 3, 'sophia.chen@aegiscare.org', '+1-555-0105'),
(6, 'MD-63202', 'David', 'Kim', 'Surgical Oncology', 3, 'david.kim@aegiscare.org', '+1-555-0106'),
(7, 'MD-52870', 'Sarah', 'Jenkins', 'Joint Reconstruction', 4, 'sarah.jenkins@aegiscare.org', '+1-555-0107'),
(8, 'MD-52871', 'Carlos', 'Mendoza', 'Orthopedic Trauma', 4, 'carlos.mendoza@aegiscare.org', '+1-555-0108'),
(9, 'MD-41098', 'Rachel', 'Patel', 'Pulmonary Critical Care', 5, 'rachel.patel@aegiscare.org', '+1-555-0109'),
(10, 'MD-41099', 'Thomas', 'Wright', 'Sleep & Respiratory Medicine', 5, 'thomas.wright@aegiscare.org', '+1-555-0110'),
(11, 'MD-30981', 'Liam', 'O''Connor', 'Minimally Invasive Surgery', 6, 'liam.oconnor@aegiscare.org', '+1-555-0111'),
(12, 'MD-30982', 'Nia', 'Adebayo', 'Colorectal Surgery', 6, 'nia.adebayo@aegiscare.org', '+1-555-0112');

-- ----------------------------------------------------------------------------
-- 3. SEED DRG MASTER (CMS Diagnosis-Related Groups with Relative Weights)
-- ----------------------------------------------------------------------------
INSERT INTO drg_master (drg_id, drg_code, drg_title, mdc_code, relative_weight, geometric_mean_los, base_payment_rate, severity_level) VALUES
(1, 'MS-DRG 001', 'Heart Transplant or Implant of Heart Assist System', 'MDC 05: Circulatory System', 14.8520, 24.5, 95000.00, 'Extreme (MCC)'),
(2, 'MS-DRG 231', 'Coronary Bypass w/ PTCA or Stent w/ MCC', 'MDC 05: Circulatory System', 5.2140, 9.2, 38500.00, 'Extreme (MCC)'),
(3, 'MS-DRG 280', 'Acute Myocardial Infarction, Discharged Alive w/ MCC', 'MDC 05: Circulatory System', 1.8410, 4.8, 14200.00, 'Extreme (MCC)'),
(4, 'MS-DRG 291', 'Heart Failure and Shock w/ MCC', 'MDC 05: Circulatory System', 1.4820, 4.3, 11500.00, 'Extreme (MCC)'),
(5, 'MS-DRG 292', 'Heart Failure and Shock w/ CC', 'MDC 05: Circulatory System', 0.9850, 3.2, 7800.00, 'Major (CC)'),
(6, 'MS-DRG 061', 'Acute Ischemic Stroke w/ Use of Thrombolytic Agent w/ MCC', 'MDC 01: Nervous System', 3.4210, 6.5, 26000.00, 'Extreme (MCC)'),
(7, 'MS-DRG 064', 'Intracranial Hemorrhage or Cerebral Infarction w/ MCC', 'MDC 01: Nervous System', 1.9540, 5.1, 15300.00, 'Extreme (MCC)'),
(8, 'MS-DRG 065', 'Intracranial Hemorrhage or Cerebral Infarction w/ CC', 'MDC 01: Nervous System', 1.1230, 3.8, 8900.00, 'Major (CC)'),
(9, 'MS-DRG 871', 'Septicemia or Severe Sepsis w/o MV >96 Hours w/ MCC', 'MDC 18: Infectious Diseases', 1.9680, 5.4, 15500.00, 'Extreme (MCC)'),
(10, 'MS-DRG 872', 'Septicemia or Severe Sepsis w/o MV >96 Hours w/o MCC', 'MDC 18: Infectious Diseases', 1.0520, 3.6, 8400.00, 'Major (CC)'),
(11, 'MS-DRG 469', 'Major Hip and Knee Joint Replacement w/ MCC', 'MDC 08: Musculoskeletal', 2.8710, 5.8, 22500.00, 'Extreme (MCC)'),
(12, 'MS-DRG 470', 'Major Hip and Knee Joint Replacement w/o MCC', 'MDC 08: Musculoskeletal', 1.6240, 2.4, 13100.00, 'Moderate'),
(13, 'MS-DRG 535', 'Fractures of Hip and Pelvis w/ MCC', 'MDC 08: Musculoskeletal', 1.7450, 4.9, 13800.00, 'Extreme (MCC)'),
(14, 'MS-DRG 193', 'Simple Pneumonia and Pleurisy w/ MCC', 'MDC 04: Respiratory System', 1.3850, 4.6, 11000.00, 'Extreme (MCC)'),
(15, 'MS-DRG 194', 'Simple Pneumonia and Pleurisy w/ CC', 'MDC 04: Respiratory System', 0.9230, 3.4, 7300.00, 'Major (CC)'),
(16, 'MS-DRG 202', 'Bronchitis and Asthma w/ CC/MCC', 'MDC 04: Respiratory System', 0.8120, 2.9, 6400.00, 'Major (CC)'),
(17, 'MS-DRG 329', 'Major Small and Large Bowel Procedures w/ MCC', 'MDC 06: Digestive System', 4.1200, 8.8, 32000.00, 'Extreme (MCC)'),
(18, 'MS-DRG 330', 'Major Small and Large Bowel Procedures w/ CC', 'MDC 06: Digestive System', 2.1500, 5.2, 17200.00, 'Major (CC)'),
(19, 'MS-DRG 438', 'Malignancy, Male/Female Reproductive System w/ MCC', 'MDC 13: Female Reproductive', 2.3140, 6.1, 18400.00, 'Extreme (MCC)'),
(20, 'MS-DRG 841', 'Lymphoma and Non-Acute Leukemia w/ MCC', 'MDC 17: Myeloproliferative', 3.1200, 7.3, 24500.00, 'Extreme (MCC)'),
(21, 'MS-DRG 842', 'Lymphoma and Non-Acute Leukemia w/ CC', 'MDC 17: Myeloproliferative', 1.4500, 4.1, 11600.00, 'Major (CC)');

-- ----------------------------------------------------------------------------
-- 4. SEED DIAGNOSTIC TESTS CATALOG
-- ----------------------------------------------------------------------------
INSERT INTO diagnostic_tests (test_id, test_code, test_name, category, loinc_code, unit, normal_range_min, normal_range_max, critical_low, critical_high, standard_cost) VALUES
(1, 'LAB-TROP-I', 'Cardiac High-Sensitivity Troponin I', 'Biochemistry', '49563-0', 'ng/L', 0.00, 14.00, NULL, 50.00, 65.00),
(2, 'LAB-BNP', 'B-Type Natriuretic Peptide (BNP)', 'Biochemistry', '30934-4', 'pg/mL', 0.00, 100.00, NULL, 400.00, 85.00),
(3, 'LAB-CREAT', 'Serum Creatinine', 'Biochemistry', '2160-0', 'mg/dL', 0.70, 1.30, 0.40, 4.00, 35.00),
(4, 'LAB-BUN', 'Blood Urea Nitrogen (BUN)', 'Biochemistry', '3094-0', 'mg/dL', 7.00, 20.00, NULL, 60.00, 30.00),
(5, 'LAB-K', 'Serum Potassium', 'Biochemistry', '2823-3', 'mEq/L', 3.50, 5.10, 2.80, 6.20, 25.00),
(6, 'LAB-NA', 'Serum Sodium', 'Biochemistry', '2951-2', 'mEq/L', 135.00, 145.00, 120.00, 160.00, 25.00),
(7, 'LAB-WBC', 'White Blood Cell Count (WBC)', 'Hematology', '6690-2', 'x10^3/uL', 4.50, 11.00, 2.00, 25.00, 40.00),
(8, 'LAB-HGB', 'Hemoglobin (Hgb)', 'Hematology', '718-7', 'g/dL', 12.00, 17.50, 7.00, 20.00, 35.00),
(9, 'LAB-PLT', 'Platelet Count', 'Hematology', '777-3', 'x10^3/uL', 150.00, 450.00, 50.00, 900.00, 40.00),
(10, 'LAB-DDIM', 'D-Dimer Quantitative', 'Hematology', '48065-7', 'ug/mL FEU', 0.00, 0.50, NULL, 2.00, 75.00),
(11, 'LAB-LACT', 'Serum Lactic Acid / Lactate', 'Biochemistry', '2524-7', 'mmol/L', 0.50, 2.00, NULL, 4.00, 55.00),
(12, 'LAB-HBA1C', 'Hemoglobin A1c (HbA1c)', 'Biochemistry', '4548-4', '%', 4.00, 5.60, NULL, 10.00, 50.00),
(13, 'LAB-ALT', 'Alanine Aminotransferase (ALT)', 'Biochemistry', '1742-6', 'U/L', 7.00, 56.00, NULL, 300.00, 45.00),
(14, 'LAB-CRP', 'C-Reactive Protein (High Sensitivity)', 'Immunology', '30522-7', 'mg/L', 0.00, 3.00, NULL, 50.00, 48.00),
(15, 'LAB-PROCAL', 'Procalcitonin (PCT)', 'Biochemistry', '33959-8', 'ng/mL', 0.00, 0.10, NULL, 2.00, 90.00),
(16, 'RAD-CXR', 'Chest X-Ray (PA and Lateral)', 'Radiology', '36554-4', 'Report', NULL, NULL, NULL, NULL, 160.00),
(17, 'RAD-CT-CHEST', 'CT Angiography Chest w/ Contrast', 'Radiology', '36642-7', 'Report', NULL, NULL, NULL, NULL, 750.00),
(18, 'RAD-MRI-BRAIN', 'MRI Brain without/with Contrast', 'Radiology', '24725-4', 'Report', NULL, NULL, NULL, NULL, 1100.00),
(19, 'CARD-ECHO', 'Transthoracic Echocardiogram (2D)', 'Cardiology Diagnostics', '34552-0', 'Report', NULL, NULL, NULL, NULL, 650.00),
(20, 'MIC-BCX', 'Blood Culture (Aerobic & Anaerobic)', 'Microbiology', '600-7', 'Culture', NULL, NULL, NULL, NULL, 110.00);

-- ----------------------------------------------------------------------------
-- 5. SEED PATIENTS (Demographics & Insurance)
-- ----------------------------------------------------------------------------
INSERT INTO patients (patient_id, mrn, first_name, last_name, dob, gender, blood_group, contact_phone, email, address, insurance_provider, policy_no) VALUES
(1, 'MRN-88001', 'Arthur', 'Pendelton', '1958-03-14', 'Male', 'O+', '+1-555-1001', 'arthur.p@gmail.com', '742 Evergreen Terrace, Springfield', 'Medicare Part A/B', 'MED-9812-A'),
(2, 'MRN-88002', 'Beatrice', 'Holloway', '1964-07-22', 'Female', 'A+', '+1-555-1002', 'bholloway@outlook.com', '1204 Elm Court, Riverdale', 'BlueCross BlueShield', 'BCBS-449102'),
(3, 'MRN-88003', 'Clarence', 'Darrow', '1951-11-05', 'Male', 'B-', '+1-555-1003', 'clarence.d@yahoo.com', '55 Lincoln Blvd, Oakridge', 'Medicare Advantage', 'MED-6619-C'),
(4, 'MRN-88004', 'Diana', 'Prince', '1979-05-18', 'Female', 'O-', '+1-555-1004', 'diana.p@themyscira.net', '88 Paradise Way, Coast City', 'UnitedHealthcare', 'UHC-881290'),
(5, 'MRN-88005', 'Edward', 'Nygma', '1970-09-30', 'Male', 'AB+', '+1-555-1005', 'e.nygma@puzzlecorp.org', '13 Riddle Lane, Gotham', 'Aetna Health', 'AET-771822'),
(6, 'MRN-88006', 'Fiona', 'Gallagher', '1988-01-12', 'Female', 'A-', '+1-555-1006', 'fiona.g@southside.edu', '2119 Wallace St, Chicago', 'Medicaid State Plan', 'MCD-110293'),
(7, 'MRN-88007', 'George', 'Burdell', '1946-04-16', 'Male', 'O+', '+1-555-1007', 'gburdell@gatech.edu', '225 North Ave NW, Atlanta', 'Medicare Part A/B', 'MED-5509-B'),
(8, 'MRN-88008', 'Helena', 'Wayne', '1982-08-27', 'Female', 'B+', '+1-555-1008', 'helena.w@wayne-ent.com', '1007 Mountain Drive, Gotham', 'Cigna Health', 'CGN-490183'),
(9, 'MRN-88009', 'Isaac', 'Newton', '1961-12-25', 'Male', 'AB-', '+1-555-1009', 'isaac.gravity@cambridge.org', '42 Principia Rd, Woolsthorpe', 'Humana Choice', 'HUM-902811'),
(10, 'MRN-88010', 'Judith', 'Resnik', '1975-04-05', 'Female', 'O+', '+1-555-1010', 'j.resnik@aerospace.gov', '300 Orbital Way, Houston', 'BlueCross BlueShield', 'BCBS-771239'),
(11, 'MRN-88011', 'Kenneth', 'Branagh', '1959-12-10', 'Male', 'A+', '+1-555-1011', 'k.branagh@theatre.uk', '16 Avon Crescent, Stratford', 'Medicare Advantage', 'MED-3341-X'),
(12, 'MRN-88012', 'Loretta', 'Young', '1967-02-14', 'Female', 'B+', '+1-555-1012', 'loretta.y@cinema.com', '500 Sunset Blvd, Hollywood', 'Kaiser Permanente', 'KP-882910'),
(13, 'MRN-88013', 'Miles', 'Davis', '1955-05-26', 'Male', 'O+', '+1-555-1013', 'miles.blue@jazzville.org', '77 Kind of Blue St, New York', 'Medicare Part A/B', 'MED-7190-Z'),
(14, 'MRN-88014', 'Nadia', 'Comaneci', '1981-11-12', 'Female', 'A+', '+1-555-1014', 'nadia.c@gymnastics.org', '10 Perfect Ten Ave, Montreal', 'UnitedHealthcare', 'UHC-664411'),
(15, 'MRN-88015', 'Oscar', 'Wilde', '1953-10-16', 'Male', 'AB+', '+1-555-1015', 'oscar.w@earnest.ie', '34 Tite Street, Chelsea', 'Aetna Health', 'AET-550912'),
(16, 'MRN-88016', 'Patricia', 'Highsmith', '1972-01-19', 'Female', 'O-', '+1-555-1016', 'pat.highsmith@novels.ch', '88 Riparian Way, Locarno', 'Cigna Health', 'CGN-109283'),
(17, 'MRN-88017', 'Quentin', 'Tarantino', '1963-03-27', 'Male', 'B-', '+1-555-1017', 'q.tarantino@pulpfilms.com', '405 Freeway Vista, Los Angeles', 'BlueCross BlueShield', 'BCBS-991823'),
(18, 'MRN-88018', 'Rosalind', 'Franklin', '1968-07-25', 'Female', 'A-', '+1-555-1018', 'r.franklin@crystallography.org', '12 Double Helix Way, London', 'UnitedHealthcare', 'UHC-440192'),
(19, 'MRN-88019', 'Salvador', 'Dali', '1950-05-11', 'Male', 'O+', '+1-555-1019', 's.dali@surreal.es', '99 Melting Clock Ln, Cadaques', 'Medicare Advantage', 'MED-8899-K'),
(20, 'MRN-88020', 'Teresa', 'Palacios', '1985-09-08', 'Female', 'B+', '+1-555-1020', 't.palacios@biomed.edu', '44 Horizon Plaza, Austin', 'Medicaid State Plan', 'MCD-990184');

-- ----------------------------------------------------------------------------
-- 6. SEED ADMISSIONS (Historical Discharged + Inpatients)
-- ----------------------------------------------------------------------------
INSERT INTO admissions (admission_id, admission_no, patient_id, dept_id, attending_physician_id, admission_date, discharge_date, admission_type, admission_source, discharge_disposition, assigned_drg_id, total_charges, los_days, status) VALUES
(1, 'ADM-2024-001', 1, 1, 1, '2024-01-10 08:30:00', '2024-01-15 14:00:00', 'Emergency', 'Emergency Department', 'Home', 4, 14200.00, 5, 'Discharged'),
(2, 'ADM-2024-002', 2, 1, 2, '2024-01-12 10:15:00', '2024-01-22 11:30:00', 'Urgent', 'Physician Referral', 'Home', 2, 42800.00, 10, 'Discharged'),
(3, 'ADM-2024-003', 3, 2, 3, '2024-01-15 14:45:00', '2024-01-21 16:00:00', 'Emergency', 'Emergency Department', 'Rehabilitation', 6, 28900.00, 6, 'Discharged'),
(4, 'ADM-2024-004', 4, 4, 7, '2024-01-18 07:00:00', '2024-01-21 12:00:00', 'Elective', 'Outpatient Clinic', 'Home', 12, 15400.00, 3, 'Discharged'),
(5, 'ADM-2024-005', 5, 5, 9, '2024-01-20 18:20:00', '2024-01-25 10:00:00', 'Emergency', 'Emergency Department', 'Home', 14, 12600.00, 5, 'Discharged'),
(6, 'ADM-2024-006', 6, 6, 11, '2024-01-22 09:10:00', '2024-01-28 15:30:00', 'Urgent', 'Transfer from Other Hospital', 'Home', 18, 19800.00, 6, 'Discharged'),
(7, 'ADM-2024-007', 7, 3, 5, '2024-01-25 11:00:00', '2024-02-02 10:45:00', 'Elective', 'Outpatient Clinic', 'Home', 20, 27600.00, 8, 'Discharged'),
(8, 'ADM-2024-008', 8, 1, 1, '2024-01-28 13:30:00', '2024-02-01 11:00:00', 'Emergency', 'Emergency Department', 'Home', 3, 16100.00, 4, 'Discharged'),
(9, 'ADM-2024-009', 9, 2, 4, '2024-02-01 16:00:00', '2024-02-07 14:00:00', 'Emergency', 'Emergency Department', 'Skilled Nursing', 7, 18200.00, 6, 'Discharged'),
(10, 'ADM-2024-010', 10, 5, 9, '2024-02-03 08:45:00', '2024-02-09 17:00:00', 'Emergency', 'Emergency Department', 'Home', 9, 21400.00, 6, 'Discharged'),
(11, 'ADM-2024-011', 11, 4, 8, '2024-02-05 12:20:00', '2024-02-11 11:30:00', 'Trauma', 'Emergency Department', 'Rehabilitation', 13, 17800.00, 6, 'Discharged'),
(12, 'ADM-2024-012', 12, 1, 2, '2024-02-10 07:30:00', '2024-02-13 14:00:00', 'Elective', 'Physician Referral', 'Home', 5, 9200.00, 3, 'Discharged'),
(13, 'ADM-2024-013', 13, 6, 12, '2024-02-14 15:10:00', '2024-02-24 16:45:00', 'Emergency', 'Emergency Department', 'Home', 17, 36500.00, 10, 'Discharged'),
(14, 'ADM-2024-014', 14, 4, 7, '2024-02-18 08:00:00', '2024-02-21 11:15:00', 'Elective', 'Outpatient Clinic', 'Home', 12, 14900.00, 3, 'Discharged'),
(15, 'ADM-2024-015', 15, 3, 6, '2024-02-20 10:30:00', '2024-02-27 13:00:00', 'Urgent', 'Physician Referral', 'Home', 19, 21100.00, 7, 'Discharged'),
(16, 'ADM-2024-016', 16, 5, 10, '2024-02-22 19:40:00', '2024-02-25 15:20:00', 'Emergency', 'Emergency Department', 'Home', 16, 7400.00, 3, 'Discharged'),
(17, 'ADM-2024-017', 17, 2, 3, '2024-02-25 04:15:00', '2024-03-01 12:00:00', 'Emergency', 'Emergency Department', 'Home', 8, 10300.00, 4, 'Discharged'),
(18, 'ADM-2024-018', 18, 3, 5, '2024-03-01 09:00:00', '2024-03-06 14:00:00', 'Elective', 'Physician Referral', 'Home', 21, 13400.00, 5, 'Discharged'),
(19, 'ADM-2024-019', 19, 1, 1, '2024-03-05 11:20:00', '2024-03-10 16:30:00', 'Emergency', 'Emergency Department', 'Home', 4, 13800.00, 5, 'Discharged'),
(20, 'ADM-2024-020', 20, 5, 9, '2024-03-08 14:50:00', '2024-03-12 11:00:00', 'Urgent', 'Outpatient Clinic', 'Home', 15, 8700.00, 4, 'Discharged'),
-- Active Inpatients currently admitted
(21, 'ADM-2024-021', 1, 1, 1, '2024-03-15 08:00:00', NULL, 'Emergency', 'Emergency Department', 'Inpatient (Active)', 3, 9800.00, 0, 'Admitted'),
(22, 'ADM-2024-022', 3, 2, 4, '2024-03-16 11:30:00', NULL, 'Urgent', 'Transfer from Other Hospital', 'Inpatient (Active)', 7, 12400.00, 0, 'Admitted'),
(23, 'ADM-2024-023', 5, 3, 5, '2024-03-17 14:15:00', NULL, 'Elective', 'Outpatient Clinic', 'Inpatient (Active)', 20, 16500.00, 0, 'Admitted'),
(24, 'ADM-2024-024', 8, 1, 2, '2024-03-18 09:45:00', NULL, 'Emergency', 'Emergency Department', 'Inpatient (Active)', 2, 29000.00, 0, 'Admitted'),
(25, 'ADM-2024-025', 10, 5, 9, '2024-03-19 16:20:00', NULL, 'Emergency', 'Emergency Department', 'Inpatient (Active)', 9, 8900.00, 0, 'Admitted');

-- Update reimbursement_amount for seeded rows based on DRG Relative Weight * Base Payment Rate
UPDATE admissions 
SET reimbursement_amount = (
    SELECT ROUND(relative_weight * base_payment_rate, 2)
    FROM drg_master
    WHERE drg_master.drg_id = admissions.assigned_drg_id
)
WHERE assigned_drg_id IS NOT NULL;

-- ----------------------------------------------------------------------------
-- 7. SEED CLINICAL DIAGNOSES (ICD-10)
-- ----------------------------------------------------------------------------
INSERT INTO diagnoses (admission_id, icd10_code, diagnosis_description, diagnosis_type, present_on_admission, diagnosed_date) VALUES
(1, 'I50.9', 'Heart failure, unspecified', 'Principal', 'Y', '2024-01-10'),
(1, 'I10', 'Essential (primary) hypertension', 'Comorbidity (CC)', 'Y', '2024-01-10'),
(1, 'N18.3', 'Chronic kidney disease, stage 3', 'Major Comorbidity (MCC)', 'Y', '2024-01-11'),
(2, 'I25.10', 'Atherosclerotic heart disease of native coronary artery', 'Principal', 'Y', '2024-01-12'),
(2, 'E11.9', 'Type 2 diabetes mellitus without complications', 'Comorbidity (CC)', 'Y', '2024-01-12'),
(2, 'I21.09', 'ST elevation (STEMI) myocardial infarction anterior wall', 'Major Comorbidity (MCC)', 'Y', '2024-01-12'),
(3, 'I63.9', 'Cerebral infarction, unspecified', 'Principal', 'Y', '2024-01-15'),
(3, 'G40.909', 'Epilepsy, unspecified, not intractable', 'Comorbidity (CC)', 'Y', '2024-01-16'),
(4, 'M16.11', 'Primary osteoarthritis, right hip', 'Principal', 'Y', '2024-01-18'),
(5, 'J18.9', 'Pneumonia, unspecified organism', 'Principal', 'Y', '2024-01-20'),
(5, 'J44.1', 'Chronic obstructive pulmonary disease w/ acute exacerbation', 'Major Comorbidity (MCC)', 'Y', '2024-01-20'),
(6, 'K56.60', 'Unspecified intestinal obstruction', 'Principal', 'Y', '2024-01-22'),
(7, 'C85.90', 'Non-Hodgkin lymphoma, unspecified', 'Principal', 'Y', '2024-01-25'),
(8, 'I21.4', 'Non-ST elevation (NSTEMI) myocardial infarction', 'Principal', 'Y', '2024-01-28'),
(9, 'I61.9', 'Nontraumatic intracerebral hemorrhage, unspecified', 'Principal', 'Y', '2024-02-01'),
(10, 'A41.9', 'Sepsis, unspecified organism', 'Principal', 'Y', '2024-02-03'),
(10, 'R65.20', 'Severe sepsis without septic shock', 'Major Comorbidity (MCC)', 'Y', '2024-02-03'),
(11, 'S72.001A', 'Fracture of head of right femur, initial encounter', 'Principal', 'Y', '2024-02-05'),
(12, 'I50.22', 'Chronic systolic (congestive) heart failure', 'Principal', 'Y', '2024-02-10'),
(13, 'K57.32', 'Diverticulitis of large intestine w/ perforation', 'Principal', 'Y', '2024-02-14'),
(14, 'M17.11', 'Primary osteoarthritis, right knee', 'Principal', 'Y', '2024-02-18'),
(15, 'C50.911', 'Malignant neoplasm of unspecified site of right female breast', 'Principal', 'Y', '2024-02-20'),
(16, 'J45.901', 'Unspecified asthma with (acute) exacerbation', 'Principal', 'Y', '2024-02-22'),
(17, 'I67.82', 'Cerebral ischemia', 'Principal', 'Y', '2024-02-25'),
(18, 'C91.00', 'Acute lymphoblastic leukemia not having achieved remission', 'Principal', 'Y', '2024-03-01'),
(19, 'I50.33', 'Acute on chronic diastolic (congestive) heart failure', 'Principal', 'Y', '2024-03-05'),
(20, 'J15.9', 'Bacterial pneumonia, unspecified', 'Principal', 'Y', '2024-03-08'),
(21, 'I21.1', 'ST elevation (STEMI) myocardial infarction of inferior wall', 'Principal', 'Y', '2024-03-15'),
(22, 'I60.9', 'Nontraumatic subarachnoid hemorrhage, unspecified', 'Principal', 'Y', '2024-03-16'),
(23, 'C90.00', 'Multiple myeloma not having achieved remission', 'Principal', 'Y', '2024-03-17'),
(24, 'I25.110', 'Atherosclerotic heart disease of native coronary artery w/ angina', 'Principal', 'Y', '2024-03-18'),
(25, 'A41.51', 'Escherichia coli sepsis', 'Principal', 'Y', '2024-03-19');

-- ----------------------------------------------------------------------------
-- 8. SEED PROCEDURES (CPT)
-- ----------------------------------------------------------------------------
INSERT INTO procedures (procedure_id, admission_id, cpt_code, procedure_name, procedure_date, performing_physician_id, procedure_cost) VALUES
(1, 2, '33533', 'Coronary artery bypass, single arterial graft', '2024-01-14 09:00:00', 2, 28500.00),
(2, 3, '37195', 'Thrombolysis, cerebral, intravenous infusion', '2024-01-15 16:30:00', 4, 9800.00),
(3, 4, '27130', 'Total hip arthroplasty (replacement)', '2024-01-19 08:30:00', 7, 12500.00),
(4, 8, '92928', 'Percutaneous transcatheter placement of intracoronary stent', '2024-01-29 10:00:00', 1, 11200.00),
(5, 11, '27236', 'Open treatment of femoral fracture, proximal end', '2024-02-06 14:00:00', 8, 14000.00),
(6, 13, '44140', 'Colectomy, partial; with anastomosis', '2024-02-15 11:00:00', 12, 22400.00),
(7, 14, '27447', 'Total knee arthroplasty (replacement)', '2024-02-19 08:00:00', 7, 11800.00),
(8, 24, '92928', 'Percutaneous transcatheter coronary stent placement', '2024-03-18 13:00:00', 2, 11500.00);

-- ----------------------------------------------------------------------------
-- 9. SEED DIAGNOSTIC RECORDS & LAB RESULTS
-- ----------------------------------------------------------------------------
-- Admission 1 (Heart Failure)
INSERT INTO diagnostic_records (admission_id, test_id, ordered_by_physician_id, order_date, result_date, numeric_result, flag, reference_range_display, interpretation_notes, verified_by, status) VALUES
(1, 1, 1, '2024-01-10 09:00:00', '2024-01-10 10:15:00', 18.5, 'HIGH', 'ng/L (0.0 - 14.0)', 'Mild myocardial injury; serial troponin indicated', 'Lab Lead Tech', 'Completed'),
(1, 2, 1, '2024-01-10 09:00:00', '2024-01-10 10:20:00', 680.0, 'CRITICAL', 'pg/mL (0.0 - 100.0)', 'Severe ventricular strain; acute decompensated heart failure confirmed', 'Lab Lead Tech', 'Completed'),
(1, 3, 1, '2024-01-10 09:00:00', '2024-01-10 10:10:00', 1.85, 'HIGH', 'mg/dL (0.7 - 1.3)', 'Cardiorenal syndrome staging; renal function diminished', 'Lab Lead Tech', 'Completed'),
(1, 5, 1, '2024-01-10 09:00:00', '2024-01-10 10:10:00', 4.8, 'NORMAL', 'mEq/L (3.5 - 5.1)', 'Within acceptable range', 'Lab Lead Tech', 'Completed'),
(1, 16, 1, '2024-01-10 09:30:00', '2024-01-10 11:00:00', NULL, 'NORMAL', 'Report', 'Bilateral pulmonary vascular congestion, cardiomegaly present', 'Dr. S. Vance (Radiology)', 'Completed'),
(1, 19, 1, '2024-01-11 14:00:00', '2024-01-11 15:30:00', NULL, 'NORMAL', 'Report', 'LVEF 35%, moderate mitral regurgitation, dilated left atrium', 'Dr. E. Vance', 'Completed');

-- Admission 2 (Coronary Bypass / STEMI)
INSERT INTO diagnostic_records (admission_id, test_id, ordered_by_physician_id, order_date, result_date, numeric_result, flag, reference_range_display, interpretation_notes, verified_by, status) VALUES
(2, 1, 2, '2024-01-12 10:30:00', '2024-01-12 11:15:00', 142.0, 'CRITICAL', 'ng/L (0.0 - 14.0)', 'Acute extensive myocardial infarction; immediate cath lab alerted', 'Lab Lead Tech', 'Completed'),
(2, 8, 2, '2024-01-12 10:30:00', '2024-01-12 11:05:00', 11.2, 'LOW', 'g/dL (12.0 - 17.5)', 'Mild anemia noted pre-op', 'Lab Lead Tech', 'Completed'),
(2, 12, 2, '2024-01-12 10:30:00', '2024-01-12 11:45:00', 8.2, 'HIGH', '% (4.0 - 5.6)', 'Poor glycaemic control, secondary diabetes management', 'Lab Lead Tech', 'Completed'),
(2, 17, 2, '2024-01-13 08:00:00', '2024-01-13 09:30:00', NULL, 'NORMAL', 'Report', 'Three vessel coronary disease; proximal LAD 90% stenosis', 'Dr. M. Sterling', 'Completed');

-- Admission 3 (Stroke / Neuro)
INSERT INTO diagnostic_records (admission_id, test_id, ordered_by_physician_id, order_date, result_date, numeric_result, flag, reference_range_display, interpretation_notes, verified_by, status) VALUES
(3, 18, 3, '2024-01-15 15:00:00', '2024-01-15 16:15:00', NULL, 'NORMAL', 'Report', 'Acute MCA territory infarction right hemisphere, no hemorrhage', 'Dr. J. Ross (Neuro)', 'Completed'),
(3, 6, 3, '2024-01-15 15:10:00', '2024-01-15 15:55:00', 133.0, 'LOW', 'mEq/L (135.0 - 145.0)', 'Mild hyponatremia', 'Lab Lead Tech', 'Completed'),
(3, 9, 3, '2024-01-15 15:10:00', '2024-01-15 15:55:00', 210.0, 'NORMAL', 'x10^3/uL (150.0 - 450.0)', 'Adequate platelet count for thrombolytic administration', 'Lab Lead Tech', 'Completed');

-- Admission 4 (Hip Replacement)
INSERT INTO diagnostic_records (admission_id, test_id, ordered_by_physician_id, order_date, result_date, numeric_result, flag, reference_range_display, interpretation_notes, verified_by, status) VALUES
(4, 7, 7, '2024-01-18 07:30:00', '2024-01-18 08:15:00', 6.4, 'NORMAL', 'x10^3/uL (4.5 - 11.0)', 'Pre-operative normal baseline', 'Lab Lead Tech', 'Completed'),
(4, 8, 7, '2024-01-18 07:30:00', '2024-01-18 08:15:00', 13.8, 'NORMAL', 'g/dL (12.0 - 17.5)', 'Baseline normal', 'Lab Lead Tech', 'Completed'),
(4, 8, 7, '2024-01-20 06:30:00', '2024-01-20 07:30:00', 9.8, 'LOW', 'g/dL (12.0 - 17.5)', 'Post-operative hemoglobin drop expected; stable', 'Lab Lead Tech', 'Completed');

-- Admission 5 (Pneumonia)
INSERT INTO diagnostic_records (admission_id, test_id, ordered_by_physician_id, order_date, result_date, numeric_result, flag, reference_range_display, interpretation_notes, verified_by, status) VALUES
(5, 7, 9, '2024-01-20 18:45:00', '2024-01-20 19:30:00', 17.8, 'HIGH', 'x10^3/uL (4.5 - 11.0)', 'Marked leukocytosis with left shift, active bacterial infection', 'Lab Lead Tech', 'Completed'),
(5, 14, 9, '2024-01-20 18:45:00', '2024-01-20 19:35:00', 68.0, 'CRITICAL', 'mg/L (0.0 - 3.0)', 'Severe systemic inflammatory response', 'Lab Lead Tech', 'Completed'),
(5, 16, 9, '2024-01-20 19:00:00', '2024-01-20 20:00:00', NULL, 'NORMAL', 'Report', 'Dense right middle lobe consolidation consistent with lobar pneumonia', 'Dr. R. Patel', 'Completed');

-- Admission 10 (Sepsis w/ MCC)
INSERT INTO diagnostic_records (admission_id, test_id, ordered_by_physician_id, order_date, result_date, numeric_result, flag, reference_range_display, interpretation_notes, verified_by, status) VALUES
(10, 11, 9, '2024-02-03 09:00:00', '2024-02-03 09:40:00', 4.8, 'CRITICAL', 'mmol/L (0.5 - 2.0)', 'Critical lactic acidosis; tissue hypoperfusion', 'Lab Lead Tech', 'Completed'),
(10, 15, 9, '2024-02-03 09:00:00', '2024-02-03 10:15:00', 8.4, 'CRITICAL', 'ng/mL (0.0 - 0.1)', 'Profound bacterial sepsis confirmed', 'Lab Lead Tech', 'Completed'),
(10, 20, 9, '2024-02-03 09:15:00', '2024-02-05 14:00:00', NULL, 'CRITICAL', 'Culture', 'Gram-negative bacilli isolated: Escherichia coli sensitive to Ceftriaxone', 'Microbiology Lab', 'Completed');

-- Admission 21 (Active Inpatient - STEMI)
INSERT INTO diagnostic_records (admission_id, test_id, ordered_by_physician_id, order_date, result_date, numeric_result, flag, reference_range_display, interpretation_notes, verified_by, status) VALUES
(21, 1, 1, '2024-03-15 08:30:00', '2024-03-15 09:15:00', 84.5, 'CRITICAL', 'ng/L (0.0 - 14.0)', 'Elevated troponin post percutaneous intervention', 'Lab Lead Tech', 'Completed'),
(21, 3, 1, '2024-03-15 08:30:00', '2024-03-15 09:15:00', 1.45, 'HIGH', 'mg/dL (0.7 - 1.3)', 'Borderline post-contrast nephropathy risk', 'Lab Lead Tech', 'Completed'),
(21, 19, 1, '2024-03-16 10:00:00', NULL, NULL, 'PENDING', 'Report', 'Repeat echo scheduled for discharge assessment', NULL, 'Ordered');

-- Admission 25 (Active Inpatient - Sepsis)
INSERT INTO diagnostic_records (admission_id, test_id, ordered_by_physician_id, order_date, result_date, numeric_result, flag, reference_range_display, interpretation_notes, verified_by, status) VALUES
(25, 7, 9, '2024-03-19 16:45:00', '2024-03-19 17:30:00', 22.4, 'CRITICAL', 'x10^3/uL (4.5 - 11.0)', 'High-grade leukocytosis; IV broad-spectrum antibiotics commenced', 'Lab Lead Tech', 'Completed'),
(25, 11, 9, '2024-03-19 16:45:00', '2024-03-19 17:30:00', 3.6, 'HIGH', 'mmol/L (0.5 - 2.0)', 'Elevated lactate; resuscitation protocol ongoing', 'Lab Lead Tech', 'Completed'),
(25, 20, 9, '2024-03-19 17:00:00', NULL, NULL, 'PENDING', 'Culture', 'Blood cultures incubating (Day 1)', NULL, 'Processing');

-- ----------------------------------------------------------------------------
-- 10. AUDIT LOG SEEDING (Demonstrating DBMS Auditing)
-- ----------------------------------------------------------------------------
INSERT INTO cmi_audit_log (action_type, table_name, record_id, description, created_at) VALUES
('SYSTEM_INITIALIZE', 'system', 0, 'Database initialized with standard CMS MS-DRG v41 definitions and test catalog', '2024-01-01 00:00:00'),
('TRIGGER_EVALUATION', 'diagnostic_records', 1, 'Automated lab result evaluation trigger fired: record_id 1 flagged as HIGH', '2024-01-10 10:15:00'),
('TRIGGER_EVALUATION', 'diagnostic_records', 2, 'Automated lab result evaluation trigger fired: record_id 2 flagged as CRITICAL (Value: 680.0 pg/mL)', '2024-01-10 10:20:00'),
('PATIENT_DISCHARGE', 'admissions', 1, 'Admission ADM-2024-001 discharged. Total LOS: 5 days. DRG: MS-DRG 291 (Heart Failure w/ MCC)', '2024-01-15 14:00:00'),
('PATIENT_DISCHARGE', 'admissions', 2, 'Admission ADM-2024-002 discharged. Total LOS: 10 days. DRG: MS-DRG 231 (Coronary Bypass w/ MCC)', '2024-01-22 11:30:00');
