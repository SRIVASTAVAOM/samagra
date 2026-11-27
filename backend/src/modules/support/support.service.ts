import { pool } from '../../config/db.config';
import { TokenPayload } from '../../types/auth.types';

export interface ComplaintItem {
  id: string;
  title: string;
  category: string;
  description: string;
  status: 'PENDING' | 'IN_REVIEW' | 'RESOLVED';
  resolution_notes: string | null;
  created_at: string;
  updated_at: string;
}

export interface FeedbackItem {
  id: string;
  category: string;
  rating: number;
  feedback_text: string;
  created_at: string;
}

export class SupportService {
  private static async resolveStudentId(user: TokenPayload): Promise<string> {
    if (user.profileId) {
      return user.profileId;
    }
    if (user.userId) {
      const { rows } = await pool.query(
        `SELECT stp.id
         FROM student_profiles stp
         JOIN users u ON stp.user_id = u.id
         WHERE stp.user_id = $1
           AND ($2::uuid IS NULL OR u.school_id = $2::uuid)
         LIMIT 1;`,
        [user.userId, user.schoolId || null]
      );
      if (rows[0]?.id) {
        return rows[0].id;
      }
    }
    throw new Error('PROFILE_NOT_FOUND');
  }

  static async getStudentComplaints(user: TokenPayload): Promise<ComplaintItem[]> {
    const studentId = await this.resolveStudentId(user);

    const query = `
      SELECT id, title, category, description, status, resolution_notes, created_at, updated_at
      FROM student_complaints
      WHERE student_id = $1 AND school_id = $2
      ORDER BY created_at DESC;
    `;
    const { rows } = await pool.query(query, [studentId, user.schoolId]);
    return rows;
  }

  static async submitComplaint(
    user: TokenPayload,
    data: { title: string; category: string; description: string }
  ): Promise<ComplaintItem> {
    const studentId = await this.resolveStudentId(user);

    const validCategories = ['ACADEMIC', 'FACILITY', 'DISCIPLINE', 'TRANSPORT', 'OTHER'];
    if (!validCategories.includes(data.category)) {
      throw new Error('INVALID_CATEGORY');
    }

    const trimmedTitle = typeof data.title === 'string' ? data.title.trim() : '';
    if (trimmedTitle.length === 0) {
      throw new Error('TITLE_REQUIRED');
    }
    if (trimmedTitle.length > 255) {
      throw new Error('TITLE_TOO_LONG');
    }

    const trimmedDescription = typeof data.description === 'string' ? data.description.trim() : '';
    if (trimmedDescription.length === 0) {
      throw new Error('DESCRIPTION_REQUIRED');
    }

    const query = `
      INSERT INTO student_complaints (school_id, student_id, title, category, description, status)
      VALUES ($1, $2, $3, $4, $5, 'PENDING')
      RETURNING id, title, category, description, status, resolution_notes, created_at, updated_at;
    `;
    const { rows } = await pool.query(query, [
      user.schoolId,
      studentId,
      trimmedTitle,
      data.category,
      trimmedDescription,
    ]);

    return rows[0];
  }

  static async getStudentFeedback(user: TokenPayload): Promise<FeedbackItem[]> {
    const studentId = await this.resolveStudentId(user);

    const query = `
      SELECT id, category, rating, feedback_text, created_at
      FROM school_feedback
      WHERE student_id = $1 AND school_id = $2
      ORDER BY created_at DESC;
    `;
    const { rows } = await pool.query(query, [studentId, user.schoolId]);
    return rows;
  }

  static async submitFeedback(
    user: TokenPayload,
    data: { category: string; rating: number; feedback_text: string }
  ): Promise<FeedbackItem> {
    const studentId = await this.resolveStudentId(user);

    const validCategories = ['CURRICULUM', 'TEACHING', 'FACILITIES', 'ACTIVITIES', 'GENERAL'];
    if (!validCategories.includes(data.category)) {
      throw new Error('INVALID_CATEGORY');
    }

    if (
      typeof data.rating !== 'number' ||
      !Number.isInteger(data.rating) ||
      data.rating < 1 ||
      data.rating > 5
    ) {
      throw new Error('INVALID_RATING');
    }

    const trimmedFeedback = typeof data.feedback_text === 'string' ? data.feedback_text.trim() : '';
    if (trimmedFeedback.length === 0) {
      throw new Error('FEEDBACK_TEXT_REQUIRED');
    }

    const query = `
      INSERT INTO school_feedback (school_id, student_id, category, rating, feedback_text)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, category, rating, feedback_text, created_at;
    `;
    const { rows } = await pool.query(query, [
      user.schoolId,
      studentId,
      data.category,
      data.rating,
      trimmedFeedback,
    ]);

    return rows[0];
  }
}
