import Sidebar from '@/components/shared/Sidebar';
import TopBar from '@/components/shared/TopBar';
import PortalProviders from '@/components/shared/PortalProviders';
import AgreementGate from '@/components/auth/AgreementGate';

export default function PortalLayout({ children }: { children: React.ReactNode }) {
  return (
    <PortalProviders>
      <AgreementGate>
        <div className="flex min-h-screen">
          <Sidebar />
          <div className="flex-1 flex flex-col bg-gray-50">
            <TopBar />
            <main className="flex-1 overflow-auto">
              <div className="max-w-7xl mx-auto px-6 py-8">{children}</div>
            </main>
          </div>
        </div>
      </AgreementGate>
    </PortalProviders>
  );
}
