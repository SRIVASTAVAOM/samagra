import { pool } from '../../config/db.config';
import { TokenPayload } from '../../types/auth.types';

export interface NoticeItem {
  id: string;
  title: string;
  content: string;
  target_role: string;
  priority: 'INFO' | 'NORMAL' | 'URGENT';
  target_class_id: string | null;
  target_section_id: string | null;
  published_at: string;
  created_at: string;
}

const noticeIdempotencyCache = new Map<string, { result: any; expiresAt: number }>();

export class NoticeService {
  static async getStudentNotices(user: TokenPayload): Promise<NoticeItem[]> {
    const query = `
      SELECT 
        id, title, content, target_role, priority, channel,
        target_class_id, target_section_id, target_student_id,
        published_at, created_at
      FROM notices
      WHERE school_id = $1
        AND (target_role = 'ALL' OR target_role = 'STUDENT')
        AND (target_class_id IS NULL OR target_class_id = $2)
        AND (target_section_id IS NULL OR target_section_id = $3)
        AND (target_student_id IS NULL OR target_student_id = $4)
      ORDER BY published_at DESC;
    `;
    const { rows } = await pool.query(query, [
      user.schoolId,
      user.classId || null,
      user.sectionId || null,
      user.profileId || null,
    ]);
    return rows;
  }

  static async getAdminNotices(user: TokenPayload): Promise<any[]> {
    const query = `
      SELECT 
        n.id, n.title, n.content, n.target_role, n.priority, n.channel,
        n.target_class_id, n.target_section_id, n.target_student_id,
        c.name AS class_name, s.name AS section_name,
        CONCAT(stp.first_name, ' ', stp.last_name) AS target_student_name,
        stp.admission_number AS target_student_admission,
        n.published_at, n.created_at
      FROM notices n
      LEFT JOIN classes c ON c.id = n.target_class_id
      LEFT JOIN sections s ON s.id = n.target_section_id
      LEFT JOIN student_profiles stp ON stp.id = n.target_student_id
      WHERE n.school_id = $1
      ORDER BY n.published_at DESC;
    `;
    const { rows } = await pool.query(query, [user.schoolId]);
    return rows;
  }

  static async createNotice(
    user: TokenPayload,
    data: {
      title: string;
      content: string;
      target_role?: string;
      target_class_id?: string | null;
      target_section_id?: string | null;
      target_student_id?: string | null;
      priority?: 'INFO' | 'NORMAL' | 'URGENT';
      channel?: string;
      idempotencyKey?: string;
    }
  ): Promise<any> {
    if (!data.title?.trim() || !data.content?.trim()) {
      const error: any = new Error('Title and content are required');
      error.statusCode = 400;
      throw error;
    }

    const now = Date.now();
    // 1. In-memory idempotency check
    if (data.idempotencyKey) {
      const cached = noticeIdempotencyCache.get(data.idempotencyKey);
      if (cached && cached.expiresAt > now) {
        return cached.result;
      }
    }

    const trimmedTitle = data.title.trim();
    const trimmedContent = data.content.trim();
    const role = data.target_role || 'ALL';

    // 2. Database level idempotency check for duplicate clicks within 60s
    const existingRecent = await pool.query(
      `SELECT * FROM notices
       WHERE school_id = $1
         AND title = $2
         AND content = $3
         AND target_role = $4
         AND created_at >= NOW() - INTERVAL '60 seconds'
       ORDER BY created_at DESC
       LIMIT 1;`,
      [user.schoolId, trimmedTitle, trimmedContent, role]
    );

    if (existingRecent.rows.length > 0) {
      const existing = existingRecent.rows[0];
      if (data.idempotencyKey) {
        noticeIdempotencyCache.set(data.idempotencyKey, {
          result: existing,
          expiresAt: now + 5 * 60 * 1000,
        });
      }
      return existing;
    }

    const query = `
      INSERT INTO notices (
        school_id, title, content, target_role,
        target_class_id, target_section_id, target_student_id, priority, channel, published_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, CURRENT_TIMESTAMP)
      RETURNING *;
    `;

    const { rows } = await pool.query(query, [
      user.schoolId,
      trimmedTitle,
      trimmedContent,
      role,
      data.target_class_id || null,
      data.target_section_id || null,
      data.target_student_id || null,
      data.priority || 'NORMAL',
      data.channel || 'IN_APP',
    ]);

    const created = rows[0];
    if (data.idempotencyKey) {
      noticeIdempotencyCache.set(data.idempotencyKey, {
        result: created,
        expiresAt: now + 5 * 60 * 1000,
      });
    }

    return created;
  }

  static async deleteNotice(user: TokenPayload, id: string): Promise<boolean> {
    const query = `
      DELETE FROM notices
      WHERE id = $1 AND school_id = $2
      RETURNING id;
    `;
    const { rows } = await pool.query(query, [id, user.schoolId]);
    return rows.length > 0;
  }
}
