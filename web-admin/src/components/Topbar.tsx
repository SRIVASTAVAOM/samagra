'use client';

import React from 'react';
import { usePathname } from 'next/navigation';
import Image from 'next/image';
import { Calendar, Menu, School, AlertCircle, GitBranch } from 'lucide-react';
import { useTenant } from '@/context/TenantContext';

const titleMap: Record<string, { title: string; subtitle: string }> = {
  '/dashboard': {
    title: 'Command Center Dashboard',
    subtitle: 'Real-time section attendance pills, homework feeds, and school KPIs',
  },
  '/timetable': {
    title: 'Master Timetable Builder',
    subtitle: 'Day-wise (Mon–Sat) x period-wise (P1–P8) interactive grid matrix',
  },
  '/academics/study-material': {
    title: 'Study Material & Academic Repository',
    subtitle: 'Upload, manage, and share syllabus, notes, and study resources with students & teachers',
  },
  '/academics/uploads': {
    title: 'Study Material & Academic Repository',
    subtitle: 'Upload, manage, and share syllabus, notes, and study resources with students & teachers',
  },
  '/reports/greensheet': {
    title: 'Master Greensheet Report Cards & Marks',
    subtitle: 'Official class tabulation marksheet, subject percentiles, and rank roster',
  },
  '/homework': {
    title: 'View/Assign Homework',
    subtitle: 'Upload, assign, and edit homework for any class and section',
  },
  '/subjects': {
    title: 'Subject Master',
    subtitle: 'Manage curriculum subjects, class affiliations, and faculty allocations',
  },
};

type TopbarProps = {
  /** Opens the sidebar drawer on screens below md. */
  onMenuClick?: () => void;
};

export function Topbar({ onMenuClick }: TopbarProps) {
  const pathname = usePathname();
  const { branding } = useTenant();
  const current = titleMap[pathname] || {
    title: 'Administration Portal',
    subtitle: 'Integrated Management System',
  };

  const todayStr = new Intl.DateTimeFormat('en-IN', {
    weekday: 'short',
    day: 'numeric',
    month: 'short',
    year: 'numeric',
  }).format(new Date());

  return (
    <header className="no-print h-16 bg-white border-b border-slate-200 px-4 md:px-6 flex items-center gap-3 shrink-0">
      <button
        type="button"
        onClick={onMenuClick}
        aria-label="Open navigation menu"
        className="md:hidden p-2 -ml-1 rounded-md text-slate-600 hover:bg-slate-100 transition-colors cursor-pointer shrink-0"
      >
        <Menu className="w-5 h-5" />
      </button>

      <div className="min-w-0 flex-1 flex items-center gap-4">
        <div>
          <h1 className="text-sm font-semibold text-slate-900 tracking-tight truncate">
            {current.title}
          </h1>
          <p className="text-xs text-slate-500 font-normal truncate">{current.subtitle}</p>
        </div>
      </div>

      <div className="hidden lg:flex items-center gap-2.5 text-xs shrink-0">
        {/* Date Display */}
        <div className="flex items-center gap-1.5 px-2.5 py-1.5 rounded-full bg-slate-50 border border-slate-200 text-slate-700 font-medium">
          <Calendar className="w-3.5 h-3.5 text-slate-400" />
          <span>{todayStr}</span>
        </div>

        {/* Dynamic School Badge */}
        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-emerald-50 border border-emerald-200/80 text-emerald-900 font-bold truncate max-w-[220px]">
          <School className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
          <span className="truncate">{branding.name}</span>
        </div>

        {/* SAMAGRA SaaS Powered Badge */}
        <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-slate-900 text-white font-semibold shadow-xs">
          <Image
            src="/logo-icon.png"
            alt="SAMAGRA"
            width={14}
            height={14}
            className="rounded-full"
          />
          <span className="tracking-tight text-[11px]">SAMAGRA ERP</span>
        </div>

        {/* Raise Complain Button (From reference image) */}
        <button
          type="button"
          onClick={() => alert('Support ticket & grievance window will open')}
          className="flex items-center gap-1.5 px-3 py-1.5 rounded-full bg-[#023E8A] hover:bg-[#001938] text-white font-bold text-xs transition cursor-pointer shadow-xs"
        >
          <AlertCircle className="w-3.5 h-3.5" />
          <span>Raise Complain</span>
        </button>

        {/* Switch Branch Dropdown */}
        <div className="flex items-center gap-1 px-2.5 py-1.5 rounded-full border border-slate-200 bg-white text-slate-700 text-xs font-semibold">
          <GitBranch className="w-3 h-3 text-rose-500" />
          <span className="text-[11px] text-slate-500">Branch:</span>
          <select className="bg-transparent border-none outline-none cursor-pointer text-slate-900 font-bold text-xs pr-1">
            <option value="main">Main Campus</option>
            <option value="city">City Wing</option>
          </select>
        </div>
      </div>
    </header>
  );
}
