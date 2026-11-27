import {
  DashboardSummaryResponse,
  GreensheetResponse,
  LoginResponse,
  SubjectItem,
  SubjectMasterItem,
  TimetableGridResponse,
  TimetableSlotEntry,
  ExamItem,
  ClassItem,
  AdminNoticeItem,
  SuperAdminMetrics,
  SchoolRecord,
  OnboardSchoolPayload,
} from './types';

export const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || 'https://school-erp-backend-du5v.onrender.com/api/v1';

export class ApiError extends Error {
  statusCode: number;
  details?: any;

  constructor(message: string, statusCode: number, details?: any) {
    super(message);
    this.name = 'ApiError';
    this.statusCode = statusCode;
    this.details = details;
  }
}

function getToken(): string | null {
  if (typeof window === 'undefined') return null;
  return localStorage.getItem('school_erp_token');
}

export function setSession(token: string, user: any) {
  if (typeof window === 'undefined') return;
  localStorage.setItem('school_erp_token', token);
  localStorage.setItem('school_erp_user', JSON.stringify(user));
  // Set cookie for quick check if needed
  document.cookie = `school_erp_token=${token}; path=/; max-age=604800; SameSite=Lax`;
}

export function clearSession() {
  if (typeof window === 'undefined') return;
  localStorage.removeItem('school_erp_token');
  localStorage.removeItem('school_erp_user');
  document.cookie = 'school_erp_token=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT';
}

export function getCurrentUser(): any | null {
  if (typeof window === 'undefined') return null;
  const raw = localStorage.getItem('school_erp_user');
  if (!raw) return null;
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

async function request<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;
  const token = getToken();

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const response = await fetch(url, {
    ...options,
    headers,
  });

  const json = await response.json().catch(() => ({}));

  if (!response.ok) {
    if (response.status === 401 && typeof window !== 'undefined') {
      clearSession();
      if (!window.location.pathname.includes('/login')) {
        window.location.href = '/login';
      }
    }
    throw new ApiError(
      json.error || json.message || `Request failed with status ${response.status}`,
      response.status,
      json.details
    );
  }

  return json.data !== undefined ? json.data : json;
}

