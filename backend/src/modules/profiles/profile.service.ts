import { ProfileRepository } from './profile.repository';
import { TokenPayload } from '../../types/auth.types';
import { CloudinaryService } from '../../services/cloudinary.service';

export class ProfileService {
  private static async resolveStudentId(user: TokenPayload): Promise<string> {
    if (user.profileId) return user.profileId;
    if (user.userId) {
      const resolved = await ProfileRepository.resolveStudentProfileId(user.userId, user.schoolId);
      if (resolved) return resolved;
    }
    throw new Error('PROFILE_NOT_FOUND');
  }

  private static async resolveStaffId(user: TokenPayload): Promise<string> {
    if (user.profileId) return user.profileId;
    if (user.userId) {
      const resolved = await ProfileRepository.resolveStaffProfileId(user.userId, user.schoolId);
      if (resolved) return resolved;
    }
    throw new Error('PROFILE_NOT_FOUND');
  }

  static async getStudentProfile(user: TokenPayload) {
    const profileId = await this.resolveStudentId(user);
    const profile = await ProfileRepository.getStudentProfile(profileId, user.schoolId);
    if (!profile) throw new Error('PROFILE_NOT_FOUND');
    return profile;
  }

  static async updateStudentProfile(
    user: TokenPayload,
    updates: {
      emergency_phone?: string | null;
      blood_group?: string | null;
      medical_notes?: string | null;
      document_url?: string | null;
      photo_url?: string | null;
    }
  ) {
    const profileId = await this.resolveStudentId(user);
    const previous = updates.photo_url
      ? await ProfileRepository.getStudentPhotoPermission(profileId, user.schoolId)
      : null;

    const updated = await ProfileRepository.updateStudentProfile(profileId, user.schoolId, updates);
    if (!updated) throw new Error('PROFILE_NOT_FOUND');

    if (
      updates.photo_url &&
      previous?.photo_url &&
      previous.photo_url !== updates.photo_url &&
      previous.photo_url.includes('cloudinary')
    ) {
      CloudinaryService.deletePhoto(previous.photo_url).catch(() => {});
    }

    return updated;
  }

  static async uploadStudentPhoto(
    user: TokenPayload,
    file: { buffer: Buffer; fileName: string; mimeType: string }
  ) {
    const profileId = await this.resolveStudentId(user);
    const permission = await ProfileRepository.getStudentPhotoPermission(profileId, user.schoolId);
    if (!permission) throw new Error('PROFILE_NOT_FOUND');

    if (permission.photo_self_edit_used && !permission.can_reupload_photo) {
      throw new Error('PHOTO_CHANGE_LIMIT_REACHED');
    }

    const uploadResult = await CloudinaryService.uploadPhoto(file.buffer, {
      fileName: file.fileName,
      mimeType: file.mimeType,
      userId: user.userId,
      role: user.roles?.join(','),
      subfolder: 'photos/students',
    });

    const updated = await ProfileRepository.updateStudentProfile(profileId, user.schoolId, {
      photo_url: uploadResult.secureUrl,
    });
    if (!updated) throw new Error('PROFILE_NOT_FOUND');

    if (
      permission.photo_url &&
      permission.photo_url !== uploadResult.secureUrl &&
      permission.photo_url.includes('cloudinary')
    ) {
      CloudinaryService.deletePhoto(permission.photo_url).catch(() => {});
    }

    return updated;
  }

  static async getStaffProfile(user: TokenPayload) {
    const profileId = await this.resolveStaffId(user);
    const profile = await ProfileRepository.getStaffProfile(profileId, user.schoolId);
    if (!profile) throw new Error('PROFILE_NOT_FOUND');
    return profile;
  }

  static async updateStaffProfile(
    user: TokenPayload,
    updates: {
      emergency_phone?: string | null;
      phone?: string | null;
      qualification?: string | null;
      blood_group?: string | null;
    }
  ) {
    const profileId = await this.resolveStaffId(user);
    const updated = await ProfileRepository.updateStaffProfile(profileId, user.schoolId, updates);
    if (!updated) throw new Error('PROFILE_NOT_FOUND');
    return updated;
  }

  static async updateStudentProfileByTeacher(
    user: TokenPayload,
    studentId: string,
    updates: {
      roll_number?: string | null;
      blood_group?: string | null;
      emergency_phone?: string | null;
      medical_notes?: string | null;
      document_url?: string | null;
    }
  ) {
    const staffId = await this.resolveStaffId(user);

    const student = await ProfileRepository.getStudentWithSchool(studentId);
    if (!student) throw new Error('STUDENT_NOT_FOUND');

    if (student.school_id !== user.schoolId) {
      throw new Error('FORBIDDEN_SCHOOL');
    }

    if (!student.current_class_id || !student.current_section_id) {
      throw new Error('STUDENT_NOT_ENROLLED');
    }

    const isClassTeacher = await ProfileRepository.isClassTeacherForClass(
      staffId,
      student.current_class_id,
      student.current_section_id
    );

    if (!isClassTeacher) {
      throw new Error('FORBIDDEN_NOT_CLASS_TEACHER');
    }

    return await ProfileRepository.updateStudentProfileByTeacher(studentId, updates);
  }
}
