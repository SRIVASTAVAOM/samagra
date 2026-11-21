'use client';

import React, { useState, useEffect, useMemo } from 'react';
import {
  BookOpen,
  Search,
  Calendar,
  Users,
  GraduationCap,
  Sparkles,
  ShieldCheck,
  CheckCircle2,
  Clock,
  FileText,
  Paperclip,
  Eye,
  Edit,
  Trash2,
  Plus,
  X,
  Upload,
  Camera,
  ExternalLink,
  Loader2,
  AlertCircle,
  Filter,
} from 'lucide-react';
import { api, API_BASE_URL } from '@/lib/api';
import { ClassItem, SubjectItem } from '@/lib/types';

interface HomeworkItem {
  id: string;
  title: string;
  description: string;
  assigned_date: string;
  due_date: string;
  s3_attachment_key: string | null;
  attachment_name: string | null;
  created_at: string;
  class_id: string;
  class_name: string;
  section_id: string;
  section_name: string;
  subject_id: string;
  subject_name: string;
  subject_code: string;
  teacher_id: string;
  teacher_name: string;
  teacher_emp_code: string;
  completed_submissions_count: number;
  total_students_count: number;
}

interface StaffOption {
  id: string;
  staff_name: string;
  employee_code?: string;
}

export default function HomeworkPage() {
  const [homeworkList, setHomeworkList] = useState<HomeworkItem[]>([]);
  const [classes, setClasses] = useState<ClassItem[]>([]);
  const [subjects, setSubjects] = useState<SubjectItem[]>([]);
  const [staffList, setStaffList] = useState<StaffOption[]>([]);
  const [loading, setLoading] = useState(true);

  // Filters state
  const [selectedClassId, setSelectedClassId] = useState<string>('ALL');
  const [selectedSectionId, setSelectedSectionId] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState('');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'PAST_DUE'>('ALL');

  // Modal states
  const [selectedHomework, setSelectedHomework] = useState<HomeworkItem | null>(null);
  const [isAddModalOpen, setIsAddModalOpen] = useState(false);
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const [editingHomework, setEditingHomework] = useState<HomeworkItem | null>(null);

  // Form state for Add/Edit
  const [formData, setFormData] = useState({
    class_id: '',
    section_id: '',
    subject_id: '',
    staff_id: '',
    title: '',
    description: '',
    assigned_date: new Date().toISOString().split('T')[0],
    due_date: new Date(Date.now() + 86400000 * 2).toISOString().split('T')[0],
    attachment_name: '',
  });

  const [saving, setSaving] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // 5 MB Attachment States
  const [addAttachmentFile, setAddAttachmentFile] = useState<File | null>(null);
  const [addAttachmentError, setAddAttachmentError] = useState<string | null>(null);

  const [editAttachmentFile, setEditAttachmentFile] = useState<File | null>(null);
  const [editAttachmentKey, setEditAttachmentKey] = useState<string | null>(null);
  const [editAttachmentName, setEditAttachmentName] = useState<string | null>(null);
  const [editAttachmentError, setEditAttachmentError] = useState<string | null>(null);

  // Live Camera Snapshot States
  const [isCameraOpen, setIsCameraOpen] = useState(false);
  const [cameraTarget, setCameraTarget] = useState<'ADD' | 'EDIT'>('ADD');
  const [cameraError, setCameraError] = useState<string | null>(null);
  const videoRef = React.useRef<HTMLVideoElement | null>(null);
  const streamRef = React.useRef<MediaStream | null>(null);

  const startCamera = async (target: 'ADD' | 'EDIT') => {
    setCameraTarget(target);
    setCameraError(null);
    setIsCameraOpen(true);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({
        video: { facingMode: 'environment', width: { ideal: 1280 }, height: { ideal: 720 } },
        audio: false,
      });
      streamRef.current = stream;
      if (videoRef.current) {
        videoRef.current.srcObject = stream;
      }
    } catch (err: any) {
      console.warn('[Camera error]:', err);
      setCameraError('Camera access not granted or unavailable. Please allow camera permissions in your browser or select a file from device.');
    }
  };

  const stopCamera = () => {
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((track) => track.stop());
      streamRef.current = null;
    }
    if (videoRef.current) {
      videoRef.current.srcObject = null;
    }
    setIsCameraOpen(false);
    setCameraError(null);
  };

  const capturePhoto = () => {
    if (!videoRef.current) return;
    const video = videoRef.current;
    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth || 1280;
    canvas.height = video.videoHeight || 720;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);

    canvas.toBlob((blob) => {
      if (!blob) return;
      const file = new File([blob], `live_photo_${Date.now()}.jpg`, { type: 'image/jpeg' });
      if (cameraTarget === 'ADD') {
        setAddAttachmentFile(file);
        setAddAttachmentError(null);
      } else {
        setEditAttachmentFile(file);
        setEditAttachmentError(null);
      }
      stopCamera();
    }, 'image/jpeg', 0.9);
  };

  useEffect(() => {
    return () => {
      if (streamRef.current) {
        streamRef.current.getTracks().forEach((track) => track.stop());
      }
    };
  }, []);

  // Fetch initial data
  const loadData = async () => {
    try {
      setLoading(true);
      const [clsData, hwData, subData, staffData] = await Promise.all([
        api.academics.getClasses().catch(() => []),
        api.admin.getHomework().catch(() => []),
        api.academics.getSubjects().catch(() => []),
        api.admin.getAllStaff().catch(() => []),
      ]);
      setClasses(clsData || []);
      setHomeworkList(hwData || []);
      setSubjects(subData || []);
      setStaffList(staffData || []);
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to load homework data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Available sections for the filter bar
  const availableFilterSections = useMemo(() => {
    if (selectedClassId === 'ALL') {
      const allSecs: { id: string; name: string }[] = [];
      const seen = new Set<string>();
      classes.forEach((c) => {
        (c.sections || []).forEach((sec) => {
          if (!seen.has(sec.id)) {
            seen.add(sec.id);
            allSecs.push(sec);
          }
        });
      });
      return allSecs;
    }
    const cls = classes.find((c) => c.id === selectedClassId);
    return cls ? cls.sections || [] : [];
  }, [classes, selectedClassId]);

  // When class filter changes, reset section filter if it is not in the new class
  const handleClassFilterChange = (classId: string) => {
    setSelectedClassId(classId);
    if (classId !== 'ALL') {
      const cls = classes.find((c) => c.id === classId);
      const hasSec = cls?.sections?.some((s) => s.id === selectedSectionId);
      if (!hasSec) {
        setSelectedSectionId('ALL');
      }
    }
  };

  // Sections available inside the Add/Edit form based on chosen class_id
  const formAvailableSections = useMemo(() => {
    if (!formData.class_id) return [];
    const cls = classes.find((c) => c.id === formData.class_id);
    return cls ? cls.sections || [] : [];
  }, [classes, formData.class_id]);

  // Filter homework list
  const todayStr = useMemo(() => new Date().toISOString().split('T')[0], []);

  const filteredHomework = useMemo(() => {
    return homeworkList.filter((hw) => {
      const matchesClass = selectedClassId === 'ALL' || hw.class_id === selectedClassId;
      const matchesSection = selectedSectionId === 'ALL' || hw.section_id === selectedSectionId;

      const isPastDue = hw.due_date < todayStr;
      const matchesStatus =
        statusFilter === 'ALL' ||
        (statusFilter === 'ACTIVE' && !isPastDue) ||
        (statusFilter === 'PAST_DUE' && isPastDue);

      const q = searchQuery.toLowerCase().trim();
      const matchesSearch =
        !q ||
        hw.title.toLowerCase().includes(q) ||
        hw.description.toLowerCase().includes(q) ||
        hw.teacher_name.toLowerCase().includes(q) ||
        hw.subject_name.toLowerCase().includes(q) ||
        hw.class_name.toLowerCase().includes(q) ||
        hw.section_name.toLowerCase().includes(q);

      return matchesClass && matchesSection && matchesStatus && matchesSearch;
    });
  }, [homeworkList, selectedClassId, selectedSectionId, statusFilter, searchQuery, todayStr]);

  // KPIs
  const totalAssignments = homeworkList.length;
  const activeAssignments = homeworkList.filter((h) => h.due_date >= todayStr).length;
  const totalSubmissions = homeworkList.reduce(
    (acc, h) => acc + (h.completed_submissions_count || 0),
    0
  );
  const uniqueTeachers = new Set(homeworkList.map((h) => h.teacher_id)).size;

  // Open Add Homework Modal
  const handleOpenAddModal = () => {
    const defaultClassId = classes[0]?.id || '';
    const defaultSectionId = classes[0]?.sections?.[0]?.id || '';
    const defaultSubjectId = subjects[0]?.id || '';

    setFormData({
      class_id: defaultClassId,
      section_id: defaultSectionId,
      subject_id: defaultSubjectId,
      staff_id: '',
      title: '',
      description: '',
      assigned_date: new Date().toISOString().split('T')[0],
      due_date: new Date(Date.now() + 86400000 * 2).toISOString().split('T')[0],
      attachment_name: '',
    });
    setAddAttachmentFile(null);
    setAddAttachmentError(null);
    setErrorMessage(null);
    setSuccessMessage(null);
    setIsAddModalOpen(true);
  };

  // Open Edit Homework Modal
  const handleOpenEditModal = (hw: HomeworkItem) => {
    setEditingHomework(hw);
    setFormData({
      class_id: hw.class_id || '',
      section_id: hw.section_id || '',
      subject_id: hw.subject_id || '',
      staff_id: hw.teacher_id || '',
      title: hw.title || '',
      description: hw.description || '',
      assigned_date: hw.assigned_date || new Date().toISOString().split('T')[0],
      due_date: hw.due_date || new Date().toISOString().split('T')[0],
      attachment_name: hw.attachment_name || '',
    });
    setEditAttachmentFile(null);
    setEditAttachmentKey(hw.s3_attachment_key || null);
    setEditAttachmentName(hw.attachment_name || null);
    setEditAttachmentError(null);
    setErrorMessage(null);
    setSuccessMessage(null);
    setIsEditModalOpen(true);
  };

  // Submit Create Homework
  const handleCreateHomework = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formData.class_id || !formData.section_id || !formData.subject_id || !formData.title.trim() || !formData.due_date) {
      setErrorMessage('Please fill in Class, Section, Subject, Title, and Submission Due Date.');
      return;
    }
    if (formData.due_date < formData.assigned_date) {
      setErrorMessage('Submission due date cannot be earlier than the assigned date.');
      return;
    }

    try {
      setSaving(true);
      setErrorMessage(null);

      let uploadedAttachmentKey: string | undefined = undefined;
      let uploadedAttachmentName: string | undefined = undefined;

      if (addAttachmentFile) {
        const uploadRes = await api.admin.uploadHomeworkAttachment(addAttachmentFile);
        uploadedAttachmentKey = uploadRes.fileKey || uploadRes.attachmentUrl;
        uploadedAttachmentName = uploadRes.attachmentName;
      }

      await api.admin.createHomework({
        class_id: formData.class_id,
        section_id: formData.section_id,
        subject_id: formData.subject_id,
        staff_id: formData.staff_id || undefined,
        title: formData.title.trim(),
        description: formData.description.trim(),
        assigned_date: formData.assigned_date,
        due_date: formData.due_date,
        attachment_name: uploadedAttachmentName || formData.attachment_name.trim() || undefined,
        s3_attachment_key: uploadedAttachmentKey,
      });
      setSuccessMessage(`Homework "${formData.title}" assigned successfully!`);
      setIsAddModalOpen(false);
      loadData();
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to assign homework');
    } finally {
      setSaving(false);
    }
  };

  // Submit Edit Homework
  const handleUpdateHomework = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingHomework) return;
    if (!formData.class_id || !formData.section_id || !formData.subject_id || !formData.title.trim() || !formData.due_date) {
      setErrorMessage('Please fill in Class, Section, Subject, Title, and Submission Due Date.');
      return;
    }
    if (formData.due_date < formData.assigned_date) {
      setErrorMessage('Submission due date cannot be earlier than the assigned date.');
      return;
    }

    try {
      setSaving(true);
      setErrorMessage(null);

      let finalKey: string | undefined = editAttachmentKey || undefined;
      let finalName: string | undefined = editAttachmentName || undefined;

      if (editAttachmentFile) {
        const uploadRes = await api.admin.uploadHomeworkAttachment(editAttachmentFile);
        finalKey = uploadRes.fileKey || uploadRes.attachmentUrl;
        finalName = uploadRes.attachmentName;
      }

      await api.admin.updateHomework(editingHomework.id, {
        class_id: formData.class_id,
        section_id: formData.section_id,
        subject_id: formData.subject_id,
        staff_id: formData.staff_id || undefined,
        title: formData.title.trim(),
        description: formData.description.trim(),
        assigned_date: formData.assigned_date,
        due_date: formData.due_date,
        attachment_name: finalName,
        s3_attachment_key: finalKey,
      });
      setSuccessMessage(`Homework "${formData.title}" updated successfully!`);
      setIsEditModalOpen(false);
      loadData();
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to update homework');
    } finally {
      setSaving(false);
    }
  };

  // Delete Homework
  const handleDeleteHomework = async (hw: HomeworkItem) => {
    if (!window.confirm(`Are you sure you want to delete homework "${hw.title}"? This cannot be undone.`)) {
      return;
    }

    try {
      setSaving(true);
      setErrorMessage(null);
      await api.admin.deleteHomework(hw.id);
      setSuccessMessage(`Homework "${hw.title}" deleted successfully.`);
      loadData();
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to delete homework');
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="space-y-6 pb-12">
      {/* Header Banner */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 samagra-hero p-6 rounded-2xl text-white shadow-xl border border-indigo-500/20">
        <div>
          <div className="flex items-center gap-2 mb-2">
            <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-indigo-500/30 text-indigo-300 border border-indigo-400/30 flex items-center gap-1.5">
              <Sparkles className="w-3.5 h-3.5" />
              Menu 11 • View/Assign Homework
            </span>
            <span className="px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 flex items-center gap-1">
              <ShieldCheck className="w-3.5 h-3.5" />
              Admin Assignment & Edit Enabled
            </span>
          </div>
          <h1 className="text-2xl font-bold tracking-tight text-white flex items-center gap-2.5">
            <BookOpen className="w-7 h-7 text-indigo-400" />
            View/Assign Homework
          </h1>
          <p className="text-sm text-slate-300 mt-1 max-w-2xl">
            Inspect, upload, and assign homework for any class and section. Edit existing tasks, review teacher attributions, and monitor student completion progress in real-time.
          </p>
        </div>

        <button
          onClick={handleOpenAddModal}
          className="inline-flex items-center justify-center gap-2 px-5 py-3 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold rounded-xl shadow-lg transition active:scale-95 text-sm shrink-0 border border-indigo-400/40"
        >
          <Plus className="w-4 h-4" />
          Assign / Upload Homework
        </button>
      </div>

      {/* Alerts */}
      {errorMessage && (
        <div className="p-4 bg-rose-50 border border-rose-200 rounded-xl flex items-center gap-3 text-rose-800 text-sm">
          <AlertCircle className="w-5 h-5 text-rose-600 shrink-0" />
          <span>{errorMessage}</span>
        </div>
      )}

      {successMessage && (
        <div className="p-4 bg-emerald-50 border border-emerald-200 rounded-xl flex items-center gap-3 text-emerald-800 text-sm">
          <CheckCircle2 className="w-5 h-5 text-emerald-600 shrink-0" />
          <span className="font-medium">{successMessage}</span>
        </div>
      )}

      {/* KPI Cards Strip */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
        <div className="bg-white p-4 rounded-xl border border-slate-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
            <BookOpen className="w-5 h-5" />
          </div>
          <div>
            <p className="text-xs text-slate-500 font-medium">Total Assignments</p>
            <p className="text-xl font-bold text-slate-800">{totalAssignments}</p>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-emerald-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
            <Clock className="w-5 h-5" />
          </div>
          <div>
            <p className="text-xs text-slate-500 font-medium">Active (Due Soon)</p>
            <p className="text-xl font-bold text-emerald-700">{activeAssignments}</p>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-blue-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
            <CheckCircle2 className="w-5 h-5" />
          </div>
          <div>
            <p className="text-xs text-slate-500 font-medium">Completed Submissions</p>
            <p className="text-xl font-bold text-blue-700">{totalSubmissions}</p>
          </div>
        </div>

        <div className="bg-white p-4 rounded-xl border border-purple-200 shadow-sm flex items-center gap-3">
          <div className="w-10 h-10 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center font-bold">
            <GraduationCap className="w-5 h-5" />
          </div>
          <div>
            <p className="text-xs text-slate-500 font-medium">Teachers Assigning</p>
            <p className="text-xl font-bold text-purple-700">{uniqueTeachers}</p>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl shadow-sm border border-slate-200 flex flex-col lg:flex-row items-center justify-between gap-4">
        {/* Search */}
        <div className="relative w-full lg:w-72">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search title, teacher, subject..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-800 focus:outline-none focus:ring-2 focus:ring-indigo-500"
          />
        </div>

        {/* Class Filter, Section Filter, and Status */}
        <div className="flex flex-wrap items-center gap-2.5 w-full lg:w-auto">
          {/* Class Filter */}
          <div className="flex items-center gap-1.5">
            <span className="text-xs font-semibold text-slate-500">Class:</span>
            <select
              value={selectedClassId}
              onChange={(e) => handleClassFilterChange(e.target.value)}
              className="px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="ALL">All Classes</option>
              {classes.map((cls) => (
                <option key={cls.id} value={cls.id}>
                  {cls.name}
                </option>
              ))}
            </select>
          </div>

          {/* Section Filter */}
          <div className="flex items-center gap-1.5">
            <span className="text-xs font-semibold text-slate-500">Section:</span>
            <select
              value={selectedSectionId}
              onChange={(e) => setSelectedSectionId(e.target.value)}
              className="px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-700 focus:outline-none focus:ring-2 focus:ring-indigo-500"
            >
              <option value="ALL">All Sections</option>
              {availableFilterSections.map((sec) => (
                <option key={sec.id} value={sec.id}>
                  Section {sec.name}
                </option>
              ))}
            </select>
          </div>

          {/* Status Buttons */}
          <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl">
            <button
              onClick={() => setStatusFilter('ALL')}
              className={`px-2.5 py-1 text-xs font-semibold rounded-lg transition ${
                statusFilter === 'ALL'
                  ? 'bg-white text-slate-800 shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              All
            </button>
            <button
              onClick={() => setStatusFilter('ACTIVE')}
              className={`px-2.5 py-1 text-xs font-semibold rounded-lg transition ${
                statusFilter === 'ACTIVE'
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Active
            </button>
            <button
              onClick={() => setStatusFilter('PAST_DUE')}
              className={`px-2.5 py-1 text-xs font-semibold rounded-lg transition ${
                statusFilter === 'PAST_DUE'
                  ? 'bg-rose-600 text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              Past Due
            </button>
          </div>
        </div>
      </div>

      {/* Homework Table */}
      <div className="bg-white rounded-2xl shadow-sm border border-slate-200 overflow-hidden">
        {loading ? (
          <div className="p-16 text-center text-slate-500 flex flex-col items-center justify-center">
            <Loader2 className="w-8 h-8 animate-spin text-indigo-600 mb-3" />
            <p className="text-sm font-medium">Loading assigned homework...</p>
          </div>
        ) : filteredHomework.length === 0 ? (
          <div className="p-16 text-center text-slate-500">
            <BookOpen className="w-12 h-12 text-slate-300 mx-auto mb-3" />
            <p className="text-base font-semibold text-slate-700">No homework records found</p>
            <p className="text-xs text-slate-400 mt-1">
              There are no assignments matching your selected filters.
            </p>
            <button
              onClick={handleOpenAddModal}
              className="mt-4 px-4 py-2 bg-indigo-600 text-white text-xs font-semibold rounded-xl hover:bg-indigo-700 transition"
            >
              + Assign Homework Now
            </button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-600">
              <thead className="bg-slate-50 text-xs uppercase font-semibold text-slate-500 border-b border-slate-200 tracking-wider">
                <tr>
                  <th className="py-3.5 px-4">Homework Title & Subject</th>
                  <th className="py-3.5 px-4">Class & Section</th>
                  <th className="py-3.5 px-4">Assigned By</th>
                  <th className="py-3.5 px-4">Timeline</th>
                  <th className="py-3.5 px-4">Completion Status</th>
                  <th className="py-3.5 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredHomework.map((hw) => {
                  const isPastDue = hw.due_date < todayStr;
                  const total = hw.total_students_count || 1;
                  const completed = hw.completed_submissions_count || 0;
                  const percent = Math.min(100, Math.round((completed / total) * 100));

                  return (
                    <tr key={hw.id} className="hover:bg-slate-50/80 transition-colors group">
                      {/* Title & Subject */}
                      <td className="py-3.5 px-4">
                        <div className="space-y-1">
                          <p className="font-semibold text-slate-800 text-sm line-clamp-1 group-hover:text-indigo-600 transition">
                            {hw.title}
                          </p>
                          <div className="flex items-center gap-2">
                            <span className="px-2 py-0.5 rounded text-[11px] font-bold bg-indigo-50 text-indigo-700 border border-indigo-200/60">
                              {hw.subject_name}
                            </span>
                            {hw.attachment_name && (
                              <a
                                href={hw.s3_attachment_key && hw.s3_attachment_key.startsWith('http') ? hw.s3_attachment_key : `${API_BASE_URL}/homework/${hw.id}/attachment-download`}
                                target="_blank"
                                rel="noopener noreferrer"
                                onClick={(e) => e.stopPropagation()}
                                className="inline-flex items-center gap-1 text-[11px] font-medium text-indigo-600 hover:text-indigo-800 hover:underline bg-indigo-50/70 px-1.5 py-0.5 rounded border border-indigo-200/50 transition"
                                title="Open Cloudinary attachment in new tab"
                              >
                                <Paperclip className="w-3 h-3 text-indigo-500" />
                                <span className="max-w-[120px] truncate">{hw.attachment_name}</span>
                                <ExternalLink className="w-2.5 h-2.5 text-indigo-400" />
                              </a>
                            )}
                          </div>
                        </div>
                      </td>

                      {/* Class & Section */}
                      <td className="py-3.5 px-4">
                        <span className="font-medium text-slate-700 text-xs px-2.5 py-1 rounded-md bg-slate-100 border border-slate-200">
                          {hw.class_name} • Sec {hw.section_name}
                        </span>
                      </td>

                      {/* Assigned Teacher / Staff */}
                      <td className="py-3.5 px-4">
                        <div className="flex items-center gap-2.5">
                          <div className="w-8 h-8 rounded-full bg-gradient-to-tr from-indigo-600 to-slate-800 text-white flex items-center justify-center font-bold text-xs shrink-0 shadow-sm">
                            {hw.teacher_name ? hw.teacher_name.charAt(0).toUpperCase() : 'A'}
                          </div>
                          <div>
                            <p className="font-semibold text-slate-800 text-xs">
                              {hw.teacher_name || 'Admin'}
                            </p>
                            <p className="text-[10px] font-mono text-slate-400">
                              {hw.teacher_emp_code || 'ADMIN'}
                            </p>
                          </div>
                        </div>
                      </td>

                      {/* Timeline */}
                      <td className="py-3.5 px-4 text-xs space-y-0.5">
                        <p className="text-slate-500">
                          Assigned: <span className="font-medium text-slate-700">{hw.assigned_date}</span>
                        </p>
                        <p className="flex items-center gap-1.5">
                          Due:{' '}
                          <span
                            className={`font-semibold ${
                              isPastDue ? 'text-rose-600' : 'text-emerald-700'
                            }`}
                          >
                            {hw.due_date}
                          </span>
                          {isPastDue ? (
                            <span className="px-1.5 py-0.2 rounded text-[10px] bg-rose-100 text-rose-700 font-bold">
                              Closed
                            </span>
                          ) : (
                            <span className="px-1.5 py-0.2 rounded text-[10px] bg-emerald-100 text-emerald-700 font-bold">
                              Open
                            </span>
                          )}
                        </p>
                      </td>

                      {/* Completion Progress Bar */}
                      <td className="py-3.5 px-4 w-44">
                        <div className="space-y-1">
                          <div className="flex justify-between text-xs font-semibold">
                            <span className="text-slate-700">
                              {completed} / {total}
                            </span>
                            <span className="text-indigo-600">{percent}%</span>
                          </div>
                          <div className="w-full h-2 bg-slate-100 rounded-full overflow-hidden">
                            <div
                              className={`h-full rounded-full transition-all ${
                                percent === 100
                                  ? 'bg-emerald-500'
                                  : percent > 50
                                  ? 'bg-indigo-600'
                                  : 'bg-amber-500'
                              }`}
                              style={{ width: `${percent}%` }}
                            />
                          </div>
                        </div>
                      </td>

                      {/* Actions: View, Edit, Delete */}
                      <td className="py-3.5 px-4 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          <button
                            onClick={() => setSelectedHomework(hw)}
                            className="p-1.5 text-slate-500 hover:text-indigo-600 hover:bg-indigo-50 rounded-lg transition"
                            title="View Details"
                          >
                            <Eye className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleOpenEditModal(hw)}
                            className="p-1.5 text-slate-500 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition"
                            title="Edit Homework"
                          >
                            <Edit className="w-4 h-4" />
                          </button>
                          <button
                            onClick={() => handleDeleteHomework(hw)}
                            className="p-1.5 text-slate-500 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition"
                            title="Delete Homework"
                          >
                            <Trash2 className="w-4 h-4" />
                          </button>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* View Homework Detail Modal */}
      {selectedHomework && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-sm animate-fade-in">
          <div className="bg-white w-full max-w-xl rounded-2xl shadow-2xl border border-slate-200 overflow-hidden">
            <div className="px-6 py-4 bg-slate-900 text-white flex items-center justify-between">
              <div>
                <span className="text-xs text-indigo-300 font-semibold uppercase tracking-wider">
                  {selectedHomework.subject_name} • {selectedHomework.class_name} ({selectedHomework.section_name})
                </span>
                <h3 className="font-bold text-lg text-white mt-0.5">{selectedHomework.title}</h3>
              </div>
              <button
                onClick={() => setSelectedHomework(null)}
                className="text-slate-400 hover:text-white transition"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-4">
              {/* Teacher Attribution Box */}
              <div className="p-3.5 bg-indigo-50/60 rounded-xl border border-indigo-100 flex items-center justify-between">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-indigo-600 text-white flex items-center justify-center font-bold text-sm">
                    {selectedHomework.teacher_name ? selectedHomework.teacher_name.charAt(0).toUpperCase() : 'A'}
                  </div>
                  <div>
                    <p className="text-xs text-slate-500 font-medium">Assigned by</p>
                    <p className="font-bold text-slate-800 text-sm">{selectedHomework.teacher_name}</p>
                  </div>
                </div>
                <span className="text-xs font-mono bg-white px-2.5 py-1 rounded-md text-slate-600 border border-slate-200">
                  {selectedHomework.teacher_emp_code}
                </span>
              </div>

              {/* Dates Strip */}
              <div className="grid grid-cols-2 gap-3 text-xs">
                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <p className="text-slate-500">Assigned Date</p>
                  <p className="font-bold text-slate-800 text-sm mt-0.5">{selectedHomework.assigned_date}</p>
                </div>
                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200">
                  <p className="text-slate-500">Submission Due Date</p>
                  <p className="font-bold text-emerald-700 text-sm mt-0.5">{selectedHomework.due_date}</p>
                </div>
              </div>

              {/* Description */}
              <div>
                <h4 className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-1.5">
                  Assignment Instructions & Description
                </h4>
                <div className="p-4 bg-slate-50 rounded-xl text-sm text-slate-700 leading-relaxed border border-slate-200/80 whitespace-pre-wrap">
                  {selectedHomework.description}
                </div>
              </div>

              {/* Attachment if present */}
              {selectedHomework.attachment_name && (
                <div className="p-3 bg-indigo-50/60 border border-indigo-100 rounded-xl flex items-center justify-between text-xs">
                  <span className="flex items-center gap-2 font-medium text-slate-800 truncate max-w-[280px]">
                    <Paperclip className="w-4 h-4 text-indigo-600 flex-shrink-0" />
                    {selectedHomework.attachment_name}
                  </span>
                  {selectedHomework.s3_attachment_key ? (
                    <a
                      href={selectedHomework.s3_attachment_key.startsWith('http') ? selectedHomework.s3_attachment_key : `${API_BASE_URL}/homework/${selectedHomework.id}/attachment-download`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="inline-flex items-center gap-1 px-3 py-1 bg-white border border-indigo-200 text-indigo-600 hover:bg-indigo-50 font-semibold rounded-lg shadow-2xs transition"
                    >
                      <Eye className="w-3.5 h-3.5" />
                      View Attachment
                    </a>
                  ) : (
                    <span className="text-slate-400">Attached Reference</span>
                  )}
                </div>
              )}
            </div>

            <div className="px-6 py-3.5 bg-slate-50 border-t border-slate-200 flex justify-end gap-2">
              <button
                onClick={() => {
                  const hw = selectedHomework;
                  setSelectedHomework(null);
                  handleOpenEditModal(hw);
                }}
                className="px-4 py-2 text-sm font-semibold text-indigo-600 bg-indigo-50 hover:bg-indigo-100 rounded-xl transition inline-flex items-center gap-1.5"
              >
                <Edit className="w-4 h-4" /> Edit
              </button>
              <button
                onClick={() => setSelectedHomework(null)}
                className="px-5 py-2 text-sm font-semibold text-slate-700 bg-white border border-slate-200 hover:bg-slate-100 rounded-xl transition"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Add / Upload Homework Modal */}
      {isAddModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm animate-fade-in">
          <div className="bg-white w-full max-w-xl rounded-2xl shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[92vh]">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-slate-50">
              <div>
                <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                  <Plus className="w-5 h-5 text-indigo-600" />
                  Assign & Upload Homework
                </h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Distribute new homework or tasks to any class and section.
                </p>
              </div>
              <button
                onClick={() => setIsAddModalOpen(false)}
                className="text-slate-400 hover:text-slate-600 p-1 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleCreateHomework} className="flex-1 overflow-y-auto p-6 space-y-4">
              {/* Class & Section Selection */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Select Class <span className="text-rose-500">*</span>
                  </label>
                  <select
                    required
                    value={formData.class_id}
                    onChange={(e) => {
                      const newClassId = e.target.value;
                      const cls = classes.find((c) => c.id === newClassId);
                      const firstSec = cls?.sections?.[0]?.id || '';
                      setFormData({
                        ...formData,
                        class_id: newClassId,
                        section_id: firstSec,
                      });
                    }}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="" disabled>Choose Class</option>
                    {classes.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Select Section <span className="text-rose-500">*</span>
                  </label>
                  <select
                    required
                    value={formData.section_id}
                    onChange={(e) => setFormData({ ...formData, section_id: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="" disabled>Choose Section</option>
                    {formAvailableSections.map((s) => (
                      <option key={s.id} value={s.id}>
                        Section {s.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Subject & Assigning Staff */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Subject <span className="text-rose-500">*</span>
                  </label>
                  <select
                    required
                    value={formData.subject_id}
                    onChange={(e) => setFormData({ ...formData, subject_id: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="" disabled>Choose Subject</option>
                    {subjects.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.name} ({s.code})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Assigned By (Staff/Teacher)
                  </label>
                  <select
                    value={formData.staff_id}
                    onChange={(e) => setFormData({ ...formData, staff_id: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="">Default (Admin / Self)</option>
                    {staffList.map((st) => (
                      <option key={st.id} value={st.id}>
                        {st.staff_name} {st.employee_code ? `(${st.employee_code})` : ''}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Homework Title */}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Homework Title <span className="text-rose-500">*</span>
                </label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Chapter 4 Practice Problems, Science Lab Report"
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              {/* Assigned Date & Due Date */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Assigned Date <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.assigned_date}
                    onChange={(e) => setFormData({ ...formData, assigned_date: e.target.value })}
                    className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Submission Due Date <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.due_date}
                    onChange={(e) => setFormData({ ...formData, due_date: e.target.value })}
                    className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>

              {/* Description / Instructions */}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Instructions & Detailed Description
                </label>
                <textarea
                  rows={4}
                  placeholder="Enter detailed homework instructions, page numbers, or submission guidelines..."
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                />
              </div>

              {/* 5 MB Attachment Upload Control */}
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="block text-xs font-semibold text-slate-700">
                    Assignment Attachment (Optional)
                  </label>
                  <span className="text-[11px] font-medium text-slate-400">Max 5 MB (JPG, PNG, WebP, PDF)</span>
                </div>

                {!addAttachmentFile ? (
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {/* Option 1: Browse from System/Files */}
                    <label className="flex flex-col items-center justify-center p-3.5 border-2 border-dashed border-slate-200 hover:border-indigo-400 rounded-xl cursor-pointer bg-slate-50/60 hover:bg-indigo-50/30 transition group text-center">
                      <div className="w-8 h-8 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600 mb-1.5 group-hover:scale-110 transition-transform">
                        <Upload className="w-4 h-4" />
                      </div>
                      <span className="text-xs font-semibold text-slate-700">Browse System File</span>
                      <p className="text-[10px] text-slate-400 mt-0.5">JPG, PNG, PDF (Max 5 MB)</p>
                      <input
                        type="file"
                        accept=".jpg,.jpeg,.png,.webp,.pdf,image/jpeg,image/png,image/webp,application/pdf"
                        className="hidden"
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (!file) return;
                          if (file.size > 5 * 1024 * 1024) {
                            setAddAttachmentError(`File size (${(file.size / (1024 * 1024)).toFixed(1)} MB) exceeds strict 5 MB limit.`);
                            return;
                          }
                          const allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
                          const ext = file.name.split('.').pop()?.toLowerCase();
                          if (!ext || !allowedExts.includes(ext)) {
                            setAddAttachmentError('Only JPG, PNG, WebP images and PDF documents are allowed.');
                            return;
                          }
                          setAddAttachmentError(null);
                          setAddAttachmentFile(file);
                        }}
                      />
                    </label>

                    {/* Option 2: Live Camera Snapshot */}
                    <button
                      type="button"
                      onClick={() => startCamera('ADD')}
                      className="flex flex-col items-center justify-center p-3.5 border-2 border-dashed border-slate-200 hover:border-emerald-400 rounded-xl cursor-pointer bg-slate-50/60 hover:bg-emerald-50/30 transition group text-center"
                    >
                      <div className="w-8 h-8 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600 mb-1.5 group-hover:scale-110 transition-transform">
                        <Camera className="w-4 h-4" />
                      </div>
                      <span className="text-xs font-semibold text-slate-700">Take Live Photo</span>
                      <p className="text-[10px] text-slate-400 mt-0.5">Click photo with camera</p>
                    </button>
                  </div>
                ) : (
                  <div className="p-3 bg-indigo-50/60 border border-indigo-200/80 rounded-xl flex items-center justify-between">
                    <div className="flex items-center gap-2.5 min-w-0">
                      <div className="w-8 h-8 rounded-lg bg-indigo-100 flex items-center justify-center text-indigo-600 flex-shrink-0">
                        {addAttachmentFile.type.includes('pdf') || addAttachmentFile.name.endsWith('.pdf') ? (
                          <FileText className="w-4 h-4 text-red-600" />
                        ) : (
                          <Paperclip className="w-4 h-4 text-indigo-600" />
                        )}
                      </div>
                      <div className="min-w-0">
                        <p className="text-xs font-semibold text-slate-800 truncate max-w-[280px]">
                          {addAttachmentFile.name}
                        </p>
                        <p className="text-[11px] text-slate-500">
                          {(addAttachmentFile.size / (1024 * 1024)).toFixed(2)} MB • Ready to upload
                        </p>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => {
                        setAddAttachmentFile(null);
                        setAddAttachmentError(null);
                      }}
                      className="p-1 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 transition"
                      title="Remove selected file [x]"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                )}

                {addAttachmentError && (
                  <p className="mt-1.5 text-xs text-red-600 flex items-center gap-1 font-medium">
                    <AlertCircle className="w-3.5 h-3.5 flex-shrink-0" />
                    {addAttachmentError}
                  </p>
                )}
              </div>

              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsAddModalOpen(false)}
                  className="px-4 py-2 border border-slate-200 text-slate-600 rounded-xl text-sm font-medium hover:bg-slate-50 transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="inline-flex items-center gap-2 px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-sm font-semibold shadow-sm transition disabled:opacity-50"
                >
                  {saving && <Loader2 className="w-4 h-4 animate-spin" />}
                  Assign Homework
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Edit Homework Modal */}
      {isEditModalOpen && editingHomework && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-sm animate-fade-in">
          <div className="bg-white w-full max-w-xl rounded-2xl shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[92vh]">
            <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-slate-50">
              <div>
                <h2 className="text-lg font-bold text-slate-800 flex items-center gap-2">
                  <Edit className="w-5 h-5 text-indigo-600" />
                  Edit Homework Assignment
                </h2>
                <p className="text-xs text-slate-500 mt-0.5">
                  Modify homework title, instructions, deadlines, or target classroom.
                </p>
              </div>
              <button
                onClick={() => setIsEditModalOpen(false)}
                className="text-slate-400 hover:text-slate-600 p-1 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleUpdateHomework} className="flex-1 overflow-y-auto p-6 space-y-4">
              {/* Class & Section Selection */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Select Class <span className="text-rose-500">*</span>
                  </label>
                  <select
                    required
                    value={formData.class_id}
                    onChange={(e) => {
                      const newClassId = e.target.value;
                      const cls = classes.find((c) => c.id === newClassId);
                      const firstSec = cls?.sections?.[0]?.id || '';
                      setFormData({
                        ...formData,
                        class_id: newClassId,
                        section_id: firstSec,
                      });
                    }}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    {classes.map((c) => (
                      <option key={c.id} value={c.id}>
                        {c.name}
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Select Section <span className="text-rose-500">*</span>
                  </label>
                  <select
                    required
                    value={formData.section_id}
                    onChange={(e) => setFormData({ ...formData, section_id: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    {formAvailableSections.map((s) => (
                      <option key={s.id} value={s.id}>
                        Section {s.name}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Subject & Assigning Staff */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Subject <span className="text-rose-500">*</span>
                  </label>
                  <select
                    required
                    value={formData.subject_id}
                    onChange={(e) => setFormData({ ...formData, subject_id: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    {subjects.map((s) => (
                      <option key={s.id} value={s.id}>
                        {s.name} ({s.code})
                      </option>
                    ))}
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Assigned By (Staff/Teacher)
                  </label>
                  <select
                    value={formData.staff_id}
                    onChange={(e) => setFormData({ ...formData, staff_id: e.target.value })}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  >
                    <option value="">Default (Admin / Self)</option>
                    {staffList.map((st) => (
                      <option key={st.id} value={st.id}>
                        {st.staff_name} {st.employee_code ? `(${st.employee_code})` : ''}
                      </option>
                    ))}
                  </select>
                </div>
              </div>

              {/* Homework Title */}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Homework Title <span className="text-rose-500">*</span>
                </label>
                <input
                  type="text"
                  required
                  value={formData.title}
                  onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                  className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                />
              </div>

              {/* Assigned Date & Due Date */}
              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Assigned Date <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.assigned_date}
                    onChange={(e) => setFormData({ ...formData, assigned_date: e.target.value })}
                    className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                    Submission Due Date <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="date"
                    required
                    value={formData.due_date}
                    onChange={(e) => setFormData({ ...formData, due_date: e.target.value })}
                    className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500"
                  />
                </div>
              </div>

              {/* Description / Instructions */}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1.5">
                  Instructions & Detailed Description
                </label>
                <textarea
                  rows={4}
                  value={formData.description}
                  onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                  className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-indigo-500 resize-none"
                />
              </div>

              {/* 5 MB Attachment Control in Edit Modal */}
              <div>
                <div className="flex items-center justify-between mb-1.5">
                  <label className="block text-xs font-semibold text-slate-700">
                    Assignment Attachment
                  </label>
                  <span className="text-[11px] font-medium text-slate-400">Max 5 MB (JPG, PNG, WebP, PDF)</span>
                </div>

                {/* Case 1: Existing attachment present and not replaced yet */}
                {editAttachmentName && !editAttachmentFile ? (
                  <div className="p-3 bg-slate-50 border border-slate-200 rounded-xl flex items-center justify-between">
                    <div className="flex items-center gap-2.5 min-w-0">
                      <div className="w-8 h-8 rounded-lg bg-indigo-50 border border-indigo-100 flex items-center justify-center text-indigo-600 flex-shrink-0">
                        {editAttachmentName.endsWith('.pdf') ? (
                          <FileText className="w-4 h-4 text-red-600" />
                        ) : (
                          <Paperclip className="w-4 h-4 text-indigo-600" />
                        )}
                      </div>
                      <div className="min-w-0">
                        <p className="text-xs font-semibold text-slate-800 truncate max-w-[200px]">
                          {editAttachmentName}
                        </p>
                        <span className="inline-block text-[10px] text-indigo-700 bg-indigo-50 font-medium px-1.5 py-0.5 rounded">
                          Current Cloudinary File
                        </span>
                      </div>
                    </div>

                    <div className="flex items-center gap-1.5">
                      {editAttachmentKey && (
                        <a
                          href={editAttachmentKey.startsWith('http') ? editAttachmentKey : `http://localhost:5001/api/v1/homework/${editingHomework?.id}/attachment-download`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="px-2.5 py-1 text-xs font-medium text-indigo-600 hover:text-indigo-800 hover:bg-indigo-50 rounded-lg flex items-center gap-1 transition"
                        >
                          <Eye className="w-3.5 h-3.5" />
                          View
                        </a>
                      )}
                      <label className="px-2.5 py-1 text-xs font-medium text-slate-600 hover:text-slate-900 hover:bg-slate-100 rounded-lg cursor-pointer flex items-center gap-1 transition">
                        <Upload className="w-3.5 h-3.5" />
                        Replace
                        <input
                          type="file"
                          accept=".jpg,.jpeg,.png,.webp,.pdf,image/jpeg,image/png,image/webp,application/pdf"
                          className="hidden"
                          onChange={(e) => {
                            const file = e.target.files?.[0];
                            if (!file) return;
                            if (file.size > 5 * 1024 * 1024) {
                              setEditAttachmentError(`File size (${(file.size / (1024 * 1024)).toFixed(1)} MB) exceeds strict 5 MB limit.`);
                              return;
                            }
                            const allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
                            const ext = file.name.split('.').pop()?.toLowerCase();
                            if (!ext || !allowedExts.includes(ext)) {
                              setEditAttachmentError('Only JPG, PNG, WebP images and PDF documents are allowed.');
                              return;
                            }
                            setEditAttachmentError(null);
                            setEditAttachmentFile(file);
                          }}
                        />
                      </label>
                      <button
                        type="button"
                        onClick={() => startCamera('EDIT')}
                        className="px-2.5 py-1 text-xs font-medium text-emerald-600 hover:text-emerald-800 hover:bg-emerald-50 rounded-lg flex items-center gap-1 transition"
                        title="Click new photo with camera"
                      >
                        <Camera className="w-3.5 h-3.5" />
                        Camera
                      </button>
                      <button
                        type="button"
                        onClick={() => {
                          setEditAttachmentName(null);
                          setEditAttachmentKey(null);
                          setEditAttachmentFile(null);
                          setEditAttachmentError(null);
                        }}
                        className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition"
                        title="Delete attachment from homework"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>
                ) : editAttachmentFile ? (
                  /* Case 2: New replacement file selected */
                  <div className="p-3 bg-indigo-50/60 border border-indigo-200/80 rounded-xl flex items-center justify-between">
                    <div className="flex items-center gap-2.5 min-w-0">
                      <div className="w-8 h-8 rounded-lg bg-indigo-100 flex items-center justify-center text-indigo-600 flex-shrink-0">
                        {editAttachmentFile.type.includes('pdf') || editAttachmentFile.name.endsWith('.pdf') ? (
                          <FileText className="w-4 h-4 text-red-600" />
                        ) : (
                          <Paperclip className="w-4 h-4 text-indigo-600" />
                        )}
                      </div>
                      <div className="min-w-0">
                        <p className="text-xs font-semibold text-slate-800 truncate max-w-[260px]">
                          {editAttachmentFile.name}
                        </p>
                        <p className="text-[11px] text-slate-500">
                          {(editAttachmentFile.size / (1024 * 1024)).toFixed(2)} MB • Will replace on save
                        </p>
                      </div>
                    </div>
                    <button
                      type="button"
                      onClick={() => {
                        setEditAttachmentFile(null);
                        setEditAttachmentError(null);
                        if (editingHomework?.attachment_name) {
                          setEditAttachmentName(editingHomework.attachment_name);
                          setEditAttachmentKey(editingHomework.s3_attachment_key);
                        }
                      }}
                      className="p-1 rounded-lg text-slate-400 hover:text-red-600 hover:bg-red-50 transition"
                      title="Cancel replacement [x]"
                    >
                      <X className="w-4 h-4" />
                    </button>
                  </div>
                ) : (
                  /* Case 3: No attachment currently */
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {/* Option 1: Browse from System/Files */}
                    <label className="flex flex-col items-center justify-center p-3.5 border-2 border-dashed border-slate-200 hover:border-indigo-400 rounded-xl cursor-pointer bg-slate-50/60 hover:bg-indigo-50/30 transition group text-center">
                      <div className="w-8 h-8 rounded-full bg-indigo-50 flex items-center justify-center text-indigo-600 mb-1.5 group-hover:scale-110 transition-transform">
                        <Upload className="w-4 h-4" />
                      </div>
                      <span className="text-xs font-semibold text-slate-700">Browse System File</span>
                      <p className="text-[10px] text-slate-400 mt-0.5">JPG, PNG, PDF (Max 5 MB)</p>
                      <input
                        type="file"
                        accept=".jpg,.jpeg,.png,.webp,.pdf,image/jpeg,image/png,image/webp,application/pdf"
                        className="hidden"
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (!file) return;
                          if (file.size > 5 * 1024 * 1024) {
                            setEditAttachmentError(`File size (${(file.size / (1024 * 1024)).toFixed(1)} MB) exceeds strict 5 MB limit.`);
                            return;
                          }
                          const allowedExts = ['jpg', 'jpeg', 'png', 'webp', 'pdf'];
                          const ext = file.name.split('.').pop()?.toLowerCase();
                          if (!ext || !allowedExts.includes(ext)) {
                            setEditAttachmentError('Only JPG, PNG, WebP images and PDF documents are allowed.');
                            return;
                          }
                          setEditAttachmentError(null);
                          setEditAttachmentFile(file);
                        }}
                      />
                    </label>

                    {/* Option 2: Live Camera Snapshot */}
                    <button
                      type="button"
                      onClick={() => startCamera('EDIT')}
                      className="flex flex-col items-center justify-center p-3.5 border-2 border-dashed border-slate-200 hover:border-emerald-400 rounded-xl cursor-pointer bg-slate-50/60 hover:bg-emerald-50/30 transition group text-center"
                    >
                      <div className="w-8 h-8 rounded-full bg-emerald-50 flex items-center justify-center text-emerald-600 mb-1.5 group-hover:scale-110 transition-transform">
                        <Camera className="w-4 h-4" />
                      </div>
                      <span className="text-xs font-semibold text-slate-700">Take Live Photo</span>
                      <p className="text-[10px] text-slate-400 mt-0.5">Click photo with camera</p>
                    </button>
                  </div>
                )}

                {editAttachmentError && (
                  <p className="mt-1.5 text-xs text-red-600 flex items-center gap-1 font-medium">
                    <AlertCircle className="w-3.5 h-3.5 flex-shrink-0" />
                    {editAttachmentError}
                  </p>
                )}
              </div>

              <div className="flex items-center justify-end gap-3 pt-4 border-t border-slate-100">
                <button
                  type="button"
                  onClick={() => setIsEditModalOpen(false)}
                  className="px-4 py-2 border border-slate-200 text-slate-600 rounded-xl text-sm font-medium hover:bg-slate-50 transition"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={saving}
                  className="inline-flex items-center gap-2 px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-sm font-semibold shadow-sm transition disabled:opacity-50"
                >
                  {saving && <Loader2 className="w-4 h-4 animate-spin" />}
                  Save Changes
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Live Camera Snapshot Modal */}
      {isCameraOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/75 backdrop-blur-xs p-4 animate-in fade-in duration-150">
          <div className="bg-white rounded-2xl w-full max-w-lg overflow-hidden shadow-2xl flex flex-col">
            <div className="px-5 py-4 border-b border-slate-100 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
                  <Camera className="w-4 h-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-800">Live Camera Snapshot</h3>
                  <p className="text-xs text-slate-400">Position the assignment document or notebook</p>
                </div>
              </div>
              <button
                type="button"
                onClick={stopCamera}
                className="p-1.5 rounded-lg text-slate-400 hover:text-slate-600 hover:bg-slate-100 transition"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-4 bg-slate-950 flex flex-col items-center justify-center relative min-h-[300px]">
              {cameraError ? (
                <div className="p-4 text-center max-w-sm">
                  <AlertCircle className="w-8 h-8 text-rose-500 mx-auto mb-2" />
                  <p className="text-xs text-slate-200">{cameraError}</p>
                </div>
              ) : (
                <video
                  ref={videoRef}
                  autoPlay
                  playsInline
                  muted
                  className="w-full rounded-xl max-h-[360px] object-cover"
                />
              )}
            </div>

            <div className="px-5 py-3.5 bg-slate-50 border-t border-slate-100 flex items-center justify-between">
              <button
                type="button"
                onClick={stopCamera}
                className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl transition"
              >
                Cancel
              </button>
              {!cameraError && (
                <button
                  type="button"
                  onClick={capturePhoto}
                  className="inline-flex items-center gap-2 px-5 py-2 bg-emerald-600 hover:bg-emerald-700 text-white rounded-xl text-xs font-semibold shadow-sm transition"
                >
                  <Camera className="w-4 h-4" />
                  Capture Photo
                </button>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
