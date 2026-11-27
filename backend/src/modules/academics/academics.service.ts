import { AcademicsRepository, ClassmateBirthdayItem, StudentRosterItem, SubjectRecord, SubjectTeacherItem } from './academics.repository';
import { TokenPayload } from '../../types/auth.types';
import { NoticeService } from '../notices/notice.service';

export class AcademicsService {
  static async getClassesAndSections(schoolId: string): Promise<any[]> {
    return await AcademicsRepository.getClassesAndSections(schoolId);
  }

  static async getSubjects(schoolId: string, classId?: string, user?: TokenPayload): Promise<SubjectRecord[]> {
    let resolvedClassId = classId;
    if (!resolvedClassId && user?.roles.includes('STUDENT')) {
      resolvedClassId = user.classId || undefined;
    }
    return await AcademicsRepository.getSubjectsBySchool(schoolId, resolvedClassId);
  }

  static async getSubjectsWithDetails(schoolId: string): Promise<any[]> {
    return await AcademicsRepository.getSubjectsWithDetails(schoolId);
  }

  static async createSubject(schoolId: string, data: { name: string; code: string; type?: string; class_ids?: string[] }): Promise<any> {
    if (!data.name || !data.code) {
      const error: any = new Error('Subject name and code are required');
      error.statusCode = 400;
      throw error;
    }
    try {
      return await AcademicsRepository.createSubject(schoolId, data);
    } catch (err: any) {
      if (err.code === '23505') {
        const error: any = new Error(`A subject with code "${data.code.trim().toUpperCase()}" already exists in your school.`);
        error.statusCode = 400;
        throw error;
      }
      throw err;
    }
  }

  static async updateSubject(schoolId: string, subjectId: string, data: any): Promise<any> {
    try {
      const updated = await AcademicsRepository.updateSubject(schoolId, subjectId, data);
      if (!updated) {
        const error: any = new Error('Subject not found or unauthorized');
        error.statusCode = 404;
        throw error;
      }
      return updated;
    } catch (err: any) {
      if (err.code === '23505') {
        const error: any = new Error(`A subject with code "${data.code?.trim().toUpperCase()}" already exists in your school.`);
        error.statusCode = 400;
        throw error;
      }
      throw err;
    }
  }

  static async deleteSubject(schoolId: string, subjectId: string): Promise<boolean> {
    const deleted = await AcademicsRepository.deleteSubject(schoolId, subjectId);
    if (!deleted) {
      const error: any = new Error('Subject not found or cannot be deleted');
      error.statusCode = 404;
      throw error;
    }
    return deleted;
  }

  static async getClassRoster(
    user: TokenPayload,
    classId: string,
    sectionId: string
  ): Promise<StudentRosterItem[]> {
    const isOnlyStudent =
      user.roles.includes('STUDENT') &&
      !user.roles.includes('TEACHER') &&
      !user.roles.includes('ADMIN') &&
      !user.roles.includes('SUPER_ADMIN');

    // 1. Data-Scope check for Student: A student can ONLY see students in their own school, class & section!
    if (user.roles.includes('STUDENT')) {
      const enrollment = await AcademicsRepository.getStudentEnrollment(
        user.profileId || user.userId,
        user.userId,
        user.schoolId
      );
      if (!enrollment || !enrollment.current_class_id || !enrollment.current_section_id) {
        throw new Error('PROFILE_NOT_FOUND');
      }
      if (enrollment.current_class_id !== classId || enrollment.current_section_id !== sectionId) {
        throw new Error('FORBIDDEN_SCOPE');
      }
    }

    // 2. Data-Scope check for Teacher: Teacher must teach or be class teacher for this class/section
    if (user.roles.includes('TEACHER') && !user.roles.includes('ADMIN') && !user.roles.includes('SUPER_ADMIN')) {
      const allocations = await AcademicsRepository.getTeacherAllocations(user.profileId!);
      const isAllocated = allocations.some(
        (a: any) => a.class_id === classId && a.section_id === sectionId
      ) || (user.classId === classId && user.sectionId === sectionId);

      if (!isAllocated) {
        throw new Error('FORBIDDEN_SCOPE');
      }
    }

    const rows = await AcademicsRepository.getClassRoster(
      classId,
      sectionId,
      user.roles.includes('SUPER_ADMIN') ? undefined : user.schoolId
    );

    if (isOnlyStudent) {
      return rows.map((row) => ({
        id: row.id,
        admission_number: row.admission_number,
        roll_number: row.roll_number,
        roll_no: row.roll_no ?? row.roll_number,
        first_name: row.first_name,
        last_name: row.last_name,
        full_name: row.full_name,
        date_of_birth: row.date_of_birth ?? null,
        birthday_formatted: row.birthday_formatted ?? null,
        avatar_url: row.avatar_url ?? row.photo_url ?? null,
        photo_url: row.photo_url ?? row.avatar_url ?? null,
        class_id: row.class_id,
        section_id: row.section_id,
      }));
    }

    return rows;
  }

