import { Response, NextFunction } from 'express';
import { z } from 'zod';
import multer from 'multer';
import path from 'path';
import { AuthenticatedRequest } from '../../types/auth.types';
import { ProfileService } from './profile.service';

const MAX_PHOTO_SIZE = 5 * 1024 * 1024;
const ALLOWED_IMAGE_EXTS = ['.jpg', '.jpeg', '.png', '.webp'];

const studentPhotoMulter = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: MAX_PHOTO_SIZE },
  fileFilter: (_req, file, cb) => {
    const allowedMimes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (allowedMimes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('Only JPEG, PNG, and WebP images are allowed.'));
    }
  },
}).single('photo');

const studentUpdateSchema = z
  .object({
    emergency_phone: z.string().min(5).max(20).nullable().optional(),
    emergencyPhone: z.string().min(5).max(20).nullable().optional(),
    blood_group: z.string().max(10).nullable().optional(),
    bloodGroup: z.string().max(10).nullable().optional(),
    medical_notes: z.string().max(500).nullable().optional(),
    medicalNotes: z.string().max(500).nullable().optional(),
    document_url: z.string().nullable().optional(),
    documentUrl: z.string().nullable().optional(),
    photo_url: z.string().min(1).max(2048).nullable().optional(),
    photoUrl: z.string().min(1).max(2048).nullable().optional(),
    avatar_url: z.string().min(1).max(2048).nullable().optional(),
    avatarUrl: z.string().min(1).max(2048).nullable().optional(),
  })
  .transform((data) => ({
    emergency_phone: data.emergency_phone !== undefined ? data.emergency_phone : data.emergencyPhone,
    blood_group: data.blood_group !== undefined ? data.blood_group : data.bloodGroup,
    medical_notes: data.medical_notes !== undefined ? data.medical_notes : data.medicalNotes,
    document_url: data.document_url !== undefined ? data.document_url : data.documentUrl,
    photo_url:
      data.photo_url !== undefined
        ? data.photo_url
        : data.photoUrl !== undefined
        ? data.photoUrl
        : data.avatar_url !== undefined
        ? data.avatar_url
        : data.avatarUrl,
  }));

const staffUpdateSchema = z
  .object({
    emergency_phone: z.string().min(5).max(20).nullable().optional(),
    emergencyPhone: z.string().min(5).max(20).nullable().optional(),
    phone: z.string().min(5).max(20).nullable().optional(),
    qualification: z.string().min(2).max(255).nullable().optional(),
    blood_group: z.string().max(10).nullable().optional(),
    bloodGroup: z.string().max(10).nullable().optional(),
  })
  .transform((data) => ({
    emergency_phone: data.emergency_phone !== undefined ? data.emergency_phone : data.emergencyPhone,
    phone: data.phone,
    qualification: data.qualification,
    blood_group: data.blood_group !== undefined ? data.blood_group : data.bloodGroup,
  }));

const emptyToNullString = (max: number, min?: number) => {
  let schema = z.string().max(max);
  if (min !== undefined) {
    schema = schema.min(min);
  }
  return z.preprocess(
    (val) => {
      if (val === undefined) return undefined;
      if (val === null) return null;
      if (typeof val === 'string') {
        const trimmed = val.trim();
        return trimmed === '' ? null : trimmed;
      }
      return val;
    },
    schema.nullable().optional()
  );
};

const teacherUpdateStudentSchema = z
  .object({
    roll_number: emptyToNullString(20),
    rollNumber: emptyToNullString(20),
    blood_group: emptyToNullString(10),
    bloodGroup: emptyToNullString(10),
    emergency_contact_phone: emptyToNullString(20, 5),
    emergency_phone: emptyToNullString(20, 5),
    emergencyPhone: emptyToNullString(20, 5),
    medical_notes: emptyToNullString(500),
    medicalNotes: emptyToNullString(500),
    document_url: z.string().nullable().optional(),
    documentUrl: z.string().nullable().optional(),
  })
  .transform((data) => ({
    roll_number: data.roll_number !== undefined ? data.roll_number : data.rollNumber,
    blood_group: data.blood_group !== undefined ? data.blood_group : data.bloodGroup,
    emergency_phone:
      data.emergency_contact_phone !== undefined
        ? data.emergency_contact_phone
        : data.emergency_phone !== undefined
        ? data.emergency_phone
        : data.emergencyPhone,
    medical_notes: data.medical_notes !== undefined ? data.medical_notes : data.medicalNotes,
    document_url: data.document_url !== undefined ? data.document_url : data.documentUrl,
  }));

