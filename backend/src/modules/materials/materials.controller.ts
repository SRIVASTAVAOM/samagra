import { Request, Response } from 'express';
import { z } from 'zod';
import { pool } from '../../config/db.config';
import { MaterialsService } from './materials.service';
import { CloudinaryService } from '../../services/cloudinary.service';

const UUID_REGEX = /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/;

const initiateUploadSchema = z.object({
  classId: z.string().uuid().optional(),
  class_id: z.string().uuid().optional(),
  sectionId: z.string().uuid().optional(),
  section_id: z.string().uuid().optional(),
  subjectId: z.string().uuid().optional(),
  subject_id: z.string().uuid().optional(),
  title: z.string().min(1, 'Title is required'),
  description: z.string().optional(),
  fileName: z.string().min(1, 'File name is required').optional(),
  file_name: z.string().min(1, 'File name is required').optional(),
  fileSizeBytes: z.number().int().positive('File size must be positive').optional(),
  file_size_bytes: z.number().int().positive('File size must be positive').optional(),
  contentType: z.string().min(1, 'Content-type is required').optional(),
  fileType: z.string().min(1, 'Content-type is required').optional(),
  content_type: z.string().min(1, 'Content-type is required').optional(),
}).transform((data) => ({
  classId: (data.classId || data.class_id)!,
  sectionId: data.sectionId || data.section_id,
  subjectId: (data.subjectId || data.subject_id)!,
  title: data.title,
  description: data.description,
  fileName: (data.fileName || data.file_name)!,
  fileSizeBytes: (data.fileSizeBytes || data.file_size_bytes)!,
  contentType: (data.contentType || data.fileType || data.content_type)!,
})).refine((d) => !!d.classId && !!d.subjectId && !!d.fileName && !!d.fileSizeBytes && !!d.contentType, {
  message: 'classId, subjectId, fileName, fileSizeBytes, and contentType are required',
});

