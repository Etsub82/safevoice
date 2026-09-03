'use client';

import { useState } from 'react';
import { InvestigationNote } from '@/lib/types';
import { casesApi } from '@/lib/api/cases';
import { useQueryClient } from '@tanstack/react-query';
import RoleGuard from '@/components/shared/RoleGuard';

interface Props { caseId: string; notes: InvestigationNote[] }

export default function InvestigationNotes({ caseId, notes }: Props) {
  const [text, setText] = useState('');
  const [saving, setSaving] = useState(false);
  const qc = useQueryClient();

  const submit = async () => {
    if (!text.trim()) return;
    setSaving(true);
    await casesApi.addNote(caseId, text.trim());
    setText('');
    setSaving(false);
    qc.invalidateQueries({ queryKey: ['case', caseId] });
  };

  return (
    <div className="space-y-3">
      <h4 className="text-sm font-semibold text-gray-700">Investigation Notes</h4>
      {notes.length === 0 && <p className="text-xs text-gray-400">No notes yet.</p>}
      <ul className="space-y-2">
        {notes.map((n) => (
          <li key={n.id} className="bg-gray-50 border border-gray-200 rounded-lg px-4 py-3">
            <p className="text-sm text-gray-800">{n.content}</p>
            <p className="text-xs text-gray-400 mt-1">{n.authorName} · {new Date(n.createdAt).toLocaleString()}</p>
          </li>
        ))}
      </ul>
      <RoleGuard permission="add_notes">
        <div className="flex gap-2">
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            rows={2}
            placeholder="Add investigation note…"
            className="flex-1 border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary resize-none"
          />
          <button
            onClick={submit}
            disabled={saving || !text.trim()}
            className="bg-primary text-white text-sm px-4 py-2 rounded-lg disabled:opacity-50 self-end transition"
          >
            Add
          </button>
        </div>
      </RoleGuard>
    </div>
  );
}
