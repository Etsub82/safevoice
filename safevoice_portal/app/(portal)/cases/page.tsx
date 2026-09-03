'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import CaseTable from '@/components/cases/CaseTable';
import { casesApi } from '@/lib/api/cases';
import { CaseStatus, RiskLevel } from '@/lib/types';

const PAGE_SIZE = 20;

export default function CaseListPage() {
  const [search, setSearch]       = useState('');
  const [status, setStatus]       = useState<CaseStatus | ''>('');
  const [risk, setRisk]           = useState<RiskLevel | ''>('');
  const [page, setPage]           = useState(1);

  const { data, isLoading } = useQuery({
    queryKey: ['cases', { search, status, risk, page }],
    queryFn: () => casesApi.list({
      search:    search || undefined,
      status:    (status || undefined) as CaseStatus | undefined,
      riskLevel: (risk || undefined) as RiskLevel | undefined,
      page,
      pageSize:  PAGE_SIZE,
    }),
    refetchInterval: 60_000,
  });

  const cases = data?.data.items ?? [];
  const total = data?.data.total ?? 0;
  const pages = Math.ceil(total / PAGE_SIZE);

  return (
    <div className="space-y-5">
      <h1 className="text-2xl font-bold text-gray-900">Cases</h1>

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <input
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(1); }}
          placeholder="Search case ID or type…"
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm w-56 focus:outline-none focus:ring-2 focus:ring-primary"
        />
        <select
          value={status}
          onChange={(e) => { setStatus(e.target.value as CaseStatus | ''); setPage(1); }}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
        >
          <option value="">All Statuses</option>
          {['Submitted','Received','Triaged','Assigned','Investigation','Escalated','Reassigned','ReferredToJustice','CourtProcess','Resolved','Closed'].map((s) => (
            <option key={s} value={s}>{s}</option>
          ))}
        </select>
        <select
          value={risk}
          onChange={(e) => { setRisk(e.target.value as RiskLevel | ''); setPage(1); }}
          className="border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
        >
          <option value="">All Risk Levels</option>
          <option value="High">High</option>
          <option value="Medium">Medium</option>
          <option value="Low">Low</option>
        </select>
      </div>

      <CaseTable cases={cases} isLoading={isLoading} />

      {/* Pagination */}
      {pages > 1 && (
        <div className="flex gap-2 items-center text-sm">
          <button onClick={() => setPage((p) => Math.max(1, p - 1))} disabled={page === 1} className="px-3 py-1.5 rounded border border-gray-300 disabled:opacity-40">Prev</button>
          <span className="text-gray-500">Page {page} of {pages}</span>
          <button onClick={() => setPage((p) => Math.min(pages, p + 1))} disabled={page === pages} className="px-3 py-1.5 rounded border border-gray-300 disabled:opacity-40">Next</button>
        </div>
      )}
    </div>
  );
}
