'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { auditApi } from '@/lib/api/audit';
import AuditLogTable from '@/components/audit/AuditLogTable';
import RoleGuard from '@/components/shared/RoleGuard';

export default function AuditLogPage() {
  const [eventType, setEventType] = useState('');
  const [caseId, setCaseId] = useState('');
  const [page, setPage] = useState(1);

  const { data, isLoading } = useQuery({
    queryKey: ['audit', { eventType, caseId, page }],
    queryFn: () => auditApi.list({
      eventType: (eventType || undefined) as any,
      caseId: caseId || undefined,
      page,
      pageSize: 50,
    }),
  });

  const entries = data?.data.items ?? [];
  const total = data?.data.total ?? 0;
  const pages = Math.ceil(total / 50);

  return (
    <RoleGuard permission="view_audit_log">
      <div className="space-y-5">
        <h1 className="text-2xl font-bold text-gray-900">Audit Log</h1>

        <div className="flex gap-3 flex-wrap">
          <select
            value={eventType}
            onChange={(e) => { setEventType(e.target.value); setPage(1); }}
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
          >
            <option value="">All Events</option>
            {['CASE_VIEWED','VICTIM_IDENTITY_ACCESSED','EVIDENCE_ACCESSED','CASE_STATUS_CHANGED','CASE_ASSIGNMENT_CHANGED','INVESTIGATION_NOTE_ADDED','ADMIN_USER_MODIFIED'].map((e) => (
              <option key={e} value={e}>{e.replace(/_/g, ' ')}</option>
            ))}
          </select>
          <input
            value={caseId}
            onChange={(e) => { setCaseId(e.target.value); setPage(1); }}
            placeholder="Filter by Case ID…"
            className="border border-gray-300 rounded-lg px-3 py-2 text-sm w-56 focus:outline-none focus:ring-2 focus:ring-primary"
          />
        </div>

        {isLoading ? <p className="text-gray-400">Loading…</p> : <AuditLogTable entries={entries} />}

        {pages > 1 && (
          <div className="flex gap-2 items-center text-sm">
            <button onClick={() => setPage((p) => Math.max(1, p-1))} disabled={page===1} className="px-3 py-1.5 rounded border border-gray-300 disabled:opacity-40">Prev</button>
            <span className="text-gray-500">Page {page} of {pages}</span>
            <button onClick={() => setPage((p) => Math.min(pages, p+1))} disabled={page===pages} className="px-3 py-1.5 rounded border border-gray-300 disabled:opacity-40">Next</button>
          </div>
        )}
      </div>
    </RoleGuard>
  );
}
