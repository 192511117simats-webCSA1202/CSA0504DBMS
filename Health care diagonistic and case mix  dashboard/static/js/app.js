/**
 * AegisCare™ Healthcare Diagnostic Records & Case Mix DBMS
 * Frontend Application & Dashboard Controller
 */

let deptCmiChartInstance = null;
let severityPieChartInstance = null;
let currentQueryResults = null;
let catalogTests = [];
let catalogDrgs = [];
let catalogPhysicians = [];
let catalogDepartments = [];

// Initialize on DOM Ready
document.addEventListener('DOMContentLoaded', () => {
    initApp();
});

async function initApp() {
    loadLookups();
    loadDashboardStats();
    loadCaseMixData();
    loadSampleQueries();
    loadSchemaMetadata();

    // Setup global search
    const globalSearch = document.getElementById('globalSearchInput');
    if (globalSearch) {
        globalSearch.addEventListener('keypress', (e) => {
            if (e.key === 'Enter') {
                const val = e.target.value.trim();
                if (val) {
                    switchTab('diagnostics');
                    document.getElementById('diagSearchInput').value = val;
                    loadDiagnosticRecords();
                }
            }
        });
    }

    // Ctrl+Enter on SQL editor
    const sqlTextarea = document.getElementById('sqlQueryInput');
    if (sqlTextarea) {
        sqlTextarea.addEventListener('keydown', (e) => {
            if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
                e.preventDefault();
                executeCurrentQuery();
            }
        });
    }
}

// -----------------------------------------------------------------------------
// Navigation & Tab Switching
// -----------------------------------------------------------------------------
function switchTab(tabId) {
    const panels = ['casemix', 'diagnostics', 'patients', 'coding', 'workbench', 'schema'];
    panels.forEach(p => {
        const panelEl = document.getElementById(`panel-${p}`);
        const tabEl = document.getElementById(`tab-${p}`);
        if (p === tabId) {
            panelEl.classList.remove('hidden');
            tabEl.classList.add('active-tab');
        } else {
            panelEl.classList.add('hidden');
            tabEl.classList.remove('active-tab');
        }
    });

    if (tabId === 'casemix') loadCaseMixData();
    if (tabId === 'diagnostics') loadDiagnosticRecords();
    if (tabId === 'patients') loadPatients();
    if (tabId === 'coding') loadDrgCatalog();
    if (tabId === 'schema') loadSchemaMetadata();
}

// -----------------------------------------------------------------------------
// Toast Notifications
// -----------------------------------------------------------------------------
function showToast(message, type = 'info') {
    const container = document.getElementById('toastContainer');
    const toast = document.createElement('div');
    toast.className = `toast-enter pointer-events-auto px-4 py-2.5 rounded-xl shadow-lg border text-xs font-medium flex items-center space-x-2 ${
        type === 'success' ? 'bg-emerald-950/90 border-emerald-700 text-emerald-200' :
        type === 'error' ? 'bg-rose-950/90 border-rose-700 text-rose-200' :
        'bg-slate-900 border-slate-700 text-slate-200'
    }`;
    const icon = type === 'success' ? 'fa-circle-check text-emerald-400' :
                 type === 'error' ? 'fa-circle-exclamation text-rose-400' : 'fa-circle-info text-cyan-400';
    toast.innerHTML = `<i class="fa-solid ${icon}"></i><span>${message}</span>`;
    container.appendChild(toast);
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transition = 'opacity 0.3s ease';
        setTimeout(() => toast.remove(), 300);
    }, 3500);
}

// -----------------------------------------------------------------------------
// Catalog & Lookups
// -----------------------------------------------------------------------------
async function loadLookups() {
    try {
        const [testsRes, drgsRes, physRes, deptsRes] = await Promise.all([
            fetch('/api/tests-catalog'),
            fetch('/api/drg-catalog'),
            fetch('/api/physicians'),
            fetch('/api/departments')
        ]);
        catalogTests = await testsRes.json();
        catalogDrgs = await drgsRes.json();
        catalogPhysicians = await physRes.json();
        catalogDepartments = await deptsRes.json();
        populateModalDropdowns();
    } catch (err) {
        console.error('Failed loading lookups:', err);
    }
}

function populateModalDropdowns() {
    // Populate tests
    const testSelect = document.getElementById('orderTestSelect');
    if (testSelect) {
        testSelect.innerHTML = '<option value="">-- Choose Diagnostic Test --</option>' +
            catalogTests.map(t => `<option value="${t.test_id}">${t.test_code} - ${t.test_name} (${t.category})</option>`).join('');
    }
    // Populate DRGs
    const drgSelect = document.getElementById('admitDrgSelect');
    if (drgSelect) {
        drgSelect.innerHTML = '<option value="">-- Choose MS-DRG (Case Mix) --</option>' +
            catalogDrgs.map(d => `<option value="${d.drg_id}">${d.drg_code} - ${d.drg_title} (RW: ${d.relative_weight})</option>`).join('');
    }
    // Populate Physicians
    const orderPhysSelect = document.getElementById('orderPhysicianSelect');
    const admitPhysSelect = document.getElementById('admitPhysicianSelect');
    const physOptions = '<option value="">-- Choose Attending Physician --</option>' +
        catalogPhysicians.map(p => `<option value="${p.physician_id}">Dr. ${p.first_name} ${p.last_name} (${p.specialty})</option>`).join('');
    if (orderPhysSelect) orderPhysSelect.innerHTML = physOptions;
    if (admitPhysSelect) admitPhysSelect.innerHTML = physOptions;

    // Populate Departments
    const deptSelect = document.getElementById('admitDeptSelect');
    if (deptSelect) {
        deptSelect.innerHTML = '<option value="">-- Choose Department --</option>' +
            catalogDepartments.map(d => `<option value="${d.dept_id}">${d.dept_code} - ${d.dept_name}</option>`).join('');
    }
}

