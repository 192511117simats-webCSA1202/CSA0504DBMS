"""
Healthcare Diagnostic Records & Case Mix (CMI) Management System
Flask Backend Application & REST API
"""

import os
import sqlite3
import time
import json
from datetime import datetime
from flask import Flask, render_template, request, jsonify, send_file, g

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "database", "healthcare.db")
EXPORT_PATH = os.path.join(BASE_DIR, "database", "healthcare_full_dump.sql")

app = Flask(__name__, template_folder="templates", static_folder="static")
app.config["SECRET_KEY"] = "healthcare-dbms-secret-key-2024"

# -----------------------------------------------------------------------------
# Database Helper Functions
# -----------------------------------------------------------------------------
def get_db():
    if "db" not in g:
        g.db = sqlite3.connect(DB_PATH)
        g.db.row_factory = sqlite3.Row
        g.db.execute("PRAGMA foreign_keys = ON;")
    return g.db

@app.teardown_appcontext
def close_db(error):
    db = g.pop("db", None)
    if db is not None:
        db.close()

def query_db(query, args=(), one=False):
    cur = get_db().execute(query, args)
    rv = cur.fetchall()
    cur.close()
    return (rv[0] if rv else None) if one else rv

def modify_db(query, args=()):
    db = get_db()
    cur = db.execute(query, args)
    db.commit()
    last_id = cur.lastrowid
    cur.close()
    return last_id

# -----------------------------------------------------------------------------
# Web Routes
# -----------------------------------------------------------------------------
@app.route("/")
def index():
    return render_template("index.html")

# -----------------------------------------------------------------------------
# REST API: Executive KPI Stats
# -----------------------------------------------------------------------------
@app.route("/api/stats", methods=["GET"])
def get_stats():
    # Overall summary query
    summary = query_db("""
        SELECT 
            (SELECT COUNT(*) FROM patients) AS total_patients,
            (SELECT COUNT(*) FROM admissions WHERE status = 'Discharged') AS total_discharges,
            (SELECT COUNT(*) FROM admissions WHERE status = 'Admitted') AS active_inpatients,
            (SELECT COUNT(*) FROM diagnostic_records WHERE flag = 'CRITICAL') AS critical_alerts,
            (SELECT COUNT(*) FROM diagnostic_records WHERE flag IN ('HIGH', 'LOW')) AS abnormal_alerts,
            (SELECT COUNT(*) FROM diagnostic_records) AS total_lab_tests,
            (SELECT ROUND(SUM(total_charges), 2) FROM admissions) AS total_revenue,
            (SELECT ROUND(SUM(reimbursement_amount), 2) FROM admissions) AS total_reimbursement,
            (SELECT ROUND(AVG(los_days), 1) FROM admissions WHERE status = 'Discharged') AS alos,
            (SELECT ROUND(SUM(dm.relative_weight) * 1.0 / NULLIF(COUNT(a.admission_id), 0), 4)
             FROM admissions a 
             JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id 
             WHERE a.status = 'Discharged') AS hospital_cmi
    """, one=True)
    
    return jsonify({
        "total_patients": summary["total_patients"] or 0,
        "total_discharges": summary["total_discharges"] or 0,
        "active_inpatients": summary["active_inpatients"] or 0,
        "critical_alerts": summary["critical_alerts"] or 0,
        "abnormal_alerts": summary["abnormal_alerts"] or 0,
        "total_lab_tests": summary["total_lab_tests"] or 0,
        "total_revenue": summary["total_revenue"] or 0.0,
        "total_reimbursement": summary["total_reimbursement"] or 0.0,
        "alos": summary["alos"] or 0.0,
        "hospital_cmi": summary["hospital_cmi"] or 0.0,
        "target_cmi": 1.25
    })

