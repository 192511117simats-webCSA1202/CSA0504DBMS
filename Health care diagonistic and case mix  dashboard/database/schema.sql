-- ============================================================================
-- HEALTHCARE DIAGNOSTIC RECORDS & CASE MIX (CMI) MANAGEMENT SYSTEM
-- Relational Database Management System (DBMS) Schema Specification
-- Compatible with SQLite3, PostgreSQL, and MySQL (ANSI SQL Standard)
-- ============================================================================

PRAGMA foreign_keys = ON;

-- ----------------------------------------------------------------------------
-- 1. DEPARTMENTS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS departments (
    dept_id INTEGER PRIMARY KEY AUTOINCREMENT,
    dept_code VARCHAR(10) NOT NULL UNIQUE,
    dept_name VARCHAR(100) NOT NULL,
    target_cmi DECIMAL(4, 2) DEFAULT 1.20,
    bed_capacity INTEGER NOT NULL CHECK (bed_capacity > 0),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 2. PHYSICIANS / CLINICIANS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS physicians (
    physician_id INTEGER PRIMARY KEY AUTOINCREMENT,
    license_no VARCHAR(50) NOT NULL UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialty VARCHAR(100) NOT NULL,
    dept_id INTEGER NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(20),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE RESTRICT
);

-- ----------------------------------------------------------------------------
-- 3. DRG MASTER (Diagnosis-Related Groups & CMS Relative Weights)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS drg_master (
    drg_id INTEGER PRIMARY KEY AUTOINCREMENT,
    drg_code VARCHAR(20) NOT NULL UNIQUE,
    drg_title VARCHAR(200) NOT NULL,
    mdc_code VARCHAR(100) NOT NULL, -- Major Diagnostic Category
    relative_weight DECIMAL(6, 4) NOT NULL CHECK (relative_weight > 0),
    geometric_mean_los DECIMAL(4, 1) NOT NULL CHECK (geometric_mean_los > 0),
    base_payment_rate DECIMAL(10, 2) NOT NULL DEFAULT 6500.00,
    severity_level VARCHAR(20) CHECK (severity_level IN ('Minor', 'Moderate', 'Major (CC)', 'Extreme (MCC)')) DEFAULT 'Moderate'
);

-- ----------------------------------------------------------------------------
-- 4. PATIENTS (Demographics & Insurance)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS patients (
    patient_id INTEGER PRIMARY KEY AUTOINCREMENT,
    mrn VARCHAR(30) NOT NULL UNIQUE, -- Medical Record Number
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    dob DATE NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
    blood_group VARCHAR(5) CHECK (blood_group IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-')),
    contact_phone VARCHAR(25),
    email VARCHAR(100),
    address VARCHAR(255),
    insurance_provider VARCHAR(100) NOT NULL,
    policy_no VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- 5. ADMISSIONS / HOSPITAL ENCOUNTERS
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS admissions (
    admission_id INTEGER PRIMARY KEY AUTOINCREMENT,
    admission_no VARCHAR(30) NOT NULL UNIQUE,
    patient_id INTEGER NOT NULL,
    dept_id INTEGER NOT NULL,
    attending_physician_id INTEGER NOT NULL,
    admission_date DATETIME NOT NULL,
    discharge_date DATETIME,
    admission_type VARCHAR(20) NOT NULL CHECK (admission_type IN ('Emergency', 'Elective', 'Urgent', 'Trauma')),
    admission_source VARCHAR(50) NOT NULL,
    discharge_disposition VARCHAR(50) DEFAULT 'Inpatient (Active)' CHECK (
        discharge_disposition IN ('Home', 'Skilled Nursing', 'Rehabilitation', 'Transferred', 'Deceased', 'Inpatient (Active)')
    ),
    assigned_drg_id INTEGER,
    total_charges DECIMAL(12, 2) DEFAULT 0.00,
    reimbursement_amount DECIMAL(12, 2) DEFAULT 0.00,
    los_days INTEGER DEFAULT 0,
    status VARCHAR(20) DEFAULT 'Admitted' CHECK (status IN ('Admitted', 'Discharged', 'Transferred')),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id) ON DELETE RESTRICT,
    FOREIGN KEY (attending_physician_id) REFERENCES physicians(physician_id) ON DELETE RESTRICT,
    FOREIGN KEY (assigned_drg_id) REFERENCES drg_master(drg_id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 6. DIAGNOSES (ICD-10 Clinical Coding)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS diagnoses (
    diagnosis_id INTEGER PRIMARY KEY AUTOINCREMENT,
    admission_id INTEGER NOT NULL,
    icd10_code VARCHAR(20) NOT NULL,
    diagnosis_description VARCHAR(255) NOT NULL,
    diagnosis_type VARCHAR(30) NOT NULL CHECK (
        diagnosis_type IN ('Principal', 'Secondary', 'Comorbidity (CC)', 'Major Comorbidity (MCC)')
    ),
    present_on_admission CHAR(1) DEFAULT 'Y' CHECK (present_on_admission IN ('Y', 'N', 'U')),
    diagnosed_date DATE NOT NULL,
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id) ON DELETE CASCADE
);

-- ----------------------------------------------------------------------------
-- 7. PROCEDURES (CPT / ICD-10-PCS)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS procedures (
    procedure_id INTEGER PRIMARY KEY AUTOINCREMENT,
    admission_id INTEGER NOT NULL,
    cpt_code VARCHAR(20) NOT NULL,
    procedure_name VARCHAR(255) NOT NULL,
    procedure_date DATETIME NOT NULL,
    performing_physician_id INTEGER,
    procedure_cost DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id) ON DELETE CASCADE,
    FOREIGN KEY (performing_physician_id) REFERENCES physicians(physician_id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 8. DIAGNOSTIC TESTS CATALOG
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS diagnostic_tests (
    test_id INTEGER PRIMARY KEY AUTOINCREMENT,
    test_code VARCHAR(30) NOT NULL UNIQUE,
    test_name VARCHAR(150) NOT NULL,
    category VARCHAR(50) NOT NULL CHECK (
        category IN ('Biochemistry', 'Hematology', 'Radiology', 'Microbiology', 'Immunology', 'Cardiology Diagnostics')
    ),
    loinc_code VARCHAR(30),
    unit VARCHAR(30),
    normal_range_min DECIMAL(8, 2),
    normal_range_max DECIMAL(8, 2),
    critical_low DECIMAL(8, 2),
    critical_high DECIMAL(8, 2),
    standard_cost DECIMAL(10, 2) NOT NULL DEFAULT 50.00
);

-- ----------------------------------------------------------------------------
-- 9. DIAGNOSTIC RECORDS (Laboratory, Imaging & Pathology Results)
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS diagnostic_records (
    record_id INTEGER PRIMARY KEY AUTOINCREMENT,
    admission_id INTEGER NOT NULL,
    test_id INTEGER NOT NULL,
    ordered_by_physician_id INTEGER,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    result_date DATETIME,
    numeric_result DECIMAL(10, 3),
    text_result TEXT,
    flag VARCHAR(20) DEFAULT 'PENDING' CHECK (flag IN ('NORMAL', 'LOW', 'HIGH', 'CRITICAL', 'PENDING', 'ABNORMAL')),
    reference_range_display VARCHAR(100),
    interpretation_notes TEXT,
    verified_by VARCHAR(100),
    status VARCHAR(20) DEFAULT 'Ordered' CHECK (status IN ('Ordered', 'Processing', 'Completed', 'Cancelled')),
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id) ON DELETE CASCADE,
    FOREIGN KEY (test_id) REFERENCES diagnostic_tests(test_id) ON DELETE RESTRICT,
    FOREIGN KEY (ordered_by_physician_id) REFERENCES physicians(physician_id) ON DELETE SET NULL
);

-- ----------------------------------------------------------------------------
-- 10. AUDIT AND TRANSACTION LOG TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS cmi_audit_log (
    log_id INTEGER PRIMARY KEY AUTOINCREMENT,
    action_type VARCHAR(50) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id INTEGER NOT NULL,
    description TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_admissions_patient ON admissions(patient_id);
CREATE INDEX IF NOT EXISTS idx_admissions_dept ON admissions(dept_id);
CREATE INDEX IF NOT EXISTS idx_admissions_drg ON admissions(assigned_drg_id);
CREATE INDEX IF NOT EXISTS idx_admissions_status ON admissions(status);
CREATE INDEX IF NOT EXISTS idx_diagnostic_admission ON diagnostic_records(admission_id);
CREATE INDEX IF NOT EXISTS idx_diagnostic_test ON diagnostic_records(test_id);
CREATE INDEX IF NOT EXISTS idx_diagnostic_flag ON diagnostic_records(flag);
CREATE INDEX IF NOT EXISTS idx_diagnoses_admission ON diagnoses(admission_id);
CREATE INDEX IF NOT EXISTS idx_diagnoses_icd ON diagnoses(icd10_code);

-- ============================================================================
-- SQL TRIGGERS (DBMS Business Logic Automation)
-- ============================================================================

-- Trigger 1: Auto-evaluate Diagnostic Result Flag & Complete Status
CREATE TRIGGER IF NOT EXISTS trg_eval_diag_result_insert
AFTER INSERT ON diagnostic_records
FOR EACH ROW
WHEN NEW.numeric_result IS NOT NULL AND NEW.status != 'Cancelled'
BEGIN
    UPDATE diagnostic_records
    SET 
        status = 'Completed',
        result_date = COALESCE(NEW.result_date, CURRENT_TIMESTAMP),
        flag = CASE 
            WHEN NEW.numeric_result <= (SELECT critical_low FROM diagnostic_tests WHERE test_id = NEW.test_id AND critical_low IS NOT NULL) THEN 'CRITICAL'
            WHEN NEW.numeric_result >= (SELECT critical_high FROM diagnostic_tests WHERE test_id = NEW.test_id AND critical_high IS NOT NULL) THEN 'CRITICAL'
            WHEN NEW.numeric_result < (SELECT normal_range_min FROM diagnostic_tests WHERE test_id = NEW.test_id AND normal_range_min IS NOT NULL) THEN 'LOW'
            WHEN NEW.numeric_result > (SELECT normal_range_max FROM diagnostic_tests WHERE test_id = NEW.test_id AND normal_range_max IS NOT NULL) THEN 'HIGH'
            ELSE 'NORMAL'
        END,
        reference_range_display = (
            SELECT COALESCE(unit, '') || ' (' || COALESCE(normal_range_min, '-') || ' - ' || COALESCE(normal_range_max, '-') || ')'
            FROM diagnostic_tests WHERE test_id = NEW.test_id
        )
    WHERE record_id = NEW.record_id;
END;

-- Trigger 2: Calculate Length of Stay and Audit Log on Discharge
CREATE TRIGGER IF NOT EXISTS trg_admissions_discharge_audit
AFTER UPDATE OF discharge_date, status ON admissions
FOR EACH ROW
WHEN NEW.discharge_date IS NOT NULL AND NEW.status = 'Discharged'
BEGIN
    UPDATE admissions
    SET los_days = MAX(1, CAST((julianday(NEW.discharge_date) - julianday(NEW.admission_date)) AS INTEGER))
    WHERE admission_id = NEW.admission_id;

    INSERT INTO cmi_audit_log (action_type, table_name, record_id, description)
    VALUES (
        'PATIENT_DISCHARGE',
        'admissions',
        NEW.admission_id,
        'Admission ' || NEW.admission_no || ' discharged. Total LOS: ' || 
        MAX(1, CAST((julianday(NEW.discharge_date) - julianday(NEW.admission_date)) AS INTEGER)) || 
        ' days. DRG ID: ' || COALESCE(NEW.assigned_drg_id, 'None')
    );
END;

-- Trigger 3: Calculate DRG Reimbursement on DRG Assignment
CREATE TRIGGER IF NOT EXISTS trg_calc_reimbursement
AFTER UPDATE OF assigned_drg_id ON admissions
FOR EACH ROW
WHEN NEW.assigned_drg_id IS NOT NULL
BEGIN
    UPDATE admissions
    SET reimbursement_amount = (
        SELECT ROUND(relative_weight * base_payment_rate, 2)
        FROM drg_master
        WHERE drg_id = NEW.assigned_drg_id
    )
    WHERE admission_id = NEW.admission_id;
END;

-- ============================================================================
-- SQL VIEWS FOR CASE MIX & CLINICAL ANALYTICS
-- ============================================================================

-- View 1: Departmental Case Mix Index (CMI) Summary
CREATE VIEW IF NOT EXISTS vw_departmental_case_mix AS
SELECT 
    d.dept_id,
    d.dept_code,
    d.dept_name,
    d.target_cmi,
    d.bed_capacity,
    COUNT(a.admission_id) AS total_admissions,
    SUM(CASE WHEN a.status = 'Discharged' THEN 1 ELSE 0 END) AS total_discharges,
    ROUND(SUM(CASE WHEN a.status = 'Discharged' THEN dm.relative_weight ELSE 0 END), 4) AS total_relative_weight,
    CASE 
        WHEN SUM(CASE WHEN a.status = 'Discharged' THEN 1 ELSE 0 END) > 0 
        THEN ROUND(
            SUM(CASE WHEN a.status = 'Discharged' THEN dm.relative_weight ELSE 0 END) * 1.0 / 
            SUM(CASE WHEN a.status = 'Discharged' THEN 1 ELSE 0 END), 4
        )
        ELSE 0.0000 
    END AS computed_cmi,
    ROUND(AVG(CASE WHEN a.status = 'Discharged' THEN a.los_days ELSE NULL END), 1) AS average_los,
    ROUND(AVG(dm.geometric_mean_los), 1) AS expected_los_benchmark,
    ROUND(SUM(a.total_charges), 2) AS total_hospital_charges,
    ROUND(SUM(a.reimbursement_amount), 2) AS total_reimbursement
FROM departments d
LEFT JOIN admissions a ON d.dept_id = a.dept_id
LEFT JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id
GROUP BY d.dept_id, d.dept_code, d.dept_name, d.target_cmi, d.bed_capacity;

-- View 2: High-Alert Critical Lab Results
CREATE VIEW IF NOT EXISTS vw_critical_diagnostic_alerts AS
SELECT 
    dr.record_id,
    p.mrn,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.gender,
    d.dept_name,
    a.admission_no,
    dt.test_name,
    dt.category AS test_category,
    dr.numeric_result,
    dt.unit,
    dt.normal_range_min,
    dt.normal_range_max,
    dt.critical_low,
    dt.critical_high,
    dr.flag,
    dr.result_date,
    ph.first_name || ' ' || ph.last_name AS attending_physician
FROM diagnostic_records dr
JOIN admissions a ON dr.admission_id = a.admission_id
JOIN patients p ON a.patient_id = p.patient_id
JOIN departments d ON a.dept_id = d.dept_id
JOIN diagnostic_tests dt ON dr.test_id = dt.test_id
JOIN physicians ph ON a.attending_physician_id = ph.physician_id
WHERE dr.flag IN ('CRITICAL', 'HIGH', 'LOW')
ORDER BY dr.result_date DESC;

-- View 3: Complete Patient Diagnostic History Dossier
CREATE VIEW IF NOT EXISTS vw_patient_diagnostic_dossier AS
SELECT 
    p.patient_id,
    p.mrn,
    p.first_name || ' ' || p.last_name AS patient_name,
    p.dob,
    p.gender,
    p.blood_group,
    p.insurance_provider,
    a.admission_id,
    a.admission_no,
    a.admission_date,
    a.discharge_date,
    a.status AS admission_status,
    d.dept_name,
    dm.drg_code,
    dm.drg_title,
    dm.relative_weight,
    dt.test_code,
    dt.test_name,
    dt.category AS test_category,
    dr.numeric_result,
    dt.unit,
    dr.flag,
    dr.result_date,
    dr.reference_range_display
FROM patients p
JOIN admissions a ON p.patient_id = a.patient_id
JOIN departments d ON a.dept_id = d.dept_id
LEFT JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id
JOIN diagnostic_records dr ON a.admission_id = dr.admission_id
JOIN diagnostic_tests dt ON dr.test_id = dt.test_id;

-- View 4: DRG Severity & Financial Performance Analysis
CREATE VIEW IF NOT EXISTS vw_drg_performance_matrix AS
SELECT 
    dm.drg_id,
    dm.drg_code,
    dm.drg_title,
    dm.mdc_code,
    dm.relative_weight,
    dm.severity_level,
    dm.geometric_mean_los,
    COUNT(a.admission_id) AS total_cases,
    ROUND(AVG(a.los_days), 1) AS actual_avg_los,
    ROUND(AVG(a.los_days) - dm.geometric_mean_los, 2) AS los_variance,
    ROUND(AVG(a.total_charges), 2) AS avg_hospital_cost,
    ROUND(AVG(a.reimbursement_amount), 2) AS avg_reimbursement,
    ROUND(AVG(a.reimbursement_amount - a.total_charges), 2) AS avg_contribution_margin
FROM drg_master dm
LEFT JOIN admissions a ON dm.drg_id = a.assigned_drg_id AND a.status = 'Discharged'
GROUP BY dm.drg_id, dm.drg_code, dm.drg_title, dm.mdc_code, dm.relative_weight, dm.severity_level, dm.geometric_mean_los
ORDER BY total_cases DESC, dm.relative_weight DESC;