// -----------------------------------------------------------------------------
// Executive KPI Stats & Case Mix
// -----------------------------------------------------------------------------
async function loadDashboardStats() {
    try {
        const res = await fetch('/api/stats');
        const data = await res.json();
        document.getElementById('statHospitalCmi').innerText = Number(data.hospital_cmi).toFixed(4);
        document.getElementById('statDischarges').innerText = data.total_discharges;
        document.getElementById('statActiveInpatients').innerText = data.active_inpatients;
        document.getElementById('statAlos').innerText = Number(data.alos).toFixed(1);
        document.getElementById('statReimbursement').innerText = `$${Number(data.total_reimbursement).toLocaleString()}`;
        document.getElementById('statRevenue').innerText = `$${Number(data.total_revenue).toLocaleString()}`;
        document.getElementById('statCriticalAlerts').innerText = data.critical_alerts;
        document.getElementById('statAbnormalAlerts').innerText = data.abnormal_alerts;

        const badge = document.getElementById('criticalBadge');
        if (data.critical_alerts > 0) {
            badge.innerText = data.critical_alerts;
            badge.classList.remove('hidden');
        } else {
            badge.classList.add('hidden');
        }
    } catch (err) {
        console.error('Failed to load stats:', err);
    }
}

async function loadCaseMixData() {
    loadDashboardStats();
    try {
        const res = await fetch('/api/case-mix');
        const data = await res.json();

        // 1. Render Department Table
        const tbody = document.getElementById('caseMixTableBody');
        tbody.innerHTML = data.departments.map(d => {
            const cmi = Number(d.computed_cmi);
            const target = Number(d.target_cmi);
            const isAbove = cmi >= target;
            const netMargin = (d.total_reimbursement || 0) - (d.total_hospital_charges || 0);

            return `
                <tr class="hover:bg-slate-800/40 transition-colors">
                    <td class="px-4 py-3 font-bold text-cyan-400">${d.dept_code}</td>
                    <td class="px-4 py-3 font-sans text-slate-200 font-medium">${d.dept_name}</td>
                    <td class="px-4 py-3 text-center text-slate-300">${d.total_discharges}</td>
                    <td class="px-4 py-3 text-center text-slate-400">${target.toFixed(2)}</td>
                    <td class="px-4 py-3 text-center font-bold ${isAbove ? 'text-emerald-400' : 'text-amber-400'}">${cmi.toFixed(4)}</td>
                    <td class="px-4 py-3 text-center font-sans">
                        <span class="px-2 py-0.5 rounded-full text-[10px] font-semibold ${isAbove ? 'bg-emerald-950 text-emerald-300 border border-emerald-800' : 'bg-amber-950 text-amber-300 border border-amber-800'}">
                            ${isAbove ? 'Target Met' : 'Below Target'}
                        </span>
                    </td>
                    <td class="px-4 py-3 text-center text-slate-300">${d.average_los || '-'} d</td>
                    <td class="px-4 py-3 text-right text-slate-400">$${Number(d.total_hospital_charges || 0).toLocaleString()}</td>
                    <td class="px-4 py-3 text-right text-emerald-400 font-semibold">$${Number(d.total_reimbursement || 0).toLocaleString()}</td>
                    <td class="px-4 py-3 text-right font-semibold ${netMargin >= 0 ? 'text-emerald-400' : 'text-rose-400'}">
                        ${netMargin >= 0 ? '+' : ''}$${Number(netMargin).toLocaleString()}
                    </td>
                </tr>
            `;
        }).join('');

        // 2. Render Charts
        renderDeptCmiChart(data.departments);
        renderSeverityPieChart(data.severities);
    } catch (err) {
        console.error('Failed to load case mix data:', err);
    }
}

function renderDeptCmiChart(departments) {
    const ctx = document.getElementById('deptCmiChart').getContext('2d');
    if (deptCmiChartInstance) deptCmiChartInstance.destroy();

    const labels = departments.map(d => d.dept_code);
    const computedCmi = departments.map(d => Number(d.computed_cmi));
    const targetCmi = departments.map(d => Number(d.target_cmi));

    deptCmiChartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [
                {
                    label: 'Computed Case Mix Index (CMI)',
                    data: computedCmi,
                    backgroundColor: 'rgba(6, 182, 212, 0.75)',
                    borderColor: '#06b6d4',
                    borderWidth: 1.5,
                    borderRadius: 6
                },
                {
                    label: 'Department Target CMI',
                    data: targetCmi,
                    backgroundColor: 'rgba(148, 163, 184, 0.3)',
                    borderColor: '#94a3b8',
                    borderWidth: 1,
                    borderRadius: 6
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: {
                    labels: { color: '#cbd5e1', font: { size: 11, family: 'Inter' } }
                },
                tooltip: {
                    callbacks: {
                        afterBody: (context) => {
                            const idx = context[0].dataIndex;
                            return `Specialty: ${departments[idx].dept_name}\nDischarges: ${departments[idx].total_discharges}`;
                        }
                    }
                }
            },
            scales: {
                x: {
                    ticks: { color: '#94a3b8', font: { family: 'JetBrains Mono' } },
                    grid: { color: 'rgba(51, 65, 85, 0.4)' }
                },
                y: {
                    beginAtZero: true,
                    ticks: { color: '#94a3b8' },
                    grid: { color: 'rgba(51, 65, 85, 0.4)' }
                }
            }
        }
    });
}

