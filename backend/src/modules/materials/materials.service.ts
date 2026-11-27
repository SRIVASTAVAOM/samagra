import crypto from 'crypto';
import { pool } from '../../config/db.config';
import { env } from '../../config/env.config';
import { TokenPayload } from '../../types/auth.types';
import { CloudinaryService } from '../../services/cloudinary.service';
import { MaterialsRepository, AcademicMaterial } from './materials.repository';

export class MaterialsService {
  static async resolveStudentEnrollment(
    user: TokenPayload
  ): Promise<{ current_class_id: string | null; current_section_id: string | null } | null> {
    const { rows } = await pool.query(
      `SELECT stp.current_class_id, stp.current_section_id
       FROM student_profiles stp
       JOIN users u ON stp.user_id = u.id
       WHERE u.school_id = $3
         AND (
           ($1 <> '' AND stp.id::text = $1)
           OR ($2 <> '' AND stp.user_id::text = $2)
         )
       LIMIT 1;`,
      [user.profileId || '', user.userId || '', user.schoolId]
    );
    return rows[0] || null;
  }

  /**
   * Verifies teacher is allocated to class and subject.
   */
  static async verifyTeacherAllocation(
    staffId: string,
    classId: string,
    subjectId: string,
    sectionId?: string
  ): Promise<void> {
    let query = `
      SELECT 1 FROM teacher_subject_allocations 
      WHERE staff_id = $1 AND class_id = $2 AND subject_id = $3
      UNION
      SELECT 1 FROM staff_assignments
      WHERE staff_id = $1 AND class_id = $2
    `;
    const params: any[] = [staffId, classId, subjectId];

    if (sectionId) {
      query += ` AND (section_id IS NULL OR section_id = $4)`;
      params.push(sectionId);
    }

    const { rows } = await pool.query(query, params);
    if (rows.length === 0) {
      throw {
        statusCode: 403,
        message: 'Teachers can only upload materials for their allocated classes and subjects.',
      };
    }
  }

  static async initiatePresignedUpload(
    user: TokenPayload,
    data: {
      classId: string;
      sectionId?: string;
      subjectId: string;
      title: string;
      description?: string;
      fileName: string;
      fileSizeBytes: number;
      contentType: string;
    },
    requestBaseUrl?: string
  ): Promise<{
    uploadUrl: string;
    fileKey: string;
    materialId: string;
    expiresInSeconds: number;
    isMock?: boolean;
  }> {
    if (!user.roles.includes('TEACHER')) {
      throw { statusCode: 403, message: 'Only teachers are authorized to upload academic materials.' };
    }

    // 1. File Type Validation against allowlist
    const allowedMimeTypes = env.ALLOWED_MIME_TYPES.split(',').map((m) => m.trim().toLowerCase());
    if (!allowedMimeTypes.includes(data.contentType.toLowerCase())) {
      throw {
        statusCode: 400,
        message: `File type '${data.contentType}' is not permitted. Allowed types: ${env.ALLOWED_MIME_TYPES}`,
      };
    }

    // 2. File Size Validation against limit
    const maxSizeBytes = parseInt(env.MAX_UPLOAD_SIZE_BYTES, 10);
    if (data.fileSizeBytes > maxSizeBytes) {
      throw {
        statusCode: 400,
        message: `File size exceeds the allowed maximum limit of ${(maxSizeBytes / (1024 * 1024)).toFixed(1)} MB.`,
      };
    }

    // 3. Authorization Check
    await this.verifyTeacherAllocation(user.profileId!, data.classId, data.subjectId, data.sectionId);

    // 4. Server-Generated Secure Key (prevent arbitrary client paths)
    const sanitizedFileName = data.fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
    const uniqueId = crypto.randomUUID();
    const serverFileKey = `schools/${user.schoolId}/classes/${data.classId}/subjects/${data.subjectId}/${uniqueId}_${sanitizedFileName}`;

    // 5. Create Pending Material Record in Database
    const material = await MaterialsRepository.createPendingMaterial({
      schoolId: user.schoolId,
      classId: data.classId,
      sectionId: data.sectionId,
      subjectId: data.subjectId,
      uploadedByStaffId: user.profileId!,
      title: data.title,
      description: data.description,
      s3FileKey: serverFileKey,
      fileName: data.fileName,
      fileSizeBytes: data.fileSizeBytes,
      contentType: data.contentType,
    });

    // 6. Generate Short-Lived Pre-Signed Upload URL (5 minutes)
    const presigned = await CloudinaryService.generatePresignedUploadUrl(
      serverFileKey,
      data.contentType,
      300,
      requestBaseUrl
    );

    return {
      uploadUrl: presigned.uploadUrl,
      fileKey: presigned.fileKey,
      materialId: material.id,
      expiresInSeconds: presigned.expiresInSeconds,
      isMock: presigned.isMock,
    };
  }

