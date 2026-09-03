'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { useRouter } from 'next/navigation';
import { authApi } from '@/lib/api/auth';
import { useAuthStore } from '@/lib/store/authStore';
import { UserRole } from '@/lib/types';

const IS_MOCK_MODE =
  process.env.NODE_ENV !== 'production' &&
  process.env.NEXT_PUBLIC_MOCK_MODE === 'true';

const schema = z.object({
  username: z.string().min(1, 'Username is required'),
  password: z.string().min(1, 'Password is required'),
});
type FormData = z.infer<typeof schema>;

export default function LoginForm() {
  const router = useRouter();
  const setSession = useAuthStore((s) => s.setSession);
  const [error, setError] = useState<string | null>(null);
  const [mockRole, setMockRole] = useState<UserRole>('Officer');

  const { register, handleSubmit, formState: { errors, isSubmitting } } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: IS_MOCK_MODE ? { username: 'dev', password: 'dev' } : undefined,
  });

  const handleMockLogin = async () => {
    // ⚠️ DEV ONLY — never runs in production
    if (process.env.NODE_ENV === 'production') return;
    const { MOCK_PROFILES, MOCK_ACCESS_TOKEN } = await import('@/lib/dev/mockAuth');
    const profile = MOCK_PROFILES.find((p) => p.user.role === mockRole) ?? MOCK_PROFILES[0];
    setSession(profile.user, MOCK_ACCESS_TOKEN);
    router.push('/dashboard');
  };

  const onSubmit = async (data: FormData) => {
    if (IS_MOCK_MODE) { await handleMockLogin(); return; }
    setError(null);
    try {
      const res = await authApi.login(data.username, data.password);
      const payload = res.data;
      // Backend may return camelCase or PascalCase
      const accessToken = payload.accessToken ?? payload.AccessToken;
      const userRaw = payload.user ?? payload.User;
      setSession({
        id: userRaw?.id ?? userRaw?.Id ?? payload.userId ?? payload.UserId,
        username: userRaw?.username ?? userRaw?.Username ?? data.username,
        role: (userRaw?.role ?? userRaw?.Role ?? payload.role ?? payload.Role) as UserRole,
        organization: userRaw?.organization ?? userRaw?.Organization ?? '',
        jurisdiction: userRaw?.jurisdiction ?? userRaw?.Jurisdiction ?? '',
      }, accessToken);
      router.push('/dashboard');
    } catch (err: any) {
      console.error('Login error:', err);
      const status = err?.response?.status;
      const msg = err?.response?.data?.error
        ?? err?.response?.data?.message
        ?? err?.message
        ?? 'Unknown error';
      if (err?.code === 'ERR_NETWORK' || msg.includes('Network') || msg.includes('fetch')) {
        setError('Cannot connect to server. Make sure the backend is running.');
      } else if (status === 401 || msg === 'INVALID_CREDENTIALS') {
        setError('Incorrect username or password.');
      } else if (status === 423 || msg.startsWith('ACCOUNT_LOCKED')) {
        setError('Account is temporarily locked due to too many failed attempts. Try again later.');
      } else {
        setError(`Login failed: ${msg}`);
      }
    }
  };

  return (
    <div className="space-y-5">
      {/* ⚠️ DEV MODE BANNER — never rendered in production */}
      {IS_MOCK_MODE && (
        <div className="bg-amber-50 border border-amber-300 rounded-lg px-4 py-3">
          <p className="text-xs font-bold text-amber-700 uppercase tracking-wide mb-2">
            ⚠️ Development Preview Mode
          </p>
          <p className="text-xs text-amber-600 mb-3">
            No backend required. Select a role to preview that user's portal experience.
            This panel is invisible in production builds.
          </p>
          <label className="block text-xs font-medium text-amber-700 mb-1">Preview as role:</label>
          <select
            value={mockRole}
            onChange={(e) => setMockRole(e.target.value as UserRole)}
            className="w-full border border-amber-300 rounded-lg px-3 py-2 text-sm bg-white focus:outline-none focus:ring-2 focus:ring-amber-400"
          >
            {DEV_ROLES.map(({ role, label }) => (
              <option key={role} value={role}>{label}</option>
            ))}
          </select>
          <p className="text-xs text-amber-500 mt-2">{DEV_ROLES.find(r => r.role === mockRole)?.description}</p>
        </div>
      )}

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
        {!IS_MOCK_MODE && (
          <>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Username</label>
              <input
                {...register('username')}
                autoComplete="username"
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-600"
              />
              {errors.username && <p className="text-xs text-red-600 mt-1">{errors.username.message}</p>}
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Password</label>
              <input
                {...register('password')}
                type="password"
                autoComplete="current-password"
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-600"
              />
              {errors.password && <p className="text-xs text-red-600 mt-1">{errors.password.message}</p>}
            </div>
          </>
        )}

        {error && (
          <p className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-3 py-2">{error}</p>
        )}

        <button
          type="submit"
          disabled={isSubmitting}
          className="w-full bg-blue-700 hover:bg-blue-800 text-white font-medium py-2.5 rounded-lg transition disabled:opacity-60"
        >
          {isSubmitting
            ? 'Signing in...'
            : IS_MOCK_MODE
              ? `Enter as ${DEV_ROLES.find(r => r.role === mockRole)?.label ?? mockRole}`
              : 'Sign In'}
        </button>
      </form>
    </div>
  );
}

// Only used in dev — tree-shaken in production
const DEV_ROLES: { role: UserRole; label: string; description: string }[] = [
  { role: 'HeadOfDepartment', label: 'Head of Department', description: 'Oversee all cases, assign to officers, escalate' },
  { role: 'Officer',         label: 'Police Officer',      description: 'Case intake, investigation notes, Tier 1 & 2 data' },
  { role: 'Supervisor',      label: 'Police Supervisor',   description: 'Assign cases, escalate, monitor officers' },
  { role: 'Prosecutor',      label: 'Prosecutor',          description: 'Justice module, legal case management' },
  { role: 'Lawyer',          label: 'Lawyer / Legal Aid',  description: 'Assigned cases only, upload legal docs' },
  { role: 'SocialWorker',    label: 'Social Worker',       description: 'Tier 3 data only, support notes' },
  { role: 'SystemAdmin',     label: 'System Admin',        description: 'User management, all access' },
  { role: 'SecurityAuditor', label: 'Security Auditor',    description: 'Audit log read-only' },
];
