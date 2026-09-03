import client from './client';
import { Evidence } from '@/lib/types';

export const evidenceApi = {
  list: (caseId: string) =>
    client.get<Evidence[]>(`/api/proxy/cases/${caseId}/evidence`),

  // Routes through Next.js proxy — binary blob response
  download: (caseId: string, evidenceId: string) =>
    client.get<Blob>(`/api/proxy/cases/${caseId}/evidence/${evidenceId}/download`, {
      responseType: 'blob',
    }),

  upload: (caseId: string, file: File, type?: string) => {
    const form = new FormData();
    form.append('file', file);
    if (type) form.append('type', type);
    return client.post(`/api/proxy/cases/${caseId}/evidence`, form, {
      headers: { 'Content-Type': 'multipart/form-data' },
    });
  },
};