  static async verifyUpload(user: TokenPayload, materialId: string): Promise<AcademicMaterial> {
    if (!user.roles.includes('TEACHER')) {
      throw { statusCode: 403, message: 'Only uploading teachers can verify uploaded materials.' };
    }

    const material = await MaterialsRepository.markMaterialVerified(materialId, user.profileId!);
    if (!material) {
      throw { statusCode: 404, message: 'Material not found or you are not the uploader of this material.' };
    }

    return material;
  }

  static async getMaterials(
    user: TokenPayload,
    classId: string,
    subjectId: string,
    sectionId?: string
  ): Promise<AcademicMaterial[]> {
    // If student, check enrolled class
    if (user.roles.includes('STUDENT')) {
      const enrollment = await this.resolveStudentEnrollment(user);
      if (!enrollment) {
        throw { statusCode: 404, message: 'Student profile not found. Please verify your enrollment.' };
      }
      const enrolledClassId = enrollment.current_class_id;
      if (!enrolledClassId) {
        throw { statusCode: 400, message: 'Student is not actively assigned to any class.' };
      }
      if (enrolledClassId !== classId) {
        throw { statusCode: 403, message: 'Students can only view study materials for their own class.' };
      }
      return await MaterialsRepository.getMaterialsByClassAndSubject(
        classId,
        subjectId,
        enrollment.current_section_id || undefined,
        user.schoolId
      );
    }

    // If teacher, check allocation
    if (user.roles.includes('TEACHER')) {
      const { rows } = await pool.query(
        `SELECT 1 FROM staff_assignments sa
         JOIN staff_profiles sp ON sa.staff_id = sp.id
         JOIN users u ON sp.user_id = u.id
         WHERE sa.staff_id = $1 AND sa.class_id = $2 AND u.school_id = $3
         UNION
         SELECT 1 FROM teacher_subject_allocations tsa
         JOIN staff_profiles sp ON tsa.staff_id = sp.id
         JOIN users u ON sp.user_id = u.id
         WHERE tsa.staff_id = $1 AND tsa.class_id = $2 AND u.school_id = $3;`,
        [user.profileId, classId, user.schoolId]
      );
      if (rows.length === 0) {
        throw { statusCode: 403, message: 'Teachers can only access study materials for their allocated classes.' };
      }
    }

    return await MaterialsRepository.getMaterialsByClassAndSubject(classId, subjectId, sectionId, user.schoolId);
  }

  static async getDownloadUrl(
    user: TokenPayload,
    materialId: string
  ): Promise<{ downloadUrl: string; fileName: string; contentType: string; expiresInSeconds: number; isMock: boolean }> {
    const material = await MaterialsRepository.getMaterialById(materialId);
    if (!material) {
      throw { statusCode: 404, message: 'Academic material not found.' };
    }

    if (material.school_id !== user.schoolId) {
      throw { statusCode: 403, message: 'Unauthorized: Material does not belong to your school.' };
    }

    if (!material.is_verified) {
      throw { statusCode: 400, message: 'Academic material upload is not yet verified.' };
    }

    // Scope check: Student must be in that class and section
    if (user.roles.includes('STUDENT')) {
      const enrollment = await this.resolveStudentEnrollment(user);
      if (!enrollment || enrollment.current_class_id !== material.class_id) {
        throw { statusCode: 403, message: 'Unauthorized: You are not enrolled in the class for this material.' };
      }
      if (material.section_id && enrollment.current_section_id && material.section_id !== enrollment.current_section_id) {
        throw { statusCode: 403, message: 'Unauthorized: Material is scoped to a different section.' };
      }
    }

    // Generate short-lived GET pre-signed URL (15 minutes)
    const { downloadUrl, isMock } = await CloudinaryService.generatePresignedDownloadUrl(material.s3_file_key, 900);

    return {
      downloadUrl,
      fileName: material.file_name,
      contentType: material.content_type,
      expiresInSeconds: 900,
      isMock,
    };
  }

