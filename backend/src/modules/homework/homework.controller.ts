import { Request, Response } from 'express';
import { z } from 'zod';
import path from 'path';
import { HomeworkService } from './homework.service';
import { CloudinaryService } from '../../services/cloudinary.service';

const createHomeworkSchema = z.object({
  classId: z.string().uuid().optional(),
  class_id: z.string().uuid().optional(),
  sectionId: z.string().uuid().optional(),
  section_id: z.string().uuid().optional(),
  subjectId: z.string().uuid().optional(),
  subject_id: z.string().uuid().optional(),
  title: z.string().min(1, 'Title is required'),
  description: z.string().min(1, 'Description/instructions are required'),
  assignedDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  assigned_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional(),
  dueDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Valid dueDate (YYYY-MM-DD) is required').optional(),
  due_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Valid dueDate (YYYY-MM-DD) is required').optional(),
  s3AttachmentKey: z.string().nullable().optional(),
  s3_attachment_key: z.string().nullable().optional(),
  attachmentName: z.string().nullable().optional(),
  attachment_name: z.string().nullable().optional(),
}).transform((data) => ({
  classId: (data.classId || data.class_id)!,
  sectionId: (data.sectionId || data.section_id)!,
  subjectId: (data.subjectId || data.subject_id)!,
  title: data.title,
  description: data.description,
  assignedDate: data.assignedDate || data.assigned_date,
  dueDate: (data.dueDate || data.due_date)!,
  s3AttachmentKey: data.s3AttachmentKey !== undefined ? (data.s3AttachmentKey || undefined) : (data.s3_attachment_key || undefined),
  attachmentName: data.attachmentName !== undefined ? (data.attachmentName || undefined) : (data.attachment_name || undefined),
})).refine((d) => !!d.classId && !!d.sectionId && !!d.subjectId && !!d.dueDate, {
  message: 'classId, sectionId, subjectId, and dueDate are required',
});

const completionSchema = z.object({
  status: z.enum(['PENDING', 'COMPLETED']),
});

const updateHomeworkSchema = z.object({
  title: z.string().min(1, 'Title cannot be empty').optional(),
  description: z.string().min(1, 'Description cannot be empty').optional(),
  dueDate: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Valid dueDate (YYYY-MM-DD) is required').optional(),
  due_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Valid dueDate (YYYY-MM-DD) is required').optional(),
  s3AttachmentKey: z.string().nullable().optional(),
  s3_attachment_key: z.string().nullable().optional(),
  attachmentName: z.string().nullable().optional(),
  attachment_name: z.string().nullable().optional(),
}).transform((data) => ({
  title: data.title,
  description: data.description,
  dueDate: data.dueDate || data.due_date,
  s3AttachmentKey: data.s3AttachmentKey !== undefined ? data.s3AttachmentKey : data.s3_attachment_key,
  attachmentName: data.attachmentName !== undefined ? data.attachmentName : data.attachment_name,
}));

