import Link from 'next/link';

export default function ResponsibilityNoticePage() {
  return (
    <main className="min-h-screen bg-slate-900 flex items-center justify-center px-4 py-12">
      <div className="w-full max-w-2xl">

        {/* Header */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-blue-900 border border-blue-700 mb-4">
            <svg className="w-8 h-8 text-blue-300" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z" />
            </svg>
          </div>
          <h1 className="text-2xl font-bold text-white tracking-tight">SafeVoice</h1>
          <p className="text-blue-300 text-sm mt-1 font-medium uppercase tracking-widest">Justice &amp; Case Management Portal</p>
        </div>

        {/* Notice card */}
        <div className="bg-slate-800 border border-slate-700 rounded-2xl overflow-hidden shadow-2xl">

          {/* Card header */}
          <div className="bg-slate-700 border-b border-slate-600 px-6 py-4">
            <h2 className="text-base font-semibold text-slate-100">
              Professional Responsibility &amp; Confidentiality Notice
            </h2>
            <p className="text-xs text-slate-400 mt-0.5">
              Please read carefully before continuing. This system is for authorized institutional use only.
            </p>
          </div>

          {/* Scrollable content */}
          <div className="px-6 py-5 space-y-5 max-h-[60vh] overflow-y-auto text-sm text-slate-300 leading-relaxed">

            <p>
              The SafeVoice Justice and Case Management Portal contains <strong className="text-white">highly sensitive and confidential information</strong> about victims, children, alleged perpetrators, evidence, investigations, legal proceedings, and protection services. Access is strictly limited to individuals who are authorized to use this system as part of their official professional duties.
            </p>

            <div>
              <p className="text-slate-100 font-semibold mb-2">By accessing this system, you agree to:</p>
              <ul className="space-y-2">
                {[
                  'Respect the privacy, dignity, safety, and rights of all victims and children at all times.',
                  'Access only the cases and information you are specifically authorized to access based on your role, organization, and jurisdiction.',
                  'Never share, disclose, or transmit confidential information to any unauthorized person or external party.',
                  'Never use SafeVoice information for personal purposes, private interest, or outside your official duties.',
                  'Protect your account credentials and never share your login details with anyone.',
                  'Avoid accessing cases involving people you have a personal, financial, or other conflicting relationship with.',
                  'Immediately report any conflict of interest to your supervisor and the system administrator.',
                ].map((item, i) => (
                  <li key={i} className="flex gap-2.5">
                    <span className="mt-0.5 flex-shrink-0 w-5 h-5 rounded-full bg-blue-900 border border-blue-700 flex items-center justify-center text-blue-300 text-xs font-bold">{i + 1}</span>
                    <span>{item}</span>
                  </li>
                ))}
              </ul>
            </div>

            <div className="bg-amber-950 border border-amber-800 rounded-lg px-4 py-3">
              <p className="text-amber-300 font-semibold text-xs uppercase tracking-wide mb-1">⚠ Audit &amp; Monitoring</p>
              <p className="text-amber-200 text-xs leading-relaxed">
                Sensitive activities on this portal — including viewing cases, accessing victim identity information, viewing or downloading evidence, changing case assignments, updating case status, making referrals, and closing cases — <strong>may be recorded in the SafeVoice audit system</strong>. These records are protected and reviewed for compliance.
              </p>
            </div>

            <div className="bg-red-950 border border-red-800 rounded-lg px-4 py-3">
              <p className="text-red-300 font-semibold text-xs uppercase tracking-wide mb-1">⛔ Consequences of Misuse</p>
              <p className="text-red-200 text-xs leading-relaxed">
                Unauthorized access, misuse, disclosure, or abuse of information in this system may result in <strong>institutional, disciplinary, or legal consequences</strong> under applicable laws and organizational policies.
              </p>
            </div>

            <p className="text-slate-400 text-xs border-t border-slate-700 pt-4">
              Your role, permissions, jurisdiction, and access level are determined and enforced by the SafeVoice backend based on your authenticated account. The frontend does not grant or override access rights. All authorization decisions are made server-side.
            </p>

          </div>

          {/* Action */}
          <div className="px-6 py-5 border-t border-slate-700 bg-slate-800">
            <div className="flex gap-3">
              <Link
                href="/login"
                className="flex-1 block text-center bg-blue-700 hover:bg-blue-600 active:bg-blue-800 text-white font-semibold py-3 px-6 rounded-xl transition-colors duration-150 text-sm shadow-lg"
              >
                ✓ I Agree — Continue to Login
              </Link>
              <Link
                href="/disagree"
                className="flex-1 block text-center bg-slate-700 hover:bg-red-900 border border-red-700 text-red-400 hover:text-red-200 font-semibold py-3 px-6 rounded-xl transition-colors duration-150 text-sm"
              >
                ✗ I Disagree
              </Link>
            </div>
            <p className="text-center text-xs text-slate-500 mt-3">
              Authorized institutional users only · SafeVoice Justice Portal
            </p>
          </div>

        </div>

      </div>
    </main>
  );
}