  static async getAdminMaterials(
    user: TokenPayload,
    filters: { classId?: string; sectionId?: string; subjectId?: string; type?: string; search?: string }
  ): Promise<AcademicMaterial[]> {
    return await MaterialsRepository.getAdminMaterials(user.schoolId, filters);
  }

  static async createAdminMaterial(user: TokenPayload, data: any): Promise<AcademicMaterial> {
    const classId = data.classId || data.class_id;
    const sectionId = data.sectionId || data.section_id;
    const subjectId = data.subjectId || data.subject_id;
    const title = data.title;
    const description = data.description;
    const materialType = data.materialType || data.material_type || data.type || 'Study Material';
    const fileName = data.fileName || data.file_name || 'document.pdf';
    const fileSizeBytes = data.fileSizeBytes || data.file_size_bytes || 1048576;
    const contentType = data.contentType || data.content_type || 'application/pdf';

    if (!classId || !subjectId || !title) {
      throw { statusCode: 400, message: 'Class, Subject, and Document Title are required.' };
    }

    // Resolve staff profile ID
    let staffId = data.staffId || data.staff_id;
    if (!staffId) {
      if (user.profileId) {
        staffId = user.profileId;
      } else {
        const staffRes = await pool.query(
          `SELECT sp.id FROM staff_profiles sp JOIN users u ON sp.user_id = u.id WHERE u.school_id = $1 LIMIT 1;`,
          [user.schoolId]
        );
        if (staffRes.rows.length > 0) {
          staffId = staffRes.rows[0].id;
        } else {
          throw { statusCode: 400, message: 'No staff profile found in school to attribute material.' };
        }
      }
    }

    const cleanFileName = fileName.replace(/[^a-zA-Z0-9._-]/g, '_');
    const s3FileKey =
      data.s3FileKey ||
      data.s3_file_key ||
      data.fileKey ||
      data.file_key ||
      data.fileUrl ||
      data.file_url ||
      `schools/${user.schoolId}/materials/${Date.now()}_${cleanFileName}`;

    return await MaterialsRepository.createAdminMaterial({
      schoolId: user.schoolId,
      classId,
      sectionId: sectionId || undefined,
      subjectId,
      uploadedByStaffId: staffId,
      title: title.trim(),
      description: description ? description.trim() : undefined,
      materialType,
      s3FileKey,
      fileName: cleanFileName,
      fileSizeBytes: Number(fileSizeBytes),
      contentType,
    });
  }

  static async updateAdminMaterial(user: TokenPayload, id: string, data: any): Promise<AcademicMaterial> {
    const updated = await MaterialsRepository.updateAdminMaterial(id, user.schoolId, {
      classId: data.classId || data.class_id,
      sectionId: data.sectionId !== undefined ? data.sectionId : data.section_id,
      subjectId: data.subjectId || data.subject_id,
      title: data.title ? data.title.trim() : undefined,
      description: data.description !== undefined ? data.description.trim() : undefined,
      materialType: data.materialType || data.material_type || data.type,
      fileName: data.fileName || data.file_name,
    });
    if (!updated) {
      throw { statusCode: 404, message: 'Study material not found or unauthorized' };
    }
    return updated;
  }

  static async deleteAdminMaterial(user: TokenPayload, id: string): Promise<boolean> {
    const deleted = await MaterialsRepository.deleteAdminMaterial(id, user.schoolId);
    if (!deleted) {
      throw { statusCode: 404, message: 'Study material not found or cannot be deleted' };
    }
    return deleted;
  }
}
