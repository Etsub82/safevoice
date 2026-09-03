'use client';

import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { assignmentApi } from '@/lib/api/assignment';

interface Props {
  caseId: string;
  userRole: string;
}

export default function OfficerReportPanel({ caseId, userRole }: Props) {
  const [showForm, setShowForm] = useState(false);
  const [form, setForm] = useState({
    actionsTaken: '', findings: '', blockers: '',
    recommendedNextAction: '', requiresAnotherDepartment: false, targetDepartment: '',
  });
  const qc = useQueryClient();

  const isOfficer = ['Officer', 'Investigator', 'HeadOfDepartment', 'Supervisor'].includes(userRole);
  const isHead = ['HeadOfDepartment', 'Supervisor', 'InstitutionalAdmin', 'SystemAdmin'].includes(userRole);

  const { data: reportsRes } = useQuery({
    queryKey: ['case-reports', caseId],
    queryFn: () => assignmentApi.getReports(caseId),
  });

  const submitMutation = useMutation({
    mutationFn: () => assignmentApi.submitReport(caseId, form),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['case-reports', caseId] });
      setShowForm(false);
      setForm({ actionsTaken: '', findings: '', blockers: '', recommendedNextAction: '', requiresAnotherDepartment: false, targetDepartment: '' });
    },
  });

  const reviewMutation = useMutation({
    mutationFn: (reportId: string) => assignmentApi.reviewReport(caseId, reportId),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['case-reports', caseId] }),
  });

  const reports = reportsRes?.data ?? [];

  return (
    <div className="bg-white rounded-xl border border-gray-200 p-5 space-y-4">
      <div className="flex items-center justify-between">
        <h3 className="font-semibold text-gray-800">Officer Reports ({reports.length})</h3>
        {isOfficer && (
          <button onClick={() => setShowForm(!showForm)} className="text-xs text-blue-600 hover:underline">
            {showForm ? 'Cancel' : '+ Submit Report'}
          </button>
        )}
      </div>

      {showForm && (
        <div className="space-y-3 border border-blue-100 bg-blue-50 rounded-xl p-4">
          <h4 className="text-sm font-semibold text-blue-800">Submit Progress Report</h4>
          {[
            { key: 'actionsTaken', label: 'Actions Taken *', required: true },
            { key: 'findings', label: 'Current Findings *', required: true },
            { key: 'blockers', label: 'Blockers / Problems', required: false },
            { key: 'recommendedNextAction', label: 'Recommended Next Action', required: false },
          ].map(f => (
            <div key={f.key}>
              <label className="block text-xs font-medium text-gray-600 mb-1">{f.label}</label>
              <textarea
                rows={2}
                value={(form as any)[f.key]}
                onChange={e => setForm(prev => ({ ...prev, [f.key]: e.target.value }))}
                className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-blue-500"
              />
            </div>
          ))}
          <label className="flex items-center gap-2 text-sm text-gray-700">
            <input
              type="checkbox"
              checked={form.requiresAnotherDepartment}
              onChange={e => setForm(prev => ({ ...prev, requiresAnotherDepartment: e.target.checked }))}
            />
            Requires another department
          </label>
          {form.requiresAnotherDepartment && (
            <input
              value={form.targetDepartment}
              onChange={e => setForm(prev => ({ ...prev, targetDepartment: e.target.value }))}
              placeholder="Target department name..."
              className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm"
            />
          )}
          <button
            onClick={() => submitMutation.mutate()}
            disabled={!form.actionsTaken || !form.findings || submitMutation.isPending}
            className="w-full bg-blue-700 text-white text-sm font-medium py-2 rounded-lg disabled:opacity-50"
          >
            {submitMutation.isPending ? 'Submitting...' : 'Submit Report'}
          </button>
        </div>
      )}

      {reports.length === 0 ? (
        <p className="text-sm text-gray-400">No reports submitted yet.</p>
      ) : (
        <div className="space-y-3">
          {reports.map(r => (
            <div key={r.id} className="border border-gray-200 rounded-xl p-4 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-gray-800">{r.officerName}</span>
                <div className="flex items-center gap-2">
                  {r.reviewedByHead ? (
                    <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded">Reviewed</span>
                  ) : isHead ? (
                    <button
                      onClick={() => reviewMutation.mutate(r.id)}
                      className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded hover:bg-blue-200"
                    >
                      Mark Reviewed
                    </button>
                  ) : (
                    <span className="text-xs bg-yellow-100 text-yellow-700 px-2 py-0.5 rounded">Pending Review</span>
                  )}
                  <span className="text-xs text-gray-400">{new Date(r.createdAt).toLocaleDateString()}</span>
                </div>
              </div>
              <div className="text-xs text-gray-600 space-y-1">
                <p><span className="font-medium">Actions:</span> {r.actionsTaken}</p>
                <p><span className="font-medium">Findings:</span> {r.findings}</p>
                {r.blockers && <p><span className="font-medium">Blockers:</span> {r.blockers}</p>}
                {r.recommendedNextAction && <p><span className="font-medium">Next Action:</span> {r.recommendedNextAction}</p>}
                {r.requiresAnotherDepartment && (
                  <p className="text-orange-600"><span className="font-medium">→ Requires Dept:</span> {r.targetDepartment}</p>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
