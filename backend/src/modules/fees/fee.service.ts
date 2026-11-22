import { pool } from '../../config/db.config';
import { PoolClient } from 'pg';
import { TokenPayload } from '../../types/auth.types';

export interface StudentFeeItem {
  id: string;
  fee_title: string;
  due_date: string;
  amount: number;
  amount_paid: number;
  status: 'PAID' | 'PARTIAL' | 'PENDING';
  created_at: string;
  fee_head_id?: string | null;
  fee_cycle_id?: string | null;
  fine_amount?: number;
  discount_amount?: number;
}

export interface FeeReceiptItem {
  id: string;
  receipt_number: string;
  payment_date: string;
  amount_paid: number;
  payment_mode: string;
  transaction_reference: string | null;
  remarks: string | null;
  fee_title: string | null;
  created_at: string;
}

export interface StudentFeeOverview {
  fees: StudentFeeItem[];
  summary: {
    total_dues: number;
    total_paid: number;
    total_outstanding: number;
  };
}

export class FeeService {
  /**
   * Concurrency-safe sequential receipt generator with transactional advisory lock.
   * Serializes receipt numbering per school to eliminate race conditions and collisions.
   */
  private static async generateReceiptNumber(
    client: PoolClient,
    schoolId: string,
    prefixType: 'REC' | 'EXT' = 'REC'
  ): Promise<string> {
    // 1. Transaction-level advisory lock serializes receipt generation for this school
    await client.query('SELECT pg_advisory_xact_lock(hashtext($1));', [`fee_receipt_seq_${schoolId}`]);

    const todayStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const prefix = `${prefixType}-${todayStr}-`;

    // 2. Query highest receipt number matching prefix with FOR UPDATE lock
    const latestRes = await client.query(
      `SELECT receipt_number 
       FROM fee_receipts 
       WHERE receipt_number LIKE $1 
       ORDER BY receipt_number DESC 
       LIMIT 1 
       FOR UPDATE;`,
      [`${prefix}%`]
    );

    let nextNum = 1;
    if (latestRes.rows.length > 0) {
      const lastReceipt = latestRes.rows[0].receipt_number as string;
      const match = lastReceipt.match(/-(\d+)$/);
      if (match) {
        nextNum = parseInt(match[1], 10) + 1;
      }
    }

    let candidate = `${prefix}${String(nextNum).padStart(4, '0')}`;

    // 3. Collision avoidance: ensure candidate does not collide with any existing record
    let collisionCheck = await client.query(
      `SELECT 1 FROM fee_receipts WHERE receipt_number = $1;`,
      [candidate]
    );
    while (collisionCheck.rows.length > 0) {
      nextNum++;
      candidate = `${prefix}${String(nextNum).padStart(4, '0')}`;
      collisionCheck = await client.query(
        `SELECT 1 FROM fee_receipts WHERE receipt_number = $1;`,
        [candidate]
      );
    }

    return candidate;
  }
  /**
   * Student: Get my personal fee dues & history
   */
  static async getStudentFees(user: TokenPayload): Promise<StudentFeeOverview> {
    if (!user.profileId) {
      throw new Error('PROFILE_NOT_FOUND');
    }

    const query = `
      SELECT 
        f.id, f.fee_title, 
        TO_CHAR(f.due_date, 'YYYY-MM-DD') AS due_date,
        f.amount::float AS amount,
        f.amount_paid::float AS amount_paid,
        f.status, f.created_at,
        f.fee_head_id, f.fee_cycle_id,
        f.fine_amount::float AS fine_amount,
        f.discount_amount::float AS discount_amount,
        fh.name AS head_name,
        fh.type AS head_type,
        fc.name AS cycle_name
      FROM student_fees f
      LEFT JOIN fee_heads fh ON f.fee_head_id = fh.id
      LEFT JOIN fee_cycles fc ON f.fee_cycle_id = fc.id
      WHERE f.student_id = $1 AND f.school_id = $2
      ORDER BY f.due_date ASC;
    `;
    const { rows } = await pool.query(query, [user.profileId, user.schoolId]);

    let totalDues = 0;
    let totalPaid = 0;

    for (const f of rows) {
      totalDues += Number(f.amount || 0);
      totalPaid += Number(f.amount_paid || 0);
    }

    const totalOutstanding = Math.max(0, totalDues - totalPaid);

    return {
      fees: rows,
      summary: {
        total_dues: totalDues,
        total_paid: totalPaid,
        total_outstanding: totalOutstanding,
      },
    };
  }

  /**
   * Student: Get personal receipts
   */
  static async getStudentReceipts(user: TokenPayload): Promise<FeeReceiptItem[]> {
    if (!user.profileId) {
      throw new Error('PROFILE_NOT_FOUND');
    }

    const query = `
      SELECT 
        r.id, r.receipt_number,
        TO_CHAR(r.payment_date, 'YYYY-MM-DD') AS payment_date,
        r.amount_paid::float AS amount_paid,
        r.payment_mode,
        r.transaction_reference,
        r.remarks,
        f.fee_title,
        r.created_at
      FROM fee_receipts r
      LEFT JOIN student_fees f ON r.student_fee_id = f.id
      WHERE r.student_id = $1 AND r.school_id = $2
      ORDER BY r.payment_date DESC;
    `;
    const { rows } = await pool.query(query, [user.profileId, user.schoolId]);
    return rows;
  }

  /**
   * Admin: Overview with KPIs and filtered student fee records
   */
  static async getAdminOverview(
    user: TokenPayload,
    filters?: { classId?: string; sectionId?: string; status?: string; search?: string }
  ): Promise<any> {
    const listQuery = `
      SELECT 
        f.id,
        f.fee_title,
        TO_CHAR(f.due_date, 'YYYY-MM-DD') AS due_date,
        f.amount::float AS amount,
        f.amount_paid::float AS amount_paid,
        GREATEST(0, (f.amount - f.amount_paid))::float AS balance,
        f.status,
        f.created_at,
        f.fine_amount::float AS fine_amount,
        f.discount_amount::float AS discount_amount,
        sp.id AS student_id,
        sp.admission_number,
        sp.roll_number,
        CONCAT(sp.first_name, ' ', sp.last_name) AS student_name,
        c.id AS class_id,
        c.name AS class_name,
        s.id AS section_id,
        s.name AS section_name
      FROM student_fees f
      JOIN student_profiles sp ON f.student_id = sp.id
      JOIN users u ON sp.user_id = u.id
      LEFT JOIN classes c ON sp.current_class_id = c.id
      LEFT JOIN sections s ON sp.current_section_id = s.id
      WHERE f.school_id = $1
        AND ($2::uuid IS NULL OR sp.current_class_id = $2::uuid)
        AND ($3::uuid IS NULL OR sp.current_section_id = $3::uuid)
        AND ($4::text IS NULL OR f.status = $4)
        AND (
          $5::text IS NULL OR 
          sp.first_name ILIKE '%' || $5 || '%' OR 
          sp.last_name ILIKE '%' || $5 || '%' OR 
          sp.admission_number ILIKE '%' || $5 || '%' OR
          f.fee_title ILIKE '%' || $5 || '%'
        )
      ORDER BY f.due_date ASC, sp.first_name ASC;
    `;

    const { rows } = await pool.query(listQuery, [
      user.schoolId,
      filters?.classId || null,
      filters?.sectionId || null,
      filters?.status || null,
      filters?.search ? filters.search.trim() : null,
    ]);

    // Aggregate summary stats across school
    const statsQuery = `
      SELECT 
        COALESCE(SUM(amount), 0)::float AS total_receivable,
        COALESCE(SUM(amount_paid), 0)::float AS total_collected
      FROM student_fees
      WHERE school_id = $1;
    `;
    const statsRes = await pool.query(statsQuery, [user.schoolId]);
    const receivable = statsRes.rows[0]?.total_receivable || 0;
    const collected = statsRes.rows[0]?.total_collected || 0;
    const pending = Math.max(0, receivable - collected);
    const collectionPercentage = receivable > 0 ? Math.round((collected / receivable) * 1000) / 10 : 100.0;

    return {
      kpis: {
        total_receivable: receivable,
        total_collected: collected,
        total_pending: pending,
        collection_percentage: collectionPercentage,
      },
      records: rows,
    };
  }

