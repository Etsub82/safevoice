import { AuditLogEntry } from '@/lib/types';

const HIGH_SENSITIVITY = new Set(['VICTIM_IDENTITY_ACCESSED', 'EVIDENCE_ACCESSED']);

interface Props { entries: AuditLogEntry[] }

export default function AuditLogTable({ entries }: Props) {
  if (entries.length === 0) return <p className="text-gray-400 text-sm py-4">No audit log entries found.</p>;

  return (
    <div className="overflow-x-auto rounded-xl border border-gray-200">
      <table className="min-w-full text-sm">
        <thead className="bg-gray-50 border-b border-gray-200">
          <tr>
            {['Event', 'Actor', 'Role', 'Case ID', 'IP Address', 'Time'].map((h) => (
              <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">{h}</th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100 bg-white">
          {entries.map((e) => {
            const isHighSensitivity = HIGH_SENSITIVITY.has(e.eventType);
            return (
              <tr key={e.id} className={isHighSensitivity ? 'bg-red-50' : ''}>
                <td className="px-4 py-3">
                  <span className={`inline-flex items-center gap-1 text-xs font-medium px-2 py-0.5 rounded ${isHighSensitivity ? 'bg-red-100 text-red-700' : 'bg-gray-100 text-gray-700'}`}>
                    {isHighSensitivity && '⚠️ '}{e.eventType.replace(/_/g, ' ')}
                  </span>
                </td>
                <td className="px-4 py-3 text-gray-700 font-mono text-xs">{e.userId.slice(0,8)}…</td>
                <td className="px-4 py-3 text-gray-600 text-xs">{e.userRole}</td>
                <td className="px-4 py-3 text-gray-500 font-mono text-xs">{e.caseId ? e.caseId.slice(0,8) + '…' : '—'}</td>
                <td className="px-4 py-3 text-gray-400 text-xs">{e.ipAddress}</td>
                <td className="px-4 py-3 text-gray-400 text-xs">{new Date(e.occurredAt).toLocaleString()}</td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
