import request from 'supertest';
import app from '../src/app';
import { pool } from '../src/config/db.config';

describe('Student Dashboard Features API Tests', () => {
  let studentToken: string;
  let teacherToken: string;

  beforeAll(async () => {
    const sRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'student1', password: 'Password@123' });
    studentToken = sRes.body.data.token;

    const tRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'teacher1', password: 'Password@123' });
    teacherToken = tRes.body.data.token;
  });

  afterAll(async () => {
    await pool.end();
  });

  describe('1. Class Teacher & Subject Teachers', () => {
    it('GET /api/v1/academics/subject-teachers returns Class Teacher and subject teachers', async () => {
      const res = await request(app)
        .get('/api/v1/academics/subject-teachers')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(2);

      // Verify Class Teacher is present
      const classTeacher = res.body.data.find((t: any) => t.is_class_teacher === true);
      expect(classTeacher).toBeDefined();
      expect(classTeacher.subject_name).toContain('Class Teacher');
      expect(classTeacher.teacher_name).toBeDefined();
    });
  });

  describe('2. Classmates Birthdays (Today-Only), Idempotent Notices & Class Teacher View', () => {
    let student2Id: string;
    let originalStudent2Dob: string | null = null;
    let student2Token: string;

    beforeAll(async () => {
      const s2Login = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'student2', password: 'Password@123' });
      student2Token = s2Login.body.data.token;

      const s2Row = await pool.query(
        `SELECT sp.id, TO_CHAR(sp.date_of_birth, 'YYYY-MM-DD') AS dob
         FROM student_profiles sp
         JOIN users u ON sp.user_id = u.id
         WHERE u.identifier = 'student2'
         LIMIT 1;`
      );
      student2Id = s2Row.rows[0].id;
      originalStudent2Dob = s2Row.rows[0].dob;

      await pool.query(
        `UPDATE student_profiles
         SET date_of_birth = ((CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date - INTERVAL '15 years')::date
         WHERE id = $1;`,
        [student2Id]
      );
    });

    afterAll(async () => {
      await pool.query(
        `DELETE FROM notices
         WHERE (title LIKE 'Classmate Birthday:%' OR title LIKE 'Student Birthday:%')
           AND (published_at AT TIME ZONE 'Asia/Kolkata')::date = (CURRENT_TIMESTAMP AT TIME ZONE 'Asia/Kolkata')::date;`
      );
      if (student2Id) {
        await pool.query(
          `UPDATE student_profiles SET date_of_birth = $1 WHERE id = $2;`,
          [originalStudent2Dob, student2Id]
        );
      }
    });

    it('GET /api/v1/academics/classmates-birthdays returns today-only birthdays and idempotent classmate notice without self-spam', async () => {
      const res1 = await request(app)
        .get('/api/v1/academics/classmates-birthdays')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res1.status).toBe(200);
      expect(res1.body.success).toBe(true);
      expect(Array.isArray(res1.body.data)).toBe(true);
      expect(res1.body.data.length).toBeGreaterThanOrEqual(1);

      const celebrant = res1.body.data.find((b: any) => b.id === student2Id) || res1.body.data[0];
      expect(celebrant.first_name).toBeDefined();
      expect(celebrant.full_name).toBeDefined();
      expect(celebrant).toHaveProperty('roll_number');
      expect(celebrant).toHaveProperty('avatar_url');
      expect(celebrant.birth_month).toBeDefined();
      expect(celebrant.birth_day).toBeDefined();
      expect(celebrant.birthday_formatted).toBeDefined();
      expect(celebrant.is_today).toBe(true);
      // Verify year & admission clutter are NOT exposed to classmates
      expect(celebrant.date_of_birth).toBeUndefined();
      expect(celebrant.admission_number).toBeUndefined();

      // Call again to verify daily idempotency
      const res2 = await request(app)
        .get('/api/v1/academics/classmates-birthdays')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(res2.status).toBe(200);

      // Student1 receives exactly one classmate birthday notice for Student2 today
      const noticesRes = await request(app)
        .get('/api/v1/notices/student')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(noticesRes.status).toBe(200);
      const bdayNotices = noticesRes.body.data.filter((n: any) =>
        typeof n.title === 'string' && n.title.startsWith(`Classmate Birthday: ${celebrant.full_name}`)
      );
      expect(bdayNotices.length).toBe(1);

      // Student2 (celebrant) does NOT receive a classmate reminder about themselves
      const selfNoticesRes = await request(app)
        .get('/api/v1/notices/student')
        .set('Authorization', `Bearer ${student2Token}`);
      expect(selfNoticesRes.status).toBe(200);
      const selfBdayNotices = selfNoticesRes.body.data.filter((n: any) =>
        typeof n.title === 'string' && n.title.startsWith(`Classmate Birthday: ${celebrant.full_name}`)
      );
      expect(selfBdayNotices.length).toBe(0);
    });

    it('GET /api/v1/academics/classmates-birthdays and GET /api/v1/notices/teacher surface homeroom birthdays for Class Teacher', async () => {
      const bdayRes = await request(app)
        .get('/api/v1/academics/classmates-birthdays')
        .set('Authorization', `Bearer ${teacherToken}`);

      expect(bdayRes.status).toBe(200);
      expect(bdayRes.body.success).toBe(true);
      expect(bdayRes.body.data.some((b: any) => b.id === student2Id)).toBe(true);

      const teacherNoticesRes = await request(app)
        .get('/api/v1/notices/teacher')
        .set('Authorization', `Bearer ${teacherToken}`);

      expect(teacherNoticesRes.status).toBe(200);
      expect(teacherNoticesRes.body.success).toBe(true);
      expect(
        teacherNoticesRes.body.data.some(
          (n: any) => typeof n.title === 'string' && n.title.startsWith('Student Birthday:')
        )
      ).toBe(true);

      const forbiddenStudentTeacherNotices = await request(app)
        .get('/api/v1/notices/teacher')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(forbiddenStudentTeacherNotices.status).toBe(403);
    });
  });

  describe('3. Notices for Student', () => {
    it('GET /api/v1/notices/student returns applicable notices', async () => {
      const res = await request(app)
        .get('/api/v1/notices/student')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);

      const notice = res.body.data[0];
      expect(notice.title).toBeDefined();
      expect(notice.content).toBeDefined();
      expect(notice.priority).toBeDefined();
    });

    it('REJECTS unauthenticated access to /notices/student with 401', async () => {
      const res = await request(app).get('/api/v1/notices/student');
      expect(res.status).toBe(401);
    });

    it('POST /api/v1/notices/student/:id/dismiss hides notice persistently and restore brings it back', async () => {
      const initialRes = await request(app)
        .get('/api/v1/notices/student')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(initialRes.status).toBe(200);
      const firstNoticeId = initialRes.body.data[0].id as string;

      const dismissRes = await request(app)
        .post(`/api/v1/notices/student/${firstNoticeId}/dismiss`)
        .set('Authorization', `Bearer ${studentToken}`);
      expect(dismissRes.status).toBe(200);
      expect(dismissRes.body.success).toBe(true);

      const afterDismissRes = await request(app)
        .get('/api/v1/notices/student')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(afterDismissRes.status).toBe(200);
      expect(afterDismissRes.body.data.some((n: any) => n.id === firstNoticeId)).toBe(false);

      const restoreRes = await request(app)
        .post('/api/v1/notices/student/restore')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ noticeIds: [firstNoticeId] });
      expect(restoreRes.status).toBe(200);

      const afterRestoreRes = await request(app)
        .get('/api/v1/notices/student')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(afterRestoreRes.body.data.some((n: any) => n.id === firstNoticeId)).toBe(true);
    });
  });

  describe('4. Student Fees & Receipts', () => {
    it('GET /api/v1/fees/my-fees returns fee items and dues summary', async () => {
      const res = await request(app)
        .get('/api/v1/fees/my-fees')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data.fees)).toBe(true);
      expect(res.body.data.fees.length).toBeGreaterThanOrEqual(1);

      const summary = res.body.data.summary;
      expect(summary.total_dues).toBeGreaterThan(0);
      expect(summary.total_paid).toBeGreaterThanOrEqual(0);
      expect(summary.total_outstanding).toBeDefined();
    });

    it('GET /api/v1/fees/my-receipts returns recorded payment receipts', async () => {
      const res = await request(app)
        .get('/api/v1/fees/my-receipts')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);

      const receipt = res.body.data[0];
      expect(receipt.receipt_number).toBeDefined();
      expect(receipt.amount_paid).toBeGreaterThan(0);
      expect(receipt.payment_mode).toBeDefined();
    });

    it('REJECTS teacher accessing student fee endpoints with 403', async () => {
      const res = await request(app)
        .get('/api/v1/fees/my-fees')
        .set('Authorization', `Bearer ${teacherToken}`);
      expect(res.status).toBe(403);
    });
  });

  describe('5. Complaints & Feedback', () => {
    it('POST /api/v1/support/complaints submits a new complaint', async () => {
      const res = await request(app)
        .post('/api/v1/support/complaints')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          title: 'Physics Lab Apparatus issue',
          category: 'FACILITY',
          description: 'The ammeter in Table 3 was giving unstable readings during experiment.',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.title).toBe('Physics Lab Apparatus issue');
      expect(res.body.data.status).toBe('PENDING');
    });

    it('POST /api/v1/support/complaints rejects title > 255 characters with 400', async () => {
      const res = await request(app)
        .post('/api/v1/support/complaints')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          title: 'A'.repeat(256),
          category: 'FACILITY',
          description: 'Testing max title length validation.',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('GET /api/v1/support/complaints returns student complaints history', async () => {
      const res = await request(app)
        .get('/api/v1/support/complaints')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });

    it('Admin updates complaint status with validation (400/404) and creates student in-app notice', async () => {
      const adminLogin = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'management1', password: 'Password@123' });
      const adminToken = adminLogin.body.data.token;

      // Invalid UUID -> 400
      const badIdRes = await request(app)
        .patch('/api/v1/admin/complaints/not-a-uuid')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: 'RESOLVED' });
      expect(badIdRes.status).toBe(400);

      // Invalid status enum -> 400
      const badStatusRes = await request(app)
        .patch('/api/v1/admin/complaints/00000000-0000-0000-0000-000000000000')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: 'CLOSED' });
      expect(badStatusRes.status).toBe(400);

      // Non-existent complaint UUID -> 404
      const missingRes = await request(app)
        .patch('/api/v1/admin/complaints/00000000-0000-0000-0000-000000000000')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: 'RESOLVED', resolution_notes: 'Handled' });
      expect(missingRes.status).toBe(404);

      // Submit & resolve real complaint
      const createRes = await request(app)
        .post('/api/v1/support/complaints')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          title: 'Water Cooler Filter Notice Check',
          category: 'FACILITY',
          description: 'Filter needs servicing on 2nd floor.',
        });
      expect(createRes.status).toBe(201);
      const complaintId = createRes.body.data.id;

      const resolveRes = await request(app)
        .patch(`/api/v1/admin/complaints/${complaintId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          status: 'RESOLVED',
          resolution_notes: 'Filter cartridge replaced today.',
        });
      expect(resolveRes.status).toBe(200);
      expect(resolveRes.body.success).toBe(true);
      expect(resolveRes.body.data.status).toBe('RESOLVED');
      expect(resolveRes.body.data.resolution_notes).toBe('Filter cartridge replaced today.');

      // Verify student notice was created
      const noticesRes = await request(app)
        .get('/api/v1/notices/student')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(noticesRes.status).toBe(200);
      const matchingNotice = noticesRes.body.data.find(
        (n: any) =>
          typeof n.title === 'string' &&
          n.title.includes('Water Cooler Filter Notice Check')
      );
      expect(matchingNotice).toBeDefined();
    });

    it('POST /api/v1/support/feedback submits student feedback', async () => {
      const res = await request(app)
        .post('/api/v1/support/feedback')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          category: 'CURRICULUM',
          rating: 5,
          feedback_text: 'The syllabus progression is well-structured.',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.rating).toBe(5);
    });

    it('POST /api/v1/support/feedback rejects non-integer rating with 400 and delivers valid feedback to Admin', async () => {
      const badRes = await request(app)
        .post('/api/v1/support/feedback')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          category: 'CURRICULUM',
          rating: 4.5,
          feedback_text: 'Decimal rating should fail validation.',
        });
      expect(badRes.status).toBe(400);
      expect(badRes.body.success).toBe(false);

      const adminLogin = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'management1', password: 'Password@123' });
      const adminToken = adminLogin.body.data.token;

      const adminRes = await request(app)
        .get('/api/v1/admin/feedback')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(adminRes.status).toBe(200);
      expect(adminRes.body.success).toBe(true);
      expect(Array.isArray(adminRes.body.data.feedback)).toBe(true);
      const found = adminRes.body.data.feedback.find(
        (f: any) => f.feedback_text === 'The syllabus progression is well-structured.'
      );
      expect(found).toBeDefined();
    });

    it('GET /api/v1/support/feedback returns student feedback history', async () => {
      const res = await request(app)
        .get('/api/v1/support/feedback')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    });
  });
});
