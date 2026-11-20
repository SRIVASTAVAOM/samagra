-- ============================================================================
-- Migration 019: Customizable Multi-Tenant Fee Structure
-- Adds tables for Fee Heads, Fee Cycles, Fee Structures, Concessions, and Transport Slabs
-- ============================================================================

-- 1. Fee Heads (Customizable components per school: Tuition, Transport, Lab, etc.)
CREATE TABLE IF NOT EXISTS fee_heads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(50) NOT NULL,
    type VARCHAR(30) NOT NULL DEFAULT 'RECURRING' CHECK (type IN ('RECURRING', 'ONE_TIME', 'REFUNDABLE')),
    is_optional BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(school_id, code)
);

-- 2. Fee Cycles / Installments (Quarterly, Monthly, Half-Yearly, Annual)
CREATE TABLE IF NOT EXISTS fee_cycles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    cycle_type VARCHAR(30) NOT NULL DEFAULT 'QUARTERLY' CHECK (cycle_type IN ('MONTHLY', 'QUARTERLY', 'HALF_YEARLY', 'ANNUAL', 'CUSTOM')),
    due_date DATE NOT NULL,
    grace_period_days INT DEFAULT 10,
    sequence_order INT NOT NULL DEFAULT 1,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Fee Structures (Class-wise templates: Primary, High School, Science, Commerce, etc.)
