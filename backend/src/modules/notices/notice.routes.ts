import { Router } from 'express';
import { NoticeController } from './notice.controller';
import { authenticateToken } from '../../middlewares/auth.middleware';
import { requireRole } from '../../middlewares/rbac.middleware';

const router = Router();

router.use(authenticateToken);

router.get('/student', requireRole(['STUDENT']), NoticeController.getStudentNotices);
router.get('/teacher', requireRole(['TEACHER', 'ADMIN', 'SUPER_ADMIN']), NoticeController.getTeacherNotices);
router.post('/student/:id/dismiss', requireRole(['STUDENT']), NoticeController.dismissStudentNotice);
router.post('/student/dismiss-all', requireRole(['STUDENT']), NoticeController.dismissAllStudentNotices);
router.post('/student/restore', requireRole(['STUDENT']), NoticeController.restoreStudentNotices);

// Admin Notice Management
router.get('/', requireRole(['ADMIN', 'SUPER_ADMIN']), NoticeController.getAdminNotices);
router.post('/', requireRole(['ADMIN', 'SUPER_ADMIN']), NoticeController.createNotice);
router.delete('/:id', requireRole(['ADMIN', 'SUPER_ADMIN']), NoticeController.deleteNotice);

export default router;
