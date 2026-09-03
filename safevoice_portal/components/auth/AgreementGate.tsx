'use client';

import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';
import { agreementApi } from '@/lib/api/agreement';
import { useAuthStore } from '@/lib/store/authStore';

export default function AgreementGate({ children }: { children: React.ReactNode }) {
  const [status, setStatus] = useState<'loading' | 'accepted' | 'pending' | 'rejected'>('loading');
  const [submitting, setSubmitting] = useState(false);
  const router = useRouter();
  const { clearSession, user } = useAuthStore();

  useEffect(() => {
    if (!user) return;
    // Victim-side roles don't need agreement
    const portalRoles = ['Officer','Investigator','Supervisor','HeadOfDepartment','WomensProtection',
      'ChildProtection','EmergencyResponse','RegionalAuthority','FederalAuthority','Prosecutor',
      'PublicProsecutor','CourtClerk','Judge','Lawyer','LegalAid','SocialWorker','ChildProtectionOrg',
      'Shelter','HealthcareReferral','PsychosocialSupport','NGO','InstitutionalAdmin','SystemAdmin','SecurityAuditor'];
    if (!portalRoles.includes(user.role)) { setStatus('accepted'); return; }

    agreementApi.getStatus().then(res => {
      if (res.data.agreementAccepted === true) setStatus('accepted');
      else setStatus('pending');
    }).catch(() => setStatus('pending'));
  }, [user]);

  const handleAccept = async () => {
    setSubmitting(true);
    try {
      await agreementApi.accept();
      setStatus('accepted');
    } finally {
      setSubmitting(false);
    }
  };

  const handleReject = async () => {
    setSubmitting(true);
    try {
      await agreementApi.reject();
      setStatus('rejected');
      setTimeout(() => { clearSession(); router.push('/login'); }, 3000);
    } finally {
      setSubmitting(false);
    }
  };

  if (status === 'loading') {
    return <div className="min-h-screen flex items-center justify-center"><div className="text-gray-400">Loading...</div></div>;
  }

  if (status === 'rejected') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50">
        <div className="max-w-md text-center p-8 bg-white rounded-2xl shadow-lg">
          <div className="text-4xl mb-4">🚫</div>
          <h2 className="text-xl font-bold text-red-700 mb-2">Access Denied</h2>
          <p className="text-gray-600 text-sm">You must accept the SafeVoice agreement to access this system. You are being signed out.</p>
        </div>
      </div>
    );
  }

  if (status === 'pending') {
    return (
      <div className="min-h-screen flex items-center justify-center bg-gray-50 p-4">
        <div className="max-w-2xl w-full bg-white rounded-2xl shadow-lg overflow-hidden">
          <div className="bg-blue-900 px-8 py-6">
            <div className="flex items-center gap-3">
              <span className="text-3xl">🛡️</span>
              <div>
                <h1 className="text-xl font-bold text-white">SafeVoice Justice Portal</h1>
                <p className="text-blue-200 text-sm">Stakeholder Confidentiality Agreement</p>
              </div>
            </div>
          </div>

          <div className="px-8 py-6 space-y-4">
            <p className="text-gray-700 text-sm leading-relaxed">
              Before accessing the SafeVoice Justice Portal, you must read and accept the following terms:
            </p>

            {[
              { icon: '🔒', title: 'Confidential Case Information', text: 'You are accessing confidential case information involving victims of gender-based violence. This information is highly sensitive and legally protected.' },
              { icon: '✅', title: 'Authorized Use Only', text: 'Case information must only be used for authorized professional purposes directly related to your role. Personal use, unauthorized sharing, or disclosure is strictly prohibited.' },
              { icon: '🤝', title: 'Victim Protection', text: 'You must protect the identity, safety, and privacy of all victims and witnesses. Unauthorized disclosure of victim information may cause serious harm and is a violation of law.' },
              { icon: '📋', title: 'SafeVoice Rules', text: 'You agree to follow all SafeVoice confidentiality, security, and data handling policies. Violations may result in immediate removal of access and legal action.' },
              { icon: '🔍', title: 'Audit & Monitoring', text: 'All your actions within this portal are logged and monitored for security and accountability purposes.' },
            ].map((item) => (
              <div key={item.title} className="flex gap-3 p-4 bg-gray-50 rounded-xl">
                <span className="text-2xl flex-shrink-0">{item.icon}</span>
                <div>
                  <p className="font-semibold text-gray-800 text-sm">{item.title}</p>
                  <p className="text-gray-600 text-sm mt-0.5">{item.text}</p>
                </div>
              </div>
            ))}

            <div className="bg-amber-50 border border-amber-200 rounded-xl p-4">
              <p className="text-amber-800 text-sm font-medium">
                By clicking "I Agree", you confirm that you understand and accept all terms above and will act in accordance with SafeVoice policies.
              </p>
            </div>

            <div className="flex gap-3 pt-2">
              <button
                onClick={handleAccept}
                disabled={submitting}
                className="flex-1 bg-blue-700 hover:bg-blue-800 text-white font-semibold py-3 rounded-xl transition disabled:opacity-60"
              >
                {submitting ? 'Processing...' : '✓ I Agree — Continue to Portal'}
              </button>
              <button
                onClick={handleReject}
                disabled={submitting}
                className="flex-1 bg-white border-2 border-red-300 hover:bg-red-50 text-red-700 font-semibold py-3 rounded-xl transition disabled:opacity-60"
              >
                ✗ I Disagree — Sign Out
              </button>
            </div>
          </div>
        </div>
      </div>
    );
  }

  return <>{children}</>;
}
