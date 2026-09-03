'use client';

import { useState } from 'react';
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';
import { CaseStatus, UserRole } from '@/lib/types';
import { getValidNextStatuses } from '@/lib/utils/permissions';
import { casesApi } from '@/lib/api/cases';
import { useQueryClient } from '@tanstack/react-query';

const REASON_REQUIRED: CaseStatus[] = ['Escalated', 'Reassigned', 'Resolved', 'Closed'];

const schema = z.object({
  status: z.string().min(1),
  reason: z.string().optional(),
}).superRefine((data, ctx) => {
  if (REASON_REQUIRED.includes(data.status as CaseStatus) && !data.reason?.trim()) {
    ctx.addIssue({ code: z.ZodIssueCode.custom, message: 'Reason is required for this status', path: ['reason'] });
  }
});

interface Props {
  caseId: string;
  currentStatus: CaseStatus;
  userRole: UserRole;
}

export default function StatusUpdateForm({ caseId, currentStatus, userRole }: Props) {
  const qc = useQueryClient();
  const [success, setSuccess] = useState(false);
  const nextStatuses = getValidNextStatuses(currentStatus);

  const { register, handleSubmit, watch, formState: { errors, isSubmitting } } = useForm({
    resolver: zodResolver(schema),
    defaultValues: { status: '', reason: '' },
  });

  const selectedStatus = watch('status') as CaseStatus;
  const needsReason = REASON_REQUIRED.includes(selectedStatus);

  if (nextStatuses.length === 0) return null;

  const onSubmit = async (data: { status: string; reason?: string }) => {
    await casesApi.updateStatus(caseId, data.status as CaseStatus, data.reason ?? '');
    setSuccess(true);
    qc.invalidateQueries({ queryKey: ['case', caseId] });
  };

  if (success) return <p className="text-sm text-green-600">Status updated successfully.</p>;

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-3 bg-gray-50 border border-gray-200 rounded-xl p-4">
      <h4 className="text-sm font-semibold text-gray-700">Update Status</h4>
      <select
        {...register('status')}
        className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary"
      >
        <option value="">Select new status…</option>
        {nextStatuses.map((s) => <option key={s} value={s}>{s}</option>)}
      </select>
      {errors.status && <p className="text-xs text-red-600">{String(errors.status.message)}</p>}

      {needsReason && (
        <textarea
          {...register('reason')}
          placeholder="Reason (required)"
          rows={2}
          className="w-full border border-gray-300 rounded-lg px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary resize-none"
        />
      )}
      {errors.reason && <p className="text-xs text-red-600">{String(errors.reason.message)}</p>}

      <button
        type="submit"
        disabled={isSubmitting}
        className="bg-primary hover:bg-primary-hover text-white text-sm font-medium px-4 py-2 rounded-lg disabled:opacity-60 transition"
      >
        {isSubmitting ? 'Updating…' : 'Update Status'}
      </button>
    </form>
  );
}
