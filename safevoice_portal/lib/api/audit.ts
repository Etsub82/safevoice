import client from './client';
import { AuditLogEntry, AuditLogParams, PaginatedResponse } from '@/lib/types';

export const auditApi = {
  list: (params?: AuditLogParams) =>
    client.get<PaginatedResponse<AuditLogEntry>>('/api/proxy/audit-logs', { params }),
};
