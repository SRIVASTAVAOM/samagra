import { pool } from '../../config/db.config';

export class ProfileRepository {
  private static async ensureStudentColumns() {
    const stmts = [
      'ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS document_url TEXT NULL;',
      'ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS photo_url TEXT NULL;',
      'ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS guardian_name VARCHAR(150) NULL;',
      'ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS photo_self_edit_used BOOLEAN NOT NULL DEFAULT FALSE;',
      'ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS can_reupload_photo BOOLEAN NOT NULL DEFAULT FALSE;',
      'ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS photo_updated_at TIMESTAMPTZ NULL;',
    ];
    for (const stmt of stmts) {
      await pool.query(stmt).catch(() => {});
    }
  }

  static async resolveStudentProfileId(userId: string, schoolId?: string): Promise<string | null> {
    const query = `
      SELECT stp.id
      FROM student_profiles stp
      JOIN users u ON stp.user_id = u.id
      WHERE stp.user_id = $1
        AND ($2::uuid IS NULL OR u.school_id = $2::uuid)
      LIMIT 1;
    `;
    const { rows } = await pool.query(query, [userId, schoolId || null]);
    return rows[0]?.id || null;
  }

  static async resolveStaffProfileId(userId: string, schoolId?: string): Promise<string | null> {
    const query = `
      SELECT sp.id
      FROM staff_profiles sp
      JOIN users u ON sp.user_id = u.id
      WHERE sp.user_id = $1
        AND ($2::uuid IS NULL OR u.school_id = $2::uuid)
      LIMIT 1;
    `;
    const { rows } = await pool.query(query, [userId, schoolId || null]);
    return rows[0]?.id || null;
  }

  static async getStudentProfile(profileId: string, schoolId?: string) {
    const query = `
      SELECT 
        stp.id,
        stp.user_id,
        stp.admission_number,
        stp.roll_number,
        stp.first_name,
        stp.last_name,
        CONCAT(stp.first_name, ' ', stp.last_name) AS full_name,
        stp.gender,
        stp.date_of_birth::text AS date_of_birth,
        stp.admission_date::text AS admission_date,
        stp.current_class_id,
        stp.current_section_id,
        stp.father_name,
        stp.mother_name,
        COALESCE(stp.guardian_name, stp.extra_data->>'guard_name') AS guardian_name,
        stp.emergency_phone,
        stp.blood_group,
        stp.medical_notes,
        stp.document_url,
        stp.photo_url,
        stp.photo_url AS avatar_url,
        COALESCE(stp.photo_self_edit_used, FALSE) AS photo_self_edit_used,
        COALESCE(stp.can_reupload_photo, FALSE) AS can_reupload_photo,
        stp.photo_updated_at,
        (NOT COALESCE(stp.photo_self_edit_used, FALSE) OR COALESCE(stp.can_reupload_photo, FALSE)) AS can_upload_photo,
        stp.address,
        stp.caste,
        stp.religion,
        stp.nationality,
        stp.student_aadhar,
        stp.aadhar_father,
        stp.aadhar_mother,
        stp.father_pan,
        stp.pan_mother,
        stp.extra_data,
        u.identifier,
        u.email,
        u.phone,
        c.id AS class_id,
        c.name AS class_name,
        s.id AS section_id,
        s.name AS section_name,
        sch.name AS school_name,
        COALESCE(
          NULLIF(TRIM(sch.contact_phone), ''),
          NULLIF(TRIM(sch.branding_config->>'phone'), ''),
          NULLIF(TRIM(sch.admin_phone), '')
        ) AS school_phone,
        COALESCE(
          NULLIF(TRIM(sch.contact_email), ''),
          NULLIF(TRIM(sch.branding_config->>'email'), ''),
          NULLIF(TRIM(sch.admin_email), '')
        ) AS school_email,
        COALESCE(
          NULLIF(TRIM(sch.address), ''),
          NULLIF(TRIM(sch.branding_config->>'address'), '')
        ) AS school_address,
        sch.menu_config,
        sch.branding_config
      FROM student_profiles stp
      LEFT JOIN classes c ON stp.current_class_id = c.id
      LEFT JOIN sections s ON stp.current_section_id = s.id
      JOIN users u ON stp.user_id = u.id
      JOIN schools sch ON u.school_id = sch.id
      WHERE stp.id = $1
        AND ($2::uuid IS NULL OR u.school_id = $2::uuid);
    `;
    try {
      const { rows } = await pool.query(query, [profileId, schoolId || null]);
      return rows[0] || null;
    } catch (err: any) {
      if (
        err.message &&
        (err.message.includes('document_url') ||
          err.message.includes('photo_url') ||
          err.message.includes('guardian_name') ||
          err.message.includes('photo_self_edit_used') ||
          err.message.includes('can_reupload_photo') ||
          err.message.includes('photo_updated_at'))
      ) {
        await this.ensureStudentColumns();
        const { rows } = await pool.query(query, [profileId, schoolId || null]);
        return rows[0] || null;
      }
      throw err;
    }
  }

