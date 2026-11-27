import { pool } from '../../config/db.config';
import { TokenPayload } from '../../types/auth.types';
import { CloudinaryService } from '../../services/cloudinary.service';
import { HomeworkRepository, HomeworkAssignment } from './homework.repository';

const homeworkIdempotencyCache = new Map<string, { result: HomeworkAssignment; expiresAt: number }>();

export class HomeworkService {
  /**
   * Verifies teacher is allocated to class, section, and subject.
   */
  static async verifyTeacherAllocation(
    staffId: string,
    classId: string,
    sectionId: string,
    subjectId: string
  ): Promise<void> {
    const { rows } = await pool.query(
      `SELECT 1 FROM teacher_subject_allocations 
       WHERE staff_id = $1 AND class_id = $2 AND section_id = $3 AND subject_id = $4
       UNION
       SELECT 1 FROM staff_assignments
       WHERE staff_id = $1 AND class_id = $2 AND section_id = $3;`,
      [staffId, classId, sectionId, subjectId]
    );

    if (rows.length === 0) {
      throw {
        statusCode: 403,
        message: 'Teachers can only assign homework for their allocated classes, sections, and subjects.',
      };
    }
  }

  static async createHomework(
    user: TokenPayload,
    data: {
      classId: string;
      sectionId: string;
      subjectId: string;
      title: string;
      description: string;
      assignedDate?: string;
      dueDate: string;
      s3AttachmentKey?: string;
      attachmentName?: string;
      idempotencyKey?: string;
    }
  ): Promise<HomeworkAssignment> {
    if (!user.roles.includes('TEACHER')) {
      throw { statusCode: 403, message: 'Only teachers can create homework assignments.' };
    }

    // 1. In-memory idempotency check for fast network double-taps
    const now = Date.now();
    if (data.idempotencyKey) {
      const cached = homeworkIdempotencyCache.get(data.idempotencyKey);
      if (cached && cached.expiresAt > now) {
        return cached.result;
      }
    }

    // Validate due date
    const assigned = data.assignedDate ? new Date(data.assignedDate) : new Date();
    const due = new Date(data.dueDate);
    if (due.setHours(0, 0, 0, 0) < assigned.setHours(0, 0, 0, 0)) {
      throw { statusCode: 400, message: 'Homework due date cannot be earlier than assigned date.' };
    }

    await this.verifyTeacherAllocation(user.profileId!, data.classId, data.sectionId, data.subjectId);

    // 2. Database level idempotency check: check if identical homework was submitted within last 60 seconds
    const existingRecent = await pool.query(
      `SELECT * FROM homework_assignments
       WHERE school_id = $1 
         AND class_id = $2 
         AND section_id = $3 
         AND subject_id = $4 
         AND assigned_by_staff_id = $5 
         AND title = $6 
         AND due_date = $7::date 
         AND created_at >= NOW() - INTERVAL '60 seconds'
       ORDER BY created_at DESC 
       LIMIT 1;`,
      [
        user.schoolId,
        data.classId,
        data.sectionId,
        data.subjectId,
        user.profileId!,
        data.title,
        data.dueDate,
      ]
    );

    if (existingRecent.rows.length > 0) {
      const existing = existingRecent.rows[0];
      if (data.idempotencyKey) {
        homeworkIdempotencyCache.set(data.idempotencyKey, {
          result: existing,
          expiresAt: now + 5 * 60 * 1000,
        });
      }
      return existing;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const homework = await HomeworkRepository.createHomework(
        {
          schoolId: user.schoolId,
          classId: data.classId,
          sectionId: data.sectionId,
          subjectId: data.subjectId,
          assignedByStaffId: user.profileId!,
          title: data.title,
          description: data.description,
          assignedDate: data.assignedDate,
          dueDate: data.dueDate,
          s3AttachmentKey: data.s3AttachmentKey,
          attachmentName: data.attachmentName,
        },
        client
      );

      // Automatically emit an in-app notice and alert for all students in target class & section atomically
      const subjectResult = await client.query(
        `SELECT name FROM subjects WHERE id = $1;`,
        [data.subjectId]
      );
      const subjectName = subjectResult.rows[0]?.name || 'Subject';

      await client.query(
        `INSERT INTO notices (
          school_id, title, content, target_role,
          target_class_id, target_section_id, priority, channel, published_at
        ) VALUES ($1, $2, $3, 'STUDENT', $4, $5, 'URGENT', 'IN_APP', CURRENT_TIMESTAMP);`,
        [
          user.schoolId,
          `New Homework: ${subjectName} - ${data.title}`,
          `Due Date: ${data.dueDate}. ${data.description.substring(0, 140)}`,
          data.classId,
          data.sectionId,
        ]
      );

      await client.query('COMMIT');

      if (data.idempotencyKey) {
        homeworkIdempotencyCache.set(data.idempotencyKey, {
          result: homework,
          expiresAt: Date.now() + 5 * 60 * 1000,
        });
      }

      return homework;
    } catch (txErr) {
      await client.query('ROLLBACK');
      throw txErr;
    } finally {
      client.release();
    }
  }

