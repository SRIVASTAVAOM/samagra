import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../types/auth.types';
import { FeeService } from './fee.service';

export class FeeController {
  static async getStudentFees(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.getStudentFees(req.user!);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getStudentReceipts(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const receipts = await FeeService.getStudentReceipts(req.user!);
      res.status(200).json({ success: true, data: receipts });
    } catch (error) {
      next(error);
    }
  }

  static async getAdminOverview(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const classId = (req.query.class_id || req.query.classId) as string | undefined;
      const sectionId = (req.query.section_id || req.query.sectionId) as string | undefined;
      const status = req.query.status as string | undefined;
      const search = req.query.search as string | undefined;

      const data = await FeeService.getAdminOverview(req.user!, { classId, sectionId, status, search });
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async collectFee(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const receipt = await FeeService.collectFee(req.user!, req.body);
      res.status(201).json({
        success: true,
        message: 'Fee payment collected successfully and receipt generated',
        data: receipt,
      });
    } catch (error) {
      next(error);
    }
  }

  static async getAdminReceipts(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const search = req.query.search as string | undefined;
      const date = req.query.date as string | undefined;
      const mode = req.query.mode as string | undefined;
      const receipts = await FeeService.getAdminReceipts(req.user!, { search, date, mode });
      res.status(200).json({ success: true, data: receipts });
    } catch (error) {
      next(error);
    }
  }

  static async assignFeeHead(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const count = await FeeService.assignFeeHead(req.user!, req.body);
      res.status(201).json({
        success: true,
        message: `Fee assigned successfully to ${count} students`,
        data: { affected_students: count },
      });
    } catch (error) {
      next(error);
    }
  }

  // ==========================================================================
  // CUSTOMIZABLE FEE MASTER CONTROLLERS
  // ==========================================================================

  static async getFeeHeads(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.getFeeHeads(req.user!);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async createFeeHead(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.createFeeHead(req.user!, req.body);
      res.status(201).json({ success: true, message: 'Fee Head created', data });
    } catch (error) {
      next(error);
    }
  }

  static async updateFeeHead(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.updateFeeHead(req.user!, req.params.id, req.body);
      res.status(200).json({ success: true, message: 'Fee Head updated', data });
    } catch (error) {
      next(error);
    }
  }

  static async deleteFeeHead(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      await FeeService.deleteFeeHead(req.user!, req.params.id);
      res.status(200).json({ success: true, message: 'Fee Head deleted successfully' });
    } catch (error) {
      next(error);
    }
  }

  static async getFeeCycles(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.getFeeCycles(req.user!);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async createFeeCycle(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.createFeeCycle(req.user!, req.body);
      res.status(201).json({ success: true, message: 'Fee Cycle created', data });
    } catch (error) {
      next(error);
    }
  }

  static async getFeeStructures(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.getFeeStructures(req.user!);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getFeeStructureById(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.getFeeStructureById(req.user!, req.params.id);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async saveFeeStructure(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const result = await FeeService.saveFeeStructure(req.user!, req.body);
      res.status(201).json({
        success: true,
        message: 'Fee Structure saved successfully',
        data: result,
      });
    } catch (error) {
      next(error);
    }
  }

  // ==========================================================================
  // CONCESSIONS & SCHOLARSHIPS
  // ==========================================================================

  static async getConcessions(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const studentId = req.query.student_id as string | undefined;
      const data = await FeeService.getConcessions(req.user!, studentId);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async createConcession(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.createConcession(req.user!, req.body);
      res.status(201).json({ success: true, message: 'Concession granted successfully', data });
    } catch (error) {
      next(error);
    }
  }

  static async deleteConcession(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      await FeeService.deleteConcession(req.user!, req.params.id);
      res.status(200).json({ success: true, message: 'Concession revoked successfully' });
    } catch (error) {
      next(error);
    }
  }

  // ==========================================================================
  // REPORTS: DEFAULTERS & DAY BOOK
  // ==========================================================================

  static async getDefaulters(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const classId = (req.query.class_id || req.query.classId) as string | undefined;
      const sectionId = (req.query.section_id || req.query.sectionId) as string | undefined;
      const search = req.query.search as string | undefined;
      const minDaysOverdue = req.query.min_days ? Number(req.query.min_days) : undefined;

      const data = await FeeService.getDefaulters(req.user!, { classId, sectionId, search, minDaysOverdue });
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getDayBook(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const date = req.query.date as string | undefined;
      const data = await FeeService.getDayBook(req.user!, date);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getFeeHeadSlots(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.getFeeHeadSlots(req.user!);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async saveFeeHeadSlots(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.saveFeeHeadSlots(req.user!, req.body);
      res.status(200).json({ success: true, message: 'Fee Head Definitions saved successfully', data });
    } catch (error) {
      next(error);
    }
  }

  static async getStudentCounterProfile(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { identifier } = req.params;
      const data = await FeeService.getStudentCounterProfile(req.user!, identifier);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async markChequeBounced(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const data = await FeeService.markChequeBounced(req.user!, id, req.body);
      res.status(200).json({ success: true, message: 'Cheque marked bounced and balances restored', data });
    } catch (error) {
      next(error);
    }
  }

  static async getPrintableReceipt(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const data = await FeeService.getPrintableReceipt(req.user!, id);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getCurrentShift(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.getCurrentShift(req.user!);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async closeCounterShift(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.closeCounterShift(req.user!, req.body);
      res.status(200).json({ success: true, message: 'Shift closed successfully', data });
    } catch (error) {
      next(error);
    }
  }

  static async collectExtraFee(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.collectExtraFee(req.user!, req.body);
      res.status(200).json({ success: true, message: 'Extra fee collected successfully', data });
    } catch (error) {
      next(error);
    }
  }

  static async applyAnnualFeeCalculation(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await FeeService.applyAnnualFeeCalculation(req.user!, req.body);
      res.status(200).json({ success: true, message: 'Annual fee schedules applied to class', data });
    } catch (error) {
      next(error);
    }
  }
}
