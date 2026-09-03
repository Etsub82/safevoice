import client from './client';
import { AgreementStatus } from '@/lib/types';

export const agreementApi = {
  getStatus: () =>
    client.get<AgreementStatus>('/api/proxy/agreement/status'),

  accept: () =>
    client.post('/api/proxy/agreement/accept'),

  reject: () =>
    client.post('/api/proxy/agreement/reject'),
};
