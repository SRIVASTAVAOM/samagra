import { pool } from '../../config/db.config';

export interface SubjectRecord {
  id: string;
  name: string;
  code: string;
}

export interface StudentRosterItem {
  id: string;
  admission_number?: string;
  roll_number: string | null;
  roll_no?: string | null;
  first_name: string;
  last_name: string;
  full_name?: string;
  date_of_birth?: string | null;
  birthday_formatted?: string | null;
  avatar_url?: string | null;
  photo_url?: string | null;
  gender?: string | null;
  emergency_phone?: string | null;
  blood_group?: string | null;
  medical_notes?: string | null;
  class_id?: string;
  section_id?: string;
}

export interface SubjectTeacherItem {
  subject_id?: string;
  subject_name: string;
  subject_code: string;
  subject_type?: string | null;
  teacher_name: string;
  employee_code: string;
  qualification: string | null;
  teacher_phone?: string | null;
  emergency_phone: string | null;
  photo_url?: string | null;
  avatar_url?: string | null;
  is_class_teacher?: boolean;
}

export interface ClassmateBirthdayItem {
  id: string;
  admission_number?: string;
  roll_number: string | null;
  roll_no?: string | null;
  first_name: string;
  last_name: string;
  full_name?: string;
  birth_month: number;
  birth_day: number;
  birthday_formatted: string;
  avatar_url?: string | null;
  photo_url?: string | null;
  is_today?: boolean;
}

export class AcademicsRepository {
  static async getClassesAndSections(schoolId: string): Promise<any[]> {
    const query = `
      SELECT 
        c.id,
        c.id AS class_id,
        c.name,
        c.name AS class_name,
        COALESCE(
          json_agg(
            json_build_object(
              'id', s.id,
              'name', s.name
            ) ORDER BY s.name ASC
          ) FILTER (WHERE s.id IS NOT NULL),
          '[]'::json
        ) AS sections
      FROM classes c
      LEFT JOIN sections s ON s.class_id = c.id
      WHERE c.school_id = $1
      GROUP BY c.id, c.name
      ORDER BY c.name ASC;
    `;
    const { rows } = await pool.query(query, [schoolId]);
    return rows;
  }

  static async getSubjectsBySchool(schoolId: string, classId?: string): Promise<SubjectRecord[]> {
    if (classId && /^[0-9a-fA-F-]{36}$/.test(classId)) {
      const scoped = await pool.query(
        `SELECT s.id, s.name, s.code, COALESCE(s.type, 'THEORY') AS type, COALESCE(s.is_active, TRUE) AS is_active
         FROM subjects s
         JOIN class_subjects cs ON cs.subject_id = s.id
         WHERE s.school_id = $1 AND cs.class_id = $2 AND COALESCE(s.is_active, TRUE) = TRUE
         ORDER BY s.name ASC;`,
        [schoolId, classId]
      );
      if (scoped.rows.length > 0) {
        return scoped.rows;
      }
    }

    const query = `
      SELECT id, name, code, COALESCE(type, 'THEORY') AS type, COALESCE(is_active, TRUE) AS is_active
      FROM subjects
      WHERE school_id = $1 AND COALESCE(is_active, TRUE) = TRUE
      ORDER BY name ASC;
    `;
    const { rows } = await pool.query(query, [schoolId]);
    return rows;
  }

  static async getSubjectsWithDetails(schoolId: string): Promise<any[]> {
    const query = `
      SELECT 
        s.id,
        s.name,
        s.code,
        COALESCE(s.type, 'THEORY') AS type,
        COALESCE(s.is_active, TRUE) AS is_active,
        s.created_at,
        COALESCE(
          json_agg(
            DISTINCT jsonb_build_object('id', c.id, 'name', c.name)
          ) FILTER (WHERE c.id IS NOT NULL),
          '[]'::json
        ) AS classes,
        COUNT(DISTINCT tsa.staff_id)::int AS teachers_count
      FROM subjects s
      LEFT JOIN class_subjects cs ON cs.subject_id = s.id
      LEFT JOIN classes c ON cs.class_id = c.id
      LEFT JOIN teacher_subject_allocations tsa ON tsa.subject_id = s.id
      WHERE s.school_id = $1
      GROUP BY s.id, s.name, s.code, s.type, s.is_active, s.created_at
      ORDER BY s.name ASC;
    `;
    const { rows } = await pool.query(query, [schoolId]);
    return rows;
  }

