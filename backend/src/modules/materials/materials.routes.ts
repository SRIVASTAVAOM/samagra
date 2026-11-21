import { raw, Router } from 'express';
import { authenticateToken } from '../../middlewares/auth.middleware';
import { requireRole } from '../../middlewares/rbac.middleware';
import { MaterialsController } from './materials.controller';

import { randomUUID } from 'crypto';
import { CloudinaryService } from '../../services/cloudinary.service';
import { env } from '../../config/env.config';

const router = Router();

// Cloudinary / Local storage simulation endpoints (no token required for pre-signed direct upload/download)
router.all('/storage-upload', MaterialsController.storageUploadHandler);
router.all('/mock-upload', MaterialsController.mockUploadHandler);
router.all('/mock-download', MaterialsController.mockDownloadHandler);
router.put('/mock-s3-upload', MaterialsController.mockUploadHandler);
router.get('/mock-s3-download', MaterialsController.mockDownloadHandler);

// Authenticated API Endpoints
router.use(authenticateToken);

router.post('/attachments', raw({ type: 'application/octet-stream', limit: Number(env.MAX_UPLOAD_SIZE_BYTES) }), async (req, res) => {
  const bytes = req.body;
  if (!Buffer.isBuffer(bytes) || !(
    bytes.subarray(0, 5).toString() === '%PDF-' ||
    bytes.subarray(0, 3).equals(Buffer.from([255, 216, 255])) ||
    bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))
  )) {
    res.status(415).json({ error: 'Select a PDF, JPEG or PNG file.' });
    return;
  }
  if (!CloudinaryService.isConfigured()) {
    res.status(503).json({ error: 'Attachment storage is unavailable.' });
    return;
  }
  try {
    const file = await CloudinaryService.uploadBuffer(bytes, randomUUID());
    res.status(201).json({ success: true, data: { url: file.url } });
  } catch {
    res.status(502).json({ error: 'Attachment upload failed. Please retry.' });
  }
});

// Teacher / Admin requests pre-signed upload URL for academic material
router.post('/presigned-upload-url', requireRole(['TEACHER', 'ADMIN', 'SUPER_ADMIN']), MaterialsController.initiatePresignedUpload);

// Teacher / Admin verifies completed upload
router.post('/:id/verify-upload', requireRole(['TEACHER', 'ADMIN', 'SUPER_ADMIN']), MaterialsController.verifyUpload);

// List materials for class & subject (scoped for Students, Teachers, Coordinators)
router.get('/class/:classId/:subjectId', MaterialsController.getMaterials);

// Download URL for authorized users
router.get('/:id/download-url', MaterialsController.getDownloadUrl);

// Admin Study Materials Management (Upload, view, edit, delete across school)
router.get('/admin/list', requireRole(['ADMIN', 'SUPER_ADMIN']), MaterialsController.getAdminMaterials);
router.post('/admin', requireRole(['ADMIN', 'SUPER_ADMIN']), MaterialsController.createAdminMaterial);
router.patch('/admin/:id', requireRole(['ADMIN', 'SUPER_ADMIN']), MaterialsController.updateAdminMaterial);
router.delete('/admin/:id', requireRole(['ADMIN', 'SUPER_ADMIN']), MaterialsController.deleteAdminMaterial);

export default router;