export const api = {
  // Auth
  auth: {
    login: async (identifier: string, password: string): Promise<LoginResponse['data']> => {
      const res = await request<LoginResponse['data']>('/auth/login', {
        method: 'POST',
        body: JSON.stringify({ identifier, password }),
      });
      return res;
    },

    getForgotRequirements: async (
      identifier: string
    ): Promise<{
      userType: string;
      identifier: string;
      maskedPhone?: string;
      maskedDob?: string;
      prompt: string;
    }> => {
      return request<{
        userType: string;
        identifier: string;
        maskedPhone?: string;
        maskedDob?: string;
        prompt: string;
      }>(`/auth/forgot-password/requirements?identifier=${encodeURIComponent(identifier)}`);
    },

    verifyForgotChallenge: async (payload: {
      identifier: string;
      phone?: string;
      dob?: string;
      email?: string;
    }): Promise<{
      resetToken: string;
      userType: string;
      name: string;
    }> => {
      return request<{
        resetToken: string;
        userType: string;
        name: string;
      }>('/auth/forgot-password/verify', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    resetPasswordWithToken: async (
      resetToken: string,
      newPassword: string
    ): Promise<{ message: string }> => {
      return request<{ message: string }>('/auth/forgot-password/reset', {
        method: 'POST',
        body: JSON.stringify({ resetToken, newPassword }),
      });
    },
  },

  // Admin Command Center & Core
  admin: {
    getDashboardSummary: async (
      params?: string | { date?: string; classId?: string; sectionId?: string; month?: string }
    ): Promise<DashboardSummaryResponse> => {
      if (typeof params === 'string') {
        const query = params ? `?date=${encodeURIComponent(params)}` : '';
        return request<DashboardSummaryResponse>(`/admin/dashboard/summary${query}`);
      }
      const q = new URLSearchParams();
      if (params?.date) q.append('date', params.date);
      if (params?.classId && params.classId !== 'ALL') q.append('class_id', params.classId);
      if (params?.sectionId && params.sectionId !== 'ALL') q.append('section_id', params.sectionId);
      if (params?.month && params.month !== 'CURRENT') q.append('month', params.month);
      const queryStr = q.toString() ? `?${q.toString()}` : '';
      return request<DashboardSummaryResponse>(`/admin/dashboard/summary${queryStr}`);
    },

    getTimetableGrid: async (
      classId: string,
      sectionId: string
    ): Promise<TimetableGridResponse> => {
      return request<TimetableGridResponse>(
        `/admin/timetable/grid?class_id=${encodeURIComponent(classId)}&section_id=${encodeURIComponent(sectionId)}`
      );
    },

    saveTimetableGrid: async (payload: {
      class_id: string;
      section_id: string;
      academic_year_id?: string;
      slots: TimetableSlotEntry[];
    }): Promise<TimetableGridResponse> => {
      return request<TimetableGridResponse>('/admin/timetable/grid', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    getGreensheet: async (
      classId: string,
      sectionId: string,
      examId?: string
    ): Promise<GreensheetResponse> => {
      const examQuery = examId ? `&exam_id=${encodeURIComponent(examId)}` : '';
      return request<GreensheetResponse>(
        `/admin/reports/greensheet?class_id=${encodeURIComponent(classId)}&section_id=${encodeURIComponent(sectionId)}${examQuery}`
      );
    },

    getTeachers: async (): Promise<any[]> => {
      return request<any[]>('/admin/staff/teachers');
    },

    getTeacherTimetable: async (teacherId: string): Promise<any[]> => {
      return request<any[]>(`/admin/timetable/teacher/${encodeURIComponent(teacherId)}`);
    },

    getSubstitutions: async (date?: string): Promise<any[]> => {
      const query = date ? `?date=${encodeURIComponent(date)}` : '';
      return request<any[]>(`/admin/timetable/substitutions${query}`);
    },

    assignSubstitution: async (payload: {
      timetable_slot_id: string;
      substitution_date: string;
      original_teacher_id: string;
      substitute_teacher_id: string;
      remarks?: string;
    }): Promise<any> => {
      return request('/admin/timetable/substitutions', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    deleteSubstitution: async (id: string): Promise<any> => {
      return request(`/admin/timetable/substitutions/${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
    },

    getStudents: async (filters?: {
      class_id?: string;
      section_id?: string;
      class_ids?: string[];
      section_ids?: string[];
      search?: string;
    }): Promise<any[]> => {
      const params = new URLSearchParams();
      if (filters?.class_id) params.set('class_id', filters.class_id);
      if (filters?.section_id) params.set('section_id', filters.section_id);
      if (filters?.class_ids && filters.class_ids.length > 0) {
        params.set('class_ids', filters.class_ids.join(','));
      }
      if (filters?.section_ids && filters.section_ids.length > 0) {
        params.set('section_ids', filters.section_ids.join(','));
      }
      if (filters?.search) params.set('search', filters.search);
      const qs = params.toString() ? `?${params.toString()}` : '';
      return request<any[]>(`/admin/students${qs}`);
    },

    createStudent: async (payload: any): Promise<any> => {
      return request<any>('/admin/students', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    bulkUploadStudents: async (students: any[]): Promise<any> => {
      return request<any>('/admin/students/bulk-upload', {
        method: 'POST',
        body: JSON.stringify({ students }),
      });
    },

    getStudentDetails: async (id: string): Promise<any> => {
      return request<any>(`/admin/students/${encodeURIComponent(id)}`);
    },

    updateStudent: async (id: string, payload: any): Promise<any> => {
      return request<any>(`/admin/students/${encodeURIComponent(id)}`, {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
    },

    uploadPhoto: async (file: File): Promise<{
      photoUrl: string;
      publicId?: string;
      format?: string;
      bytes?: number;
    }> => {
      const token = getToken();
      const formData = new FormData();
      formData.append('photo', file);
      const url = `${API_BASE_URL}/admin/upload/photo`;
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: formData,
      });
      const json = await response.json().catch(() => ({}));
      if (!response.ok) {
        throw new ApiError(
          json.error || json.message || 'Failed to upload photo',
          response.status,
          json.details
        );
      }
      return json.data;
    },

    updateStudentPhoto: async (id: string, photo_url: string): Promise<any> => {
      return request<any>(`/admin/students/${encodeURIComponent(id)}/photo`, {
        method: 'PATCH',
        body: JSON.stringify({ photo_url }),
      });
    },

    deleteStudentPhoto: async (id: string): Promise<any> => {
      return request<any>(`/admin/students/${encodeURIComponent(id)}/photo`, {
        method: 'DELETE',
      });
    },

    resetStudentPassword: async (id: string, password?: string): Promise<any> => {
      return request<any>(`/admin/students/${encodeURIComponent(id)}/reset-password`, {
        method: 'POST',
        body: JSON.stringify({ password }),
      });
    },

    resetStaffPassword: async (id: string, password?: string): Promise<any> => {
      return request<any>(`/admin/staff/${encodeURIComponent(id)}/reset-password`, {
        method: 'POST',
        body: JSON.stringify({ password }),
      });
    },

    // Staff Directory & Management
    getAllStaff: async (search?: string, isActive?: boolean): Promise<any[]> => {
      const params = new URLSearchParams();
      if (search) params.append('search', search);
      if (isActive !== undefined) params.append('is_active', String(isActive));
      const qs = params.toString() ? `?${params.toString()}` : '';
      return request<any[]>(`/admin/staff${qs}`);
    },

    createStaff: async (payload: any): Promise<any> => {
      return request('/admin/staff', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    bulkUploadStaff: async (staff: any[]): Promise<any> => {
      return request('/admin/staff/bulk-upload', {
        method: 'POST',
        body: JSON.stringify({ staff }),
      });
    },

    updateStaff: async (id: string, payload: any): Promise<any> => {
      return request(`/admin/staff/${encodeURIComponent(id)}`, {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
    },

    deleteStaff: async (id: string): Promise<any> => {
      return request(`/admin/staff/${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
    },

    // Academic Class Teacher & Subject Teacher Allocations
    getAcademicAllocations: async (): Promise<any> => {
      return request<any>('/admin/academics/allocations');
    },

    saveAcademicAllocations: async (payload: {
      class_id: string;
      section_id: string;
      class_teacher_id?: string | null;
      subject_allocations?: Array<{ subject_id: string; teacher_id: string | null }>;
    }): Promise<any> => {
      return request<any>('/admin/academics/allocations', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    // Real-Time 360-Degree Dashboard Inspection
    getStudentInspection: async (id: string): Promise<any> => {
      return request<any>(`/admin/dashboard/student-inspect/${encodeURIComponent(id)}`);
    },

    getTeacherInspection: async (id: string): Promise<any> => {
      return request<any>(`/admin/dashboard/teacher-inspect/${encodeURIComponent(id)}`);
    },

    // Homework Management (View & Assign)
    getHomework: async (filters?: {
      class_id?: string;
      section_id?: string;
      subject_id?: string;
      search?: string;
    }): Promise<any[]> => {
      const params = new URLSearchParams();
      if (filters?.class_id) params.set('class_id', filters.class_id);
      if (filters?.section_id) params.set('section_id', filters.section_id);
      if (filters?.subject_id) params.set('subject_id', filters.subject_id);
      if (filters?.search) params.set('search', filters.search);
      const qs = params.toString() ? `?${params.toString()}` : '';
      return request<any[]>(`/admin/homework${qs}`);
    },

    createHomework: async (payload: {
      class_id: string;
      section_id: string;
      subject_id: string;
      staff_id?: string;
      title: string;
      description?: string;
      assigned_date?: string;
      due_date: string;
      attachment_name?: string;
      attachmentName?: string;
      s3_attachment_key?: string;
      s3AttachmentKey?: string;
    }): Promise<any> => {
      return request('/admin/homework', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    updateHomework: async (
      id: string,
      payload: {
        class_id?: string;
        section_id?: string;
        subject_id?: string;
        staff_id?: string;
        title?: string;
        description?: string;
        assigned_date?: string;
        due_date?: string;
        attachment_name?: string;
        attachmentName?: string;
        s3_attachment_key?: string;
        s3AttachmentKey?: string;
      }
    ): Promise<any> => {
      return request(`/admin/homework/${encodeURIComponent(id)}`, {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
    },

    deleteHomework: async (id: string): Promise<any> => {
      return request(`/admin/homework/${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
    },

    uploadHomeworkAttachment: async (file: File): Promise<{
      fileKey: string;
      attachmentUrl: string;
      attachmentName: string;
      sizeBytes: number;
      format: string;
    }> => {
      const token = getToken();
      const url = `${API_BASE_URL}/homework/attachment-upload?fileName=${encodeURIComponent(file.name)}`;
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': file.type || 'application/octet-stream',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: file,
      });
      const json = await response.json().catch(() => ({}));
      if (!response.ok) {
        throw new ApiError(
          json.error || json.message || 'Failed to upload homework attachment',
          response.status,
          json.details
        );
      }
      return json.data;
    },

    // Feedback & Complaints
    getFeedback: async (): Promise<{ feedback: any[]; complaints: any[] }> => {
      return request<{ feedback: any[]; complaints: any[] }>('/admin/feedback');
    },

    updateComplaintStatus: async (
      id: string,
      payload: { status: string; resolution_notes?: string }
    ): Promise<any> => {
      return request(`/admin/complaints/${encodeURIComponent(id)}`, {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
    },

    // Study Materials & Academic Repository (Live sync with Student & Teacher Apps)
    getMaterials: async (filters?: {
      class_id?: string;
      section_id?: string;
      subject_id?: string;
      type?: string;
      search?: string;
    }): Promise<any[]> => {
      const params = new URLSearchParams();
      if (filters?.class_id) params.set('class_id', filters.class_id);
      if (filters?.section_id) params.set('section_id', filters.section_id);
      if (filters?.subject_id) params.set('subject_id', filters.subject_id);
      if (filters?.type && filters.type !== 'ALL') params.set('type', filters.type);
      if (filters?.search) params.set('search', filters.search);
      const qs = params.toString() ? `?${params.toString()}` : '';
      return request<any[]>(`/admin/materials${qs}`);
    },

    uploadMaterialFile: async (file: File): Promise<{
      fileKey: string;
      fileUrl: string;
      fileName: string;
      sizeBytes: number;
      contentType: string;
    }> => {
      const token = getToken();
      const url = `${API_BASE_URL}/materials/upload?fileName=${encodeURIComponent(file.name)}`;
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'Content-Type': file.type || 'application/octet-stream',
          ...(token ? { Authorization: `Bearer ${token}` } : {}),
        },
        body: file,
      });
      const json = await response.json().catch(() => ({}));
      if (!response.ok) {
        throw new ApiError(
          json.error || json.message || 'Failed to upload study material file',
          response.status,
          json.details
        );
      }
      return json.data;
    },

    createMaterial: async (payload: {
      class_id: string;
      section_id?: string;
      subject_id: string;
      staff_id?: string;
      title: string;
      description?: string;
      material_type?: string;
      file_name: string;
      file_size_bytes?: number;
      content_type?: string;
      s3_file_key?: string;
    }): Promise<any> => {
      return request('/admin/materials', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    updateMaterial: async (
      id: string,
      payload: {
        class_id?: string;
        section_id?: string | null;
        subject_id?: string;
        title?: string;
        description?: string;
        material_type?: string;
        file_name?: string;
      }
    ): Promise<any> => {
      return request(`/admin/materials/${encodeURIComponent(id)}`, {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
    },

    deleteMaterial: async (id: string): Promise<any> => {
      return request(`/admin/materials/${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
    },

    getMaterialDownloadUrl: async (id: string): Promise<{ downloadUrl: string; fileName: string; isMock: boolean }> => {
      return request<{ downloadUrl: string; fileName: string; isMock: boolean }>(`/materials/${encodeURIComponent(id)}/download-url`);
    },

    getTenantConfig: async (): Promise<any> => {
      return request('/admin/tenant-config');
    },

    updateTenantConfig: async (payload: { name?: string; contactEmail?: string; contactPhone?: string; address?: string; branding?: any; features?: any }): Promise<any> => {
      return request('/admin/tenant-config', {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
    },
  },

  // Academics & Exams Lookups
  academics: {
    getSubjects: async (): Promise<SubjectItem[]> => {
      return request<SubjectItem[]>('/academics/subjects');
    },
    getSubjectsMaster: async (): Promise<SubjectMasterItem[]> => {
      return request<SubjectMasterItem[]>('/academics/subjects/master');
    },
    createSubject: async (payload: { name: string; code: string; type?: string; class_ids?: string[] }): Promise<any> => {
      return request<any>('/academics/subjects', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },
    updateSubject: async (id: string, payload: { name?: string; code?: string; type?: string; is_active?: boolean; class_ids?: string[] }): Promise<any> => {
      return request<any>(`/academics/subjects/${encodeURIComponent(id)}`, {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
    },
    deleteSubject: async (id: string): Promise<any> => {
      return request<any>(`/academics/subjects/${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
    },
    getClasses: async (): Promise<ClassItem[]> => {
      return request<ClassItem[]>('/academics/classes');
    },
  },

  exams: {
    list: async (): Promise<ExamItem[]> => {
      return request<ExamItem[]>('/exams');
    },
  },

  // Notices Management (Live sync with Student and Teacher Apps)
  notices: {
    list: async (): Promise<AdminNoticeItem[]> => {
      return request<AdminNoticeItem[]>('/notices');
    },
    create: async (data: {
      title: string;
      content: string;
      target_role?: string;
      target_class_id?: string | null;
      target_section_id?: string | null;
      target_student_id?: string | null;
      priority?: 'INFO' | 'NORMAL' | 'URGENT';
      channel?: 'IN_APP' | 'PUSH' | 'SMS' | 'EMAIL';
    }): Promise<AdminNoticeItem> => {
      return request<AdminNoticeItem>('/notices', {
        method: 'POST',
        body: JSON.stringify(data),
      });
    },
    delete: async (id: string): Promise<any> => {
      return request(`/notices/${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
    },
  },

  // Leave Management (Dual-visibility Approvals)
  leaves: {
    getStaffManagementQueue: async (filters?: {
      status?: string;
      timeframe?: string;
      search?: string;
    }): Promise<any[]> => {
      const params = new URLSearchParams();
      if (filters?.status && filters.status !== 'ALL') params.set('status', filters.status);
      if (filters?.timeframe && filters.timeframe !== 'all') params.set('timeframe', filters.timeframe);
      if (filters?.search?.trim()) params.set('search', filters.search.trim());
      const qs = params.toString() ? `?${params.toString()}` : '';
      return request<any[]>(`/leaves/staff/management-queue${qs}`);
    },

    updateStudentLeaveStatus: async (
      id: string,
      status: 'APPROVED' | 'REJECTED',
      remarks?: string
    ): Promise<any> => {
      return request(`/leaves/student/${encodeURIComponent(id)}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status, remarks }),
      });
    },

    decideStaffLeave: async (
      id: string,
      decision: 'APPROVED' | 'REJECTED',
      comment?: string
    ): Promise<any> => {
      return request(`/leaves/staff/${encodeURIComponent(id)}/decide`, {
        method: 'PATCH',
        body: JSON.stringify({ decision, comment }),
      });
    },
  },

  // Fee Management & Collections (Live sync with Student Receipts)
  fees: {
    getOverview: async (filters?: {
      class_id?: string;
      section_id?: string;
      status?: string;
      search?: string;
    }): Promise<{
      kpis: {
        total_receivable: number;
        total_collected: number;
        total_pending: number;
        collection_percentage: number;
      };
      records: any[];
    }> => {
      const params = new URLSearchParams();
      if (filters?.class_id) params.set('class_id', filters.class_id);
      if (filters?.section_id) params.set('section_id', filters.section_id);
      if (filters?.status) params.set('status', filters.status);
      if (filters?.search) params.set('search', filters.search);
      const qs = params.toString() ? `?${params.toString()}` : '';
      return request(`/fees/admin/overview${qs}`);
    },

    collectFee: async (payload: {
      student_id: string;
      student_fee_id?: string;
      amount_paid: number;
      payment_mode: 'CASH' | 'CHEQUE' | 'BANK_TRANSFER' | 'DEMAND_DRAFT' | 'ONLINE';
      transaction_reference?: string;
      cheque_number?: string;
      cheque_bank?: string;
      cheque_date?: string;
      idempotency_key?: string;
      remarks?: string;
    }): Promise<any> => {
      return request('/fees/admin/collect', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    getStudentCounterProfile: async (identifier: string): Promise<any> => {
      return request(`/fees/admin/counter-profile/${encodeURIComponent(identifier)}`);
    },

    getPrintableReceipt: async (id: string): Promise<any> => {
      return request(`/fees/admin/receipts/${encodeURIComponent(id)}/print`);
    },

    markChequeBounced: async (
      id: string,
      payload?: { penalty_amount?: number; reason?: string }
    ): Promise<any> => {
      return request(`/fees/admin/receipts/${encodeURIComponent(id)}/cheque-bounce`, {
        method: 'POST',
        body: JSON.stringify(payload || {}),
      });
    },

    getCurrentShift: async (): Promise<any> => {
      return request('/fees/admin/shifts/current');
    },

    closeCounterShift: async (payload: {
      physical_cash: number;
      denominations: Record<string, number>;
      closing_notes?: string;
    }): Promise<any> => {
      return request('/fees/admin/shifts/close', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    getReceipts: async (
      params?: string | { search?: string; date?: string; mode?: string }
    ): Promise<any[]> => {
      let qs = '';
      if (typeof params === 'string') {
        qs = params ? `?search=${encodeURIComponent(params)}` : '';
      } else if (params) {
        const query = new URLSearchParams();
        if (params.search) query.set('search', params.search);
        if (params.date) query.set('date', params.date);
        if (params.mode) query.set('mode', params.mode);
        const str = query.toString();
        qs = str ? `?${str}` : '';
      }
      return request<any[]>(`/fees/admin/receipts${qs}`);
    },

    assignFeeHead: async (payload: {
      class_id?: string;
      fee_title: string;
      amount: number;
      due_date: string;
    }): Promise<any> => {
      return request('/fees/admin/assign', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    // Fee Master & Configurable Structures
    getFeeHeads: async (): Promise<any[]> => {
      return request<any[]>('/fees/admin/heads');
    },

    createFeeHead: async (payload: {
      name: string;
      code: string;
      type?: string;
      is_optional?: boolean;
      description?: string;
    }): Promise<any> => {
      return request('/fees/admin/heads', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    updateFeeHead: async (
      id: string,
      payload: { name?: string; type?: string; is_optional?: boolean; description?: string }
    ): Promise<any> => {
      return request(`/fees/admin/heads/${encodeURIComponent(id)}`, {
        method: 'PUT',
        body: JSON.stringify(payload),
      });
    },

    deleteFeeHead: async (id: string): Promise<any> => {
      return request(`/fees/admin/heads/${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
    },

    getFeeCycles: async (): Promise<any[]> => {
      return request<any[]>('/fees/admin/cycles');
    },

    createFeeCycle: async (payload: {
      name: string;
      cycle_type: string;
      due_date: string;
      grace_period_days?: number;
      sequence_order?: number;
    }): Promise<any> => {
      return request('/fees/admin/cycles', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    getFeeStructures: async (): Promise<any[]> => {
      return request<any[]>('/fees/admin/structures');
    },

    getFeeStructureById: async (id: string): Promise<any> => {
      return request(`/fees/admin/structures/${encodeURIComponent(id)}`);
    },

    saveFeeStructure: async (payload: {
      id?: string;
      name: string;
      class_id?: string;
      items: Array<{ fee_head_id: string; fee_cycle_id: string; amount: number }>;
      apply_to_students?: boolean;
    }): Promise<any> => {
      return request('/fees/admin/structures', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    // Concessions & Scholarships
    getConcessions: async (studentId?: string): Promise<any[]> => {
      const qs = studentId ? `?student_id=${encodeURIComponent(studentId)}` : '';
      return request<any[]>(`/fees/admin/concessions${qs}`);
    },

    createConcession: async (payload: {
      student_id: string;
      fee_head_id?: string;
      concession_type: 'PERCENTAGE' | 'FLAT_AMOUNT';
      concession_value: number;
      reason: string;
    }): Promise<any> => {
      return request('/fees/admin/concessions', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    deleteConcession: async (id: string): Promise<any> => {
      return request(`/fees/admin/concessions/${encodeURIComponent(id)}`, {
        method: 'DELETE',
      });
    },

    // Reports: Defaulters & Day Book
    getDefaulters: async (filters?: {
      class_id?: string;
      section_id?: string;
      search?: string;
      min_days?: number;
    }): Promise<any[]> => {
      const params = new URLSearchParams();
      if (filters?.class_id) params.set('class_id', filters.class_id);
      if (filters?.section_id) params.set('section_id', filters.section_id);
      if (filters?.search) params.set('search', filters.search);
      if (filters?.min_days) params.set('min_days', String(filters.min_days));
      const qs = params.toString() ? `?${params.toString()}` : '';
      return request<any[]>(`/fees/admin/defaulters${qs}`);
    },

    getDayBook: async (date?: string): Promise<any> => {
      const qs = date ? `?date=${encodeURIComponent(date)}` : '';
      return request(`/fees/admin/day-book${qs}`);
    },

    // Standard ERP 20 Head Slots & Transport Definition
    getFeeHeadSlots: async (): Promise<{
      slots: Array<{ slot_number: number; head_name: string; is_active: boolean }>;
      transport: { head_name: string; collection_method: string };
    }> => {
      return request('/fees/admin/slots');
    },

    saveFeeHeadSlots: async (payload: {
      slots: Array<{ slot_number: number; head_name: string; is_active?: boolean }>;
      transport?: { head_name?: string; collection_method?: string };
    }): Promise<any> => {
      return request('/fees/admin/slots', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    collectExtraFee: async (payload: {
      student_id: string;
      fee_category: string;
      amount: number;
      payment_mode: string;
      remarks?: string;
    }): Promise<any> => {
      return request('/fees/admin/collect-extra', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    applyAnnualFeeCalculation: async (payload: {
      class_id: string;
      matrix: Record<string, number>;
    }): Promise<any> => {
      return request('/fees/admin/apply-annual-matrix', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },
  },

  // Attendance Management (Students & Staff)
  attendance: {
    getClassStudentAttendance: async (
      classId: string,
      sectionId: string,
      date: string
    ): Promise<any[]> => {
      return request<any[]>(
        `/attendance/student/class/${encodeURIComponent(classId)}/${encodeURIComponent(sectionId)}?date=${encodeURIComponent(date)}`
      );
    },

    markStudentAttendance: async (payload: {
      class_id: string;
      section_id: string;
      attendance_date: string;
      records: Array<{ student_id: string; status: 'PRESENT' | 'ABSENT'; remarks?: string | null }>;
    }): Promise<any> => {
      return request('/attendance/student', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    getAllStaffAttendance: async (date: string): Promise<any[]> => {
      return request<any[]>(
        `/attendance/staff/management-overview?date=${encodeURIComponent(date)}`
      );
    },

    markStaffAttendance: async (payload: {
      attendance_date: string;
      records: Array<{
        staffId: string;
        status: 'PRESENT' | 'ABSENT';
        inTime?: string | null;
        outTime?: string | null;
        remarks?: string | null;
      }>;
    }): Promise<any> => {
      return request('/attendance/staff', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },
  },

  // Level 1: Super Admin (Platform Owner)
  superAdmin: {
    getMetrics: async (): Promise<SuperAdminMetrics> => {
      return request<SuperAdminMetrics>('/super-admin/metrics');
    },

    getSchools: async (filters?: { search?: string; status?: string; plan?: string }): Promise<SchoolRecord[]> => {
      const params = new URLSearchParams();
      if (filters?.search) params.append('search', filters.search);
      if (filters?.status) params.append('status', filters.status);
      if (filters?.plan) params.append('plan', filters.plan);
      const queryStr = params.toString() ? `?${params.toString()}` : '';
      return request<SchoolRecord[]>(`/super-admin/schools${queryStr}`);
    },

    getSchoolById: async (schoolId: string): Promise<any> => {
      return request(`/super-admin/schools/${encodeURIComponent(schoolId)}`);
    },

    onboardSchool: async (payload: OnboardSchoolPayload): Promise<{ school: SchoolRecord; adminCredentials: any }> => {
      return request('/super-admin/schools', {
        method: 'POST',
        body: JSON.stringify(payload),
      });
    },

    updateSchoolStatus: async (schoolId: string, status: 'ACTIVE' | 'SUSPENDED'): Promise<any> => {
      return request(`/super-admin/schools/${encodeURIComponent(schoolId)}/status`, {
        method: 'PATCH',
        body: JSON.stringify({ status }),
      });
    },

    updateSchoolPlan: async (schoolId: string, payload: { plan: string; maxStudents?: number; subscriptionExpiresAt?: string }): Promise<any> => {
      return request(`/super-admin/schools/${encodeURIComponent(schoolId)}/plan`, {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
    },

    restoreCredentials: async (): Promise<any> => {
      return request('/super-admin/restore-credentials', {
        method: 'POST',
      });
    },

    updateSchoolConfig: async (
      schoolId: string,
      payload: {
        name?: string;
        contactEmail?: string;
        contactPhone?: string;
        address?: string;
        branding?: any;
        features?: any;
        menuConfig?: any;
      }
    ): Promise<any> => {
      return request(`/super-admin/schools/${encodeURIComponent(schoolId)}/config`, {
        method: 'PATCH',
        body: JSON.stringify(payload),
      });
    },
  },
};