  static async getStudentPhotoPermission(profileId: string, schoolId?: string) {
    const query = `
      SELECT
        stp.id,
        stp.photo_url,
        COALESCE(stp.photo_self_edit_used, FALSE) AS photo_self_edit_used,
        COALESCE(stp.can_reupload_photo, FALSE) AS can_reupload_photo
      FROM student_profiles stp
      JOIN users u ON stp.user_id = u.id
      WHERE stp.id = $1
        AND ($2::uuid IS NULL OR u.school_id = $2::uuid)
      LIMIT 1;
    `;
    try {
      const { rows } = await pool.query(query, [profileId, schoolId || null]);
      return rows[0] || null;
    } catch (err: any) {
      if (
        err.message &&
        (err.message.includes('photo_url') ||
          err.message.includes('photo_self_edit_used') ||
          err.message.includes('can_reupload_photo'))
      ) {
        await this.ensureStudentColumns();
        const { rows } = await pool.query(query, [profileId, schoolId || null]);
        return rows[0] || null;
      }
      throw err;
    }
  }

  static async updateStudentProfile(
    profileId: string,
    schoolId: string | undefined,
    updates: {
      emergency_phone?: string | null;
      blood_group?: string | null;
      medical_notes?: string | null;
      document_url?: string | null;
      photo_url?: string | null;
    }
  ) {
    const existing = await this.getStudentPhotoPermission(profileId, schoolId);
    if (!existing) {
      throw new Error('PROFILE_NOT_FOUND');
    }

    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (updates.emergency_phone !== undefined) {
      fields.push(`emergency_phone = $${idx++}`);
      values.push(updates.emergency_phone);
    }
    if (updates.blood_group !== undefined) {
      fields.push(`blood_group = $${idx++}`);
      values.push(updates.blood_group);
    }
    if (updates.medical_notes !== undefined) {
      fields.push(`medical_notes = $${idx++}`);
      values.push(updates.medical_notes);
    }
    if (updates.document_url !== undefined) {
      fields.push(`document_url = $${idx++}`);
      values.push(updates.document_url);
    }
    if (updates.photo_url !== undefined) {
      if (updates.photo_url && updates.photo_url.trim() !== '') {
        if (existing.photo_self_edit_used && !existing.can_reupload_photo) {
          throw new Error('PHOTO_CHANGE_LIMIT_REACHED');
        }
        fields.push(`photo_url = $${idx++}`);
        values.push(updates.photo_url.trim());
        fields.push('photo_self_edit_used = TRUE');
        fields.push('can_reupload_photo = FALSE');
        fields.push('photo_updated_at = CURRENT_TIMESTAMP');
      }
    }

    if (fields.length > 0) {
      values.push(profileId);
      const query = `
        UPDATE student_profiles
        SET ${fields.join(', ')}, updated_at = CURRENT_TIMESTAMP
        WHERE id = $${idx};
      `;
      try {
        await pool.query(query, values);
      } catch (err: any) {
        if (
          err.message &&
          (err.message.includes('document_url') ||
            err.message.includes('photo_url') ||
            err.message.includes('photo_self_edit_used') ||
            err.message.includes('can_reupload_photo') ||
            err.message.includes('photo_updated_at'))
        ) {
          await this.ensureStudentColumns();
          await pool.query(query, values);
        } else {
          throw err;
        }
      }
    }

    return await this.getStudentProfile(profileId, schoolId);
  }

