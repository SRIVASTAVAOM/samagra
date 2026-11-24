import { Request, Response } from 'express';
import { z } from 'zod';
import { AdminService } from './admin.service';
import { pool } from '../../config/db.config';
import { CloudinaryService } from '../../services/cloudinary.service';
import multer from 'multer';
import path from 'path';
import fs from 'fs';

// Multer configuration for photo upload
const ALLOWED_PHOTO_TYPES = ['image/jpeg', 'image/png', 'image/webp'];
const MAX_PHOTO_SIZE = 5 * 1024 * 1024; // 5MB

const photoStorage = multer.memoryStorage();
const photoUploadMiddleware = multer({
  storage: photoStorage,
  limits: { fileSize: MAX_PHOTO_SIZE },
  fileFilter: (_req, file, cb) => {
    if (ALLOWED_PHOTO_TYPES.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error(`Invalid file type. Allowed: ${ALLOWED_PHOTO_TYPES.join(', ')}`));
    }
  },
}).single('photo');

export { photoUploadMiddleware };

const saveGridSlotItemSchema = z.object({
  day_of_week: z.coerce.number().int().min(1).max(6).optional(),
  dayOfWeek: z.coerce.number().int().min(1).max(6).optional(),
  period_number: z.coerce.number().int().min(1).max(8).optional(),
  periodNumber: z.coerce.number().int().min(1).max(8).optional(),
  start_time: z.string().min(1).optional(),
  startTime: z.string().min(1).optional(),
  end_time: z.string().min(1).optional(),
  endTime: z.string().min(1).optional(),
  subject_id: z.string().uuid().optional(),
  subjectId: z.string().uuid().optional(),
  teacher_id: z.string().uuid().optional(),
  teacherId: z.string().uuid().optional(),
  room_number: z.string().nullable().optional(),
  roomNumber: z.string().nullable().optional(),
}).transform((data) => ({
  day_of_week: (data.day_of_week || data.dayOfWeek)!,
  period_number: (data.period_number || data.periodNumber)!,
  start_time: (data.start_time || data.startTime)!,
  end_time: (data.end_time || data.endTime)!,
  subject_id: (data.subject_id || data.subjectId)!,
  teacher_id: (data.teacher_id || data.teacherId)!,
  room_number: data.room_number ?? data.roomNumber ?? null,
})).refine(
  (d) =>
    d.day_of_week !== undefined &&
    d.period_number !== undefined &&
    !!d.start_time &&
    !!d.end_time &&
    !!d.subject_id &&
    !!d.teacher_id,
  {
    message: 'day_of_week, period_number, start_time, end_time, subject_id, and teacher_id are required for each slot',
  }
);

const saveTimetableGridSchema = z.object({
  class_id: z.string().uuid().optional(),
  classId: z.string().uuid().optional(),
  section_id: z.string().uuid().optional(),
  sectionId: z.string().uuid().optional(),
  academic_year_id: z.string().uuid().optional(),
  academicYearId: z.string().uuid().optional(),
  slots: z.array(saveGridSlotItemSchema),
}).transform((data) => ({
  class_id: (data.class_id || data.classId)!,
  section_id: (data.section_id || data.sectionId)!,
  academic_year_id: data.academic_year_id || data.academicYearId,
  slots: data.slots,
})).refine((d) => !!d.class_id && !!d.section_id, {
  message: 'class_id and section_id are required',
});