  static async getMyTeacherRoster(user: TokenPayload): Promise<StudentRosterItem[]> {
    if (!user.profileId) {
      throw new Error('PROFILE_NOT_FOUND');
    }
    return await AcademicsRepository.getTeacherClassStudents(user.profileId);
  }

  static async getTeacherAllocations(user: TokenPayload) {
    if (!user.profileId) {
      throw new Error('PROFILE_NOT_FOUND');
    }
    const homeroom = await AcademicsRepository.getTeacherHomeroom(user.profileId);
    const allocations = await AcademicsRepository.getTeacherAllocations(
      user.profileId,
      user.roles.includes('SUPER_ADMIN') ? undefined : user.schoolId
    );
    return {
      homeroom,
      allocations,
    };
  }

  static async getStudentSubjectTeachers(user: TokenPayload): Promise<SubjectTeacherItem[]> {
    const enrollment = await AcademicsRepository.getStudentEnrollment(
      user.profileId || user.userId,
      user.userId,
      user.schoolId
    );
    if (!enrollment) {
      throw new Error('PROFILE_NOT_FOUND');
    }
    if (!enrollment.current_class_id || !enrollment.current_section_id) {
      return [];
    }
    const studentProfileId = enrollment.student_profile_id || user.profileId;
    if (!studentProfileId) {
      throw new Error('PROFILE_NOT_FOUND');
    }
    return await AcademicsRepository.getStudentSubjectTeachers(
      studentProfileId,
      user.roles.includes('SUPER_ADMIN') ? undefined : (enrollment.school_id || user.schoolId)
    );
  }

  static async getClassmatesBirthdays(user: TokenPayload): Promise<ClassmateBirthdayItem[]> {
    const isTeacherOnly =
      user.roles.includes('TEACHER') && !user.roles.includes('STUDENT');

    if (isTeacherOnly) {
      const homeroom = await AcademicsRepository.getTeacherHomeroom(
        user.profileId || user.userId,
        user.userId,
        user.schoolId
      );
      if (!homeroom || !homeroom.class_id || !homeroom.section_id) {
        return [];
      }
      const targetSchoolId = homeroom.school_id || user.schoolId;
      if (targetSchoolId) {
        await NoticeService.ensureTodayBirthdayNotices(
          targetSchoolId,
          homeroom.class_id,
          homeroom.section_id
        ).catch((err) => {
          console.warn('[Birthday Notice Warning]:', err?.message);
        });
      }
      return await AcademicsRepository.getClassmatesBirthdays(
        homeroom.class_id,
        homeroom.section_id,
        user.roles.includes('SUPER_ADMIN') ? undefined : targetSchoolId
      );
    }

    const enrollment = await AcademicsRepository.getStudentEnrollment(
      user.profileId || user.userId,
      user.userId,
      user.schoolId
    );
    if (!enrollment || !enrollment.current_class_id || !enrollment.current_section_id) {
      return [];
    }

    const targetSchoolId = enrollment.school_id || user.schoolId;
    if (targetSchoolId) {
      await NoticeService.ensureTodayBirthdayNotices(
        targetSchoolId,
        enrollment.current_class_id,
        enrollment.current_section_id
      ).catch((err) => {
        console.warn('[Birthday Notice Warning]:', err?.message);
      });
    }

    const rows = await AcademicsRepository.getClassmatesBirthdays(
      enrollment.current_class_id,
      enrollment.current_section_id,
      user.roles.includes('SUPER_ADMIN') ? undefined : targetSchoolId
    );

    return rows.map((row) => ({
      id: row.id,
      roll_number: row.roll_number,
      roll_no: row.roll_no ?? row.roll_number,
      first_name: row.first_name,
      last_name: row.last_name,
      full_name: row.full_name,
      birth_month: row.birth_month,
      birth_day: row.birth_day,
      birthday_formatted: row.birthday_formatted,
      avatar_url: row.avatar_url ?? row.photo_url ?? null,
      photo_url: row.photo_url ?? row.avatar_url ?? null,
      is_today: row.is_today ?? true,
    }));
  }
}

