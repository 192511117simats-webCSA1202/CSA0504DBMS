# AegisCare™ Healthcare Diagnostic Records & Case Mix (CMI) System
### A Database Management System (DBMS) Project with Interactive Web Interface & Analytics Dashboard

---

## 🏥 Overview

**AegisCare™** is a full-stack, enterprise-grade **Database Management System (DBMS)** project designed for hospital networks to manage **Diagnostic Laboratory & Imaging Records** while analyzing clinical patient complexity using the **Case Mix Index (CMI)** and CMS Diagnosis-Related Groups (**MS-DRGs**).

Built using **Python (Flask), SQLite3, ANSI SQL, Tailwind CSS, and Chart.js**, this project fulfills all academic and industry requirements for DBMS demonstrations:
* **Relational Schema Normalized to 3NF/BCNF** across 10 tables, complete with Foreign Key integrity constraints (`ON DELETE CASCADE` / `RESTRICT`).
* **3 Automated Event-Driven DBMS Triggers** (Automated laboratory critical alert flagging, Discharge Length of Stay calculation, and DRG prospective reimbursement pricing).
* **4 Pre-compiled Analytical SQL Views** (Departmental CMI, Critical Diagnostic Alerts, Patient Dossier, and DRG Profitability Matrix).
* **Interactive DBMS SQL Workbench** with a built-in sandbox execution engine, query performance timer in milliseconds, one-click curated academic query bank, and CSV export.
* **Modern Executive Healthcare Dashboard**: Real-time CMI vs target benchmark tracking, DRG severity distribution charts, patient diagnostic dossier, test ordering, and inpatient admissions.

---

## 🚀 Quick Start (Running the Project)

### Prerequisites
* Python 3.8+ (Python 3.13 is supported).
* All required Python libraries (`flask`, etc.) are standard or already installed.

### Option 1: Double-Click Launcher (Windows)
Simply double-click:
```cmd
run.bat
```
or run in PowerShell:
```powershell
.\run.ps1
```

### Option 2: Command Line (Any OS)
1. Navigate to the project directory:
   ```bash
   cd C:\Users\gamin\.gemini\antigravity\scratch\healthcare-cmi-dbms
   ```
2. Initialize or reset the database (runs schema DDL, triggers, views, and seed data):
   ```bash
   python database/init_db.py
   ```
3. Start the Flask application:
   ```bash
   python app.py
   ```
4. Open your browser at:
   ```
   http://127.0.0.1:5000
   ```

---

## 📐 Relational Database Architecture

```
                    +-----------------------+
                    |      DEPARTMENTS      |
                    +-----------------------+
                     | 1                   | 1
                     |                     |
                     | *                   | *
            +-----------------+   +------------------+
            |   PHYSICIANS    |   |    ADMISSIONS    |<----+
            +-----------------+   +------------------+     |
                     | 1             | 1      | 1          |
                     |               |        |            |
                     | *             | *      | *          |
            +-------------------+ +----------+ | +------------------+
            | DIAGNOSTIC_RECORDS| |DIAGNOSES | | |    PROCEDURES    |
            +-------------------+ +----------+ | +------------------+
                     | *                       |
                     | 1                       | * (FK)
            +-------------------+              |
            | DIAGNOSTIC_TESTS  |         +--------------+
            +-------------------+         |  DRG_MASTER  |
                                          +--------------+
```

### The 10 Relational Tables:
1. `departments`: Hospital clinical units (Cardiology, Oncology, Neurology, Orthopedics, Pulmonology, General Surgery).
2. `physicians`: Attending clinicians, specialties, and departmental affiliations.
3. `drg_master`: CMS Diagnosis-Related Groups with relative weights (RW) and geometric mean length of stay (GMLOS).
4. `patients`: Master demographic and payer insurance records.
5. `admissions`: Inpatient hospitalization encounters, admission type, charges, and discharge status.
6. `diagnoses`: ICD-10 coded primary, secondary, and CC/MCC comorbidity conditions.
7. `procedures`: CPT/ICD-10-PCS clinical and surgical interventions.
8. `diagnostic_tests`: Laboratory & imaging catalog with reference normal ranges and critical limits.
9. `diagnostic_records`: Quantitative & qualitative test results with automated trigger evaluation.
10. `cmi_audit_log`: Permanent system audit log tracking trigger events and discharge transitions.

---

## 🧮 What is Case Mix Index (CMI)?

In healthcare administration and DBMS design, the **Case Mix Index (CMI)** measures the clinical complexity and resource consumption of treated patients:

$$\text{Case Mix Index (CMI)} = \frac{\sum_{i=1}^{\text{Discharges}} \text{Relative Weight}_i}{\text{Total Discharges}}$$

* **Relative Weight (RW)**: Each DRG has a weight assigned based on the typical cost and hospital intensity required. A higher relative weight represents higher illness severity and resource usage (e.g., *MS-DRG 001 Heart Transplant* = `14.8520`, *MS-DRG 470 Knee Replacement* = `1.6240`).
* **Hospital CMI Benchmark**: A CMI $> 1.00$ indicates higher than average patient acuity. AegisCare automatically computes CMI dynamically across hospital departments using SQL Views and Joins.

---

## 🖥️ User Interface Modules

