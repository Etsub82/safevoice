'use client';

import { useQuery } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import StatCard from '@/components/dashboard/StatCard';
import RiskChart from '@/components/dashboard/RiskChart';
import { casesApi } from '@/lib/api/cases';
import { useAuthStore } from '@/lib/store/authStore';
import { hasPermission } from '@/lib/utils/permissions';
import { CaseListItem, CaseStatus } from '@/lib/types';

function tally(items: CaseListItem[], key: keyof CaseListItem) {
  return items.reduce<Record<string, number>>((acc, item) => {
    const val = String(item[key] ?? 'Unknown');
    acc[val] = (acc[val] ?? 0) + 1;
    return acc;
  }, {});
}

const STATUS_ORDER: CaseStatus[] = [
  'Submitted','Received','Triaged','Assigned','Investigation',
  'Escalated','Reassigned','ReferredToJustice','CourtProcess','Resolved','Closed',
];

export default function DashboardPage() {
  const router = useRouter();
  const user = useAuthStore((s) => s.user);

  const { data, isLoading } = useQuery({
    queryKey: ['cases', 'dashboard'],
    queryFn: () => casesApi.list({ pageSize: 1000 }),
    refetchInterval: 60_000,
  });

  const cases: CaseListItem[] = data?.data.items ?? [];
  const byStatus = tally(cases, 'status');
  const byRisk   = tally(cases, 'riskLevel');

  const riskData = [
    { name: 'High',   value: byRisk['High']   ?? 0 },
    { name: 'Medium', value: byRisk['Medium'] ?? 0 },
    { name: 'Low',    value: byRisk['Low']    ?? 0 },
  ];

  const highRiskCases   = cases.filter((c) => c.riskLevel === 'High');
  const escalatedCases  = cases.filter((c) => c.status === 'Escalated');
  const submittedCases  = cases.filter((c) => c.status === 'Submitted' || c.status === 'Received');
  const referredCases   = cases.filter((c) => c.status === 'ReferredToJustice');
  const courtCases      = cases.filter((c) => c.status === 'CourtProcess');

  if (isLoading) return <p className="text-gray-400 py-8">Loading dashboard…</p>;

  const role = user?.role ?? 'Officer';
  const canManageCases  = hasPermission(role, 'update_status');
  const canViewAudit    = hasPermission(role, 'view_audit_log');
  const canManageUsers  = hasPermission(role, 'manage_users');
  const canAssign       = hasPermission(role, 'assign_cases');

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="text-sm text-gray-500 mt-1">
          {user?.username} · <span className="font-medium text-gray-700">{role.replace(/([A-Z])/g, ' $1').trim()}</span> · {user?.organization}
        </p>
      </div>

      {/* Role-specific alert banner */}
      {escalatedCases.length > 0 && canManageCases && (
        <div className="bg-red-50 border border-red-200 rounded-xl px-5 py-4 flex items-center justify-between">
          <div>
            <p className="text-sm font-semibold text-red-700">⚠️ {escalatedCases.length} Escalated Case{escalatedCases.length > 1 ? 's' : ''} Require Attention</p>
            <p className="text-xs text-red-500 mt-0.5">These cases need immediate review or reassignment.</p>
          </div>
          <button onClick={() => router.push('/cases?status=Escalated')} className="text-xs text-red-700 font-semibold underline">View Escalated</button>
        </div>
      )}

      {submittedCases.length > 0 && canAssign && (
        <div className="bg-amber-50 border border-amber-200 rounded-xl px-5 py-4 flex items-center justify-between">
          <div>
            <p className="text-sm font-semibold text-amber-700">📥 {submittedCases.length} New Case{submittedCases.length > 1 ? 's' : ''} Awaiting Assignment</p>
            <p className="text-xs text-amber-500 mt-0.5">Unassigned cases need to be triaged and assigned.</p>
          </div>
          <button onClick={() => router.push('/cases?status=Submitted')} className="text-xs text-amber-700 font-semibold underline">Assign Cases</button>
        </div>
      )}

      {referredCases.length > 0 && role === 'Prosecutor' && (
        <div className="bg-blue-50 border border-blue-200 rounded-xl px-5 py-4 flex items-center justify-between">
          <div>
            <p className="text-sm font-semibold text-blue-700">⚖️ {referredCases.length} Case{referredCases.length > 1 ? 's' : ''} Referred to Justice</p>
            <p className="text-xs text-blue-500 mt-0.5">Cases referred from police awaiting prosecution review.</p>
          </div>
          <button onClick={() => router.push('/cases?status=ReferredToJustice')} className="text-xs text-blue-700 font-semibold underline">Review</button>
        </div>
      )}

      {/* Stat cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <StatCard label="Total Cases"           value={cases.length}                        color="blue"  />
        <StatCard label="High Risk"             value={byRisk['High']   ?? 0}               color="red"   />
        <StatCard label="Under Investigation"   value={byStatus['Investigation'] ?? 0}      color="amber" />
        <StatCard label="Resolved"              value={(byStatus['Resolved'] ?? 0) + (byStatus['Closed'] ?? 0)} color="green" />
      </div>

      {/* Charts + status breakdown */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <RiskChart data={riskData} />
        <div className="bg-white border border-gray-200 rounded-xl p-5">
          <h3 className="text-sm font-semibold text-gray-700 mb-3">Cases by Status</h3>
          <ul className="space-y-2">
            {STATUS_ORDER.filter((s) => byStatus[s]).map((status) => (
              <li key={status} className="flex justify-between items-center text-sm">
                <button
                  onClick={() => router.push(`/cases`)}
                  className="text-gray-600 hover:text-primary hover:underline text-left"
                >
                  {status.replace(/([A-Z])/g, ' $1').trim()}
                </button>
                <span className="font-semibold text-gray-900">{byStatus[status]}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>

      {/* Role-specific quick action panels */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">

        {/* High risk cases — for officers, supervisors, prosecutors */}
        {canManageCases && highRiskCases.length > 0 && (
          <div className="bg-white border border-red-200 rounded-xl p-5">
            <h3 className="text-sm font-semibold text-red-700 mb-3">🔴 High Risk Cases</h3>
            <ul className="space-y-2">
              {highRiskCases.slice(0, 5).map((c) => (
                <li key={c.id}>
                  <button
                    onClick={() => router.push(`/cases/${c.id}`)}
                    className="w-full flex justify-between items-center text-sm hover:bg-red-50 px-2 py-1.5 rounded-lg transition"
                  >
                    <span className="text-gray-700">{c.incidentType.replace(/([A-Z])/g, ' $1').trim()}</span>
                    <span className="text-xs text-gray-400">{c.district} · {c.status}</span>
                  </button>
                </li>
              ))}
            </ul>
            {highRiskCases.length > 5 && (
              <button onClick={() => router.push('/cases')} className="text-xs text-primary mt-2 hover:underline">View all {highRiskCases.length} high risk cases →</button>
            )}
          </div>
        )}

        {/* Referred to justice — for prosecutors, judges */}
        {(role === 'Prosecutor' || role === 'PublicProsecutor' || role === 'Judge' || role === 'CourtClerk') && courtCases.concat(referredCases).length > 0 && (
          <div className="bg-white border border-blue-200 rounded-xl p-5">
            <h3 className="text-sm font-semibold text-blue-700 mb-3">⚖️ Justice Queue</h3>
            <ul className="space-y-2">
              {[...referredCases, ...courtCases].slice(0, 5).map((c) => (
                <li key={c.id}>
                  <button
                    onClick={() => router.push(`/cases/${c.id}`)}
                    className="w-full flex justify-between items-center text-sm hover:bg-blue-50 px-2 py-1.5 rounded-lg transition"
                  >
                    <span className="text-gray-700">{c.incidentType.replace(/([A-Z])/g, ' $1').trim()}</span>
                    <span className="text-xs text-gray-400">{c.status}</span>
                  </button>
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* Audit summary — for auditors and admins */}
        {canViewAudit && (
          <div className="bg-white border border-gray-200 rounded-xl p-5">
            <h3 className="text-sm font-semibold text-gray-700 mb-3">🔍 Audit Activity</h3>
            <p className="text-xs text-gray-500 mb-3">Recent sensitive actions logged in the system.</p>
            <div className="space-y-2 text-sm text-gray-600">
              <div className="flex justify-between"><span>VICTIM_IDENTITY_ACCESSED</span><span className="text-red-600 font-semibold">1</span></div>
              <div className="flex justify-between"><span>EVIDENCE_ACCESSED</span><span className="text-red-600 font-semibold">1</span></div>
              <div className="flex justify-between"><span>CASE_STATUS_CHANGED</span><span className="font-semibold">1</span></div>
              <div className="flex justify-between"><span>INVESTIGATION_NOTE_ADDED</span><span className="font-semibold">1</span></div>
            </div>
            <button onClick={() => router.push('/audit')} className="mt-3 text-xs text-primary hover:underline">View full audit log →</button>
          </div>
        )}

        {/* User management — for admins */}
        {canManageUsers && (
          <div className="bg-white border border-gray-200 rounded-xl p-5">
            <h3 className="text-sm font-semibold text-gray-700 mb-3">⚙️ Administration</h3>
            <div className="space-y-2">
              <button onClick={() => router.push('/admin/users')} className="w-full flex justify-between items-center text-sm text-gray-700 hover:bg-gray-50 px-2 py-2 rounded-lg transition">
                <span>👤 Manage Users</span>
                <span className="text-xs text-gray-400">6 active users →</span>
              </button>
              <button onClick={() => router.push('/admin/organizations')} className="w-full flex justify-between items-center text-sm text-gray-700 hover:bg-gray-50 px-2 py-2 rounded-lg transition">
                <span>🏢 Organizations</span>
                <span className="text-xs text-gray-400">5 organizations →</span>
              </button>
            </div>
          </div>
        )}

        {/* Lawyer — assigned cases only */}
        {(role === 'Lawyer' || role === 'LegalAid') && (
          <div className="bg-white border border-gray-200 rounded-xl p-5">
            <h3 className="text-sm font-semibold text-gray-700 mb-3">📁 My Assigned Cases</h3>
            <p className="text-xs text-gray-500 mb-3">You have access only to cases assigned to you.</p>
            <button onClick={() => router.push('/cases')} className="text-sm text-primary hover:underline">View assigned cases →</button>
          </div>
        )}

        {/* Social worker */}
        {role === 'SocialWorker' && (
          <div className="bg-white border border-gray-200 rounded-xl p-5">
            <h3 className="text-sm font-semibold text-gray-700 mb-3">🤝 Support Cases</h3>
            <p className="text-xs text-gray-500 mb-3">Cases referred to your organization for support services.</p>
            <button onClick={() => router.push('/cases')} className="text-sm text-primary hover:underline">View referred cases →</button>
          </div>
        )}
      </div>
    </div>
  );
}
