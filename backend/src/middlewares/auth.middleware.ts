import { Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.config';
import { pool } from '../config/db.config';
import { AuthenticatedRequest, TokenPayload, UserRole } from '../types/auth.types';

interface CachedUserStatus {
  isActive: boolean;
  schoolId: string;
  roles: UserRole[];
  cachedAt: number;
}

const userStatusCache = new Map<string, CachedUserStatus>();
const CACHE_TTL_MS = 30 * 1000; // 30 seconds in-memory TTL

export function invalidateUserStatusCache(userId?: string): void {
  if (userId) {
    userStatusCache.delete(userId);
  } else {
    userStatusCache.clear();
  }
}

export async function authenticateToken(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({
      success: false,
      error: 'Unauthorized: Missing or malformed authentication token',
    });
    return;
  }

  const token = authHeader.split(' ')[1];

  let decoded: TokenPayload;
  try {
    decoded = jwt.verify(token, env.JWT_SECRET) as TokenPayload;
  } catch (error) {
    res.status(401).json({
      success: false,
      error: 'Unauthorized: Invalid or expired authentication token',
    });
    return;
  }

  const now = Date.now();
  let cached = userStatusCache.get(decoded.userId);

  if (!cached || now - cached.cachedAt > CACHE_TTL_MS) {
    try {
      const result = await pool.query(
        `SELECT u.id, u.is_active, u.school_id, 
                COALESCE(array_agg(r.name) FILTER (WHERE r.name IS NOT NULL), '{}') AS roles
         FROM users u
         LEFT JOIN user_roles ur ON u.id = ur.user_id
         LEFT JOIN roles r ON ur.role_id = r.id
         WHERE u.id = $1
         GROUP BY u.id, u.is_active, u.school_id;`,
        [decoded.userId]
      );

      if (result.rows.length === 0) {
        userStatusCache.delete(decoded.userId);
        res.status(401).json({
          success: false,
          error: 'Unauthorized: Account no longer exists or has been deleted',
        });
        return;
      }

      const row = result.rows[0];
      cached = {
        isActive: Boolean(row.is_active),
        schoolId: row.school_id || '',
        roles: (row.roles || []).filter((r: string | null) => r !== null) as UserRole[],
        cachedAt: now,
      };
      userStatusCache.set(decoded.userId, cached);
    } catch (dbErr) {
      // In case of transient DB pool hiccup, allow verified cryptographic JWT to proceed gracefully
      console.warn('[authenticateToken] DB live check fallback to JWT claims:', dbErr);
      req.user = decoded;
      return next();
    }
  }

  // 1. Enforce active user status
  if (!cached.isActive) {
    res.status(401).json({
      success: false,
      error: 'Unauthorized: User account is inactive or disabled. Please contact your administrator.',
    });
    return;
  }

  // 2. Enforce school/tenant validity (unless SUPER_ADMIN)
  if (!decoded.roles.includes('SUPER_ADMIN')) {
    if (cached.schoolId && decoded.schoolId && cached.schoolId !== decoded.schoolId) {
      res.status(403).json({
        success: false,
        error: 'Forbidden: User school assignment has changed or does not match token',
      });
      return;
    }
  }

  // 3. Attach fresh verified context
  req.user = {
    ...decoded,
    schoolId: cached.schoolId || decoded.schoolId,
    roles: cached.roles.length > 0 ? cached.roles : decoded.roles,
  };

  next();
}
