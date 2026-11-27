'use client';

import React, { useEffect, useState } from 'react';
import {
  Building2,
  Phone,
  Mail,
  MapPin,
  Clock,
  Save,
  RefreshCw,
  CheckCircle2,
  AlertCircle,
  ShieldCheck,
} from 'lucide-react';
import { api } from '@/lib/api';
import { useTenant } from '@/context/TenantContext';

export default function SchoolSettingsPage() {
  const { refreshTenant } = useTenant();
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const [schoolCode, setSchoolCode] = useState('');
  const [form, setForm] = useState({
    name: '',
    contactPhone: '',
    contactEmail: '',
    address: '',
    affiliation: '',
    officeHours: '',
  });

  const loadConfig = async () => {
    try {
      setLoading(true);
      setError(null);
      const data = await api.admin.getTenantConfig();
      const b = data?.branding || {};
      setSchoolCode(data?.code || '');
      setForm({
        name: data?.name || b.name || '',
        contactPhone: data?.contactPhone || b.phone || '',
        contactEmail: data?.contactEmail || b.email || '',
        address: data?.address || b.address || '',
        affiliation: b.affiliation || '',
        officeHours: b.officeHours || b.office_hours || '',
      });
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : 'Failed to load school contact details'
      );
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadConfig();
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setSaving(true);
      setError(null);
      setSuccess(null);

      await api.admin.updateTenantConfig({
        name: form.name.trim() || undefined,
        contactPhone: form.contactPhone.trim() || undefined,
        contactEmail: form.contactEmail.trim() || undefined,
        address: form.address.trim() || undefined,
        branding: {
          name: form.name.trim() || undefined,
          phone: form.contactPhone.trim() || undefined,
          email: form.contactEmail.trim() || undefined,
          address: form.address.trim() || undefined,
          affiliation: form.affiliation.trim(),
          officeHours: form.officeHours.trim(),
        },
      });

      await refreshTenant();
      setSuccess('School contact & institutional details saved and synced to Mobile App!');
    } catch (err: unknown) {
      setError(
        err instanceof Error ? err.message : 'Failed to save school contact settings'
      );
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6 max-w-4xl">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 samagra-hero p-6 rounded-2xl text-white shadow-xl border border-indigo-500/20">
        <div>
          <div className="flex items-center gap-2 mb-2">
            <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-500/30 text-indigo-200 border border-indigo-400/30 flex items-center gap-1.5">
              <ShieldCheck className="w-3.5 h-3.5" />
              Tenant Identity{schoolCode ? ` • ${schoolCode}` : ''}
            </span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2.5">
            <Building2 className="w-7 h-7 text-indigo-300" />
            School Contact &amp; Settings
          </h1>
          <p className="text-sm text-slate-300 mt-1 max-w-2xl">
            Manage official helpline phone, contact email, campus address, and office hours displayed in the Student Mobile App.
          </p>
        </div>

        <button
          type="button"
          onClick={loadConfig}
          disabled={loading}
          className="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-white/10 hover:bg-white/20 border border-white/15 text-white text-xs font-semibold transition cursor-pointer disabled:opacity-50"
        >
          <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`} />
          <span>Refresh</span>
        </button>
      </div>

      {error && (
        <div className="p-4 bg-rose-50 border border-rose-200 rounded-xl flex items-center gap-3 text-rose-800 text-sm">
          <AlertCircle className="w-5 h-5 text-rose-600 shrink-0" />
          <span>{error}</span>
        </div>
      )}

      {success && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl flex items-center gap-3 text-emerald-800 text-sm">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          <span className="font-medium">{success}</span>
        </div>
      )}

      {loading ? (
        <div className="p-12 bg-white rounded-2xl border border-slate-200 text-center text-slate-500 text-sm">
          Loading school contact configuration...
        </div>
      ) : (
        <form
          onSubmit={handleSave}
          className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 space-y-5"
        >
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="md:col-span-2 space-y-1.5">
              <label className="text-xs font-semibold text-slate-700 flex items-center gap-1.5">
                <Building2 className="w-3.5 h-3.5 text-indigo-600" />
                <span>Official School Name</span>
              </label>
              <input
                type="text"
                required
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="Enter school name"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm font-medium focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-700 flex items-center gap-1.5">
                <Phone className="w-3.5 h-3.5 text-indigo-600" />
                <span>Reception / Helpline Phone</span>
              </label>
              <input
                type="tel"
                value={form.contactPhone}
                onChange={(e) => setForm({ ...form, contactPhone: e.target.value })}
                placeholder="e.g. +91 9876543210"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm font-mono focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-700 flex items-center gap-1.5">
                <Mail className="w-3.5 h-3.5 text-indigo-600" />
                <span>Official Inquiries Email</span>
              </label>
              <input
                type="email"
                value={form.contactEmail}
                onChange={(e) => setForm({ ...form, contactEmail: e.target.value })}
                placeholder="e.g. info@school.edu"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div className="md:col-span-2 space-y-1.5">
              <label className="text-xs font-semibold text-slate-700 flex items-center gap-1.5">
                <MapPin className="w-3.5 h-3.5 text-indigo-600" />
                <span>Campus Physical Address</span>
              </label>
              <input
                type="text"
                value={form.address}
                onChange={(e) => setForm({ ...form, address: e.target.value })}
                placeholder="Street, Locality, City, PIN"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-700">
                Affiliation / Board Tagline
              </label>
              <input
                type="text"
                value={form.affiliation}
                onChange={(e) => setForm({ ...form, affiliation: e.target.value })}
                placeholder="e.g. Affiliated to CBSE, New Delhi"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>

            <div className="space-y-1.5">
              <label className="text-xs font-semibold text-slate-700 flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-indigo-600" />
                <span>Office Working Hours</span>
              </label>
              <input
                type="text"
                value={form.officeHours}
                onChange={(e) => setForm({ ...form, officeHours: e.target.value })}
                placeholder="e.g. Mon–Fri 8:00 AM – 3:30 PM, Sat 8:00 AM – 1:00 PM"
                className="w-full px-3.5 py-2.5 rounded-xl border border-slate-300 text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
              />
            </div>
          </div>

          <div className="pt-4 border-t border-slate-100 flex justify-end">
            <button
              type="submit"
              disabled={saving}
              className="inline-flex items-center gap-2 px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 disabled:opacity-50 text-white text-sm font-semibold shadow-sm transition cursor-pointer"
            >
              <Save className="w-4 h-4" />
              <span>{saving ? 'Saving...' : 'Save School Contact'}</span>
            </button>
          </div>
        </form>
      )}
    </div>
  );
}