CREATE TABLE IF NOT EXISTS fee_structures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    academic_year_id UUID NOT NULL REFERENCES academic_years(id) ON DELETE CASCADE,
    name VARCHAR(100) NOT NULL,
    class_id UUID REFERENCES classes(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Fee Structure Items (Matrix of Fee Structure + Head + Cycle -> Amount)
CREATE TABLE IF NOT EXISTS fee_structure_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fee_structure_id UUID NOT NULL REFERENCES fee_structures(id) ON DELETE CASCADE,
    fee_head_id UUID NOT NULL REFERENCES fee_heads(id) ON DELETE CASCADE,
    fee_cycle_id UUID NOT NULL REFERENCES fee_cycles(id) ON DELETE CASCADE,
    amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00 CHECK (amount >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(fee_structure_id, fee_head_id, fee_cycle_id)
);

-- 5. Student Fee Concessions & Scholarships (Sibling discount, Staff ward, RTE, Merit)
CREATE TABLE IF NOT EXISTS student_fee_concessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    student_id UUID NOT NULL REFERENCES student_profiles(id) ON DELETE CASCADE,
    fee_head_id UUID REFERENCES fee_heads(id) ON DELETE CASCADE,
    concession_type VARCHAR(50) NOT NULL DEFAULT 'PERCENTAGE' CHECK (concession_type IN ('PERCENTAGE', 'FLAT_AMOUNT')),
    concession_value NUMERIC(10, 2) NOT NULL CHECK (concession_value >= 0),
    reason VARCHAR(150) NOT NULL,
    approved_by UUID REFERENCES users(id) ON DELETE SET NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. Transport Route Slabs (Optional bus route fees)
CREATE TABLE IF NOT EXISTS transport_route_slabs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    route_name VARCHAR(150) NOT NULL,
    distance_slab VARCHAR(50) NOT NULL,
    monthly_fee NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 7. Extend student_fees for head & cycle mapping, fines, and discounts
ALTER TABLE student_fees 
    ADD COLUMN IF NOT EXISTS fee_head_id UUID REFERENCES fee_heads(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS fee_cycle_id UUID REFERENCES fee_cycles(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS fine_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    ADD COLUMN IF NOT EXISTS discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00;

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_fee_heads_school ON fee_heads(school_id);
CREATE INDEX IF NOT EXISTS idx_fee_cycles_school ON fee_cycles(school_id, academic_year_id);
CREATE INDEX IF NOT EXISTS idx_fee_structures_school ON fee_structures(school_id, class_id);
CREATE INDEX IF NOT EXISTS idx_concessions_student ON student_fee_concessions(student_id);

-- 8. Seed default heads and cycles for existing schools
DO $$
DECLARE
    r_school RECORD;
    v_ay_id UUID;
    v_tuit_id UUID;
    v_trnp_id UUID;
    v_comp_id UUID;
    v_exam_id UUID;
    v_annl_id UUID;
    v_q1_id UUID;
    v_q2_id UUID;
    v_q3_id UUID;
    v_q4_id UUID;
BEGIN
    FOR r_school IN SELECT id FROM schools LOOP
        -- Seed Default Heads if none exist for this school
        IF NOT EXISTS (SELECT 1 FROM fee_heads WHERE school_id = r_school.id) THEN
            INSERT INTO fee_heads (school_id, name, code, type, is_optional, description)
            VALUES 
                (r_school.id, 'Tuition Fee', 'TUIT', 'RECURRING', FALSE, 'Regular academic instruction and classroom learning fee')
            RETURNING id INTO v_tuit_id;

            INSERT INTO fee_heads (school_id, name, code, type, is_optional, description)
            VALUES 
                (r_school.id, 'Transport Fee', 'TRNP', 'RECURRING', TRUE, 'Optional school bus and transport service fee')
            RETURNING id INTO v_trnp_id;

            INSERT INTO fee_heads (school_id, name, code, type, is_optional, description)
            VALUES 
                (r_school.id, 'Computer & IT Fee', 'COMP', 'RECURRING', FALSE, 'Computer laboratory, digital learning, and smart classroom fee')
            RETURNING id INTO v_comp_id;

            INSERT INTO fee_heads (school_id, name, code, type, is_optional, description)
            VALUES 
                (r_school.id, 'Examination Fee', 'EXAM', 'ONE_TIME', FALSE, 'Mid-term and final examination papers, assessment, and result card fee')
            RETURNING id INTO v_exam_id;

            INSERT INTO fee_heads (school_id, name, code, type, is_optional, description)
            VALUES 
                (r_school.id, 'Annual Development Charges', 'ANNL', 'ONE_TIME', FALSE, 'Annual institutional amenities, sports grounds, and infrastructure fee')
            RETURNING id INTO v_annl_id;

            INSERT INTO fee_heads (school_id, name, code, type, is_optional, description)
            VALUES 
                (r_school.id, 'Science Lab Fee', 'LAB', 'RECURRING', FALSE, 'Physics, Chemistry, and Biology laboratory equipment and chemicals fee');

            INSERT INTO fee_heads (school_id, name, code, type, is_optional, description)
            VALUES 
                (r_school.id, 'Caution Deposit (Refundable)', 'CAUT', 'REFUNDABLE', TRUE, 'One-time refundable security caution deposit');
        END IF;

        -- Find current academic year for school
        SELECT id INTO v_ay_id FROM academic_years WHERE school_id = r_school.id AND is_current = TRUE LIMIT 1;
        IF v_ay_id IS NULL THEN
            SELECT id INTO v_ay_id FROM academic_years WHERE school_id = r_school.id ORDER BY start_date DESC LIMIT 1;
        END IF;

        -- Seed standard 4 Quarterly cycles if none exist
        IF v_ay_id IS NOT NULL AND NOT EXISTS (SELECT 1 FROM fee_cycles WHERE school_id = r_school.id AND academic_year_id = v_ay_id) THEN
            INSERT INTO fee_cycles (school_id, academic_year_id, name, cycle_type, due_date, grace_period_days, sequence_order)
            VALUES (r_school.id, v_ay_id, 'Quarter 1 (Apr - Jun)', 'QUARTERLY', '2026-04-15', 10, 1)
            RETURNING id INTO v_q1_id;

            INSERT INTO fee_cycles (school_id, academic_year_id, name, cycle_type, due_date, grace_period_days, sequence_order)
            VALUES (r_school.id, v_ay_id, 'Quarter 2 (Jul - Sep)', 'QUARTERLY', '2026-07-15', 10, 2)
            RETURNING id INTO v_q2_id;

            INSERT INTO fee_cycles (school_id, academic_year_id, name, cycle_type, due_date, grace_period_days, sequence_order)
            VALUES (r_school.id, v_ay_id, 'Quarter 3 (Oct - Dec)', 'QUARTERLY', '2026-10-15', 10, 3)
            RETURNING id INTO v_q3_id;

            INSERT INTO fee_cycles (school_id, academic_year_id, name, cycle_type, due_date, grace_period_days, sequence_order)
            VALUES (r_school.id, v_ay_id, 'Quarter 4 (Jan - Mar)', 'QUARTERLY', '2027-01-15', 10, 4)
            RETURNING id INTO v_q4_id;
        END IF;
    END LOOP;
END $$;

