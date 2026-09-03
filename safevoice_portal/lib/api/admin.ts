import client from './client';
import { PortalUser, UserRole } from '@/lib/types';

export const adminApi = {
  listUsers: (params?: { page?: number; pageSize?: number }) =>
    client.get<{ items: PortalUser[]; total: number }>('/api/proxy/admin/users', { params }),

  createUser: (data: { username: string; role: UserRole; organization: string; jurisdiction: string; password: string }) =>
    client.post<PortalUser>('/api/proxy/admin/users', data),

  updateUser: (id: string, data: Partial<{ role: UserRole; organization: string; jurisdiction: string; isActive: boolean }>) =>
    client.patch<PortalUser>(`/api/proxy/admin/users/${id}`, data),

  deactivateUser: (id: string) =>
    client.patch(`/api/proxy/admin/users/${id}`, { isActive: false }),

  listOrganizations: () =>
    client.get<{ id: string; name: string; jurisdiction: string }[]>('/api/proxy/admin/organizations'),
};
