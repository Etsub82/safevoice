'use client';

import { useState } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { useIdleTimeout } from '@/lib/hooks/useIdleTimeout';
import { useSessionRestore } from '@/lib/hooks/useSessionRestore';

function PortalShell({ children }: { children: React.ReactNode }) {
  useSessionRestore();
  useIdleTimeout();
  return <>{children}</>;
}

export default function PortalProviders({ children }: { children: React.ReactNode }) {
  const [queryClient] = useState(() => new QueryClient({
    defaultOptions: {
      queries: {
        staleTime: 30_000,
        gcTime: 60_000,
        retry: 1,
      },
    },
  }));

  return (
    <QueryClientProvider client={queryClient}>
      <PortalShell>{children}</PortalShell>
    </QueryClientProvider>
  );
}
