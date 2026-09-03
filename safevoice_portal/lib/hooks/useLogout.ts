'use client';

import { useRouter } from 'next/navigation';
import { authApi } from '@/lib/api/auth';
import { useAuthStore } from '@/lib/store/authStore';

const IS_MOCK_MODE =
  process.env.NODE_ENV !== 'production' &&
  process.env.NEXT_PUBLIC_MOCK_MODE === 'true';

export function useLogout() {
  const router = useRouter();
  const clearSession = useAuthStore((s) => s.clearSession);

  return async () => {
    if (!IS_MOCK_MODE) {
      await authApi.logout().catch(() => {});
    }
    clearSession();
    router.push('/login');
  };
}
