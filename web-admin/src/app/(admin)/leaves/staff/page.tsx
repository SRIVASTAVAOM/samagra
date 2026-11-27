'use client';

import React, { useCallback, useEffect, useState } from 'react';
import {
  Calendar,
  CheckCircle2,
  Paperclip,
  RefreshCw,
  Search,
  XCircle,
} from 'lucide-react';
import { api } from '@/lib/api';
import { StaffLeaveRecordItem } from '@/lib/types';

function formatShortDate(raw: string): string {
  const trimmed = (raw || '').trim();
  if (!trimmed) return '';
  const datePart = trimmed.split(/[T ]/)[0];
  const parsed = new Date(`${datePart}T00:00:00`);
  if (Number.isNaN(parsed.getTime())) return datePart;
  return new Intl.DateTimeFormat('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  }).format(parsed);
}

function formatDateRange(startRaw: string, endRaw: string): string {
  const start = formatShortDate(startRaw);
  const end = formatShortDate(endRaw);
  if (!start && !end) return 'Date unavailable';
  if (!start) return end;
  if (!end || start === end) return start;
  return `${start} – ${end}`;
}

const STATUS_BADGE: Record<string, string> = {
  APPROVED: 'bg-emerald-50 text-emerald-700 border-emerald-200',
  RECOMMENDED: 'bg-blue-50 text-blue-700 border-blue-200',
  REJECTED: 'bg-rose-50 text-rose-700 border-rose-200',
  PENDING: 'bg-amber-50 text-amber-700 border-amber-200',
};

export default function TeacherLeavesPage() {
  const [leaves, setLeaves] = useState<StaffLeaveRecordItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [timeframeFilter, setTimeframeFilter] = useState<string>('all');
  const [search, setSearch] = useState('');

  const [decisionTarget, setDecisionTarget] = useState<{
    leave: StaffLeaveRecordItem;
    decision: 'APPROVED' | 'REJECTED';
  } | null>(null);
  const [decisionNote, setDecisionNote] = useState('');
  const [deciding, setDeciding] = useState(false);

  const loadQueue = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const data = await api.leaves.getStaffManagementQueue({
        status: statusFilter,
        timeframe: timeframeFilter,
        search,
      });
      setLeaves(Array.isArray(data) ? data : []);
    } catch (err: unknown) {
      setError(
        err instanceof Error
          ? err.message
          : 'Failed to load teacher leave applications'
      );
    } finally {
      setLoading(false);
    }
  }, [statusFilter, timeframeFilter, search]);

  useEffect(() => {
    let active = true;
    const handle = setTimeout(() => {
      if (active) {
        void loadQueue();
      }
    }, 0);
    return () => {
      active = false;
      clearTimeout(handle);
    };
  }, [loadQueue]);

  const handleConfirmDecision = async () => {
    if (!decisionTarget) return;
    if (
      decisionTarget.decision === 'REJECTED' &&
      decisionNote.trim().length < 3
    ) {
      return;
    }
    setDeciding(true);
    try {
      await api.leaves.decideStaffLeave(
        decisionTarget.leave.id,
        decisionTarget.decision,
        decisionNote.trim() || undefined
      );
      setDecisionTarget(null);
      setDecisionNote('');
      await loadQueue();
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : 'Failed to update leave decision'
      );
    } finally {
      setDeciding(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 bg-white p-5 rounded-xl border border-slate-200 shadow-xs">
        <div>
          <h2 className="text-lg font-bold text-slate-900">
            Teacher Leaves &amp; Approvals
          </h2>
          <p className="text-sm text-slate-500 mt-0.5">
            Review teacher leave applications and approve or reject with remarks.
          </p>
        </div>
        <button
          type="button"
          onClick={loadQueue}
          className="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-lg hover:bg-slate-50 cursor-pointer self-start sm:self-auto"
        >
          <RefreshCw className="w-4 h-4" />
          Refresh
        </button>
      </div>

      {/* Filters */}
      <div className="bg-white p-4 rounded-xl border border-slate-200 space-y-3">
        <div className="flex flex-col md:flex-row md:items-center gap-3">
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by teacher name, employee code, or reason..."
              className="w-full pl-9 pr-3 py-2 text-sm border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-slate-900/15"
            />
          </div>
          <div className="flex flex-wrap items-center gap-1.5">
            {(['ALL', 'PENDING', 'RECOMMENDED', 'APPROVED', 'REJECTED'] as const).map(
              (st) => (
                <button
                  key={st}
                  type="button"
                  onClick={() => setStatusFilter(st)}
                  className={`px-3 py-1.5 text-xs font-semibold rounded-full border cursor-pointer transition-colors ${
                    statusFilter === st
                      ? 'bg-slate-900 text-white border-slate-900'
                      : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50'
                  }`}
                >
                  {st === 'ALL' ? 'All Status' : st}
                </button>
              )
            )}
          </div>
          <div className="flex items-center gap-1.5">
            {[
              { id: 'all', label: 'All Time' },
              { id: 'this_week', label: 'This Week' },
              { id: 'this_month', label: 'This Month' },
            ].map((tf) => (
              <button
                key={tf.id}
                type="button"
                onClick={() => setTimeframeFilter(tf.id)}
                className={`px-3 py-1.5 text-xs font-semibold rounded-full border cursor-pointer transition-colors ${
                  timeframeFilter === tf.id
                    ? 'bg-slate-900 text-white border-slate-900'
                    : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50'
                }`}
              >
                {tf.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {error && (
        <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-sm">
          {error}
        </div>
      )}

      {loading ? (
        <div className="bg-white rounded-xl border border-slate-200 p-12 text-center text-sm text-slate-500">
          Loading teacher leave applications...
        </div>
      ) : leaves.length === 0 ? (
        <div className="bg-white rounded-xl border border-slate-200 p-12 text-center text-sm text-slate-500">
          No teacher leave applications match the current filters.
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {leaves.map((leave) => {
            const reviewer = (leave.sanctioned_by_identifier || '').trim();
            const remarks = (leave.management_comment || '').trim();
            const coordNote = (leave.coordinator_recommendation || '').trim();
            const coordName = (leave.recommended_by_name || '').trim();
            const isActionable =
              leave.status === 'PENDING' || leave.status === 'RECOMMENDED';

            return (
              <div
                key={leave.id}
                className="bg-white rounded-xl border border-slate-200 p-5 flex flex-col justify-between gap-3"
              >
                <div className="space-y-3">
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <h3 className="text-sm font-bold text-slate-900 truncate">
                        {leave.staff_name || 'Teacher'}
                      </h3>
                      {leave.employee_code && (
                        <p className="text-xs text-slate-500">
                          Code: {leave.employee_code}
                          {leave.wing_name ? ` • ${leave.wing_name}` : ''}
                        </p>
                      )}
                    </div>
                    <span
                      className={`shrink-0 px-2.5 py-0.5 text-[11px] font-semibold rounded border ${
                        STATUS_BADGE[leave.status] || STATUS_BADGE.PENDING
                      }`}
                    >
                      {leave.status}
                    </span>
                  </div>

                  <div className="flex items-center gap-2 text-xs font-semibold text-slate-800">
                    <Calendar className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                    <span>
                      {leave.leave_type} •{' '}
                      {formatDateRange(leave.start_date, leave.end_date)}
                    </span>
                  </div>

                  <p className="text-sm text-slate-800 font-medium leading-relaxed">
                    {leave.reason}
                  </p>

                  {leave.document_url && (
                    <a
                      href={leave.document_url}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md bg-blue-50 border border-blue-200 text-xs font-semibold text-blue-700 hover:bg-blue-100"
                    >
                      <Paperclip className="w-3.5 h-3.5" />
                      <span>
                        {leave.attachment_name?.trim() || 'View Attached Document'}
                      </span>
                    </a>
                  )}

                  {coordNote && (
                    <div className="p-2.5 rounded-lg bg-blue-50/70 border border-blue-200 text-xs text-blue-900">
                      Coordinator Note: &ldquo;{coordNote}&rdquo;
                      {coordName ? ` (${coordName})` : ''}
                    </div>
                  )}

                  {remarks && (
                    <p
                      className={`text-xs italic ${
                        leave.status === 'REJECTED'
                          ? 'text-rose-700'
                          : 'text-emerald-700'
                      }`}
                    >
                      Remarks: {remarks}
                    </p>
                  )}

                  {reviewer && (
                    <p className="text-xs text-slate-500">
                      Reviewed by {reviewer}
                    </p>
                  )}
                </div>

                {isActionable && (
                  <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => {
                        setDecisionNote('');
                        setDecisionTarget({ leave, decision: 'REJECTED' });
                      }}
                      className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-semibold text-rose-700 border border-rose-300 rounded-lg hover:bg-rose-50 cursor-pointer"
                    >
                      <XCircle className="w-3.5 h-3.5" />
                      Reject
                    </button>
                    <button
                      type="button"
                      onClick={() => {
                        setDecisionNote('');
                        setDecisionTarget({ leave, decision: 'APPROVED' });
                      }}
                      className="inline-flex items-center gap-1 px-3 py-1.5 text-xs font-semibold text-white bg-emerald-700 rounded-lg hover:bg-emerald-800 cursor-pointer"
                    >
                      <CheckCircle2 className="w-3.5 h-3.5" />
                      Approve
                    </button>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {decisionTarget && (
        <div className="fixed inset-0 z-50 bg-slate-900/50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl border border-slate-200 w-full max-w-md p-6 space-y-4">
            <h3
              className={`text-base font-bold ${
                decisionTarget.decision === 'APPROVED'
                  ? 'text-emerald-700'
                  : 'text-rose-700'
              }`}
            >
              {decisionTarget.decision === 'APPROVED'
                ? `Approve Leave: ${decisionTarget.leave.staff_name}`
                : `Reject Leave: ${decisionTarget.leave.staff_name}`}
            </h3>
            <p className="text-xs text-slate-600">
              {decisionTarget.leave.leave_type} •{' '}
              {formatDateRange(
                decisionTarget.leave.start_date,
                decisionTarget.leave.end_date
              )}
            </p>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                {decisionTarget.decision === 'REJECTED'
                  ? 'Rejection Reason (Required)'
                  : 'Remarks / Note (Optional)'}
              </label>
              <textarea
                value={decisionNote}
                onChange={(e) => setDecisionNote(e.target.value)}
                rows={3}
                placeholder={
                  decisionTarget.decision === 'REJECTED'
                    ? 'State reason for rejection...'
                    : 'Optional approval remarks...'
                }
                className="w-full px-3 py-2 text-sm border border-slate-300 rounded-lg"
              />
            </div>
            <div className="flex items-center justify-end gap-2">
              <button
                type="button"
                onClick={() => setDecisionTarget(null)}
                className="px-4 py-2 text-sm font-medium text-slate-600 cursor-pointer"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={
                  deciding ||
                  (decisionTarget.decision === 'REJECTED' &&
                    decisionNote.trim().length < 3)
                }
                onClick={handleConfirmDecision}
                className={`px-4 py-2 text-sm font-semibold text-white rounded-lg disabled:opacity-50 cursor-pointer ${
                  decisionTarget.decision === 'APPROVED'
                    ? 'bg-emerald-700 hover:bg-emerald-800'
                    : 'bg-rose-700 hover:bg-rose-800'
                }`}
              >
                {deciding
                  ? 'Saving...'
                  : decisionTarget.decision === 'APPROVED'
                  ? 'Confirm Approval'
                  : 'Confirm Rejection'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