function renderSeverityPieChart(severities) {
    const ctx = document.getElementById('severityPieChart').getContext('2d');
    if (severityPieChartInstance) severityPieChartInstance.destroy();

    const labels = severities.map(s => s.severity_level);
    const counts = severities.map(s => s.count);

    const colors = [
        'rgba(244, 63, 94, 0.8)',  // MCC - Red
        'rgba(249, 115, 22, 0.8)', // CC - Orange
        'rgba(14, 165, 233, 0.8)', // Moderate - Blue
        'rgba(16, 185, 129, 0.8)'  // Minor - Green
    ];

    severityPieChartInstance = new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: labels,
            datasets: [{
                data: counts,
                backgroundColor: colors,
                borderColor: '#0f172a',
                borderWidth: 2
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false }
            },
            cutout: '68%'
        }
    });

    const legendContainer = document.getElementById('severityLegend');
    legendContainer.innerHTML = severities.map((s, i) => `
        <div class="flex items-center space-x-2">
            <span class="w-2.5 h-2.5 rounded-full" style="background-color: ${colors[i % colors.length]}"></span>
            <span class="truncate text-slate-300">${s.severity_level}: <strong>${s.count}</strong></span>
        </div>
    `).join('');
}

// -----------------------------------------------------------------------------
// Diagnostic Records Hub
// -----------------------------------------------------------------------------
async function loadDiagnosticRecords() {
    const flag = document.getElementById('diagFlagFilter').value;
    const category = document.getElementById('diagCategoryFilter').value;
    const search = document.getElementById('diagSearchInput').value.trim();

    const params = new URLSearchParams();
    if (flag) params.append('flag', flag);
    if (category) params.append('category', category);
    if (search) params.append('search', search);

    try {
        const res = await fetch(`/api/diagnostics?${params.toString()}`);
        const records = await res.json();
        renderDiagnosticTable(records);
    } catch (err) {
        console.error('Failed to load diagnostics:', err);
    }
}

function filterDiagnostics(flag) {
    switchTab('diagnostics');
    const select = document.getElementById('diagFlagFilter');
    if (select) {
        select.value = flag;
        loadDiagnosticRecords();
    }
}

function filterDiagnosticsLocal() {
    clearTimeout(window._diagFilterTimer);
    window._diagFilterTimer = setTimeout(() => {
        loadDiagnosticRecords();
    }, 250);
}

function renderDiagnosticTable(records) {
    const tbody = document.getElementById('diagnosticsTableBody');
    if (!records.length) {
        tbody.innerHTML = `<tr><td colspan="10" class="text-center py-8 text-slate-500 font-sans">No diagnostic records matched the selected criteria.</td></tr>`;
        return;
    }

    tbody.innerHTML = records.map(r => {
        let flagClass = 'flag-pending';
        let flagIcon = 'fa-hourglass-start';
        if (r.flag === 'CRITICAL') { flagClass = 'flag-critical'; flagIcon = 'fa-triangle-exclamation animate-pulse'; }
        else if (r.flag === 'HIGH') { flagClass = 'flag-high'; flagIcon = 'fa-arrow-trend-up'; }
        else if (r.flag === 'LOW') { flagClass = 'flag-low'; flagIcon = 'fa-arrow-trend-down'; }
        else if (r.flag === 'NORMAL') { flagClass = 'flag-normal'; flagIcon = 'fa-check'; }

        // Gauge marker percentage
        let gaugeHtml = '';
        if (r.numeric_result !== null && r.normal_range_min !== null && r.normal_range_max !== null) {
            const min = r.normal_range_min;
            const max = r.normal_range_max;
            const span = max - min;
            let pct = ((r.numeric_result - min) / (span || 1)) * 60 + 20; // 20% to 80% is normal zone
            pct = Math.max(5, Math.min(95, pct));
            const markerColor = r.flag === 'CRITICAL' ? '#f43f5e' : r.flag === 'HIGH' ? '#f97316' : r.flag === 'LOW' ? '#3b82f6' : '#10b981';
            gaugeHtml = `
                <div class="ref-gauge-container mt-1">
                    <div class="ref-gauge-normal-zone"></div>
                    <div class="ref-gauge-marker" style="left: ${pct}%; background-color: ${markerColor}"></div>
                </div>
            `;
        }

        return `
            <tr class="hover:bg-slate-800/40 transition-colors">
                <td class="px-4 py-3 font-mono font-bold text-slate-400">#${r.record_id}</td>
                <td class="px-4 py-3">
                    <div class="font-bold text-white hover:text-cyan-400 cursor-pointer" onclick="openPatientDossierByAdmission(${r.admission_id})">${r.patient_name}</div>
                    <div class="text-[11px] text-slate-400 font-mono">${r.mrn} • ${r.admission_no}</div>
                </td>
                <td class="px-4 py-3 text-slate-300 font-medium">${r.dept_name}</td>
                <td class="px-4 py-3">
                    <div class="font-semibold text-slate-200">${r.test_name}</div>
                    <div class="text-[10px] text-slate-400 font-mono">${r.test_code} • ${r.test_category}</div>
                </td>
                <td class="px-4 py-3 text-center">
                    <span class="font-mono font-bold text-sm ${r.flag === 'CRITICAL' ? 'text-rose-400' : r.flag === 'HIGH' ? 'text-orange-400' : r.flag === 'LOW' ? 'text-blue-400' : 'text-emerald-400'}">
                        ${r.numeric_result !== null ? r.numeric_result : (r.text_result || 'Pending')}
                    </span>
                    <span class="text-[11px] text-slate-400 font-mono block">${r.unit || ''}</span>
                    ${gaugeHtml}
                </td>
                <td class="px-4 py-3 text-center font-mono text-slate-400 text-[11px]">
                    ${r.reference_range_display || (r.normal_range_min ? `${r.normal_range_min} - ${r.normal_range_max} ${r.unit}` : 'Standard')}
                </td>
                <td class="px-4 py-3 text-center">
                    <span class="px-2.5 py-1 rounded-full text-[10px] font-bold inline-flex items-center space-x-1 ${flagClass}">
                        <i class="fa-solid ${flagIcon}"></i>
                        <span>${r.flag}</span>
                    </span>
                </td>
                <td class="px-4 py-3">
                    <span class="text-xs ${r.status === 'Completed' ? 'text-emerald-400' : 'text-amber-400'} font-medium">
                        ${r.status}
                    </span>
                </td>
                <td class="px-4 py-3 text-[11px] text-slate-400 font-mono">
                    ${r.order_date ? r.order_date.split(' ')[0] : '-'}
                </td>
                <td class="px-4 py-3 text-right">
                    <button onclick="promptUpdateResult(${r.record_id}, '${r.test_name}')" 
                            class="text-xs bg-slate-800 hover:bg-cyan-600 hover:text-white text-slate-300 px-2 py-1 rounded border border-slate-700 transition-colors">
                        Enter Result
                    </button>
                </td>
            </tr>
        `;
    }).join('');
}