# -----------------------------------------------------------------------------
# REST API: Case Mix (CMI) Analytics
# -----------------------------------------------------------------------------
@app.route("/api/case-mix", methods=["GET"])
def get_case_mix():
    # 1. Department Breakdown (From View)
    dept_rows = query_db("SELECT * FROM vw_departmental_case_mix ORDER BY computed_cmi DESC;")
    departments = [dict(r) for r in dept_rows]

    # 2. Top DRGs by discharge volume & relative weight
    drg_rows = query_db("""
        SELECT 
            dm.drg_code,
            dm.drg_title,
            dm.relative_weight,
            dm.severity_level,
            COUNT(a.admission_id) as case_count,
            ROUND(AVG(a.los_days), 1) as actual_alos,
            dm.geometric_mean_los as benchmark_los,
            ROUND(SUM(a.reimbursement_amount), 2) as total_reimbursement
        FROM drg_master dm
        JOIN admissions a ON dm.drg_id = a.assigned_drg_id
        WHERE a.status = 'Discharged'
        GROUP BY dm.drg_id, dm.drg_code, dm.drg_title, dm.relative_weight, dm.severity_level
        ORDER BY dm.relative_weight DESC;
    """)
    top_drgs = [dict(r) for r in drg_rows]

    # 3. Severity Level Breakdown (CC / MCC vs Minor)
    severity_rows = query_db("""
        SELECT 
            COALESCE(dm.severity_level, 'Standard') as severity_level,
            COUNT(a.admission_id) as count,
            ROUND(AVG(dm.relative_weight), 3) as avg_weight
        FROM admissions a
        LEFT JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id
        WHERE a.status = 'Discharged'
        GROUP BY dm.severity_level;
    """)
    severities = [dict(r) for r in severity_rows]

    # 4. Monthly/Admission trend
    trend_rows = query_db("""
        SELECT 
            strftime('%Y-%m', a.admission_date) as month,
            COUNT(a.admission_id) as admissions,
            ROUND(AVG(dm.relative_weight), 3) as monthly_cmi
        FROM admissions a
        LEFT JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id
        GROUP BY strftime('%Y-%m', a.admission_date)
        ORDER BY month ASC;
    """)
    trends = [dict(r) for r in trend_rows]

    return jsonify({
        "departments": departments,
        "top_drgs": top_drgs,
        "severities": severities,
        "trends": trends
    })

# -----------------------------------------------------------------------------
# REST API: Diagnostic Records Hub
# -----------------------------------------------------------------------------
@app.route("/api/diagnostics", methods=["GET"])
def get_diagnostics():
    flag = request.args.get("flag")
    category = request.args.get("category")
    admission_id = request.args.get("admission_id")
    search = request.args.get("search")

    query = """
        SELECT 
            dr.record_id,
            dr.admission_id,
            a.admission_no,
            p.mrn,
            p.first_name || ' ' || p.last_name AS patient_name,
            p.gender,
            d.dept_name,
            dt.test_code,
            dt.test_name,
            dt.category AS test_category,
            dt.unit,
            dt.normal_range_min,
            dt.normal_range_max,
            dt.critical_low,
            dt.critical_high,
            dr.numeric_result,
            dr.text_result,
            dr.flag,
            dr.reference_range_display,
            dr.interpretation_notes,
            dr.verified_by,
            dr.status,
            dr.order_date,
            dr.result_date,
            ph.first_name || ' ' || ph.last_name AS ordering_physician
        FROM diagnostic_records dr
        JOIN admissions a ON dr.admission_id = a.admission_id
        JOIN patients p ON a.patient_id = p.patient_id
        JOIN departments d ON a.dept_id = d.dept_id
        JOIN diagnostic_tests dt ON dr.test_id = dt.test_id
        LEFT JOIN physicians ph ON dr.ordered_by_physician_id = ph.physician_id
        WHERE 1=1
    """
    params = []

    if flag and flag != "ALL":
        query += " AND dr.flag = ?"
        params.append(flag)

    if category and category != "ALL":
        query += " AND dt.category = ?"
        params.append(category)

    if admission_id:
        query += " AND dr.admission_id = ?"
        params.append(admission_id)

    if search:
        search_term = f"%{search}%"
        query += " AND (p.first_name LIKE ? OR p.last_name LIKE ? OR p.mrn LIKE ? OR dt.test_name LIKE ?)"
        params.extend([search_term, search_term, search_term, search_term])

    query += " ORDER BY dr.record_id DESC"
    records = query_db(query, params)
    return jsonify([dict(r) for r in records])

