'use client';

import { PortalUser, UserRole } from '@/lib/types';
import { adminApi } from '@/lib/api/admin';
import { useQueryClient } from '@tanstack/react-query';

const ALL_ROLES: UserRole[] = [
  'Officer','Investigator','Supervisor','WomensProtection','ChildProtection',
  'EmergencyResponse','RegionalAuthority','FederalAuthority','Prosecutor',
  'PublicProsecutor','CourtClerk','Judge','Lawyer','LegalAid','SocialWorker',
  'ChildProtectionOrg','Shelter','HealthcareReferral','PsychosocialSupport',
  'NGO','InstitutionalAdmin','SystemAdmin','SecurityAuditor',
];

interface Props { users: PortalUser[] }

export default function UserManagementTable({ users }: Props) {
  const qc = useQueryClient();

  const toggleActive = async (user: PortalUser) => {
    await adminApi.updateUser(user.id, { isActive: !user.isActive });
    qc.invalidateQueries({ queryKey: ['admin', 'users'] });
  };

  return (
    <div className="overflow-x-auto rounded-xl border border-gray-200">
      <table className="min-w-full text-sm">
        <thead className="bg-gray-50 border-b border-gray-200">
          <tr>
            {['Username','Role','Organization','Jurisdiction','Status','Actions'].map((h) => (
              <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">{h}</th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100 bg-white">
          {users.map((u) => (
            <tr key={u.id}>
              <td className="px-4 py-3 font-medium text-gray-800">{u.username}</td>
              <td className="px-4 py-3 text-gray-600 text-xs">{u.role}</td>
              <td className="px-4 py-3 text-gray-500">{u.organization}</td>
              <td className="px-4 py-3 text-gray-500">{u.jurisdiction}</td>
              <td className="px-4 py-3">
                <span className={`px-2 py-0.5 text-xs rounded font-medium ${u.isActive ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'}`}>
                  {u.isActive ? 'Active' : 'Inactive'}
                </span>
              </td>
              <td className="px-4 py-3">
                <button
                  onClick={() => toggleActive(u)}
                  className="text-xs text-primary hover:underline"
                >
                  {u.isActive ? 'Deactivate' : 'Activate'}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