function readRawRequestBuffer(req: AuthenticatedRequest): Promise<Buffer> {
  if (Buffer.isBuffer(req.body)) {
    return Promise.resolve(req.body);
  }
  return new Promise<Buffer>((resolve, reject) => {
    const chunks: Buffer[] = [];
    let total = 0;
    let limitExceeded = false;

    req.on('data', (chunk: Buffer) => {
      if (limitExceeded) return;
      total += chunk.length;
      if (total > MAX_PHOTO_SIZE) {
        limitExceeded = true;
        return;
      }
      chunks.push(chunk);
    });

    req.on('end', () => {
      if (limitExceeded) {
        const err: any = new Error('Photo size exceeds maximum allowed limit of 5 MB');
        err.statusCode = 400;
        return reject(err);
      }
      resolve(Buffer.concat(chunks));
    });

    req.on('error', (err) => reject(err));
  });
}

function validateImageSignature(buffer: Buffer, ext: string): string | null {
  const isJpg = buffer.length >= 3 && buffer[0] === 0xff && buffer[1] === 0xd8 && buffer[2] === 0xff;
  const isPng =
    buffer.length >= 8 &&
    buffer[0] === 0x89 &&
    buffer[1] === 0x50 &&
    buffer[2] === 0x4e &&
    buffer[3] === 0x47;
  const isWebp =
    buffer.length >= 12 &&
    buffer.slice(0, 4).toString('ascii') === 'RIFF' &&
    buffer.slice(8, 12).toString('ascii') === 'WEBP';

  if (isJpg && (ext === '.jpg' || ext === '.jpeg' || !ext)) return 'image/jpeg';
  if (isPng && (ext === '.png' || !ext)) return 'image/png';
  if (isWebp && (ext === '.webp' || !ext)) return 'image/webp';
  if (isJpg) return 'image/jpeg';
  if (isPng) return 'image/png';
  if (isWebp) return 'image/webp';
  return null;
}

