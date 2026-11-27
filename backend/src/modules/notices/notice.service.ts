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
  static async ensureTodayBirthdayNotices(
    schoolId: string,
    classId: string,
    sectionId: string
  ): Promise<void> {
    if (!schoolId || !classId || !sectionId) return;

    const celebrantsRes = await pool.query(
      `SELECT sp.id, sp.first_name, sp.last_name, sp.roll_number,
              TO_CHAR((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date, 'YYYY-MM-DD') AS ist_today
       FROM student_profiles sp
       JOIN users u ON sp.user_id = u.id
       JOIN classes c ON sp.current_class_id = c.id
       WHERE u.school_id = $1
         AND c.school_id = $1
         AND sp.current_class_id = $2
         AND sp.current_section_id = $3
         AND sp.is_active = TRUE
         AND sp.date_of_birth IS NOT NULL
         AND TO_CHAR(sp.date_of_birth, 'MM-DD') = TO_CHAR((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date, 'MM-DD');`,
      [schoolId, classId, sectionId]
    );

    if (celebrantsRes.rows.length === 0) return;

    const istToday = celebrantsRes.rows[0].ist_today as string;
    const lockKey = `birthday-notice:${schoolId}:${classId}:${sectionId}:${istToday}`;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query('SELECT pg_advisory_xact_lock(hashtext($1));', [lockKey]);

      const classmatesRes = await client.query(
        `SELECT sp.id
         FROM student_profiles sp
         JOIN users u ON sp.user_id = u.id
         WHERE u.school_id = $1
           AND sp.current_class_id = $2
           AND sp.current_section_id = $3
           AND sp.is_active = TRUE;`,
        [schoolId, classId, sectionId]
      );

      for (const celebrant of celebrantsRes.rows) {
        const fullName = [celebrant.first_name, celebrant.last_name]
          .filter((part: string | null | undefined) => Boolean(part && part.trim()))
          .join(' ')
          .trim() || 'Classmate';
        const rollSuffix = celebrant.roll_number ? ` (Roll No: ${celebrant.roll_number})` : '';

        const studentTitle = `Classmate Birthday: ${fullName}`;
        const studentContent = `Wish ${fullName}${rollSuffix} a very Happy Birthday today!`;

        for (const classmate of classmatesRes.rows) {
          if (classmate.id === celebrant.id) continue; // Avoid self-spam

          const existingStudentNotice = await client.query(
            `SELECT 1 FROM notices
             WHERE school_id = $1
               AND target_role = 'STUDENT'
               AND target_class_id = $2
               AND target_section_id = $3
               AND target_student_id = $4
               AND title = $5
               AND (published_at AT TIME ZONE 'Asia/Kolkata')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date
             LIMIT 1;`,
            [schoolId, classId, sectionId, classmate.id, studentTitle]
          );

          if (existingStudentNotice.rows.length === 0) {
            await client.query(
              `INSERT INTO notices (
                school_id, title, content, target_role,
                target_class_id, target_section_id, target_student_id,
                priority, channel, published_at
              ) VALUES ($1, $2, $3, 'STUDENT', $4, $5, $6, 'INFO', 'IN_APP', CURRENT_TIMESTAMP);`,
              [schoolId, studentTitle, studentContent, classId, sectionId, classmate.id]
            );
          }
        }

        const teacherTitle = `Student Birthday: ${fullName}`;
        const teacherContent = `${fullName}${rollSuffix} in your homeroom class has a birthday today!`;
        const existingTeacherNotice = await client.query(
          `SELECT 1 FROM notices
           WHERE school_id = $1
             AND target_role = 'TEACHER'
             AND target_class_id = $2
             AND target_section_id = $3
             AND target_student_id IS NULL
             AND title = $4
             AND (published_at AT TIME ZONE 'Asia/Kolkata')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date
           LIMIT 1;`,
          [schoolId, classId, sectionId, teacherTitle]
        );

        if (existingTeacherNotice.rows.length === 0) {
          await client.query(
            `INSERT INTO notices (
              school_id, title, content, target_role,
              target_class_id, target_section_id, target_student_id,
              priority, channel, published_at
            ) VALUES ($1, $2, $3, 'TEACHER', $4, $5, NULL, 'INFO', 'IN_APP', CURRENT_TIMESTAMP);`,
            [schoolId, teacherTitle, teacherContent, classId, sectionId]
          );
        }
      }

      await client.query('COMMIT');
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  static async getStudentNotices(user: TokenPayload): Promise<NoticeItem[]> {
    let classId = user.classId || null;
    let sectionId = user.sectionId || null;
    let studentProfileId = user.profileId || null;

    if (!classId || !sectionId || !studentProfileId) {
      const profileRes = await pool.query(
        `SELECT sp.id, sp.current_class_id, sp.current_section_id
         FROM student_profiles sp
         JOIN users u ON sp.user_id = u.id
         WHERE u.school_id = $1 AND (sp.id::text = $2 OR sp.user_id::text = $3)
         LIMIT 1;`,
        [user.schoolId, user.profileId || user.userId, user.userId]
      );
      if (profileRes.rows.length > 0) {
        studentProfileId = profileRes.rows[0].id;
        classId = classId || profileRes.rows[0].current_class_id;
        sectionId = sectionId || profileRes.rows[0].current_section_id;
      }
    }

    if (user.schoolId && classId && sectionId) {
      await NoticeService.ensureTodayBirthdayNotices(user.schoolId, classId, sectionId).catch((err) => {
        console.warn('[Birthday Notice Warning - Student]:', err?.message);
      });
    }

    const query = `
      SELECT 
        n.id, n.title, n.content, n.target_role, n.priority, n.channel,
        n.target_class_id, n.target_section_id, n.target_student_id,
        n.published_at, n.created_at
      FROM notices n
      WHERE n.school_id = $1
        AND (n.target_role = 'ALL' OR n.target_role = 'STUDENT')
        AND (n.target_class_id IS NULL OR n.target_class_id = $2)
        AND (n.target_section_id IS NULL OR n.target_section_id = $3)
        AND (n.target_student_id IS NULL OR n.target_student_id = $4)
        AND NOT EXISTS (
          SELECT 1
          FROM notice_dismissals nd
          WHERE nd.notice_id = n.id
            AND nd.user_id = $5
        )
      ORDER BY n.published_at DESC;
    `;
    const { rows } = await pool.query(query, [
      user.schoolId,
      classId,
      sectionId,
      studentProfileId,
      user.userId,
    ]);
    return rows;
  }

  static async getTeacherNotices(user: TokenPayload): Promise<NoticeItem[]> {
    const scopeRes = await pool.query(
      `SELECT DISTINCT sa.class_id, sa.section_id, sa.assignment_type
       FROM staff_assignments sa
       JOIN staff_profiles sp ON sa.staff_id = sp.id
       JOIN users u ON sp.user_id = u.id
       WHERE u.school_id = $1
         AND (sp.id::text = $2 OR sp.user_id::text = $3)
         AND sa.class_id IS NOT NULL
         AND sa.section_id IS NOT NULL
       UNION
       SELECT DISTINCT tsa.class_id, tsa.section_id, 'SUBJECT_TEACHER' AS assignment_type
       FROM teacher_subject_allocations tsa
       JOIN staff_profiles sp ON tsa.staff_id = sp.id
       JOIN users u ON sp.user_id = u.id
       WHERE u.school_id = $1
         AND (sp.id::text = $2 OR sp.user_id::text = $3);`,
      [user.schoolId, user.profileId || user.userId, user.userId]
    );

    const homerooms = scopeRes.rows.filter((r: any) => r.assignment_type === 'CLASS_TEACHER');
    for (const hr of homerooms) {
      await NoticeService.ensureTodayBirthdayNotices(user.schoolId, hr.class_id, hr.section_id).catch((err) => {
        console.warn('[Birthday Notice Warning - Teacher]:', err?.message);
      });
    }

    const query = `
      SELECT 
        n.id, n.title, n.content, n.target_role, n.priority, n.channel,
        n.target_class_id, n.target_section_id, n.target_student_id,
        n.published_at, n.created_at
      FROM notices n
      WHERE n.school_id = $1
        AND (n.target_role = 'ALL' OR n.target_role = 'TEACHER')
        AND (
          n.target_class_id IS NULL
          OR EXISTS (
            SELECT 1
            FROM staff_assignments sa
            JOIN staff_profiles sp ON sa.staff_id = sp.id
            JOIN users u ON sp.user_id = u.id
            WHERE u.school_id = $1
              AND (sp.id::text = $2 OR sp.user_id::text = $3)
              AND sa.class_id = n.target_class_id
              AND (n.target_section_id IS NULL OR sa.section_id = n.target_section_id)
            UNION ALL
            SELECT 1
            FROM teacher_subject_allocations tsa
            JOIN staff_profiles sp ON tsa.staff_id = sp.id
            JOIN users u ON sp.user_id = u.id
            WHERE u.school_id = $1
              AND (sp.id::text = $2 OR sp.user_id::text = $3)
              AND tsa.class_id = n.target_class_id
              AND (n.target_section_id IS NULL OR tsa.section_id = n.target_section_id)
          )
        )
        AND NOT EXISTS (
          SELECT 1
          FROM notice_dismissals nd
          WHERE nd.notice_id = n.id
            AND nd.user_id::text = $3
        )
      ORDER BY n.published_at DESC;
    `;
    const { rows } = await pool.query(query, [
      user.schoolId,
      user.profileId || user.userId,
      user.userId,
    ]);
    return rows;
  }

  static async dismissStudentNotice(user: TokenPayload, noticeId: string): Promise<boolean> {
    const checkRes = await pool.query(
      `SELECT id FROM notices
       WHERE id = $1
         AND school_id = $2
         AND (target_role = 'ALL' OR target_role = 'STUDENT')
         AND (target_class_id IS NULL OR target_class_id = $3)
         AND (target_section_id IS NULL OR target_section_id = $4)
         AND (target_student_id IS NULL OR target_student_id = $5)
       LIMIT 1;`,
      [
        noticeId,
        user.schoolId,
        user.classId || null,
        user.sectionId || null,
        user.profileId || null,
      ]
    );
    if (checkRes.rows.length === 0) {
      return false;
    }

    await pool.query(
      `INSERT INTO notice_dismissals (school_id, user_id, notice_id)
       VALUES ($1, $2, $3)
       ON CONFLICT (user_id, notice_id) DO NOTHING;`,
      [user.schoolId, user.userId, noticeId]
    );
    return true;
  }

  static async dismissAllStudentNotices(user: TokenPayload, noticeIds?: string[]): Promise<number> {
    const hasFilter = Array.isArray(noticeIds) && noticeIds.length > 0;
    const { rowCount } = await pool.query(
      `INSERT INTO notice_dismissals (school_id, user_id, notice_id)
       SELECT n.school_id, $5::uuid, n.id
       FROM notices n
       WHERE n.school_id = $1
         AND (n.target_role = 'ALL' OR n.target_role = 'STUDENT')
         AND (n.target_class_id IS NULL OR n.target_class_id = $2)
         AND (n.target_section_id IS NULL OR n.target_section_id = $3)
         AND (n.target_student_id IS NULL OR n.target_student_id = $4)
         ${hasFilter ? 'AND n.id = ANY($6::uuid[])' : ''}
       ON CONFLICT (user_id, notice_id) DO NOTHING;`,
      hasFilter
        ? [
            user.schoolId,
            user.classId || null,
            user.sectionId || null,
            user.profileId || null,
            user.userId,
            noticeIds,
          ]
        : [
            user.schoolId,
            user.classId || null,
            user.sectionId || null,
            user.profileId || null,
            user.userId,
          ]
    );
    return rowCount || 0;
  }

  static async restoreStudentNotices(user: TokenPayload, noticeIds?: string[]): Promise<number> {
    const hasFilter = Array.isArray(noticeIds) && noticeIds.length > 0;
    const { rowCount } = await pool.query(
      hasFilter
        ? `DELETE FROM notice_dismissals WHERE user_id = $1 AND school_id = $2 AND notice_id = ANY($3::uuid[]);`
        : `DELETE FROM notice_dismissals WHERE user_id = $1 AND school_id = $2;`,
      hasFilter ? [user.userId, user.schoolId, noticeIds] : [user.userId, user.schoolId]
    );
    return rowCount || 0;
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
