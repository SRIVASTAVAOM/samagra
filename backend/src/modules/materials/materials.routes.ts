import express, { Router } from 'express';
import { authenticateToken } from '../../middlewares/auth.middleware';
import { requireRole } from '../../middlewares/rbac.middleware';
import { MaterialsController } from './materials.controller';

const router = Router();

const uploadParser = express.raw({
  limit: '10mb',
  type: ['image/*', 'application/pdf', 'application/octet-stream'],
});

// Cloudinary direct upload handler (for pre-signed uploads)
router.all('/storage-upload', uploadParser, MaterialsController.storageUploadHandler);

// Simulated test storage endpoints
router.put('/mock-s3-upload', uploadParser, (_req, res) => {
  res.status(200).json({ success: true, message: 'Mock storage upload received' });
});
router.get('/mock-s3-download', (_req, res) => {
  res.setHeader('Content-Type', 'application/pdf');
  res.status(200).send(Buffer.from('%PDF-1.4 Mock PDF Content'));
});

// Authenticated API Endpoints
router.use(authenticateToken);

// Direct binary upload for Teachers and Admins (up to 10MB)
router.post('/upload', requireRole(['TEACHER', 'ADMIN', 'SUPER_ADMIN']), uploadParser, MaterialsController.uploadMaterialFile);

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
