'use client';

import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useParams } from 'next/navigation';
import Link from 'next/link';
import { evidenceApi } from '@/lib/api/evidence';
import EvidenceList from '@/components/cases/EvidenceList';
import RoleGuard from '@/components/shared/RoleGuard';

export default function EvidencePage() {
  const { id } = useParams<{ id: string }>();

  const { data, isLoading } = useQuery({
    queryKey: ['evidence', id],
    queryFn: () => evidenceApi.list(id),
  });

  const raw = data?.data;
  // Backend returns the array directly
  const items: any[] = Array.isArray(raw) ? raw : [];

  return (
    <div className="space-y-5 max-w-3xl">
      <div className="flex items-center gap-3">
        <Link href={`/cases/${id}`} className="text-sm text-gray-400 hover:text-gray-600">← Case Detail</Link>
        <h1 className="text-xl font-bold text-gray-900">Evidence</h1>
      </div>

      {isLoading ? (
        <p className="text-gray-400">Loading evidence…</p>
      ) : (
        <EvidenceList caseId={id} items={items} />
      )}

      {/* Lawyer document upload */}
      <RoleGuard permission="upload_legal_docs">
        <LegalDocUpload caseId={id} />
      </RoleGuard>
    </div>
  );
}

function LegalDocUpload({ caseId }: { caseId: string }) {
  const [file, setFile] = useState<File | null>(null);
  const [uploading, setUploading] = useState(false);
  const [done, setDone] = useState(false);

  const upload = async () => {
    if (!file) return;
    setUploading(true);
    await evidenceApi.upload(caseId, file, 'LegalDocument');
    setDone(true);
    setUploading(false);
  };

  if (done) return <p className="text-sm text-green-600">Document uploaded.</p>;

  return (
    <div className="bg-white border border-gray-200 rounded-xl p-4 space-y-3">
      <h4 className="text-sm font-semibold text-gray-700">Upload Legal Document</h4>
      <input type="file" accept=".pdf,.doc,.docx" onChange={(e) => setFile(e.target.files?.[0] ?? null)} className="text-sm" />
      <button
        onClick={upload}
        disabled={!file || uploading}
        className="bg-primary text-white text-sm px-4 py-2 rounded-lg disabled:opacity-50 transition"
      >
        {uploading ? 'Uploading…' : 'Upload'}
      </button>
    </div>
  );
}
