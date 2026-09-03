import { CaseStatusHistory } from '@/lib/types';

export default function StatusTimeline({ history }: { history: CaseStatusHistory[] }) {
  const sorted = [...history].sort(
    (a, b) => new Date(a.changedAt).getTime() - new Date(b.changedAt).getTime()
  );

  return (
    <div className="relative pl-5 border-l-2 border-gray-200 space-y-4">
      {sorted.map((entry) => (
        <div key={entry.id} className="relative">
          <span className="absolute -left-[23px] w-3 h-3 bg-primary rounded-full border-2 border-white" />
          <div className="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
            <div className="flex items-center justify-between gap-2">
              <span className="text-sm font-medium text-gray-800">
                {entry.oldStatus} → <strong>{entry.newStatus}</strong>
              </span>
              <span className="text-xs text-gray-400">
                {new Date(entry.changedAt).toLocaleString()}
              </span>
            </div>
            <p className="text-xs text-gray-500 mt-1">By {entry.changedBy}</p>
            {entry.reason && <p className="text-xs text-gray-600 mt-1 italic">"{entry.reason}"</p>}
          </div>
        </div>
      ))}
    </div>
  );
}