  /**
   * Admin: Get comprehensive Student Profile for POS Counter Search
   * Includes: Student metadata, Linked Siblings, Waterfall Dues Breakdown, and Recent Receipts.
   */
  static async getStudentCounterProfile(user: TokenPayload, identifier: string): Promise<any> {
    const cleanId = identifier.trim();
    if (!cleanId) {
      throw { statusCode: 400, message: 'Student name, admission number, or roll number is required' };
    }

    // 1. Find matching student
    const studentQuery = `
      SELECT 
        sp.id, sp.admission_number, sp.roll_number,
        sp.first_name, sp.last_name,
        CONCAT(sp.first_name, ' ', sp.last_name) AS full_name,
        sp.father_name, sp.mother_name, sp.emergency_phone AS emergency_contact_number,
        sp.current_class_id, sp.current_section_id,
        c.name AS class_name,
        s.name AS section_name,
        u.phone, u.email
      FROM student_profiles sp
      JOIN users u ON sp.user_id = u.id
      LEFT JOIN classes c ON sp.current_class_id = c.id
      LEFT JOIN sections s ON sp.current_section_id = s.id
      WHERE u.school_id = $1
        AND (
          sp.id::text = $2 OR
          sp.admission_number ILIKE $2 OR
          sp.roll_number ILIKE $2 OR
          CONCAT(sp.first_name, ' ', sp.last_name) ILIKE '%' || $2 || '%' OR
          u.phone ILIKE '%' || $2 || '%'
        )
      LIMIT 1;
    `;
    const { rows: studentRows } = await pool.query(studentQuery, [user.schoolId, cleanId]);
    if (studentRows.length === 0) {
      throw { statusCode: 404, message: `Student '${cleanId}' not found in school records.` };
    }
    const student = studentRows[0];

    // 2. Auto-detect Siblings (linked by parent emergency contact or father's name)
    let siblings: any[] = [];
    if (student.emergency_contact_number || (student.father_name && student.father_name.length > 3)) {
      const sibQuery = `
        SELECT 
          sp.id, sp.admission_number,
          CONCAT(sp.first_name, ' ', sp.last_name) AS full_name,
          c.name AS class_name, s.name AS section_name
        FROM student_profiles sp
        JOIN users u ON sp.user_id = u.id
        LEFT JOIN classes c ON sp.current_class_id = c.id
        LEFT JOIN sections s ON sp.current_section_id = s.id
        WHERE u.school_id = $1 
          AND sp.id != $2
          AND (
            ($3::text IS NOT NULL AND sp.emergency_phone = $3) OR
            ($4::text IS NOT NULL AND sp.father_name ILIKE $4)
          );
      `;
      const sibRes = await pool.query(sibQuery, [
        user.schoolId,
        student.id,
        student.emergency_contact_number || null,
        student.father_name || null,
      ]);
      siblings = sibRes.rows;
    }

    // 3. Fetch all fee records with strict Waterfall Priority sorting
    // Priority: 
    // 1: LAST YEAR DUE (oldest arrears)
    // 2: Late fines
    // 3: Overdue Tuition & Academic Heads
    // 4: Upcoming / Current cycle fees
    const duesQuery = `
      SELECT 
        f.id,
        f.fee_title,
        TO_CHAR(f.due_date, 'YYYY-MM-DD') AS due_date,
        f.amount::float AS amount,
        f.amount_paid::float AS amount_paid,
        GREATEST(0, (f.amount - f.amount_paid))::float AS balance,
        f.fine_amount::float AS fine_amount,
        f.discount_amount::float AS discount_amount,
        f.status,
        f.fee_head_id,
        f.fee_cycle_id,
        COALESCE(fh.name, f.fee_title) AS head_name,
        COALESCE(fc.name, 'Regular') AS cycle_name,
        CASE 
          WHEN f.fee_title ILIKE '%LAST YEAR%' OR f.fee_title ILIKE '%PREVIOUS%DUE%' THEN 1
          WHEN f.due_date < CURRENT_DATE THEN 2
          ELSE 3
        END AS waterfall_priority
      FROM student_fees f
      LEFT JOIN fee_heads fh ON f.fee_head_id = fh.id
      LEFT JOIN fee_cycles fc ON f.fee_cycle_id = fc.id
      WHERE f.student_id = $1 AND f.school_id = $2
      ORDER BY waterfall_priority ASC, f.due_date ASC, f.created_at ASC;
    `;
    const { rows: feeRows } = await pool.query(duesQuery, [student.id, user.schoolId]);

    const totalDues = feeRows.reduce((acc, r) => acc + Number(r.amount), 0);
    const totalPaid = feeRows.reduce((acc, r) => acc + Number(r.amount_paid), 0);
    const totalOutstanding = Math.max(0, totalDues - totalPaid);

    // 4. Fetch recent 5 receipts for instant reprint/verification
    const recentReceiptsQuery = `
      SELECT 
        r.id, r.receipt_number,
        TO_CHAR(r.payment_date, 'YYYY-MM-DD') AS payment_date,
        r.amount_paid::float AS amount_paid,
        r.payment_mode, r.transaction_reference,
        r.cheque_status, r.is_cancelled,
        r.created_at
      FROM fee_receipts r
      WHERE r.student_id = $1 AND r.school_id = $2
      ORDER BY r.created_at DESC
      LIMIT 5;
    `;
    const { rows: receiptRows } = await pool.query(recentReceiptsQuery, [student.id, user.schoolId]);

    return {
      student,
      siblings,
      fees: feeRows,
      summary: {
        total_dues: totalDues,
        total_paid: totalPaid,
        total_outstanding: totalOutstanding,
        has_pending_arrears: feeRows.some((f) => f.waterfall_priority === 1 && f.balance > 0),
      },
      recent_receipts: receiptRows,
    };
  }