@app.route("/api/diagnostics/order", methods=["POST"])
def order_diagnostic():
    data = request.json or {}
    admission_id = data.get("admission_id")
    test_id = data.get("test_id")
    physician_id = data.get("ordered_by_physician_id")
    numeric_result = data.get("numeric_result")
    text_result = data.get("text_result")
    notes = data.get("interpretation_notes")

    if not admission_id or not test_id:
        return jsonify({"error": "admission_id and test_id are required"}), 400

    record_id = modify_db("""
        INSERT INTO diagnostic_records (
            admission_id, test_id, ordered_by_physician_id,
            numeric_result, text_result, interpretation_notes,
            order_date, result_date, verified_by, status
        ) VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP, 
                  CASE WHEN ? IS NOT NULL THEN CURRENT_TIMESTAMP ELSE NULL END, 
                  'Dr. ' || (SELECT last_name FROM physicians WHERE physician_id = ?),
                  CASE WHEN ? IS NOT NULL THEN 'Completed' ELSE 'Ordered' END)
    """, (admission_id, test_id, physician_id, numeric_result, text_result, notes, 
          numeric_result, physician_id, numeric_result))

    # Fetch updated record (triggers will have fired!)
    updated = query_db("""
        SELECT dr.*, dt.test_name, dt.unit 
        FROM diagnostic_records dr 
        JOIN diagnostic_tests dt ON dr.test_id = dt.test_id 
        WHERE dr.record_id = ?
    """, (record_id,), one=True)

    return jsonify({"success": True, "record": dict(updated)})

@app.route("/api/diagnostics/<int:record_id>/result", methods=["POST"])
def update_diagnostic_result(record_id):
    data = request.json or {}
    numeric_result = data.get("numeric_result")
    text_result = data.get("text_result")
    notes = data.get("interpretation_notes")
    verified_by = data.get("verified_by", "Attending Physician")

    # Update numeric_result; this automatically fires SQLite trigger to calculate flags!
    modify_db("""
        UPDATE diagnostic_records
        SET numeric_result = ?,
            text_result = ?,
            interpretation_notes = ?,
            verified_by = ?,
            result_date = CURRENT_TIMESTAMP,
            status = 'Completed'
        WHERE record_id = ?;
    """, (numeric_result, text_result, notes, verified_by, record_id))

    # Get updated record
    updated = query_db("""
        SELECT dr.*, dt.test_name, dt.unit 
        FROM diagnostic_records dr 
        JOIN diagnostic_tests dt ON dr.test_id = dt.test_id 
        WHERE dr.record_id = ?
    """, (record_id,), one=True)

    return jsonify({"success": True, "record": dict(updated)})

# -----------------------------------------------------------------------------
# REST API: Patients & Demographics
# -----------------------------------------------------------------------------
@app.route("/api/patients", methods=["GET"])
def get_patients():
    search = request.args.get("search", "")
    query = """
        SELECT 
            p.*,
            (SELECT COUNT(*) FROM admissions a WHERE a.patient_id = p.patient_id) AS total_admissions,
            (SELECT status FROM admissions a WHERE a.patient_id = p.patient_id ORDER BY a.admission_date DESC LIMIT 1) AS latest_status
        FROM patients p
        WHERE 1=1
    """
    params = []
    if search:
        search_term = f"%{search}%"
        query += " AND (p.first_name LIKE ? OR p.last_name LIKE ? OR p.mrn LIKE ? OR p.insurance_provider LIKE ?)"
        params.extend([search_term, search_term, search_term, search_term])
    query += " ORDER BY p.patient_id DESC"
    patients = query_db(query, params)
    return jsonify([dict(r) for r in patients])

