import { UserRole } from '@/lib/types';

export type Permission =
  | 'view_tier1'
  | 'view_tier2'
  | 'update_status'
  | 'assign_cases'
  | 'add_notes'
  | 'view_audit_log'
  | 'manage_users'
  | 'refer_cases'
  | 'upload_legal_docs'
  | 'request_emergency';

const ROLE_PERMISSIONS: Record<UserRole, Permission[]> = {
  HeadOfDepartment:    ['view_tier1', 'view_tier2', 'update_status', 'assign_cases', 'add_notes', 'refer_cases'],
  Officer:             ['view_tier1', 'view_tier2', 'update_status', 'add_notes', 'request_emergency'],
  Investigator:        ['view_tier1', 'view_tier2', 'update_status', 'add_notes'],
  Supervisor:          ['view_tier1', 'view_tier2', 'update_status', 'assign_cases', 'add_notes', 'refer_cases'],
  WomensProtection:    ['view_tier1', 'view_tier2', 'update_status', 'add_notes'],
  ChildProtection:     ['view_tier1', 'view_tier2', 'update_status', 'add_notes'],
  EmergencyResponse:   ['view_tier1', 'view_tier2', 'update_status', 'request_emergency'],
  RegionalAuthority:   ['view_tier1', 'view_tier2', 'update_status', 'assign_cases', 'refer_cases'],
  FederalAuthority:    ['view_tier1', 'view_tier2', 'update_status', 'assign_cases', 'refer_cases', 'view_audit_log'],
  Prosecutor:          ['view_tier1', 'view_tier2', 'update_status', 'add_notes', 'refer_cases', 'upload_legal_docs'],
  PublicProsecutor:    ['view_tier1', 'view_tier2', 'update_status', 'add_notes', 'refer_cases', 'upload_legal_docs'],
  CourtClerk:          ['view_tier2', 'add_notes'],
  Judge:               ['view_tier1', 'view_tier2'],
  Lawyer:              ['view_tier2', 'upload_legal_docs'],
  LegalAid:            ['view_tier2', 'upload_legal_docs'],
  SocialWorker:        [],
  ChildProtectionOrg:  ['view_tier2'],
  Shelter:             [],
  HealthcareReferral:  [],
  PsychosocialSupport: [],
  NGO:                 [],
  InstitutionalAdmin:  ['manage_users', 'assign_cases'],
  SystemAdmin:         ['manage_users', 'view_audit_log'],
  SecurityAuditor:     ['view_audit_log'],
};

export function hasPermission(role: UserRole, permission: Permission): boolean {
  return ROLE_PERMISSIONS[role]?.includes(permission) ?? false;
}

export function getRolePermissions(role: UserRole): Permission[] {
  return ROLE_PERMISSIONS[role] ?? [];
}

/** Valid next statuses a role may transition a case to from a given current status */
export const VALID_TRANSITIONS: Record<string, string[]> = {
  Submitted:        ['Received'],
  Received:         ['Triaged'],
  Triaged:          ['Assigned', 'Escalated'],
  Assigned:         ['Investigation', 'Escalated', 'Reassigned'],
  Investigation:    ['Escalated', 'Reassigned', 'ReferredToJustice', 'Resolved'],
  Escalated:        ['Assigned', 'Reassigned', 'ReferredToJustice'],
  Reassigned:       ['Investigation', 'Escalated'],
  ReferredToJustice:['CourtProcess', 'Resolved'],
  CourtProcess:     ['Resolved', 'Closed'],
  Resolved:         ['Closed'],
  Closed:           [],
};

export function getValidNextStatuses(currentStatus: string): string[] {
  return VALID_TRANSITIONS[currentStatus] ?? [];
}
