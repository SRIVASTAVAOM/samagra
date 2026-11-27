import { Response, NextFunction } from 'express';
import { AuthenticatedRequest } from '../../types/auth.types';
import { AcademicsService } from './academics.service';

export class AcademicsController {
  static async getClassesAndSections(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const classes = await AcademicsService.getClassesAndSections(req.user!.schoolId);
      res.status(200).json({ success: true, data: classes });
    } catch (error) {
      next(error);
    }
  }

  static async getSubjects(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const classId = (req.query.classId || req.query.class_id) as string | undefined;
      const subjects = await AcademicsService.getSubjects(req.user!.schoolId, classId, req.user);
      res.status(200).json({ success: true, data: subjects });
    } catch (error) {
      next(error);
    }
  }

  static async getSubjectsWithDetails(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const subjects = await AcademicsService.getSubjectsWithDetails(req.user!.schoolId);
      res.status(200).json({ success: true, data: subjects });
    } catch (error) {
      next(error);
    }
  }

  static async createSubject(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const newSub = await AcademicsService.createSubject(req.user!.schoolId, req.body);
      res.status(201).json({ success: true, data: newSub, message: 'Subject created successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  static async updateSubject(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      const updated = await AcademicsService.updateSubject(req.user!.schoolId, id, req.body);
      res.status(200).json({ success: true, data: updated, message: 'Subject updated successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  static async deleteSubject(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { id } = req.params;
      await AcademicsService.deleteSubject(req.user!.schoolId, id);
      res.status(200).json({ success: true, message: 'Subject deleted successfully' });
    } catch (error: any) {
      res.status(error.statusCode || 500).json({ success: false, error: error.message });
    }
  }

  static async getClassRoster(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const { classId, sectionId } = req.params;
      const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
      if (!uuidRegex.test(classId) || !uuidRegex.test(sectionId)) {
        res.status(400).json({
          success: false,
          error: 'Invalid classId or sectionId format.',
        });
        return;
      }

      const roster = await AcademicsService.getClassRoster(req.user!, classId, sectionId);
      res.status(200).json({ success: true, data: roster });
    } catch (error: any) {
      if (error.message === 'PROFILE_NOT_FOUND') {
        res.status(404).json({
          success: false,
          error: 'Student enrollment profile not found.',
        });
        return;
      }
      if (error.message === 'FORBIDDEN_SCOPE') {
        res.status(403).json({
          success: false,
          error: 'Forbidden: You do not have permission to view rosters outside your assigned scope.',
        });
        return;
      }
      next(error);
    }
  }

  static async getMyRoster(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const roster = await AcademicsService.getMyTeacherRoster(req.user!);
      res.status(200).json({ success: true, data: roster });
    } catch (error) {
      next(error);
    }
  }

  static async getMyAllocations(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const data = await AcademicsService.getTeacherAllocations(req.user!);
      res.status(200).json({ success: true, data });
    } catch (error) {
      next(error);
    }
  }

  static async getSubjectTeachers(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const teachers = await AcademicsService.getStudentSubjectTeachers(req.user!);
      res.status(200).json({ success: true, data: teachers });
    } catch (error: any) {
      if (error.message === 'PROFILE_NOT_FOUND') {
        res.status(404).json({
          success: false,
          error: 'Student enrollment profile not found.',
        });
        return;
      }
      next(error);
    }
  }

  static async getClassmatesBirthdays(req: AuthenticatedRequest, res: Response, next: NextFunction): Promise<void> {
    try {
      const birthdays = await AcademicsService.getClassmatesBirthdays(req.user!);
      res.status(200).json({ success: true, data: birthdays });
    } catch (error) {
      next(error);
    }
  }
}

