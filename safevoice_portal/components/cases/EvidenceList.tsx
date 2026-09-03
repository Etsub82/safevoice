'use client';

import { useState } from 'react';
import { evidenceApi } from '@/lib/api/evidence';

interface EvidenceItem {
  id: string;
  fileName: string;
  mimeType: string;
  fileSizeBytes: number;
  uploadedAt: string;
  virusScanPassed?: boolean;
}

function formatBytes(b: number) {
  if (b < 1024) return `${b} B`;
  if (b < 1024 * 1024) return `${(b / 1024).toFixed(1)} KB`;
  return `${(b / (1024 * 1024)).toFixed(1)} MB`;
}

function fileIcon(mime: string) {
  if (mime.startsWith('image/')) return '🖼️';
  if (mime.startsWith('audio/')) return '🎵';
  if (mime.startsWith('video/')) return '🎬';
  if (mime.includes('pdf'))      return '📄';
  return '📎';
}

interface Props {
  caseId: string;
  items: EvidenceItem[];
}

export default function EvidenceList({ caseId, items }: Props) {
  const [preview, setPreview] = useState<{
    url: string;
    type: string;
    name: string;
    available: boolean;
  } | null>(null);
  const [loading, setLoading] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  const handleView = async (item: EvidenceItem) => {
    setError(null);
    setLoading(item.id);
    try {
      const res = await evidenceApi.download(caseId, item.id);

      // Check if backend returned JSON "not available" instead of a blob
      const contentType = (res.headers as any)?.['content-type'] ?? '';
      if (contentType.includes('application/json')) {
        // File not stored locally — show metadata only
        setPreview({ url: '', type: item.mimeType, name: item.fileName, available: false });
        return;
      }

      const url = URL.createObjectURL(res.data as Blob);
      setPreview({ url, type: item.mimeType, name: item.fileName, available: true });
    } catch (e: any) {
      setError(`Could not load file: ${e?.response?.data?.error ?? e?.message ?? 'Unknown error'}`);
    } finally {
      setLoading(null);
    }
  };

  const closePreview = () => {
    if (preview?.url) URL.revokeObjectURL(preview.url);
    setPreview(null);
  };

  if (items.length === 0) {
    return (
      <div className="border border-gray-200 rounded-xl p-8 text-center bg-white">
        <p className="text-3xl mb-2">📎</p>
        <p className="text-sm text-gray-500">No evidence attached to this case.</p>
      </div>
    );
  }

  return (
    <div className="space-y-3">
      {error && (
        <div className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-4 py-3">
          {error}
        </div>
      )}

      {/* Evidence list */}
      <ul className="divide-y divide-gray-100 border border-gray-200 rounded-xl overflow-hidden bg-white">
        {items.map((item) => (
          <li key={item.id} className="flex items-center gap-3 px-4 py-3 hover:bg-gray-50 transition">
            <span className="text-xl flex-shrink-0">{fileIcon(item.mimeType)}</span>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-gray-800 truncate">{item.fileName}</p>
              <p className="text-xs text-gray-400 mt-0.5">
                {item.mimeType} · {formatBytes(item.fileSizeBytes)} ·{' '}
                {new Date(item.uploadedAt).toLocaleDateString()}
              </p>
            </div>
            <button
              onClick={() => handleView(item)}
              disabled={loading === item.id}
              className="text-xs font-medium text-blue-600 hover:underline disabled:opacity-50 flex-shrink-0"
            >
              {loading === item.id ? 'Loading…' : 'View'}
            </button>
          </li>
        ))}
      </ul>

      {/* Inline preview panel */}
      {preview && (
        <div className="border border-gray-200 rounded-xl p-4 bg-gray-50 space-y-3">
          <div className="flex justify-between items-center">
            <p className="text-sm font-medium text-gray-700 truncate">{preview.name}</p>
            <button
              onClick={closePreview}
              className="text-xs text-gray-400 hover:text-gray-600 flex-shrink-0 ml-2"
            >
              ✕ Close
            </button>
          </div>

          {!preview.available ? (
            <div className="bg-amber-50 border border-amber-200 rounded-lg px-4 py-3 text-sm text-amber-700">
              File is not stored locally on this server. In a production deployment, files are
              served from cloud storage (Azure Blob / S3).
            </div>
          ) : preview.type.startsWith('image/') ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={preview.url}
              alt={preview.name}
              className="max-h-96 w-full object-contain rounded-lg bg-white border border-gray-100"
            />
          ) : preview.type.startsWith('audio/') ? (
            <audio controls src={preview.url} className="w-full" />
          ) : preview.type.startsWith('video/') ? (
            <video controls src={preview.url} className="w-full max-h-96 rounded-lg" />
          ) : (
            <div className="text-center py-4">
              <p className="text-sm text-gray-500 mb-2">Preview not available for this file type.</p>
              <a
                href={preview.url}
                download={preview.name}
                className="text-sm text-blue-600 hover:underline font-medium"
              >
                ⬇️ Download {preview.name}
              </a>
            </div>
          )}
        </div>
      )}
    </div>
  );
}