  static async createSubject(
    schoolId: string,
    data: { name: string; code: string; type?: string; class_ids?: string[] }
  ): Promise<any> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const insertQuery = `
        INSERT INTO subjects (school_id, name, code, type, is_active)
        VALUES ($1, $2, $3, $4, TRUE)
        RETURNING id, name, code, type, is_active, created_at;
      `;
      const res = await client.query(insertQuery, [
        schoolId,
        data.name.trim(),
        data.code.trim().toUpperCase(),
        data.type || 'THEORY',
      ]);
      const newSubject = res.rows[0];

      if (data.class_ids && Array.isArray(data.class_ids) && data.class_ids.length > 0) {
        for (const classId of data.class_ids) {
          await client.query(
            `INSERT INTO class_subjects (class_id, subject_id) VALUES ($1, $2) ON CONFLICT (class_id, subject_id) DO NOTHING;`,
            [classId, newSubject.id]
          );
        }
      }
      await client.query('COMMIT');
      return newSubject;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  static async updateSubject(
    schoolId: string,
    subjectId: string,
    data: { name?: string; code?: string; type?: string; is_active?: boolean; class_ids?: string[] }
  ): Promise<any> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const fields: string[] = [];
      const values: any[] = [];
      let idx = 1;

      if (data.name !== undefined) {
        fields.push(`name = $${idx++}`);
        values.push(data.name.trim());
      }
      if (data.code !== undefined) {
        fields.push(`code = $${idx++}`);
        values.push(data.code.trim().toUpperCase());
      }
      if (data.type !== undefined) {
        fields.push(`type = $${idx++}`);
        values.push(data.type);
      }
      if (data.is_active !== undefined) {
        fields.push(`is_active = $${idx++}`);
        values.push(data.is_active);
      }

      if (fields.length > 0) {
        values.push(subjectId, schoolId);
        await client.query(
          `UPDATE subjects SET ${fields.join(', ')} WHERE id = $${idx++} AND school_id = $${idx}`,
          values
        );
      }

      if (data.class_ids !== undefined && Array.isArray(data.class_ids)) {
        await client.query(`DELETE FROM class_subjects WHERE subject_id = $1;`, [subjectId]);
        for (const classId of data.class_ids) {
          await client.query(
            `INSERT INTO class_subjects (class_id, subject_id) VALUES ($1, $2) ON CONFLICT (class_id, subject_id) DO NOTHING;`,
            [classId, subjectId]
          );
        }
      }

      await client.query('COMMIT');
      const fetchQuery = `
        SELECT 
          s.id, s.name, s.code, COALESCE(s.type, 'THEORY') AS type, COALESCE(s.is_active, TRUE) AS is_active,
          COALESCE(
            json_agg(DISTINCT jsonb_build_object('id', c.id, 'name', c.name)) FILTER (WHERE c.id IS NOT NULL),
            '[]'::json
          ) AS classes
        FROM subjects s
        LEFT JOIN class_subjects cs ON cs.subject_id = s.id
        LEFT JOIN classes c ON cs.class_id = c.id
        WHERE s.id = $1 AND s.school_id = $2
        GROUP BY s.id, s.name, s.code, s.type, s.is_active;
      `;
      const finalRes = await pool.query(fetchQuery, [subjectId, schoolId]);
      return finalRes.rows[0] || null;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  static async deleteSubject(schoolId: string, subjectId: string): Promise<boolean> {
    const res = await pool.query(`DELETE FROM subjects WHERE id = $1 AND school_id = $2;`, [
      subjectId,
      schoolId,
    ]);
    return (res.rowCount ?? 0) > 0;
  }