@app.route("/api/patients", methods=["POST"])
def add_patient():
    data = request.json or {}
    # Generate unique MRN if omitted
    cur = get_db().execute("SELECT MAX(patient_id) FROM patients")
    max_id = (cur.fetchone()[0] or 20) + 1
    mrn = data.get("mrn") or f"MRN-88{max_id:03d}"

    try:
        patient_id = modify_db("""
            INSERT INTO patients (mrn, first_name, last_name, dob, gender, blood_group, contact_phone, email, address, insurance_provider, policy_no)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            mrn,
            data.get("first_name", "Jane"),
            data.get("last_name", "Doe"),
            data.get("dob", "1980-01-01"),
            data.get("gender", "Female"),
            data.get("blood_group", "O+"),
            data.get("contact_phone", "+1-555-0000"),
            data.get("email", "patient@example.com"),
            data.get("address", "Hospital Way"),
            data.get("insurance_provider", "BlueCross BlueShield"),
            data.get("policy_no", f"POL-{max_id:04d}")
        ))
        new_patient = query_db("SELECT * FROM patients WHERE patient_id = ?", (patient_id,), one=True)
        return jsonify({"success": True, "patient": dict(new_patient)})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route("/api/patients/<int:patient_id>", methods=["GET"])
def get_patient_detail(patient_id):
    patient = query_db("SELECT * FROM patients WHERE patient_id = ?", (patient_id,), one=True)
    if not patient:
        return jsonify({"error": "Patient not found"}), 404

    admissions = query_db("""
        SELECT 
            a.*,
            d.dept_name,
            dm.drg_code,
            dm.drg_title,
            dm.relative_weight,
            ph.first_name || ' ' || ph.last_name AS physician_name
        FROM admissions a
        JOIN departments d ON a.dept_id = d.dept_id
        LEFT JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id
        JOIN physicians ph ON a.attending_physician_id = ph.physician_id
        WHERE a.patient_id = ?
        ORDER BY a.admission_date DESC
    """, (patient_id,))

    # Diagnostic records for this patient
    records = query_db("""
        SELECT 
            dr.*,
            dt.test_code,
            dt.test_name,
            dt.category,
            dt.unit,
            dt.normal_range_min,
            dt.normal_range_max,
            dt.critical_low,
            dt.critical_high
        FROM diagnostic_records dr
        JOIN admissions a ON dr.admission_id = a.admission_id
        JOIN diagnostic_tests dt ON dr.test_id = dt.test_id
        WHERE a.patient_id = ?
        ORDER BY dr.record_id DESC
    """, (patient_id,))

    # Diagnoses for this patient
    diagnoses = query_db("""
        SELECT diag.*, a.admission_no
        FROM diagnoses diag
        JOIN admissions a ON diag.admission_id = a.admission_id
        WHERE a.patient_id = ?
        ORDER BY diag.diagnosed_date DESC
    """, (patient_id,))

    return jsonify({
        "patient": dict(patient),
        "admissions": [dict(a) for a in admissions],
        "diagnostics": [dict(r) for r in records],
        "diagnoses": [dict(d) for d in diagnoses]
    })

# -----------------------------------------------------------------------------
# REST API: Admissions Management
# -----------------------------------------------------------------------------
@app.route("/api/admissions", methods=["GET"])
def get_admissions():
    status = request.args.get("status")
    dept_id = request.args.get("dept_id")

    query = """
        SELECT 
            a.*,
            p.mrn,
            p.first_name || ' ' || p.last_name AS patient_name,
            p.gender,
            p.dob,
            d.dept_name,
            dm.drg_code,
            dm.drg_title,
            dm.relative_weight,
            dm.severity_level,
            ph.first_name || ' ' || ph.last_name AS physician_name
        FROM admissions a
        JOIN patients p ON a.patient_id = p.patient_id
        JOIN departments d ON a.dept_id = d.dept_id
        LEFT JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id
        JOIN physicians ph ON a.attending_physician_id = ph.physician_id
        WHERE 1=1
    """
    params = []
    if status and status != "ALL":
        query += " AND a.status = ?"
        params.append(status)
    if dept_id and dept_id != "ALL":
        query += " AND a.dept_id = ?"
        params.append(dept_id)

    query += " ORDER BY a.admission_id DESC"
    admissions = query_db(query, params)
    return jsonify([dict(a) for a in admissions])

@app.route("/api/admissions", methods=["POST"])
def admit_patient():
    data = request.json or {}
    cur = get_db().execute("SELECT MAX(admission_id) FROM admissions")
    max_id = (cur.fetchone()[0] or 25) + 1
    adm_no = f"ADM-2024-{max_id:03d}"

    try:
        admission_id = modify_db("""
            INSERT INTO admissions (
                admission_no, patient_id, dept_id, attending_physician_id,
                admission_date, admission_type, admission_source, assigned_drg_id,
                total_charges, status
            ) VALUES (?, ?, ?, ?, CURRENT_TIMESTAMP, ?, ?, ?, ?, 'Admitted')
        """, (
            adm_no,
            data.get("patient_id"),
            data.get("dept_id"),
            data.get("attending_physician_id"),
            data.get("admission_type", "Emergency"),
            data.get("admission_source", "Emergency Department"),
            data.get("assigned_drg_id"),
            data.get("total_charges", 5000.00)
        ))

        # Add principal diagnosis if provided
        if data.get("icd10_code"):
            modify_db("""
                INSERT INTO diagnoses (admission_id, icd10_code, diagnosis_description, diagnosis_type, diagnosed_date)
                VALUES (?, ?, ?, 'Principal', CURRENT_DATE)
            """, (admission_id, data.get("icd10_code"), data.get("diagnosis_description", "Clinical Evaluation")))

        # Fetch new admission
        adm = query_db("SELECT * FROM admissions WHERE admission_id = ?", (admission_id,), one=True)
        return jsonify({"success": True, "admission": dict(adm)})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

@app.route("/api/admissions/<int:admission_id>/discharge", methods=["POST"])
def discharge_patient(admission_id):
    try:
        # Trigger 2 will automatically calculate los_days and log audit!
        modify_db("""
            UPDATE admissions
            SET discharge_date = CURRENT_TIMESTAMP,
                discharge_disposition = 'Home',
                status = 'Discharged'
            WHERE admission_id = ?
        """, (admission_id,))

        adm = query_db("SELECT * FROM admissions WHERE admission_id = ?", (admission_id,), one=True)
        return jsonify({"success": True, "admission": dict(adm)})
    except Exception as e:
        return jsonify({"error": str(e)}), 400

# -----------------------------------------------------------------------------
# REST API: Master Catalogs & Lookups
# -----------------------------------------------------------------------------
@app.route("/api/departments", methods=["GET"])
def get_departments():
    depts = query_db("SELECT * FROM departments ORDER BY dept_name")
    return jsonify([dict(d) for d in depts])

@app.route("/api/physicians", methods=["GET"])
def get_physicians():
    phys = query_db("""
        SELECT ph.*, d.dept_name 
        FROM physicians ph 
        JOIN departments d ON ph.dept_id = d.dept_id 
        ORDER BY ph.first_name
    """)
    return jsonify([dict(p) for p in phys])

@app.route("/api/drg-catalog", methods=["GET"])
def get_drgs():
    drgs = query_db("SELECT * FROM drg_master ORDER BY relative_weight DESC")
    return jsonify([dict(d) for d in drgs])

@app.route("/api/tests-catalog", methods=["GET"])
def get_tests():
    tests = query_db("SELECT * FROM diagnostic_tests ORDER BY category, test_name")
    return jsonify([dict(t) for t in tests])

# -----------------------------------------------------------------------------
# REST API: DBMS Query Workbench (Interactive SQL Runner)
# -----------------------------------------------------------------------------
@app.route("/api/query", methods=["POST"])
def execute_sql():
    data = request.json or {}
    sql = (data.get("sql") or "").strip()

    if not sql:
        return jsonify({"error": "Empty SQL query provided"}), 400

    # Disallow destructive dropped database operations for web safety
    forbidden = ["DROP DATABASE", "ATTACH", "DETACH"]
    for f in forbidden:
        if f in sql.upper():
            return jsonify({"error": f"Operation '{f}' is restricted in sandbox mode."}), 403

    start_time = time.perf_counter()
    try:
        db = get_db()
        cur = db.cursor()
        
        # Execute query
        cur.execute(sql)
        
        # Check if it was a SELECT query or modification
        if cur.description:
            columns = [desc[0] for desc in cur.description]
            rows = [list(r) for r in cur.fetchall()]
            row_count = len(rows)
            is_mutation = False
        else:
            db.commit()
            columns = ["status", "rows_affected"]
            row_count = cur.rowcount
            rows = [["Success", row_count]]
            is_mutation = True

        duration_ms = round((time.perf_counter() - start_time) * 1000, 2)
        cur.close()

        return jsonify({
            "success": True,
            "columns": columns,
            "rows": rows,
            "row_count": row_count,
            "duration_ms": duration_ms,
            "is_mutation": is_mutation
        })
    except Exception as e:
        duration_ms = round((time.perf_counter() - start_time) * 1000, 2)
        return jsonify({
            "success": False,
            "error": str(e),
            "duration_ms": duration_ms
        }), 400

@app.route("/api/sample-queries", methods=["GET"])
def get_sample_queries():
    queries = [
        {
            "id": 1,
            "title": "Hospital-wide Case Mix Index (CMI) Formula",
            "concept": "Aggregate Mathematical Formulation & Weighting",
            "description": "Calculates Overall CMI = SUM(Relative_Weight * Discharges) / Total_Discharges with ALOS and Total Reimbursement.",
            "sql": """SELECT 
    COUNT(a.admission_id) AS total_discharges,
    ROUND(SUM(dm.relative_weight), 4) AS sum_relative_weight,
    ROUND(SUM(dm.relative_weight) * 1.0 / COUNT(a.admission_id), 4) AS hospital_case_mix_index,
    ROUND(AVG(a.los_days), 2) AS actual_alos_days,
    ROUND(AVG(dm.geometric_mean_los), 2) AS cms_benchmark_alos,
    ROUND(SUM(a.total_charges), 2) AS total_hospital_charges,
    ROUND(SUM(a.reimbursement_amount), 2) AS total_reimbursement,
    ROUND(SUM(a.reimbursement_amount - a.total_charges), 2) AS net_hospital_margin
FROM admissions a
JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id
WHERE a.status = 'Discharged';"""
        },
        {
            "id": 2,
            "title": "Departmental CMI vs Target Performance",
            "concept": "Multi-table JOINs, GROUP BY, and Target Variance",
            "description": "Compares each department's actual computed CMI against the hospital-set target CMI and highlights variance.",
            "sql": """SELECT 
    d.dept_code,
    d.dept_name,
    d.target_cmi,
    COUNT(a.admission_id) AS discharges,
    ROUND(SUM(dm.relative_weight) * 1.0 / NULLIF(COUNT(a.admission_id), 0), 4) AS actual_cmi,
    ROUND((SUM(dm.relative_weight) * 1.0 / NULLIF(COUNT(a.admission_id), 0)) - d.target_cmi, 4) AS cmi_variance,
    CASE 
        WHEN (SUM(dm.relative_weight) * 1.0 / NULLIF(COUNT(a.admission_id), 0)) >= d.target_cmi THEN 'TARGET MET (Higher Acuity)'
        ELSE 'BELOW TARGET (Lower Acuity)'
    END AS clinical_acuity_status
FROM departments d
LEFT JOIN admissions a ON d.dept_id = a.dept_id AND a.status = 'Discharged'
LEFT JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id
GROUP BY d.dept_id, d.dept_code, d.dept_name, d.target_cmi
ORDER BY actual_cmi DESC;"""
        },
        {
            "id": 3,
            "title": "Critical Lab Alerts & Physician Direct Contact",
            "concept": "Emergency Clinical Triage View with 5-Way JOIN",
            "description": "Extracts pending or critical abnormal lab results needing urgent clinical intervention.",
            "sql": """SELECT 
    dr.record_id,
    p.mrn,
    p.first_name || ' ' || p.last_name AS patient_name,
    d.dept_code,
    dt.test_name,
    dr.numeric_result || ' ' || dt.unit AS patient_value,
    dr.reference_range_display AS normal_range,
    dr.flag,
    ph.first_name || ' ' || ph.last_name AS attending_physician,
    ph.phone AS physician_phone,
    dr.interpretation_notes
FROM diagnostic_records dr
JOIN admissions a ON dr.admission_id = a.admission_id
JOIN patients p ON a.patient_id = p.patient_id
JOIN departments d ON a.dept_id = d.dept_id
JOIN diagnostic_tests dt ON dr.test_id = dt.test_id
JOIN physicians ph ON a.attending_physician_id = ph.physician_id
WHERE dr.flag = 'CRITICAL'
ORDER BY dr.result_date DESC;"""
        },
        {
            "id": 4,
            "title": "DRG Financial Margin & Profitability Analysis",
            "concept": "Financial Reimbursement vs Hospital Cost Variance",
            "description": "Calculates profit/loss contribution margin per DRG code.",
            "sql": """SELECT 
    dm.drg_code,
    dm.drg_title,
    dm.relative_weight,
    COUNT(a.admission_id) AS case_volume,
    ROUND(AVG(a.total_charges), 2) AS avg_hospital_charge,
    ROUND(AVG(a.reimbursement_amount), 2) AS avg_reimbursement,
    ROUND(AVG(a.reimbursement_amount - a.total_charges), 2) AS avg_profit_margin,
    ROUND(SUM(a.reimbursement_amount - a.total_charges), 2) AS total_department_profit
FROM drg_master dm
JOIN admissions a ON dm.drg_id = a.assigned_drg_id
WHERE a.status = 'Discharged'
GROUP BY dm.drg_id, dm.drg_code, dm.drg_title, dm.relative_weight
ORDER BY total_department_profit DESC;"""
        },
        {
            "id": 5,
            "title": "Comorbidity / Complication (CC/MCC) Capture Rate",
            "concept": "Subqueries and Conditional Aggregations",
            "description": "Quantifies percentage of patients with high-severity secondary diagnoses affecting DRG weights.",
            "sql": """SELECT 
    d.dept_name,
    COUNT(DISTINCT a.admission_id) AS total_admissions,
    COUNT(DISTINCT CASE WHEN diag.diagnosis_type = 'Major Comorbidity (MCC)' THEN a.admission_id END) AS mcc_cases,
    COUNT(DISTINCT CASE WHEN diag.diagnosis_type = 'Comorbidity (CC)' THEN a.admission_id END) AS cc_cases,
    ROUND(
        COUNT(DISTINCT CASE WHEN diag.diagnosis_type IN ('Major Comorbidity (MCC)', 'Comorbidity (CC)') THEN a.admission_id END) * 100.0 /
        COUNT(DISTINCT a.admission_id), 1
    ) AS cc_mcc_capture_percentage
FROM departments d
JOIN admissions a ON d.dept_id = a.dept_id
LEFT JOIN diagnoses diag ON a.admission_id = diag.admission_id
GROUP BY d.dept_id, d.dept_name
ORDER BY cc_mcc_capture_percentage DESC;"""
        },
        {
            "id": 6,
            "title": "Length of Stay (LOS) Outlier Detection",
            "concept": "Statistical Variance and Benchmark Outliers",
            "description": "Identifies cases where patient stay exceeded CMS geometric mean benchmark by more than 2 days.",
            "sql": """SELECT 
    a.admission_no,
    p.mrn,
    p.first_name || ' ' || p.last_name AS patient_name,
    dm.drg_code,
    dm.drg_title,
    a.los_days AS actual_los_days,
    dm.geometric_mean_los AS expected_benchmark_days,
    ROUND(a.los_days - dm.geometric_mean_los, 2) AS excess_days,
    ROUND((a.los_days - dm.geometric_mean_los) * 1250.00, 2) AS estimated_excess_bed_cost
FROM admissions a
JOIN patients p ON a.patient_id = p.patient_id
JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id
WHERE a.status = 'Discharged' AND (a.los_days - dm.geometric_mean_los) > 1.5
ORDER BY excess_days DESC;"""
        },
        {
            "id": 7,
            "title": "Trigger Audit Log for Discharge & Flag Operations",
            "concept": "Database Auditing & Automated Trigger Inspection",
            "description": "Demonstrates DBMS triggers recording system activity and automatic evaluations.",
            "sql": """SELECT 
    log_id,
    action_type,
    table_name,
    record_id,
    description,
    created_at
FROM cmi_audit_log
ORDER BY log_id DESC;"""
        }
    ]
    return jsonify(queries)

# -----------------------------------------------------------------------------
# REST API: Database Schema & Metadata Explorer
# -----------------------------------------------------------------------------
@app.route("/api/schema-meta", methods=["GET"])
def get_schema_meta():
    db = get_db()
    cur = db.cursor()

    # Get tables
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name;")
    tables = [r[0] for r in cur.fetchall()]

    schema_info = []
    for tbl in tables:
        # Columns
        cur.execute(f"PRAGMA table_info({tbl});")
        columns = [{"cid": r[0], "name": r[1], "type": r[2], "notnull": bool(r[3]), "dflt_value": r[4], "pk": bool(r[5])} for r in cur.fetchall()]
        
        # Foreign Keys
        cur.execute(f"PRAGMA foreign_key_list({tbl});")
        fks = [{"id": r[0], "seq": r[1], "table": r[2], "from": r[3], "to": r[4], "on_update": r[5], "on_delete": r[6]} for r in cur.fetchall()]

        # Row count
        cur.execute(f"SELECT COUNT(*) FROM {tbl};")
        row_count = cur.fetchone()[0]

        schema_info.append({
            "table_name": tbl,
            "columns": columns,
            "foreign_keys": fks,
            "row_count": row_count
        })

    # Views
    cur.execute("SELECT name, sql FROM sqlite_master WHERE type='view' ORDER BY name;")
    views = [{"name": r[0], "sql": r[1]} for r in cur.fetchall()]

    # Triggers
    cur.execute("SELECT name, sql FROM sqlite_master WHERE type='trigger' ORDER BY name;")
    triggers = [{"name": r[0], "sql": r[1]} for r in cur.fetchall()]

    return jsonify({
        "tables": schema_info,
        "views": views,
        "triggers": triggers
    })

# -----------------------------------------------------------------------------
# REST API: Download Standalone SQL Dump
# -----------------------------------------------------------------------------
@app.route("/api/export-sql", methods=["GET"])
def export_sql():
    if os.path.exists(EXPORT_PATH):
        return send_file(EXPORT_PATH, as_attachment=True, download_name="healthcare_cmi_full_dump.sql")
    return jsonify({"error": "Dump file not found"}), 404

if __name__ == "__main__":
    print("[*] Healthcare Diagnostic Records & Case Mix DBMS Server starting on http://127.0.0.1:5000")
    app.run(host="127.0.0.1", port=5000, debug=True)
