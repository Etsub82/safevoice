'use client';

import { useEffect, useState } from 'react';
import { useAuthStore } from '@/lib/store/authStore';
import { useLogout } from '@/lib/hooks/useLogout';

export default function TopBar() {
  const [mounted, setMounted] = useState(false);
  const user = useAuthStore(s => s.user);
  const logout = useLogout();

  useEffect(() => { setMounted(true); }, []);

  if (!mounted || !user) return null;

  return (
    <div className="h-12 bg-white border-b border-gray-200 flex items-center justify-between px-6 flex-shrink-0">
      <div />
      <div className="flex items-center gap-4">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-full bg-blue-100 flex items-center justify-center text-blue-700 font-bold text-xs">
            {user.username?.[0]?.toUpperCase() ?? 'U'}
          </div>
          <div className="text-right">
            <p className="text-xs font-semibold text-gray-800 leading-none">{user.username}</p>
            <p className="text-xs text-gray-400 leading-none mt-0.5">{user.role}</p>
          </div>
        </div>
        <button
          onClick={logout}
          className="text-xs bg-gray-100 hover:bg-red-50 hover:text-red-600 text-gray-600 px-3 py-1.5 rounded-lg transition font-medium"
        >
          Sign Out
        </button>
      </div>
    </div>
  );
}
