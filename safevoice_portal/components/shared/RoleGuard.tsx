'use client';

import { useAuthStore } from '@/lib/store/authStore';
import { hasPermission, Permission } from '@/lib/utils/permissions';

interface Props {
  permission: Permission;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}

export default function RoleGuard({ permission, children, fallback }: Props) {
  const user = useAuthStore((s) => s.user);

  if (!user || !hasPermission(user.role, permission)) {
    return fallback ? <>{fallback}</> : null;
  }

  return <>{children}</>;
}
