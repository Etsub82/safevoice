interface Props {
  label: string;
  value: number;
  color?: 'blue' | 'red' | 'amber' | 'green';
}

const COLOR_MAP = {
  blue:  'bg-blue-50 text-blue-700 border-blue-200',
  red:   'bg-red-50 text-red-700 border-red-200',
  amber: 'bg-amber-50 text-amber-700 border-amber-200',
  green: 'bg-green-50 text-green-700 border-green-200',
};

export default function StatCard({ label, value, color = 'blue' }: Props) {
  return (
    <div className={`border rounded-xl p-5 ${COLOR_MAP[color]}`}>
      <p className="text-sm font-medium opacity-70">{label}</p>
      <p className="text-3xl font-bold mt-1">{value}</p>
    </div>
  );
}