export class ProfileController {
  static async getStudentProfile(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const profile = await ProfileService.getStudentProfile(req.user!);
      res.status(200).json({ success: true, data: profile });
    } catch (error: any) {
      if (error.message === 'PROFILE_NOT_FOUND') {
        res.status(404).json({ success: false, error: 'Student profile not found' });
        return;
      }
      next(error);
    }
  }

  static async updateStudentProfile(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const validation = studentUpdateSchema.safeParse(req.body);
      if (!validation.success) {
        res.status(400).json({
          success: false,
          error: 'Validation Error',
          details: validation.error.errors.map((e) => e.message),
        });
        return;
      }

      const updated = await ProfileService.updateStudentProfile(req.user!, validation.data);
      res.status(200).json({
        success: true,
        message: 'Profile updated successfully',
        data: updated,
      });
    } catch (error: any) {
      if (error.message === 'PROFILE_NOT_FOUND') {
        res.status(404).json({ success: false, error: 'Student profile not found' });
        return;
      }
      if (error.message === 'PHOTO_CHANGE_LIMIT_REACHED') {
        res.status(403).json({
          success: false,
          error:
            'One-time profile photo upload has already been used. Ask your School Admin to allow photo re-upload.',
        });
        return;
      }
      next(error);
    }
  }

  static async uploadStudentPhoto(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    const contentType = req.headers['content-type'] || '';

    const handleUpload = async (buffer: Buffer, fileName: string, detectedMime?: string) => {
      if (!buffer || buffer.length === 0) {
        res.status(400).json({ success: false, error: 'No photo data received' });
        return;
      }
      if (buffer.length > MAX_PHOTO_SIZE) {
        res.status(400).json({ success: false, error: 'Photo size exceeds maximum allowed limit of 5 MB' });
        return;
      }

      const safeName = path.basename(fileName || `student_photo_${Date.now()}.jpg`).replace(/[^a-zA-Z0-9._-]/g, '_');
      const ext = path.extname(safeName).toLowerCase();
      if (ext && !ALLOWED_IMAGE_EXTS.includes(ext)) {
        res.status(400).json({
          success: false,
          error: 'Invalid photo format. Only JPEG, PNG, and WebP images are allowed.',
        });
        return;
      }

      const validMime = validateImageSignature(buffer, ext) || (detectedMime?.startsWith('image/') ? detectedMime : null);
      if (!validMime) {
        res.status(400).json({
          success: false,
          error: 'File content does not match a supported image format (JPEG, PNG, WebP).',
        });
        return;
      }

      const updated = await ProfileService.uploadStudentPhoto(req.user!, {
        buffer,
        fileName: safeName,
        mimeType: validMime,
      });

      res.status(200).json({
        success: true,
        message: 'Profile photo uploaded successfully',
        data: updated,
      });
    };

    if (contentType.includes('multipart/form-data')) {
      studentPhotoMulter(req as any, res as any, async (err: any) => {
        if (err) {
          res.status(400).json({ success: false, error: err.message || 'Photo upload error' });
          return;
        }
        const file = (req as any).file as Express.Multer.File | undefined;
        if (!file) {
          res.status(400).json({ success: false, error: 'No photo file provided' });
          return;
        }
        try {
          await handleUpload(file.buffer, file.originalname, file.mimetype);
        } catch (error: any) {
          if (error.message === 'PROFILE_NOT_FOUND') {
            res.status(404).json({ success: false, error: 'Student profile not found' });
            return;
          }
          if (error.message === 'PHOTO_CHANGE_LIMIT_REACHED') {
            res.status(403).json({
              success: false,
              error:
                'One-time profile photo upload has already been used. Ask your School Admin to allow photo re-upload.',
            });
            return;
          }
          next(error);
        }
      });
      return;
    }

    try {
      const buffer = await readRawRequestBuffer(req);
      const rawName =
        (req.query.fileName as string) ||
        (req.query.filename as string) ||
        (req.headers['x-file-name'] as string) ||
        `student_photo_${Date.now()}.jpg`;
      await handleUpload(buffer, rawName, contentType);
    } catch (error: any) {
      if (error.statusCode === 400) {
        res.status(400).json({ success: false, error: error.message });
        return;
      }
      if (error.message === 'PROFILE_NOT_FOUND') {
        res.status(404).json({ success: false, error: 'Student profile not found' });
        return;
      }
      if (error.message === 'PHOTO_CHANGE_LIMIT_REACHED') {
        res.status(403).json({
          success: false,
          error:
            'One-time profile photo upload has already been used. Ask your School Admin to allow photo re-upload.',
        });
        return;
      }
      next(error);
    }
  }

  static async getStaffProfile(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const profile = await ProfileService.getStaffProfile(req.user!);
      res.status(200).json({ success: true, data: profile });
    } catch (error: any) {
      if (error.message === 'PROFILE_NOT_FOUND') {
        res.status(404).json({ success: false, error: 'Staff profile not found' });
        return;
      }
      next(error);
    }
  }

  static async updateStaffProfile(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const validation = staffUpdateSchema.safeParse(req.body);
      if (!validation.success) {
        res.status(400).json({
          success: false,
          error: 'Validation Error',
          details: validation.error.errors.map((e) => e.message),
        });
        return;
      }

      const updated = await ProfileService.updateStaffProfile(req.user!, validation.data);
      res.status(200).json({
        success: true,
        message: 'Staff profile updated successfully',
        data: updated,
      });
    } catch (error: any) {
      if (error.message === 'PROFILE_NOT_FOUND') {
        res.status(404).json({ success: false, error: 'Staff profile not found' });
        return;
      }
      next(error);
    }
  }

  static async updateStudentProfileByTeacher(
    req: AuthenticatedRequest,
    res: Response,
    next: NextFunction
  ): Promise<void> {
    try {
      const { studentId } = req.params;
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(studentId)) {
        res.status(400).json({
          success: false,
          error: 'Invalid studentId format.',
        });
        return;
      }
      const validation = teacherUpdateStudentSchema.safeParse(req.body);
      if (!validation.success) {
        res.status(400).json({
          success: false,
          error: 'Validation Error',
          details: validation.error.errors.map((e) => e.message),
        });
        return;
      }

      const updated = await ProfileService.updateStudentProfileByTeacher(
        req.user!,
        studentId,
        validation.data
      );

      res.status(200).json({
        success: true,
        message: 'Student details updated successfully',
        data: updated,
      });
    } catch (error: any) {
      if (error.message === 'PROFILE_NOT_FOUND') {
        res.status(404).json({ success: false, error: 'Teacher profile not found' });
        return;
      }
      if (error.message === 'STUDENT_NOT_FOUND') {
        res.status(404).json({ success: false, error: 'Student not found' });
        return;
      }
      if (error.message === 'STUDENT_NOT_ENROLLED') {
        res.status(400).json({ success: false, error: 'Student is not assigned to a class and section' });
        return;
      }
      if (
        error.message === 'FORBIDDEN_SCHOOL' ||
        error.message === 'FORBIDDEN_NOT_CLASS_TEACHER'
      ) {
        res.status(403).json({
          success: false,
          error:
            'Forbidden: Only the assigned Class Teacher can update this student details',
        });
        return;
      }
      next(error);
    }
  }
}