  static async getStudentMyClassHomework(user: TokenPayload): Promise<HomeworkAssignment[]> {
    if (!user.roles.includes('STUDENT')) {
      throw { statusCode: 403, message: 'Only students can access my-class homework.' };
    }

    const { rows } = await pool.query(
      `SELECT current_class_id, current_section_id FROM student_profiles WHERE id = $1;`,
      [user.profileId]
    );

    if (rows.length === 0 || !rows[0].current_class_id || !rows[0].current_section_id) {
      throw { statusCode: 404, message: 'Student class/section assignment not found.' };
    }

    return await HomeworkRepository.getClassSectionHomework(
      rows[0].current_class_id,
      rows[0].current_section_id,
      user.profileId || undefined
    );
  }

  static async getTeacherMyAssignedHomework(user: TokenPayload): Promise<HomeworkAssignment[]> {
    if (!user.roles.includes('TEACHER')) {
      throw { statusCode: 403, message: 'Only teachers can access my-assigned homework.' };
    }

    return await HomeworkRepository.getTeacherAssignedHomework(user.profileId!);
  }

  static async getClassSectionHomework(
    user: TokenPayload,
    classId: string,
    sectionId: string
  ): Promise<HomeworkAssignment[]> {
    // If student, check class and section match
    if (user.roles.includes('STUDENT')) {
      const { rows } = await pool.query(
        `SELECT current_class_id, current_section_id FROM student_profiles WHERE id = $1;`,
        [user.profileId]
      );
      if (rows.length === 0 || rows[0].current_class_id !== classId || rows[0].current_section_id !== sectionId) {
        throw { statusCode: 403, message: 'Students can only view homework for their own class and section.' };
      }
      return await HomeworkRepository.getClassSectionHomework(classId, sectionId, user.profileId || undefined);
    }

    // If teacher, check assignment
    if (user.roles.includes('TEACHER')) {
      const { rows } = await pool.query(
        `SELECT 1 FROM staff_assignments WHERE staff_id = $1 AND class_id = $2 AND section_id = $3
         UNION
         SELECT 1 FROM teacher_subject_allocations WHERE staff_id = $1 AND class_id = $2 AND section_id = $3;`,
        [user.profileId, classId, sectionId]
      );
      if (rows.length === 0) {
        throw { statusCode: 403, message: 'Teachers can only view homework for their allocated classes and sections.' };
      }
    }



    return await HomeworkRepository.getClassSectionHomework(classId, sectionId);
  }

  static async getHomeworkDetail(user: TokenPayload, id: string): Promise<HomeworkAssignment> {
    const studentId = user.roles.includes('STUDENT') ? (user.profileId || undefined) : undefined;
    const homework = await HomeworkRepository.getHomeworkById(id, studentId);
    if (!homework) {
      throw { statusCode: 404, message: 'Homework assignment not found.' };
    }

    // Tenant check
    if (!user.roles.includes('SUPER_ADMIN') && homework.school_id !== user.schoolId) {
      throw { statusCode: 403, message: 'Forbidden: Access denied to homework from another school.' };
    }

    // Scope check
    if (user.roles.includes('STUDENT')) {
      const { rows } = await pool.query(
        `SELECT current_class_id, current_section_id FROM student_profiles WHERE id = $1;`,
        [user.profileId]
      );
      if (rows.length === 0 || rows[0].current_class_id !== homework.class_id || rows[0].current_section_id !== homework.section_id) {
        throw { statusCode: 403, message: 'Unauthorized to view this homework assignment.' };
      }
    }

    return homework;
  }

