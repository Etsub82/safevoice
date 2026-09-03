// ─── Roles ────────────────────────────────────────────────────────────────────

export type UserRole =
  | 'HeadOfDepartment'
  | 'Officer'
  | 'Investigator'
  | 'Supervisor'
  | 'WomensProtection'
  | 'ChildProtection'
  | 'EmergencyResponse'
  | 'RegionalAuthority'
  | 'FederalAuthority'
  | 'Prosecutor'
  | 'PublicProsecutor'
  | 'CourtClerk'
  | 'Judge'
  | 'Lawyer'
  | 'LegalAid'
  | 'SocialWorker'
  | 'ChildProtectionOrg'
  | 'Shelter'
  | 'HealthcareReferral'
  | 'PsychosocialSupport'
  | 'NGO'
  | 'InstitutionalAdmin'
  | 'SystemAdmin'
  | 'SecurityAuditor';

// ─── Case ─────────────────────────────────────────────────────────────────────

export type CaseStatus =
  | 'Submitted'
  | 'Received'
  | 'Triaged'
  | 'Assigned'
  | 'Investigation'
  | 'Escalated'
  | 'Reassigned'
  | 'ReferredToJustice'
  | 'CourtProcess'
  | 'Resolved'
  | 'Closed';

export type RiskLevel = 'Low' | 'Medium' | 'High';

export type IncidentType =
  | 'PhysicalViolence'
  | 'SexualViolence'
  | 'PsychologicalViolence'
  | 'EconomicViolence'
  | 'Other';

export interface Case {
  id: string;
  incidentType: IncidentType;
  description?: string;         // Tier 3
  submittedAt: string;          // ISO 8601
  updatedAt: string;
  status: CaseStatus;
  riskLevel: RiskLevel;
  district: string;
  assignedOfficerId?: string;
  assignedOfficerName?: string;
  isAnonymous: boolean;
  // Tier 1 — only present if backend authorises for the requesting role
  victimName?: string;
  victimContact?: string;
  locationText?: string;
  latitude?: number;
  longitude?: number;
}

export interface CaseListItem {
  id: string;
  incidentType: IncidentType;
  submittedAt: string;
  status: CaseStatus;
  riskLevel: RiskLevel;
  district: string;
  assignedOfficerName?: string;
}

export interface CaseStatusHistory {
  id: string;
  oldStatus: CaseStatus;
  newStatus: CaseStatus;
  changedBy: string;
  changedAt: string;
  reason?: string;
}

export interface CaseDetail extends Case {
  statusHistory: CaseStatusHistory[];
  notes: InvestigationNote[];
}

// ─── Evidence ─────────────────────────────────────────────────────────────────

export interface Evidence {
  id: string;
  caseId: string;
  fileName: string;
  mimeType: string;
  fileSizeBytes: number;
  uploadedAt: string;
  virusScanPassed: boolean;
}

// ─── Investigation Notes ──────────────────────────────────────────────────────

export interface InvestigationNote {
  id: string;
  caseId: string;
  authorId: string;
  authorName: string;
  content: string;
  createdAt: string;
}

// ─── Audit Log ────────────────────────────────────────────────────────────────

export type AuditEventType =
  | 'PORTAL_SESSION_STARTED'
  | 'PORTAL_SESSION_ENDED'
  | 'CASE_VIEWED'
  | 'VICTIM_IDENTITY_ACCESSED'
  | 'EVIDENCE_ACCESSED'
  | 'EVIDENCE_UPLOADED'
  | 'CASE_STATUS_CHANGED'
  | 'CASE_ASSIGNMENT_CHANGED'
  | 'CASE_REFERRED'
  | 'INVESTIGATION_NOTE_ADDED'
  | 'SUPPORT_NOTE_ADDED'
  | 'ADMIN_USER_MODIFIED';

export interface AuditLogEntry {
  id: string;
  eventType: AuditEventType;
  userId: string;
  userRole: UserRole;
  caseId?: string;
  evidenceId?: string;
  ipAddress: string;
  occurredAt: string;
  metadata: Record<string, unknown>;
}

// ─── Users ────────────────────────────────────────────────────────────────────

export interface AuthUser {
  id: string;
  username: string;
  role: UserRole;
  organization: string;
  jurisdiction: string;
}

export interface PortalUser {
  id: string;
  username: string;
  role: UserRole;
  organization: string;
  jurisdiction: string;
  isActive: boolean;
  createdAt: string;
}

// ─── API Response Wrappers ────────────────────────────────────────────────────

export interface PaginatedResponse<T> {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
}

export interface ApiError {
  message: string;
  statusCode: number;
}

// ─── Filters ─────────────────────────────────────────────────────────────────

export interface CaseListParams {
  status?: CaseStatus;
  riskLevel?: RiskLevel;
  incidentType?: IncidentType;
  dateFrom?: string;
  dateTo?: string;
  search?: string;
  page?: number;
  pageSize?: number;
}

export interface AuditLogParams {
  eventType?: AuditEventType;
  userId?: string;
  caseId?: string;
  dateFrom?: string;
  dateTo?: string;
  page?: number;
  pageSize?: number;
}

// ─── Officer Reports ──────────────────────────────────────────────────────────

export interface OfficerReport {
  id: string;
  caseId: string;
  officerId: string;
  officerName: string;
  actionsTaken: string;
  findings: string;
  blockers?: string;
  recommendedNextAction?: string;
  requiresAnotherDepartment: boolean;
  targetDepartment?: string;
  createdAt: string;
  reviewedByHead: boolean;
  reviewedAt?: string;
}

// ─── Department Stats ─────────────────────────────────────────────────────────

export interface DepartmentStats {
  total: number;
  unassigned: number;
  assigned: number;
  inProgress: number;
  highRisk: number;
  resolved: number;
  perOfficer: { officerId: string; name: string; count: number }[];
}

// ─── Agreement ────────────────────────────────────────────────────────────────

export interface AgreementStatus {
  agreementAccepted: boolean | null;
  acceptedAt?: string;
}

// ─── CaseListParams ───────────────────────────────────────────────────────────

export interface CaseListParams {
  status?: CaseStatus;
  riskLevel?: RiskLevel;
  incidentType?: string;
  search?: string;
  page?: number;
  pageSize?: number;
}

// ─── AuditLogParams ───────────────────────────────────────────────────────────

export interface AuditLogParams {
  eventType?: string;
  userId?: string;
  caseId?: string;
  dateFrom?: string;
  dateTo?: string;
  page?: number;
  pageSize?: number;
}
