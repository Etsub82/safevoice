import client from './client';
import { DepartmentStats, OfficerReport } from '@/lib/types';

export const assignmentApi = {
  assignCase: (caseId: string, officerId: string, reason?: string) =>
    client.patch(`/api/proxy/cases/${caseId}/assign`, { officerId, reason }),

  getDepartmentStats: () =>
    client.get<DepartmentStats>('/api/proxy/cases/department/stats'),

  getOfficers: () =>
    client.get<{ id: string; username: string; displayName: string; organization: string }[]>(
      '/api/proxy/cases/officers'
    ),

  submitReport: (caseId: string, data: {
    actionsTaken: string;
    findings: string;
    blockers?: string;
    recommendedNextAction?: string;
    requiresAnotherDepartment: boolean;
    targetDepartment?: string;
  }) => client.post(`/api/proxy/cases/${caseId}/reports`, data),

  getReports: (caseId: string) =>
    client.get<OfficerReport[]>(`/api/proxy/cases/${caseId}/reports`),

  reviewReport: (caseId: string, reportId: string) =>
    client.patch(`/api/proxy/cases/${caseId}/reports/${reportId}/review`, {}),
};
