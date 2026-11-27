-- ============================================================================
-- Migration 024: Student Homework Submissions & Per-User Notice Dismissals
-- ============================================================================

-- 1. Extend student_homework_completions to store student submission notes & attachment
ALTER TABLE student_homework_completions
  ADD COLUMN IF NOT EXISTS submission_text TEXT,
  ADD COLUMN IF NOT EXISTS submission_attachment_key VARCHAR(500),
  ADD COLUMN IF NOT EXISTS submission_attachment_name VARCHAR(255),
  ADD COLUMN IF NOT EXISTS submitted_at TIMESTAMP WITH TIME ZONE;

-- 2. Per-user soft-dismissal / clear table for notices (preserves shared notices & audit history)
CREATE TABLE IF NOT EXISTS notice_dismissals (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  notice_id UUID NOT NULL REFERENCES notices(id) ON DELETE CASCADE,
  dismissed_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT uq_notice_dismissal_user_notice UNIQUE(user_id, notice_id)
);

CREATE INDEX IF NOT EXISTS idx_notice_dismissals_user_school
  ON notice_dismissals(user_id, school_id);
