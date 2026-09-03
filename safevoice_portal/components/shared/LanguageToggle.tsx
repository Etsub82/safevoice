'use client';

import { useRouter, usePathname } from 'next/navigation';

const LANGUAGES = [
  { code: 'en', label: 'EN' },
  { code: 'am', label: 'አማ' },
];

export default function LanguageToggle({ currentLocale }: { currentLocale: string }) {
  const router = useRouter();
  const pathname = usePathname();

  const switchTo = (code: string) => {
    // Swap locale prefix in URL
    const segments = pathname.split('/');
    segments[1] = code;
    router.push(segments.join('/'));
  };

  return (
    <div className="flex items-center gap-1">
      {LANGUAGES.map((lang) => (
        <button
          key={lang.code}
          onClick={() => switchTo(lang.code)}
          className={`px-2 py-1 text-xs rounded font-medium transition ${
            currentLocale === lang.code
              ? 'bg-primary text-white'
              : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
          }`}
        >
          {lang.label}
        </button>
      ))}
    </div>
  );
}
