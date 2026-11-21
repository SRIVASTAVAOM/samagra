import { Request, Response } from 'express';
import { z } from 'zod';
import { MaterialsService } from './materials.service';
import { CloudinaryService } from '../../services/cloudinary.service';

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
      const result = await MaterialsService.initiatePresignedUpload((req as any).user, parsed);
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
      const attachmentUrl = req.body?.attachmentUrl;
      if (attachmentUrl !== undefined && !CloudinaryService.isAttachmentUrl(attachmentUrl)) {
        res.status(400).json({ error: 'Invalid attachment URL' });
        return;
      }
      const metadata = req.body?.metadata === undefined ? undefined : z.object({
        name: z.string().min(1).max(255), size: z.number().int().positive(),
        type: z.enum(['application/pdf', 'image/jpeg', 'image/jpg', 'image/png']),
      }).parse(req.body.metadata);
      const material = await MaterialsService.verifyUpload((req as any).user, id, attachmentUrl, metadata);
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
   * Universal upload handler:
   * If Cloudinary is configured, streams directly to Cloudinary.
   * If unconfigured, performs safe local simulation.
   */
  static async storageUploadHandler(req: Request, res: Response): Promise<void> {
    try {
      const fileKey = (req.query.key as string) || `upload_${Date.now()}`;
      if (CloudinaryService.isConfigured()) {
        const chunks: Buffer[] = [];
        req.on('data', (chunk) => chunks.push(chunk));
        req.on('end', async () => {
          try {
            const buffer = Buffer.concat(chunks);
            const uploadResult = await CloudinaryService.uploadBuffer(buffer, fileKey, req.headers['content-type'] as string);
            res.status(200).json({ success: true, message: 'File uploaded to Cloudinary successfully', data: uploadResult });
          } catch (uploadErr: any) {
            console.error('[Cloudinary Upload Error]:', uploadErr);
            res.status(500).json({ success: false, error: uploadErr.message || 'Cloudinary upload failed' });
          }
        });
      } else {
        console.info(`[Storage Notice]: Mock upload executed successfully for key: ${fileKey}`);
        res.status(200).json({ success: true, message: 'Mock storage upload simulated successfully' });
      }
    } catch (err: any) {
      res.status(500).json({ success: false, error: err.message });
    }
  }

  /**
   * Safe local simulation handler for uploads when Cloudinary credentials are not configured.
   */
  static mockUploadHandler(req: Request, res: Response): void {
    console.info(`[Storage Notice]: Upload simulated successfully for key: ${req.query.key}`);
    res.status(200).json({ success: true, message: 'Storage upload simulated successfully' });
  }

  /**
   * Safe local simulation handler for GET downloads when Cloudinary credentials are not configured.
   */
  static mockDownloadHandler(req: Request, res: Response): void {
    console.info(`[Storage Notice]: Download accessed for key: ${req.query.key}`);
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename="simulated_document.pdf"');
    res.status(200).send(Buffer.from('%PDF-1.4 Simulated ERP Academic Document Content'));
  }
}