  static async getClassRoster(classId: string, sectionId: string, schoolId?: string): Promise<StudentRosterItem[]> {
    let query = `
      SELECT 
        sp.id,
        sp.admission_number,
        sp.roll_number,
        sp.roll_number AS roll_no,
        sp.first_name,
        sp.last_name,
        TRIM(CONCAT(sp.first_name, ' ', COALESCE(sp.last_name, ''))) AS full_name,
        TO_CHAR(sp.date_of_birth, 'YYYY-MM-DD') AS date_of_birth,
        TO_CHAR(sp.date_of_birth, 'DD Mon YYYY') AS birthday_formatted,
        sp.photo_url,
        sp.photo_url AS avatar_url,
        sp.gender,
        sp.emergency_phone,
        sp.blood_group,
        sp.medical_notes,
        sp.current_class_id AS class_id,
        sp.current_section_id AS section_id
      FROM student_profiles sp
      JOIN users u ON sp.user_id = u.id
      JOIN classes c ON sp.current_class_id = c.id
      WHERE sp.current_class_id = $1 AND sp.current_section_id = $2 AND sp.is_active = TRUE
    `;
    const params: any[] = [classId, sectionId];
    if (schoolId) {
      query += ` AND u.school_id = $3 AND c.school_id = $3`;
      params.push(schoolId);
    }
    query += `
      ORDER BY
        CASE WHEN sp.roll_number ~ '^[0-9]+$' THEN 0 ELSE 1 END,
        CASE WHEN sp.roll_number ~ '^[0-9]+$' THEN sp.roll_number::int ELSE NULL END ASC NULLS LAST,
        sp.roll_number ASC NULLS LAST,
        sp.first_name ASC;
    `;
    const { rows } = await pool.query(query, params);
    return rows;
  }


