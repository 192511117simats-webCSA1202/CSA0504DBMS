"""
Database Initialization & Validation Script
Healthcare Diagnostic Records & Case Mix Management System (DBMS Project)
"""

import os
import sqlite3
import sys

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DB_PATH = os.path.join(BASE_DIR, "healthcare.db")
SCHEMA_PATH = os.path.join(BASE_DIR, "schema.sql")
SEED_PATH = os.path.join(BASE_DIR, "seed_data.sql")
EXPORT_PATH = os.path.join(BASE_DIR, "healthcare_full_dump.sql")

def init_database(reset=True):
    print("=" * 60)
    print(" Initializing Healthcare Diagnostic Records & CMI Database")
    print("=" * 60)

    if reset and os.path.exists(DB_PATH):
        try:
            os.remove(DB_PATH)
            print(f"[+] Removed existing database file: {DB_PATH}")
        except Exception as e:
            print(f"[-] Could not remove existing database: {e}")

    conn = sqlite3.connect(DB_PATH)
    conn.execute("PRAGMA foreign_keys = ON;")
    cursor = conn.cursor()

    # 1. Execute Schema
    print(f"[+] Applying relational schema from: {SCHEMA_PATH}")
    with open(SCHEMA_PATH, "r", encoding="utf-8") as f:
        schema_sql = f.read()
    cursor.executescript(schema_sql)

    # 2. Execute Seed Data
    print(f"[+] Seeding realistic hospital & clinical data from: {SEED_PATH}")
    with open(SEED_PATH, "r", encoding="utf-8") as f:
        seed_sql = f.read()
    cursor.executescript(seed_sql)
    conn.commit()

    # 3. Verify Database Integrity & Counts
    tables = [
        "departments", "physicians", "drg_master", "patients", 
        "admissions", "diagnoses", "procedures", "diagnostic_tests", 
        "diagnostic_records", "cmi_audit_log"
    ]
    
    print("\n--- Relational Table Population Summary ---")
    for tbl in tables:
        cursor.execute(f"SELECT COUNT(*) FROM {tbl};")
        count = cursor.fetchone()[0]
        print(f"  * Table '{tbl:20}': {count:4} rows")

    # 4. Test Views
    print("\n--- Verifying Analytical Views ---")
    views = [
        ("vw_departmental_case_mix", "Departmental Case Mix Index (CMI)"),
        ("vw_critical_diagnostic_alerts", "Critical Lab Alerts"),
        ("vw_drg_performance_matrix", "DRG Performance Matrix"),
        ("vw_patient_diagnostic_dossier", "Patient Diagnostic Dossier")
    ]
    for view_name, label in views:
        cursor.execute(f"SELECT COUNT(*) FROM {view_name};")
        count = cursor.fetchone()[0]
        print(f"  * View '{view_name:30}' ({label}): {count:4} records")

    # Test Hospital-wide CMI calculation
    cursor.execute("""
        SELECT 
            COUNT(CASE WHEN status = 'Discharged' THEN 1 END) as discharges,
            ROUND(SUM(CASE WHEN status = 'Discharged' THEN dm.relative_weight ELSE 0 END), 4) as total_rw,
            ROUND(SUM(CASE WHEN status = 'Discharged' THEN dm.relative_weight ELSE 0 END) * 1.0 / 
                  COUNT(CASE WHEN status = 'Discharged' THEN 1 END), 4) as hospital_cmi,
            ROUND(AVG(CASE WHEN status = 'Discharged' THEN los_days END), 2) as alos,
            ROUND(SUM(total_charges), 2) as total_charges,
            ROUND(SUM(reimbursement_amount), 2) as total_reimbursement
        FROM admissions a
        LEFT JOIN drg_master dm ON a.assigned_drg_id = dm.drg_id;
    """)
    row = cursor.fetchone()
    print("\n--- Executive Case Mix Performance Key Metrics ---")
    print(f"  * Total Discharges          : {row[0]}")
    print(f"  * Total Case Relative Weight: {row[1]}")
    print(f"  * Overall Hospital CMI      : {row[2]} (Target: > 1.20)")
    print(f"  * Average Length of Stay    : {row[3]} days")
    print(f"  * Total Hospital Charges    : ${row[4]:,.2f}")
    print(f"  * Total Reimbursement       : ${row[5]:,.2f}")

    # Generate combined full dump for project presentation
    with open(EXPORT_PATH, "w", encoding="utf-8") as out:
        out.write("-- HEALTHCARE DIAGNOSTIC RECORDS & CASE MIX MANAGEMENT SYSTEM\n")
        out.write("-- FULL RELATIONAL DATABASE DUMP (DDL + DML)\n\n")
        out.write(schema_sql)
        out.write("\n\n-- SEED DATA\n\n")
        out.write(seed_sql)
    print(f"\n[+] Generated standalone full database dump: {EXPORT_PATH}")

    conn.close()
    print("\n[SUCCESS] Database initialization completed successfully!")

if __name__ == "__main__":
    init_database()
