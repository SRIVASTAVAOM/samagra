import request from 'supertest';
import app from '../src/app';
import { pool } from '../src/config/db.config';

describe('Homework Management API Tests', () => {
  let teacherToken: string;
  let studentToken: string;
  let student2Token: string;
  let coordinatorToken: string;
  let classId: string;
  let sectionId: string;
  let mathSubjectId: string;
  let createdHomeworkId: string;

  beforeAll(async () => {
    // 1. Login Teacher1
    const tLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'teacher1', password: 'Password@123' });
    teacherToken = tLogin.body.data.token;

    // 2. Login Student1
    const sLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'student1', password: 'Password@123' });
    studentToken = sLogin.body.data.token;

    // 3. Login Coordinator1
    const cLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'coordinator1', password: 'Password@123' });
    coordinatorToken = cLogin.body.data.token;

    // 4. Fetch Class, Section, and Math Subject IDs
    const classRes = await pool.query(`SELECT id FROM classes WHERE name = 'Grade 10' LIMIT 1;`);
    classId = classRes.rows[0].id;

    const secRes = await pool.query(`SELECT id FROM sections WHERE class_id = $1 LIMIT 1;`, [classId]);
    sectionId = secRes.rows[0].id;

    const subRes = await pool.query(`SELECT id FROM subjects WHERE code = 'MATH10' LIMIT 1;`);
    mathSubjectId = subRes.rows[0].id;
  });

  afterAll(async () => {
    // Clean up test homework
    if (createdHomeworkId) {
      await pool.query(`DELETE FROM homework_assignments WHERE id = $1;`, [createdHomeworkId]);
    }
    await pool.end();
  });

  describe('POST /api/v1/homework (Create Homework)', () => {
    it('should allow allocated teacher to create homework assignment', async () => {
      const res = await request(app)
        .post('/api/v1/homework')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          classId,
          sectionId,
          subjectId: mathSubjectId,
          title: 'Polynomial Division Worksheet',
          description: 'Complete questions 1 to 5 from page 48.',
          assignedDate: '2026-10-25',
          dueDate: '2026-10-30',
          attachmentName: 'polynomial_worksheet.pdf',
          s3AttachmentKey: 'schools/APEX01/homework/poly_ws.pdf',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.title).toBe('Polynomial Division Worksheet');
      expect(res.body.data.s3_attachment_key).toBe('schools/APEX01/homework/poly_ws.pdf');
      createdHomeworkId = res.body.data.id;
    });

    it('should reject homework when dueDate is earlier than assigned date', async () => {
      const res = await request(app)
        .post('/api/v1/homework')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          classId,
          sectionId,
          subjectId: mathSubjectId,
          title: 'Invalid Date Homework',
          description: 'This has an impossible due date.',
          assignedDate: '2026-10-25',
          dueDate: '2026-10-20',
        });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
      expect(res.body.error).toMatch(/due date cannot be earlier/i);
    });

    it('should REJECT student trying to create homework with 403 Forbidden', async () => {
      const res = await request(app)
        .post('/api/v1/homework')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          classId,
          sectionId,
          subjectId: mathSubjectId,
          title: 'Student Attempted Homework',
          description: 'Should not succeed.',
          dueDate: '2026-10-30',
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });
  });

  describe('GET /api/v1/homework/student/my-class', () => {
    it('should allow student to fetch homework for their enrolled class & section', async () => {
      const res = await request(app)
        .get('/api/v1/homework/student/my-class')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
      const item = res.body.data[0];
      expect(item).toHaveProperty('title');
      expect(item).toHaveProperty('student_status');
    });

    it('should reject non-student calling student/my-class with 403', async () => {
      const res = await request(app)
        .get('/api/v1/homework/student/my-class')
        .set('Authorization', `Bearer ${teacherToken}`);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });
  });

  describe('POST /api/v1/homework/:id/completion (Student Completion Toggle)', () => {
    it('should allow student to mark their homework as COMPLETED', async () => {
      const res = await request(app)
        .post(`/api/v1/homework/${createdHomeworkId}/completion`)
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ status: 'COMPLETED' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('COMPLETED');
    });

    it('should allow student to toggle homework back to PENDING', async () => {
      const res = await request(app)
        .post(`/api/v1/homework/${createdHomeworkId}/completion`)
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ status: 'PENDING' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('PENDING');
    });

    it('should REJECT teacher trying to update student completion with 403 Forbidden', async () => {
      const res = await request(app)
        .post(`/api/v1/homework/${createdHomeworkId}/completion`)
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({ status: 'COMPLETED' });

      expect(res.status).toBe(403);
    });
  });

  describe('GET /api/v1/homework/teacher/my-assigned', () => {
    it('should allow teacher to view list of their assigned homework with completion counts', async () => {
      const res = await request(app)
        .get('/api/v1/homework/teacher/my-assigned')
        .set('Authorization', `Bearer ${teacherToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBeGreaterThan(0);
      expect(res.body.data[0]).toHaveProperty('completed_count');
    });
  });

  describe('GET /api/v1/homework/:id/attachment-download', () => {
    it('should return short-lived download URL for homework with attachment', async () => {
      const res = await request(app)
        .get(`/api/v1/homework/${createdHomeworkId}/attachment-download`)
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('downloadUrl');
      expect(res.body.data).toHaveProperty('attachmentName');
    });
  });

  describe('POST /api/v1/homework/attachment-upload', () => {
    it('should reject file upload when unauthenticated', async () => {
      const res = await request(app)
        .post('/api/v1/homework/attachment-upload')
        .send(Buffer.from('%PDF-1.4 test content'));

      expect(res.status).toBe(401);
    });

    it('should reject file upload from students with 403', async () => {
      const res = await request(app)
        .post('/api/v1/homework/attachment-upload?fileName=assignment.pdf')
        .set('Authorization', `Bearer ${studentToken}`)
        .set('Content-Type', 'application/pdf')
        .send(Buffer.from('%PDF-1.4 test content'));

      expect(res.status).toBe(403);
    });

    it('should reject empty file data with 400', async () => {
      const res = await request(app)
        .post('/api/v1/homework/attachment-upload?fileName=empty.pdf')
        .set('Authorization', `Bearer ${teacherToken}`)
        .set('Content-Type', 'application/pdf')
        .send(Buffer.alloc(0));

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });

    it('should reject invalid file format with 400', async () => {
      const res = await request(app)
        .post('/api/v1/homework/attachment-upload?fileName=malicious.exe')
        .set('Authorization', `Bearer ${teacherToken}`)
        .set('Content-Type', 'application/octet-stream')
        .send(Buffer.from('Not allowed content'));

      expect(res.status).toBe(400);
      expect(res.body.error).toContain('Invalid file format');
    });

    it('should reject files exceeding strict 5 MB limit with 400', async () => {
      const oversizedBuffer = Buffer.alloc(5 * 1024 * 1024 + 1024, 0x41); // > 5 MB
      const res = await request(app)
        .post('/api/v1/homework/attachment-upload?fileName=large.pdf')
        .set('Authorization', `Bearer ${teacherToken}`)
        .set('Content-Type', 'application/pdf')
        .send(oversizedBuffer);

      expect(res.status).toBe(400);
      expect(res.body.error).toContain('5 MB');
    });

    it('should accept and upload a valid image under 5 MB', async () => {
      const validPngBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';
      const validPngBuffer = Buffer.from(validPngBase64, 'base64');

      const res = await request(app)
        .post('/api/v1/homework/attachment-upload?fileName=assignment_diagram.png')
        .set('Authorization', `Bearer ${teacherToken}`)
        .set('Content-Type', 'image/png')
        .send(validPngBuffer);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveProperty('attachmentUrl');
      expect(res.body.data.attachmentName).toBe('assignment_diagram.png');
    }, 15000);
  });
});