export class HomeworkController {
  static async updateHomework(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const parsed = updateHomeworkSchema.parse(req.body);
      const homework = await HomeworkService.updateHomework((req as any).user, id, parsed);
      res.status(200).json({ success: true, data: homework });
    } catch (error: any) {
      if (error instanceof z.ZodError) {
        res.status(400).json({ success: false, error: 'Validation failed', details: error.errors });
        return;
      }
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to update homework assignment',
      });
    }
  }
  static async createHomework(req: Request, res: Response): Promise<void> {
    try {
      const parsed = createHomeworkSchema.parse(req.body);
      const idempotencyKey = (req.headers['idempotency-key'] ||
        req.headers['x-idempotency-key'] ||
        req.body.idempotencyKey ||
        req.body.idempotency_key) as string | undefined;

      const homework = await HomeworkService.createHomework((req as any).user, {
        ...parsed,
        idempotencyKey,
      });
      res.status(201).json({ success: true, data: homework });
    } catch (error: any) {
      if (error instanceof z.ZodError) {
        res.status(400).json({ success: false, error: 'Validation failed', details: error.errors });
        return;
      }
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to create homework assignment',
      });
    }
  }

  static async getStudentMyClassHomework(req: Request, res: Response): Promise<void> {
    try {
      const list = await HomeworkService.getStudentMyClassHomework((req as any).user);
      res.status(200).json({ success: true, data: list });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to fetch student homework',
      });
    }
  }

  static async getTeacherMyAssignedHomework(req: Request, res: Response): Promise<void> {
    try {
      const list = await HomeworkService.getTeacherMyAssignedHomework((req as any).user);
      res.status(200).json({ success: true, data: list });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to fetch teacher assigned homework',
      });
    }
  }

  static async getClassSectionHomework(req: Request, res: Response): Promise<void> {
    try {
      const { classId, sectionId } = req.params;
      const list = await HomeworkService.getClassSectionHomework((req as any).user, classId, sectionId);
      res.status(200).json({ success: true, data: list });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to fetch class homework',
      });
    }
  }

  static async getHomeworkDetail(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const homework = await HomeworkService.getHomeworkDetail((req as any).user, id);
      res.status(200).json({ success: true, data: homework });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to fetch homework detail',
      });
    }
  }

  static async setCompletionStatus(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const parsed = completionSchema.parse(req.body);
      const result = await HomeworkService.setCompletionStatus((req as any).user, id, parsed.status);
      res.status(200).json({ success: true, data: result });
    } catch (error: any) {
      if (error instanceof z.ZodError) {
        res.status(400).json({ success: false, error: 'Validation failed', details: error.errors });
        return;
      }
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to update homework completion status',
      });
    }
  }

  static async getAttachmentDownloadUrl(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      const result = await HomeworkService.getAttachmentDownloadUrl((req as any).user, id);
      res.status(200).json({ success: true, data: result });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to generate attachment download URL',
      });
    }
  }

  /**
   * Upload homework attachment directly to Cloudinary with strict 5 MB limit.
   */
  static async uploadHomeworkAttachment(req: Request, res: Response): Promise<void> {
    const MAX_FILE_SIZE = 5 * 1024 * 1024; // 5 MB (5,242,880 bytes)
    const ALLOWED_EXTS = ['.jpg', '.jpeg', '.png', '.webp', '.pdf'];

    const getRawBuffer = (): Promise<Buffer> => {
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
          if (total > MAX_FILE_SIZE) {
            limitExceeded = true;
            return;
          }
          chunks.push(chunk);
        });

        req.on('end', () => {
          if (limitExceeded) {
            const err: any = new Error('File size exceeds maximum allowed limit of 5 MB');
            err.statusCode = 400;
            return reject(err);
          }
          resolve(Buffer.concat(chunks));
        });

        req.on('error', (err) => reject(err));
      });
    };

    try {
      const buffer = await getRawBuffer();

      if (!buffer || buffer.length === 0) {
        res.status(400).json({ success: false, error: 'No file data received or uploaded file is empty' });
        return;
      }

      if (buffer.length > MAX_FILE_SIZE) {
        res.status(400).json({ success: false, error: 'File size exceeds maximum allowed limit of 5 MB' });
        return;
      }

      // Determine file name and extension
      const rawName =
        (req.query.fileName as string) ||
        (req.query.filename as string) ||
        (req.headers['x-file-name'] as string) ||
        `attachment_${Date.now()}.pdf`;

      const safeBaseName = path.basename(rawName).replace(/[^a-zA-Z0-9._-]/g, '_');
      const ext = path.extname(safeBaseName).toLowerCase();

      if (!ALLOWED_EXTS.includes(ext)) {
        res.status(400).json({
          success: false,
          error: `Invalid file format (${ext || 'unknown'}). Only JPEG, PNG, WebP, and PDF documents are allowed.`,
        });
        return;
      }

      // Magic numbers validation
      const isPdf = buffer.length >= 4 && buffer.slice(0, 4).toString('ascii') === '%PDF';
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

      if (!isPdf && !isJpg && !isPng && !isWebp) {
        res.status(400).json({
          success: false,
          error: 'File content does not match allowed format signature (JPEG, PNG, WebP, or PDF).',
        });
        return;
      }

      const contentType =
        ext === '.pdf'
          ? 'application/pdf'
          : ext === '.png'
          ? 'image/png'
          : ext === '.webp'
          ? 'image/webp'
          : 'image/jpeg';

      const uniqueKey = `homework_${Date.now()}_${safeBaseName}`;
      const uploadResult = await CloudinaryService.uploadBuffer(buffer, uniqueKey, contentType);

      res.status(200).json({
        success: true,
        message: 'Homework attachment uploaded successfully',
        data: {
          fileKey: uploadResult.url || uploadResult.publicId,
          attachmentUrl: uploadResult.url,
          attachmentName: safeBaseName,
          sizeBytes: buffer.length,
          format: ext.replace('.', ''),
        },
      });
    } catch (error: any) {
      console.error('[Homework Attachment Upload Error]:', error);
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to upload homework attachment',
      });
    }
  }
}