  /**
   * Admin: Bulletproof Real-Time Fee Collection with Idempotency, 
   * Pessimistic Locking, Strict Waterfall FIFO, Cheque Life-Cycle, and Itemized 3-Part Receipts.
   */
  static async collectFee(
    user: TokenPayload,
    data: {
      student_id: string;
      student_fee_id?: string;
      amount_paid: number;
      payment_mode: 'CASH' | 'CHEQUE' | 'BANK_TRANSFER' | 'DEMAND_DRAFT' | 'ONLINE';
      transaction_reference?: string;
      cheque_number?: string;
      cheque_bank?: string;
      cheque_date?: string;
      idempotency_key?: string;
      remarks?: string;
    }
  ): Promise<any> {
    if (!data.student_id || !data.amount_paid || data.amount_paid <= 0) {
      throw { statusCode: 400, message: 'Valid student_id and positive amount_paid are required' };
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Idempotency Check (Prevent duplicate clicks during counter rush)
      if (data.idempotency_key) {
        const existingReceipt = await client.query(
          `SELECT r.*, 
                  json_agg(ri.*) AS items
           FROM fee_receipts r
           LEFT JOIN fee_receipt_items ri ON r.id = ri.fee_receipt_id
           WHERE r.idempotency_key = $1 AND r.school_id = $2
           GROUP BY r.id;`,
          [data.idempotency_key, user.schoolId]
        );
        if (existingReceipt.rows.length > 0) {
          await client.query('COMMIT');
          console.info(`[Fee POS Notice]: Idempotency key matched. Returning existing receipt ${existingReceipt.rows[0].receipt_number}`);
          return existingReceipt.rows[0];
        }
      }

      // 2. Pessimistic Row Locking (FOR UPDATE) - Prevents race condition between concurrent counters
      const unpaidRes = await client.query(
        `SELECT id, fee_title, amount::float, amount_paid::float, 
                GREATEST(0, (amount - amount_paid))::float AS balance,
                fee_head_id, fee_cycle_id,
                CASE 
                  WHEN fee_title ILIKE '%LAST YEAR%' OR fee_title ILIKE '%PREVIOUS%DUE%' THEN 1
                  WHEN due_date < CURRENT_DATE THEN 2
                  ELSE 3
                END AS waterfall_priority
         FROM student_fees
         WHERE student_id = $1 AND school_id = $2 AND status != 'PAID'
         ORDER BY waterfall_priority ASC, due_date ASC, created_at ASC
         FOR UPDATE;`,
        [data.student_id, user.schoolId]
      );

      let remaining = Number(data.amount_paid);
      const settledItems: Array<{
        student_fee_id: string;
        head_name: string;
        base_amount: number;
        paid_amount: number;
      }> = [];

      let primaryFeeId: string | null = data.student_fee_id || null;

      // 3. Priority Settlement: If user explicitly targeted a specific fee head
      if (data.student_fee_id) {
        const target = unpaidRes.rows.find((r) => r.id === data.student_fee_id);
        if (target && target.balance > 0) {
          const payForTarget = Math.min(remaining, target.balance);
          if (payForTarget > 0) {
            await client.query(
              `UPDATE student_fees
               SET amount_paid = amount_paid + $1,
                   status = CASE WHEN (amount_paid + $1) >= amount THEN 'PAID' ELSE 'PARTIAL' END
               WHERE id = $2 AND school_id = $3;`,
              [payForTarget, target.id, user.schoolId]
            );
            remaining -= payForTarget;
            settledItems.push({
              student_fee_id: target.id,
              head_name: target.fee_title,
              base_amount: target.amount,
              paid_amount: payForTarget,
            });
          }
        }
      }

      // 4. Cascade remaining across Waterfall FIFO (Oldest Arrears -> Fines -> Current)
      for (const fee of unpaidRes.rows) {
        if (remaining <= 0) break;
        if (data.student_fee_id && fee.id === data.student_fee_id) continue;

        const bal = fee.balance;
        if (bal <= 0) continue;

        const payForThis = Math.min(remaining, bal);
        await client.query(
          `UPDATE student_fees
           SET amount_paid = amount_paid + $1,
               status = CASE WHEN (amount_paid + $1) >= amount THEN 'PAID' ELSE 'PARTIAL' END
           WHERE id = $2 AND school_id = $3;`,
          [payForThis, fee.id, user.schoolId]
        );
        if (!primaryFeeId) primaryFeeId = fee.id;
        remaining -= payForThis;
        settledItems.push({
          student_fee_id: fee.id,
          head_name: fee.fee_title,
          base_amount: fee.amount,
          paid_amount: payForThis,
        });
      }

      // 5. Generate Standard Sequential Receipt Number: REC-YYYYMMDD-XXXX (Concurrency safe)
      const receiptNumber = await FeeService.generateReceiptNumber(client, user.schoolId, 'REC');

      const isCheque = data.payment_mode === 'CHEQUE';
      const chequeStatus = isCheque ? 'PENDING_CLEARANCE' : 'CLEARED';

      const breakdownSummary = settledItems.map((si) => `${si.head_name}: ₹${si.paid_amount}`).join(' | ');
      const combinedRemarks = data.remarks
        ? `${data.remarks} (Breakdown: ${breakdownSummary})`
        : (breakdownSummary ? `Settled: ${breakdownSummary}` : 'Fee Payment via Admin Counter');

      // 6. Insert Master Receipt Record
      let insertReceipt;
      try {
        insertReceipt = await client.query(
          `INSERT INTO fee_receipts (
             school_id, student_fee_id, student_id, receipt_number,
             payment_date, amount_paid, payment_mode, transaction_reference,
             cheque_number, cheque_bank, cheque_date, cheque_status,
             idempotency_key, remarks, waterfall_breakdown, collected_by
           ) VALUES ($1, $2, $3, $4, CURRENT_DATE, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
           RETURNING *;`,
          [
            user.schoolId,
            primaryFeeId || null,
            data.student_id,
            receiptNumber,
            data.amount_paid,
            data.payment_mode || 'CASH',
            data.transaction_reference || null,
            data.cheque_number || null,
            data.cheque_bank || null,
            data.cheque_date || null,
            chequeStatus,
            data.idempotency_key || null,
            combinedRemarks,
            JSON.stringify(settledItems),
            user.userId || null,
          ]
        );
      } catch (insertErr: any) {
        if (insertErr.code === '23505' && insertErr.constraint?.includes('receipt_number')) {
          // Retry once with refreshed unique sequence on conflict
          const retryReceiptNumber = await FeeService.generateReceiptNumber(client, user.schoolId, 'REC');
          insertReceipt = await client.query(
            `INSERT INTO fee_receipts (
               school_id, student_fee_id, student_id, receipt_number,
               payment_date, amount_paid, payment_mode, transaction_reference,
               cheque_number, cheque_bank, cheque_date, cheque_status,
               idempotency_key, remarks, waterfall_breakdown, collected_by
             ) VALUES ($1, $2, $3, $4, CURRENT_DATE, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15)
             RETURNING *;`,
            [
              user.schoolId,
              primaryFeeId || null,
              data.student_id,
              retryReceiptNumber,
              data.amount_paid,
              data.payment_mode || 'CASH',
              data.transaction_reference || null,
              data.cheque_number || null,
              data.cheque_bank || null,
              data.cheque_date || null,
              chequeStatus,
              data.idempotency_key || null,
              combinedRemarks,
              JSON.stringify(settledItems),
              user.userId || null,
            ]
          );
        } else {
          throw insertErr;
        }
      }
      const receipt = insertReceipt.rows[0];

      // 7. Insert Itemized Line Items for 3-part receipt printing
      for (const item of settledItems) {
        await client.query(
          `INSERT INTO fee_receipt_items (
             fee_receipt_id, student_fee_id, fee_head_name, base_amount, net_paid
           ) VALUES ($1, $2, $3, $4, $5);`,
          [receipt.id, item.student_fee_id, item.head_name, item.base_amount, item.paid_amount]
        );
      }

      // 8. Auto-Tally with Active Counter Shift if one exists
      const shiftUpdateQuery = `
        UPDATE fee_counter_shifts
        SET total_receipts_count = total_receipts_count + 1,
            system_cash_total = system_cash_total + CASE WHEN $2 = 'CASH' THEN $3 ELSE 0.00 END,
            system_upi_total = system_upi_total + CASE WHEN $2 IN ('ONLINE', 'UPI') THEN $3 ELSE 0.00 END,
            system_cheque_total = system_cheque_total + CASE WHEN $2 = 'CHEQUE' THEN $3 ELSE 0.00 END,
            system_bank_total = system_bank_total + CASE WHEN $2 = 'BANK_TRANSFER' THEN $3 ELSE 0.00 END
        WHERE school_id = $1 AND clerk_id = $4 AND status = 'OPEN';
      `;
      await client.query(shiftUpdateQuery, [
        user.schoolId,
        data.payment_mode,
        data.amount_paid,
        user.userId,
      ]);

      await client.query('COMMIT');
      return {
        ...receipt,
        items: settledItems,
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Admin: 1-Click Cheque Bounce Handler & Reversal
   * Marks receipt bounced, restores unpaid balances, and automatically appends bank bounce penalty.
   */
  static async markChequeBounced(
    user: TokenPayload,
    receiptId: string,
    data: { penalty_amount?: number; reason?: string }
  ): Promise<any> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const receiptRes = await client.query(
        `SELECT * FROM fee_receipts WHERE id = $1 AND school_id = $2 FOR UPDATE;`,
        [receiptId, user.schoolId]
      );
      if (receiptRes.rows.length === 0) {
        throw { statusCode: 404, message: 'Receipt not found' };
      }
      const receipt = receiptRes.rows[0];
      if (receipt.is_cancelled || receipt.cheque_status === 'BOUNCED') {
        throw { statusCode: 400, message: 'This receipt is already marked as cancelled or bounced' };
      }

      // 1. Fetch itemized line items settled by this receipt
      const itemsRes = await client.query(
        `SELECT student_fee_id, net_paid FROM fee_receipt_items WHERE fee_receipt_id = $1;`,
        [receiptId]
      );

      // 2. Reverse amounts paid on student_fees
      for (const item of itemsRes.rows) {
        if (item.student_fee_id) {
          await client.query(
            `UPDATE student_fees
             SET amount_paid = GREATEST(0, amount_paid - $1),
                 status = CASE WHEN (amount_paid - $1) <= 0 THEN 'PENDING' ELSE 'PARTIAL' END
             WHERE id = $2 AND school_id = $3;`,
            [item.net_paid, item.student_fee_id, user.schoolId]
          );
        }
      }

      // 3. Mark receipt as bounced and cancelled
      const cancelReason = data.reason || 'Cheque dishonoured by issuing bank';
      await client.query(
        `UPDATE fee_receipts
         SET is_cancelled = TRUE,
             cheque_status = 'BOUNCED',
             cancellation_reason = $1,
             cancelled_at = CURRENT_TIMESTAMP,
             cancelled_by = $2
         WHERE id = $3;`,
        [cancelReason, user.userId, receiptId]
      );

      // 4. Append Bank Dishonour Penalty if specified (default: ₹500)
      const penalty = Number(data.penalty_amount ?? 500);
      if (penalty > 0) {
        const ayRes = await client.query(
          `SELECT id FROM academic_years WHERE school_id = $1 AND is_current = TRUE LIMIT 1;`,
          [user.schoolId]
        );
        const ayId = ayRes.rows[0]?.id;
        if (ayId) {
          await client.query(
            `INSERT INTO student_fees (
               school_id, student_id, academic_year_id, fee_title,
               due_date, amount, amount_paid, status
             ) VALUES ($1, $2, $3, $4, CURRENT_DATE + INTERVAL '7 days', $5, 0.00, 'PENDING');`,
            [
              user.schoolId,
              receipt.student_id,
              ayId,
              `CHEQUE BOUNCE PENALTY (${receipt.receipt_number})`,
              penalty,
            ]
          );
        }
      }

      await client.query('COMMIT');
      return { success: true, message: 'Cheque marked bounced and balances restored successfully' };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  /**
   * Admin: Get Complete 3-Part Printable Receipt Data (School Copy, Student Copy, Bank Copy)
   */
  static async getPrintableReceipt(user: TokenPayload, receiptId: string): Promise<any> {
    const receiptQuery = `
      SELECT 
        r.id, r.receipt_number,
        TO_CHAR(r.payment_date, 'DD/MM/YYYY') AS payment_date,
        r.amount_paid::float AS amount_paid,
        r.payment_mode, r.transaction_reference,
        r.cheque_number, r.cheque_bank, r.cheque_date,
        r.cheque_status, r.is_cancelled, r.cancellation_reason,
        r.remarks, r.created_at,
        sp.id AS student_id,
        sp.admission_number, sp.roll_number,
        CONCAT(sp.first_name, ' ', sp.last_name) AS student_name,
        sp.father_name, sp.emergency_phone AS emergency_contact_number,
        c.name AS class_name, s.name AS section_name,
        sch.name AS school_name, sch.code AS school_code,
        u_collector.identifier AS collected_by_name
      FROM fee_receipts r
      JOIN student_profiles sp ON r.student_id = sp.id
      JOIN schools sch ON r.school_id = sch.id
      LEFT JOIN classes c ON sp.current_class_id = c.id
      LEFT JOIN sections s ON sp.current_section_id = s.id
      LEFT JOIN users u_collector ON r.collected_by = u_collector.id
      WHERE r.id = $1 AND r.school_id = $2;
    `;
    const { rows: receiptRows } = await pool.query(receiptQuery, [receiptId, user.schoolId]);
    if (receiptRows.length === 0) {
      throw { statusCode: 404, message: 'Receipt not found' };
    }
    const receipt = receiptRows[0];

    const itemsQuery = `
      SELECT id, fee_head_name, base_amount::float, net_paid::float
      FROM fee_receipt_items
      WHERE fee_receipt_id = $1
      ORDER BY created_at ASC;
    `;
    const { rows: itemRows } = await pool.query(itemsQuery, [receiptId]);

    return {
      ...receipt,
      items: itemRows,
    };
  }

  /**
   * Admin: Counter Shift Day-Book Management
   */
  static async getCurrentShift(user: TokenPayload): Promise<any> {
    const { rows } = await pool.query(
      `SELECT * FROM fee_counter_shifts
       WHERE school_id = $1 AND clerk_id = $2 AND status = 'OPEN'
       ORDER BY opened_at DESC LIMIT 1;`,
      [user.schoolId, user.userId]
    );
    if (rows.length === 0) {
      // Auto open shift for today if none exists
      const newShift = await pool.query(
        `INSERT INTO fee_counter_shifts (school_id, clerk_id, shift_date)
         VALUES ($1, $2, CURRENT_DATE)
         RETURNING *;`,
        [user.schoolId, user.userId]
      );
      return newShift.rows[0];
    }
    return rows[0];
  }

  static async closeCounterShift(
    user: TokenPayload,
    data: {
      physical_cash: number;
      denominations: Record<string, number>;
      closing_notes?: string;
    }
  ): Promise<any> {
    const shift = await this.getCurrentShift(user);
    const variance = Number(data.physical_cash) - Number(shift.system_cash_total);

    const { rows } = await pool.query(
      `UPDATE fee_counter_shifts
       SET status = 'CLOSED',
           closed_at = CURRENT_TIMESTAMP,
           physical_cash_total = $1,
           denominations = $2,
           cash_variance = $3,
           closing_notes = $4
       WHERE id = $5 AND school_id = $6
       RETURNING *;`,
      [
        data.physical_cash,
        JSON.stringify(data.denominations),
        variance,
        data.closing_notes || null,
        shift.id,
        user.schoolId,
      ]
    );
    return rows[0];
  }

  /**
   * Admin: List all receipts with student and class metadata
   */
  static async getAdminReceipts(
    user: TokenPayload,
    filtersParam?: string | { search?: string; date?: string; mode?: string }
  ): Promise<any[]> {
    const filters = typeof filtersParam === 'string' ? { search: filtersParam } : (filtersParam || {});
    const search = filters.search ? filters.search.trim() : null;
    const date = filters.date ? filters.date.trim() : null;
    const rawMode = filters.mode ? filters.mode.trim().toUpperCase() : null;

    let modeFilterCondition = '';
    const params: any[] = [user.schoolId, search, date];

    if (rawMode && rawMode !== 'ALL') {
      if (rawMode === 'CASH') {
        params.push('CASH');
        modeFilterCondition = `AND r.payment_mode = $${params.length}`;
      } else if (rawMode === 'ONLINE') {
        modeFilterCondition = `AND r.payment_mode IN ('ONLINE', 'BANK_TRANSFER')`;
      } else if (rawMode === 'APP_PAYMENTS' || rawMode === 'APP' || rawMode === 'UPI') {
        modeFilterCondition = `AND r.payment_mode IN ('APP_PAYMENTS', 'APP', 'UPI')`;
      } else if (rawMode === 'CHEQUES' || rawMode === 'CHEQUE') {
        modeFilterCondition = `AND r.payment_mode IN ('CHEQUE', 'CHEQUES', 'DEMAND_DRAFT')`;
      } else {
        params.push(rawMode);
        modeFilterCondition = `AND r.payment_mode = $${params.length}`;
      }
    }

    const query = `
      SELECT 
        r.id,
        r.receipt_number,
        TO_CHAR(r.payment_date, 'YYYY-MM-DD') AS payment_date,
        r.amount_paid::float AS amount_paid,
        r.payment_mode,
        r.transaction_reference,
        r.remarks,
        r.created_at,
        f.fee_title,
        sp.id AS student_id,
        sp.admission_number,
        sp.roll_number,
        CONCAT(sp.first_name, ' ', sp.last_name) AS student_name,
        c.name AS class_name,
        s.name AS section_name
      FROM fee_receipts r
      JOIN student_profiles sp ON r.student_id = sp.id
      LEFT JOIN student_fees f ON r.student_fee_id = f.id
      LEFT JOIN classes c ON sp.current_class_id = c.id
      LEFT JOIN sections s ON sp.current_section_id = s.id
      WHERE r.school_id = $1
        AND (
          $2::text IS NULL OR
          r.receipt_number ILIKE '%' || $2 || '%' OR
          sp.first_name ILIKE '%' || $2 || '%' OR
          sp.last_name ILIKE '%' || $2 || '%' OR
          sp.admission_number ILIKE '%' || $2 || '%' OR
          r.transaction_reference ILIKE '%' || $2 || '%'
        )
        AND ($3::date IS NULL OR r.payment_date = $3::date)
        ${modeFilterCondition}
      ORDER BY r.created_at DESC;
    `;
    const { rows } = await pool.query(query, params);
    return rows;
  }

  /**
   * Admin: Assign new fee head to entire class or school (Legacy backward compatible)
   */
  static async assignFeeHead(
    user: TokenPayload,
    data: {
      class_id?: string;
      fee_title: string;
      amount: number;
      due_date: string;
      fee_head_id?: string;
      fee_cycle_id?: string;
    }
  ): Promise<number> {
    if (!data.fee_title?.trim() || !data.amount || !data.due_date) {
      const err: any = new Error('fee_title, amount, and due_date are required');
      err.statusCode = 400;
      throw err;
    }

    // Get active academic year
    const ayRes = await pool.query(
      `SELECT id FROM academic_years WHERE school_id = $1 AND is_current = TRUE LIMIT 1;`,
      [user.schoolId]
    );
    let finalAyId = ayRes.rows[0]?.id;
    if (!finalAyId) {
      const fallbackAy = await pool.query(
        `SELECT id FROM academic_years WHERE school_id = $1 ORDER BY start_date DESC LIMIT 1;`,
        [user.schoolId]
      );
      if (fallbackAy.rows.length === 0) {
        throw new Error('No academic year configured for this school');
      }
      finalAyId = fallbackAy.rows[0].id;
    }

    // Fetch target students
    const studentsRes = await pool.query(
      `SELECT sp.id FROM student_profiles sp
       JOIN users u ON sp.user_id = u.id
       WHERE u.school_id = $1 
         AND ($2::uuid IS NULL OR sp.current_class_id = $2::uuid)
         AND u.is_active = TRUE;`,
      [user.schoolId, data.class_id || null]
    );

    if (studentsRes.rows.length === 0) {
      return 0;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      for (const st of studentsRes.rows) {
        await client.query(
          `INSERT INTO student_fees (
             school_id, student_id, academic_year_id, fee_title, due_date, amount, amount_paid, status, fee_head_id, fee_cycle_id
           ) VALUES ($1, $2, $3, $4, $5, $6, 0.00, 'PENDING', $7, $8);`,
          [
            user.schoolId,
            st.id,
            finalAyId,
            data.fee_title.trim(),
            data.due_date,
            data.amount,
            data.fee_head_id || null,
            data.fee_cycle_id || null,
          ]
        );
      }
      await client.query('COMMIT');
      return studentsRes.rows.length;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  // ==========================================================================
  // CUSTOMIZABLE FEE MASTER APIS
  // ==========================================================================

  /**
   * Get all Fee Heads for school
   */
  static async getFeeHeads(user: TokenPayload): Promise<any[]> {
    const { rows } = await pool.query(
      `SELECT id, name, code, type, is_optional, description, created_at
       FROM fee_heads
       WHERE school_id = $1
       ORDER BY (CASE WHEN type = 'RECURRING' THEN 1 WHEN type = 'ONE_TIME' THEN 2 ELSE 3 END), name ASC;`,
      [user.schoolId]
    );
    return rows;
  }

  /**
   * Create new Fee Head
   */
  static async createFeeHead(
    user: TokenPayload,
    data: { name: string; code: string; type?: string; is_optional?: boolean; description?: string }
  ): Promise<any> {
    if (!data.name?.trim() || !data.code?.trim()) {
      const err: any = new Error('Name and Code are required');
      err.statusCode = 400;
      throw err;
    }
    const cleanCode = data.code.trim().toUpperCase().replace(/\s+/g, '_');
    const { rows } = await pool.query(
      `INSERT INTO fee_heads (school_id, name, code, type, is_optional, description)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *;`,
      [
        user.schoolId,
        data.name.trim(),
        cleanCode,
        data.type || 'RECURRING',
        Boolean(data.is_optional),
        data.description?.trim() || null,
      ]
    );
    return rows[0];
  }

  /**
   * Update Fee Head
   */
  static async updateFeeHead(
    user: TokenPayload,
    id: string,
    data: { name?: string; type?: string; is_optional?: boolean; description?: string }
  ): Promise<any> {
    const { rows } = await pool.query(
      `UPDATE fee_heads
       SET name = COALESCE($1, name),
           type = COALESCE($2, type),
           is_optional = COALESCE($3, is_optional),
           description = COALESCE($4, description)
       WHERE id = $5 AND school_id = $6
       RETURNING *;`,
      [data.name?.trim() || null, data.type || null, data.is_optional, data.description || null, id, user.schoolId]
    );
    return rows[0];
  }

  /**
   * Delete Fee Head
   */
  static async deleteFeeHead(user: TokenPayload, id: string): Promise<boolean> {
    // Check if in use
    const checkRes = await pool.query(
      `SELECT 1 FROM student_fees WHERE fee_head_id = $1 AND school_id = $2 LIMIT 1;`,
      [id, user.schoolId]
    );
    if (checkRes.rows.length > 0) {
      const err: any = new Error('Cannot delete this Fee Head because active student fees are assigned to it.');
      err.statusCode = 400;
      throw err;
    }
    await pool.query(`DELETE FROM fee_heads WHERE id = $1 AND school_id = $2;`, [id, user.schoolId]);
    return true;
  }

  /**
   * Get all Fee Cycles for school
   */
  static async getFeeCycles(user: TokenPayload): Promise<any[]> {
    const { rows } = await pool.query(
      `SELECT id, name, cycle_type, TO_CHAR(due_date, 'YYYY-MM-DD') AS due_date, 
              grace_period_days, sequence_order, created_at
       FROM fee_cycles
       WHERE school_id = $1
       ORDER BY sequence_order ASC, due_date ASC;`,
      [user.schoolId]
    );
    return rows;
  }

  /**
   * Create Fee Cycle
   */
  static async createFeeCycle(
    user: TokenPayload,
    data: { name: string; cycle_type: string; due_date: string; grace_period_days?: number; sequence_order?: number }
  ): Promise<any> {
    if (!data.name?.trim() || !data.due_date) {
      const err: any = new Error('Cycle name and due_date are required');
      err.statusCode = 400;
      throw err;
    }
    // Get AY
    const ayRes = await pool.query(
      `SELECT id FROM academic_years WHERE school_id = $1 AND is_current = TRUE LIMIT 1;`,
      [user.schoolId]
    );
    const ayId = ayRes.rows[0]?.id || (await pool.query(`SELECT id FROM academic_years WHERE school_id = $1 ORDER BY start_date DESC LIMIT 1;`, [user.schoolId])).rows[0].id;

    const { rows } = await pool.query(
      `INSERT INTO fee_cycles (school_id, academic_year_id, name, cycle_type, due_date, grace_period_days, sequence_order)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *;`,
      [
        user.schoolId,
        ayId,
        data.name.trim(),
        data.cycle_type || 'QUARTERLY',
        data.due_date,
        data.grace_period_days ?? 10,
        data.sequence_order ?? 1,
      ]
    );
    return rows[0];
  }

  /**
   * Get Fee Structure Templates
   */
  static async getFeeStructures(user: TokenPayload): Promise<any[]> {
    const { rows } = await pool.query(
      `SELECT fs.id, fs.name, fs.class_id, c.name AS class_name, fs.created_at,
              COUNT(fsi.id)::int AS items_count,
              COALESCE(SUM(fsi.amount), 0)::float AS total_annual_amount
       FROM fee_structures fs
       LEFT JOIN classes c ON fs.class_id = c.id
       LEFT JOIN fee_structure_items fsi ON fs.id = fsi.fee_structure_id
       WHERE fs.school_id = $1
       GROUP BY fs.id, fs.name, fs.class_id, c.name, fs.created_at
       ORDER BY c.name ASC NULLS LAST, fs.name ASC;`,
      [user.schoolId]
    );
    return rows;
  }

  /**
   * Get Fee Structure Details by ID
   */
  static async getFeeStructureById(user: TokenPayload, id: string): Promise<any> {
    const structRes = await pool.query(
      `SELECT fs.id, fs.name, fs.class_id, c.name AS class_name
       FROM fee_structures fs
       LEFT JOIN classes c ON fs.class_id = c.id
       WHERE fs.id = $1 AND fs.school_id = $2;`,
      [id, user.schoolId]
    );
    if (structRes.rows.length === 0) {
      const err: any = new Error('Fee Structure not found');
      err.statusCode = 404;
      throw err;
    }

    const itemsRes = await pool.query(
      `SELECT fsi.id, fsi.fee_head_id, fsi.fee_cycle_id, fsi.amount::float,
              fh.name AS head_name, fh.code AS head_code,
              fc.name AS cycle_name, TO_CHAR(fc.due_date, 'YYYY-MM-DD') AS due_date
       FROM fee_structure_items fsi
       JOIN fee_heads fh ON fsi.fee_head_id = fh.id
       JOIN fee_cycles fc ON fsi.fee_cycle_id = fc.id
       WHERE fsi.fee_structure_id = $1
       ORDER BY fc.sequence_order ASC, fh.name ASC;`,
      [id]
    );

    return {
      structure: structRes.rows[0],
      items: itemsRes.rows,
    };
  }

  /**
   * Save (Create or Replace) Fee Structure Template & optionally apply to students
   */
  static async saveFeeStructure(
    user: TokenPayload,
    data: {
      id?: string;
      name: string;
      class_id?: string;
      items: Array<{ fee_head_id: string; fee_cycle_id: string; amount: number }>;
      apply_to_students?: boolean;
    }
  ): Promise<any> {
    if (!data.name?.trim() || !data.items || data.items.length === 0) {
      const err: any = new Error('Structure name and at least one fee item amount are required');
      err.statusCode = 400;
      throw err;
    }

    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Academic year
      const ayRes = await client.query(
        `SELECT id FROM academic_years WHERE school_id = $1 AND is_current = TRUE LIMIT 1;`,
        [user.schoolId]
      );
      const ayId = ayRes.rows[0]?.id || (await client.query(`SELECT id FROM academic_years WHERE school_id = $1 ORDER BY start_date DESC LIMIT 1;`, [user.schoolId])).rows[0].id;

      let structureId = data.id;

      if (structureId) {
        await client.query(
          `UPDATE fee_structures
           SET name = $1, class_id = $2
           WHERE id = $3 AND school_id = $4;`,
          [data.name.trim(), data.class_id || null, structureId, user.schoolId]
        );
        // Clear old items
        await client.query(`DELETE FROM fee_structure_items WHERE fee_structure_id = $1;`, [structureId]);
      } else {
        const insRes = await client.query(
          `INSERT INTO fee_structures (school_id, academic_year_id, name, class_id)
           VALUES ($1, $2, $3, $4)
           RETURNING id;`,
          [user.schoolId, ayId, data.name.trim(), data.class_id || null]
        );
        structureId = insRes.rows[0].id;
      }

      // Insert items
      for (const item of data.items) {
        if (Number(item.amount) > 0) {
          await client.query(
            `INSERT INTO fee_structure_items (fee_structure_id, fee_head_id, fee_cycle_id, amount)
             VALUES ($1, $2, $3, $4)
             ON CONFLICT (fee_structure_id, fee_head_id, fee_cycle_id) 
             DO UPDATE SET amount = EXCLUDED.amount;`,
            [structureId, item.fee_head_id, item.fee_cycle_id, Number(item.amount)]
          );
        }
      }

      // If requested to apply directly to enrolled students:
      let assignedStudentsCount = 0;
      if (data.apply_to_students && data.class_id) {
        const students = await client.query(
          `SELECT sp.id FROM student_profiles sp
           JOIN users u ON sp.user_id = u.id
           WHERE u.school_id = $1 AND sp.current_class_id = $2 AND u.is_active = TRUE;`,
          [user.schoolId, data.class_id]
        );

        // Fetch heads and cycles metadata
        const headsMap = new Map();
        const headsRes = await client.query(`SELECT id, name FROM fee_heads WHERE school_id = $1;`, [user.schoolId]);
        for (const h of headsRes.rows) headsMap.set(h.id, h.name);

        const cyclesMap = new Map();
        const cyclesRes = await client.query(`SELECT id, name, TO_CHAR(due_date, 'YYYY-MM-DD') AS due_date FROM fee_cycles WHERE school_id = $1;`, [user.schoolId]);
        for (const c of cyclesRes.rows) cyclesMap.set(c.id, c);

        // Pre-fetch all active concessions for matched students in one batch query (Eliminates N+1 query loop)
        const studentIds = students.rows.map((st: any) => st.id);
        const concessionsMap = new Map<string, any[]>();
        if (studentIds.length > 0) {
          const allConcRes = await client.query(
            `SELECT student_id, fee_head_id, concession_type, concession_value::float 
             FROM student_fee_concessions 
             WHERE student_id = ANY($1::uuid[]) AND is_active = TRUE;`,
            [studentIds]
          );
          for (const c of allConcRes.rows) {
            const list = concessionsMap.get(c.student_id) || [];
            list.push(c);
            concessionsMap.set(c.student_id, list);
          }
        }

        for (const st of students.rows) {
          const studentConcessions = concessionsMap.get(st.id) || [];

          for (const item of data.items) {
            const headName = headsMap.get(item.fee_head_id) || 'Fee';
            const cycle = cyclesMap.get(item.fee_cycle_id);
            const cycleName = cycle?.name || '';
            const dueDate = cycle?.due_date || new Date().toISOString().slice(0, 10);
            const title = `${headName} (${cycleName})`;

            let baseAmount = Number(item.amount);
            let discountAmount = 0;

            // Apply concession if matched
            const matchingConc = studentConcessions.find((c) => !c.fee_head_id || c.fee_head_id === item.fee_head_id);
            if (matchingConc) {
              if (matchingConc.concession_type === 'PERCENTAGE') {
                discountAmount = (baseAmount * matchingConc.concession_value) / 100;
              } else {
                discountAmount = Math.min(baseAmount, matchingConc.concession_value);
              }
            }

            const finalAmount = Math.max(0, baseAmount - discountAmount);

            // Insert or update pending student_fees
            await client.query(
              `INSERT INTO student_fees (
                 school_id, student_id, academic_year_id, fee_title, due_date, 
                 amount, amount_paid, status, fee_head_id, fee_cycle_id, discount_amount
               ) VALUES ($1, $2, $3, $4, $5, $6, 0.00, 'PENDING', $7, $8, $9);`,
              [
                user.schoolId,
                st.id,
                ayId,
                title,
                dueDate,
                finalAmount,
                item.fee_head_id,
                item.fee_cycle_id,
                discountAmount,
              ]
            );
          }
          assignedStudentsCount++;
        }
      }

      await client.query('COMMIT');
      return { structure_id: structureId, assigned_students: assignedStudentsCount };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  // ==========================================================================
  // CONCESSIONS & SCHOLARSHIPS APIS
  // ==========================================================================

  /**
   * Get all Concessions / Scholarships in school
   */
  static async getConcessions(user: TokenPayload, studentId?: string): Promise<any[]> {
    const query = `
      SELECT 
        sfc.id,
        sfc.student_id,
        CONCAT(sp.first_name, ' ', sp.last_name) AS student_name,
        sp.admission_number,
        c.name AS class_name,
        s.name AS section_name,
        sfc.fee_head_id,
        COALESCE(fh.name, 'All Fee Heads') AS head_name,
        sfc.concession_type,
        sfc.concession_value::float AS concession_value,
        sfc.reason,
        sfc.is_active,
        sfc.created_at
      FROM student_fee_concessions sfc
      JOIN student_profiles sp ON sfc.student_id = sp.id
      LEFT JOIN fee_heads fh ON sfc.fee_head_id = fh.id
      LEFT JOIN classes c ON sp.current_class_id = c.id
      LEFT JOIN sections s ON sp.current_section_id = s.id
      WHERE sfc.school_id = $1
        AND ($2::uuid IS NULL OR sfc.student_id = $2::uuid)
      ORDER BY sfc.created_at DESC;
    `;
    const { rows } = await pool.query(query, [user.schoolId, studentId || null]);
    return rows;
  }

  /**
   * Create Concession
   */
  static async createConcession(
    user: TokenPayload,
    data: {
      student_id: string;
      fee_head_id?: string;
      concession_type: 'PERCENTAGE' | 'FLAT_AMOUNT';
      concession_value: number;
      reason: string;
    }
  ): Promise<any> {
    if (!data.student_id || !data.concession_value || !data.reason?.trim()) {
      const err: any = new Error('student_id, concession_value, and reason are required');
      err.statusCode = 400;
      throw err;
    }
    const { rows } = await pool.query(
      `INSERT INTO student_fee_concessions (
         school_id, student_id, fee_head_id, concession_type, concession_value, reason, approved_by, is_active
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, TRUE)
       RETURNING *;`,
      [
        user.schoolId,
        data.student_id,
        data.fee_head_id || null,
        data.concession_type || 'PERCENTAGE',
        data.concession_value,
        data.reason.trim(),
        user.userId,
      ]
    );
    return rows[0];
  }

  /**
   * Delete Concession
   */
  static async deleteConcession(user: TokenPayload, id: string): Promise<boolean> {
    await pool.query(
      `DELETE FROM student_fee_concessions WHERE id = $1 AND school_id = $2;`,
      [id, user.schoolId]
    );
    return true;
  }

  // ==========================================================================
  // REPORTS: DEFAULTERS & DAY-BOOK
  // ==========================================================================

  /**
   * Get Defaulters list with days overdue & parent contacts
   */
  static async getDefaulters(
    user: TokenPayload,
    filters?: { classId?: string; sectionId?: string; search?: string; minDaysOverdue?: number }
  ): Promise<any[]> {
    const query = `
      SELECT 
        sp.id AS student_id,
        sp.admission_number,
        sp.roll_number,
        CONCAT(sp.first_name, ' ', sp.last_name) AS student_name,
        sp.father_name,
        sp.primary_phone,
        u.email,
        c.id AS class_id,
        c.name AS class_name,
        s.id AS section_id,
        s.name AS section_name,
        COUNT(f.id)::int AS overdue_heads_count,
        SUM(f.amount - f.amount_paid)::float AS total_overdue_amount,
        TO_CHAR(MIN(f.due_date), 'YYYY-MM-DD') AS oldest_due_date,
        (CURRENT_DATE - MIN(f.due_date))::int AS days_overdue
      FROM student_fees f
      JOIN student_profiles sp ON f.student_id = sp.id
      JOIN users u ON sp.user_id = u.id
      LEFT JOIN classes c ON sp.current_class_id = c.id
      LEFT JOIN sections s ON sp.current_section_id = s.id
      WHERE f.school_id = $1
        AND f.status != 'PAID'
        AND f.due_date < CURRENT_DATE
        AND ($2::uuid IS NULL OR sp.current_class_id = $2::uuid)
        AND ($3::uuid IS NULL OR sp.current_section_id = $3::uuid)
        AND (
          $4::text IS NULL OR
          sp.first_name ILIKE '%' || $4 || '%' OR
          sp.last_name ILIKE '%' || $4 || '%' OR
          sp.admission_number ILIKE '%' || $4 || '%'
        )
      GROUP BY sp.id, sp.admission_number, sp.roll_number, sp.first_name, sp.last_name, sp.father_name, sp.primary_phone, u.email, c.id, c.name, s.id, s.name
      HAVING ($5::int IS NULL OR (CURRENT_DATE - MIN(f.due_date)) >= $5::int)
      ORDER BY days_overdue DESC, total_overdue_amount DESC;
    `;

    const { rows } = await pool.query(query, [
      user.schoolId,
      filters?.classId || null,
      filters?.sectionId || null,
      filters?.search ? filters.search.trim() : null,
      filters?.minDaysOverdue || null,
    ]);
    return rows;
  }

  /**
   * Get Day-Book Daily Collection summary
   */
  static async getDayBook(user: TokenPayload, dateParam?: string): Promise<any> {
    const targetDate = dateParam ? dateParam.trim() : new Date().toISOString().slice(0, 10);

    const statsQuery = `
      SELECT 
        COALESCE(SUM(amount_paid), 0)::float AS total_collected,
        COUNT(id)::int AS receipt_count,
        COALESCE(SUM(CASE WHEN payment_mode = 'CASH' THEN amount_paid ELSE 0 END), 0)::float AS cash_total,
        COALESCE(SUM(CASE WHEN payment_mode IN ('ONLINE', 'UPI') THEN amount_paid ELSE 0 END), 0)::float AS online_upi_total,
        COALESCE(SUM(CASE WHEN payment_mode IN ('CHEQUE', 'CHEQUES', 'DEMAND_DRAFT') THEN amount_paid ELSE 0 END), 0)::float AS cheque_total,
        COALESCE(SUM(CASE WHEN payment_mode = 'BANK_TRANSFER' THEN amount_paid ELSE 0 END), 0)::float AS bank_transfer_total
      FROM fee_receipts
      WHERE school_id = $1 AND payment_date = $2::date;
    `;
    const statsRes = await pool.query(statsQuery, [user.schoolId, targetDate]);

    // Receipts of that day
    const receipts = await this.getAdminReceipts(user, { date: targetDate });

    return {
      date: targetDate,
      summary: statsRes.rows[0],
      receipts,
    };
  }

  // ==========================================================================
  // STANDARD SCHOOL ERP: 20 FEE HEAD SLOTS & TRANSPORT DEFINITION
  // ==========================================================================

  /**
   * Get 20 Fee Head Slots & Transport Head Definition
   */
  static async getFeeHeadSlots(user: TokenPayload): Promise<{
    slots: Array<{ slot_number: number; head_name: string; is_active: boolean }>;
    transport: { head_name: string; collection_method: string };
  }> {
    const slotsRes = await pool.query(
      `SELECT slot_number, head_name, is_active
       FROM fee_head_slots
       WHERE school_id = $1
       ORDER BY slot_number ASC;`,
      [user.schoolId]
    );

    const transportRes = await pool.query(
      `SELECT head_name, collection_method
       FROM transport_head_settings
       WHERE school_id = $1 LIMIT 1;`,
      [user.schoolId]
    );

    const transport = transportRes.rows[0] || {
      head_name: 'TRANSPORT FEE',
      collection_method: 'MONTHLY',
    };

    const slotsMap = new Map();
    for (const r of slotsRes.rows) slotsMap.set(r.slot_number, r);

    const finalSlots = [];
    for (let i = 1; i <= 20; i++) {
      if (slotsMap.has(i)) {
        finalSlots.push(slotsMap.get(i));
      } else {
        finalSlots.push({ slot_number: i, head_name: '', is_active: true });
      }
    }

    return {
      slots: finalSlots,
      transport,
    };
  }

  /**
   * Save 20 Fee Head Slots & Transport Head Definition
   */
  static async saveFeeHeadSlots(
    user: TokenPayload,
    data: {
      slots: Array<{ slot_number: number; head_name: string; is_active?: boolean }>;
      transport?: { head_name?: string; collection_method?: string };
    }
  ): Promise<any> {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      if (Array.isArray(data.slots)) {
        for (const s of data.slots) {
          if (s.slot_number >= 1 && s.slot_number <= 20) {
            await client.query(
              `INSERT INTO fee_head_slots (school_id, slot_number, head_name, is_active, updated_at)
               VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
               ON CONFLICT (school_id, slot_number)
               DO UPDATE SET head_name = EXCLUDED.head_name, 
                             is_active = EXCLUDED.is_active,
                             updated_at = CURRENT_TIMESTAMP;`,
              [user.schoolId, s.slot_number, (s.head_name || '').trim().toUpperCase(), s.is_active ?? true]
            );
          }
        }
      }

      if (data.transport) {
        await client.query(
          `INSERT INTO transport_head_settings (school_id, head_name, collection_method, updated_at)
           VALUES ($1, $2, $3, CURRENT_TIMESTAMP)
           ON CONFLICT (school_id)
           DO UPDATE SET head_name = EXCLUDED.head_name,
                         collection_method = EXCLUDED.collection_method,
                         updated_at = CURRENT_TIMESTAMP;`,
          [
            user.schoolId,
            (data.transport.head_name || 'TRANSPORT FEE').trim().toUpperCase(),
            data.transport.collection_method || 'MONTHLY',
          ]
        );
      }

      await client.query('COMMIT');
      return { success: true };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  static async collectExtraFee(user: any, data: {
    student_id: string;
    fee_category: string;
    amount: number;
    payment_mode: string;
    remarks?: string;
    idempotency_key?: string;
  }) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const schoolId = user.schoolId;

      // Idempotency check for extra fee collection
      if (data.idempotency_key) {
        const existing = await client.query(
          `SELECT r.id AS receipt_id, r.receipt_number, r.amount_paid,
                  sp.first_name, sp.last_name, sp.admission_number, c.name AS class_name, sec.name AS section_name
           FROM fee_receipts r
           JOIN student_profiles sp ON r.student_id = sp.id
           LEFT JOIN classes c ON sp.current_class_id = c.id
           LEFT JOIN sections sec ON sp.current_section_id = sec.id
           WHERE r.idempotency_key = $1 AND r.school_id = $2;`,
          [data.idempotency_key, schoolId]
        );
        if (existing.rows.length > 0) {
          await client.query('COMMIT');
          const ext = existing.rows[0];
          return {
            receipt_id: ext.receipt_id,
            receipt_number: ext.receipt_number,
            amount_paid: ext.amount_paid,
            student_name: `${ext.first_name} ${ext.last_name || ''}`.trim(),
            admission_number: ext.admission_number,
            class_name: ext.class_name,
            section_name: ext.section_name,
            category: data.fee_category,
          };
        }
      }

      const receiptNumber = await FeeService.generateReceiptNumber(client, schoolId, 'EXT');

      const stRes = await client.query(
        `SELECT sp.id, sp.first_name, sp.last_name, sp.admission_number, c.name AS class_name, sec.name AS section_name
         FROM student_profiles sp
         JOIN classes c ON sp.current_class_id = c.id
         JOIN sections sec ON sp.current_section_id = sec.id
         WHERE sp.id = $1 AND sp.school_id = $2`,
        [data.student_id, schoolId]
      );
      if (stRes.rows.length === 0) {
        throw new Error('Student not found in this school');
      }
      const st = stRes.rows[0];

      let recRes;
      try {
        recRes = await client.query(
          `INSERT INTO fee_receipts (
             school_id, student_id, receipt_number, amount_paid, payment_mode, 
             payment_date, collected_by, is_cancelled, waterfall_breakdown, idempotency_key
           ) VALUES ($1, $2, $3, $4, $5, CURRENT_DATE, $6, FALSE, $7, $8)
           RETURNING id, receipt_number, amount_paid, payment_mode, payment_date;`,
          [
            schoolId,
            data.student_id,
            receiptNumber,
            data.amount,
            data.payment_mode || 'CASH',
            user.userId,
            JSON.stringify([{ head: data.fee_category, amount: data.amount, remarks: data.remarks || '' }]),
            data.idempotency_key || null,
          ]
        );
      } catch (insertErr: any) {
        if (insertErr.code === '23505' && insertErr.constraint?.includes('receipt_number')) {
          const retryReceiptNumber = await FeeService.generateReceiptNumber(client, schoolId, 'EXT');
          recRes = await client.query(
            `INSERT INTO fee_receipts (
               school_id, student_id, receipt_number, amount_paid, payment_mode, 
               payment_date, collected_by, is_cancelled, waterfall_breakdown, idempotency_key
             ) VALUES ($1, $2, $3, $4, $5, CURRENT_DATE, $6, FALSE, $7, $8)
             RETURNING id, receipt_number, amount_paid, payment_mode, payment_date;`,
            [
              schoolId,
              data.student_id,
              retryReceiptNumber,
              data.amount,
              data.payment_mode || 'CASH',
              user.userId,
              JSON.stringify([{ head: data.fee_category, amount: data.amount, remarks: data.remarks || '' }]),
              data.idempotency_key || null,
            ]
          );
        } else {
          throw insertErr;
        }
      }

      const receipt = recRes.rows[0];

      await client.query(
        `INSERT INTO fee_receipt_items (receipt_id, fee_head_name, allocated_amount, notes)
         VALUES ($1, $2, $3, $4);`,
        [receipt.id, data.fee_category, data.amount, data.remarks || 'Direct Counter Extra Fee']
      );

      if ((data.payment_mode || 'CASH').toUpperCase() === 'CASH') {
        await client.query(
          `UPDATE fee_counter_shifts
           SET system_cash_total = system_cash_total + $1
           WHERE school_id = $2 AND cashier_id = $3 AND is_closed = FALSE`,
          [data.amount, schoolId, user.userId]
        );
      }

      await client.query('COMMIT');
      return {
        receipt_id: receipt.id,
        receipt_number: receipt.receipt_number,
        amount_paid: receipt.amount_paid,
        student_name: `${st.first_name} ${st.last_name || ''}`.trim(),
        admission_number: st.admission_number,
        class_name: st.class_name,
        section_name: st.section_name,
        category: data.fee_category,
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  static async applyAnnualFeeCalculation(user: any, data: {
    class_id: string;
    matrix: Record<string, number>;
  }) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const schoolId = user.schoolId;

      const ayRes = await client.query(
        'SELECT id FROM academic_years WHERE school_id = $1 AND is_current = TRUE LIMIT 1',
        [schoolId]
      );
      const ayId = ayRes.rows[0]?.id || null;

      const stRes = await client.query(
        'SELECT id FROM student_profiles WHERE school_id = $1 AND current_class_id = $2',
        [schoolId, data.class_id]
      );
      const students = stRes.rows;

      if (students.length === 0) {
        throw new Error('No students found enrolled in this class');
      }

      let insertedCount = 0;
      for (const [headName, annualAmount] of Object.entries(data.matrix)) {
        const amt = Number(annualAmount);
        if (amt > 0) {
          for (const student of students) {
            await client.query(
              `INSERT INTO student_fees (
                 school_id, student_id, academic_year_id, fee_title,
                 amount, amount_paid, due_date, status, created_at
               ) VALUES ($1, $2, $3, $4, $5, 0, CURRENT_DATE + INTERVAL '30 days', 'PENDING', CURRENT_TIMESTAMP);`,
              [schoolId, student.id, ayId, headName.trim().toUpperCase(), amt]
            );
            insertedCount++;
          }
        }
      }

      await client.query('COMMIT');
      return {
        success: true,
        studentsCount: students.length,
        feeRecordsCreated: insertedCount,
      };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
}
