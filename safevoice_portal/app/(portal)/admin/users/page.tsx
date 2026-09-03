'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { adminApi } from '@/lib/api/admin';
import UserManagementTable from '@/components/admin/UserManagementTable';
import RoleGuard from '@/components/shared/RoleGuard';
import { UserRole } from '@/lib/types';

const ROLES: UserRole[] = [
  'Officer','Investigator','Supervisor','Prosecutor','PublicProsecutor',
  'CourtClerk','Judge','Lawyer','LegalAid','SocialWorker','SystemAdmin','SecurityAuditor',
];

export default function AdminUsersPage() {
  const [creating, setCreating] = useState(false);
  const [form, setForm] = useState({ username: '', password: '', role: '' as UserRole, organization: '', jurisdiction: '' });
  const [saving, setSaving] = useState(false);
  const { data, isLoading, refetch } = useQuery({
    queryKey: ['admin', 'users'],
    queryFn: () => adminApi.listUsers(),
  });

  const users = data?.data.items ?? [];

  const handleCreate = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    await adminApi.createUser(form as any);
    setSaving(false);
    setCreating(false);
    refetch();
  };

  return (
    <RoleGuard permission="manage_users">
      <div className="space-y-5">
        <div className="flex justify-between items-center">
          <h1 className="text-2xl font-bold text-gray-900">User Management</h1>
          <button onClick={() => setCreating(true)} className="bg-primary text-white text-sm px-4 py-2 rounded-lg">+ New User</button>
        </div>

        {creating && (
          <form onSubmit={handleCreate} className="bg-white border border-gray-200 rounded-xl p-5 space-y-3 max-w-md">
            <h3 className="font-semibold text-gray-700">Create User</h3>
            {[['Username','username','text'],['Password','password','password'],['Organization','organization','text'],['Jurisdiction','jurisdiction','text']].map(([label, field, type]) => (
              <div key={field}>
                <label className="text-xs font-medium text-gray-600">{label}</label>
                <input
                  type={type}
                  value={(form as any)[field]}
                  onChange={(e) => setForm((f) => ({ ...f, [field]: e.target.value }))}
                  required
                  className="mt-1 w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
                />
              </div>
            ))}
            <div>
              <label className="text-xs font-medium text-gray-600">Role</label>
              <select value={form.role} onChange={(e) => setForm((f) => ({ ...f, role: e.target.value as UserRole }))} required className="mt-1 w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none">
                <option value="">Select role</option>
                {ROLES.map((r) => <option key={r} value={r}>{r}</option>)}
              </select>
            </div>
            <div className="flex gap-2">
              <button type="submit" disabled={saving} className="bg-primary text-white text-sm px-4 py-2 rounded-lg disabled:opacity-60">
                {saving ? 'Creating…' : 'Create'}
              </button>
              <button type="button" onClick={() => setCreating(false)} className="text-gray-500 text-sm px-4 py-2 rounded-lg border border-gray-300">Cancel</button>
            </div>
          </form>
        )}

        {isLoading ? <p className="text-gray-400">Loading…</p> : <UserManagementTable users={users} />}
      </div>
    </RoleGuard>
  );
}
