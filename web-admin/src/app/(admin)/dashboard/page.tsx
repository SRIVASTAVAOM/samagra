'use client';

import React, { useEffect, useState, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import {
  Users,
  GraduationCap,
  LayoutGrid,
  CheckCircle,
  Image as ImageIcon,
  IndianRupee,
  Search,
  Check,
  AlertCircle,
  Calendar,
  Bus,
  HeartHandshake,
  FileText,
  ChevronRight,
  ArrowUpRight,
  Banknote,
  CreditCard,
  Smartphone,
  Landmark,
  Clock,
  RefreshCw,
  X,
  ShieldCheck,
  BookOpen,
  CalendarDays,
  UserCheck,
  UserX,
  AlertTriangle,
  Layers,
  ChevronDown,
  Phone,
  Mail,
  User,
  Briefcase,
  ArrowRight,
  Eye,
  Receipt,
} from 'lucide-react';
import { api } from '@/lib/api';
import { DashboardSummaryResponse, SectionSummary, PendingLeaveSummary } from '@/lib/types';
import { DonutChart, DonutSlice, CHART_COLORS } from '@/components/dashboard/DashboardCharts';

// Local YYYY-MM-DD (toISOString would give yesterday in IST before 05:30).
const todayISO = () => {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
};

export default function DashboardPage() {
  const router = useRouter();

  // Primary data state
  const [data, setData] = useState<DashboardSummaryResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Fee filter states
  const [selectedClass, setSelectedClass] = useState<string>('ALL');
  const [selectedSection, setSelectedSection] = useState<string>('ALL');
  const [selectedMonth, setSelectedMonth] = useState<string>('CURRENT');
  const [selectedDate, setSelectedDate] = useState<string>(todayISO);
  const [activeFeeView, setActiveFeeView] = useState<'TODAY' | 'MONTHLY' | 'MATRIX'>('TODAY');

  // Attendance inspection modal
  const [attendanceModalOpen, setAttendanceModalOpen] = useState(false);
  const [attendanceModalTab, setAttendanceModalTab] = useState<'PRESENT' | 'ABSENT'>('PRESENT');
  const [attendanceSearch, setAttendanceSearch] = useState('');

  // Expand compliance grid toggle
  const [showComplianceGrid, setShowComplianceGrid] = useState(false);

  // Institutional 360 Inspector States
  const [inspectorTab, setInspectorTab] = useState<'STUDENT' | 'TEACHER'>('STUDENT');
  const [inspectorClassId, setInspectorClassId] = useState<string>('ALL');
  const [inspectorSectionId, setInspectorSectionId] = useState<string>('ALL');
  const [inspectorSearchQuery, setInspectorSearchQuery] = useState<string>('');

  const [studentsList, setStudentsList] = useState<any[]>([]);
  const [selectedStudentId, setSelectedStudentId] = useState<string | null>(null);
  const [studentInspection, setStudentInspection] = useState<any | null>(null);
  const [loadingStudentInspect, setLoadingStudentInspect] = useState<boolean>(false);

  const [teachersList, setTeachersList] = useState<any[]>([]);
  const [selectedTeacherId, setSelectedTeacherId] = useState<string | null>(null);
  const [teacherInspection, setTeacherInspection] = useState<any | null>(null);
  const [loadingTeacherInspect, setLoadingTeacherInspect] = useState<boolean>(false);

  // Fetch students for inspector
  const fetchInspectorStudents = async () => {
    try {
      const res = await api.admin.getStudents({
        class_id: inspectorClassId === 'ALL' ? undefined : inspectorClassId,
        section_id: inspectorSectionId === 'ALL' ? undefined : inspectorSectionId,
        search: inspectorSearchQuery.trim() || undefined,
      });
      const list = Array.isArray(res) ? res : [];
      setStudentsList(list);
      if (list.length > 0) {
        if (!selectedStudentId || !list.some((s: any) => s.id === selectedStudentId)) {
          setSelectedStudentId(list[0].id);
          loadStudentInspection(list[0].id);
        }
      } else {
        setSelectedStudentId(null);
        setStudentInspection(null);
      }
    } catch (e) {
      console.error('Error fetching students for inspector:', e);
    }
  };

  // Load individual student inspection
  const loadStudentInspection = async (studentId: string) => {
    try {
      setLoadingStudentInspect(true);
      const res = await api.admin.getStudentInspection(studentId);
      setStudentInspection(res);
    } catch (e) {
      console.error('Error loading student inspection:', e);
      setStudentInspection(null);
    } finally {
      setLoadingStudentInspect(false);
    }
  };

  // Fetch teachers for inspector
  const fetchInspectorTeachers = async () => {
    try {
      const res = await api.admin.getAllStaff(undefined, true);
      const list = Array.isArray(res) ? res : [];
      setTeachersList(list);
      if (list.length > 0) {
        if (!selectedTeacherId || !list.some((t: any) => t.id === selectedTeacherId)) {
          setSelectedTeacherId(list[0].id);
          loadTeacherInspection(list[0].id);
        }
      }
    } catch (e) {
      console.error('Error fetching teachers for inspector:', e);
    }
  };

  // Load individual teacher inspection
  const loadTeacherInspection = async (teacherId: string) => {
    try {
      setLoadingTeacherInspect(true);
      const res = await api.admin.getTeacherInspection(teacherId);
      setTeacherInspection(res);
    } catch (e) {
      console.error('Error loading teacher inspection:', e);
      setTeacherInspection(null);
    } finally {
      setLoadingTeacherInspect(false);
    }
  };

  useEffect(() => {
    fetchInspectorStudents();
  }, [inspectorClassId, inspectorSectionId, inspectorSearchQuery]);

  useEffect(() => {
    fetchInspectorTeachers();
  }, []);

  const handleInspectStudentFromModal = (studentId: string) => {
    setAttendanceModalOpen(false);
    setInspectorTab('STUDENT');
    setSelectedStudentId(studentId);
    loadStudentInspection(studentId);
    setTimeout(() => {
      const elem = document.getElementById('institutional-inspector');
      if (elem) elem.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };

  const handleInspectTeacherDirect = (teacherId?: string) => {
    setInspectorTab('TEACHER');
    if (teacherId) {
      setSelectedTeacherId(teacherId);
      loadTeacherInspection(teacherId);
    }
    setTimeout(() => {
      const elem = document.getElementById('institutional-inspector');
      if (elem) elem.scrollIntoView({ behavior: 'smooth' });
    }, 100);
  };

  // Fetch live dashboard summary
  const fetchSummary = async (dateParam?: string) => {
    try {
      setLoading(true);
      setError(null);
      const queryDate = typeof dateParam === 'string' ? dateParam : selectedDate;
      const res = await api.admin.getDashboardSummary({
        date: queryDate,
        classId: selectedClass,
        sectionId: selectedSection,
        month: selectedMonth,
      });
      setData(res);
      if (res.date) {
        setSelectedDate(res.date);
      }
    } catch (err: any) {
      setError(err?.message || 'Failed to load institutional dashboard data.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchSummary();
  }, []);

  // Formatted date string
  const formattedToday = useMemo(() => {
    if (!data?.date) return selectedDate.split('-').reverse().join('-');
    const [y, m, d] = data.date.split('-');
    return `${d}-${m}-${y}`;
  }, [data?.date, selectedDate]);

  // Distinct classes and sections from data for each and every class
  const distinctClasses = useMemo(() => {
    if (!data?.sections) return [];
    const map = new Map<string, string>();
    data.sections.forEach((s) => map.set(s.class_id, s.class_name));
    return Array.from(map.entries()).map(([id, name]) => ({ id, name }));
  }, [data?.sections]);

  const distinctSections = useMemo(() => {
    if (!data?.sections) return [];
    if (selectedClass === 'ALL') {
      const map = new Map<string, string>();
      data.sections.forEach((s) => map.set(s.section_id, s.section_name));
      return Array.from(map.entries()).map(([id, name]) => ({ id, name }));
    }
    return data.sections
      .filter((s) => s.class_id === selectedClass)
      .map((s) => ({ id: s.section_id, name: s.section_name }));
  }, [data?.sections, selectedClass]);

  // Distinct sections for Institutional Inspector
  const inspectorDistinctSections = useMemo(() => {
    if (!data?.sections) return [];
    if (inspectorClassId === 'ALL') {
      const map = new Map<string, string>();
      data.sections.forEach((s) => map.set(s.section_id, s.section_name));
      return Array.from(map.entries()).map(([id, name]) => ({ id, name }));
    }
    return data.sections
      .filter((s) => s.class_id === inspectorClassId)
      .map((s) => ({ id: s.section_id, name: s.section_name }));
  }, [data?.sections, inspectorClassId]);

  // Total Students count
  const totalStudents = useMemo(() => {
    if (!data?.sections) return 0;
    return data.sections.reduce((acc, s) => acc + (s.total_students || 0), 0);
  }, [data?.sections]);

  const totalPresentToday = useMemo(() => {
    if (!data?.today_student_attendance) {
      return (data?.sections || []).reduce((acc, s) => acc + (s.present_count || 0), 0);
    }
    return data.today_student_attendance.filter((s) => s.status === 'PRESENT').length;
  }, [data]);

  const totalAbsentToday = useMemo(() => {
    if (!data?.today_student_attendance) {
      return data?.kpis?.total_absent_students ?? 0;
    }
    return data.today_student_attendance.filter((s) => s.status === 'ABSENT').length;
  }, [data]);

  // Real Day-wise collection from database
  const dailyCollection = useMemo(() => {
    return {
      date: data?.daily_collection?.date || selectedDate,
      totalReceived: data?.daily_collection?.total_received ?? 0,
      totalCreated: data?.daily_collection?.total_created ?? 0,
      receivedCount: data?.daily_collection?.received_count ?? 0,
      createdCount: data?.daily_collection?.created_count ?? 0,
      byMode: data?.daily_collection?.by_mode ?? {
        cash: { amount: 0, count: 0 },
        online: { amount: 0, count: 0 },
        cheque: { amount: 0, count: 0 },
        upi: { amount: 0, count: 0 },
      },
    };
  }, [data?.daily_collection, selectedDate]);

  // Real Monthly collection from database
  const monthlyCollection = useMemo(() => {
    return {
      month: data?.monthly_collection?.month || 'This month',
      totalReceived: data?.monthly_collection?.total_received ?? 0,
      totalCreated: data?.monthly_collection?.total_created ?? 0,
      receivedCount: data?.monthly_collection?.received_count ?? 0,
      createdCount: data?.monthly_collection?.created_count ?? 0,
      byMode: data?.monthly_collection?.by_mode ?? {
        cash: { amount: 0, count: 0 },
        online: { amount: 0, count: 0 },
        cheque: { amount: 0, count: 0 },
        upi: { amount: 0, count: 0 },
      },
    };
  }, [data?.monthly_collection]);

  // Active mode breakdown based on tab
  const activeModeBreakdown = useMemo(() => {
    return activeFeeView === 'TODAY' ? dailyCollection.byMode : monthlyCollection.byMode;
  }, [activeFeeView, dailyCollection.byMode, monthlyCollection.byMode]);

  // Fee overview metrics from database
  const feeMetrics = useMemo(() => {
    const baseTotal = data?.fee_overview?.total_fee ?? 0;
    const basePaid = data?.fee_overview?.paid_fee ?? 0;
    const baseDue = data?.fee_overview?.due_fee ?? 0;
    const paidPct = data?.fee_overview?.paid_percentage ?? (baseTotal > 0 ? Math.round((basePaid / baseTotal) * 100) : 0);
    const duePct = data?.fee_overview?.due_percentage ?? (baseTotal > 0 ? 100 - paidPct : 0);

    return {
      totalStudents: data?.fee_overview?.total_students || totalStudents,
      totalFee: baseTotal,
      paidFee: basePaid,
      dueFee: baseDue,
      paidPercentage: paidPct,
      duePercentage: duePct,
    };
  }, [data?.fee_overview, totalStudents]);

  // Real academic 12-month matrix from database
  const monthlyMatrix = useMemo(() => {
    return data?.monthly_matrix || [];
  }, [data?.monthly_matrix]);

  // Recent Activities
  const recentActivities = useMemo(() => {
    return data?.recent_activities ?? [];
  }, [data?.recent_activities]);

  // Modal attendance lists
  const modalPresentList = useMemo(() => {
    return (data?.today_student_attendance || []).filter((s) => s.status === 'PRESENT');
  }, [data]);

  const modalAbsentList = useMemo(() => {
    return (data?.today_student_attendance || []).filter((s) => s.status === 'ABSENT');
  }, [data]);

  const activeModalList = attendanceModalTab === 'PRESENT' ? modalPresentList : modalAbsentList;

  const filteredModalList = useMemo(() => {
    if (!attendanceSearch.trim()) return activeModalList;
    const q = attendanceSearch.toLowerCase();
    return activeModalList.filter((s) =>
      `${s.student_name} ${s.roll_number || ''} ${s.admission_number || ''} ${s.class_name || ''} ${s.section_name || ''}`
        .toLowerCase()
        .includes(q)
    );
  }, [activeModalList, attendanceSearch]);

  useEffect(() => {
    if (!attendanceModalOpen) return;
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && setAttendanceModalOpen(false);
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [attendanceModalOpen]);

  const handleOpenAttendanceModal = (tab: 'PRESENT' | 'ABSENT') => {
    setAttendanceModalTab(tab);
    setAttendanceModalOpen(true);
  };

  return (
    <div className="space-y-5 sm:space-y-6">
      {/* Top Banner Alert (If Any) */}
      {error && (
        <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl flex items-center justify-between text-rose-800 text-xs">
          <div className="flex flex-wrap items-center gap-2">
            <AlertTriangle className="w-4 h-4 text-rose-600 shrink-0" />
            <span>{error}</span>
          </div>
          <button onClick={() => fetchSummary()} className="underline font-semibold hover:text-rose-950">
            Retry
          </button>
        </div>
      )}

      {/* ========================================================================= */}
      {/* 1. TOP MASTER SHORTCUT CARDS (Student, Teacher, Class, Section, Photo)     */}
      {/* ========================================================================= */}
      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3.5">
        {/* Student Card */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/70 shadow-2xs hover:shadow-lg hover:shadow-indigo-900/5 hover:-translate-y-0.5 hover:border-indigo-200 transition-all duration-200 group">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white group-hover:ring-indigo-600 transition-colors duration-200">
                <Users className="w-5 h-5" />
              </div>
              <div>
                <p className="font-semibold text-slate-900 text-sm tracking-tight">Student</p>
                <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 mt-0.5">
                  <button
                    onClick={() => router.push('/students')}
                    className="hover:text-indigo-600 transition-colors"
                  >
                    Add / View
                  </button>
                </div>
              </div>
            </div>
            <button
              onClick={() => router.push('/students')}
              className="p-1 rounded-full text-slate-300 group-hover:text-indigo-600 group-hover:bg-indigo-50 group-hover:translate-x-0.5 transition-all duration-200"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Teacher Card */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/70 shadow-2xs hover:shadow-lg hover:shadow-indigo-900/5 hover:-translate-y-0.5 hover:border-indigo-200 transition-all duration-200 group">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white group-hover:ring-indigo-600 transition-colors duration-200">
                <GraduationCap className="w-5 h-5" />
              </div>
              <div>
                <p className="font-semibold text-slate-900 text-sm tracking-tight">Teacher</p>
                <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 mt-0.5">
                  <button
                    onClick={() => router.push('/staff')}
                    className="hover:text-indigo-600 transition-colors"
                  >
                    Add / View
                  </button>
                </div>
              </div>
            </div>
            <button
              onClick={() => router.push('/staff')}
              className="p-1 rounded-full text-slate-300 group-hover:text-indigo-600 group-hover:bg-indigo-50 group-hover:translate-x-0.5 transition-all duration-200"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Class Card */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/70 shadow-2xs hover:shadow-lg hover:shadow-indigo-900/5 hover:-translate-y-0.5 hover:border-indigo-200 transition-all duration-200 group">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white group-hover:ring-indigo-600 transition-colors duration-200">
                <LayoutGrid className="w-5 h-5" />
              </div>
              <div>
                <p className="font-semibold text-slate-900 text-sm tracking-tight">Class</p>
                <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 mt-0.5">
                  <button
                    onClick={() => router.push('/academics/subjects')}
                    className="hover:text-indigo-600 transition-colors"
                  >
                    Add / View
                  </button>
                </div>
              </div>
            </div>
            <button
              onClick={() => router.push('/academics/subjects')}
              className="p-1 rounded-full text-slate-300 group-hover:text-indigo-600 group-hover:bg-indigo-50 group-hover:translate-x-0.5 transition-all duration-200"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Section Card */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/70 shadow-2xs hover:shadow-lg hover:shadow-indigo-900/5 hover:-translate-y-0.5 hover:border-indigo-200 transition-all duration-200 group">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white group-hover:ring-indigo-600 transition-colors duration-200">
                <CheckCircle className="w-5 h-5" />
              </div>
              <div>
                <p className="font-semibold text-slate-900 text-sm tracking-tight">Section</p>
                <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 mt-0.5">
                  <button
                    onClick={() => router.push('/timetable')}
                    className="hover:text-indigo-600 transition-colors"
                  >
                    Add / View
                  </button>
                </div>
              </div>
            </div>
            <button
              onClick={() => router.push('/timetable')}
              className="p-1 rounded-full text-slate-300 group-hover:text-indigo-600 group-hover:bg-indigo-50 group-hover:translate-x-0.5 transition-all duration-200"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* Photo / Study Material Card */}
        <div className="bg-white p-4 rounded-2xl border border-slate-200/70 shadow-2xs hover:shadow-lg hover:shadow-indigo-900/5 hover:-translate-y-0.5 hover:border-indigo-200 transition-all duration-200 group">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white group-hover:ring-indigo-600 transition-colors duration-200">
                <ImageIcon className="w-5 h-5" />
              </div>
              <div>
                <p className="font-semibold text-slate-900 text-sm tracking-tight">Photo</p>
                <div className="flex items-center gap-1.5 text-xs font-medium text-slate-500 mt-0.5">
                  <button
                    onClick={() => router.push('/academics/study-material')}
                    className="hover:text-indigo-600 transition-colors"
                  >
                    Upload / View
                  </button>
                </div>
              </div>
            </div>
            <button
              onClick={() => router.push('/academics/study-material')}
              className="p-1 rounded-full text-slate-300 group-hover:text-indigo-600 group-hover:bg-indigo-50 group-hover:translate-x-0.5 transition-all duration-200"
            >
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 2. MIDDLE SECTION: FEE COLLECTION & INSTITUTIONAL FINANCIAL LEDGER          */}
      {/* ========================================================================= */}
      <div className="bg-white rounded-2xl border border-slate-200/70 shadow-sm p-4 sm:p-6 space-y-5">
        {/* Header Strip: Title, Live Database Sync Badge & Mode Navigation */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-100">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100 flex items-center justify-center shrink-0">
              <IndianRupee className="w-5 h-5" />
            </div>
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="font-semibold text-slate-900 text-base tracking-tight">
                  Fee collection
                </h3>
              </div>
              <p className="text-xs text-slate-500 font-medium mt-0.5">
                Today, this month and month-wise dues
              </p>
            </div>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {/* View Mode Toggle: Day-wise vs Month Matrix vs Monthly */}
            <div className="inline-flex max-w-full overflow-x-auto p-1 bg-slate-100/80 rounded-xl border border-slate-200/70 text-xs">
              <button
                type="button"
                onClick={() => setActiveFeeView('TODAY')}
                className={`px-3 py-1.5 rounded-lg font-semibold whitespace-nowrap transition-all duration-200 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 ${
                  activeFeeView === 'TODAY'
                    ? 'bg-white text-indigo-700 shadow-sm ring-1 ring-slate-200/80'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                Today ({formattedToday})
              </button>
              <button
                type="button"
                onClick={() => setActiveFeeView('MATRIX')}
                className={`px-3 py-1.5 rounded-lg font-semibold whitespace-nowrap transition-all duration-200 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 ${
                  activeFeeView === 'MATRIX'
                    ? 'bg-white text-indigo-700 shadow-sm ring-1 ring-slate-200/80'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                Session (12 months)
              </button>
              <button
                type="button"
                onClick={() => setActiveFeeView('MONTHLY')}
                className={`px-3 py-1.5 rounded-lg font-semibold whitespace-nowrap transition-all duration-200 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 ${
                  activeFeeView === 'MONTHLY'
                    ? 'bg-white text-indigo-700 shadow-sm ring-1 ring-slate-200/80'
                    : 'text-slate-600 hover:text-slate-900'
                }`}
              >
                This Month ({monthlyCollection.month.split(' ')[0]})
              </button>
            </div>


            {/* Refresh Live Button */}
            <button
              onClick={() => fetchSummary()}
              disabled={loading}
              title="Refresh Live Data"
              className="p-2 text-slate-500 hover:text-indigo-600 bg-white hover:bg-indigo-50 border border-slate-200 hover:border-indigo-200 rounded-xl shadow-2xs transition-all duration-200 disabled:opacity-50 cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin text-indigo-600' : ''}`} />
            </button>
          </div>
        </div>

        {/* 4 HIGH-IMPACT FINANCIAL CARDS */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3.5">
          {/* Card 1: Today's Collection (Day-wise) */}
          <div className="bg-white p-4 sm:p-5 rounded-2xl border border-slate-200/70 shadow-2xs hover:shadow-md hover:shadow-slate-900/5 transition-shadow duration-200 flex flex-col justify-between space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-slate-500 flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                Today's collection
              </span>
              <span className="text-[10px] font-semibold px-2 py-0.5 bg-emerald-50 text-emerald-700 ring-1 ring-emerald-200/70 rounded-full">
                {dailyCollection.receivedCount} receipt{dailyCollection.receivedCount === 1 ? '' : 's'}
              </span>
            </div>
            <div>
              <p className="text-2xl sm:text-[1.65rem] font-bold leading-tight text-slate-900 tracking-tight tabular-nums">
                {loading ? '…' : `₹ ${dailyCollection.totalReceived.toLocaleString('en-IN')}`}
              </p>
              <p className="text-[11px] text-slate-500 mt-0.5">
                Cash: ₹{dailyCollection.byMode.cash.amount.toLocaleString('en-IN')} | Digital: ₹{(dailyCollection.byMode.online.amount + dailyCollection.byMode.upi.amount).toLocaleString('en-IN')}
              </p>
            </div>
          </div>

          {/* Card 2: This Month's Collection */}
          <div className="bg-white p-4 sm:p-5 rounded-2xl border border-slate-200/70 shadow-2xs hover:shadow-md hover:shadow-slate-900/5 transition-shadow duration-200 flex flex-col justify-between space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-blue-600 flex items-center gap-1.5">
                <span className="w-2 h-2 rounded-full bg-blue-500"></span>
                {monthlyCollection.month}
              </span>
              <span className="text-[10px] font-semibold px-2 py-0.5 bg-blue-50 text-blue-700 ring-1 ring-blue-200/70 rounded-full">
                {monthlyCollection.receivedCount} receipt{monthlyCollection.receivedCount === 1 ? '' : 's'}
              </span>
            </div>
            <div>
              <p className="text-2xl sm:text-[1.65rem] font-bold leading-tight text-blue-900 tracking-tight tabular-nums">
                {loading ? '…' : `₹ ${monthlyCollection.totalReceived.toLocaleString('en-IN')}`}
              </p>
              <p className="text-[11px] text-blue-600 font-medium mt-0.5">
                Collected this month
              </p>
            </div>
          </div>

          {/* Card 3: Total Pending dues (Outstanding) */}
          <div
            onClick={() => router.push('/fees')}
            className="bg-linear-to-br from-rose-50/60 to-white p-4 sm:p-5 rounded-2xl border border-rose-200/80 shadow-2xs flex flex-col justify-between space-y-3 cursor-pointer hover:border-rose-300 hover:shadow-md hover:shadow-rose-900/5 transition-all duration-200 group"
          >
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-rose-600 flex items-center gap-1.5">
                <AlertCircle className="w-3.5 h-3.5 text-rose-500" />
                Pending dues
              </span>
              <span className="text-[10px] font-semibold px-2 py-0.5 bg-rose-50 text-rose-700 ring-1 ring-rose-200/70 rounded-full">
                {feeMetrics.duePercentage}%
              </span>
            </div>
            <div>
              <p className="text-2xl sm:text-[1.65rem] font-bold leading-tight text-rose-700 tracking-tight tabular-nums">
                {loading ? '…' : `₹ ${feeMetrics.dueFee.toLocaleString('en-IN')}`}
              </p>
              <p className="text-[11px] text-rose-500 font-semibold mt-0.5 flex items-center gap-1 group-hover:underline">
                View fee desk →
              </p>
            </div>
          </div>

          {/* Card 4: Overall Institutional Recovery */}
          <div className="bg-white p-4 sm:p-5 rounded-2xl border border-slate-200/70 shadow-2xs hover:shadow-md hover:shadow-slate-900/5 transition-shadow duration-200 flex flex-col justify-between space-y-3">
            <div className="flex items-center justify-between">
              <span className="text-[11px] font-bold text-slate-600">
                Total collected
              </span>
              <span className="text-[10px] font-semibold text-indigo-700 bg-indigo-50 ring-1 ring-indigo-200/70 px-2 py-0.5 rounded-full">
                {feeMetrics.paidPercentage}%
              </span>
            </div>
            <div>
              <p className="text-2xl sm:text-[1.65rem] font-bold leading-tight text-slate-900 tracking-tight tabular-nums">
                {loading ? '…' : `₹ ${feeMetrics.paidFee.toLocaleString('en-IN')}`}
              </p>
              <div className="w-full bg-slate-100 rounded-full h-2 mt-2 overflow-hidden">
                <div
                  className="bg-linear-to-r from-indigo-500 to-indigo-600 h-2 rounded-full transition-all duration-500"
                  style={{ width: `${Math.min(100, feeMetrics.paidPercentage)}%` }}
                />
              </div>
              <p className="text-[11px] text-slate-400 mt-1">
                of ₹{feeMetrics.totalFee.toLocaleString('en-IN')} total fee
              </p>
            </div>
          </div>
        </div>

        {/* VIEW 1: ACADEMIC MONTH-BY-MONTH MATRIX (12 MONTHS GRID) */}
        {activeFeeView === 'MATRIX' && (
          <div className="space-y-3 pt-2">
            <div className="flex items-center justify-between">
              <div>
                <h4 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                  <Calendar className="w-4 h-4 text-indigo-600" />
                  Month-wise fees (April – March)
                </h4>
                <p className="text-xs text-slate-500 mt-0.5">
                  Scheduled, collected and pending amount for each month
                </p>
              </div>
              <button
                onClick={() => router.push('/fees')}
                className="text-xs font-semibold text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50 px-2.5 py-1 rounded-lg flex items-center gap-1 cursor-pointer transition-colors shrink-0"
              >
                Go to fees →
              </button>
            </div>

            {monthlyMatrix.length === 0 ? (
              <div className="p-8 text-center text-slate-400 text-xs bg-slate-50 border border-dashed border-slate-200 rounded-2xl">
                Loading…
              </div>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3">
                {monthlyMatrix.map((m) => {
                  const statusConfig = {
                    PAID: { bg: 'bg-emerald-50', text: 'text-emerald-700', border: 'border-emerald-200', label: 'Fully paid' },
                    PARTIAL: { bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200', label: 'Partial' },
                    OVERDUE: { bg: 'bg-rose-50', text: 'text-rose-700', border: 'border-rose-200', label: 'Overdue' },
                    UPCOMING: { bg: 'bg-slate-50', text: 'text-slate-600', border: 'border-slate-200', label: 'Upcoming' },
                  }[m.status];

                  return (
                    <div
                      key={m.month_key}
                      className="bg-white border border-slate-200/70 rounded-2xl p-4 shadow-2xs hover:shadow-md hover:shadow-slate-900/5 hover:border-slate-300/80 transition-all duration-200 flex flex-col justify-between space-y-3"
                    >
                      <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                        <div>
                          <span className="font-semibold text-slate-900 text-sm">
                            {m.month_name}
                          </span>
                          <span className="text-[11px] font-semibold text-slate-400 ml-1.5">
                            {m.year}
                          </span>
                        </div>
                        <span className={`text-[10px] font-bold px-2 py-0.5 rounded-full border ${statusConfig.bg} ${statusConfig.text} ${statusConfig.border}`}>
                          {statusConfig.label}
                        </span>
                      </div>

                      <div className="space-y-1.5 text-xs">
                        <div className="flex items-center justify-between text-slate-600">
                          <span>Scheduled Fee:</span>
                          <span className="font-bold text-slate-900 tabular-nums">
                            ₹ {m.scheduled_amount.toLocaleString('en-IN')}
                          </span>
                        </div>
                        <div className="flex items-center justify-between text-emerald-700">
                          <span>Collected:</span>
                          <span className="font-bold tabular-nums">
                            ₹ {m.collected_amount.toLocaleString('en-IN')}
                          </span>
                        </div>
                        <div className="flex items-center justify-between text-rose-600">
                          <span>Remaining Due:</span>
                          <span className="font-bold tabular-nums">
                            ₹ {m.pending_amount.toLocaleString('en-IN')}
                          </span>
                        </div>

                        {/* Progress Bar */}
                        <div className="pt-1">
                          <div className="flex items-center justify-between text-[10px] text-slate-400 mb-1">
                            <span>Collection Rate</span>
                            <span className="font-bold text-slate-700">{m.collection_percentage}%</span>
                          </div>
                          <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                            <div
                              className={`h-full rounded-full transition-all duration-500 ${
                                m.collection_percentage >= 100
                                  ? 'bg-emerald-500'
                                  : m.collection_percentage > 50
                                  ? 'bg-indigo-600'
                                  : 'bg-amber-500'
                              }`}
                              style={{ width: `${Math.min(100, m.collection_percentage)}%` }}
                            />
                          </div>
                        </div>
                      </div>

                      <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[11px]">
                        <span className="text-slate-400">
                          {m.receipts_count} receipt{m.receipts_count === 1 ? '' : 's'}
                        </span>
                        {m.defaulters_count > 0 ? (
                          <span className="text-rose-600 font-semibold">
                            {m.defaulters_count} student{m.defaulters_count === 1 ? '' : 's'} pending
                          </span>
                        ) : (
                          <span className="text-emerald-600 font-medium">Clear</span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* VIEW 2 & 3: TODAY'S COUNTER & MONTHLY MODE BREAKDOWN */}
        {activeFeeView !== 'MATRIX' && (
          <div className="space-y-3 pt-1">
            <div className="flex items-center justify-between gap-2">
              <span className="text-xs font-semibold text-slate-600">
                By payment mode ({activeFeeView === 'TODAY' ? `Today: ${formattedToday}` : monthlyCollection.month})
              </span>
              <button
                onClick={() => router.push('/fees')}
                className="text-xs font-semibold text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50 px-2.5 py-1 rounded-lg flex items-center gap-1 cursor-pointer transition-colors shrink-0"
              >
                Go to fees →
              </button>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
              {/* Box 1: Cash */}
              <div
                onClick={() => router.push('/reports/daily-transactions?mode=CASH')}
                className="bg-white border border-slate-200/70 hover:border-indigo-200 rounded-2xl p-4 shadow-2xs hover:shadow-md hover:shadow-indigo-900/5 hover:-translate-y-0.5 transition-all duration-200 cursor-pointer group flex flex-col justify-between"
              >
                <div className="flex items-center justify-between">
                  <div className="flex flex-wrap items-center gap-2">
                    <div className="w-9 h-9 rounded-xl bg-emerald-50 text-emerald-600 ring-1 ring-emerald-100 flex items-center justify-center">
                      <Banknote className="w-4 h-4" />
                    </div>
                    <span className="font-semibold text-slate-900 text-xs group-hover:text-indigo-600 transition">
                      Cash
                    </span>
                  </div>
                  <ArrowUpRight className="w-4 h-4 text-slate-300 group-hover:text-indigo-600 group-hover:-translate-y-0.5 group-hover:translate-x-0.5 transition-all duration-200" />
                </div>
                <div className="mt-3">
                  <p className="text-lg font-bold text-slate-900 tabular-nums">
                    {loading ? '…' : `₹ ${activeModeBreakdown.cash.amount.toLocaleString('en-IN')}`}
                  </p>
                  <p className="text-[11px] text-slate-500 mt-0.5">
                    {activeModeBreakdown.cash.count} receipt{activeModeBreakdown.cash.count === 1 ? '' : 's'}
                  </p>
                </div>
              </div>

              {/* Box 2: Online / Netbanking */}
              <div
                onClick={() => router.push('/reports/daily-transactions?mode=ONLINE')}
                className="bg-white border border-slate-200/70 hover:border-indigo-200 rounded-2xl p-4 shadow-2xs hover:shadow-md hover:shadow-indigo-900/5 hover:-translate-y-0.5 transition-all duration-200 cursor-pointer group flex flex-col justify-between"
              >
                <div className="flex items-center justify-between">
                  <div className="flex flex-wrap items-center gap-2">
                    <div className="w-9 h-9 rounded-xl bg-blue-50 text-blue-600 ring-1 ring-blue-100 flex items-center justify-center">
                      <CreditCard className="w-4 h-4" />
                    </div>
                    <span className="font-semibold text-slate-900 text-xs group-hover:text-indigo-600 transition">
                      Online / Netbanking
                    </span>
                  </div>
                  <ArrowUpRight className="w-4 h-4 text-slate-300 group-hover:text-indigo-600 group-hover:-translate-y-0.5 group-hover:translate-x-0.5 transition-all duration-200" />
                </div>
                <div className="mt-3">
                  <p className="text-lg font-bold text-slate-900 tabular-nums">
                    {loading ? '…' : `₹ ${activeModeBreakdown.online.amount.toLocaleString('en-IN')}`}
                  </p>
                  <p className="text-[11px] text-slate-500 mt-0.5">
                    {activeModeBreakdown.online.count} payment{activeModeBreakdown.online.count === 1 ? '' : 's'}
                  </p>
                </div>
              </div>

              {/* Box 3: Cheque / DD */}
              <div
                onClick={() => router.push('/reports/daily-transactions?mode=CHEQUES')}
                className="bg-white border border-slate-200/70 hover:border-indigo-200 rounded-2xl p-4 shadow-2xs hover:shadow-md hover:shadow-indigo-900/5 hover:-translate-y-0.5 transition-all duration-200 cursor-pointer group flex flex-col justify-between"
              >
                <div className="flex items-center justify-between">
                  <div className="flex flex-wrap items-center gap-2">
                    <div className="w-9 h-9 rounded-xl bg-amber-50 text-amber-600 ring-1 ring-amber-100 flex items-center justify-center">
                      <Landmark className="w-4 h-4" />
                    </div>
                    <span className="font-semibold text-slate-900 text-xs group-hover:text-indigo-600 transition">
                      Cheque / DD
                    </span>
                  </div>
                  <ArrowUpRight className="w-4 h-4 text-slate-300 group-hover:text-indigo-600 group-hover:-translate-y-0.5 group-hover:translate-x-0.5 transition-all duration-200" />
                </div>
                <div className="mt-3">
                  <p className="text-lg font-bold text-slate-900 tabular-nums">
                    {loading ? '…' : `₹ ${activeModeBreakdown.cheque.amount.toLocaleString('en-IN')}`}
                  </p>
                  <p className="text-[11px] text-slate-500 mt-0.5">
                    {activeModeBreakdown.cheque.count} cheque{activeModeBreakdown.cheque.count === 1 ? '' : 's'}
                  </p>
                </div>
              </div>

              {/* Box 4: UPI / App */}
              <div
                onClick={() => router.push('/reports/daily-transactions?mode=APP_PAYMENTS')}
                className="bg-white border border-slate-200/70 hover:border-indigo-200 rounded-2xl p-4 shadow-2xs hover:shadow-md hover:shadow-indigo-900/5 hover:-translate-y-0.5 transition-all duration-200 cursor-pointer group flex flex-col justify-between"
              >
                <div className="flex items-center justify-between">
                  <div className="flex flex-wrap items-center gap-2">
                    <div className="w-9 h-9 rounded-xl bg-purple-50 text-purple-600 ring-1 ring-purple-100 flex items-center justify-center">
                      <Smartphone className="w-4 h-4" />
                    </div>
                    <span className="font-semibold text-slate-900 text-xs group-hover:text-indigo-600 transition">
                      UPI
                    </span>
                  </div>
                  <ArrowUpRight className="w-4 h-4 text-slate-300 group-hover:text-indigo-600 group-hover:-translate-y-0.5 group-hover:translate-x-0.5 transition-all duration-200" />
                </div>
                <div className="mt-3">
                  <p className="text-lg font-bold text-slate-900 tabular-nums">
                    {loading ? '…' : `₹ ${activeModeBreakdown.upi.amount.toLocaleString('en-IN')}`}
                  </p>
                  <p className="text-[11px] text-slate-500 mt-0.5">
                    {activeModeBreakdown.upi.count} payment{activeModeBreakdown.upi.count === 1 ? '' : 's'}
                  </p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Filter Controls Row: Class, Section, Month, Day Date Picker, View Button */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3 pt-4 border-t border-slate-100">
          {/* Class Filter */}
          <div>
            <label className="block text-[11px] font-semibold uppercase tracking-wide text-slate-500 mb-1.5">Class</label>
            <select
              value={selectedClass}
              onChange={(e) => {
                setSelectedClass(e.target.value);
                setSelectedSection('ALL');
              }}
              className="w-full text-xs px-3 py-2.5 bg-white border border-slate-200 rounded-xl shadow-2xs hover:border-slate-300 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15 font-medium text-slate-800 cursor-pointer transition"
            >
              <option value="ALL">All classes</option>
              {distinctClasses.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name}
                </option>
              ))}
            </select>
          </div>

          {/* Section Filter */}
          <div>
            <label className="block text-[11px] font-semibold uppercase tracking-wide text-slate-500 mb-1.5">Section</label>
            <select
              value={selectedSection}
              onChange={(e) => setSelectedSection(e.target.value)}
              className="w-full text-xs px-3 py-2.5 bg-white border border-slate-200 rounded-xl shadow-2xs hover:border-slate-300 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15 font-medium text-slate-800 cursor-pointer transition"
            >
              <option value="ALL">All sections</option>
              {distinctSections.map((s) => (
                <option key={s.id} value={s.id}>
                  {s.name}
                </option>
              ))}
            </select>
          </div>

          {/* Month Filter */}
          <div>
            <label className="block text-[11px] font-semibold uppercase tracking-wide text-slate-500 mb-1.5">Month</label>
            <select
              value={selectedMonth}
              onChange={(e) => setSelectedMonth(e.target.value)}
              className="w-full text-xs px-3 py-2.5 bg-white border border-slate-200 rounded-xl shadow-2xs hover:border-slate-300 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15 font-medium text-slate-800 cursor-pointer transition"
            >
              <option value="CURRENT">Current month</option>
              <option value="APR">April</option>
              <option value="MAY">May</option>
              <option value="JUN">June</option>
              <option value="JUL">July</option>
              <option value="AUG">August</option>
              <option value="SEP">September</option>
              <option value="OCT">October</option>
              <option value="NOV">November</option>
              <option value="DEC">December</option>
              <option value="JAN">January</option>
              <option value="FEB">February</option>
              <option value="MAR">March</option>
            </select>
          </div>

          {/* Day Date Picker */}
          <div>
            <label className="block text-[11px] font-semibold uppercase tracking-wide text-slate-500 mb-1.5">Date</label>
            <input
              type="date"
              value={selectedDate}
              onChange={(e) => setSelectedDate(e.target.value)}
              className="w-full text-xs px-3 py-2.5 bg-white border border-slate-200 rounded-xl shadow-2xs hover:border-slate-300 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15 font-medium text-slate-800 cursor-pointer transition"
            />
          </div>

          {/* View Button */}
          <div className="flex items-end">
            <button
              onClick={() => fetchSummary(selectedDate)}
              className="w-full py-3 px-4 sm:px-5 bg-indigo-600 hover:bg-indigo-700 active:scale-[0.98] text-white rounded-xl text-xs font-semibold flex items-center justify-center gap-1.5 shadow-sm shadow-indigo-900/20 hover:shadow-md hover:shadow-indigo-900/25 transition-all duration-200 cursor-pointer focus-visible:outline-none focus-visible:ring-4 focus-visible:ring-indigo-500/30"
            >
              <Search className="w-3.5 h-3.5" />
              Apply
            </button>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 2.5. INSTITUTIONAL 360° REAL-TIME INSPECTOR (STUDENT & TEACHER LIVE CARD)  */}
      {/* ========================================================================= */}
      <div id="institutional-inspector" className="bg-white rounded-2xl border border-slate-200/70 shadow-sm overflow-hidden scroll-mt-6">
        {/* Header Ribbon */}
        <div className="p-4 sm:p-5 bg-white border-b border-slate-100 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="w-11 h-11 rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100 flex items-center justify-center shrink-0">
              <Users className="w-5 h-5" />
            </div>
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="font-semibold text-base tracking-tight text-slate-900">
                  Student &amp; teacher lookup
                </h3>
              </div>
              <p className="text-xs text-slate-500">
                Attendance, fees and timetable for a student or teacher
              </p>
            </div>
          </div>

          {/* Mode Switcher Tabs */}
          <div className="inline-flex p-1 bg-slate-100/80 rounded-xl border border-slate-200/70 self-start md:self-center">
            <button
              type="button"
              onClick={() => setInspectorTab('STUDENT')}
              className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-all duration-200 flex items-center gap-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 ${inspectorTab === 'STUDENT'
                ? 'bg-white text-indigo-700 shadow-sm ring-1 ring-slate-200/80'
                : 'text-slate-600 hover:text-slate-900'
                }`}
            >
              <Users className="w-3.5 h-3.5" />
              Students ({studentsList.length})
            </button>
            <button
              type="button"
              onClick={() => setInspectorTab('TEACHER')}
              className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-all duration-200 flex items-center gap-2 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500 ${inspectorTab === 'TEACHER'
                ? 'bg-white text-indigo-700 shadow-sm ring-1 ring-slate-200/80'
                : 'text-slate-600 hover:text-slate-900'
                }`}
            >
              <GraduationCap className="w-3.5 h-3.5" />
              Teachers ({teachersList.length})
            </button>
          </div>
        </div>

        {/* Filter & Selection Bar */}
        <div className="p-4 sm:px-5 bg-slate-50/60 border-b border-slate-100 flex flex-wrap items-center justify-between gap-3 text-xs">
          {inspectorTab === 'STUDENT' ? (
            <div className="flex flex-wrap items-center gap-2.5 w-full md:w-auto">
              {/* Class Filter */}
              <div className="flex items-center gap-1.5">
                <span className="text-[11px] font-semibold text-slate-500">Class:</span>
                <select
                  value={inspectorClassId}
                  onChange={(e) => {
                    setInspectorClassId(e.target.value);
                    setInspectorSectionId('ALL');
                  }}
                  className="px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-medium text-slate-800 shadow-2xs hover:border-slate-300 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15 transition"
                >
                  <option value="ALL">All Classes</option>
                  {distinctClasses.map((c) => (
                    <option key={c.id} value={c.id}>{c.name}</option>
                  ))}
                </select>
              </div>

              {/* Section Filter */}
              <div className="flex items-center gap-1.5">
                <span className="text-[11px] font-semibold text-slate-500">Section:</span>
                <select
                  value={inspectorSectionId}
                  onChange={(e) => setInspectorSectionId(e.target.value)}
                  className="px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-medium text-slate-800 shadow-2xs hover:border-slate-300 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15 transition"
                >
                  <option value="ALL">All Sections</option>
                  {inspectorDistinctSections.map((s) => (
                    <option key={s.id} value={s.id}>{s.name}</option>
                  ))}
                </select>
              </div>

              {/* Student Select Dropdown */}
              <div className="flex items-center gap-1.5 flex-1 min-w-[200px]">
                <span className="text-[11px] font-semibold text-slate-500">Student:</span>
                <select
                  value={selectedStudentId || ''}
                  onChange={(e) => {
                    setSelectedStudentId(e.target.value);
                    if (e.target.value) loadStudentInspection(e.target.value);
                  }}
                  className="flex-1 px-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-bold text-indigo-950 shadow-2xs hover:border-slate-300 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15 transition"
                >
                  {studentsList.length === 0 ? (
                    <option value="">No students found</option>
                  ) : (
                    studentsList.map((st: any) => (
                      <option key={st.id} value={st.id}>
                        {st.full_name || `${st.first_name} ${st.last_name}`} (Roll: {st.roll_number || st.admission_number || '—'}{st.class_name ? ` • ${st.class_name}-${st.section_name}` : ''})
                      </option>
                    ))
                  )}
                </select>
              </div>
            </div>
          ) : (
            /* Teacher Select Dropdown */
            <div className="flex flex-wrap items-center gap-2.5 w-full md:w-auto">
              <div className="flex items-center gap-1.5 flex-1 min-w-[260px]">
                <span className="text-[11px] font-semibold text-slate-500">Teacher:</span>
                <select
                  value={selectedTeacherId || ''}
                  onChange={(e) => {
                    setSelectedTeacherId(e.target.value);
                    if (e.target.value) loadTeacherInspection(e.target.value);
                  }}
                  className="flex-1 px-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-bold text-indigo-950 shadow-2xs hover:border-slate-300 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15 transition"
                >
                  {teachersList.length === 0 ? (
                    <option value="">No teachers found</option>
                  ) : (
                    teachersList.map((t: any) => (
                      <option key={t.id} value={t.id}>
                        {t.staff_name || `${t.first_name} ${t.last_name}`} ({t.employee_code || 'No Code'} • {t.designation || 'Teacher'})
                      </option>
                    ))
                  )}
                </select>
              </div>
            </div>
          )}

          {/* Quick Search */}
          <div className="relative w-full sm:w-60">
            <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder={inspectorTab === 'STUDENT' ? 'Search name or roll no' : 'Search name or code'}
              value={inspectorSearchQuery}
              onChange={(e) => setInspectorSearchQuery(e.target.value)}
              className="w-full pl-8 pr-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs text-slate-800 placeholder-slate-400 shadow-2xs hover:border-slate-300 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15 transition"
            />
          </div>
        </div>

        {/* Live Content Deck */}
        <div className="p-4 sm:p-5">
          {inspectorTab === 'STUDENT' ? (
            loadingStudentInspect ? (
              <div className="py-12 flex flex-col items-center justify-center text-slate-400 gap-2">
                <RefreshCw className="w-6 h-6 animate-spin text-indigo-600" />
                <p className="text-xs font-medium">Loading student details…</p>
              </div>
            ) : !studentInspection ? (
              <div className="py-12 text-center text-slate-400">
                <Users className="w-10 h-10 mx-auto text-slate-300 mb-2" />
                <p className="font-semibold text-slate-700 text-sm">No student selected</p>
                <p className="text-xs text-slate-400">Pick a student from the list above</p>
              </div>
            ) : (
              /* STUDENT 360° LIVE DISPLAY CARD */
              <div className="space-y-4">
                {/* Top Student Header Strip */}
                <div className="p-4 sm:p-5 rounded-2xl bg-linear-to-r from-indigo-50/70 via-white to-white border border-indigo-100/80 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div className="flex items-center gap-3.5">
                    <div className="w-12 h-12 rounded-full bg-indigo-600 text-white flex items-center justify-center font-semibold text-lg shadow-sm ring-4 ring-indigo-100 shrink-0">
                      {studentInspection.student?.first_name?.[0] || 'S'}
                    </div>
                    <div>
                      <div className="flex flex-wrap items-center gap-2">
                        <h4 className="font-semibold text-slate-900 text-base">
                          {studentInspection.student?.full_name}
                        </h4>
                        <span className="px-2 py-0.5 rounded-full text-[11px] font-medium bg-white text-slate-600 border border-slate-200">
                          {studentInspection.student?.class_name}-{studentInspection.student?.section_name}
                        </span>
                      </div>
                      <p className="text-xs text-slate-500 flex flex-wrap items-center gap-x-2 gap-y-0.5 mt-1">
                        <span>Roll No: <strong>{studentInspection.student?.roll_number || '—'}</strong></span>
                        <span>•</span>
                        <span>Adm No: <strong>{studentInspection.student?.admission_number || '—'}</strong></span>
                        <span>•</span>
                        <span>Parent Phone: <strong>{studentInspection.student?.emergency_phone || studentInspection.student?.phone || '—'}</strong></span>
                      </p>
                    </div>
                  </div>

                  {/* Badges: Attendance Today + Fee Balance */}
                  <div className="flex flex-wrap items-center gap-2 self-start sm:self-center">
                    {/* Today Attendance Badge */}
                    <div className={`px-3 py-1.5 rounded-xl border flex items-center gap-1.5 text-xs font-bold ${studentInspection.attendance?.status === 'PRESENT'
                      ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                      : studentInspection.attendance?.status === 'ABSENT'
                        ? 'bg-rose-50 text-rose-800 border-rose-200'
                        : 'bg-amber-50 text-amber-800 border-amber-200'
                      }`}>
                      {studentInspection.attendance?.status === 'PRESENT' ? (
                        <>
                          <CheckCircle className="w-4 h-4 text-slate-400" />
                          <span>Present today</span>
                        </>
                      ) : studentInspection.attendance?.status === 'ABSENT' ? (
                        <>
                          <AlertCircle className="w-4 h-4 text-rose-600" />
                          <span>Absent today</span>
                        </>
                      ) : (
                        <>
                          <Clock className="w-4 h-4 text-amber-600" />
                          <span>Not marked yet</span>
                        </>
                      )}
                    </div>

                    {/* Fee Balance Badge */}
                    <div className={`px-3 py-1.5 rounded-xl border flex items-center gap-1.5 text-xs font-bold ${(studentInspection.fees?.due || 0) === 0
                      ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                      : 'bg-rose-50 text-rose-800 border-rose-200'
                      }`}>
                      <IndianRupee className="w-3.5 h-3.5" />
                      <span>
                        {(studentInspection.fees?.due || 0) === 0 ? 'Fees paid' : `₹ ${(studentInspection.fees?.due || 0).toLocaleString('en-IN')} Due`}
                      </span>
                    </div>
                  </div>
                </div>

                {/* 3-Column Inspection Grid */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
                  {/* Column 1: Faculty In-Charge (Class Teacher & Subject Teachers) */}
                  <div className="bg-slate-50/70 p-4 rounded-2xl border border-slate-200/70 space-y-3 hover:border-slate-300/70 transition-colors">
                    <div className="flex items-center justify-between pb-2.5 border-b border-slate-200/70">
                      <div className="flex items-center gap-1.5 font-bold text-slate-800 text-xs">
                        <GraduationCap className="w-4 h-4 text-slate-400" />
                        <span>Teachers</span>
                      </div>
                      <button
                        onClick={() => router.push('/academics/allocations')}
                        className="text-[11px] font-semibold text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50 px-2 py-1 -my-1 rounded-md transition-colors"
                      >
                        Allocations
                      </button>
                    </div>

                    {/* Homeroom Class Teacher */}
                    <div className="bg-white p-3 rounded-lg border border-slate-200">
                      <span className="text-[11px] font-medium text-slate-500">
                        Class teacher
                      </span>
                      <p className="font-bold text-slate-900 text-sm mt-1">
                        {studentInspection.class_teacher?.teacher_name || 'Not assigned'}
                      </p>
                      <p className="text-[11px] text-slate-500 mt-0.5">
                        Code: {studentInspection.class_teacher?.employee_code || '—'} • Phone: {studentInspection.class_teacher?.phone || '—'}
                      </p>
                    </div>

                    {/* Subject Teachers List */}
                    <div className="space-y-1.5">
                      <span className="text-[11px] font-bold text-slate-600">Subject teachers</span>
                      {(!studentInspection.subject_teachers || studentInspection.subject_teachers.length === 0) ? (
                        <p className="text-slate-400 italic text-[11px]">No subject teachers assigned</p>
                      ) : (
                        <div className="space-y-1 max-h-36 overflow-y-auto pr-1">
                          {studentInspection.subject_teachers.map((st: any, idx: number) => (
                            <div key={idx} className="flex items-center justify-between bg-white px-2.5 py-1.5 rounded-lg border border-slate-200/70 hover:border-slate-300 transition-colors text-[11px]">
                              <span className="font-semibold text-slate-700">{st.subject_name}</span>
                              <span className="text-slate-500">{st.teacher_name}</span>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Column 2: Fee Ledger & Receipts */}
                  <div className="bg-slate-50/70 p-4 rounded-2xl border border-slate-200/70 space-y-3 hover:border-slate-300/70 transition-colors">
                    <div className="flex items-center justify-between pb-2.5 border-b border-slate-200/70">
                      <div className="flex items-center gap-1.5 font-bold text-slate-800 text-xs">
                        <IndianRupee className="w-4 h-4 text-slate-400" />
                        <span>Fees</span>
                      </div>
                      <button
                        onClick={() => router.push('/fees')}
                        className="text-[11px] font-semibold text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50 px-2 py-1 -my-1 rounded-md transition-colors"
                      >
                        Fee desk
                      </button>
                    </div>

                    {/* Fee Summary Cards */}
                    <div className="grid grid-cols-3 gap-2 text-center">
                      <div className="bg-white p-2 rounded-lg border border-slate-200">
                        <span className="text-[10px] text-slate-500 font-medium">Total</span>
                        <p className="font-bold text-slate-900 mt-0.5">₹ {(studentInspection.fees?.total || 0).toLocaleString('en-IN')}</p>
                      </div>
                      <div className="bg-emerald-50/60 p-2 rounded-lg border border-emerald-100">
                        <span className="text-[10px] text-emerald-700 font-medium">Paid</span>
                        <p className="font-bold text-emerald-800 mt-0.5">₹ {(studentInspection.fees?.paid || 0).toLocaleString('en-IN')}</p>
                      </div>
                      <div className="bg-rose-50/60 p-2 rounded-lg border border-rose-100">
                        <span className="text-[10px] text-rose-700 font-medium">Due</span>
                        <p className="font-bold text-rose-800 mt-0.5">₹ {(studentInspection.fees?.due || 0).toLocaleString('en-IN')}</p>
                      </div>
                    </div>

                    {/* Recent Fee Receipts */}
                    <div className="space-y-1.5">
                      <span className="text-[11px] font-bold text-slate-600">Recent receipts</span>
                      {(!studentInspection.fees?.receipts || studentInspection.fees?.receipts.length === 0) ? (
                        <p className="text-slate-400 italic text-[11px]">No fee receipts found</p>
                      ) : (
                        <div className="space-y-1 max-h-36 overflow-y-auto pr-1">
                          {studentInspection.fees?.receipts.map((rcpt: any, idx: number) => (
                            <div key={idx} className="flex items-center justify-between bg-white px-2.5 py-1.5 rounded-lg border border-slate-200/70 hover:border-slate-300 transition-colors text-[11px]">
                              <div>
                                <span className="font-bold text-slate-800">#{rcpt.receipt_number || 'RCPT'}</span>
                                <span className="text-[10px] text-slate-400 ml-1.5">{rcpt.payment_mode}</span>
                              </div>
                              <span className="font-bold text-emerald-700">₹ {Number(rcpt.amount_paid).toLocaleString('en-IN')}</span>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Column 3: Guardian & Schedule Today */}
                  <div className="bg-slate-50/70 p-4 rounded-2xl border border-slate-200/70 space-y-3 hover:border-slate-300/70 transition-colors">
                    <div className="flex items-center justify-between pb-2.5 border-b border-slate-200/70">
                      <div className="flex items-center gap-1.5 font-bold text-slate-800 text-xs">
                        <CalendarDays className="w-4 h-4 text-slate-400" />
                        <span>Today&apos;s timetable</span>
                      </div>
                      <button
                        onClick={() => router.push('/timetable')}
                        className="text-[11px] font-semibold text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50 px-2 py-1 -my-1 rounded-md transition-colors"
                      >
                        Timetable
                      </button>
                    </div>

                    {/* Guardians info */}
                    <div className="bg-white p-2.5 rounded-lg border border-slate-200/70 space-y-1 text-[11px]">
                      <div className="flex justify-between">
                        <span className="text-slate-500">Father:</span>
                        <span className="font-semibold text-slate-800">{studentInspection.student?.father_name || '—'}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-500">Mother:</span>
                        <span className="font-semibold text-slate-800">{studentInspection.student?.mother_name || '—'}</span>
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-500">Login ID:</span>
                        <span className="font-mono text-indigo-700">{studentInspection.student?.username || '—'}</span>
                      </div>
                    </div>

                    {/* Schedule List */}
                    <div className="space-y-1.5">
                      <span className="text-[11px] font-bold text-slate-600">Periods today</span>
                      {(!studentInspection.today_schedule || studentInspection.today_schedule.length === 0) ? (
                        <p className="text-slate-400 italic text-[11px]">No periods today</p>
                      ) : (
                        <div className="space-y-1 max-h-32 overflow-y-auto pr-1">
                          {studentInspection.today_schedule.map((slot: any, idx: number) => (
                            <div key={idx} className="flex items-center justify-between bg-white px-2.5 py-1 rounded-lg border border-slate-200/70 hover:border-slate-300 transition-colors text-[11px]">
                              <span className="font-semibold text-slate-700">{slot.subject_name}</span>
                              <span className="text-slate-400 text-[11px] tabular-nums">{slot.start_time?.slice(0, 5)} - {slot.end_time?.slice(0, 5)}</span>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            )
          ) : (
            /* TEACHER 360° LIVE DISPLAY CARD */
            loadingTeacherInspect ? (
              <div className="py-12 flex flex-col items-center justify-center text-slate-400 gap-2">
                <RefreshCw className="w-6 h-6 animate-spin text-emerald-600" />
                <p className="text-xs font-medium">Loading teacher details…</p>
              </div>
            ) : !teacherInspection ? (
              <div className="py-12 text-center text-slate-400">
                <GraduationCap className="w-10 h-10 mx-auto text-slate-300 mb-2" />
                <p className="font-semibold text-slate-700 text-sm">No teacher selected</p>
                <p className="text-xs text-slate-400">Pick a teacher from the list above</p>
              </div>
            ) : (
              <div className="space-y-4">
                {/* Top Teacher Header Strip */}
                <div className="p-4 sm:p-5 rounded-2xl bg-linear-to-r from-indigo-50/70 via-white to-white border border-indigo-100/80 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div className="flex items-center gap-3.5">
                    <div className="w-12 h-12 rounded-full bg-indigo-600 text-white flex items-center justify-center font-semibold text-lg shadow-sm ring-4 ring-indigo-100 shrink-0">
                      {teacherInspection.teacher?.first_name?.[0] || 'T'}
                    </div>
                    <div>
                      <div className="flex flex-wrap items-center gap-2">
                        <h4 className="font-semibold text-slate-900 text-base">
                          {teacherInspection.teacher?.full_name}
                        </h4>
                        <span className="px-2 py-0.5 rounded-full text-[11px] font-medium bg-white text-slate-600 border border-slate-200">
                          {teacherInspection.teacher?.designation || 'Teacher'}
                        </span>
                      </div>
                      <p className="text-xs text-slate-500 flex flex-wrap items-center gap-x-2 gap-y-0.5 mt-1">
                        <span>Code: <strong>{teacherInspection.teacher?.employee_code || '—'}</strong></span>
                        <span>•</span>
                        <span>Dept: <strong>{teacherInspection.teacher?.department || 'Academics'}</strong></span>
                        <span>•</span>
                        <span>Phone: <strong>{teacherInspection.teacher?.phone || '—'}</strong></span>
                      </p>
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center gap-2 self-start sm:self-center">
                    <button
                      onClick={() => router.push('/staff')}
                      className="px-3.5 py-2 bg-white border border-slate-200 hover:bg-slate-50 hover:border-slate-300 rounded-xl text-xs font-semibold text-slate-700 shadow-2xs transition-all duration-200"
                    >
                      Staff list
                    </button>
                    <button
                      onClick={() => router.push('/academics/allocations')}
                      className="px-3.5 py-2 bg-indigo-600 hover:bg-indigo-700 active:scale-[0.98] text-white rounded-xl text-xs font-semibold shadow-sm shadow-indigo-900/20 hover:shadow-md transition-all duration-200 flex items-center gap-1.5"
                    >
                                            Assign classes
                    </button>
                  </div>
                </div>

                {/* 3-Column Teacher Inspection Grid */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-xs">
                  {/* Column 1: Homeroom Class Teacher Assignment */}
                  <div className="bg-slate-50/70 p-4 rounded-2xl border border-slate-200/70 space-y-3 hover:border-slate-300/70 transition-colors">
                    <div className="flex items-center gap-1.5 font-bold text-slate-800 text-xs pb-2.5 border-b border-slate-200/70">
                      <LayoutGrid className="w-4 h-4 text-slate-400" />
                      <span>Class teacher of</span>
                    </div>

                    {(!teacherInspection.class_teacher_of || teacherInspection.class_teacher_of.length === 0) ? (
                      <div className="p-4 bg-white rounded-lg border border-slate-200 text-center text-slate-400">
                        <AlertCircle className="w-6 h-6 mx-auto mb-1 text-slate-300" />
                        <p className="font-semibold text-slate-600 text-xs">Not a class teacher</p>
                        <p className="text-[11px] text-slate-400 mt-0.5">Can be assigned from Allocations</p>
                      </div>
                    ) : (
                      <div className="space-y-2">
                        {teacherInspection.class_teacher_of.map((c: any, idx: number) => (
                          <div key={idx} className="bg-white p-3 rounded-lg border border-slate-200 flex items-center justify-between">
                            <div>
                              <span className="text-[11px] font-medium text-slate-500">
                                Class Teacher
                              </span>
                              <p className="font-bold text-slate-900 text-sm mt-1">
                                {c.class_name} - {c.section_name}
                              </p>
                            </div>
                            <CheckCircle className="w-5 h-5 text-emerald-500" />
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Column 2: Subject & Class Allocations */}
                  <div className="bg-slate-50/70 p-4 rounded-2xl border border-slate-200/70 space-y-3 hover:border-slate-300/70 transition-colors">
                    <div className="flex items-center justify-between pb-2.5 border-b border-slate-200/70">
                      <div className="flex items-center gap-1.5 font-bold text-slate-800 text-xs">
                        <BookOpen className="w-4 h-4 text-slate-400" />
                        <span>Subjects Taught ({teacherInspection.subjects_taught?.length || 0})</span>
                      </div>
                      
                    </div>

                    {(!teacherInspection.subjects_taught || teacherInspection.subjects_taught.length === 0) ? (
                      <div className="p-4 bg-white rounded-lg border border-slate-200 text-center text-slate-400">
                        <p className="text-xs">No subject allocations found</p>
                      </div>
                    ) : (
                      <div className="space-y-1.5 max-h-48 overflow-y-auto pr-1">
                        {teacherInspection.subjects_taught.map((sub: any, idx: number) => (
                          <div key={idx} className="bg-white p-2.5 rounded-lg border border-slate-200/70 flex items-center justify-between">
                            <div>
                              <p className="font-bold text-slate-800 text-xs">{sub.subject_name}</p>
                              <p className="text-[10px] text-slate-500 font-medium">
                                {sub.class_name} - {sub.section_name}
                              </p>
                            </div>
                            <span className="text-[10px] font-mono text-slate-400">{sub.subject_code || 'SUB'}</span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Column 3: Today's Teaching Schedule */}
                  <div className="bg-slate-50/70 p-4 rounded-2xl border border-slate-200/70 space-y-3 hover:border-slate-300/70 transition-colors">
                    <div className="flex items-center justify-between pb-2.5 border-b border-slate-200/70">
                      <div className="flex items-center gap-1.5 font-bold text-slate-800 text-xs">
                        <Clock className="w-4 h-4 text-slate-400" />
                        <span>Today&apos;s periods</span>
                      </div>
                      <button
                        onClick={() => router.push('/timetable')}
                        className="text-[11px] font-semibold text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50 px-2 py-1 -my-1 rounded-md transition-colors"
                      >
                        Timetable
                      </button>
                    </div>

                    {(!teacherInspection.today_classes || teacherInspection.today_classes.length === 0) ? (
                      <div className="p-4 bg-white rounded-lg border border-slate-200 text-center text-slate-400">
                        <Clock className="w-6 h-6 mx-auto mb-1 text-slate-300" />
                        <p className="text-xs font-semibold text-slate-600">No periods today</p>
                        <p className="text-[10px] text-slate-400 mt-0.5">Free today, or timetable not set</p>
                      </div>
                    ) : (
                      <div className="space-y-1.5 max-h-48 overflow-y-auto pr-1">
                        {teacherInspection.today_classes.map((cls: any, idx: number) => (
                          <div key={idx} className="bg-white p-2.5 rounded-lg border border-slate-200/70 flex items-center justify-between">
                            <div>
                              <p className="font-bold text-slate-800 text-xs">{cls.subject_name}</p>
                              <p className="text-[10px] text-slate-500 font-medium">{cls.class_name} - {cls.section_name}</p>
                            </div>
                            <span className="text-[11px] text-slate-500 tabular-nums">
                              {cls.start_time?.slice(0, 5)} - {cls.end_time?.slice(0, 5)}
                            </span>
                          </div>
                        ))}
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )
          )}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 3. LOWER SECTION: TODAY'S STATUS TABLE (LEFT) + QUICK ACCESS (RIGHT)       */}
      {/* ========================================================================= */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-5">
        {/* Left Column: Today's Status (7 cols) */}
        <div className="lg:col-span-7 bg-white rounded-2xl border border-slate-200/70 shadow-sm overflow-hidden">
          {/* Header */}
          <div className="px-4 sm:px-5 py-4 border-b border-slate-100 flex items-center justify-between gap-2">
            <div className="flex items-center gap-2.5">
              <div className="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100 flex items-center justify-center shrink-0">
                <Calendar className="w-4 h-4" />
              </div>
              <h3 className="font-semibold text-slate-900 text-[15px] tracking-tight">Today&apos;s Status</h3>
            </div>
            <span className="text-xs font-semibold text-slate-600 bg-white ring-1 ring-slate-200 px-2.5 py-1 rounded-full whitespace-nowrap">
              {formattedToday}
            </span>
          </div>

          {/* Table */}
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs text-slate-600">
              <thead className="bg-slate-50/80 text-[11px] font-semibold uppercase tracking-wider text-slate-500 border-b border-slate-100">
                <tr>
                  <th className="py-3 px-4 sm:px-5 w-12 text-center">S.No</th>
                  <th className="py-3 px-4 sm:px-5">Title</th>
                  <th className="py-3 px-4 sm:px-5 text-center">Total</th>
                  <th className="py-3 px-4 sm:px-5 text-center text-emerald-700">Present</th>
                  <th className="py-3 px-4 sm:px-5 text-center text-rose-700">Absent</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {/* 1. Total Student */}
                <tr
                  onClick={() => handleOpenAttendanceModal('PRESENT')}
                  className="hover:bg-indigo-50/40 transition-colors cursor-pointer group"
                >
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">1</td>
                  <td className="py-3 px-4 sm:px-5 font-semibold text-slate-800 flex items-center justify-between">
                    <span>Students</span>
                    <span className="text-[10px] text-blue-600 opacity-0 group-hover:opacity-100 transition">
                      View list
                    </span>
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-slate-900">
                    {loading ? '…' : (data?.today_status?.total_students ?? totalStudents).toLocaleString('en-IN')}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-emerald-600">
                    {loading ? '…' : (data?.today_status?.present_students ?? totalPresentToday).toLocaleString('en-IN')}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-rose-600">
                    {loading ? '…' : (data?.today_status?.absent_students ?? totalAbsentToday).toLocaleString('en-IN')}
                  </td>
                </tr>

                {/* 2. Total Teacher */}
                <tr
                  onClick={() => handleInspectTeacherDirect()}
                  className="hover:bg-indigo-50/40 transition-colors cursor-pointer group"
                >
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">2</td>
                  <td className="py-3 px-4 sm:px-5 font-semibold text-slate-800 flex items-center justify-between">
                    <span>Teachers</span>
                    <span className="text-[10px] text-emerald-600 opacity-0 group-hover:opacity-100 transition">
                      View details
                    </span>
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-slate-900">
                    {loading ? '…' : data?.today_status?.total_teachers ?? data?.kpis?.total_faculty ?? 0}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-emerald-600">
                    {loading ? '…' : (data?.today_status?.present_teachers ?? Math.max(0, (data?.kpis?.total_faculty ?? 0) - (data?.kpis?.total_absent_staff ?? 0)))}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-rose-600">
                    {loading ? '…' : data?.today_status?.absent_teachers ?? data?.kpis?.total_absent_staff ?? 0}
                  </td>
                </tr>

                {/* 3. Total Classes */}
                <tr
                  onClick={() => router.push('/academics/subjects')}
                  className="hover:bg-indigo-50/40 transition-colors cursor-pointer"
                >
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">3</td>
                  <td className="py-3 px-4 sm:px-5 font-semibold text-slate-800">Classes</td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-slate-900">
                    {loading ? '…' : data?.today_status?.total_classes ?? distinctClasses.length}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-emerald-600">
                    {loading ? '…' : data?.today_status?.total_classes ?? distinctClasses.length}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">0</td>
                </tr>

                {/* 4. Total Sections */}
                <tr
                  onClick={() => router.push('/timetable')}
                  className="hover:bg-indigo-50/40 transition-colors cursor-pointer"
                >
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">4</td>
                  <td className="py-3 px-4 sm:px-5 font-semibold text-slate-800">Sections</td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-slate-900">
                    {loading ? '…' : data?.today_status?.total_sections ?? data?.sections?.length ?? 0}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-emerald-600">
                    {loading ? '…' : data?.today_status?.total_sections ?? data?.sections?.length ?? 0}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">0</td>
                </tr>

                {/* 5. Total Fee Collection */}
                <tr
                  onClick={() => router.push('/reports/daily-transactions')}
                  className="hover:bg-indigo-50/40 transition-colors cursor-pointer group"
                >
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">5</td>
                  <td className="py-3 px-4 sm:px-5 font-semibold text-slate-800 flex items-center justify-between">
                    <span>Fee collected</span>
                    <span className="text-[10px] text-blue-600 opacity-0 group-hover:opacity-100 transition">
                      Transactions
                    </span>
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-emerald-700">
                    {loading ? '…' : `₹ ${(data?.daily_collection?.total_received ?? data?.today_status?.today_fee_collection ?? 0).toLocaleString('en-IN')}`}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">—</td>
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">—</td>
                </tr>

                {/* 6. Total Transport */}
                <tr className="hover:bg-indigo-50/40 transition-colors">
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">6</td>
                  <td className="py-3 px-4 sm:px-5 font-semibold text-slate-800">Transport</td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-slate-900">
                    {loading ? '…' : data?.today_status?.total_transport ?? '—'}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">—</td>
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">0</td>
                </tr>

                {/* 7. Total Parents */}
                <tr className="hover:bg-indigo-50/40 transition-colors">
                  <td className="py-3 px-4 sm:px-5 text-center font-medium text-slate-400">7</td>
                  <td className="py-3 px-4 sm:px-5 font-semibold text-slate-800">Parents</td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-slate-900">
                    {loading ? '…' : (data?.today_status?.total_parents ?? totalStudents).toLocaleString('en-IN')}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-emerald-600">
                    {loading ? '…' : totalPresentToday.toLocaleString('en-IN')}
                  </td>
                  <td className="py-3 px-4 sm:px-5 text-center font-bold text-rose-600">
                    {loading ? '…' : totalAbsentToday.toLocaleString('en-IN')}
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        {/* Right Column: Quick Access (5 cols) */}
        <div className="lg:col-span-5 bg-white rounded-2xl border border-slate-200/70 shadow-sm p-4 sm:p-5 flex flex-col justify-between">
          <div className="flex items-center gap-2.5 mb-4">
            <div className="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100 flex items-center justify-center shrink-0">
              <LayoutGrid className="w-4 h-4" />
            </div>
            <h3 className="font-semibold text-slate-900 text-[15px] tracking-tight">Quick Access</h3>
          </div>

          {/* 8 Colorful Circular / Rounded Modules Grid */}
          <div className="grid grid-cols-2 gap-3">
            {/* Student */}
            <button
              onClick={() => router.push('/students')}
              className="flex items-center gap-3 p-3 rounded-xl border border-slate-200/70 hover:border-indigo-200 bg-white hover:bg-indigo-50/50 hover:shadow-sm hover:-translate-y-0.5 transition-all duration-200 group cursor-pointer text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
            >
              <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white transition-colors duration-200">
                <Users className="w-5 h-5" />
              </div>
              <span className="font-semibold text-xs sm:text-[13px] text-slate-800 group-hover:text-indigo-700 transition-colors">
                Student
              </span>
            </button>

            {/* Teacher */}
            <button
              onClick={() => router.push('/staff')}
              className="flex items-center gap-3 p-3 rounded-xl border border-slate-200/70 hover:border-indigo-200 bg-white hover:bg-indigo-50/50 hover:shadow-sm hover:-translate-y-0.5 transition-all duration-200 group cursor-pointer text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
            >
              <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white transition-colors duration-200">
                <GraduationCap className="w-5 h-5" />
              </div>
              <span className="font-semibold text-xs sm:text-[13px] text-slate-800 group-hover:text-indigo-700 transition-colors">
                Teacher
              </span>
            </button>

            {/* Class */}
            <button
              onClick={() => router.push('/academics/subjects')}
              className="flex items-center gap-3 p-3 rounded-xl border border-slate-200/70 hover:border-indigo-200 bg-white hover:bg-indigo-50/50 hover:shadow-sm hover:-translate-y-0.5 transition-all duration-200 group cursor-pointer text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
            >
              <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white transition-colors duration-200">
                <LayoutGrid className="w-5 h-5" />
              </div>
              <span className="font-semibold text-xs sm:text-[13px] text-slate-800 group-hover:text-indigo-700 transition-colors">
                Class
              </span>
            </button>

            {/* Section */}
            <button
              onClick={() => router.push('/timetable')}
              className="flex items-center gap-3 p-3 rounded-xl border border-slate-200/70 hover:border-indigo-200 bg-white hover:bg-indigo-50/50 hover:shadow-sm hover:-translate-y-0.5 transition-all duration-200 group cursor-pointer text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
            >
              <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white transition-colors duration-200">
                <CheckCircle className="w-5 h-5" />
              </div>
              <span className="font-semibold text-xs sm:text-[13px] text-slate-800 group-hover:text-indigo-700 transition-colors">
                Section
              </span>
            </button>

            {/* Fee */}
            <button
              onClick={() => router.push('/fees')}
              className="flex items-center gap-3 p-3 rounded-xl border border-slate-200/70 hover:border-indigo-200 bg-white hover:bg-indigo-50/50 hover:shadow-sm hover:-translate-y-0.5 transition-all duration-200 group cursor-pointer text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
            >
              <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white transition-colors duration-200">
                <IndianRupee className="w-5 h-5" />
              </div>
              <span className="font-semibold text-xs sm:text-[13px] text-slate-800 group-hover:text-indigo-700 transition-colors">
                Fee
              </span>
            </button>

            {/* Attendance */}
            <button
              onClick={() => router.push('/attendance/students')}
              className="flex items-center gap-3 p-3 rounded-xl border border-slate-200/70 hover:border-indigo-200 bg-white hover:bg-indigo-50/50 hover:shadow-sm hover:-translate-y-0.5 transition-all duration-200 group cursor-pointer text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
            >
              <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white transition-colors duration-200">
                <CalendarDays className="w-5 h-5" />
              </div>
              <span className="font-semibold text-xs sm:text-[13px] text-slate-800 group-hover:text-indigo-700 transition-colors">
                Attendance
              </span>
            </button>

            {/* Homework / Transport */}
            <button
              onClick={() => router.push('/homework')}
              className="flex items-center gap-3 p-3 rounded-xl border border-slate-200/70 hover:border-indigo-200 bg-white hover:bg-indigo-50/50 hover:shadow-sm hover:-translate-y-0.5 transition-all duration-200 group cursor-pointer text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
            >
              <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white transition-colors duration-200">
                <BookOpen className="w-5 h-5" />
              </div>
              <span className="font-semibold text-xs sm:text-[13px] text-slate-800 group-hover:text-indigo-700 transition-colors">
                Homework
              </span>
            </button>

            {/* Reports */}
            <button
              onClick={() => router.push('/reports/daily-transactions')}
              className="flex items-center gap-3 p-3 rounded-xl border border-slate-200/70 hover:border-indigo-200 bg-white hover:bg-indigo-50/50 hover:shadow-sm hover:-translate-y-0.5 transition-all duration-200 group cursor-pointer text-left focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-indigo-500"
            >
              <div className="w-10 h-10 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center shrink-0 group-hover:bg-indigo-600 group-hover:text-white transition-colors duration-200">
                <FileText className="w-5 h-5" />
              </div>
              <span className="font-semibold text-xs sm:text-[13px] text-slate-800 group-hover:text-indigo-700 transition-colors">
                Reports
              </span>
            </button>
          </div>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 4. BOTTOM SECTION: RECENT ACTIVITY AUDIT LOG TABLE                        */}
      {/* ========================================================================= */}
      <div className="bg-white rounded-2xl border border-slate-200/70 shadow-sm overflow-hidden">
        {/* Header */}
        <div className="px-4 sm:px-5 py-4 border-b border-slate-100 flex items-center justify-between gap-2">
          <div className="flex flex-wrap items-center gap-2">
            <div className="w-9 h-9 rounded-xl bg-indigo-50 text-indigo-600 ring-1 ring-indigo-100 flex items-center justify-center shrink-0">
              <Clock className="w-4 h-4" />
            </div>
            <h3 className="font-semibold text-slate-900 text-[15px] tracking-tight">Recent Activity</h3>
          </div>
          <button
            onClick={() => router.push('/reports/daily-transactions')}
            className="text-xs font-semibold text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50 px-2.5 py-1 rounded-lg transition-colors"
          >
            View All
          </button>
        </div>

        {/* Activities Table */}
        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs text-slate-600">
            <thead className="bg-slate-50/80 text-[11px] font-semibold uppercase tracking-wider text-slate-500 border-b border-slate-100">
              <tr>
                <th className="py-3 px-4 sm:px-5 w-32">Date</th>
                <th className="py-3 px-4 sm:px-5 w-28">Time</th>
                <th className="py-3 px-4 sm:px-5">Activity</th>
                <th className="py-3 px-4 sm:px-5 w-28 text-right">User</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {recentActivities.length === 0 && (
                <tr>
                  <td colSpan={4} className="py-8 px-4 text-center text-slate-400">
                    No activity recorded yet
                  </td>
                </tr>
              )}
              {recentActivities.map((act) => (
                <tr key={act.id} className="hover:bg-indigo-50/40 transition-colors">
                  <td className="py-3 px-4 sm:px-5 text-slate-600 tabular-nums">{act.date}</td>
                  <td className="py-3 px-4 sm:px-5 text-slate-500 tabular-nums">{act.time}</td>
                  <td className="py-3 px-4 sm:px-5 font-medium text-slate-800">{act.activity}</td>
                  <td className="py-3 px-4 sm:px-5 text-right">
                    <span className="text-slate-500">
                      {act.user}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* ========================================================================= */}
      {/* 5. OPTIONAL ACCORDION: SECTION-WISE ATTENDANCE & HOMEWORK COMPLIANCE     */}
      {/* ========================================================================= */}
      <div className="bg-white rounded-2xl border border-slate-200/70 shadow-sm overflow-hidden">
        <button
          onClick={() => setShowComplianceGrid(!showComplianceGrid)}
          className="w-full p-4 sm:px-5 flex items-center justify-between gap-3 text-left hover:bg-slate-50/70 transition-colors cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-indigo-500"
        >
          <div className="flex items-center gap-2.5">
            <Layers className="w-5 h-5 text-indigo-600 shrink-0" />
            <div>
              <h4 className="font-semibold text-slate-900 text-[15px] tracking-tight">
                Section-wise attendance & homework
              </h4>
              <p className="text-xs text-slate-500">
                Which sections have marked attendance and given homework today
              </p>
            </div>
          </div>
          <span className="text-xs font-semibold text-indigo-600 flex items-center gap-1 shrink-0 px-2.5 py-1 rounded-lg bg-indigo-50">
            {showComplianceGrid ? 'Hide' : 'Show'}
            <ChevronDown className={`w-4 h-4 transition-transform ${showComplianceGrid ? 'rotate-180' : ''}`} />
          </span>
        </button>

        {showComplianceGrid && (
          <div className="p-4 sm:p-5 border-t border-slate-100 bg-slate-50/50 animate-fade-in">
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-2.5">
              {(data?.sections || []).map((sec) => (
                <div
                  key={`${sec.class_id}_${sec.section_id}`}
                  className="bg-white p-3 rounded-xl border border-slate-200/70 shadow-2xs hover:shadow-md hover:shadow-slate-900/5 transition-shadow duration-200 space-y-2"
                >
                  <p className="font-bold text-slate-800 text-xs truncate">
                    {sec.class_name} - {sec.section_name}
                  </p>
                  <div className="flex items-center justify-between text-[11px]">
                    <span className="text-slate-500">Students:</span>
                    <span className="font-bold text-slate-700">{sec.total_students}</span>
                  </div>
                  <div className="flex flex-wrap items-center gap-1.5 pt-1.5 border-t border-slate-100">
                    <span
                      className={`px-1.5 py-0.5 rounded-md text-[10px] font-semibold ${sec.attendance_status === 'GREEN'
                        ? 'bg-emerald-100 text-emerald-800'
                        : 'bg-rose-100 text-rose-800'
                        }`}
                    >
                      {sec.attendance_status === 'GREEN' ? 'Attendance done' : 'Attendance pending'}
                    </span>
                    <span
                      className={`px-1.5 py-0.5 rounded-md text-[10px] font-semibold ${sec.homework_status === 'GREEN'
                        ? 'bg-blue-100 text-blue-800'
                        : 'bg-amber-100 text-amber-800'
                        }`}
                    >
                      {sec.homework_status === 'GREEN' ? 'Homework given' : 'No homework'}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      {/* ========================================================================= */}
      {/* 6. MODAL: STUDENT ATTENDANCE ROSTER (PRESENT & ABSENT INSPECTION)         */}
      {/* ========================================================================= */}
      {attendanceModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fade-in">
          <div role="dialog" aria-modal="true" className="bg-white w-full max-w-2xl rounded-2xl shadow-2xl ring-1 ring-slate-900/5 overflow-hidden max-h-[90vh] flex flex-col">
            {/* Modal Header */}
            <div className="px-6 py-4 bg-white border-b border-slate-100 flex items-center justify-between">
              <div>
                <h3 className="font-semibold text-base text-slate-900 flex items-center gap-2">
                  <CalendarDays className="w-5 h-5 text-indigo-600" />
                  Attendance – {formattedToday}
                </h3>
                <p className="text-xs text-slate-500">
                  Students marked present and absent today
                </p>
              </div>
              <button
                onClick={() => setAttendanceModalOpen(false)}
                aria-label="Close" className="text-slate-400 hover:text-slate-700 hover:bg-slate-100 rounded-md transition p-1"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Tabs & Search */}
            <div className="p-4 border-b border-slate-100 bg-slate-50/70 flex flex-col sm:flex-row items-center justify-between gap-3">
              <div className="flex items-center gap-1.5 p-1 bg-slate-200/70 rounded-xl w-full sm:w-auto">
                <button
                  onClick={() => setAttendanceModalTab('PRESENT')}
                  className={`flex-1 sm:flex-none justify-center px-4 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-all duration-200 ${attendanceModalTab === 'PRESENT'
                    ? 'bg-white text-emerald-800 shadow-xs'
                    : 'text-slate-600 hover:text-slate-900'
                    }`}
                >
                  <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                  Present ({modalPresentList.length})
                </button>
                <button
                  onClick={() => setAttendanceModalTab('ABSENT')}
                  className={`flex-1 sm:flex-none justify-center px-4 py-1.5 rounded-lg text-xs font-semibold flex items-center gap-1.5 transition-all duration-200 ${attendanceModalTab === 'ABSENT'
                    ? 'bg-white text-rose-800 shadow-xs'
                    : 'text-slate-600 hover:text-slate-900'
                    }`}
                >
                  <span className="w-2 h-2 rounded-full bg-rose-500"></span>
                  Absent ({modalAbsentList.length})
                </button>
              </div>

              <div className="relative w-full sm:w-64">
                <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Search name or roll no"
                  value={attendanceSearch}
                  onChange={(e) => setAttendanceSearch(e.target.value)}
                  className="w-full pl-8 pr-3 py-1.5 bg-white border border-slate-200 rounded-xl text-xs text-slate-800 shadow-2xs hover:border-slate-300 focus:outline-none focus:border-indigo-400 focus:ring-4 focus:ring-indigo-500/15 transition"
                />
              </div>
            </div>

            {/* Modal Content Table */}
            <div className="p-4 overflow-auto max-h-[55vh]">
              {filteredModalList.length === 0 ? (
                <div className="p-12 text-center text-slate-400">
                  <Users className="w-10 h-10 mx-auto mb-2 text-slate-300" />
                  <p className="font-semibold text-slate-700 text-sm">No students found</p>
                  <p className="text-xs text-slate-400 mt-0.5">Try a different name or roll no</p>
                </div>
              ) : (
                <table className="w-full text-left text-xs text-slate-600">
                  <thead className="bg-slate-50 text-[11px] font-semibold text-slate-500 border-b border-slate-200">
                    <tr>
                      <th className="py-2 px-3">Student Name</th>
                      <th className="py-2 px-3">Roll No</th>
                      <th className="py-2 px-3">Class & Section</th>
                      <th className="py-2 px-3 text-center">Status</th>
                      <th className="py-2 px-3 text-right"></th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {filteredModalList.map((st) => (
                      <tr key={st.id} className="hover:bg-indigo-50/40 transition-colors">
                        <td className="py-2 px-3 font-semibold text-slate-800">
                          {st.student_name}
                        </td>
                        <td className="py-2 px-3 text-slate-600 tabular-nums">
                          {st.roll_number || st.admission_number || '—'}
                        </td>
                        <td className="py-2 px-3 text-slate-600">
                          {st.class_name ? `${st.class_name} - ${st.section_name}` : '—'}
                        </td>
                        <td className="py-2 px-3 text-center">
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${st.status === 'PRESENT'
                              ? 'bg-emerald-100 text-emerald-800'
                              : 'bg-rose-100 text-rose-800'
                              }`}
                          >
                            {st.status}
                          </span>
                        </td>
                        <td className="py-2 px-3 text-right">
                          <button
                            type="button"
                            onClick={() => handleInspectStudentFromModal(st.student_id || st.id)}
                            className="px-2.5 py-1 hover:bg-indigo-50 text-indigo-600 font-semibold rounded-lg text-[11px] transition-colors"
                          >
                                                        View
                          </button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              )}
            </div>

            {/* Modal Footer */}
            <div className="px-6 py-3 bg-slate-50/70 border-t border-slate-100 flex justify-end">
              <button
                onClick={() => setAttendanceModalOpen(false)}
                className="px-4 py-2 text-xs font-semibold text-slate-700 bg-white border border-slate-200 hover:bg-slate-50 hover:border-slate-300 rounded-xl shadow-2xs transition-all duration-200"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
