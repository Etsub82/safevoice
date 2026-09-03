import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'SafeVoice — Justice Portal',
  description: 'Justice & Case Management Web Portal',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
