import client from './client';
import { CaseDetail, CaseListItem, CaseStatus, CaseListParams, PaginatedResponse, InvestigationNote } from '@/lib/types';

export const casesApi = {
  list: (params?: CaseListParams) =>
    client.get<PaginatedResponse<CaseListItem>>('/api/proxy/cases', { params }),

  detail: (id: string) =>
    client.get<CaseDetail>(`/api/proxy/cases/${id}`),

  updateStatus: (id: string, status: CaseStatus, reason: string) =>
    client.patch(`/api/proxy/cases/${id}/status`, { status, reason }),

  addNote: (id: string, content: string) =>
    client.post<InvestigationNote>(`/api/proxy/cases/${id}/notes`, { content }),

  assign: (id: string, officerId: string) =>
    client.patch(`/api/proxy/cases/${id}/assign`, { officerId }),

  escalate: (id: string, reason: string) =>
    client.patch(`/api/proxy/cases/${id}/status`, { status: 'Escalated', reason }),

  refer: (id: string, targetOrg: string, reason: string) =>
    client.post(`/api/proxy/cases/${id}/refer`, { targetOrg, reason }),
};
