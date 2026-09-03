/**
 * ⚠️  DEVELOPMENT ONLY — Mock API response handler.
 * Intercepts Axios requests when NEXT_PUBLIC_MOCK_MODE=true and NODE_ENV !== 'production'.
 * Returns realistic sample data without hitting the real backend.
 */

import type { InternalAxiosRequestConfig, AxiosResponse } from 'axios';
import { MOCK_CASES, MOCK_CASE_DETAILS, MOCK_AUDIT_LOGS, MOCK_USERS } from './mockData';

function mockResponse<T>(data: T, status = 200): AxiosResponse<T> {
  return {
    data,
    status,
    statusText: 'OK',
    headers: {},
    config: {} as InternalAxiosRequestConfig,
  };
}

/** Returns a mock response if the URL matches a known pattern, otherwise null (real request proceeds). */
export function handleMockRequest(url: string, method: string): AxiosResponse | null {
  const m = method.toLowerCase();

  // Auth
  if (url.includes('/api/auth/refresh') && m === 'post')
    return mockResponse({ accessToken: 'DEV_MOCK_TOKEN_NOT_A_REAL_JWT' });
  if (url.includes('/api/auth/logout') && m === 'post')
    return mockResponse({});

  // Cases list
  if (url.match(/\/api\/cases$/) && m === 'get')
    return mockResponse({ items: MOCK_CASES, total: MOCK_CASES.length, page: 1, pageSize: 20 });

  // Case detail
  const caseDetailMatch = url.match(/\/api\/cases\/([\w-]+)$/);
  if (caseDetailMatch && m === 'get') {
    const id = caseDetailMatch[1];
    const detail = MOCK_CASE_DETAILS[id] ?? {
      ...MOCK_CASES.find((c) => c.id === id),
      description: 'Sample case description for preview purposes.',
      updatedAt: new Date().toISOString(),
      isAnonymous: false,
      statusHistory: [],
      notes: [],
    };
    return mockResponse(detail);
  }

  // Case status update
  if (url.match(/\/api\/cases\/[\w-]+\/status/) && m === 'patch')
    return mockResponse({ success: true });

  // Case notes
  if (url.match(/\/api\/cases\/[\w-]+\/notes/) && m === 'post')
    return mockResponse({ id: 'n-new', caseId: '', authorId: '', authorName: 'Dev User', content: 'Mock note', createdAt: new Date().toISOString() });

  // Evidence list
  if (url.match(/\/api\/cases\/[\w-]+\/evidence$/) && m === 'get')
    return mockResponse([
      { id: 'ev-01', caseId: '', fileName: 'photo_evidence.jpg',  mimeType: 'image/jpeg',       fileSizeBytes: 2_400_000, uploadedAt: '2026-08-01T09:00:00Z', virusScanPassed: true },
      { id: 'ev-02', caseId: '', fileName: 'voice_statement.mp3', mimeType: 'audio/mpeg',        fileSizeBytes:   800_000, uploadedAt: '2026-08-01T09:05:00Z', virusScanPassed: true },
      { id: 'ev-03', caseId: '', fileName: 'medical_report.pdf',  mimeType: 'application/pdf',   fileSizeBytes: 1_200_000, uploadedAt: '2026-08-02T11:00:00Z', virusScanPassed: true },
    ]);

  // Audit logs
  if (url.includes('/api/audit-logs') && m === 'get')
    return mockResponse({ items: MOCK_AUDIT_LOGS, total: MOCK_AUDIT_LOGS.length, page: 1, pageSize: 50 });

  // Admin users
  if (url.includes('/api/admin/users') && m === 'get')
    return mockResponse({ items: MOCK_USERS, total: MOCK_USERS.length });
  if (url.includes('/api/admin/users') && m === 'post')
    return mockResponse({ ...MOCK_USERS[0], id: 'u-new', username: 'new.user' }, 201);
  if (url.match(/\/api\/admin\/users\/[\w-]+/) && m === 'patch')
    return mockResponse({ success: true });

  // Admin organizations
  if (url.includes('/api/admin/organizations') && m === 'get')
    return mockResponse([
      { id: 'org-01', name: 'Addis Ababa Police',    jurisdiction: 'Addis Ababa' },
      { id: 'org-02', name: 'Federal Prosecutor',    jurisdiction: 'Federal' },
      { id: 'org-03', name: 'Legal Aid Ethiopia',    jurisdiction: 'Addis Ababa' },
      { id: 'org-04', name: 'Ministry of Women',     jurisdiction: 'National' },
      { id: 'org-05', name: 'UNICEF Child Protection', jurisdiction: 'National' },
    ]);

  return null; // no mock — let request through
}
