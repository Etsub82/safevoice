'use client';

import { useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useAuthStore } from '@/lib/store/authStore';
import { authApi } from '@/lib/api/auth';

const IDLE_MS = 15 * 60 * 1000; // 15 minutes
const IS_MOCK_MODE =
  process.env.NODE_ENV !== 'production' &&
  process.env.NEXT_PUBLIC_MOCK_MODE === 'true';

export function useIdleTimeout() {
  const router = useRouter();
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const clearSession = useAuthStore((s) => s.clearSession);

  const reset = () => {
    if (timer.current) clearTimeout(timer.current);
    timer.current = setTimeout(async () => {
      if (!IS_MOCK_MODE) {
        await authApi.logout().catch(() => {});
      }
      clearSession();
      router.push('/login?reason=idle');
    }, IDLE_MS);
  };

  useEffect(() => {
    const events = ['mousemove', 'keydown', 'click', 'scroll', 'touchstart'];
    events.forEach((e) => window.addEventListener(e, reset, { passive: true }));
    reset();
    return () => {
      events.forEach((e) => window.removeEventListener(e, reset));
      if (timer.current) clearTimeout(timer.current);
    };
  }, []); // eslint-disable-line react-hooks/exhaustive-deps
}
