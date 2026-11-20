-- ============================================================================
-- Migration 021: Bulletproof Real-Time Fee Counter Engine
-- Implements Idempotency, Waterfall Allocations, Cheque Lifecycle, 
-- Shift Day-Book Closing, and Itemized 3-Part Receipts.
-- ============================================================================

-- 1. Extend fee_receipts with Idempotency, Cheque State, and Reversal Audit
ALTER TABLE fee_receipts 
    ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR(100) UNIQUE,
    ADD COLUMN IF NOT EXISTS cheque_status VARCHAR(30) DEFAULT 'CLEARED' CHECK (cheque_status IN ('CLEARED', 'PENDING_CLEARANCE', 'BOUNCED', 'REVERSED')),
    ADD COLUMN IF NOT EXISTS cheque_number VARCHAR(50),
    ADD COLUMN IF NOT EXISTS cheque_bank VARCHAR(100),
    ADD COLUMN IF NOT EXISTS cheque_date DATE,
    ADD COLUMN IF NOT EXISTS is_cancelled BOOLEAN DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS cancellation_reason TEXT,
    ADD COLUMN IF NOT EXISTS cancelled_at TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS cancelled_by UUID REFERENCES users(id),
    ADD COLUMN IF NOT EXISTS waterfall_breakdown JSONB DEFAULT '[]'::jsonb,
    ADD COLUMN IF NOT EXISTS collected_by UUID REFERENCES users(id);

-- 2. Itemized Receipt Items (For printing 3-part receipt with Head 1..20 itemization)
CREATE TABLE IF NOT EXISTS fee_receipt_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    fee_receipt_id UUID NOT NULL REFERENCES fee_receipts(id) ON DELETE CASCADE,
    student_fee_id UUID REFERENCES student_fees(id) ON DELETE SET NULL,
    fee_head_name VARCHAR(100) NOT NULL,
    cycle_name VARCHAR(100),
    base_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    fine_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    net_paid NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_receipt_items_receipt ON fee_receipt_items(fee_receipt_id);

-- 3. Counter Shift Day-Book Register (Cash Denominations & Daily Closing)
CREATE TABLE IF NOT EXISTS fee_counter_shifts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id UUID NOT NULL REFERENCES schools(id) ON DELETE CASCADE,
    clerk_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    shift_date DATE NOT NULL DEFAULT CURRENT_DATE,
    opened_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP WITH TIME ZONE,
    opening_cash NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    system_cash_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    system_upi_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    system_cheque_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    system_bank_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    total_receipts_count INT NOT NULL DEFAULT 0,
    physical_cash_total NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    denominations JSONB DEFAULT '{"500": 0, "200": 0, "100": 0, "50": 0, "20": 0, "10": 0}'::jsonb,
    cash_variance NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    closing_notes TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_counter_shifts_school_date ON fee_counter_shifts(school_id, shift_date, status);
