'use client';

import { useQuery } from '@tanstack/react-query';
import { adminApi } from '@/lib/api/admin';
import RoleGuard from '@/components/shared/RoleGuard';

export default function OrganizationsPage() {
  const { data, isLoading } = useQuery({
    queryKey: ['admin', 'organizations'],
    queryFn: () => adminApi.listOrganizations(),
  });

  const orgs = data?.data ?? [];

  return (
    <RoleGuard permission="manage_users">
      <div className="space-y-5">
        <h1 className="text-2xl font-bold text-gray-900">Organizations</h1>
        {isLoading ? <p className="text-gray-400">Loading…</p> : (
          <div className="overflow-x-auto rounded-xl border border-gray-200">
            <table className="min-w-full text-sm">
              <thead className="bg-gray-50 border-b border-gray-200">
                <tr>
                  {['Name','Jurisdiction'].map((h) => (
                    <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100 bg-white">
                {orgs.map((o) => (
                  <tr key={o.id}>
                    <td className="px-4 py-3 text-gray-800">{o.name}</td>
                    <td className="px-4 py-3 text-gray-500">{o.jurisdiction}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </RoleGuard>
  );
}
