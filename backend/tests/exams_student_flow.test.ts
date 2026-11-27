import request from 'supertest';
import app from '../src/app';
import { pool } from '../src/config/db.config';

describe('Student Exam, Datesheet, Marks Lock & Admin Approval Flow', () => {
  let adminToken: string;
  let teacherToken: string;
  let studentToken: string;

  let schoolId: string;
  let academicYearId: string;
  let seniorWingId: string;
  let classId: string;
  let sectionId: string;
  let mathSubjectId: string;
  let student1ProfileId: string;

  let publishedExamId: string;
  let unpublishedExamId: string;
  let datesheetId: string;

  beforeAll(async () => {
    const aLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'management1', password: 'Password@123' });
    adminToken = aLogin.body.data.token;

    const tLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'teacher1', password: 'Password@123' });
    teacherToken = tLogin.body.data.token;

    const sLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'student1', password: 'Password@123' });
    studentToken = sLogin.body.data.token;

    const sch = await pool.query(`SELECT id FROM schools LIMIT 1;`);
    schoolId = sch.rows[0].id;

    const ay = await pool.query(`SELECT id FROM academic_years WHERE school_id = $1 LIMIT 1;`, [schoolId]);
    academicYearId = ay.rows[0].id;

    const w = await pool.query(`SELECT id FROM wings WHERE name = 'Senior Wing' LIMIT 1;`);
    seniorWingId = w.rows[0].id;

    const cls = await pool.query(`SELECT id FROM classes WHERE name = 'Grade 10' AND school_id = $1 LIMIT 1;`, [schoolId]);
    classId = cls.rows[0].id;

    const sec = await pool.query(`SELECT id FROM sections WHERE class_id = $1 LIMIT 1;`, [classId]);
    sectionId = sec.rows[0].id;

    const subMath = await pool.query(`SELECT id FROM subjects WHERE code = 'MATH10' AND school_id = $1 LIMIT 1;`, [schoolId]);
    mathSubjectId = subMath.rows[0].id;

    const std1 = await pool.query(
      `SELECT sp.id FROM student_profiles sp JOIN users u ON sp.user_id = u.id WHERE u.identifier = 'student1';`
    );
    student1ProfileId = std1.rows[0].id;
  });

  afterAll(async () => {
    if (publishedExamId) {
      await pool.query(`DELETE FROM exams WHERE id = $1;`, [publishedExamId]);
    }
    if (unpublishedExamId) {
      await pool.query(`DELETE FROM exams WHERE id = $1;`, [unpublishedExamId]);
    }
    await pool.end();
  });

  it('allows Admin to create exams & schedule datesheets, blocks student datesheet when unpublished, allows once published', async () => {
    const unpubRes = await request(app)
      .post('/api/v1/exams')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        academicYearId,
        wingId: seniorWingId,
        name: 'Draft Quiz 2026',
        startDate: '2026-12-01',
        endDate: '2026-12-05',
      });
    expect(unpubRes.status).toBe(201);
    unpublishedExamId = unpubRes.body.data.id;

    const unpubDsForStudent = await request(app)
      .get(`/api/v1/exams/${unpublishedExamId}/datesheets`)
      .set('Authorization', `Bearer ${studentToken}`);
    expect(unpubDsForStudent.status).toBe(403);

    const examRes = await request(app)
      .post('/api/v1/exams')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        academicYearId,
        wingId: seniorWingId,
        name: 'Published Mid-Term 2026',
        startDate: '2026-12-10',
        endDate: '2026-12-20',
      });
    expect(examRes.status).toBe(201);
    publishedExamId = examRes.body.data.id;

    const dsRes = await request(app)
      .post(`/api/v1/exams/${publishedExamId}/datesheets`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({
        classId,
        sectionId,
        subjectId: mathSubjectId,
        examDate: '2026-12-12',
        startTime: '09:00:00',
        endTime: '11:00:00',
        maxMarks: 100,
        passingMarks: 33,
      });
    expect(dsRes.status).toBe(201);
    datesheetId = dsRes.body.data.id;

    // Publish exam so student can see datesheet
    const pubRes = await request(app)
      .patch(`/api/v1/exams/${publishedExamId}/publish`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ isPublished: true });
    expect(pubRes.status).toBe(200);

    const listRes = await request(app)
      .get('/api/v1/exams')
      .set('Authorization', `Bearer ${studentToken}`);
    expect(listRes.status).toBe(200);
    expect(listRes.body.data.some((e: any) => e.id === publishedExamId)).toBe(true);
    expect(listRes.body.data.some((e: any) => e.id === unpublishedExamId)).toBe(false);

    const dsStudentRes = await request(app)
      .get(`/api/v1/exams/${publishedExamId}/datesheets`)
      .set('Authorization', `Bearer ${studentToken}`);
    expect(dsStudentRes.status).toBe(200);
    expect(dsStudentRes.body.data.length).toBe(1);
    expect(dsStudentRes.body.data[0].subject_code).toBe('MATH10');
  });

  it('keeps marks entry unlocked when exam is published (before verification/approval) and supports Admin approval & student result view', async () => {
    const saveMarksRes = await request(app)
      .post(`/api/v1/exams/${publishedExamId}/datesheets/${datesheetId}/marks`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({
        submitForVerification: true,
        entries: [
          {
            student_id: student1ProfileId,
            marks_obtained: 88,
            is_absent: false,
            remarks: 'Consistent work',
          },
        ],
      });
    expect(saveMarksRes.status).toBe(200);

    const genRes = await request(app)
      .post(`/api/v1/exams/${publishedExamId}/classes/${classId}/sections/${sectionId}/generate-report-cards`)
      .set('Authorization', `Bearer ${teacherToken}`)
      .send({ remarks: 'Great progress' });
    expect(genRes.status).toBe(200);

    // Before approval, student receives 403
    const preApproveRes = await request(app)
      .get(`/api/v1/exams/${publishedExamId}/results/me`)
      .set('Authorization', `Bearer ${studentToken}`);
    expect(preApproveRes.status).toBe(403);

    // Admin (without COORDINATOR assignment) can approve report cards directly
    const approveRes = await request(app)
      .patch(`/api/v1/exams/${publishedExamId}/classes/${classId}/sections/${sectionId}/approve-report-cards`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(approveRes.status).toBe(200);
    expect(approveRes.body.data.approvedCount).toBeGreaterThanOrEqual(1);

    const resultRes = await request(app)
      .get(`/api/v1/exams/${publishedExamId}/results/me`)
      .set('Authorization', `Bearer ${studentToken}`);
    expect(resultRes.status).toBe(200);
    expect(resultRes.body.data.reportCard.status).toBe('APPROVED');
    expect(resultRes.body.data.reportCard.total_marks_obtained).toBe(88);
    expect(resultRes.body.data.subjectMarks.length).toBe(1);

    // Also verify PUBLISHED status is readable by student
    await pool.query(
      `UPDATE report_cards SET status = 'PUBLISHED' WHERE exam_id = $1 AND student_id = $2;`,
      [publishedExamId, student1ProfileId]
    );
    const pubCardRes = await request(app)
      .get(`/api/v1/exams/${publishedExamId}/results/me`)
      .set('Authorization', `Bearer ${studentToken}`);
    expect(pubCardRes.status).toBe(200);
    expect(pubCardRes.body.data.reportCard.status).toBe('PUBLISHED');
  });
});
