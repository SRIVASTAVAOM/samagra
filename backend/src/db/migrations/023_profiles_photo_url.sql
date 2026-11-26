-- Migration 023: Profiles Photo URL Columns
-- Add photo_url to staff_profiles and student_profiles
ALTER TABLE staff_profiles ADD COLUMN IF NOT EXISTS photo_url TEXT NULL;
ALTER TABLE student_profiles ADD COLUMN IF NOT EXISTS photo_url TEXT NULL;
