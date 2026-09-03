'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { assignmentApi } from '@/lib/api/assignment';
import { casesApi } from '@/lib/api/cases';
import { useAuthStore } from '@/lib/store/authStore';

export default function HeadDashboard() {
  const router = useRouter();
  const user = useAuthStore(s => s.user);

  const { data: statsRes } = useQuery({
    queryKey: ['dept-stats'],
    queryFn: () => assignmentApi.getDepartmentStats(),
    refetchInterval: 30_000,
  });

  const { data: casesRes, isLoading } = useQuery({
    queryKey: ['head-cases'],
    queryFn: () => casesApi.list({ pageSize: 50 }),
  });

  const stats = statsRes?.data;
  const cases = casesRes?.data?.items ?? [];
  const unassigned = cases.filter(c => !c.assignedOfficerName && c.status !== 'Closed' && c.status !== 'Resolved');

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Head of Department Dashboard</h1>
        <p className="text-gray-500 text-sm mt-1">Monitor cases, assign officers, and track progress</p>
      </div>

      {/* Stats Grid */}
      {stats && (
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-4">
          {[
            { label: 'Total Cases', value: stats.total, color: 'bg-blue-50 text-blue-700' },
            { label: 'Unassigned', value: stats.unassigned, color: 'bg-red-50 text-red-700' },
            { label: 'Assigned', value: stats.assigned, color: 'bg-yellow-50 text-yellow-700' },
            { label: 'In Progress', value: stats.inProgress, color: 'bg-purple-50 text-purple-700' },
            { label: 'High Risk', value: stats.highRisk, color: 'bg-orange-50 text-orange-700' },
            { label: 'Resolved', value: stats.resolved, color: 'bg-green-50 text-green-700' },
          ].map(s => (
            <div key={s.label} className={`rounded-xl p-4 ${s.color}`}>
              <p className="text-2xl font-bold">{s.value}</p>
              <p className="text-xs font-medium mt-1">{s.label}</p>
            </div>
          ))}
        </div>
      )}

      {/* Officer Workload */}
      {stats && stats.perOfficer.length > 0 && (
        <div className="bg-white rounded-xl border border-gray-200 p-5">
          <h2 className="font-semibold text-gray-800 mb-3">Cases per Officer</h2>
          <div className="space-y-2">
            {stats.perOfficer.map(o => (
              <div key={o.officerId} className="flex items-center gap-3">
                <span className="text-sm text-gray-600 w-32 truncate">{o.name}</span>
                <div className="flex-1 bg-gray-100 rounded-full h-2">
                  <div
                    className="bg-blue-500 h-2 rounded-full"
                    style={{ width: `${Math.min((o.count / (stats.total || 1)) * 100, 100)}%` }}
                  />
                </div>
                <span className="text-sm font-medium text-gray-700 w-8 text-right">{o.count}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Unassigned Cases */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="px-5 py-4 border-b border-gray-100 flex items-center justify-between">
          <h2 className="font-semibold text-gray-800">Unassigned Cases ({unassigned.length})</h2>
          <span className="text-xs text-gray-400">Click a case to assign it</span>
        </div>
        {isLoading ? (
          <p className="text-gray-400 text-sm p-5">Loading...</p>
        ) : unassigned.length === 0 ? (
          <p className="text-gray-400 text-sm p-5">All cases are assigned ✓</p>
        ) : (
          <div className="divide-y divide-gray-100">
            {unassigned.map(c => (
              <div
                key={c.id}
                onClick={() => router.push(`/cases/${c.id}`)}
                className="flex items-center gap-4 px-5 py-3 hover:bg-gray-50 cursor-pointer"
              >
                <span className="font-mono text-xs text-gray-500">{c.id.slice(0, 8).toUpperCase()}</span>
                <span className="text-sm text-gray-700 flex-1">{c.incidentType}</span>
                <span className={`text-xs px-2 py-0.5 rounded font-medium ${
                  c.riskLevel === 'High' ? 'bg-red-100 text-red-700' :
                  c.riskLevel === 'Medium' ? 'bg-yellow-100 text-yellow-700' :
                  'bg-green-100 text-green-700'
                }`}>{c.riskLevel}</span>
                <span className="text-xs text-gray-400">{new Date(c.submittedAt).toLocaleDateString()}</span>
              </div>
            ))}
          </div>
        )}
      </div>

      {/* All Cases Table */}
      <div className="bg-white rounded-xl border border-gray-200">
        <div className="px-5 py-4 border-b border-gray-100">
          <h2 className="font-semibold text-gray-800">All Cases</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="min-w-full text-sm">
            <thead className="bg-gray-50">
              <tr>
                {['Case ID', 'Type', 'Risk', 'Status', 'Assigned To', 'Submitted'].map(h => (
                  <th key={h} className="px-4 py-3 text-left text-xs font-semibold text-gray-500 uppercase">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100">
              {cases.map(c => (
                <tr key={c.id} onClick={() => router.push(`/cases/${c.id}`)} className="cursor-pointer hover:bg-gray-50">
                  <td className="px-4 py-3 font-mono text-xs text-gray-600">{c.id.slice(0,8).toUpperCase()}</td>
                  <td className="px-4 py-3 text-gray-700">{c.incidentType}</td>
                  <td className="px-4 py-3">
                    <span className={`px-2 py-0.5 rounded text-xs font-medium ${
                      c.riskLevel === 'High' ? 'bg-red-100 text-red-700' :
                      c.riskLevel === 'Medium' ? 'bg-yellow-100 text-yellow-700' : 'bg-green-100 text-green-700'
                    }`}>{c.riskLevel}</span>
                  </td>
                  <td className="px-4 py-3 text-gray-600 text-xs">{c.status}</td>
                  <td className="px-4 py-3 text-gray-600 text-xs">{c.assignedOfficerName ?? <span className="text-red-500">Unassigned</span>}</td>
                  <td className="px-4 py-3 text-gray-400 text-xs">{new Date(c.submittedAt).toLocaleDateString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
