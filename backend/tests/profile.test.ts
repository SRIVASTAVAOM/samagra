import request from 'supertest';
import app from '../src/app';
import { pool } from '../src/config/db.config';

describe('Profile Viewing & Editing API Tests', () => {
  let studentToken: string;
  let teacherToken: string;
  let adminToken: string;

  beforeAll(async () => {
    const sRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'student1', password: 'Password@123' });
    studentToken = sRes.body.data.token;

    const tRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'teacher1', password: 'Password@123' });
    teacherToken = tRes.body.data.token;

    const aRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'management1', password: 'Password@123' });
    adminToken = aRes.body.data.token;
  });

  afterAll(async () => {
    await pool.end();
  });

  describe('Student Profile Endpoints', () => {
    it('GET /api/v1/profiles/student returns full student profile', async () => {
      const res = await request(app)
        .get('/api/v1/profiles/student')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.admission_number).toBe('ADM2026001');
      expect(res.body.data.class_name).toBe('Grade 10');
      expect(res.body.data.section_name).toBe('Section A');
      expect(res.body.data.school_name).toBe('Apex International School');
    });

    it('PATCH /api/v1/profiles/student successfully updates permitted editable fields', async () => {
      const res = await request(app)
        .patch('/api/v1/profiles/student')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          emergency_phone: '+91 9988776655',
          blood_group: 'B+',
          medical_notes: 'Mild dust allergy',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.emergency_phone).toBe('+91 9988776655');
      expect(res.body.data.blood_group).toBe('B+');
      expect(res.body.data.medical_notes).toBe('Mild dust allergy');
      expect(res.body.data.admission_number).toBe('ADM2026001');
      expect(res.body.data.school_name).toBe('Apex International School');
    });

    it('enforces one-time student photo upload and Admin re-upload approval flow', async () => {
      const profileRes = await request(app)
        .get('/api/v1/profiles/student')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(profileRes.status).toBe(200);
      const studentId = profileRes.body.data.id;

      // Ensure clean baseline for test via Admin
      await request(app)
        .patch(`/api/v1/admin/students/${studentId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ photo_self_edit_used: false, can_reupload_photo: false });

      // 1. First self-upload succeeds
      const firstUpload = await request(app)
        .patch('/api/v1/profiles/student')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ photo_url: 'https://cdn.example.com/student_first.jpg' });
      expect(firstUpload.status).toBe(200);
      expect(firstUpload.body.data.photo_url).toBe('https://cdn.example.com/student_first.jpg');
      expect(firstUpload.body.data.photo_self_edit_used).toBe(true);
      expect(firstUpload.body.data.can_upload_photo).toBe(false);

      // 2. Second self-upload is blocked with 403 until Admin re-approves
      const secondUpload = await request(app)
        .patch('/api/v1/profiles/student')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ photo_url: 'https://cdn.example.com/student_second.jpg' });
      expect(secondUpload.status).toBe(403);
      expect(secondUpload.body.success).toBe(false);

      // 3. Admin approves re-upload + updates emergency phone
      const adminGrant = await request(app)
        .patch(`/api/v1/admin/students/${studentId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ can_reupload_photo: true, emergency_phone: '+91 9811100000' });
      expect(adminGrant.status).toBe(200);
      expect(adminGrant.body.data.can_reupload_photo).toBe(true);
      expect(adminGrant.body.data.emergency_phone).toBe('+91 9811100000');

      // 4. Student can now upload once more and consumes the re-upload flag
      const thirdUpload = await request(app)
        .patch('/api/v1/profiles/student')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ photo_url: 'https://cdn.example.com/student_reapproved.jpg' });
      expect(thirdUpload.status).toBe(200);
      expect(thirdUpload.body.data.photo_url).toBe('https://cdn.example.com/student_reapproved.jpg');
      expect(thirdUpload.body.data.can_reupload_photo).toBe(false);
      expect(thirdUpload.body.data.can_upload_photo).toBe(false);
    });

    it('PATCH /api/v1/profiles/student rejects invalid phone format (<5 chars)', async () => {
      const res = await request(app)
        .patch('/api/v1/profiles/student')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ emergency_phone: '123' });

      expect(res.status).toBe(400);
      expect(res.body.success).toBe(false);
    });
  });

  describe('Staff Profile Endpoints', () => {
    it('GET /api/v1/profiles/staff returns staff profile with allocations', async () => {
      const res = await request(app)
        .get('/api/v1/profiles/staff')
        .set('Authorization', `Bearer ${teacherToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.employee_code).toBe('EMP-TEACHER1');
      expect(typeof res.body.data.qualification).toBe('string');
      expect(res.body.data.qualification).toBeTruthy();
    });

    it('PATCH /api/v1/profiles/staff updates qualification and emergency contact', async () => {
      const res = await request(app)
        .patch('/api/v1/profiles/staff')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          emergency_phone: '+91 9123456789',
          qualification: 'M.Sc., M.Ed., Ph.D.',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.qualification).toBe('M.Sc., M.Ed., Ph.D.');
    });
  });

  describe('Teacher Updating Student Profile (Class Teacher Only)', () => {
    let studentId: string;

    beforeAll(async () => {
      const sRes = await request(app)
        .get('/api/v1/profiles/student')
        .set('Authorization', `Bearer ${studentToken}`);
      studentId = sRes.body.data.id;
    });

    it('PATCH /api/v1/profiles/student/:studentId/by-teacher allows Class Teacher to update permitted fields', async () => {
      const res = await request(app)
        .patch(`/api/v1/profiles/student/${studentId}/by-teacher`)
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({
          roll_number: '12',
          blood_group: 'AB+',
          emergency_contact_phone: '+91 9876543210',
          medical_notes: 'Asthma inhaler in bag',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.roll_number).toBe('12');
      expect(res.body.data.blood_group).toBe('AB+');
      expect(res.body.data.emergency_phone).toBe('+91 9876543210');
      expect(res.body.data.medical_notes).toBe('Asthma inhaler in bag');
      // Immutable identity fields preserved
      expect(res.body.data.admission_number).toBe('ADM2026001');
    });

    it('PATCH /api/v1/profiles/student/:studentId/by-teacher rejects unauthorized role (STUDENT)', async () => {
      const res = await request(app)
        .patch(`/api/v1/profiles/student/${studentId}/by-teacher`)
        .set('Authorization', `Bearer ${studentToken}`)
        .send({ roll_number: '99' });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('PATCH /api/v1/profiles/student/:studentId/by-teacher rejects non-existent student with 404', async () => {
      const res = await request(app)
        .patch('/api/v1/profiles/student/00000000-0000-0000-0000-000000000000/by-teacher')
        .set('Authorization', `Bearer ${teacherToken}`)
        .send({ roll_number: '15' });

      expect(res.status).toBe(404);
      expect(res.body.success).toBe(false);
    });
  });

  describe('Tenant School Contact Sync', () => {
    it('PATCH /api/v1/admin/tenant-config validates input and syncs school contact to student profile', async () => {
      const badEmail = await request(app)
        .patch('/api/v1/admin/tenant-config')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ contactEmail: 'invalid-email' });
      expect(badEmail.status).toBe(400);

      const badPhone = await request(app)
        .patch('/api/v1/admin/tenant-config')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ contactPhone: '12' });
      expect(badPhone.status).toBe(400);

      const getRes = await request(app)
        .get('/api/v1/admin/tenant-config')
        .set('Authorization', `Bearer ${adminToken}`);
      expect(getRes.status).toBe(200);
      const originalPhone = getRes.body.data.contactPhone || '+91 9876543210';

      const updateRes = await request(app)
        .patch('/api/v1/admin/tenant-config')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          contactPhone: '+91 9911223344',
          branding: { officeHours: 'Mon-Fri 8:30 AM - 3:00 PM' },
        });
      expect(updateRes.status).toBe(200);

      const profileRes = await request(app)
        .get('/api/v1/profiles/student')
        .set('Authorization', `Bearer ${studentToken}`);
      expect(profileRes.status).toBe(200);
      expect(profileRes.body.data.school_phone).toBe('+91 9911223344');
      expect(profileRes.body.data.branding_config.officeHours).toBe(
        'Mon-Fri 8:30 AM - 3:00 PM'
      );

      // Restore original school phone
      await request(app)
        .patch('/api/v1/admin/tenant-config')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ contactPhone: originalPhone });
    });
  });
});

