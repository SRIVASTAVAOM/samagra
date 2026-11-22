-- Migration 019: Add profile photo URL to student and staff profiles
ALTER TABLE student_profiles
  ADD COLUMN IF NOT EXISTS photo_url TEXT NULL;

ALTER TABLE staff_profiles
  ADD COLUMN IF NOT EXISTS photo_url TEXT NULL;
