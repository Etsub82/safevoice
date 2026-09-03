import { Suspense } from 'react';
import LoginForm from '@/components/auth/LoginForm';

export default function LoginPage() {
  return (
    <main className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="w-full max-w-md bg-white rounded-2xl shadow-lg p-8">
        <div className="mb-8 text-center">
          <h1 className="text-2xl font-bold text-gray-900">SafeVoice</h1>
          <p className="text-sm text-gray-500 mt-1">Justice &amp; Case Management Portal</p>
        </div>
        <Suspense fallback={<div className="text-center text-gray-400 text-sm">Loading...</div>}>
          <LoginForm />
        </Suspense>
      </div>
    </main>
  );
}
