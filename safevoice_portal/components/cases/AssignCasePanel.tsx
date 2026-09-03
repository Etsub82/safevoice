'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { assignmentApi } from '@/lib/api/assignment';

interface Props {
  caseId: string;
  currentOfficerName?: string;
  userRole: string;
}

export default function AssignCasePanel({ caseId, currentOfficerName, userRole }: Props) {
  const [selectedOfficer, setSelectedOfficer] = useState('');
  const [reason, setReason] = useState('');
  const [showForm, setShowForm] = useState(false);
  const qc = useQueryClient();

  const canAssign = ['HeadOfDepartment', 'Supervisor', 'InstitutionalAdmin', 'SystemAdmin', 'Admin'].includes(userRole);

  const { data: officersRes } = useQuery({
    queryKey: ['officers'],
    queryFn: () => assignmentApi.getOfficers(),
    enabled: canAssign && showForm,
  });

  const assignMutation = useMutation({
    mutationFn: () => assignmentApi.assignCase(caseId, selectedOfficer, reason),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['case', caseId] });
      qc.invalidateQueries({ queryKey: ['head-cases'] });
      qc.invalidateQueries({ queryKey: ['dept-stats'] });
      setShowForm(false);
      setSelectedOfficer('');
      setReason('');
    },
  });

  const officers = officersRes?.data ?? [];

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5">
      <div className="flex items-center justify-between mb-3">
        <h3 className="font-semibold text-gray-800">Assignment</h3>
        {canAssign && (
          <button
            onClick={() => setShowForm(!showForm)}
            className="text-xs text-blue-600 hover:underline"
          >
            {showForm ? 'Cancel' : currentOfficerName ? 'Reassign' : 'Assign Officer'}
          </button>
        )}
      </div>

      {currentOfficerName ? (
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 bg-blue-100 rounded-full flex items-center justify-center text-blue-700 font-bold text-sm">
            {currentOfficerName[0]?.toUpperCase()}
          </div>
          <div>
            <p className="text-sm font-medium text-gray-800">{currentOfficerName}</p>
            <p className="text-xs text-gray-400">Assigned Officer</p>
          </div>
        </div>
      ) : (
        <p className="text-sm text-red-500">No officer assigned yet</p>
      )}

      {showForm && canAssign && (
        <div className="mt-4 space-y-3 border-t border-gray-100 pt-4">
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Select Officer</label>
            <select
              value={selectedOfficer}
              onChange={e => setSelectedOfficer(e.target.value)}
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            >
              <option value="">-- Choose officer --</option>
              {officers.map(o => (
                <option key={o.id} value={o.id}>
                  {o.username || o.displayName} {o.organization ? `(${o.organization})` : ''}
                </option>
              ))}
            </select>
          </div>
          <div>
            <label className="block text-xs font-medium text-gray-600 mb-1">Reason (optional)</label>
            <input
              value={reason}
              onChange={e => setReason(e.target.value)}
              placeholder="Assignment reason..."
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <button
            onClick={() => assignMutation.mutate()}
            disabled={!selectedOfficer || assignMutation.isPending}
            className="w-full bg-blue-700 hover:bg-blue-800 text-white text-sm font-medium py-2 rounded-lg disabled:opacity-50 transition"
          >
            {assignMutation.isPending ? 'Assigning...' : 'Confirm Assignment'}
          </button>
          {assignMutation.isError && (
            <p className="text-red-500 text-xs">Failed to assign. Try again.</p>
          )}
        </div>
      )}
    </div>
  );
}
