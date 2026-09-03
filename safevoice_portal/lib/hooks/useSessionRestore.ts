'use client';

import { useEffect } from 'react';
import { useAuthStore } from '@/lib/store/authStore';

const IS_MOCK_MODE =
  process.env.NODE_ENV !== 'production' &&
  process.env.NEXT_PUBLIC_MOCK_MODE === 'true';

/**
 * In mock mode: do nothing — session is set by LoginForm directly in Zustand.
 * In production: try to restore session from HttpOnly refresh-token cookie.
 */
export function useSessionRestore() {
  const { isAuthenticated, setToken, clearSession } = useAuthStore();

  useEffect(() => {
    // Mock mode — session lives in Zustand memory, no cookie to restore
    if (IS_MOCK_MODE) return;
    // Already authenticated — no need to restore
    if (isAuthenticated) return;

    // Try to get a new access token from the refresh cookie
    import('@/lib/api/auth').then(({ authApi }) => {
      authApi.refresh()
        .then((res) => setToken(res.data.accessToken))
        .catch(() => {
          // No valid refresh cookie — clear any stale state
          clearSession();
        });
    });
  }, []); // eslint-disable-line react-hooks/exhaustive-deps
}
