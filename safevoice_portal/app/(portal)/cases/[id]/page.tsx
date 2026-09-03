'use client';

import { useQuery } from '@tanstack/react-query';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { casesApi } from '@/lib/api/cases';
import { useAuthStore } from '@/lib/store/authStore';
import StatusTimeline from '@/components/cases/StatusTimeline';
import StatusUpdateForm from '@/components/cases/StatusUpdateForm';
import InvestigationNotes from '@/components/cases/InvestigationNotes';
import SensitiveDataBadge from '@/components/shared/SensitiveDataBadge';
import RoleGuard from '@/components/shared/RoleGuard';
import AssignCasePanel from '@/components/cases/AssignCasePanel';
import OfficerReportPanel from '@/components/cases/OfficerReportPanel';
import { hasPermission } from '@/lib/utils/permissions';
import { UserRole } from '@/lib/types';

export default function CaseDetailPage() {
  const { id } = useParams<{ id: string }>();
  const user = useAuthStore((s) => s.user);

  const { data, isLoading, isError } = useQuery({
    queryKey: ['case', id],
    queryFn: () => casesApi.detail(id),
    retry: false,
  });

  if (isLoading) return <p className="text-gray-500 py-8 text-center">Loading case…</p>;
  if (isError || !data) {
    return (
      <div className="max-w-xl mx-auto mt-16 text-center space-y-4">
        <p className="text-5xl">🔒</p>
        <p className="text-lg font-semibold text-gray-700">Access Denied</p>
        <p className="text-sm text-gray-500">
          This case is not assigned to you, or it does not exist.
          Cases become accessible after they are assigned to you by a supervisor.
        </p>
        <Link href="/cases" className="inline-block mt-2 text-sm text-blue-600 hover:underline">
          ← Back to Cases
        </Link>
      </div>
    );
  }

  const c = data.data;
  const role = user?.role as UserRole | undefined;
  const hasTier1 = role && hasPermission(role, 'view_tier1');
  const canUpdateStatus = role && hasPermission(role, 'update_status');
  const canAssign = role && hasPermission(role, 'assign_cases');

  // Detect if tier1 fields were returned by backend
  const tier1Available = !!(c.victimName || c.victimContact || c.locationText);

  return (
    <div className="space-y-6 max-w-4xl">
      {/* Header */}
      <div className="flex items-center gap-3 flex-wrap">
        <Link href="/cases" className="text-sm text-gray-400 hover:text-gray-600">← Cases</Link>
        <h1 className="text-xl font-bold text-gray-900">
          Case {c.id.slice(0, 8).toUpperCase()}
        </h1>
        <span className={`px-2 py-0.5 text-xs rounded font-medium ${
          c.riskLevel === 'High'   ? 'bg-red-100 text-red-700' :
          c.riskLevel === 'Medium' ? 'bg-amber-100 text-amber-700' :
                                     'bg-green-100 text-green-700'
        }`}>{c.riskLevel} Risk</span>
        <span className="px-2 py-0.5 text-xs rounded font-medium bg-gray-100 text-gray-600">
          {c.status}
        </span>
      </div>

      {/* Access level banner */}
      {hasTier1 ? (
        <div className="flex items-center gap-2 text-xs text-green-700 bg-green-50 border border-green-200 rounded-lg px-4 py-2">
          🔓 You have Tier 1 access — full case details including victim information are visible.
        </div>
      ) : (
        <div className="flex items-center gap-2 text-xs text-amber-700 bg-amber-50 border border-amber-200 rounded-lg px-4 py-2">
          🔒 Limited access — victim identity and location are not visible at your access level.
        </div>
      )}

      {/* Core fields — visible to all portal roles */}
      <div className="bg-white border border-gray-200 rounded-xl p-5 space-y-4">
        <h2 className="text-sm font-semibold text-gray-700 mb-2">Case Information</h2>
        <div className="grid grid-cols-2 gap-4">
          <Field label="Incident Type"
            value={(c.incidentType ?? '').replace(/([A-Z])/g, ' $1').trim()} />
          <Field label="Status" value={c.status ?? ''} />
          <Field label="District" value={c.district ?? '—'} />
          <Field label="Submitted"
            value={c.submittedAt ? new Date(c.submittedAt).toLocaleString() : '—'} />
          {(c as any).assignedOfficerName && (
            <Field label="Assigned Officer" value={(c as any).assignedOfficerName} />
          )}
          {(c as any).assignedAt && (
            <Field label="Assigned At"
              value={new Date((c as any).assignedAt).toLocaleString()} />
          )}
          {c.description && (
            <Field label="Description" value={c.description} className="col-span-2" />
          )}
        </div>
      </div>

      {/* Assignment Panel — Head / Supervisor only */}
      {canAssign && user && (
        <AssignCasePanel
          caseId={id}
          currentOfficerName={(c as any).assignedOfficerName}
          userRole={user.role}
        />
      )}

      {/* Tier 1 — Victim identity — only if backend returned fields */}
      {tier1Available ? (
        <SensitiveDataBadge label="Victim Identity (Tier 1 — Confidential)">
          <div className="grid grid-cols-2 gap-3 mt-2">
            {c.victimName    && <Field label="Victim Name"    value={c.victimName} />}
            {c.victimContact && <Field label="Contact Number" value={c.victimContact} />}
            {c.locationText  && (
              <div className="col-span-2">
                <p className="text-xs text-gray-400 font-medium uppercase tracking-wide mb-0.5">
                  Incident Location
                </p>
                <p className="text-sm text-gray-800">{c.locationText}</p>
                {(c as any).latitude && (c as any).longitude && (
                  <a
                    href={`https://www.google.com/maps/search/?api=1&query=${(c as any).latitude},${(c as any).longitude}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-1 mt-1 text-xs text-blue-600 hover:underline"
                  >
                    🗺️ Open in Google Maps
                  </a>
                )}
              </div>
            )}
          </div>
        </SensitiveDataBadge>
      ) : hasTier1 ? (
        <div className="bg-gray-50 border border-gray-200 rounded-xl p-4 text-sm text-gray-500">
          No victim identity information was provided for this case.
        </div>
      ) : null}

      {/* Evidence */}
      <div className="bg-white border border-gray-200 rounded-xl p-4 flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-700">📎 Evidence</p>
          <p className="text-xs text-gray-400 mt-0.5">Photos, audio, video, and documents</p>
        </div>
        <Link
          href={`/cases/${id}/evidence`}
          className="text-sm text-blue-600 hover:underline font-medium"
        >
          View Evidence →
        </Link>
      </div>

      {/* Status update */}
      {canUpdateStatus && user && (
        <RoleGuard permission="update_status">
          <StatusUpdateForm caseId={id} currentStatus={c.status} userRole={user.role} />
        </RoleGuard>
      )}

      {/* Officer Reports */}
      {user && (
        <OfficerReportPanel caseId={id} userRole={user.role} />
      )}

      {/* Status timeline */}
      <div className="bg-white border border-gray-200 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-gray-700 mb-4">Status History</h3>
        <StatusTimeline history={c.statusHistory ?? []} />
      </div>

      {/* Investigation notes */}
      <div className="bg-white border border-gray-200 rounded-xl p-5">
        <InvestigationNotes caseId={id} notes={c.notes ?? []} />
      </div>
    </div>
  );
}

function Field({
  label, value, className = '',
}: {
  label: string; value: string; className?: string;
}) {
  return (
    <div className={className}>
      <p className="text-xs text-gray-400 font-medium uppercase tracking-wide">{label}</p>
      <p className="text-sm text-gray-800 mt-0.5 break-words">{value || '—'}</p>
    </div>
  );
}
