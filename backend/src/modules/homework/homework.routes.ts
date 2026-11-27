import express, { Router } from 'express';
import { authenticateToken } from '../../middlewares/auth.middleware';
import { requireRole } from '../../middlewares/rbac.middleware';
import { HomeworkController } from './homework.controller';

const router = Router();

const uploadParser = express.raw({
  limit: '6mb',
  type: ['image/*', 'application/pdf', 'application/octet-stream'],
});

router.use(authenticateToken);

// Teacher/Student/Admin uploads homework or submission attachment (5MB limit) - before /:id
router.post(
  '/attachment-upload',
  requireRole(['TEACHER', 'STUDENT', 'ADMIN', 'SUPER_ADMIN']),
  uploadParser,
  HomeworkController.uploadHomeworkAttachment
);

// Teacher creates homework
router.post('/', requireRole(['TEACHER', 'ADMIN', 'SUPER_ADMIN']), HomeworkController.createHomework);

// Teacher updates their assigned homework
router.patch('/:id', requireRole(['TEACHER', 'ADMIN', 'SUPER_ADMIN']), HomeworkController.updateHomework);

// Teacher views their assigned homework
router.get('/teacher/my-assigned', requireRole(['TEACHER', 'ADMIN', 'SUPER_ADMIN']), HomeworkController.getTeacherMyAssignedHomework);

// Student views homework for their class/section
router.get('/student/my-class', requireRole(['STUDENT']), HomeworkController.getStudentMyClassHomework);

// Student submits work (note/attachment) and marks homework completed
router.post('/:id/submit', requireRole(['STUDENT']), HomeworkController.submitHomework);

// Student toggles completion status for an assignment
router.post('/:id/completion', requireRole(['STUDENT']), HomeworkController.setCompletionStatus);

// Class & section homework list (scoped for teachers, coordinators, students)
router.get('/class/:classId/:sectionId', HomeworkController.getClassSectionHomework);

// Attachment download URL (scoped)
router.get('/:id/attachment-download', HomeworkController.getAttachmentDownloadUrl);

// Single homework assignment detail
router.get('/:id', HomeworkController.getHomeworkDetail);

export default router;
