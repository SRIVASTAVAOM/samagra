import { Router } from 'express';
import { FeeController } from './fee.controller';
import { authenticateToken } from '../../middlewares/auth.middleware';
import { requireRole } from '../../middlewares/rbac.middleware';

const router = Router();

router.use(authenticateToken);

// Student Fee Routes
router.get('/my-fees', requireRole(['STUDENT']), FeeController.getStudentFees);
router.get('/my-receipts', requireRole(['STUDENT']), FeeController.getStudentReceipts);

// Admin Fee Operations
router.get('/admin/overview', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getAdminOverview);
router.get('/admin/counter-profile/:identifier', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getStudentCounterProfile);
router.post('/admin/collect', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.collectFee);
router.get('/admin/receipts', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getAdminReceipts);
router.get('/admin/receipts/:id/print', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getPrintableReceipt);
router.post('/admin/receipts/:id/cheque-bounce', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.markChequeBounced);
router.post('/admin/assign', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.assignFeeHead);

// Counter Shifts & Cash Closing
router.get('/admin/shifts/current', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getCurrentShift);
router.post('/admin/shifts/close', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.closeCounterShift);

// Customizable Fee Master & Structure Routes
router.post('/admin/collect-extra', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.collectExtraFee);
router.post('/admin/apply-annual-matrix', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.applyAnnualFeeCalculation);
router.get('/admin/heads', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getFeeHeads);
router.post('/admin/heads', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.createFeeHead);
router.put('/admin/heads/:id', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.updateFeeHead);
router.delete('/admin/heads/:id', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.deleteFeeHead);

router.get('/admin/cycles', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getFeeCycles);
router.post('/admin/cycles', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.createFeeCycle);

router.get('/admin/structures', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getFeeStructures);
router.get('/admin/structures/:id', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getFeeStructureById);
router.post('/admin/structures', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.saveFeeStructure);

// Concessions & Scholarships
router.get('/admin/concessions', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getConcessions);
router.post('/admin/concessions', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.createConcession);
router.delete('/admin/concessions/:id', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.deleteConcession);

// Reports: Defaulters & Day Book
router.get('/admin/defaulters', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getDefaulters);
router.get('/admin/day-book', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getDayBook);

// Standard ERP 20 Head Slots & Transport Definition
router.get('/admin/slots', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.getFeeHeadSlots);
router.post('/admin/slots', requireRole(['ADMIN', 'SUPER_ADMIN']), FeeController.saveFeeHeadSlots);

export default router;