  static async getStaffProfile(profileId: string, schoolId?: string) {
    const query = `
      SELECT 
        sp.id,
        sp.employee_code,
        sp.first_name,
        sp.last_name,
        sp.gender,
        sp.date_of_birth,
        sp.qualification,
        sp.joining_date,
        sp.emergency_phone,
        sp.phone,
        sp.blood_group,
        sp.photo_url,
        sp.photo_url AS avatar_url,
        sch.name AS school_name,
        sch.menu_config,
        sch.branding_config,
        COALESCE(
          json_agg(
            DISTINCT jsonb_build_object(
              'assignment_type', sa.assignment_type,
              'wing_id', sa.wing_id,
              'class_id', sa.class_id,
              'section_id', sa.section_id
            )
          ) FILTER (WHERE sa.id IS NOT NULL),
          '[]'
        ) AS assignments
      FROM staff_profiles sp
      JOIN users u ON sp.user_id = u.id
      JOIN schools sch ON u.school_id = sch.id
      LEFT JOIN staff_assignments sa ON sp.id = sa.staff_id
      WHERE sp.id = $1
        AND ($2::uuid IS NULL OR u.school_id = $2::uuid)
      GROUP BY sp.id, sch.name, sch.menu_config, sch.branding_config;
    `;
    try {
      const { rows } = await pool.query(query, [profileId, schoolId || null]);
      return rows[0] || null;
    } catch (err: any) {
      if (err.message && err.message.includes('photo_url')) {
        await pool.query('ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS photo_url TEXT NULL;').catch(() => {});
        const { rows } = await pool.query(query, [profileId, schoolId || null]);
        return rows[0] || null;
      }
      throw err;
    }
  }

  static async updateStaffProfile(
    profileId: string,
    schoolId: string | undefined,
    updates: {
      emergency_phone?: string | null;
      phone?: string | null;
      qualification?: string | null;
      blood_group?: string | null;
    }
  ) {
    const existing = await this.getStaffProfile(profileId, schoolId);
    if (!existing) {
      throw new Error('PROFILE_NOT_FOUND');
    }

    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (updates.emergency_phone !== undefined) {
      fields.push(`emergency_phone = $${idx++}`);
      values.push(updates.emergency_phone);
    }
    if (updates.phone !== undefined) {
      fields.push(`phone = $${idx++}`);
      values.push(updates.phone);
    }
    if (updates.qualification !== undefined) {
      fields.push(`qualification = $${idx++}`);
      values.push(updates.qualification);
    }
    if (updates.blood_group !== undefined) {
      fields.push(`blood_group = $${idx++}`);
      values.push(updates.blood_group);
    }

    if (fields.length > 0) {
      values.push(profileId);
      const query = `
        UPDATE staff_profiles
        SET ${fields.join(', ')}, updated_at = CURRENT_TIMESTAMP
        WHERE id = $${idx};
      `;
      await pool.query(query, values);
    }

    return await this.getStaffProfile(profileId, schoolId);
  }

  static async getStudentWithSchool(studentId: string) {
    const query = `
      SELECT stp.id, stp.current_class_id, stp.current_section_id, u.school_id
      FROM student_profiles stp
      JOIN users u ON stp.user_id = u.id
      WHERE stp.id = $1;
    `;
    const { rows } = await pool.query(query, [studentId]);
    return rows[0] || null;
  }

  static async isClassTeacherForClass(staffId: string, classId: string, sectionId: string): Promise<boolean> {
    const query = `
      SELECT 1 FROM staff_assignments
      WHERE staff_id = $1 AND class_id = $2 AND section_id = $3 AND assignment_type = 'CLASS_TEACHER'
      LIMIT 1;
    `;
    const { rows } = await pool.query(query, [staffId, classId, sectionId]);
    return rows.length > 0;
  }

  static async updateStudentProfileByTeacher(
    studentId: string,
    updates: {
      roll_number?: string | null;
      blood_group?: string | null;
      emergency_phone?: string | null;
      medical_notes?: string | null;
      document_url?: string | null;
    }
  ) {
    const fields: string[] = [];
    const values: any[] = [];
    let idx = 1;

    if (updates.roll_number !== undefined) {
      fields.push(`roll_number = $${idx++}`);
      values.push(updates.roll_number);
    }
    if (updates.blood_group !== undefined) {
      fields.push(`blood_group = $${idx++}`);
      values.push(updates.blood_group);
    }
    if (updates.emergency_phone !== undefined) {
      fields.push(`emergency_phone = $${idx++}`);
      values.push(updates.emergency_phone);
    }
    if (updates.medical_notes !== undefined) {
      fields.push(`medical_notes = $${idx++}`);
      values.push(updates.medical_notes);
    }
    if (updates.document_url !== undefined) {
      fields.push(`document_url = $${idx++}`);
      values.push(updates.document_url);
    }

    if (fields.length > 0) {
      values.push(studentId);
      const query = `
        UPDATE student_profiles
        SET ${fields.join(', ')}, updated_at = CURRENT_TIMESTAMP
        WHERE id = $${idx};
      `;
      try {
        await pool.query(query, values);
      } catch (err: any) {
        if (err.message && err.message.includes('document_url')) {
          await this.ensureStudentColumns();
          await pool.query(query, values);
        } else {
          throw err;
        }
      }
    }

    return await this.getStudentProfile(studentId);
  }
}
