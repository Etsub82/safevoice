interface Props { label: string; children: React.ReactNode }

export default function SensitiveDataBadge({ label, children }: Props) {
  return (
    <div className="border border-amber-300 bg-amber-50 rounded-lg p-4">
      <span className="inline-block text-xs font-semibold text-amber-700 bg-amber-100 px-2 py-0.5 rounded mb-2 uppercase tracking-wide">
        🔒 {label} — Sensitive
      </span>
      <div>{children}</div>
    </div>
  );
}