### 1. Case Mix (CMI) Analytics Dashboard
* **Real-time KPI Tiles**: Hospital-wide CMI, Total Discharges, Active Census, Average Length of Stay (ALOS), Total Reimbursement, and Critical Lab Count.
* **Departmental CMI vs Target Chart**: Grouped bar chart comparing computed CMI against benchmark targets.
* **DRG Severity Doughnut**: Visual breakdown of patient volume across Minor, Moderate, CC (Comorbidity), and MCC (Major Comorbidity) illness tiers.
* **Department Resource Matrix**: Live table showing charges, reimbursements, and net margins.

### 2. Diagnostic Records Hub
* Filterable by **Flag** (`CRITICAL`, `HIGH`, `LOW`, `NORMAL`, `PENDING`) and **Category** (`Biochemistry`, `Hematology`, `Radiology`, `Microbiology`, etc.).
* **Visual Reference Range Bullet Gauge**: Shows in real-time where the patient's quantitative result lies relative to normal and critical boundaries.
* **Order New Test Modal**: Place orders with automatic trigger evaluation.
* **Update Result Action**: Demonstrates DBMS triggers firing immediately upon entering a new value.

### 3. Patients & Encounters Directory
* Complete patient directory with MRN, DOB, gender, blood group, and insurance.
* **Patient 360-degree Dossier**: Comprehensive modal showing encounter history, ICD-10 diagnoses, and chronological lab test records.
* **One-Click Discharge**: Triggers automated calculation of Length of Stay (LOS) and records audit entries.

### 4. Clinical Coding & DRG Master
* Searchable catalog of CMS MS-DRGs, base payment calculations, severity classes, and benchmark LOS.

### 5. DBMS SQL Workbench (Interactive SQL Console)
* **Live SQL Sandbox**: Type and execute ANY custom SQL query against the database.
* **Query Performance Profiler**: Measures exact query execution time in milliseconds.
* **One-Click Curated Academic Queries**:
  1. *Hospital-wide CMI Mathematical Formulation*
  2. *Departmental CMI vs Target Performance Ranking*
  3. *Critical Lab Alerts with Immediate Attending Physician Contact*
  4. *DRG Financial Margin & Profitability Analysis*
  5. *Comorbidity / Complication (CC/MCC) Capture Rate*
  6. *Length of Stay Outlier Detection (ALOS vs Benchmark)*
  7. *Trigger Audit Log for Discharge & Flag Operations*
* **Export CSV**: Instant export of any query output for reporting.

### 6. Schema & ER Model Inspector
* Live data dictionary viewer showing column data types, Primary Keys, Foreign Keys, and row counts.
* Live viewer for active DBMS Triggers and Views SQL DDL code.
* Download button for standalone `schema.sql` and `seed_data.sql`.

---

## 🎓 DBMS Viva & Project Evaluation Q&A

**Q1: How does this database satisfy 3NF?**
> **Answer**: All tables have atomic attributes (1NF), all non-key columns depend on the entire primary key (2NF), and there are no transitive dependencies (3NF). For example, department metadata is stored solely in `departments` and referenced via `dept_id` foreign key rather than redundantly stored in `admissions` or `physicians`.

**Q2: How are DBMS Triggers utilized in this project?**
> **Answer**: We implemented 3 active triggers:
> 1. `trg_eval_diag_result_insert`: When a numeric test result is entered, the trigger automatically checks normal and critical bounds from `diagnostic_tests` and sets the flag to `CRITICAL`, `HIGH`, `LOW`, or `NORMAL`.
> 2. `trg_admissions_discharge_audit`: When an admission's status is changed to `Discharged`, it automatically computes `los_days = julianday(discharge_date) - julianday(admission_date)` and logs an audit transaction to `cmi_audit_log`.
> 3. `trg_calc_reimbursement`: Dynamically recalculates `reimbursement_amount = relative_weight * base_payment_rate` when a DRG is assigned.

**Q3: How is the Case Mix Index calculated in SQL?**
> **Answer**: Using SQL aggregation:
> ```sql
> SELECT 
>     COUNT(a.admission_id) AS total_discharges,
>     ROUND(SUM(dm.relative_weight) * 1.0 / COUNT(a.admission_id), 4) AS hospital_cmi
> FROM admissions a
> JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id
> WHERE a.status = 'Discharged';
> ```

---

## 📂 Project Directory Structure

```
healthcare-cmi-dbms/
├── app.py                      # Flask Backend API & Application Controller
├── run.bat                     # Windows Batch Launcher
├── run.ps1                     # PowerShell Launcher
├── README.md                   # Complete Project & Viva Guide
├── database/
│   ├── healthcare.db           # SQLite Relational Database (Generated)
│   ├── schema.sql              # ANSI SQL DDL (Tables, Keys, Triggers, Views)
│   ├── seed_data.sql           # Realistic Hospital Clinical & Case Mix Seed Data
│   ├── init_db.py              # Database Initialization & Test Script
│   ├── healthcare_full_dump.sql# Standalone All-In-One SQL Dump
│   └── README_DBMS_SPEC.md     # Detailed DBMS Specification & Normalization Proofs
├── static/
│   ├── css/
│   │   └── styles.css          # Custom Styles & Visual Gauge Bars
│   └── js/
│       └── app.js              # Frontend AJAX, Chart.js & Workbench Logic
└── templates/
    └── index.html              # Responsive Healthcare Dashboard Single Page App
```