// -----------------------------------------------------------------------------
// Patients Directory & 360-degree Dossier
// -----------------------------------------------------------------------------
async function loadPatients() {
    const search = document.getElementById('patientSearchInput').value.trim();
    try {
        const res = await fetch(`/api/patients?search=${encodeURIComponent(search)}`);
        const patients = await res.json();
        const tbody = document.getElementById('patientsTableBody');

        tbody.innerHTML = patients.map(p => `
            <tr class="hover:bg-slate-800/40 transition-colors">
                <td class="px-4 py-3 font-mono font-bold text-cyan-400">${p.mrn}</td>
                <td class="px-4 py-3">
                    <div class="font-bold text-white hover:text-cyan-300 cursor-pointer" onclick="openPatientDossier(${p.patient_id})">
                        ${p.first_name} ${p.last_name}
                    </div>
                    <div class="text-[11px] text-slate-400">${p.contact_phone || 'No phone'}</div>
                </td>
                <td class="px-4 py-3 text-center font-mono text-slate-300">
                    ${p.gender} / ${p.dob}
                </td>
                <td class="px-4 py-3 text-center">
                    <span class="px-2 py-0.5 rounded font-mono font-bold text-[11px] bg-slate-800 text-rose-400 border border-slate-700">
                        ${p.blood_group || 'Unknown'}
                    </span>
                </td>
                <td class="px-4 py-3 text-slate-300 font-medium">
                    ${p.insurance_provider}
                    <span class="block text-[10px] text-slate-500 font-mono">${p.policy_no}</span>
                </td>
                <td class="px-4 py-3 text-center font-mono text-slate-300 font-bold">
                    ${p.total_admissions}
                </td>
                <td class="px-4 py-3 text-center">
                    <span class="px-2.5 py-0.5 rounded-full text-[10px] font-semibold ${
                        p.latest_status === 'Admitted' ? 'bg-cyan-950 text-cyan-300 border border-cyan-800' : 'bg-slate-800 text-slate-400'
                    }">
                        ${p.latest_status || 'Registered'}
                    </span>
                </td>
                <td class="px-4 py-3 text-right">
                    <button onclick="openPatientDossier(${p.patient_id})" class="text-xs bg-slate-800 hover:bg-slate-700 text-cyan-400 px-2.5 py-1 rounded border border-slate-700 transition-colors">
                        <i class="fa-solid fa-folder-open mr-1"></i> Dossier
                    </button>
                </td>
            </tr>
        `).join('');
    } catch (err) {
        console.error('Failed to load patients:', err);
    }
}

function filterPatientsLocal() {
    clearTimeout(window._patFilterTimer);
    window._patFilterTimer = setTimeout(() => {
        loadPatients();
    }, 250);
}

