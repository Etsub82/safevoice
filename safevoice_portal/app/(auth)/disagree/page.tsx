import Link from 'next/link';

export default function DisagreePage() {
  return (
    <main className="min-h-screen bg-slate-900 flex items-center justify-center px-4">
      <div className="max-w-md w-full bg-slate-800 border border-slate-700 rounded-2xl shadow-2xl p-8 text-center space-y-5">
        <div className="inline-flex items-center justify-center w-16 h-16 rounded-full bg-red-900 border border-red-700">
          <span className="text-3xl">🚫</span>
        </div>
        <h1 className="text-xl font-bold text-white">Access Not Permitted</h1>
        <p className="text-slate-300 text-sm leading-relaxed">
          You have chosen not to agree to the SafeVoice Confidentiality and Professional Responsibility terms.
        </p>
        <p className="text-slate-400 text-sm leading-relaxed">
          Agreement to these terms is <strong className="text-white">mandatory</strong> to access the SafeVoice Justice Portal. You cannot proceed without accepting the terms.
        </p>
        <div className="border-t border-slate-700 pt-4">
          <p className="text-slate-500 text-xs mb-4">
            If you believe this is an error or you wish to reconsider, you may return to the notice page.
          </p>
          <Link
            href="/notice"
            className="block w-full text-center bg-slate-700 hover:bg-slate-600 text-slate-200 font-medium py-2.5 rounded-xl text-sm transition"
          >
            ← Return to Notice Page
          </Link>
        </div>
      </div>
    </main>
  );
}
