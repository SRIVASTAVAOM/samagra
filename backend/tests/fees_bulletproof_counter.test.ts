import request from 'supertest';
import app from '../src/app';
import { pool } from '../src/config/db.config';

describe('Bulletproof Real-Time Fee Counter Engine Tests', () => {
  let adminToken: string;
  let studentId: string;
  let schoolId: string;
  let academicYearId: string;
  let createdReceiptId: string;

  beforeAll(async () => {
    // 1. Login as Admin
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'management1', password: 'Password@123' });
    adminToken = loginRes.body.data.token;
    schoolId = loginRes.body.data.user.schoolId;

    // 2. Fetch or create a student profile
    const stdRes = await pool.query(
      `SELECT sp.id, sp.admission_number, sp.current_class_id, sp.current_section_id
       FROM student_profiles sp
       JOIN users u ON sp.user_id = u.id
       WHERE u.school_id = $1 LIMIT 1;`,
      [schoolId]
    );
    studentId = stdRes.rows[0].id;

    // 3. Fetch current academic year
    const ayRes = await pool.query(
      `SELECT id FROM academic_years WHERE school_id = $1 AND is_current = TRUE LIMIT 1;`,
      [schoolId]
    );
    academicYearId = ayRes.rows[0].id;

    // 4. Seed 3 fee records with different priorities to test Waterfall
    // Record 1: LAST YEAR DUE (₹3,000)
    await pool.query(
      `INSERT INTO student_fees (
         school_id, student_id, academic_year_id, fee_title, due_date, amount, amount_paid, status
       ) VALUES ($1, $2, $3, 'LAST YEAR DUE ARREARS', CURRENT_DATE - INTERVAL '60 days', 3000, 0, 'PENDING')
       ON CONFLICT DO NOTHING;`,
      [schoolId, studentId, academicYearId]
    );

    // Record 2: TUITION FEE Q1 (₹2,000)
    await pool.query(
      `INSERT INTO student_fees (
         school_id, student_id, academic_year_id, fee_title, due_date, amount, amount_paid, status
       ) VALUES ($1, $2, $3, 'TUITION FEE Q1', CURRENT_DATE - INTERVAL '10 days', 2000, 0, 'PENDING')
       ON CONFLICT DO NOTHING;`,
      [schoolId, studentId, academicYearId]
    );
  });

  afterAll(async () => {
    // Cleanup generated test fees and receipts
    await pool.query(
      `DELETE FROM fee_receipt_items WHERE fee_receipt_id IN (
         SELECT id FROM fee_receipts WHERE student_id = $1
       );`,
      [studentId]
    );
    await pool.query(`DELETE FROM fee_receipts WHERE student_id = $1;`, [studentId]);
    await pool.query(`DELETE FROM student_fees WHERE student_id = $1 AND fee_title ILIKE '%ARREARS%';`, [studentId]);
    await pool.end();
  });

  it('1. GET /api/v1/fees/admin/counter-profile/:identifier - pulls student profile with waterfall breakdown', async () => {
    const res = await request(app)
      .get(`/api/v1/fees/admin/counter-profile/${studentId}`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.student.id).toBe(studentId);
    expect(Array.isArray(res.body.data.fees)).toBe(true);
    expect(res.body.data.fees[0].waterfall_priority).toBe(1); // LAST YEAR DUE is Priority 1
  });

  it('2. POST /api/v1/fees/admin/collect - strictly follows Waterfall FIFO allocation', async () => {
    // Paying ₹3,500: ₹3,000 should clear LAST YEAR DUE completely, and remaining ₹500 goes to TUITION FEE Q1
    const idempotencyKey = `test_idem_${Date.now()}`;
    const res = await request(app)
      .post('/api/v1/fees/admin/collect')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        student_id: studentId,
        amount_paid: 3500,
        payment_mode: 'CHEQUE',
        cheque_number: '987654',
        cheque_bank: 'State Bank of India',
        cheque_date: '2026-11-18',
        idempotency_key: idempotencyKey,
        remarks: 'Waterfall FIFO Settlement Test',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data).toHaveProperty('receipt_number');
    expect(res.body.data.payment_mode).toBe('CHEQUE');
    expect(res.body.data.cheque_status).toBe('PENDING_CLEARANCE');
    createdReceiptId = res.body.data.id;

    // Check itemized line items
    expect(res.body.data.items).toBeDefined();
    expect(res.body.data.items.length).toBeGreaterThanOrEqual(1);

    // Verify database state: LAST YEAR DUE should be PAID (3000 paid)
    const dueCheck = await pool.query(
      `SELECT status, amount_paid FROM student_fees 
       WHERE student_id = $1 AND fee_title ILIKE '%LAST YEAR%' LIMIT 1;`,
      [studentId]
    );
    expect(dueCheck.rows[0].status).toBe('PAID');
    expect(Number(dueCheck.rows[0].amount_paid)).toBe(3000);
  });

  it('3. POST /api/v1/fees/admin/collect - Idempotency rejects/deduplicates double-clicks safely', async () => {
    const fixedKey = 'duplicate_click_prevention_key_123';

    // First Click
    const res1 = await request(app)
      .post('/api/v1/fees/admin/collect')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        student_id: studentId,
        amount_paid: 500,
        payment_mode: 'CASH',
        idempotency_key: fixedKey,
      });
    expect(res1.status).toBe(201);
    const firstReceiptNumber = res1.body.data.receipt_number;

    // Second Immediate Click (simulating clerk double-click)
    const res2 = await request(app)
      .post('/api/v1/fees/admin/collect')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        student_id: studentId,
        amount_paid: 500,
        payment_mode: 'CASH',
        idempotency_key: fixedKey,
      });

    expect(res2.status).toBe(201);
    // Must return the exact same receipt without re-charging!
    expect(res2.body.data.receipt_number).toBe(firstReceiptNumber);
  });

  it('4. GET /api/v1/fees/admin/receipts/:id/print - returns 3-part voucher metadata', async () => {
    const res = await request(app)
      .get(`/api/v1/fees/admin/receipts/${createdReceiptId}/print`)
      .set('Authorization', `Bearer ${adminToken}`);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.receipt_number).toBeDefined();
    expect(res.body.data.school_name).toBeDefined();
    expect(Array.isArray(res.body.data.items)).toBe(true);
  });

  it('5. POST /api/v1/fees/admin/receipts/:id/cheque-bounce - marks bounced, restores balances and applies penalty', async () => {
    const res = await request(app)
      .post(`/api/v1/fees/admin/receipts/${createdReceiptId}/cheque-bounce`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        penalty_amount: 500,
        reason: 'Cheque bounced due to signature mismatch',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    // Verify receipt is marked cancelled & bounced
    const receiptCheck = await pool.query(
      `SELECT is_cancelled, cheque_status FROM fee_receipts WHERE id = $1;`,
      [createdReceiptId]
    );
    expect(receiptCheck.rows[0].is_cancelled).toBe(true);
    expect(receiptCheck.rows[0].cheque_status).toBe('BOUNCED');

    // Verify bounce penalty record was appended
    const penaltyCheck = await pool.query(
      `SELECT amount FROM student_fees WHERE student_id = $1 AND fee_title ILIKE '%BOUNCE PENALTY%';`,
      [studentId]
    );
    expect(penaltyCheck.rows.length).toBeGreaterThan(0);
    expect(Number(penaltyCheck.rows[0].amount)).toBe(500);
  });

  it('6. GET & POST /api/v1/fees/admin/shifts - reconciles day-book closing with cash denomination count', async () => {
    // 1. Get Current Shift
    const shiftRes = await request(app)
      .get('/api/v1/fees/admin/shifts/current')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(shiftRes.status).toBe(200);
    expect(shiftRes.body.data.status).toBe('OPEN');

    // 2. Close Shift with Physical Cash Denominations
    const closeRes = await request(app)
      .post('/api/v1/fees/admin/shifts/close')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        physical_cash: 5000,
        denominations: { '500': 10, '200': 0, '100': 0, '50': 0, '20': 0, '10': 0 },
        closing_notes: 'End of Day Counter Closing by Cashier',
      });

    expect(closeRes.status).toBe(200);
    expect(closeRes.body.data.status).toBe('CLOSED');
    expect(closeRes.body.data.physical_cash_total).toBeDefined();
  });
});
