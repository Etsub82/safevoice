/**
 * ⚠️  DEVELOPMENT ONLY — Mock data for UI preview.
 * This file is never imported in production builds.
 * All data is fictional and does not represent real persons or cases.
 */

import { CaseDetail, CaseListItem, AuditLogEntry, PortalUser } from '@/lib/types';

// ─── Sample Cases ────────────────────────────────────────────────────────────

export const MOCK_CASES: CaseListItem[] = [
  { id: 'c1a2b3c4-0001-0000-0000-000000000001', incidentType: 'PhysicalViolence',     submittedAt: '2026-08-01T08:30:00Z', status: 'Investigation',    riskLevel: 'High',   district: 'Addis Ababa', assignedOfficerName: 'Sgt. Kebede Alemu' },
  { id: 'c1a2b3c4-0002-0000-0000-000000000002', incidentType: 'SexualViolence',       submittedAt: '2026-08-02T11:00:00Z', status: 'Assigned',          riskLevel: 'High',   district: 'Oromia',      assignedOfficerName: 'Sgt. Tigist Haile' },
  { id: 'c1a2b3c4-0003-0000-0000-000000000003', incidentType: 'PsychologicalViolence',submittedAt: '2026-08-03T09:15:00Z', status: 'Triaged',           riskLevel: 'Medium', district: 'Amhara',      assignedOfficerName: undefined },
  { id: 'c1a2b3c4-0004-0000-0000-000000000004', incidentType: 'EconomicViolence',     submittedAt: '2026-08-04T14:00:00Z', status: 'ReferredToJustice', riskLevel: 'Medium', district: 'Addis Ababa', assignedOfficerName: 'Sgt. Kebede Alemu' },
  { id: 'c1a2b3c4-0005-0000-0000-000000000005', incidentType: 'PhysicalViolence',     submittedAt: '2026-08-05T07:45:00Z', status: 'Resolved',          riskLevel: 'Low',    district: 'SNNPR',       assignedOfficerName: 'Sgt. Mulugeta Bekele' },
  { id: 'c1a2b3c4-0006-0000-0000-000000000006', incidentType: 'Other',               submittedAt: '2026-08-06T16:20:00Z', status: 'Submitted',         riskLevel: 'Low',    district: 'Tigray',      assignedOfficerName: undefined },
  { id: 'c1a2b3c4-0007-0000-0000-000000000007', incidentType: 'SexualViolence',       submittedAt: '2026-08-07T10:10:00Z', status: 'Escalated',         riskLevel: 'High',   district: 'Oromia',      assignedOfficerName: 'Sgt. Tigist Haile' },
  { id: 'c1a2b3c4-0008-0000-0000-000000000008', incidentType: 'PhysicalViolence',     submittedAt: '2026-08-08T13:00:00Z', status: 'CourtProcess',      riskLevel: 'High',   district: 'Addis Ababa', assignedOfficerName: 'Sgt. Kebede Alemu' },
];

export const MOCK_CASE_DETAILS: Record<string, CaseDetail> = {
  'c1a2b3c4-0001-0000-0000-000000000001': {
    id: 'c1a2b3c4-0001-0000-0000-000000000001',
    incidentType: 'PhysicalViolence',
    description: 'Victim reported repeated physical assault in the home. Multiple injuries documented by health worker.',
    submittedAt: '2026-08-01T08:30:00Z',
    updatedAt: '2026-08-03T10:00:00Z',
    status: 'Investigation',
    riskLevel: 'High',
    district: 'Addis Ababa',
    assignedOfficerId: 'u-officer-01',
    assignedOfficerName: 'Sgt. Kebede Alemu',
    isAnonymous: false,
    // Tier 1 — only shown to authorized roles in real system
    victimName: '[Sample Victim Name]',
    victimContact: '+251 9XX XXX XXX',
    locationText: 'Bole Sub-city, Woreda 03',
    statusHistory: [
      { id: 'sh-01', oldStatus: 'Submitted', newStatus: 'Received',      changedBy: 'System',           changedAt: '2026-08-01T08:31:00Z', reason: undefined },
      { id: 'sh-02', oldStatus: 'Received',  newStatus: 'Triaged',       changedBy: 'Admin Dispatcher', changedAt: '2026-08-01T09:00:00Z', reason: undefined },
      { id: 'sh-03', oldStatus: 'Triaged',   newStatus: 'Assigned',      changedBy: 'Supervisor Tesfaye', changedAt: '2026-08-01T10:30:00Z', reason: 'Assigned to available officer' },
      { id: 'sh-04', oldStatus: 'Assigned',  newStatus: 'Investigation', changedBy: 'Sgt. Kebede Alemu', changedAt: '2026-08-02T08:00:00Z', reason: 'Investigation opened after victim interview' },
    ],
    notes: [
      { id: 'n-01', caseId: 'c1a2b3c4-0001-0000-0000-000000000001', authorId: 'u-officer-01', authorName: 'Sgt. Kebede Alemu', content: 'Victim interviewed. Medical examination scheduled for tomorrow.', createdAt: '2026-08-02T09:00:00Z' },
      { id: 'n-02', caseId: 'c1a2b3c4-0001-0000-0000-000000000001', authorId: 'u-officer-01', authorName: 'Sgt. Kebede Alemu', content: 'Suspect identified. Warrant request submitted to prosecutor.', createdAt: '2026-08-03T11:00:00Z' },
    ],
  },
};

