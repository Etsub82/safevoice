/**
 * ⚠️  DEVELOPMENT ONLY — Mock authentication.
 * Never imported or executed in production builds.
 * Provides fake JWT tokens and user objects for UI preview only.
 * Does NOT bypass, weaken, or modify the real authentication system.
 */

import { AuthUser, UserRole } from '@/lib/types';

export interface MockProfile {
  label: string;
  user: AuthUser;
  description: string;
}

export const MOCK_PROFILES: MockProfile[] = [
  {
    label: 'Police Officer',
    description: 'Can intake cases, add notes, update status, view Tier 1 & 2 data',
    user: { id: 'u-officer-01',    username: 'kebede.alemu',  role: 'Officer',         organization: 'Addis Ababa Police', jurisdiction: 'Addis Ababa' },
  },
  {
    label: 'Police Supervisor',
    description: 'Can assign cases, escalate, refer, monitor all officers in jurisdiction',
    user: { id: 'u-supervisor-01', username: 'tesfaye.girma', role: 'Supervisor',      organization: 'Addis Ababa Police', jurisdiction: 'Addis Ababa' },
  },
  {
    label: 'Prosecutor',
    description: 'Can manage referred cases, upload legal docs, transition to Court Process',
    user: { id: 'u-prosecutor-01', username: 'meron.tadesse', role: 'Prosecutor',      organization: 'Federal Prosecutor', jurisdiction: 'Federal' },
  },
  {
    label: 'Lawyer / Legal Aid',
    description: 'Read-only on assigned cases, can upload legal documents',
    user: { id: 'u-lawyer-01',     username: 'selam.bekele',  role: 'Lawyer',          organization: 'Legal Aid Ethiopia', jurisdiction: 'Addis Ababa' },
  },
  {
    label: 'Social Worker',
    description: 'Tier 3 data only, no evidence or investigation access',
    user: { id: 'u-social-01',     username: 'hana.girma',    role: 'SocialWorker',    organization: 'Ministry of Women', jurisdiction: 'Addis Ababa' },
  },
  {
    label: 'System Administrator',
    description: 'Full admin access: user management, audit logs',
    user: { id: 'u-admin-01',      username: 'admin',         role: 'SystemAdmin',     organization: 'SafeVoice HQ',       jurisdiction: 'National' },
  },
  {
    label: 'Security Auditor',
    description: 'Read-only access to audit logs',
    user: { id: 'u-auditor-01',    username: 'audit.officer', role: 'SecurityAuditor', organization: 'SafeVoice HQ',       jurisdiction: 'National' },
  },
];

/** Fake JWT — clearly not a real token, never sent to any server */
export const MOCK_ACCESS_TOKEN = 'DEV_MOCK_TOKEN_NOT_A_REAL_JWT';

export function getMockProfile(role: UserRole): MockProfile | undefined {
  return MOCK_PROFILES.find((p) => p.user.role === role);
}
