import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../types/auth.types';
import { NoticeService } from './notice.service';

export class NoticeController {
  static async getStudentNotices(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const notices = await NoticeService.getStudentNotices(req.user!);
      res.status(200).json({ success: true, data: notices });
    } catch (error) {
      next(error);
    }
  }

  static async dismissStudentNotice(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      if (!/^[0-9a-fA-F-]{36}$/.test(id)) {
        res.status(400).json({ success: false, error: 'Invalid notice ID' });
        return;
      }
      const dismissed = await NoticeService.dismissStudentNotice(req.user!, id);
      if (!dismissed) {
        res.status(404).json({ success: false, error: 'Notice not found' });
        return;
      }
      res.status(200).json({ success: true, message: 'Notice dismissed from view' });
    } catch (error) {
      next(error);
    }
  }

  static async dismissAllStudentNotices(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const noticeIds = Array.isArray(req.body?.noticeIds)
        ? req.body.noticeIds.filter((id: unknown): id is string => typeof id === 'string')
        : undefined;
      const count = await NoticeService.dismissAllStudentNotices(req.user!, noticeIds);
      res.status(200).json({ success: true, message: 'Notices cleared from view', data: { dismissedCount: count } });
    } catch (error) {
      next(error);
    }
  }

  static async restoreStudentNotices(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const noticeIds = Array.isArray(req.body?.noticeIds)
        ? req.body.noticeIds.filter((id: unknown): id is string => typeof id === 'string')
        : undefined;
      const count = await NoticeService.restoreStudentNotices(req.user!, noticeIds);
      res.status(200).json({ success: true, message: 'Cleared notices restored', data: { restoredCount: count } });
    } catch (error) {
      next(error);
    }
  }

  static async getAdminNotices(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const notices = await NoticeService.getAdminNotices(req.user!);
      res.status(200).json({ success: true, data: notices });
    } catch (error) {
      next(error);
    }
  }

  static async createNotice(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const idempotencyKey = (req.headers['idempotency-key'] ||
        req.headers['x-idempotency-key'] ||
        req.body.idempotencyKey ||
        req.body.idempotency_key) as string | undefined;

      const notice = await NoticeService.createNotice(req.user!, {
        ...req.body,
        idempotencyKey,
      });
      res.status(201).json({ success: true, message: 'Notice published successfully', data: notice });
    } catch (error) {
      next(error);
    }
  }

  static async deleteNotice(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const deleted = await NoticeService.deleteNotice(req.user!, id);
      if (!deleted) {
        res.status(404).json({ success: false, error: 'Notice not found' });
        return;
      }
      res.status(200).json({ success: true, message: 'Notice deleted successfully' });
    } catch (error) {
      next(error);
    }
  }
}