  static async getStudentSubjectTeachers(
    studentProfileId: string,
    schoolId?: string
  ): Promise<SubjectTeacherItem[]> {
    const query = `
      (
        SELECT 
          'HOMEROOM' AS subject_id,
          'Class Teacher (Homeroom)' AS subject_name,
          'HOMEROOM' AS subject_code,
          'HOMEROOM' AS subject_type,
          TRIM(CONCAT(sp.first_name, ' ', COALESCE(sp.last_name, ''))) AS teacher_name,
          sp.employee_code,
          sp.qualification,
          COALESCE(NULLIF(TRIM(sp.phone), ''), sp.emergency_phone) AS teacher_phone,
          COALESCE(NULLIF(TRIM(sp.phone), ''), sp.emergency_phone) AS emergency_phone,
          sp.photo_url,
          sp.photo_url AS avatar_url,
          TRUE AS is_class_teacher
        FROM student_profiles stp
        JOIN users u_stu ON stp.user_id = u_stu.id
        JOIN classes c ON stp.current_class_id = c.id AND c.school_id = u_stu.school_id
        JOIN staff_assignments sa 
          ON stp.current_class_id = sa.class_id 
         AND stp.current_section_id = sa.section_id
         AND sa.assignment_type = 'CLASS_TEACHER'
        JOIN staff_profiles sp ON sa.staff_id = sp.id AND sp.is_active = TRUE
        JOIN users u_stf ON sp.user_id = u_stf.id AND u_stf.school_id = u_stu.school_id
        WHERE stp.id = $1
          AND stp.is_active = TRUE
          AND ($2::uuid IS NULL OR u_stu.school_id = $2::uuid)
        ORDER BY sa.created_at DESC
        LIMIT 1
      )
      UNION ALL
      (
        SELECT 
          sub.id::text AS subject_id,
          sub.name AS subject_name,
          sub.code AS subject_code,
          COALESCE(sub.type, 'THEORY') AS subject_type,
          TRIM(CONCAT(sp.first_name, ' ', COALESCE(sp.last_name, ''))) AS teacher_name,
          sp.employee_code,
          sp.qualification,
          COALESCE(NULLIF(TRIM(sp.phone), ''), sp.emergency_phone) AS teacher_phone,
          COALESCE(NULLIF(TRIM(sp.phone), ''), sp.emergency_phone) AS emergency_phone,
          sp.photo_url,
          sp.photo_url AS avatar_url,
          FALSE AS is_class_teacher
        FROM student_profiles stp
        JOIN users u_stu ON stp.user_id = u_stu.id
        JOIN classes c ON stp.current_class_id = c.id AND c.school_id = u_stu.school_id
        JOIN teacher_subject_allocations tsa 
          ON stp.current_class_id = tsa.class_id 
         AND stp.current_section_id = tsa.section_id
        JOIN academic_years ay ON tsa.academic_year_id = ay.id AND ay.school_id = u_stu.school_id
        JOIN subjects sub ON tsa.subject_id = sub.id AND sub.school_id = u_stu.school_id
        JOIN staff_profiles sp ON tsa.staff_id = sp.id AND sp.is_active = TRUE
        JOIN users u_stf ON sp.user_id = u_stf.id AND u_stf.school_id = u_stu.school_id
        WHERE stp.id = $1
          AND stp.is_active = TRUE
          AND ($2::uuid IS NULL OR u_stu.school_id = $2::uuid)
          AND COALESCE(sub.is_active, TRUE) = TRUE
          AND (
            ay.is_current = TRUE
            OR NOT EXISTS (
              SELECT 1 FROM academic_years ay2
              WHERE ay2.school_id = u_stu.school_id AND ay2.is_current = TRUE
            )
          )
          AND (
            NOT EXISTS (
              SELECT 1 FROM class_subjects cs0 WHERE cs0.class_id = stp.current_class_id
            )
            OR EXISTS (
              SELECT 1 FROM class_subjects cs
              WHERE cs.class_id = stp.current_class_id AND cs.subject_id = sub.id
            )
          )
        ORDER BY sub.name ASC
      );
    `;
    const { rows } = await pool.query(query, [studentProfileId, schoolId || null]);
    return rows;
  }

  static async getClassmatesBirthdays(classId: string, sectionId: string, schoolId?: string): Promise<ClassmateBirthdayItem[]> {
    let query = `
      SELECT 
        sp.id,
        sp.admission_number,
        sp.roll_number,
        sp.roll_number AS roll_no,
        sp.first_name,
        sp.last_name,
        TRIM(CONCAT(sp.first_name, ' ', COALESCE(sp.last_name, ''))) AS full_name,
        EXTRACT(MONTH FROM sp.date_of_birth)::int AS birth_month,
        EXTRACT(DAY FROM sp.date_of_birth)::int AS birth_day,
        TO_CHAR(sp.date_of_birth, 'DD Mon') AS birthday_formatted,
        sp.photo_url,
        sp.photo_url AS avatar_url,
        TRUE AS is_today
      FROM student_profiles sp
      JOIN users u ON sp.user_id = u.id
      JOIN classes c ON sp.current_class_id = c.id
      WHERE sp.current_class_id = $1
        AND sp.current_section_id = $2
        AND sp.is_active = TRUE
        AND sp.date_of_birth IS NOT NULL
        AND TO_CHAR(sp.date_of_birth, 'MM-DD') = TO_CHAR((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date, 'MM-DD')
    `;
    const params: any[] = [classId, sectionId];
    if (schoolId) {
      query += ` AND u.school_id = $3 AND c.school_id = $3`;
      params.push(schoolId);
    }
    query += `
      ORDER BY
        CASE WHEN sp.roll_number ~ '^[0-9]+$' THEN 0 ELSE 1 END,
        CASE WHEN sp.roll_number ~ '^[0-9]+$' THEN sp.roll_number::int ELSE NULL END ASC NULLS LAST,
        sp.roll_number ASC NULLS LAST,
        sp.first_name ASC;
    `;
    const { rows } = await pool.query(query, params);
    return rows;
  }