export class AdminController {
  /**
   * GET /api/v1/admin/dashboard/summary
   */
  static async getDashboardSummary(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { date, class_id, classId, section_id, sectionId, month } = req.query;
      const summary = await AdminService.getDashboardSummary(
        user,
        typeof date === 'string' ? date : undefined,
        (class_id || classId) as string,
        (section_id || sectionId) as string,
        typeof month === 'string' ? month : undefined
      );
      res.status(200).json({
        success: true,
        data: summary,
      });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to fetch admin dashboard summary',
      });
    }
  }

  /**
   * GET /api/v1/admin/timetable/grid
   */
  static async getTimetableGrid(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const classId = (req.query.class_id || req.query.classId) as string;
      const sectionId = (req.query.section_id || req.query.sectionId) as string;

      if (!classId || !sectionId) {
        res.status(400).json({
          success: false,
          error: 'class_id and section_id query parameters are required',
        });
        return;
      }

      const grid = await AdminService.getTimetableGrid(user, classId, sectionId);
      res.status(200).json({
        success: true,
        data: grid,
      });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to fetch timetable grid',
      });
    }
  }

  /**
   * POST /api/v1/admin/timetable/grid
   */
  static async saveTimetableGrid(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const validated = saveTimetableGridSchema.parse(req.body);
      const updatedGrid = await AdminService.saveTimetableGrid(user, validated);
      res.status(200).json({
        success: true,
        data: updatedGrid,
        message: 'Master timetable grid updated successfully',
      });
    } catch (error: any) {
      if (error instanceof z.ZodError) {
        res.status(400).json({
          success: false,
          error: 'Validation failed',
          details: error.errors.map((e) => e.message),
        });
        return;
      }
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to update timetable grid',
      });
    }
  }

  /**
   * GET /api/v1/admin/reports/greensheet
   */
  static async getGreensheet(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const classId = (req.query.class_id || req.query.classId) as string;
      const sectionId = (req.query.section_id || req.query.sectionId) as string;
      const examId = (req.query.exam_id || req.query.examId) as string | undefined;

      if (!classId || !sectionId) {
        res.status(400).json({
          success: false,
          error: 'class_id and section_id query parameters are required',
        });
        return;
      }

      const greensheet = await AdminService.getGreensheet(user, classId, sectionId, examId);
      res.status(200).json({
        success: true,
        data: greensheet,
      });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to generate greensheet tabulation',
      });
    }
  }

  /**
   * GET /api/v1/admin/staff/teachers
   */
  static async getTeachers(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const teachers = await AdminService.getTeachers(user);
      res.status(200).json({ success: true, data: teachers });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * GET /api/v1/admin/timetable/teacher/:teacherId
   */
  static async getTeacherTimetable(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { teacherId } = req.params;
      const timetable = await AdminService.getTeacherTimetable(user, teacherId);
      res.status(200).json({ success: true, data: timetable });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * GET /api/v1/admin/timetable/substitutions
   */
  static async getSubstitutions(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const date = req.query.date as string | undefined;
      const substitutions = await AdminService.getSubstitutions(user, date);
      res.status(200).json({ success: true, data: substitutions });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * POST /api/v1/admin/timetable/substitutions
   */
  static async assignSubstitution(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const sub = await AdminService.assignSubstitution(user, req.body);
      res.status(201).json({
        success: true,
        message: 'Substitution assigned successfully and synced with teacher app',
        data: sub,
      });
    } catch (error: any) {
      res.status(error.statusCode || 400).json({ success: false, error: error.message });
    }
  }

  /**
   * DELETE /api/v1/admin/timetable/substitutions/:id
   */
  static async deleteSubstitution(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const deleted = await AdminService.deleteSubstitution(user, id);
      if (!deleted) {
        res.status(404).json({ success: false, error: 'Substitution not found' });
        return;
      }
      res.status(200).json({ success: true, message: 'Substitution cancelled successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * GET /api/v1/admin/students
   */
  static async getStudentsList(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const classId = (req.query.class_id || req.query.classId) as string | undefined;
      const sectionId = (req.query.section_id || req.query.sectionId) as string | undefined;
      const classIdsParam = (req.query.class_ids || req.query.classIds) as string | string[] | undefined;
      const sectionIdsParam = (req.query.section_ids || req.query.sectionIds) as string | string[] | undefined;
      const search = req.query.search as string | undefined;

      const classIds = Array.isArray(classIdsParam)
        ? classIdsParam
        : typeof classIdsParam === 'string'
        ? classIdsParam.split(',').map((s) => s.trim()).filter(Boolean)
        : undefined;

      const sectionIds = Array.isArray(sectionIdsParam)
        ? sectionIdsParam
        : typeof sectionIdsParam === 'string'
        ? sectionIdsParam.split(',').map((s) => s.trim()).filter(Boolean)
        : undefined;

      const students = await AdminService.getStudentsList(user, {
        classId,
        sectionId,
        classIds,
        sectionIds,
        search,
      });
      res.status(200).json({ success: true, data: students });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * GET /api/v1/admin/students/:id
   */
  static async getStudentDetails(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const student = await AdminService.getStudentDetails(user, id);
      res.status(200).json({ success: true, data: student });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * PATCH /api/v1/admin/students/:id
   */
  static async updateStudent(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const updated = await AdminService.updateStudent(user, id, req.body);
      res.status(200).json({ success: true, data: updated, message: 'Student updated successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * POST /api/v1/admin/students/:id/reset-password
   */
  static async resetStudentPassword(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const { password } = req.body;
      const result = await AdminService.resetStudentPassword(user, id, password);
      res.status(200).json({ success: true, message: 'Student password reset successfully', data: result });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * POST /api/v1/admin/students (New Admission Form)
   */
  static async createStudent(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const created = await AdminService.createStudent(user, req.body);
      res.status(201).json({ success: true, message: 'Student admission successfully created', data: created });
    } catch (error: any) {
      res.status(error.statusCode || 400).json({
        success: false,
        message: error.message,
        error: error.message,
      });
    }
  }

  /**
   * GET /api/v1/admin/staff
   */
  static async getAllStaff(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const search = req.query.search as string | undefined;
      const isActiveParam = req.query.is_active as string | undefined;
      const isActive =
        isActiveParam === 'true' ? true : isActiveParam === 'false' ? false : undefined;
      const staff = await AdminService.getAllStaff(user, search, isActive);
      res.status(200).json({ success: true, data: staff });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * POST /api/v1/admin/staff
   */
  static async createStaff(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const created = await AdminService.createStaff(user, req.body);
      res.status(201).json({ success: true, message: 'Staff created successfully', data: created });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * PATCH /api/v1/admin/staff/:id
   */
  static async updateStaff(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const updated = await AdminService.updateStaff(user, id, req.body);
      res.status(200).json({ success: true, message: 'Staff updated successfully', data: updated });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * POST /api/v1/admin/staff/:id/reset-password
   */
  static async resetStaffPassword(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const { password } = req.body;
      const result = await AdminService.resetStaffPassword(user, id, password);
      res.status(200).json({ success: true, message: 'Staff password reset successfully', data: result });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * DELETE /api/v1/admin/staff/:id
   */
  static async deleteStaff(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      await AdminService.deleteStaff(user, id);
      res.status(200).json({ success: true, message: 'Staff member deactivated successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * GET /api/v1/admin/homework
   */
  static async getAdminHomework(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const classId = (req.query.class_id || req.query.classId) as string | undefined;
      const sectionId = (req.query.section_id || req.query.sectionId) as string | undefined;
      const subjectId = (req.query.subject_id || req.query.subjectId) as string | undefined;
      const search = req.query.search as string | undefined;

      const homework = await AdminService.getAdminHomework(user, { classId, sectionId, subjectId, search });
      res.status(200).json({ success: true, data: homework });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * POST /api/v1/admin/homework
   */
  static async createAdminHomework(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const created = await AdminService.createAdminHomework(user, req.body);
      res.status(201).json({ success: true, data: created, message: 'Homework assigned successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * PATCH /api/v1/admin/homework/:id
   */
  static async updateAdminHomework(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const updated = await AdminService.updateAdminHomework(user, id, req.body);
      res.status(200).json({ success: true, data: updated, message: 'Homework updated successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * DELETE /api/v1/admin/homework/:id
   */
  static async deleteAdminHomework(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      await AdminService.deleteAdminHomework(user, id);
      res.status(200).json({ success: true, message: 'Homework deleted successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * GET /api/v1/admin/feedback
   */
  static async getAdminFeedback(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const data = await AdminService.getAdminFeedback(user);
      res.status(200).json({ success: true, data });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * PATCH /api/v1/admin/complaints/:id
   */
  static async updateComplaintStatus(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const updated = await AdminService.updateComplaintStatus(user, id, req.body);
      res.status(200).json({ success: true, message: 'Grievance updated successfully', data: updated });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  // 17. Bulk Upload Students
  static async bulkUploadStudents(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { students } = req.body;
      const result = await AdminService.bulkUploadStudents(user, students);
      res.status(200).json({ success: true, message: 'Students successfully processed and allocated', data: result });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  // 18. Bulk Upload Staff
  static async bulkUploadStaff(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { staff } = req.body;
      const result = await AdminService.bulkUploadStaff(user, staff);
      res.status(200).json({ success: true, message: 'Staff roster successfully processed', data: result });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  // 19. Get Academic Allocations
  static async getAcademicAllocations(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const data = await AdminService.getAcademicAllocations(user);
      res.status(200).json({ success: true, data });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  // 20. Save Academic Allocations
  static async saveAcademicAllocations(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const result = await AdminService.saveAcademicAllocations(user, req.body);
      res.status(200).json({ success: true, message: 'Academic allocations successfully updated', data: result });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  // 21. Student 360-Degree Inspector
  static async getStudentInspection(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const data = await AdminService.getStudentInspection(user, id);
      res.status(200).json({ success: true, data });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  // 22. Teacher 360-Degree Inspector
  static async getTeacherInspection(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const data = await AdminService.getTeacherInspection(user, id);
      res.status(200).json({ success: true, data });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  // 23. Tenant Configuration (Dynamic Branding & Feature Switches)
  static async getTenantConfig(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const schoolId = user.schoolId;
      const { rows } = await pool.query(
        'SELECT id, name, code, contact_email, contact_phone, address, menu_config, branding_config FROM schools WHERE id = $1',
        [schoolId]
      );
      if (rows.length === 0) {
        res.status(404).json({ success: false, error: 'School not found' });
        return;
      }
      const s = rows[0];
      res.status(200).json({
        success: true,
        data: {
          id: s.id,
          name: s.name,
          code: s.code,
          contactEmail: s.contact_email,
          contactPhone: s.contact_phone,
          address: s.address,
          branding: {
            name: s.name,
            code: s.code,
            platformBrand: 'SAMAGRA',
            affiliation: s.branding_config?.affiliation || 'Affiliated to CBSE, New Delhi',
            logoUrl: s.branding_config?.logoUrl || '/logo-icon.png',
            tagline: 'The Complete School Platform',
            address: s.address || '',
            phone: s.contact_phone || '',
            ...s.branding_config,
          },
          features: s.menu_config?.features || {
            fees: true,
            transport: true,
            extra_fees: true,
            annual_matrix: true,
            cheque_management: true,
            sibling_discount: true,
            defaulters: true,
          },
          menuConfig: s.menu_config || {},
        },
      });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  static async updateTenantConfig(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const schoolId = user.schoolId;
      const { name, contactEmail, contactPhone, address, branding, features } = req.body;

      const current = await pool.query('SELECT menu_config, branding_config FROM schools WHERE id = $1', [schoolId]);
      if (current.rows.length === 0) {
        res.status(404).json({ success: false, error: 'School not found' });
        return;
      }

      const mergedBranding = {
        ...current.rows[0].branding_config,
        ...(branding || {}),
      };

      const mergedMenu = {
        ...current.rows[0].menu_config,
        features: {
          ...(current.rows[0].menu_config?.features || {}),
          ...(features || {}),
        },
      };

      await pool.query(
        `UPDATE schools 
         SET name = COALESCE($1, name),
             contact_email = COALESCE($2, contact_email),
             contact_phone = COALESCE($3, contact_phone),
             address = COALESCE($4, address),
             branding_config = $5,
             menu_config = $6,
             updated_at = NOW()
         WHERE id = $7`,
        [name, contactEmail, contactPhone, address, JSON.stringify(mergedBranding), JSON.stringify(mergedMenu), schoolId]
      );

      res.status(200).json({ success: true, message: 'Tenant configuration updated successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * POST /api/v1/admin/upload/photo
   * Uploads a photo file directly to Cloudinary Media Library.
   * Returns Cloudinary secure_url, publicId, and asset metadata.
   */
  static async uploadPhoto(req: Request, res: Response): Promise<void> {
    photoUploadMiddleware(req, res, async (err: any) => {
      if (err) {
        console.error('[Upload Photo Middleware Error]:', err.message);
        res.status(400).json({ success: false, error: err.message || 'File upload error' });
        return;
      }
      const file = (req as any).file as Express.Multer.File | undefined;
      const user = (req as any).user;
      if (!file) {
        console.warn(`[Upload Photo Error]: No photo file provided in request from user ${user?.userId || 'unknown'}`);
        res.status(400).json({ success: false, error: 'No photo file provided' });
        return;
      }

      console.info(`[Upload Photo API] Request received - User: ${user?.userId || 'system'}, Role: ${user?.roles?.join(',') || 'unknown'}, File: ${file.originalname}, MIME: ${file.mimetype}, Size: ${(file.size / 1024).toFixed(2)} KB`);

      try {
        const uploadResult = await CloudinaryService.uploadPhoto(file.buffer, {
          fileName: file.originalname,
          mimeType: file.mimetype,
          userId: user?.userId,
          role: user?.roles?.join(','),
          subfolder: 'photos',
        });

        console.info(`[Upload Photo API] Cloudinary upload successful - Public ID: ${uploadResult.publicId}, Secure URL: ${uploadResult.secureUrl}`);

        res.status(200).json({
          success: true,
          message: 'Photo uploaded successfully to Cloudinary',
          data: {
            photoUrl: uploadResult.secureUrl,
            publicId: uploadResult.publicId,
            format: uploadResult.format,
            bytes: uploadResult.bytes,
          },
        });
      } catch (error: any) {
        console.error('[Upload Photo API Error]: Cloudinary upload failed:', error.message);
        res.status(error.statusCode || 502).json({
          success: false,
          error: error.message || 'Failed to upload photo to Cloudinary',
        });
      }
    });
  }

  /**
   * PATCH /api/v1/admin/students/:id/photo
   */
  static async updateStudentPhoto(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const { photo_url } = req.body;

      if (!photo_url || typeof photo_url !== 'string') {
        res.status(400).json({ success: false, error: 'Valid photo_url is required' });
        return;
      }

      console.info(`[Update Student Photo] Admin: ${user?.userId}, Target Student ID: ${id}, New Photo: ${photo_url}`);

      const result = await AdminService.updateStudentPhoto(user, id, photo_url);
      console.info(`[Update Student Photo Success] Student ID: ${id} updated in database.`);

      // Clean up previous Cloudinary photo asynchronously if present
      if (result && result.oldPhotoUrl && result.oldPhotoUrl !== photo_url && result.oldPhotoUrl.includes('cloudinary')) {
        CloudinaryService.deletePhoto(result.oldPhotoUrl).catch((delErr) => {
          console.warn('[Old Student Photo Cleanup Warning]:', delErr?.message);
        });
      }

      res.status(200).json({
        success: true,
        data: result.updated || result,
        message: 'Student photo updated successfully in database',
      });
    } catch (error: any) {
      console.error(`[Update Student Photo Failed] Student ID: ${req.params.id}:`, error.message);
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * DELETE /api/v1/admin/students/:id/photo
   */
  static async deleteStudentPhoto(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      console.info(`[Delete Student Photo] Admin: ${user?.userId}, Target Student ID: ${id}`);

      const result = await AdminService.deleteStudentPhoto(user, id);
      console.info(`[Delete Student Photo Success] Student ID: ${id} photo removed from database.`);

      if (result && result.oldPhotoUrl && result.oldPhotoUrl.includes('cloudinary')) {
        CloudinaryService.deletePhoto(result.oldPhotoUrl).catch((delErr) => {
          console.warn('[Student Photo Cloudinary Delete Warning]:', delErr?.message);
        });
      }

      res.status(200).json({
        success: true,
        data: result.deleted || result,
        message: 'Student photo removed successfully',
      });
    } catch (error: any) {
      console.error(`[Delete Student Photo Failed] Student ID: ${req.params.id}:`, error.message);
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * PATCH /api/v1/admin/staff/:id/photo
   */
  static async updateStaffPhoto(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const { photo_url } = req.body;

      if (!photo_url || typeof photo_url !== 'string') {
        res.status(400).json({ success: false, error: 'Valid photo_url is required' });
        return;
      }

      console.info(`[Update Staff Photo] Admin: ${user?.userId}, Target Staff ID: ${id}, New Photo: ${photo_url}`);

      const result = await AdminService.updateStaffPhoto(user, id, photo_url);
      console.info(`[Update Staff Photo Success] Staff ID: ${id} updated in database.`);

      if (result && result.oldPhotoUrl && result.oldPhotoUrl !== photo_url && result.oldPhotoUrl.includes('cloudinary')) {
        CloudinaryService.deletePhoto(result.oldPhotoUrl).catch((delErr) => {
          console.warn('[Old Staff Photo Cleanup Warning]:', delErr?.message);
        });
      }

      res.status(200).json({
        success: true,
        data: result.updated || result,
        message: 'Staff photo updated successfully in database',
      });
    } catch (error: any) {
      console.error(`[Update Staff Photo Failed] Staff ID: ${req.params.id}:`, error.message);
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  /**
   * DELETE /api/v1/admin/staff/:id/photo
   */
  static async deleteStaffPhoto(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      console.info(`[Delete Staff Photo] Admin: ${user?.userId}, Target Staff ID: ${id}`);

      const result = await AdminService.deleteStaffPhoto(user, id);
      console.info(`[Delete Staff Photo Success] Staff ID: ${id} photo removed from database.`);

      if (result && result.oldPhotoUrl && result.oldPhotoUrl.includes('cloudinary')) {
        CloudinaryService.deletePhoto(result.oldPhotoUrl).catch((delErr) => {
          console.warn('[Staff Photo Cloudinary Delete Warning]:', delErr?.message);
        });
      }

      res.status(200).json({
        success: true,
        data: result.deleted || result,
        message: 'Staff photo removed successfully',
      });
    } catch (error: any) {
      console.error(`[Delete Staff Photo Failed] Staff ID: ${req.params.id}:`, error.message);
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }
}