// ─── Sample Audit Logs ────────────────────────────────────────────────────────

export const MOCK_AUDIT_LOGS: AuditLogEntry[] = [
  { id: 'al-01', eventType: 'PORTAL_SESSION_STARTED',  userId: 'u-officer-01',   userRole: 'Officer',    caseId: undefined,                                         ipAddress: '196.188.x.x', occurredAt: '2026-08-08T08:00:00Z', metadata: {} },
  { id: 'al-02', eventType: 'CASE_VIEWED',             userId: 'u-officer-01',   userRole: 'Officer',    caseId: 'c1a2b3c4-0001-0000-0000-000000000001',            ipAddress: '196.188.x.x', occurredAt: '2026-08-08T08:02:00Z', metadata: {} },
  { id: 'al-03', eventType: 'VICTIM_IDENTITY_ACCESSED',userId: 'u-officer-01',   userRole: 'Officer',    caseId: 'c1a2b3c4-0001-0000-0000-000000000001',            ipAddress: '196.188.x.x', occurredAt: '2026-08-08T08:02:10Z', metadata: {} },
  { id: 'al-04', eventType: 'INVESTIGATION_NOTE_ADDED',userId: 'u-officer-01',   userRole: 'Officer',    caseId: 'c1a2b3c4-0001-0000-0000-000000000001',            ipAddress: '196.188.x.x', occurredAt: '2026-08-08T09:00:00Z', metadata: { noteId: 'n-02' } },
  { id: 'al-05', eventType: 'EVIDENCE_ACCESSED',       userId: 'u-prosecutor-01',userRole: 'Prosecutor', caseId: 'c1a2b3c4-0001-0000-0000-000000000001',            ipAddress: '197.156.x.x', occurredAt: '2026-08-08T10:00:00Z', metadata: { evidenceId: 'ev-01' } },
  { id: 'al-06', eventType: 'CASE_STATUS_CHANGED',     userId: 'u-supervisor-01',userRole: 'Supervisor', caseId: 'c1a2b3c4-0002-0000-0000-000000000002',            ipAddress: '196.188.x.x', occurredAt: '2026-08-08T11:00:00Z', metadata: { from: 'Triaged', to: 'Assigned' } },
  { id: 'al-07', eventType: 'ADMIN_USER_MODIFIED',     userId: 'u-admin-01',     userRole: 'SystemAdmin',caseId: undefined,                                         ipAddress: '10.0.0.1',    occurredAt: '2026-08-08T12:00:00Z', metadata: { targetUserId: 'u-new-officer' } },
];

// ─── Sample Portal Users ──────────────────────────────────────────────────────

export const MOCK_USERS: PortalUser[] = [
  { id: 'u-officer-01',    username: 'kebede.alemu',   role: 'Officer',    organization: 'Addis Ababa Police', jurisdiction: 'Addis Ababa', isActive: true,  createdAt: '2026-01-10T00:00:00Z' },
  { id: 'u-supervisor-01', username: 'tesfaye.girma',  role: 'Supervisor', organization: 'Addis Ababa Police', jurisdiction: 'Addis Ababa', isActive: true,  createdAt: '2026-01-05T00:00:00Z' },
  { id: 'u-prosecutor-01', username: 'meron.tadesse',  role: 'Prosecutor', organization: 'Federal Prosecutor', jurisdiction: 'Federal',     isActive: true,  createdAt: '2026-01-08T00:00:00Z' },
  { id: 'u-lawyer-01',     username: 'selam.bekele',   role: 'Lawyer',     organization: 'Legal Aid Ethiopia',  jurisdiction: 'Addis Ababa', isActive: true,  createdAt: '2026-02-01T00:00:00Z' },
  { id: 'u-admin-01',      username: 'admin',          role: 'SystemAdmin',organization: 'SafeVoice HQ',        jurisdiction: 'National',    isActive: true,  createdAt: '2026-01-01T00:00:00Z' },
  { id: 'u-auditor-01',    username: 'audit.officer',  role: 'SecurityAuditor', organization: 'SafeVoice HQ',  jurisdiction: 'National',    isActive: true,  createdAt: '2026-01-01T00:00:00Z' },
];
