-- ============================================================================
-- Migration 020: Standard School ERP Fee Head Slots (1 to 20) & Transport Config
-- Matches exact Indian School ERP standard (eSchool / Sanskar Global School format)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fee_head_slots (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    slot_number INT NOT NULL CHECK (slot_number >= 1 AND slot_number <= 20),
    head_name VARCHAR(100) NOT NULL DEFAULT '',
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(school_id, slot_number)
);

CREATE TABLE IF NOT EXISTS transport_head_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE UNIQUE,
    head_name VARCHAR(100) NOT NULL DEFAULT 'TRANSPORT FEE',
    collection_method VARCHAR(50) NOT NULL DEFAULT 'MONTHLY' CHECK (collection_method IN ('MONTHLY', 'QUARTERLY', 'ROUTE_WISE', 'ANNUAL')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Seed default 20 slots for all existing schools
DO $$
DECLARE
    r_school RECORD;
    i INT;
    v_name VARCHAR(100);
BEGIN
    FOR r_school IN SELECT id FROM schools LOOP
        -- Seed Transport Settings
        INSERT INTO transport_head_settings (school_id, head_name, collection_method)
        VALUES (r_school.id, 'TRANSPORT FEE', 'MONTHLY')
        ON CONFLICT (school_id) DO NOTHING;

        -- Seed 20 Slots
        FOR i IN 1..20 LOOP
            CASE i
                WHEN 1 THEN v_name := 'LAST YEAR DUE';
                WHEN 2 THEN v_name := 'ADMISSION FEE';
                WHEN 3 THEN v_name := 'TUITION FEE';
                WHEN 4 THEN v_name := 'EXAM FEE';
                WHEN 5 THEN v_name := 'DEVELOPMENT CHARGES';
                WHEN 6 THEN v_name := 'COMPUTER / IT FEE';
                WHEN 7 THEN v_name := 'SCIENCE LAB FEE';
                WHEN 8 THEN v_name := 'LIBRARY FEE';
                WHEN 9 THEN v_name := 'SPORTS & GAMES';
                WHEN 10 THEN v_name := 'ACTIVITY FEE';
                ELSE v_name := '';
            END CASE;

            INSERT INTO fee_head_slots (school_id, slot_number, head_name)
            VALUES (r_school.id, i, v_name)
            ON CONFLICT (school_id, slot_number) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