  static async getTeacherAllocations(staffProfileId: string, schoolId?: string) {
    let query = `
      SELECT 
        tsa.id,
        c.id AS class_id,
        c.name AS class_name,
        s.id AS section_id,
        s.name AS section_name,
        sub.id AS subject_id,
        sub.name AS subject_name,
        sub.code AS subject_code
      FROM teacher_subject_allocations tsa
      JOIN classes c ON tsa.class_id = c.id
      JOIN sections s ON tsa.section_id = s.id
      JOIN subjects sub ON tsa.subject_id = sub.id
      WHERE tsa.staff_id = $1
    `;
    const params: any[] = [staffProfileId];
    if (schoolId) {
      query += ` AND c.school_id = $2 AND sub.school_id = $2`;
      params.push(schoolId);
    }
    query += ';';
    const { rows } = await pool.query(query, params);
    return rows;
  }

  static async getTeacherHomeroom(staffProfileId: string, userId?: string, schoolId?: string) {
    const params: any[] = [staffProfileId, userId ?? staffProfileId];
    let query = `
      SELECT 
        sa.id,
        c.id AS class_id,
        c.name AS class_name,
        s.id AS section_id,
        s.name AS section_name,
        u.school_id
      FROM staff_assignments sa
      JOIN staff_profiles sp ON sa.staff_id = sp.id
      JOIN users u ON sp.user_id = u.id
      JOIN classes c ON sa.class_id = c.id
      JOIN sections s ON sa.section_id = s.id
      WHERE (sp.id::text = $1 OR sp.user_id::text = $2)
        AND sa.assignment_type = 'CLASS_TEACHER'
    `;
    if (schoolId) {
      query += ` AND u.school_id = $3 AND c.school_id = $3`;
      params.push(schoolId);
    }
    query += ` LIMIT 1;`;
    const { rows } = await pool.query(query, params);
    return rows[0] || null;
  }

  static async getTeacherClassStudents(staffProfileId: string): Promise<StudentRosterItem[]> {
    const query = `
      SELECT DISTINCT 
        stp.id, stp.admission_number, stp.roll_number, stp.first_name, stp.last_name,
        stp.photo_url, stp.photo_url AS avatar_url,
        stp.gender, stp.emergency_phone, stp.blood_group, stp.medical_notes,
        stp.current_class_id AS class_id, stp.current_section_id AS section_id
      FROM student_profiles stp

      WHERE (stp.current_class_id, stp.current_section_id) IN (
        SELECT class_id, section_id FROM teacher_subject_allocations WHERE staff_id = $1
        UNION
        SELECT class_id, section_id FROM staff_assignments WHERE staff_id = $1 AND class_id IS NOT NULL
      )
      AND stp.is_active = TRUE
      ORDER BY stp.first_name ASC;
    `;
    const { rows } = await pool.query(query, [staffProfileId]);
    return rows;
  }

  static async getStudentEnrollment(studentProfileId: string, userId?: string, schoolId?: string) {
    const params: any[] = [studentProfileId, userId ?? studentProfileId];
    let query = `
      SELECT sp.id AS student_profile_id, sp.current_class_id, sp.current_section_id, u.school_id
      FROM student_profiles sp
      JOIN users u ON sp.user_id = u.id
      WHERE (sp.id::text = $1 OR sp.user_id::text = $2)
    `;
    if (schoolId) {
      query += ` AND u.school_id = $3`;
      params.push(schoolId);
    }
    query += ` LIMIT 1;`;
    const { rows } = await pool.query(query, params);
    return rows[0] || null;
  }
}
