'use client';

import { useRouter } from 'next/navigation';
import { CaseListItem, RiskLevel } from '@/lib/types';

const RISK_BADGE: Record<RiskLevel, string> = {
  High:   'bg-red-100 text-red-700 border border-red-200',
  Medium: 'bg-amber-100 text-amber-700 border border-amber-200',
  Low:    'bg-green-100 text-green-700 border border-green-200',
};

interface Props {
  cases: CaseListItem[];
  isLoading: boolean;
}

export default function CaseTable({ cases, isLoading }: Props) {
  const router = useRouter();

  if (isLoading) return <p className="text-gray-400 py-8 text-center">Loading cases...</p>;
  if (cases.length === 0) return <p className="text-gray-400 py-8 text-center">No cases found</p>;

  return (
    <div className="overflow-x-auto rounded-xl border border-gray-200">
      <table className="min-w-full text-sm">
        <thead className="bg-gray-50 border-b border-gray-200">
          <tr>
            {['Case ID', 'Incident Type', 'Risk', 'Status', 'Submitted', 'Officer'].map((h) => (
              <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">
                {h}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100 bg-white">
          {cases.map((c) => (
            <tr
              key={c.id}
              onClick={() => router.push(`/cases/${c.id}`)}
              className="cursor-pointer hover:bg-gray-50 transition"
            >
              <td className="px-4 py-3 font-mono text-xs text-gray-700">{c.id.slice(0, 8)}…</td>
              <td className="px-4 py-3 text-gray-700">{c.incidentType.replace(/([A-Z])/g, ' $1').trim()}</td>
              <td className="px-4 py-3">
                <span className={`px-2 py-0.5 rounded text-xs font-medium ${RISK_BADGE[c.riskLevel]}`}>
                  {c.riskLevel}
                </span>
              </td>
              <td className="px-4 py-3 text-gray-600">{c.status}</td>
              <td className="px-4 py-3 text-gray-500 text-xs">
                {new Date(c.submittedAt).toLocaleDateString()}
              </td>
              <td className="px-4 py-3 text-gray-500">{c.assignedOfficerName ?? '—'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
