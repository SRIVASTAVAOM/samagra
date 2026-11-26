-- Migration 022: Student Leaves Review, Remarks, and Approver Tracking Columns
-- Non-destructive additive migration

-- 1. Add review and approver tracking columns to student_leaves
ALTER TABLE student_leaves
  ADD COLUMN IF NOT EXISTS remarks TEXT NULL,
  ADD COLUMN IF NOT EXISTS reviewed_by_staff_id UUID REFERENCES staff_profiles(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reviewed_by_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE NULL,
  ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;

-- 2. Performance indexes for reviewer lookups and student leave status filtering
CREATE INDEX IF NOT EXISTS idx_student_leaves_status ON student_leaves(school_id, status);
CREATE INDEX IF NOT EXISTS idx_student_leaves_reviewer_staff ON student_leaves(reviewed_by_staff_id);
CREATE INDEX IF NOT EXISTS idx_student_leaves_reviewer_user ON student_leaves(reviewed_by_user_id);

-- 3. Base table safety if student_leave_applications exists as physical table
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'student_leave_applications' AND table_type = 'BASE TABLE'
  ) THEN
    ALTER TABLE student_leave_applications ADD COLUMN IF NOT EXISTS remarks TEXT NULL;
    ALTER TABLE student_leave_applications ADD COLUMN IF NOT EXISTS reviewed_by_staff_id UUID NULL;
    ALTER TABLE student_leave_applications ADD COLUMN IF NOT EXISTS reviewed_by_user_id UUID NULL;
    ALTER TABLE student_leave_applications ADD COLUMN IF NOT EXISTS reviewed_at TIMESTAMP WITH TIME ZONE NULL;
    ALTER TABLE student_leave_applications ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP;
  END IF;
END $$;

-- 4. Recreate view to expose all newly added columns
CREATE OR REPLACE VIEW student_leave_applications AS SELECT * FROM student_leaves;