async function openPatientDossier(patientId) {
    try {
        const res = await fetch(`/api/patients/${patientId}`);
        const data = await res.json();
        const p = data.patient;

        document.getElementById('dossierPatientName').innerText = `${p.first_name} ${p.last_name}`;
        document.getElementById('dossierPatientMeta').innerText = `MRN: ${p.mrn} • DOB: ${p.dob} (${p.gender}) • Blood: ${p.blood_group} • Insurance: ${p.insurance_provider}`;

        const container = document.getElementById('dossierContent');
        container.innerHTML = `
            <!-- Admissions History -->
            <div>
                <h4 class="font-bold text-white uppercase text-xs tracking-wider mb-2 flex items-center">
                    <i class="fa-solid fa-hospital mr-2 text-cyan-400"></i> Encounters & Admissions (${data.admissions.length})
                </h4>
                <div class="space-y-2">
                    ${data.admissions.map(a => `
                        <div class="bg-slate-950 p-3 rounded-lg border border-slate-800 flex flex-wrap items-center justify-between gap-2">
                            <div>
                                <span class="font-bold font-mono text-cyan-400 mr-2">${a.admission_no}</span>
                                <span class="font-semibold text-slate-200">${a.dept_name}</span>
                                <span class="text-[11px] text-slate-400 block font-mono">
                                    Admit: ${a.admission_date} | Discharged: ${a.discharge_date || 'Active Inpatient'} | LOS: ${a.los_days || 0} days
                                </span>
                            </div>
                            <div class="text-right">
                                <span class="px-2 py-0.5 rounded text-[10px] font-bold ${a.status === 'Admitted' ? 'bg-cyan-950 text-cyan-400 border border-cyan-800' : 'bg-slate-800 text-slate-300'}">
                                    ${a.status}
                                </span>
                                ${a.status === 'Admitted' ? `
                                    <button onclick="dischargeAdmission(${a.admission_id}, ${p.patient_id})" class="ml-2 text-[11px] bg-rose-900/60 hover:bg-rose-800 text-rose-200 px-2 py-0.5 rounded border border-rose-700">
                                        Discharge Patient
                                    </button>
                                ` : ''}
                                <div class="text-[11px] text-emerald-400 font-mono mt-1">Reimb: $${Number(a.reimbursement_amount || 0).toLocaleString()}</div>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>

            <!-- Diagnoses List -->
            <div>
                <h4 class="font-bold text-white uppercase text-xs tracking-wider mb-2 flex items-center">
                    <i class="fa-solid fa-notes-medical mr-2 text-teal-400"></i> Clinical Diagnoses (ICD-10) (${data.diagnoses.length})
                </h4>
                <div class="bg-slate-950 rounded-lg p-3 border border-slate-800 space-y-1.5">
                    ${data.diagnoses.map(d => `
                        <div class="flex items-center justify-between border-b border-slate-800/60 pb-1 text-slate-300">
                            <div>
                                <span class="font-mono font-bold text-teal-400 mr-2">${d.icd10_code}</span>
                                <span>${d.diagnosis_description}</span>
                            </div>
                            <span class="px-2 py-0.5 rounded text-[10px] font-medium bg-slate-900 text-slate-400 border border-slate-800">
                                ${d.diagnosis_type}
                            </span>
                        </div>
                    `).join('')}
                </div>
            </div>

            <!-- Diagnostic Records & Lab Results -->
            <div>
                <h4 class="font-bold text-white uppercase text-xs tracking-wider mb-2 flex items-center">
                    <i class="fa-solid fa-flask-vial mr-2 text-indigo-400"></i> Laboratory & Diagnostic Results (${data.diagnostics.length})
                </h4>
                <div class="space-y-1.5">
                    ${data.diagnostics.map(dr => `
                        <div class="bg-slate-950 p-2.5 rounded-lg border border-slate-800 flex items-center justify-between text-slate-300">
                            <div>
                                <span class="font-semibold text-white mr-2">${dr.test_name}</span>
                                <span class="text-[10px] font-mono text-slate-400">${dr.category} • ${dr.order_date || ''}</span>
                                ${dr.interpretation_notes ? `<p class="text-[11px] text-slate-400 italic mt-0.5">${dr.interpretation_notes}</p>` : ''}
                            </div>
                            <div class="text-right">
                                <span class="font-mono font-bold text-sm ${dr.flag === 'CRITICAL' ? 'text-rose-400' : dr.flag === 'HIGH' ? 'text-orange-400' : dr.flag === 'LOW' ? 'text-blue-400' : 'text-emerald-400'}">
                                    ${dr.numeric_result !== null ? dr.numeric_result : (dr.text_result || 'Pending')} ${dr.unit || ''}
                                </span>
                                <span class="px-2 py-0.5 rounded text-[10px] font-bold block mt-0.5 ${dr.flag === 'CRITICAL' ? 'bg-rose-950 text-rose-300 border border-rose-800' : 'bg-slate-800 text-slate-300'}">
                                    ${dr.flag}
                                </span>
                            </div>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;

        document.getElementById('dossierModal').classList.remove('hidden');
    } catch (err) {
        showToast('Error opening dossier: ' + err.message, 'error');
    }
}

function openPatientDossierByAdmission(admissionId) {
    fetch(`/api/admissions?status=ALL`)
        .then(r => r.json())
        .then(adms => {
            const adm = adms.find(a => a.admission_id === admissionId);
            if (adm) openPatientDossier(adm.patient_id);
        });
}

function closeDossierModal() {
    document.getElementById('dossierModal').classList.add('hidden');
}

async function dischargeAdmission(admissionId, patientId) {
    if (!confirm('Discharge this patient? The DBMS trigger will compute actual Length of Stay (LOS) and record the audit log.')) return;
    try {
        const res = await fetch(`/api/admissions/${admissionId}/discharge`, { method: 'POST' });
        const data = await res.json();
        if (data.success) {
            showToast('Patient discharged successfully. Trigger updated LOS & CMI.', 'success');
            openPatientDossier(patientId);
            loadDashboardStats();
            loadCaseMixData();
        } else {
            showToast('Discharge failed: ' + data.error, 'error');
        }
    } catch (err) {
        showToast('Discharge error: ' + err.message, 'error');
    }
}

// -----------------------------------------------------------------------------
// DRG Master Catalog
// -----------------------------------------------------------------------------
async function loadDrgCatalog() {
    try {
        const res = await fetch('/api/drg-catalog');
        const drgs = await res.json();
        document.getElementById('drgCountBadge').innerText = `${drgs.length} MS-DRG Categories`;

        const tbody = document.getElementById('drgTableBody');
        tbody.innerHTML = drgs.map(d => `
            <tr class="hover:bg-slate-800/40 transition-colors">
                <td class="px-4 py-3 font-bold text-cyan-400">${d.drg_code}</td>
                <td class="px-4 py-3 font-sans text-slate-200 font-medium">${d.drg_title}</td>
                <td class="px-4 py-3 font-sans text-slate-400 text-xs">${d.mdc_code}</td>
                <td class="px-4 py-3 text-center font-bold text-amber-400">${Number(d.relative_weight).toFixed(4)}</td>
                <td class="px-4 py-3 text-center font-sans">
                    <span class="px-2 py-0.5 rounded text-[10px] font-semibold ${
                        d.severity_level.includes('Extreme') ? 'bg-rose-950 text-rose-300 border border-rose-800' :
                        d.severity_level.includes('Major') ? 'bg-amber-950 text-amber-300 border border-amber-800' :
                        'bg-slate-800 text-slate-300 border border-slate-700'
                    }">
                        ${d.severity_level}
                    </span>
                </td>
                <td class="px-4 py-3 text-center text-slate-300">${d.geometric_mean_los} days</td>
                <td class="px-4 py-3 text-right text-emerald-400 font-semibold font-mono">
                    $${Number(d.base_payment_rate * d.relative_weight).toLocaleString(undefined, {maximumFractionDigits: 2})}
                </td>
            </tr>
        `).join('');
    } catch (err) {
        console.error('Failed to load DRG catalog:', err);
    }
}

// -----------------------------------------------------------------------------
// DBMS SQL Workbench (Interactive Query Console)
// -----------------------------------------------------------------------------
async function loadSampleQueries() {
    try {
        const res = await fetch('/api/sample-queries');
        const queries = await res.json();
        const container = document.getElementById('sampleQueriesButtons');

        container.innerHTML = queries.map(q => `
            <button onclick="loadSampleQueryIntoEditor(${q.id})" 
                    class="bg-slate-900 hover:bg-cyan-950 hover:text-cyan-300 text-slate-300 text-[11px] px-2.5 py-1.5 rounded border border-slate-800 transition-colors font-medium">
                ${q.id}. ${q.title}
            </button>
        `).join('');

        window._sampleQueriesCache = queries;
        // Load Query 1 by default
        loadSampleQueryIntoEditor(1);
    } catch (err) {
        console.error('Failed to load sample queries:', err);
    }
}

function loadSampleQueryIntoEditor(id) {
    if (!window._sampleQueriesCache) return;
    const q = window._sampleQueriesCache.find(x => x.id === id);
    if (q) {
        document.getElementById('sqlQueryInput').value = q.sql;
        document.getElementById('queryStatusText').innerText = `Loaded Query ${q.id}: ${q.concept}`;
    }
}

async function executeCurrentQuery() {
    const sql = document.getElementById('sqlQueryInput').value.trim();
    if (!sql) {
        showToast('Please enter an SQL query first.', 'error');
        return;
    }

    const metricsEl = document.getElementById('queryResultMetrics');
    const container = document.getElementById('queryOutputContainer');
    metricsEl.innerHTML = `<i class="fa-solid fa-spinner fa-spin mr-1"></i> Running query...`;

    try {
        const res = await fetch('/api/query', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ sql })
        });
        const result = await res.json();

        if (!result.success) {
            metricsEl.innerHTML = `<span class="text-rose-400 font-bold"><i class="fa-solid fa-circle-xmark mr-1"></i> Query Error (${result.duration_ms} ms)</span>`;
            container.innerHTML = `
                <div class="p-4 bg-rose-950/40 border border-rose-900 text-rose-300 text-xs font-mono rounded-lg m-4">
                    <strong>DBMS Error:</strong> ${result.error}
                </div>
            `;
            document.getElementById('exportCsvBtn').disabled = true;
            return;
        }

        currentQueryResults = result;
        document.getElementById('exportCsvBtn').disabled = false;
        metricsEl.innerHTML = `<span class="text-emerald-400 font-semibold"><i class="fa-solid fa-check mr-1"></i> ${result.row_count} rows returned in ${result.duration_ms} ms</span>`;

        // Render dynamic output table
        let tableHtml = `
            <table class="w-full text-left text-xs text-slate-300 font-mono">
                <thead class="bg-slate-950/90 text-cyan-400 font-bold text-[11px] sticky top-0 border-b border-slate-800">
                    <tr>
                        ${result.columns.map(c => `<th class="px-4 py-2.5 whitespace-nowrap">${c}</th>`).join('')}
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/60 text-xs">
                    ${result.rows.map(r => `
                        <tr class="hover:bg-slate-800/40 transition-colors">
                            ${r.map(val => `<td class="px-4 py-2 whitespace-nowrap text-slate-200">${val !== null ? val : '<span class="text-slate-600">NULL</span>'}</td>`).join('')}
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        `;
        container.innerHTML = tableHtml;
    } catch (err) {
        metricsEl.innerHTML = `<span class="text-rose-400">Connection error</span>`;
        container.innerHTML = `<div class="p-4 text-rose-400 text-xs">${err.message}</div>`;
    }
}

function exportQueryResultsCSV() {
    if (!currentQueryResults || !currentQueryResults.rows.length) return;
    const cols = currentQueryResults.columns;
    const rows = currentQueryResults.rows;

    let csvContent = "data:text/csv;charset=utf-8," + cols.join(",") + "\n" +
        rows.map(r => r.map(v => `"${(v !== null ? v : '').toString().replace(/"/g, '""')}"`).join(",")).join("\n");

    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `dbms_query_export_${Date.now()}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
}

// -----------------------------------------------------------------------------
// Schema & ER Metadata Explorer
// -----------------------------------------------------------------------------
async function loadSchemaMetadata() {
    try {
        const res = await fetch('/api/schema-meta');
        const meta = await res.json();
        window._schemaMetaCache = meta;

        // Render table tabs
        const tabsContainer = document.getElementById('schemaTableTabs');
        tabsContainer.innerHTML = meta.tables.map((t, idx) => `
            <button onclick="renderTableSchema('${t.table_name}')" 
                    id="schema-btn-${t.table_name}"
                    class="px-3 py-1.5 rounded text-xs font-mono font-medium border border-slate-800 transition-colors ${idx === 0 ? 'bg-cyan-950 text-cyan-300 border-cyan-700' : 'bg-slate-900 text-slate-400 hover:text-white'}">
                ${t.table_name} (${t.row_count})
            </button>
        `).join('');

        if (meta.tables.length) {
            renderTableSchema(meta.tables[0].table_name);
        }

        // Render triggers
        const trgContainer = document.getElementById('schemaTriggersContainer');
        trgContainer.innerHTML = meta.triggers.map(trg => `
            <div class="bg-slate-950 p-3 rounded-lg border border-slate-800">
                <div class="font-mono font-bold text-amber-400 mb-1 flex items-center">
                    <i class="fa-solid fa-gear mr-1.5 text-xs"></i> ${trg.name}
                </div>
                <pre class="bg-slate-900/80 p-2 rounded text-[11px] font-mono text-slate-300 overflow-x-auto whitespace-pre-wrap">${trg.sql}</pre>
            </div>
        `).join('');

        // Render views
        const viewsContainer = document.getElementById('schemaViewsContainer');
        viewsContainer.innerHTML = meta.views.map(v => `
            <div class="bg-slate-950 p-3 rounded-lg border border-slate-800">
                <div class="font-mono font-bold text-teal-400 mb-1 flex items-center">
                    <i class="fa-solid fa-eye mr-1.5 text-xs"></i> ${v.name}
                </div>
                <pre class="bg-slate-900/80 p-2 rounded text-[11px] font-mono text-slate-300 overflow-x-auto whitespace-pre-wrap">${v.sql}</pre>
            </div>
        `).join('');
    } catch (err) {
        console.error('Failed to load schema meta:', err);
    }
}

function renderTableSchema(tableName) {
    if (!window._schemaMetaCache) return;
    const table = window._schemaMetaCache.tables.find(t => t.table_name === tableName);
    if (!table) return;

    // Highlight button
    window._schemaMetaCache.tables.forEach(t => {
        const btn = document.getElementById(`schema-btn-${t.table_name}`);
        if (btn) {
            if (t.table_name === tableName) {
                btn.className = 'px-3 py-1.5 rounded text-xs font-mono font-medium border bg-cyan-950 text-cyan-300 border-cyan-700';
            } else {
                btn.className = 'px-3 py-1.5 rounded text-xs font-mono font-medium border bg-slate-900 text-slate-400 hover:text-white border-slate-800';
            }
        }
    });

    const container = document.getElementById('schemaTableDetail');
    container.innerHTML = `
        <div class="flex items-center justify-between mb-3 border-b border-slate-800 pb-2">
            <div>
                <h4 class="text-sm font-bold text-white font-mono flex items-center">
                    <i class="fa-solid fa-table text-cyan-400 mr-2"></i> Table: ${table.table_name}
                </h4>
                <span class="text-xs text-slate-400">Total Records: <strong class="text-cyan-400">${table.row_count}</strong></span>
            </div>
            <button onclick="loadSampleQueryIntoEditorRaw('SELECT * FROM ${table.table_name} LIMIT 20;')" class="text-xs text-cyan-400 hover:underline">
                Query Table <i class="fa-solid fa-arrow-right"></i>
            </button>
        </div>

        <div class="overflow-x-auto">
            <table class="w-full text-left text-xs font-mono text-slate-300">
                <thead class="bg-slate-900 text-slate-400 text-[10px] uppercase">
                    <tr>
                        <th class="px-3 py-2">Column</th>
                        <th class="px-3 py-2">Data Type</th>
                        <th class="px-3 py-2 text-center">PK</th>
                        <th class="px-3 py-2 text-center">Not Null</th>
                        <th class="px-3 py-2">Default</th>
                    </tr>
                </thead>
                <tbody class="divide-y divide-slate-800/60">
                    ${table.columns.map(c => `
                        <tr>
                            <td class="px-3 py-1.5 font-bold ${c.pk ? 'text-amber-400' : 'text-slate-200'}">
                                ${c.pk ? '<i class="fa-solid fa-key text-[10px] mr-1 text-amber-400"></i>' : ''}
                                ${c.name}
                            </td>
                            <td class="px-3 py-1.5 text-cyan-400">${c.type}</td>
                            <td class="px-3 py-1.5 text-center">${c.pk ? 'YES' : '-'}</td>
                            <td class="px-3 py-1.5 text-center">${c.notnull ? 'YES' : '-'}</td>
                            <td class="px-3 py-1.5 text-slate-500">${c.dflt_value || 'NULL'}</td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>

        ${table.foreign_keys.length ? `
            <div class="mt-3 pt-2 border-t border-slate-800 text-[11px] text-slate-400">
                <strong class="text-slate-300">Foreign Key Constraints:</strong>
                <ul class="list-disc pl-5 mt-1 space-y-0.5">
                    ${table.foreign_keys.map(fk => `
                        <li><span class="text-cyan-400 font-mono">${fk.from}</span> &rarr; references <span class="text-teal-400 font-mono">${fk.table}(${fk.to})</span> [ON DELETE ${fk.on_delete}]</li>
                    `).join('')}
                </ul>
            </div>
        ` : ''}
    `;
}

function loadSampleQueryIntoEditorRaw(sql) {
    switchTab('workbench');
    document.getElementById('sqlQueryInput').value = sql;
    executeCurrentQuery();
}

// -----------------------------------------------------------------------------
// Modals: Order Test & Admit Patient & Register Patient
// -----------------------------------------------------------------------------
function openOrderModal() {
    // Populate active admissions
    fetch('/api/admissions?status=ALL')
        .then(r => r.json())
        .then(admissions => {
            const select = document.getElementById('orderAdmissionSelect');
            select.innerHTML = '<option value="">-- Choose Admission / Patient --</option>' +
                admissions.map(a => `<option value="${a.admission_id}">${a.admission_no} - ${a.patient_name} (${a.dept_name}) [${a.status}]</option>`).join('');
            document.getElementById('orderModal').classList.remove('hidden');
        });
}

function closeOrderModal() {
    document.getElementById('orderModal').classList.add('hidden');
}

function onTestSelectedChange() {
    const testId = Number(document.getElementById('orderTestSelect').value);
    const help = document.getElementById('testInfoHelp');
    if (!testId) { help.classList.add('hidden'); return; }

    const t = catalogTests.find(x => x.test_id === testId);
    if (t) {
        help.classList.remove('hidden');
        help.innerText = `Normal: ${t.normal_range_min || '-'} to ${t.normal_range_max || '-'} ${t.unit || ''} | Critical High: ${t.critical_high || '-'}`;
    }
}

async function submitDiagnosticOrder(e) {
    e.preventDefault();
    const admission_id = Number(document.getElementById('orderAdmissionSelect').value);
    const test_id = Number(document.getElementById('orderTestSelect').value);
    const ordered_by_physician_id = Number(document.getElementById('orderPhysicianSelect').value);
    const numeric_result_val = document.getElementById('orderNumericResult').value;
    const numeric_result = numeric_result_val ? parseFloat(numeric_result_val) : null;
    const text_result = document.getElementById('orderTextResult').value.trim() || null;
    const interpretation_notes = document.getElementById('orderNotes').value.trim() || null;

    try {
        const res = await fetch('/api/diagnostics/order', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                admission_id,
                test_id,
                ordered_by_physician_id,
                numeric_result,
                text_result,
                interpretation_notes
            })
        });
        const data = await res.json();
        if (data.success) {
            closeOrderModal();
            showToast(`Diagnostic order created! Trigger evaluated flag: ${data.record.flag}`, 'success');
            loadDashboardStats();
            loadDiagnosticRecords();
            switchTab('diagnostics');
        } else {
            showToast('Order failed: ' + data.error, 'error');
        }
    } catch (err) {
        showToast('Error: ' + err.message, 'error');
    }
}

function promptUpdateResult(recordId, testName) {
    const val = prompt(`Enter quantitative test result value for ${testName}:\n(DBMS trigger will immediately evaluate Normal/High/Low/Critical)`);
    if (val === null || val.trim() === '') return;

    const num = parseFloat(val);
    if (isNaN(num)) {
        alert('Please enter a valid numeric value.');
        return;
    }

    fetch(`/api/diagnostics/${recordId}/result`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ numeric_result: num })
    })
    .then(r => r.json())
    .then(data => {
        if (data.success) {
            showToast(`Result updated! DBMS Trigger set Flag: ${data.record.flag}`, 'success');
            loadDashboardStats();
            loadDiagnosticRecords();
        } else {
            showToast('Update failed: ' + data.error, 'error');
        }
    });
}