  static async setCompletionStatus(
    user: TokenPayload,
    homeworkId: string,
    status: 'COMPLETED' | 'PENDING',
    submission?: {
      submissionText?: string | null;
      submissionAttachmentKey?: string | null;
      submissionAttachmentName?: string | null;
    }
  ): Promise<{
    status: string;
    completed_at: string;
    submission_text: string | null;
    submission_attachment_key: string | null;
    submission_attachment_name: string | null;
    submitted_at: string | null;
  }> {
    if (!user.roles.includes('STUDENT')) {
      throw { statusCode: 403, message: 'Only students can track or submit homework.' };
    }

    const homework = await HomeworkRepository.getHomeworkById(homeworkId);
    if (!homework) {
      throw { statusCode: 404, message: 'Homework assignment not found.' };
    }

    // Tenant check
    if (!user.roles.includes('SUPER_ADMIN') && homework.school_id !== user.schoolId) {
      throw { statusCode: 403, message: 'Forbidden: Access denied to homework from another school.' };
    }

    // Verify student belongs to that class/section
    const { rows } = await pool.query(
      `SELECT current_class_id, current_section_id FROM student_profiles WHERE id = $1;`,
      [user.profileId]
    );
    if (rows.length === 0 || rows[0].current_class_id !== homework.class_id || rows[0].current_section_id !== homework.section_id) {
      throw { statusCode: 403, message: 'Student is not enrolled in this homework class and section.' };
    }

    return await HomeworkRepository.setCompletionStatus(homeworkId, user.profileId!, status, submission);
  }

  static async getAttachmentDownloadUrl(
    user: TokenPayload,
    homeworkId: string,
    kind: 'assignment' | 'submission' = 'assignment'
  ): Promise<{ downloadUrl: string; attachmentName: string; isMock: boolean }> {
    const homework = await this.getHomeworkDetail(user, homeworkId);
    const key =
      kind === 'submission' ? homework.submission_attachment_key : homework.s3_attachment_key;
    const name =
      kind === 'submission'
        ? homework.submission_attachment_name || 'submission_attachment'
        : homework.attachment_name || 'homework_attachment';

    if (!key) {
      throw { statusCode: 404, message: 'No attachment found for this homework assignment.' };
    }

    const { downloadUrl, isMock } = await CloudinaryService.generatePresignedDownloadUrl(key, 900);
    return {
      downloadUrl,
      attachmentName: name,
      isMock,
    };
  }

  static async updateHomework(
    user: TokenPayload,
    id: string,
    data: {
      title?: string;
      description?: string;
      dueDate?: string;
      s3AttachmentKey?: string | null;
      attachmentName?: string | null;
    }
  ): Promise<HomeworkAssignment> {
    if (!user.roles.includes('TEACHER')) {
      throw { statusCode: 403, message: 'Only teachers can update homework assignments.' };
    }

    const homework = await HomeworkRepository.getHomeworkById(id);
    if (!homework) {
      throw { statusCode: 404, message: 'Homework assignment not found.' };
    }

    // Tenant check
    if (!user.roles.includes('SUPER_ADMIN') && homework.school_id !== user.schoolId) {
      throw { statusCode: 403, message: 'Forbidden: Access denied to homework from another school.' };
    }

    if (homework.school_id !== user.schoolId || homework.assigned_by_staff_id !== user.profileId) {
      throw { statusCode: 403, message: 'You can only update homework assignments created by you.' };
    }

    if (data.dueDate) {
      const assigned = new Date(homework.assigned_date);
      const due = new Date(data.dueDate);
      if (due.setHours(0, 0, 0, 0) < assigned.setHours(0, 0, 0, 0)) {
        throw { statusCode: 400, message: 'Homework due date cannot be earlier than assigned date.' };
      }
    }

    const updated = await HomeworkRepository.updateHomework(id, user.schoolId, user.profileId!, data);
    if (!updated) {
      throw { statusCode: 500, message: 'Failed to update homework assignment.' };
    }
    return updated;
  }
}