export class MaterialsController {
  static async initiatePresignedUpload(req: Request, res: Response): Promise<void> {
    try {
      const parsed = initiateUploadSchema.parse(req.body);
      const host = req.get('host');
      const requestBaseUrl = host ? `${req.protocol}://${host}` : undefined;
      const result = await MaterialsService.initiatePresignedUpload((req as any).user, parsed, requestBaseUrl);
      res.status(201).json({ success: true, data: result });
    } catch (error: any) {
      if (error instanceof z.ZodError) {
        res.status(400).json({ success: false, error: 'Validation failed', details: error.errors });
        return;
      }
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to initiate upload',
      });
    }
  }

  static async verifyUpload(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      if (!UUID_REGEX.test(id)) {
        res.status(400).json({ success: false, error: 'Invalid material ID format' });
        return;
      }
      const material = await MaterialsService.verifyUpload((req as any).user, id);
      res.status(200).json({ success: true, data: material });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to verify upload',
      });
    }
  }

  static async getMaterials(req: Request, res: Response): Promise<void> {
    try {
      const { classId, subjectId } = req.params;
      const { sectionId } = req.query;
      if (!UUID_REGEX.test(classId) || !UUID_REGEX.test(subjectId) || (sectionId && !UUID_REGEX.test(String(sectionId)))) {
        res.status(400).json({ success: false, error: 'Invalid class, subject, or section identifier' });
        return;
      }
      const list = await MaterialsService.getMaterials(
        (req as any).user,
        classId,
        subjectId,
        sectionId as string | undefined
      );
      res.status(200).json({ success: true, data: list });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to fetch materials',
      });
    }
  }

  static async getDownloadUrl(req: Request, res: Response): Promise<void> {
    try {
      const { id } = req.params;
      if (!UUID_REGEX.test(id)) {
        res.status(400).json({ success: false, error: 'Invalid material ID format' });
        return;
      }
      const result = await MaterialsService.getDownloadUrl((req as any).user, id);
      res.status(200).json({ success: true, data: result });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to generate download URL',
      });
    }
  }

  static async getAdminMaterials(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const classId = (req.query.class_id || req.query.classId) as string | undefined;
      const sectionId = (req.query.section_id || req.query.sectionId) as string | undefined;
      const subjectId = (req.query.subject_id || req.query.subjectId) as string | undefined;
      const type = (req.query.type || req.query.category) as string | undefined;
      const search = req.query.search as string | undefined;

      const list = await MaterialsService.getAdminMaterials(user, { classId, sectionId, subjectId, type, search });
      res.status(200).json({ success: true, data: list });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to fetch study materials',
      });
    }
  }

  static async createAdminMaterial(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const material = await MaterialsService.createAdminMaterial(user, req.body);
      res.status(201).json({ success: true, data: material, message: 'Study material published successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to publish study material',
      });
    }
  }

  static async updateAdminMaterial(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      const updated = await MaterialsService.updateAdminMaterial(user, id, req.body);
      res.status(200).json({ success: true, data: updated, message: 'Study material updated successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to update study material',
      });
    }
  }

  static async deleteAdminMaterial(req: Request, res: Response): Promise<void> {
    try {
      const user = (req as any).user;
      const { id } = req.params;
      await MaterialsService.deleteAdminMaterial(user, id);
      res.status(200).json({ success: true, message: 'Study material deleted successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to delete study material',
      });
    }
  }

  /**
   * Direct binary upload for study materials (PDF, JPEG, PNG, WebP) up to 10MB.
   */
  static async uploadMaterialFile(req: Request, res: Response): Promise<void> {
    const MAX_FILE_SIZE = 10 * 1024 * 1024; // 10 MB
    const ALLOWED_EXTS = ['.pdf', '.jpg', '.jpeg', '.png', '.webp', '.docx', '.xlsx'];

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
            const err: any = new Error('File size exceeds maximum allowed limit of 10 MB');
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
        res.status(400).json({ success: false, error: 'File size exceeds maximum allowed limit of 10 MB' });
        return;
      }

      const rawName =
        (req.query.fileName as string) ||
        (req.query.filename as string) ||
        (req.headers['x-file-name'] as string) ||
        `material_${Date.now()}.pdf`;

      const safeBaseName = rawName.replace(/[^a-zA-Z0-9._-]/g, '_');
      const ext = (safeBaseName.includes('.') ? safeBaseName.slice(safeBaseName.lastIndexOf('.')) : '').toLowerCase();

      if (!ALLOWED_EXTS.includes(ext)) {
        res.status(400).json({
          success: false,
          error: `Invalid file format (${ext || 'unknown'}). Allowed: PDF, JPG, PNG, WebP, DOCX, XLSX.`,
        });
        return;
      }

      // Magic byte validation for primary formats
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
      const isZipDoc =
        buffer.length >= 4 &&
        buffer[0] === 0x50 &&
        buffer[1] === 0x4b &&
        buffer[2] === 0x03 &&
        buffer[3] === 0x04;

      if (!isPdf && !isJpg && !isPng && !isWebp && !isZipDoc) {
        res.status(400).json({
          success: false,
          error: 'File content does not match allowed format signature (PDF, JPEG, PNG, WebP, Office XML).',
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
          : ext === '.xlsx'
          ? 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          : ext === '.docx'
          ? 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
          : 'image/jpeg';

      const uniqueKey = `materials_${Date.now()}_${safeBaseName}`;
      const uploadResult = await CloudinaryService.uploadBuffer(buffer, uniqueKey, contentType);

      res.status(200).json({
        success: true,
        message: 'Material file uploaded successfully',
        data: {
          fileKey: uploadResult.url || uploadResult.publicId,
          fileUrl: uploadResult.url,
          fileName: safeBaseName,
          sizeBytes: buffer.length,
          contentType,
        },
      });
    } catch (error: any) {
      console.error('[Materials File Upload Error]:', error);
      res.status(error.statusCode || 500).json({
        success: false,
        error: error.message || 'Failed to upload study material file',
      });
    }
  }

  /**
   * Upload handler for pre-signed upload URLs.
   */
  static async storageUploadHandler(req: Request, res: Response): Promise<void> {
    try {
      const fileKey = (req.query.key as string) || `upload_${Date.now()}`;
      if (!CloudinaryService.isConfigured()) {
        res.status(503).json({
          success: false,
          error: 'Cloudinary storage credentials are not configured on the server.',
        });
        return;
      }

      let buffer: Buffer;
      if (Buffer.isBuffer(req.body)) {
        buffer = req.body;
      } else {
        const chunks: Buffer[] = [];
        await new Promise<void>((resolve, reject) => {
          req.on('data', (chunk) => chunks.push(chunk));
          req.on('end', () => resolve());
          req.on('error', (err) => reject(err));
        });
        buffer = Buffer.concat(chunks);
      }

      if (!buffer || buffer.length === 0) {
        res.status(400).json({ success: false, error: 'Empty file payload received' });
        return;
      }

      const uploadResult = await CloudinaryService.uploadBuffer(
        buffer,
        fileKey,
        req.headers['content-type'] as string
      );
      if (uploadResult.url) {
        await pool.query(
          `UPDATE academic_materials SET s3_file_key = $1, updated_at = CURRENT_TIMESTAMP WHERE s3_file_key = $2;`,
          [uploadResult.url, fileKey]
        );
      }
      res.status(200).json({
        success: true,
        message: 'File uploaded to Cloudinary successfully',
        data: uploadResult,
      });
    } catch (err: any) {
      console.error('[Storage Upload Handler Error]:', err);
      res.status(500).json({ success: false, error: err.message || 'Storage upload failed' });
    }
  }
}