function openAdmitModal() {
    fetch('/api/patients')
        .then(r => r.json())
        .then(patients => {
            const select = document.getElementById('admitPatientSelect');
            select.innerHTML = '<option value="">-- Choose Patient --</option>' +
                patients.map(p => `<option value="${p.patient_id}">${p.mrn} - ${p.first_name} ${p.last_name}</option>`).join('');
            document.getElementById('admitModal').classList.remove('hidden');
        });
}

function closeAdmitModal() {
    document.getElementById('admitModal').classList.add('hidden');
}

async function submitAdmission(e) {
    e.preventDefault();
    const payload = {
        patient_id: Number(document.getElementById('admitPatientSelect').value),
        dept_id: Number(document.getElementById('admitDeptSelect').value),
        attending_physician_id: Number(document.getElementById('admitPhysicianSelect').value),
        admission_type: document.getElementById('admitTypeSelect').value,
        admission_source: document.getElementById('admitSourceInput').value,
        assigned_drg_id: Number(document.getElementById('admitDrgSelect').value),
        icd10_code: document.getElementById('admitIcd10').value.trim() || null,
        total_charges: parseFloat(document.getElementById('admitCharges').value) || 5000.00
    };

    try {
        const res = await fetch('/api/admissions', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.success) {
            closeAdmitModal();
            showToast(`Patient admitted successfully under ${data.admission.admission_no}!`, 'success');
            loadDashboardStats();
            loadCaseMixData();
            switchTab('casemix');
        } else {
            showToast('Admission failed: ' + data.error, 'error');
        }
    } catch (err) {
        showToast('Error: ' + err.message, 'error');
    }
}

function openPatientModal() {
    document.getElementById('patientModal').classList.remove('hidden');
}

function closePatientModal() {
    document.getElementById('patientModal').classList.add('hidden');
}

async function submitPatient(e) {
    e.preventDefault();
    const payload = {
        first_name: document.getElementById('patFirstName').value.trim(),
        last_name: document.getElementById('patLastName').value.trim(),
        dob: document.getElementById('patDob').value,
        gender: document.getElementById('patGender').value,
        blood_group: document.getElementById('patBlood').value,
        insurance_provider: document.getElementById('patInsurance').value.trim(),
        contact_phone: document.getElementById('patPhone').value.trim()
    };

    try {
        const res = await fetch('/api/patients', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });
        const data = await res.json();
        if (data.success) {
            closePatientModal();
            showToast(`Patient registered! Generated MRN: ${data.patient.mrn}`, 'success');
            loadPatients();
            switchTab('patients');
        } else {
            showToast('Registration failed: ' + data.error, 'error');
        }
    } catch (err) {
        showToast('Error: ' + err.message, 'error');
    }
}
