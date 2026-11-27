import { TokenPayload } from '../../types/auth.types';
import { LeavesRepository, StaffLeaveFilters, StudentLeaveFilters } from './leaves.repository';
import { NoticeService } from '../notices/notice.service';
import { pool } from '../../config/db.config';

export class LeavesService {
  private static isValidDateString(dateStr: string): boolean {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateStr)) return false;
    const d = new Date(dateStr);
    return !isNaN(d.getTime());
  }

  static async createStaffLeave(
    user: TokenPayload,
    leaveType: 'SICK' | 'CASUAL' | 'EARNED',
    startDate: string,
    endDate: string,
    reason: string,
    documentUrl?: string | null,
    attachmentName?: string | null
  ) {
    if (!user.roles.includes('TEACHER')) {
      throw new Error('FORBIDDEN_ROLE');
    }

    const staffId =
      user.profileId || (await LeavesRepository.getStaffProfileIdByUserId(user.userId));
    if (!staffId) {
      throw new Error('PROFILE_NOT_FOUND');
    }

    if (!this.isValidDateString(startDate) || !this.isValidDateString(endDate)) {
      throw new Error('INVALID_DATE');
    }

    if (new Date(endDate) < new Date(startDate)) {
      throw new Error('INVALID_DATE_RANGE');
    }

    const staff = await LeavesRepository.getStaffMemberById(staffId);
    const schoolId = staff?.school_id || user.schoolId;

    const created = await LeavesRepository.createStaffLeave(
      schoolId,
      staffId,
      leaveType,
      startDate,
      endDate,
      reason.trim(),
      documentUrl,
      attachmentName
    );

    try {
      const staffName = staff
        ? `${staff.first_name} ${staff.last_name || ''}`.trim()
        : 'Teacher';
      const empCode = staff?.employee_code ? ` (${staff.employee_code})` : '';
      const noticeUser: TokenPayload = { ...user, schoolId };
      await NoticeService.createNotice(noticeUser, {
        title: `Staff Leave Request: ${staffName}`,
        content: `${staffName}${empCode} has applied for ${leaveType} leave from ${startDate} to ${endDate}. Reason: ${reason.trim()}`,
        target_role: 'ADMIN',
        priority: 'NORMAL',
        channel: 'IN_APP',
      });
    } catch (noticeErr) {
      console.warn('[LeavesService]: Non-blocking admin leave notice failed:', noticeErr);
    }

    return (await LeavesRepository.getStaffLeaveById(created.id)) || created;
  }

  static async getStaffMyLeaves(user: TokenPayload) {
    const profileId =
      user.profileId || (await LeavesRepository.getStaffProfileIdByUserId(user.userId));
    if (!profileId) {
      throw new Error('PROFILE_NOT_FOUND');
    }
    return await LeavesRepository.getStaffLeavesByStaffId(profileId);
  }

  static async getStaffWingLeaves(user: TokenPayload) {
    if (!user.wingId) {
      throw new Error('WING_NOT_ASSIGNED');
    }
    return await LeavesRepository.getStaffLeavesByWingId(user.wingId);
  }

  static async getAllStaffLeavesForManagement(
    user: TokenPayload,
    filters?: StaffLeaveFilters
  ) {
    if (!user.roles.includes('ADMIN')) {
      throw new Error('FORBIDDEN_ROLE');
    }
    return await LeavesRepository.getAllStaffLeavesForManagement(user.schoolId, filters);
  }

  static async recommendStaffLeave(
    user: TokenPayload,
    leaveId: string,
    recommendation: string
  ) {
    if (!user.profileId || !user.wingId) {
      throw new Error('COORDINATOR_CONTEXT_MISSING');
    }

    const leave = await LeavesRepository.getStaffLeaveById(leaveId);
    if (!leave) {
      throw new Error('LEAVE_NOT_FOUND');
    }

    // Wing Scope Check: Teacher must be in Coordinator's assigned wing
    if (leave.wing_id !== user.wingId) {
      throw new Error('FORBIDDEN_SCOPE');
    }

    // Self-recommendation guard: Staff cannot recommend their own leave application
    if (leave.staff_id === user.profileId) {
      throw new Error('FORBIDDEN_SCOPE');
    }

    if (leave.status === 'APPROVED' || leave.status === 'REJECTED') {
      throw new Error('INVALID_STATE_TRANSITION');
    }

    await LeavesRepository.recommendStaffLeave(
      leaveId,
      user.profileId,
      recommendation.trim()
    );

    return await LeavesRepository.getStaffLeaveById(leaveId);
  }

  static async sanctionStaffLeave(
    user: TokenPayload,
    leaveId: string,
    decision: 'APPROVED' | 'REJECTED',
    comment: string | null
  ) {
    if (!user.roles.includes('ADMIN')) {
      throw new Error('FORBIDDEN_ROLE');
    }

    const leave = await LeavesRepository.getStaffLeaveById(leaveId);
    if (!leave) {
      throw new Error('LEAVE_NOT_FOUND');
    }

    if (user.schoolId && leave.school_id !== user.schoolId) {
      throw new Error('FORBIDDEN_SCOPE');
    }

    if (leave.status === 'APPROVED' || leave.status === 'REJECTED') {
      throw new Error('INVALID_STATE_TRANSITION');
    }

    await LeavesRepository.sanctionStaffLeave(
      leaveId,
      user.userId,
      decision,
      comment ? comment.trim() : null
    );

    const updated = await LeavesRepository.getStaffLeaveById(leaveId);

    try {
      const commentText = comment && comment.trim() ? ` Remarks: ${comment.trim()}` : '';
      await NoticeService.createNotice(user, {
        title: `Staff Leave ${decision === 'APPROVED' ? 'Approved' : 'Rejected'}: ${leave.staff_name}`,
        content: `${leave.staff_name} (${leave.employee_code}) ${leave.leave_type} leave from ${leave.start_date} to ${leave.end_date} was ${decision.toLowerCase()}.${commentText}`,
        target_role: 'TEACHER',
        priority: decision === 'APPROVED' ? 'NORMAL' : 'URGENT',
        channel: 'IN_APP',
      });
    } catch (noticeErr) {
      console.warn('[LeavesService]: Non-blocking staff decision notice failed:', noticeErr);
    }

    return updated;
  }

  static async createStudentLeave(
    user: TokenPayload,
    startDate: string,
    endDate: string,
    reason: string,
    documentUrl?: string | null,
    attachmentName?: string | null
  ) {
    if (!user.profileId) {
      throw new Error('PROFILE_NOT_FOUND');
    }

    let classId = user.classId;
    let sectionId = user.sectionId;

    if (!classId || !sectionId) {
      const enrollment = await LeavesRepository.getStudentEnrollment(user.profileId, user.schoolId);
      if (!enrollment || !enrollment.class_id || !enrollment.section_id) {
        throw new Error('STUDENT_ENROLLMENT_NOT_FOUND');
      }
      classId = enrollment.class_id;
      sectionId = enrollment.section_id;
    }

    if (!this.isValidDateString(startDate) || !this.isValidDateString(endDate)) {
      throw new Error('INVALID_DATE');
    }

    if (new Date(endDate) < new Date(startDate)) {
      throw new Error('INVALID_DATE_RANGE');
    }

    const createdLeave = await LeavesRepository.createStudentLeave(
      user.schoolId,
      user.profileId,
      classId,
      sectionId,
      startDate,
      endDate,
      reason.trim(),
      documentUrl || null,
      attachmentName || null
    );

    // Trigger in-app notice to Class Teacher / School Staff
    try {
      const { rows: stpRows } = await pool.query(
        `SELECT first_name, last_name, admission_number FROM student_profiles WHERE id = $1`,
        [user.profileId]
      );
      const studentName =
        stpRows.length > 0
          ? `${stpRows[0].first_name} ${stpRows[0].last_name || ''}`.trim()
          : 'Student';
      const admission = stpRows.length > 0 ? stpRows[0].admission_number : '';

      await NoticeService.createNotice(user, {
        title: `Leave Request: ${studentName}`,
        content: `${studentName}${admission ? ` (Adm: ${admission})` : ''} has applied for leave from ${startDate} to ${endDate}. Reason: ${reason.trim()}`,
        target_role: 'TEACHER',
        target_class_id: classId,
        target_section_id: sectionId,
        priority: 'NORMAL',
        channel: 'IN_APP',
      });
    } catch (noticeErr) {
      console.warn('[LeavesService]: Non-blocking leave notice generation failed:', noticeErr);
    }

    return createdLeave;
  }

  static async getStudentMyLeaves(user: TokenPayload) {
    if (!user.profileId) {
      throw new Error('PROFILE_NOT_FOUND');
    }
    return await LeavesRepository.getStudentLeavesByStudentId(user.profileId);
  }

  static async getPendingStudentLeaves(
    user: TokenPayload,
    classId?: string,
    sectionId?: string,
    filters?: StudentLeaveFilters
  ) {
    const combinedFilters: StudentLeaveFilters = {
      ...(filters || {}),
      status: 'PENDING',
    };
    const isManagementOrAdmin = user.roles.some((r) =>
      ['ADMIN', 'SUPER_ADMIN'].includes(r)
    );

    if (isManagementOrAdmin) {
      if (classId && sectionId) {
        return await LeavesRepository.getClassStudentLeaves(classId, sectionId, combinedFilters);
      }
      return await LeavesRepository.getAllSchoolStudentLeaves(user.schoolId, combinedFilters);
    }

    if (!user.profileId) {
      throw new Error('PROFILE_NOT_FOUND');
    }
    const homeroom = await LeavesRepository.getTeacherHomeroom(user.profileId);
    if (!homeroom) {
      throw new Error('NOT_CLASS_TEACHER');
    }
    return await LeavesRepository.getClassStudentLeaves(homeroom.class_id, homeroom.section_id, combinedFilters);
  }

  static async getClassStudentLeaves(
    user: TokenPayload,
    classId?: string,
    sectionId?: string,
    filters?: StudentLeaveFilters
  ) {
    const isManagementOrAdmin = user.roles.some((r) =>
      ['ADMIN', 'SUPER_ADMIN'].includes(r)
    );

    if (isManagementOrAdmin) {
      if (classId && sectionId) {
        return await LeavesRepository.getClassStudentLeaves(classId, sectionId, filters);
      }
      return await LeavesRepository.getAllSchoolStudentLeaves(user.schoolId, filters);
    }

    if (!user.profileId) {
      throw new Error('PROFILE_NOT_FOUND');
    }
    const homeroom = await LeavesRepository.getTeacherHomeroom(user.profileId);
    if (!homeroom) {
      throw new Error('NOT_CLASS_TEACHER');
    }
    return await LeavesRepository.getClassStudentLeaves(homeroom.class_id, homeroom.section_id, filters);
  }

  static async updateStudentLeaveStatus(
    user: TokenPayload,
    leaveId: string,
    status: 'APPROVED' | 'REJECTED',
    remarks?: string | null
  ) {
    const leave = await LeavesRepository.getStudentLeaveById(leaveId);
    if (!leave) {
      throw new Error('LEAVE_NOT_FOUND');
    }

    if (leave.school_id !== user.schoolId) {
      throw new Error('FORBIDDEN_SCOPE');
    }

    // Lock final states (APPROVED/REJECTED) from further edits
    if (leave.status === 'APPROVED' || leave.status === 'REJECTED') {
      throw new Error('INVALID_STATE_TRANSITION');
    }

    const isManagementOrAdmin = user.roles.some((r) =>
      ['ADMIN', 'SUPER_ADMIN'].includes(r)
    );

    let updatedLeave;
    if (isManagementOrAdmin) {
      updatedLeave = await LeavesRepository.updateStudentLeaveStatus(
        leaveId,
        status,
        { userId: user.userId, staffId: user.profileId || null },
        remarks
      );
    } else {
      if (!user.profileId) {
        throw new Error('PROFILE_NOT_FOUND');
      }

      const homeroom = await LeavesRepository.getTeacherHomeroom(user.profileId);
      if (!homeroom) {
        throw new Error('NOT_CLASS_TEACHER');
      }

      // Class Teacher must be in the same school and assigned to the same class & section
      if (leave.class_id !== homeroom.class_id || leave.section_id !== homeroom.section_id) {
        throw new Error('FORBIDDEN_SCOPE');
      }

      updatedLeave = await LeavesRepository.updateStudentLeaveStatus(
        leaveId,
        status,
        { staffId: user.profileId, userId: user.userId },
        remarks
      );
    }

    // Trigger in-app notice for the student
    try {
      const statusUpper = status.toUpperCase();
      const title = `Leave Application ${statusUpper === 'APPROVED' ? 'Approved' : 'Rejected'}`;
      const remarksText = remarks && remarks.trim() ? ` Remarks: ${remarks.trim()}` : '';
      const content = `Your leave application from ${leave.start_date} to ${leave.end_date} has been ${statusUpper.toLowerCase()}.${remarksText}`;

      await NoticeService.createNotice(user, {
        title,
        content,
        target_role: 'STUDENT',
        target_student_id: leave.student_id,
        target_class_id: leave.class_id,
        target_section_id: leave.section_id,
        priority: statusUpper === 'APPROVED' ? 'NORMAL' : 'URGENT',
        channel: 'IN_APP',
      });
    } catch (noticeErr) {
      console.warn('[LeavesService]: Non-blocking student notice generation failed:', noticeErr);
    }

    return updatedLeave;
  }
}

