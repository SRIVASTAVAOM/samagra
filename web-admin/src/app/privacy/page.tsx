import React from 'react';
import Link from 'next/link';
import { ShieldCheck, Lock, Eye, Mail, ArrowLeft, School } from 'lucide-react';

export const metadata = {
  title: 'Privacy Policy | SAMAGRA School ERP',
  description: 'Official Privacy Policy for SAMAGRA ERP Mobile & Web Platforms',
};

export default function PrivacyPolicyPage() {
  return (
    <div className="min-h-screen bg-slate-50 text-slate-900 font-sans">
      {/* Header */}
      <header className="bg-white border-b border-slate-200 sticky top-0 z-20">
        <div className="max-w-4xl mx-auto px-4 py-4 flex items-center justify-between">
          <div className="flex items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-[#0f1d3a] flex items-center justify-center text-white font-bold text-sm shadow-sm">
              S
            </div>
            <div>
              <span className="font-extrabold text-base tracking-tight text-[#0f1d3a]">SAMAGRA</span>
              <span className="text-xs text-slate-500 block -mt-1 font-medium">School ERP Platform</span>
            </div>
          </div>
          <Link
            href="/login"
            className="inline-flex items-center gap-1.5 text-xs font-semibold text-slate-600 hover:text-slate-900 px-3 py-1.5 rounded-lg border border-slate-200 bg-white shadow-xs"
          >
            <ArrowLeft className="w-3.5 h-3.5" />
            <span>Back to Portal</span>
          </Link>
        </div>
      </header>

      {/* Main Content */}
      <main className="max-w-4xl mx-auto px-4 py-10 space-y-8">
        {/* Banner */}
        <div className="samagra-hero rounded-2xl p-6 sm:p-8 text-white space-y-2">
          <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-white/10 text-xs font-semibold text-amber-300">
            <ShieldCheck className="w-3.5 h-3.5" />
            <span>Compliance & Trust</span>
          </div>
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Privacy Policy</h1>
          <p className="text-xs text-white/80">Last Updated: November 20, 2026 • Effective Date: November 20, 2026</p>
        </div>

        {/* Policy Body */}
        <div className="bg-white rounded-2xl p-6 sm:p-8 border border-slate-200 shadow-xs space-y-6 text-sm leading-relaxed text-slate-700">
          <section className="space-y-2">
            <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
              <School className="w-4 h-4 text-indigo-600" />
              1. Introduction
            </h2>
            <p>
              SAMAGRA School ERP (&ldquo;SAMAGRA&rdquo;, &ldquo;we&rdquo;, &ldquo;us&rdquo;, or &ldquo;our&rdquo;) provides comprehensive school administration and academic management software for educational institutions, teachers, parents, and students. This Privacy Policy applies to our Mobile Applications and Web Admin portal.
            </p>
          </section>

          <section className="space-y-2">
            <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
              <Lock className="w-4 h-4 text-emerald-600" />
              2. Information We Collect
            </h2>
            <p>We collect information necessary to deliver educational and administrative services:</p>
            <ul className="list-disc list-inside space-y-1.5 pl-2 text-slate-600">
              <li><strong>Student & Guardian Information:</strong> Student Name, Roll Number, Class, Section, Guardian Contact, Admission Records.</li>
              <li><strong>Academic & Attendance Records:</strong> Daily attendance marks, grades, report cards, homework submissions, syllabus progress.</li>
              <li><strong>Fee Management & Receipts:</strong> Fee dues, payment receipt numbers, transaction logs (handled securely through compliant bank/payment channels; no raw card details are stored).</li>
              <li><strong>Device & Media Permissions:</strong> Camera & Storage access (strictly used when users capture homework, profile photos, or study documents).</li>
            </ul>
          </section>

          <section className="space-y-2">
            <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
              <Eye className="w-4 h-4 text-amber-600" />
              3. How We Use Information
            </h2>
            <p>
              Your data is solely used to facilitate school operations:
            </p>
            <ul className="list-disc list-inside space-y-1.5 pl-2 text-slate-600">
              <li>Enabling parents and students to view attendance, timetables, fee receipts, and homework.</li>
              <li>Sending essential academic notifications and school notices.</li>
              <li>Multi-tenant institutional segregation, ensuring each school&apos;s data is isolated and encrypted.</li>
              <li><strong>We NEVER sell, rent, or trade student or school personal data to third parties or advertisers.</strong></li>
            </ul>
          </section>

          <section className="space-y-2">
            <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
              <ShieldCheck className="w-4 h-4 text-blue-600" />
              4. Data Security & Storage
            </h2>
            <p>
              Data transmission is protected via industry-standard SSL/TLS (HTTPS) encryption. Database storage utilizes authenticated PostgreSQL instances with strict role-based access control (RBAC).
            </p>
          </section>

          <section className="space-y-2">
            <h2 className="text-lg font-bold text-slate-900 flex items-center gap-2">
              <Mail className="w-4 h-4 text-indigo-600" />
              5. Contact Us & Grievance Officer
            </h2>
            <p>
              If you have any questions or data deletion requests, please contact our administrative desk:
            </p>
            <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 text-xs space-y-1">
              <p><strong>Platform:</strong> SAMAGRA School ERP</p>
              <p><strong>Support Email:</strong> privacy@samagraerp.com / support@samagraerp.com</p>
              <p><strong>Entity:</strong> SAMAGRA Educational Technologies</p>
            </div>
          </section>
        </div>
      </main>
    </div>
  );
}
