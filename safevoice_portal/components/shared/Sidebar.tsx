'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { useAuthStore } from '@/lib/store/authStore';
import { hasPermission } from '@/lib/utils/permissions';
import { useLogout } from '@/lib/hooks/useLogout';

const NAV = [
  { href: '/dashboard',   label: 'Dashboard',    icon: '🏠', permission: null },
  { href: '/head',        label: 'HoD Dashboard', icon: '👔', permission: 'assign_cases' as const },
  { href: '/cases',       label: 'Cases',         icon: '📋', permission: null },
  { href: '/audit',       label: 'Audit Log',     icon: '🔍', permission: 'view_audit_log' as const },
  { href: '/admin/users', label: 'Admin',         icon: '⚙️',  permission: 'manage_users' as const },
];

export default function Sidebar() {
  const pathname = usePathname();
  const user = useAuthStore((s) => s.user);
  const logout = useLogout();
  const [mounted, setMounted] = useState(false);

  useEffect(() => { setMounted(true); }, []);

  const visible = NAV.filter((item) =>
    !item.permission || (user && hasPermission(user.role, item.permission))
  );

  return (
    <aside className="w-60 min-h-screen bg-gray-900 text-white flex flex-col">
      <div className="px-6 py-5 border-b border-gray-700">
        <p className="text-lg font-bold tracking-tight">SafeVoice</p>
        <p className="text-xs text-gray-400 mt-0.5">Justice Portal</p>
      </div>

      <nav className="flex-1 py-4 space-y-1 px-3">
        {mounted && visible.map((item) => {
          const active = pathname.startsWith(item.href);
          return (
            <Link
              key={item.href}
              href={item.href}
              className={`flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition ${
                active ? 'bg-primary text-white' : 'text-gray-300 hover:bg-gray-800'
              }`}
            >
              <span>{item.icon}</span>
              {item.label}
            </Link>
          );
        })}
      </nav>

      {mounted && user && (
        <div className="px-4 py-4 border-t border-gray-700">
          <p className="text-xs text-gray-400 truncate">{user.username}</p>
          <p className="text-xs text-gray-500 truncate">{user.role}</p>
          <button
            onClick={logout}
            className="mt-3 w-full text-xs text-gray-300 hover:text-white py-1.5 rounded hover:bg-gray-800 transition"
          >
            Sign Out
          </button>
        </div>
      )}
    </aside>
  );
}
