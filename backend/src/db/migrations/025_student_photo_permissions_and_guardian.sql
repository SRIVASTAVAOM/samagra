-- Migration 025: Student photo one-time self-edit tracking, Admin re-approval flag, and guardian_name

ALTER TABLE student_profiles
  ADD COLUMN IF NOT EXISTS guardian_name VARCHAR(150) NULL,
  ADD COLUMN IF NOT EXISTS photo_self_edit_used BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS can_reupload_photo BOOLEAN NOT NULL DEFAULT FALSE,
  ADD COLUMN IF NOT EXISTS photo_updated_at TIMESTAMPTZ NULL;
