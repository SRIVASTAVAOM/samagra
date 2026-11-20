'use client';

import React, { useState, useEffect } from 'react';
import {
  CreditCard,
  Search,
  Filter,
  Plus,
  CheckCircle2,
  AlertCircle,
  Clock,
  Printer,
  Download,
  IndianRupee,
  Calendar,
  X,
  FileText,
  User,
  GraduationCap,
  Building2,
  RefreshCw,
  Sparkles,
  Sliders,
  Layers,
  Award,
  AlertTriangle,
  Send,
  Trash2,
  Edit2,
  Check,
  ChevronRight,
  Activity,
  Save,
  RotateCcw,
  Bus,
} from 'lucide-react';
import { api } from '@/lib/api';
import { ClassItem } from '@/lib/types';
import { useTenant } from '@/context/TenantContext';

export default function FeesSectionPage() {
  const { branding, features } = useTenant();

  // Navigation matching exact School ERP Standard shown in the image
  const [activeSubTab, setActiveSubTab] = useState<
    | 'fee-heads'
    | 'pay-fee'
    | 'pay-extra'
    | 'transactions'
    | 'monthly-report'
    | 'annual-calculation'
    | 'transport-collection'
    | 'defaulters'
  >('fee-heads');

  const [classes, setClasses] = useState<ClassItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [savingSlots, setSavingSlots] = useState(false);
  const [statusMessage, setStatusMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);

  // Pay Extra Fee State
  const [extraSearchText, setExtraSearchText] = useState('');
  const [extraSearching, setExtraSearching] = useState(false);
  const [extraStudentProfile, setExtraStudentProfile] = useState<any>(null);
  const [extraCategory, setExtraCategory] = useState('LATE FEE FINE');
  const [extraAmount, setExtraAmount] = useState<number | ''>(500);
  const [extraMode, setExtraMode] = useState<'CASH' | 'UPI' | 'CHEQUE'>('CASH');
  const [extraRemarks, setExtraRemarks] = useState('');
  const [submittingExtra, setSubmittingExtra] = useState(false);

  // Transport Collection State
  const [transSearchText, setTransSearchText] = useState('');
  const [transSearching, setTransSearching] = useState(false);
  const [transStudentProfile, setTransStudentProfile] = useState<any>(null);
  const [transRoute, setTransRoute] = useState('Route 1: Civil Lines & Court (₹800/mo)');
  const [transRate, setTransRate] = useState(800);
  const [transMonths, setTransMonths] = useState<string[]>(['APRIL', 'MAY']);
  const [transMode, setTransMode] = useState<'CASH' | 'UPI' | 'CHEQUE'>('CASH');
  const [submittingTrans, setSubmittingTrans] = useState(false);

  // Annual calculation state
  const [applyingMatrix, setApplyingMatrix] = useState(false);

  // =========================================================================
  // 1. FEE HEADS DEFINITION (HEAD 1 TO 20) & TRANSPORT DEFINITION
  // =========================================================================
  const [headSlots, setHeadSlots] = useState<Array<{ slot_number: number; head_name: string; is_active: boolean }>>(() =>
    Array.from({ length: 20 }, (_, i) => ({
      slot_number: i + 1,
      head_name:
        i === 0
          ? 'LAST YEAR DUE'
          : i === 1
          ? 'ADMISSION FEE'
          : i === 2
          ? 'TUITION FEE'
          : i === 3
          ? 'EXAM FEE'
          : i === 4
          ? 'DEVELOPMENT CHARGES'
          : i === 5
          ? 'COMPUTER / IT FEE'
          : i === 6
          ? 'SCIENCE LAB FEE'
          : i === 7
          ? 'LIBRARY FEE'
          : i === 8
          ? 'SPORTS & GAMES'
          : i === 9
          ? 'ACTIVITY FEE'
          : '',
      is_active: true,
    }))
  );

  const [transportHead, setTransportHead] = useState({
    head_name: 'TRANSPORT FEE',
    collection_method: 'MONTHLY',
  });

  const [activityLogsModalOpen, setActivityLogsModalOpen] = useState(false);

  // =========================================================================
  // 2. PAY FEE TAB (Smart POS)
  // =========================================================================
  const [overviewData, setOverviewData] = useState<{
    kpis: {
      total_receivable: number;
      total_collected: number;
      total_pending: number;
      collection_percentage: number;
    };
    records: any[];
  } | null>(null);
  const [search, setSearch] = useState('');
  const [selectedClassId, setSelectedClassId] = useState('');
  const [selectedSectionId, setSelectedSectionId] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  // Collect Fee Modal
  const [collectModalOpen, setCollectModalOpen] = useState(false);
  const [collectStudent, setCollectStudent] = useState<any | null>(null);
  const [collectAmount, setCollectAmount] = useState<number>(0);
  const [paymentMode, setPaymentMode] = useState<'CASH' | 'CHEQUE' | 'BANK_TRANSFER' | 'DEMAND_DRAFT' | 'ONLINE'>('CASH');
  const [transactionRef, setTransactionRef] = useState('');
  const [remarks, setRemarks] = useState('');
  const [chequeNumber, setChequeNumber] = useState('');
  const [chequeBank, setChequeBank] = useState('');
  const [chequeDate, setChequeDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [submittingPayment, setSubmittingPayment] = useState(false);

  // Quick POS Counter Search state
  const [counterSearchText, setCounterSearchText] = useState('');
  const [counterProfile, setCounterProfile] = useState<any | null>(null);
  const [counterSearching, setCounterSearching] = useState(false);

  // 3-Part Printable Receipt Modal
  const [threePartReceipt, setThreePartReceipt] = useState<any | null>(null);

  // Cheque Bounce Reversal Modal
  const [bouncingReceipt, setBouncingReceipt] = useState<any | null>(null);
  const [bouncePenalty, setBouncePenalty] = useState(500);
  const [bounceReason, setBounceReason] = useState('Cheque dishonoured / insufficient funds');
  const [submittingBounce, setSubmittingBounce] = useState(false);

  // Counter Shift Day-Book Closing Modal
  const [shiftModalOpen, setShiftModalOpen] = useState(false);
  const [currentShiftData, setCurrentShiftData] = useState<any | null>(null);
  const [denominations, setDenominations] = useState<Record<string, number>>({
    '500': 0,
    '200': 0,
    '100': 0,
    '50': 0,
    '20': 0,
    '10': 0,
  });
  const [shiftClosingNotes, setShiftClosingNotes] = useState('');
  const [submittingShiftClose, setSubmittingShiftClose] = useState(false);

  // =========================================================================
  // 3. TRANSACTIONS TAB (Receipts Register & Printable Slips)
  // =========================================================================
  const [receipts, setReceipts] = useState<any[]>([]);
  const [receiptSearch, setReceiptSearch] = useState('');
  const [receiptModeFilter, setReceiptModeFilter] = useState('ALL');
  const [receiptDateFilter, setReceiptDateFilter] = useState('');
  const [activeReceiptModal, setActiveReceiptModal] = useState<any | null>(null);

  // =========================================================================
  // 4. ANNUAL FEE CALCULATION MATRIX
  // =========================================================================
  const [calcClassId, setCalcClassId] = useState('');
  const [calcMatrix, setCalcMatrix] = useState<Record<string, number>>({});
  const [feeCycles, setFeeCycles] = useState<any[]>([]);

  // =========================================================================
  // 5. MONTHLY FEE DEPOSIT REPORT (Day-Book)
  // =========================================================================
  const [depositReportDate, setDepositReportDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [dayBookData, setDayBookData] = useState<any | null>(null);

  // =========================================================================
  // 6. DEFAULTERS LIST
  // =========================================================================
  const [defaulters, setDefaulters] = useState<any[]>([]);
  const [defaulterClassId, setDefaulterClassId] = useState('');
  const [defaulterMinDays, setDefaulterMinDays] = useState(1);

  // Live clock for footer
  const [currentTime, setCurrentTime] = useState(() => new Date().toLocaleTimeString('en-IN'));

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date().toLocaleTimeString('en-IN'));
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Load fee head slots from API on mount
  const loadSlots = async () => {
    try {
      setLoading(true);
      const res = await api.fees.getFeeHeadSlots();
      if (res?.slots && res.slots.length > 0) {
        setHeadSlots(res.slots);
      }
      if (res?.transport) {
        setTransportHead(res.transport);
      }
    } catch (err: any) {
      console.error('Failed to load fee head slots:', err);
    } finally {
      setLoading(false);
    }
  };

  const loadClasses = async () => {
    try {
      const cls = await api.academics.getClasses();
      setClasses(cls || []);
    } catch (err) {
      console.error(err);
    }
  };

  const loadOverview = async () => {
    try {
      setLoading(true);
      const ovData = await api.fees.getOverview({
        class_id: selectedClassId || undefined,
        section_id: selectedSectionId || undefined,
        status: statusFilter || undefined,
        search: search || undefined,
      });
      setOverviewData(ovData);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const loadReceipts = async () => {
    try {
      setLoading(true);
      const list = await api.fees.getReceipts({
        search: receiptSearch || undefined,
        mode: receiptModeFilter !== 'ALL' ? receiptModeFilter : undefined,
        date: receiptDateFilter || undefined,
      });
      setReceipts(list || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const loadDayBook = async () => {
    try {
      setLoading(true);
      const res = await api.fees.getDayBook(depositReportDate);
      setDayBookData(res);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const loadDefaulters = async () => {
    try {
      setLoading(true);
      const res = await api.fees.getDefaulters({
        class_id: defaulterClassId || undefined,
        min_days: defaulterMinDays,
      });
      setDefaulters(res || []);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const loadCycles = async () => {
    try {
      const cyc = await api.fees.getFeeCycles();
      setFeeCycles(cyc || []);
    } catch (err) {
      console.error(err);
    }
  };

  useEffect(() => {
    loadSlots();
    loadClasses();
    loadCycles();
  }, []);

  useEffect(() => {
    if (activeSubTab === 'pay-fee') loadOverview();
    else if (activeSubTab === 'transactions') loadReceipts();
    else if (activeSubTab === 'monthly-report') loadDayBook();
    else if (activeSubTab === 'defaulters') loadDefaulters();
  }, [activeSubTab]);

  useEffect(() => {
    if (activeSubTab === 'pay-fee') {
      const timer = setTimeout(() => loadOverview(), 300);
      return () => clearTimeout(timer);
    }
  }, [search, selectedClassId, selectedSectionId, statusFilter]);

  useEffect(() => {
    if (activeSubTab === 'transactions') {
      const timer = setTimeout(() => loadReceipts(), 300);
      return () => clearTimeout(timer);
    }
  }, [receiptSearch, receiptModeFilter, receiptDateFilter]);

  useEffect(() => {
    if (activeSubTab === 'monthly-report') {
      loadDayBook();
    }
  }, [depositReportDate]);

  useEffect(() => {
    if (activeSubTab === 'defaulters') {
      loadDefaulters();
    }
  }, [defaulterClassId, defaulterMinDays]);

  // Handle saving the 20 Fee Head Slots
  const handleSaveFeeHeads = async () => {
    try {
      setSavingSlots(true);
      setStatusMessage(null);
      await api.fees.saveFeeHeadSlots({
        slots: headSlots,
        transport: transportHead,
      });
      setStatusMessage({
        type: 'success',
        text: 'Fee Heads Definition and Transport settings updated successfully!',
      });
    } catch (err: any) {
      setStatusMessage({
        type: 'error',
        text: err.message || 'Failed to save Fee Heads Definition',
      });
    } finally {
      setSavingSlots(false);
    }
  };

  const handleSlotNameChange = (index: number, val: string) => {
    setHeadSlots((prev) => {
      const updated = [...prev];
      updated[index] = { ...updated[index], head_name: val };
      return updated;
    });
  };

  const handleOpenCollectModal = (record: any) => {
    setCollectStudent(record);
    setCollectAmount(Number(record.balance || record.amount || 0));
    setPaymentMode('CASH');
    setTransactionRef('');
    setChequeNumber('');
    setChequeBank('');
    setRemarks('');
    setCollectModalOpen(true);
  };

  // Quick POS Counter search for student
  const handleSearchStudentCounter = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!counterSearchText.trim()) return;

    try {
      setCounterSearching(true);
      setStatusMessage(null);
      const res = await api.fees.getStudentCounterProfile(counterSearchText.trim());
      setCounterProfile(res);
    } catch (err: any) {
      setCounterProfile(null);
      setStatusMessage({
        type: 'error',
        text: err.message || 'Student not found. Try searching by Admission Number.',
      });
    } finally {
      setCounterSearching(false);
    }
  };

  const handleCollectSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!collectStudent || collectAmount <= 0) return;

    try {
      setSubmittingPayment(true);
      setStatusMessage(null);

      // Generate client-side idempotency key to prevent double charge on double-click
      const idempotencyKey = crypto.randomUUID ? crypto.randomUUID() : `pos_${Date.now()}_${Math.random()}`;

      const res = await api.fees.collectFee({
        student_id: collectStudent.student_id,
        student_fee_id: collectStudent.id,
        amount_paid: Number(collectAmount),
        payment_mode: paymentMode,
        transaction_reference: transactionRef || undefined,
        cheque_number: paymentMode === 'CHEQUE' ? chequeNumber : undefined,
        cheque_bank: paymentMode === 'CHEQUE' ? chequeBank : undefined,
        cheque_date: paymentMode === 'CHEQUE' ? chequeDate : undefined,
        idempotency_key: idempotencyKey,
        remarks: remarks || undefined,
      });

      setStatusMessage({
        type: 'success',
        text: `Fee Payment of ₹${collectAmount} recorded successfully! Receipt: ${res.receipt_number}`,
      });
      setCollectModalOpen(false);

      // Load full printable 3-part receipt
      if (res?.id) {
        handleOpenPrintReceipt(res.id);
      } else {
        setActiveReceiptModal({
          ...res,
          student_name: collectStudent.student_name,
          admission_number: collectStudent.admission_number,
          class_name: collectStudent.class_name,
          section_name: collectStudent.section_name,
        });
      }

      await loadOverview();
      if (counterProfile) {
        handleSearchStudentCounter();
      }
    } catch (err: any) {
      setStatusMessage({ type: 'error', text: err.message || 'Payment collection failed' });
    } finally {
      setSubmittingPayment(false);
    }
  };

  // Open 3-Part Printable Receipt Modal
  const handleOpenPrintReceipt = async (receiptId: string) => {
    try {
      const fullReceipt = await api.fees.getPrintableReceipt(receiptId);
      setThreePartReceipt(fullReceipt);
    } catch (err: any) {
      console.error(err);
    }
  };

  // Handler: Search Student for Extra Fee
  const handleSearchExtraStudent = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!extraSearchText.trim()) return;
    try {
      setExtraSearching(true);
      setStatusMessage(null);
      const res = await api.fees.getStudentCounterProfile(extraSearchText.trim());
      setExtraStudentProfile(res);
    } catch (err: any) {
      setExtraStudentProfile(null);
      setStatusMessage({ type: 'error', text: err.message || 'Student not found for extra fee collection' });
    } finally {
      setExtraSearching(false);
    }
  };

  // Handler: Submit Extra Fee Payment
  const handleSubmitExtraFee = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!extraStudentProfile || !extraAmount || Number(extraAmount) <= 0) {
      alert('Please select student and enter valid amount');
      return;
    }
    try {
      setSubmittingExtra(true);
      const res = await api.fees.collectExtraFee({
        student_id: extraStudentProfile.student.id,
        fee_category: extraCategory,
        amount: Number(extraAmount),
        payment_mode: extraMode,
        remarks: extraRemarks,
      });
      setStatusMessage({
        type: 'success',
        text: `Extra fee collected successfully! Receipt #${res.data?.receipt_number || ''}`,
      });
      if (res.data?.receipt_id) {
        handleOpenPrintReceipt(res.data.receipt_id);
      }
      setExtraAmount(500);
      setExtraRemarks('');
    } catch (err: any) {
      setStatusMessage({ type: 'error', text: err.message || 'Failed to collect extra fee' });
    } finally {
      setSubmittingExtra(false);
    }
  };

  // Handler: Search Student for Transport Collection
  const handleSearchTransStudent = async (e?: React.FormEvent) => {
    if (e) e.preventDefault();
    if (!transSearchText.trim()) return;
    try {
      setTransSearching(true);
      setStatusMessage(null);
      const res = await api.fees.getStudentCounterProfile(transSearchText.trim());
      setTransStudentProfile(res);
    } catch (err: any) {
      setTransStudentProfile(null);
      setStatusMessage({ type: 'error', text: err.message || 'Student not found for transport billing' });
    } finally {
      setTransSearching(false);
    }
  };

  // Handler: Submit Transport Fee Collection
  const handleSubmitTransFee = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!transStudentProfile) {
      alert('Please search and select a student');
      return;
    }
    if (transMonths.length === 0) {
      alert('Please select at least one billing month');
      return;
    }
    const totalAmount = transMonths.length * transRate;
    try {
      setSubmittingTrans(true);
      const res = await api.fees.collectExtraFee({
        student_id: transStudentProfile.student.id,
        fee_category: `TRANSPORT FEE (${transMonths.join(', ')})`,
        amount: totalAmount,
        payment_mode: transMode,
        remarks: `Route: ${transRoute}`,
      });
      setStatusMessage({
        type: 'success',
        text: `Transport fee ₹${totalAmount.toLocaleString('en-IN')} collected successfully!`,
      });
      if (res.data?.receipt_id) {
        handleOpenPrintReceipt(res.data.receipt_id);
      }
    } catch (err: any) {
      setStatusMessage({ type: 'error', text: err.message || 'Transport collection failed' });
    } finally {
      setSubmittingTrans(false);
    }
  };

  // Handler: Apply Annual Fee Matrix
  const handleApplyAnnualFee = async () => {
    if (!calcClassId) {
      alert('Please select a target class first');
      return;
    }
    const hasValues = Object.values(calcMatrix).some((v) => Number(v) > 0);
    if (!hasValues) {
      alert('Please enter at least one fee head annual amount');
      return;
    }
    try {
      setApplyingMatrix(true);
      const res = await api.fees.applyAnnualFeeCalculation({
        class_id: calcClassId,
        matrix: calcMatrix,
      });
      setStatusMessage({
        type: 'success',
        text: `Annual fee schedules generated for ${res.data?.studentsCount || 0} students (${res.data?.feeRecordsCreated || 0} fee records created)!`,
      });
    } catch (err: any) {
      setStatusMessage({ type: 'error', text: err.message || 'Failed to apply annual fee matrix' });
    } finally {
      setApplyingMatrix(false);
    }
  };

  // 1-Click Cheque Bounce
  const handleMarkChequeBounceSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!bouncingReceipt) return;

    try {
      setSubmittingBounce(true);
      await api.fees.markChequeBounced(bouncingReceipt.id, {
        penalty_amount: Number(bouncePenalty),
        reason: bounceReason,
      });
      setStatusMessage({
        type: 'success',
        text: `Receipt #${bouncingReceipt.receipt_number} marked as BOUNCED. Balances restored and ₹${bouncePenalty} penalty applied.`,
      });
      setBouncingReceipt(null);
      await loadReceipts();
    } catch (err: any) {
      setStatusMessage({ type: 'error', text: err.message || 'Failed to mark cheque bounced' });
    } finally {
      setSubmittingBounce(false);
    }
  };

  // Shift Day-Book Closing
  const handleOpenShiftModal = async () => {
    try {
      const shift = await api.fees.getCurrentShift();
      setCurrentShiftData(shift);
      setShiftModalOpen(true);
    } catch (err: any) {
      console.error(err);
    }
  };

  const handleCloseShiftSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      setSubmittingShiftClose(true);
      const totalPhysicalCash = Object.entries(denominations).reduce(
        (sum, [denom, count]) => sum + Number(denom) * Number(count || 0),
        0
      );
      await api.fees.closeCounterShift({
        physical_cash: totalPhysicalCash,
        denominations,
        closing_notes: shiftClosingNotes,
      });
      setStatusMessage({
        type: 'success',
        text: 'Counter Shift closed successfully and Day-Book reconciled!',
      });
      setShiftModalOpen(false);
      await loadDayBook();
    } catch (err: any) {
      setStatusMessage({ type: 'error', text: err.message || 'Failed to close shift' });
    } finally {
      setSubmittingShiftClose(false);
    }
  };

  const selectedClass = classes.find((c) => c.class_id === selectedClassId);

  return (
    <div className="min-h-screen bg-[#F0F4F8] text-slate-800 flex flex-col justify-between font-sans">
      <div className="p-4 md:p-6 max-w-[1400px] w-full mx-auto space-y-4">
        {/* =================================================================== */}
        {/* TOP SUB-NAVIGATION PILL BAR (Exact from reference image)            */}
        {/* =================================================================== */}
        <div className="bg-white/95 backdrop-blur-xs rounded-full p-1.5 shadow-xs border border-slate-200/80 flex flex-wrap items-center justify-center gap-1.5 text-xs font-semibold">
          {[
            { id: 'fee-heads', label: 'Fee Heads Definition', show: true },
            { id: 'pay-fee', label: 'Pay Fee', show: true },
            { id: 'pay-extra', label: 'Pay Extra Fee', show: features.extra_fees !== false },
            { id: 'transactions', label: 'Fee Transactions', show: true },
            { id: 'monthly-report', label: 'Monthly Fee Deposite Report', show: true },
            { id: 'annual-calculation', label: 'Annual Fee Calculation', show: features.annual_matrix !== false },
            { id: 'transport-collection', label: 'Transport Fee Collection', show: features.transport !== false },
            { id: 'defaulters', label: 'Defaulters List', show: features.defaulters !== false },
          ]
            .filter((i) => i.show)
            .map((item) => {
              const isActive = activeSubTab === item.id;
              return (
                <button
                  key={item.id}
                  onClick={() => setActiveSubTab(item.id as any)}
                  className={`px-4 py-1.5 rounded-full transition-all cursor-pointer ${
                    isActive
                      ? 'bg-[#00B4D8] text-white font-bold shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  {item.label}
                </button>
              );
            })}
        </div>

        {/* STATUS MESSAGE BANNER */}
        {statusMessage && (
          <div
            className={`p-3 rounded-xl flex items-center justify-between border text-xs font-medium shadow-xs ${
              statusMessage.type === 'success'
                ? 'bg-emerald-50 text-emerald-900 border-emerald-200'
                : 'bg-rose-50 text-rose-900 border-rose-200'
            }`}
          >
            <div className="flex items-center gap-2">
              {statusMessage.type === 'success' ? (
                <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" />
              ) : (
                <AlertCircle className="w-4 h-4 text-rose-600 shrink-0" />
              )}
              <span>{statusMessage.text}</span>
            </div>
            <button
              onClick={() => setStatusMessage(null)}
              className="text-xs font-bold underline hover:opacity-75 cursor-pointer"
            >
              Dismiss
            </button>
          </div>
        )}

        {/* =================================================================== */}
        {/* VIEW 1: FEE HEADS DEFINITION (HEAD 1 TO 20) (From photo)           */}
        {/* =================================================================== */}
        {activeSubTab === 'fee-heads' && (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-sm p-6 md:p-8 space-y-6">
            {/* Header Title & Activity Log Button */}
            <div className="flex items-center justify-between border-b border-slate-100 pb-4">
              <h2 className="text-xl font-bold text-slate-800 tracking-tight">
                Fee Heads Definition
              </h2>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => setActivityLogsModalOpen(true)}
                  className="px-4 py-1.5 rounded-lg bg-[#2DD4BF] hover:bg-[#14B8A6] text-white text-xs font-bold transition shadow-xs cursor-pointer flex items-center gap-1.5"
                >
                  <Activity className="w-3.5 h-3.5" />
                  Activity Log
                </button>
              </div>
            </div>

            {/* 2-Column Fee Heads Grid (Head 1 to 10 on Left, Head 11 to 20 on Right) */}
            <div className="grid grid-cols-1 md:grid-cols-2 gap-x-12 gap-y-3.5">
              {/* Left Column: Head 1 to 10 */}
              <div className="space-y-3">
                {headSlots.slice(0, 10).map((slot, index) => (
                  <div key={slot.slot_number} className="flex flex-col sm:flex-row sm:items-center gap-2">
                    <label className="text-xs font-semibold text-slate-700 w-20 shrink-0">
                      Head {slot.slot_number}
                    </label>
                    <input
                      type="text"
                      placeholder={`Enter Head ${slot.slot_number} name`}
                      value={slot.head_name}
                      onChange={(e) => handleSlotNameChange(index, e.target.value)}
                      className="flex-1 px-4 py-2 rounded-full border border-slate-200 bg-white hover:border-slate-300 focus:border-teal-500 focus:ring-2 focus:ring-teal-100 text-xs font-semibold text-slate-800 outline-none transition shadow-2xs"
                    />
                  </div>
                ))}
              </div>

              {/* Right Column: Head 11 to 20 */}
              <div className="space-y-3">
                {headSlots.slice(10, 20).map((slot, index) => {
                  const actualIdx = index + 10;
                  return (
                    <div key={slot.slot_number} className="flex flex-col sm:flex-row sm:items-center gap-2">
                      <label className="text-xs font-semibold text-slate-700 w-20 shrink-0">
                        Head {slot.slot_number}
                      </label>
                      <input
                        type="text"
                        placeholder={`Enter Head ${slot.slot_number} name`}
                        value={slot.head_name}
                        onChange={(e) => handleSlotNameChange(actualIdx, e.target.value)}
                        className="flex-1 px-4 py-2 rounded-full border border-slate-200 bg-white hover:border-slate-300 focus:border-teal-500 focus:ring-2 focus:ring-teal-100 text-xs font-semibold text-slate-800 outline-none transition shadow-2xs"
                      />
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Transport Head Definition Section */}
            <div className="pt-6 border-t border-slate-100 space-y-4">
              <h3 className="text-base font-bold text-slate-800">
                Transport Head Definition
              </h3>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-x-12 gap-y-3">
                <div className="flex flex-col sm:flex-row sm:items-center gap-2">
                  <label className="text-xs font-semibold text-slate-700 w-28 shrink-0">
                    Head Name
                  </label>
                  <input
                    type="text"
                    value={transportHead.head_name}
                    onChange={(e) =>
                      setTransportHead((prev) => ({ ...prev, head_name: e.target.value }))
                    }
                    className="flex-1 px-4 py-2 rounded-full border border-slate-200 bg-white hover:border-slate-300 focus:border-teal-500 focus:ring-2 focus:ring-teal-100 text-xs font-semibold text-slate-800 outline-none transition shadow-2xs"
                  />
                </div>

                <div className="flex flex-col sm:flex-row sm:items-center gap-2">
                  <label className="text-xs font-semibold text-slate-700 w-36 shrink-0">
                    Collection Method
                  </label>
                  <select
                    value={transportHead.collection_method}
                    onChange={(e) =>
                      setTransportHead((prev) => ({ ...prev, collection_method: e.target.value }))
                    }
                    className="flex-1 px-4 py-2 rounded-full border border-slate-200 bg-white hover:border-slate-300 focus:border-teal-500 focus:ring-2 focus:ring-teal-100 text-xs font-semibold text-slate-800 outline-none transition shadow-2xs cursor-pointer"
                  >
                    <option value="MONTHLY">Monthly Billing</option>
                    <option value="QUARTERLY">Quarterly Billing</option>
                    <option value="ROUTE_WISE">Route-Wise Distance Slabs</option>
                    <option value="ANNUAL">Annual One-Time</option>
                  </select>
                </div>
              </div>
            </div>

            {/* Bottom Actions Bar */}
            <div className="pt-6 border-t border-slate-100 flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={loadSlots}
                className="px-5 py-2 rounded-full border border-slate-300 hover:bg-slate-50 text-xs font-semibold text-slate-700 transition cursor-pointer flex items-center gap-1.5"
              >
                <RotateCcw className="w-3.5 h-3.5" /> Reset
              </button>

              <button
                type="button"
                onClick={handleSaveFeeHeads}
                disabled={savingSlots}
                className="px-6 py-2 rounded-full bg-[#10B981] hover:bg-[#059669] text-white text-xs font-bold transition shadow-xs cursor-pointer flex items-center gap-2 disabled:opacity-50"
              >
                <Save className="w-3.5 h-3.5" />
                {savingSlots ? 'Saving Changes...' : 'Save Fee Heads Definition'}
              </button>
            </div>
          </div>
        )}

        {/* =================================================================== */}
        {/* VIEW 2: PAY FEE (Smart POS Counter with Waterfall Settlement)       */}
        {/* =================================================================== */}
        {activeSubTab === 'pay-fee' && (
          <div className="space-y-4">
            {/* Real-Time Fast POS Counter Search Bar */}
            <div className="bg-gradient-to-r from-teal-900 to-slate-900 rounded-2xl p-4 text-white shadow-md">
              <div className="flex flex-col sm:flex-row items-center justify-between gap-3">
                <div className="space-y-0.5">
                  <h3 className="text-sm font-bold flex items-center gap-2 text-teal-300">
                    <Sparkles className="w-4 h-4 text-emerald-400" /> Real-Time Quick Fee POS Counter
                  </h3>
                  <p className="text-[11px] text-slate-300">
                    Search student by Admission Number, Roll No, or Name for instant Waterfall settlement.
                  </p>
                </div>

                <form onSubmit={handleSearchStudentCounter} className="flex items-center gap-2 w-full sm:w-auto">
                  <div className="relative flex-1 sm:w-72">
                    <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                    <input
                      type="text"
                      placeholder="e.g. ADM-101 or Aarav..."
                      value={counterSearchText}
                      onChange={(e) => setCounterSearchText(e.target.value)}
                      className="w-full pl-9 pr-3 py-1.5 rounded-full text-xs bg-white/10 text-white placeholder-slate-400 border border-white/20 focus:outline-none focus:bg-white/20 focus:border-teal-400"
                    />
                  </div>
                  <button
                    type="submit"
                    disabled={counterSearching || !counterSearchText.trim()}
                    className="px-4 py-1.5 rounded-full bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold text-xs transition cursor-pointer disabled:opacity-50 shrink-0"
                  >
                    {counterSearching ? 'Searching...' : 'Pull Student'}
                  </button>
                  {counterProfile && (
                    <button
                      type="button"
                      onClick={() => {
                        setCounterProfile(null);
                        setCounterSearchText('');
                      }}
                      className="p-1.5 rounded-full bg-white/10 hover:bg-white/20 text-slate-300 text-xs"
                      title="Clear Search"
                    >
                      <X className="w-3.5 h-3.5" />
                    </button>
                  )}
                </form>
              </div>

              {/* Student Quick Profile Card & Waterfall Breakdown (If pulled) */}
              {counterProfile && (
                <div className="mt-4 pt-4 border-t border-white/15 grid grid-cols-1 md:grid-cols-3 gap-4">
                  {/* Col 1: Student Metadata */}
                  <div className="bg-white/5 rounded-xl p-3 space-y-2 border border-white/10 text-xs">
                    <div className="flex items-center gap-2">
                      <div className="w-8 h-8 rounded-full bg-emerald-400/20 text-emerald-300 flex items-center justify-center font-bold">
                        {counterProfile.student?.first_name?.[0] || 'S'}
                      </div>
                      <div>
                        <div className="font-bold text-white text-sm">{counterProfile.student?.full_name}</div>
                        <div className="text-[10px] text-slate-300 font-mono">
                          Adm: {counterProfile.student?.admission_number} | Roll: {counterProfile.student?.roll_number || '—'}
                        </div>
                      </div>
                    </div>

                    <div className="text-[11px] space-y-1 text-slate-300 pt-1 border-t border-white/10">
                      <div>Class: <strong className="text-white">{counterProfile.student?.class_name ? `Class ${counterProfile.student.class_name} (${counterProfile.student.section_name})` : '—'}</strong></div>
                      <div>Father: <strong className="text-white">{counterProfile.student?.father_name || '—'}</strong></div>
                      <div>Contact: <strong className="text-white">{counterProfile.student?.emergency_contact_number || counterProfile.student?.phone_number || '—'}</strong></div>
                    </div>

                    {/* Sibling Linkage Alert */}
                    {counterProfile.siblings?.length > 0 && (
                      <div className="p-2 rounded-lg bg-teal-500/20 border border-teal-400/30 text-[10px] text-teal-200">
                        <span className="font-bold block">Linked Sibling in School:</span>
                        {counterProfile.siblings.map((sib: any) => (
                          <div key={sib.id}>• {sib.full_name} ({sib.class_name})</div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Col 2 & 3: Waterfall Dues List & Quick Collect */}
                  <div className="md:col-span-2 bg-white/5 rounded-xl p-3 border border-white/10 text-xs space-y-3">
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-slate-200">Waterfall Priority Dues Breakdown</span>
                      <div className="text-right">
                        <span className="text-[10px] text-slate-400 block">Total Outstanding</span>
                        <span className="text-base font-extrabold text-rose-400">
                          ₹{Number(counterProfile.summary?.total_outstanding || 0).toLocaleString('en-IN')}
                        </span>
                      </div>
                    </div>

                    {counterProfile.summary?.has_pending_arrears && (
                      <div className="p-2 rounded-lg bg-rose-500/20 border border-rose-400/40 text-rose-300 text-[11px] flex items-center gap-2">
                        <AlertTriangle className="w-4 h-4 shrink-0" />
                        <span><strong>Warning:</strong> Student has unpaid prior year arrears (Head 1: LAST YEAR DUE). All payments will clear this first.</span>
                      </div>
                    )}

                    <div className="max-h-48 overflow-y-auto divide-y divide-white/10 rounded-lg bg-black/20 p-2">
                      {counterProfile.fees?.map((fee: any) => (
                        <div key={fee.id} className="py-1.5 flex items-center justify-between text-[11px]">
                          <div>
                            <span className="font-semibold text-slate-200">{fee.fee_title}</span>
                            <span className="text-[10px] text-slate-400 block">Due: {fee.due_date}</span>
                          </div>
                          <div className="text-right">
                            <span className="font-bold text-rose-300">₹{fee.balance.toLocaleString('en-IN')}</span>
                            <span className="text-[9px] text-slate-400 block">Total: ₹{fee.amount}</span>
                          </div>
                        </div>
                      ))}
                    </div>

                    <div className="flex items-center justify-end gap-2 pt-1">
                      <button
                        type="button"
                        onClick={() =>
                          handleOpenCollectModal({
                            student_id: counterProfile.student.id,
                            student_name: counterProfile.student.full_name,
                            admission_number: counterProfile.student.admission_number,
                            class_name: counterProfile.student.class_name,
                            section_name: counterProfile.student.section_name,
                            fee_title: 'Full Waterfall Settlement',
                            balance: counterProfile.summary?.total_outstanding,
                          })
                        }
                        className="px-5 py-2 rounded-full bg-emerald-500 hover:bg-emerald-400 text-slate-950 font-bold text-xs transition cursor-pointer shadow-xs flex items-center gap-1.5"
                      >
                        <CreditCard className="w-3.5 h-3.5" />
                        Collect Payment (Waterfall Settlement)
                      </button>
                    </div>
                  </div>
                </div>
              )}
            </div>

            {overviewData?.kpis && (
              <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
                <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
                  <span className="text-[11px] font-semibold text-slate-500 block">Total Receivable</span>
                  <div className="text-xl font-bold text-slate-900 mt-1">
                    ₹{overviewData.kpis.total_receivable.toLocaleString('en-IN')}
                  </div>
                </div>
                <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
                  <span className="text-[11px] font-semibold text-emerald-700 block">Total Collected</span>
                  <div className="text-xl font-bold text-emerald-600 mt-1">
                    ₹{overviewData.kpis.total_collected.toLocaleString('en-IN')}
                  </div>
                </div>
                <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
                  <span className="text-[11px] font-semibold text-rose-700 block">Pending Dues</span>
                  <div className="text-xl font-bold text-rose-600 mt-1">
                    ₹{overviewData.kpis.total_pending.toLocaleString('en-IN')}
                  </div>
                </div>
                <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-xs">
                  <span className="text-[11px] font-semibold text-indigo-700 block">Collection Rate</span>
                  <div className="text-xl font-bold text-indigo-600 mt-1">
                    {overviewData.kpis.collection_percentage}%
                  </div>
                </div>
              </div>
            )}

            {/* Filter */}
            <div className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-xs flex flex-wrap items-center gap-3">
              <div className="relative flex-1 min-w-[200px]">
                <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Search student by name, admission no, or head..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full pl-9 pr-4 py-1.5 rounded-full border border-slate-200 text-xs bg-slate-50/50 outline-none focus:border-teal-500"
                />
              </div>

              <select
                value={selectedClassId}
                onChange={(e) => {
                  setSelectedClassId(e.target.value);
                  setSelectedSectionId('');
                }}
                className="px-3 py-1.5 rounded-full border border-slate-200 text-xs bg-white text-slate-700 cursor-pointer"
              >
                <option value="">All Classes</option>
                {classes.map((c) => (
                  <option key={c.class_id} value={c.class_id}>
                    Class {c.class_name}
                  </option>
                ))}
              </select>

              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value)}
                className="px-3 py-1.5 rounded-full border border-slate-200 text-xs bg-white text-slate-700 cursor-pointer"
              >
                <option value="">All Statuses</option>
                <option value="PENDING">Pending Dues</option>
                <option value="PARTIAL">Partially Paid</option>
                <option value="PAID">Fully Paid</option>
              </select>
            </div>

            {/* Table */}
            <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
              {loading ? (
                <div className="p-12 text-center text-xs text-slate-500">Loading student accounts...</div>
              ) : !overviewData?.records || overviewData.records.length === 0 ? (
                <div className="p-12 text-center text-xs text-slate-500">No student records found.</div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs border-collapse min-w-[750px]">
                    <thead>
                      <tr className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200">
                        <th className="p-3 pl-5">Student</th>
                        <th className="p-3">Class</th>
                        <th className="p-3">Fee Item</th>
                        <th className="p-3">Due Date</th>
                        <th className="p-3 text-right">Amount</th>
                        <th className="p-3 text-right">Paid</th>
                        <th className="p-3 text-right">Balance</th>
                        <th className="p-3 text-center">Status</th>
                        <th className="p-3 pr-5 text-right">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {overviewData.records.map((r) => (
                        <tr key={r.id} className="hover:bg-slate-50/80">
                          <td className="p-3 pl-5 font-bold text-slate-900">
                            {r.student_name}
                            <span className="block font-mono text-[10px] text-slate-400 font-normal">
                              Adm: {r.admission_number}
                            </span>
                          </td>
                          <td className="p-3 text-slate-700 font-medium">
                            {r.class_name ? `Class ${r.class_name} (${r.section_name})` : '—'}
                          </td>
                          <td className="p-3 font-semibold text-slate-800">{r.fee_title}</td>
                          <td className="p-3 text-slate-600">{r.due_date}</td>
                          <td className="p-3 text-right font-semibold text-slate-700">
                            ₹{r.amount.toLocaleString('en-IN')}
                          </td>
                          <td className="p-3 text-right font-semibold text-emerald-600">
                            ₹{r.amount_paid.toLocaleString('en-IN')}
                          </td>
                          <td className="p-3 text-right font-bold text-rose-600">
                            ₹{r.balance.toLocaleString('en-IN')}
                          </td>
                          <td className="p-3 text-center">
                            <span
                              className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                                r.status === 'PAID'
                                  ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                  : r.status === 'PARTIAL'
                                  ? 'bg-amber-50 text-amber-700 border border-amber-200'
                                  : 'bg-rose-50 text-rose-700 border border-rose-200'
                              }`}
                            >
                              {r.status}
                            </span>
                          </td>
                          <td className="p-3 pr-5 text-right">
                            {r.status !== 'PAID' ? (
                              <button
                                onClick={() => handleOpenCollectModal(r)}
                                className="px-3 py-1 rounded-full bg-[#10B981] hover:bg-[#059669] text-white text-[11px] font-bold transition cursor-pointer shadow-2xs"
                              >
                                Pay Fee
                              </button>
                            ) : (
                              <span className="text-[11px] text-emerald-600 font-medium">Paid</span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        )}

        {/* =================================================================== */}
        {/* VIEW 3: TRANSACTIONS & RECEIPTS (From photo)                        */}
        {/* =================================================================== */}
        {activeSubTab === 'transactions' && (
          <div className="space-y-4">
            <div className="bg-white p-3.5 rounded-2xl border border-slate-200 shadow-xs flex flex-wrap items-center gap-3">
              <div className="relative flex-1 min-w-[200px]">
                <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Search receipt #, student name, admission no..."
                  value={receiptSearch}
                  onChange={(e) => setReceiptSearch(e.target.value)}
                  className="w-full pl-9 pr-4 py-1.5 rounded-full border border-slate-200 text-xs bg-slate-50/50 outline-none focus:border-teal-500"
                />
              </div>

              <select
                value={receiptModeFilter}
                onChange={(e) => setReceiptModeFilter(e.target.value)}
                className="px-3 py-1.5 rounded-full border border-slate-200 text-xs bg-white text-slate-700 cursor-pointer"
              >
                <option value="ALL">All Modes</option>
                <option value="CASH">Cash</option>
                <option value="ONLINE">Online / UPI</option>
                <option value="CHEQUE">Cheque / DD</option>
                <option value="BANK_TRANSFER">Bank Transfer</option>
              </select>

              <input
                type="date"
                value={receiptDateFilter}
                onChange={(e) => setReceiptDateFilter(e.target.value)}
                className="px-3 py-1.5 rounded-full border border-slate-200 text-xs bg-white text-slate-700 cursor-pointer"
              />
            </div>

            <div className="bg-white rounded-2xl border border-slate-200 shadow-xs overflow-hidden">
              {loading ? (
                <div className="p-12 text-center text-xs text-slate-500">Loading transactions...</div>
              ) : receipts.length === 0 ? (
                <div className="p-12 text-center text-xs text-slate-500">No transactions found.</div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-xs border-collapse min-w-[700px]">
                    <thead>
                      <tr className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200">
                        <th className="p-3 pl-5">Receipt #</th>
                        <th className="p-3">Date</th>
                        <th className="p-3">Student</th>
                        <th className="p-3">Class</th>
                        <th className="p-3">Mode</th>
                        <th className="p-3 text-right">Amount Paid</th>
                        <th className="p-3 pr-5 text-right">Action</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {receipts.map((r) => (
                        <tr key={r.id} className="hover:bg-slate-50/80">
                          <td className="p-3 pl-5 font-mono font-bold text-teal-700">{r.receipt_number}</td>
                          <td className="p-3 text-slate-600">{r.payment_date}</td>
                          <td className="p-3 font-bold text-slate-900">
                            {r.student_name}
                            <span className="block font-mono text-[10px] text-slate-400 font-normal">
                              Adm: {r.admission_number}
                            </span>
                          </td>
                          <td className="p-3 text-slate-700 font-medium">
                            {r.class_name ? `Class ${r.class_name} (${r.section_name})` : '—'}
                          </td>
                          <td className="p-3 font-semibold text-slate-700">{r.payment_mode}</td>
                          <td className="p-3 text-right font-bold text-emerald-600">
                            ₹{Number(r.amount_paid).toLocaleString('en-IN')}
                          </td>
                          <td className="p-3 pr-5 text-right flex items-center justify-end gap-1.5">
                            <button
                              onClick={() => handleOpenPrintReceipt(r.id)}
                              className="px-3 py-1 rounded-full bg-teal-800 hover:bg-teal-700 text-white text-[11px] font-semibold cursor-pointer flex items-center gap-1"
                            >
                              <Printer className="w-3 h-3" /> 3-Part Slip
                            </button>
                            {r.payment_mode === 'CHEQUE' && !r.is_cancelled && r.cheque_status !== 'BOUNCED' && (
                              <button
                                onClick={() => setBouncingReceipt(r)}
                                className="px-2.5 py-1 rounded-full border border-rose-300 text-rose-700 hover:bg-rose-50 text-[10px] font-bold cursor-pointer"
                              >
                                Dishonour / Bounce
                              </button>
                            )}
                            {r.is_cancelled && (
                              <span className="px-2 py-0.5 rounded-full bg-rose-100 text-rose-800 text-[10px] font-bold">
                                Bounced
                              </span>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          </div>
        )}

        {/* =================================================================== */}
        {/* VIEW 4: MONTHLY FEE DEPOSIT REPORT (From photo)                     */}
        {/* =================================================================== */}
        {activeSubTab === 'monthly-report' && (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xs p-6 space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-100 pb-4">
              <div>
                <h3 className="text-base font-bold text-slate-800">Monthly Fee Deposit &amp; Day-Book Report</h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Daily &amp; monthly cashier collection reconciliation by payment mode.
                </p>
              </div>

              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={handleOpenShiftModal}
                  className="px-4 py-1.5 rounded-full bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold transition flex items-center gap-1.5 cursor-pointer shadow-xs"
                >
                  <Activity className="w-3.5 h-3.5" /> Reconcile &amp; Close Shift
                </button>
                <span className="text-xs font-semibold text-slate-600 ml-2">Date:</span>
                <input
                  type="date"
                  value={depositReportDate}
                  onChange={(e) => setDepositReportDate(e.target.value)}
                  className="px-3 py-1.5 rounded-full border border-slate-200 text-xs bg-white text-slate-700 outline-none"
                />
              </div>
            </div>

            {dayBookData?.summary && (
              <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
                <div className="p-4 rounded-2xl bg-slate-50 border border-slate-200">
                  <span className="text-[11px] text-slate-500 block">Total Deposited</span>
                  <strong className="text-xl text-slate-900 block mt-1">
                    ₹{dayBookData.summary.total_collected.toLocaleString('en-IN')}
                  </strong>
                  <span className="text-[10px] text-slate-400 block mt-0.5">
                    {dayBookData.summary.receipt_count} receipts
                  </span>
                </div>
                <div className="p-4 rounded-2xl bg-emerald-50 border border-emerald-200">
                  <span className="text-[11px] text-emerald-800 block">Cash in Hand</span>
                  <strong className="text-xl text-emerald-700 block mt-1">
                    ₹{dayBookData.summary.cash_total.toLocaleString('en-IN')}
                  </strong>
                </div>
                <div className="p-4 rounded-2xl bg-blue-50 border border-blue-200">
                  <span className="text-[11px] text-blue-800 block">UPI / Online</span>
                  <strong className="text-xl text-blue-700 block mt-1">
                    ₹{dayBookData.summary.online_upi_total.toLocaleString('en-IN')}
                  </strong>
                </div>
                <div className="p-4 rounded-2xl bg-purple-50 border border-purple-200">
                  <span className="text-[11px] text-purple-800 block">Cheques Received</span>
                  <strong className="text-xl text-purple-700 block mt-1">
                    ₹{dayBookData.summary.cheque_total.toLocaleString('en-IN')}
                  </strong>
                </div>
                <div className="p-4 rounded-2xl bg-amber-50 border border-amber-200">
                  <span className="text-[11px] text-amber-800 block">Bank Transfer</span>
                  <strong className="text-xl text-amber-700 block mt-1">
                    ₹{dayBookData.summary.bank_transfer_total.toLocaleString('en-IN')}
                  </strong>
                </div>
              </div>
            )}
          </div>
        )}

        {/* =================================================================== */}
        {/* VIEW 5: ANNUAL FEE CALCULATION (From photo)                         */}
        {/* =================================================================== */}
        {activeSubTab === 'annual-calculation' && (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xs p-6 space-y-6">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-100 pb-4">
              <div>
                <h3 className="text-base font-bold text-slate-800">Annual Fee Calculation Matrix</h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Calculate and assign annual fee schedules across defined Fee Heads for each class.
                </p>
              </div>

              <select
                value={calcClassId}
                onChange={(e) => setCalcClassId(e.target.value)}
                className="px-4 py-1.5 rounded-full border border-slate-200 text-xs font-bold bg-white text-slate-800 cursor-pointer"
              >
                <option value="">Select Target Class...</option>
                {classes.map((c) => (
                  <option key={c.class_id} value={c.class_id}>
                    Class {c.class_name}
                  </option>
                ))}
              </select>
            </div>

            {/* Grid of active head slots */}
            <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
              {headSlots
                .filter((s) => s.head_name.trim().length > 0)
                .map((slot) => {
                  const val = calcMatrix[slot.head_name] ?? '';
                  return (
                    <div key={slot.slot_number} className="p-4 rounded-2xl border border-slate-200 bg-slate-50/50 space-y-2">
                      <div className="flex items-center justify-between">
                        <span className="text-[10px] font-bold text-slate-400">Head #{slot.slot_number}</span>
                        <span className="text-[10px] font-bold text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded">ACTIVE</span>
                      </div>
                      <strong className="text-xs text-slate-800 block truncate">{slot.head_name}</strong>
                      <div className="flex items-center gap-1.5 pt-1">
                        <span className="text-xs text-slate-500 font-bold">₹</span>
                        <input
                          type="number"
                          min="0"
                          placeholder="Annual amount"
                          value={val}
                          onChange={(e) => {
                            const num = Number(e.target.value);
                            setCalcMatrix((prev) => ({
                              ...prev,
                              [slot.head_name]: num >= 0 ? num : 0,
                            }));
                          }}
                          className="w-full px-3 py-1.5 rounded-full border border-slate-200 bg-white text-xs font-bold text-slate-800 outline-none"
                        />
                      </div>
                    </div>
                  );
                })}
            </div>

            <div className="p-4 rounded-2xl bg-teal-50/50 border border-teal-200 flex flex-col sm:flex-row items-center justify-between gap-3">
              <div>
                <span className="text-xs text-slate-600 block">Total Calculated Annual Fee:</span>
                <strong className="text-2xl text-teal-800">
                  ₹{Object.values(calcMatrix).reduce((acc, v) => acc + (Number(v) || 0), 0).toLocaleString('en-IN')}
                </strong>
              </div>

              <button
                type="button"
                disabled={applyingMatrix}
                onClick={handleApplyAnnualFee}
                className="px-6 py-2 rounded-full bg-[#023E8A] hover:bg-[#001938] text-white text-xs font-bold transition shadow-xs cursor-pointer disabled:opacity-50"
              >
                {applyingMatrix ? 'Applying to Class Students...' : 'Apply Calculation to Class'}
              </button>
            </div>
          </div>
        )}

        {/* =================================================================== */}
        {/* VIEW 6: DEFAULTERS LIST (From photo)                                */}
        {/* =================================================================== */}
        {activeSubTab === 'defaulters' && (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xs p-6 space-y-4">
            <div className="flex flex-wrap items-center justify-between gap-3 border-b border-slate-100 pb-4">
              <div>
                <h3 className="text-base font-bold text-slate-800">Fee Defaulters Directory</h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Overdue accounts past scheduled deadline with instant reminder capability.
                </p>
              </div>

              <div className="flex items-center gap-2">
                <select
                  value={defaulterClassId}
                  onChange={(e) => setDefaulterClassId(e.target.value)}
                  className="px-3 py-1.5 rounded-full border border-slate-200 text-xs bg-white text-slate-700 cursor-pointer"
                >
                  <option value="">All Classes</option>
                  {classes.map((c) => (
                    <option key={c.class_id} value={c.class_id}>
                      Class {c.class_name}
                    </option>
                  ))}
                </select>

                <select
                  value={defaulterMinDays}
                  onChange={(e) => setDefaulterMinDays(Number(e.target.value))}
                  className="px-3 py-1.5 rounded-full border border-slate-200 text-xs bg-white text-slate-700 cursor-pointer"
                >
                  <option value={1}>Overdue &gt; 1 Day</option>
                  <option value={15}>Overdue &gt; 15 Days</option>
                  <option value={30}>Overdue &gt; 30 Days</option>
                </select>
              </div>
            </div>

            {defaulters.length === 0 ? (
              <div className="p-12 text-center text-xs text-slate-500">
                <CheckCircle2 className="w-8 h-8 text-emerald-500 mx-auto mb-2" />
                <p className="font-bold text-slate-800">No Defaulters Found!</p>
                <p className="text-slate-400">All student accounts are currently cleared.</p>
              </div>
            ) : (
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs border-collapse min-w-[700px]">
                  <thead>
                    <tr className="bg-slate-50 text-slate-500 font-semibold border-b border-slate-200">
                      <th className="p-3 pl-5">Student</th>
                      <th className="p-3">Class</th>
                      <th className="p-3">Parent Contact</th>
                      <th className="p-3 text-right">Total Overdue</th>
                      <th className="p-3 text-center">Days Overdue</th>
                      <th className="p-3 pr-5 text-right">Reminder</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {defaulters.map((d) => (
                      <tr key={d.student_id} className="hover:bg-slate-50">
                        <td className="p-3 pl-5 font-bold text-slate-900">
                          {d.student_name}
                          <span className="block font-mono text-[10px] text-slate-400 font-normal">
                            Adm: {d.admission_number}
                          </span>
                        </td>
                        <td className="p-3 text-slate-700 font-medium">
                          {d.class_name ? `Class ${d.class_name} (${d.section_name})` : '—'}
                        </td>
                        <td className="p-3 text-slate-700 font-mono text-[11px]">
                          {d.primary_phone || 'No phone'}
                        </td>
                        <td className="p-3 text-right font-bold text-rose-600">
                          ₹{Number(d.total_overdue_amount).toLocaleString('en-IN')}
                        </td>
                        <td className="p-3 text-center">
                          <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-rose-100 text-rose-800">
                            {d.days_overdue} days
                          </span>
                        </td>
                        <td className="p-3 pr-5 text-right">
                          {d.primary_phone ? (
                            <a
                              href={`https://wa.me/${d.primary_phone.replace(/\D/g, '')}?text=Dear%20Parent,%20School%20fees%20of%20INR%20${d.total_overdue_amount}%20for%20${encodeURIComponent(d.student_name)}%20is%20overdue.%20Kindly%20settle.`}
                              target="_blank"
                              rel="noreferrer"
                              className="px-3 py-1 rounded-full bg-emerald-600 hover:bg-emerald-700 text-white text-[11px] font-semibold cursor-pointer"
                            >
                              WhatsApp
                            </a>
                          ) : (
                            <span className="text-[11px] text-slate-400">—</span>
                          )}
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        )}

        {/* =================================================================== */}
        {/* VIEW 7: PAY EXTRA FEE (Live Real-Time Counter)                     */}
        {/* =================================================================== */}
        {activeSubTab === 'pay-extra' && (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xs p-6 space-y-6">
            <div className="border-b border-slate-100 pb-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h3 className="text-base font-bold text-slate-800">Pay Extra & Miscellaneous Fees</h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Direct accounts counter collection for fines, exam re-tests, uniforms, books, and certificates with instant 3-part receipt.
                </p>
              </div>
            </div>

            {/* Student Search Bar */}
            <form onSubmit={handleSearchExtraStudent} className="flex flex-col sm:flex-row items-center gap-3 bg-slate-50 p-4 rounded-xl border border-slate-200">
              <div className="relative flex-1 w-full">
                <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Enter Student Admission No. or Name (e.g. ADM-101)..."
                  value={extraSearchText}
                  onChange={(e) => setExtraSearchText(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 rounded-lg border border-slate-200 bg-white text-xs font-medium text-slate-800 outline-none focus:border-teal-500"
                />
              </div>
              <button
                type="submit"
                disabled={extraSearching || !extraSearchText.trim()}
                className="w-full sm:w-auto px-6 py-2 rounded-lg bg-[#023E8A] hover:bg-[#001938] text-white font-bold text-xs transition cursor-pointer disabled:opacity-50"
              >
                {extraSearching ? 'Searching...' : 'Find Student'}
              </button>
            </form>

            {/* Student Profile Card (if found) */}
            {extraStudentProfile && (
              <div className="p-4 rounded-xl bg-teal-50/60 border border-teal-200 flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-teal-600 text-white flex items-center justify-center font-bold text-sm">
                    {extraStudentProfile.student.first_name?.[0] || 'S'}
                  </div>
                  <div>
                    <h4 className="font-bold text-slate-900 text-sm">{extraStudentProfile.student.student_name}</h4>
                    <p className="text-xs text-slate-500">
                      Adm No: <strong className="font-mono text-slate-800">{extraStudentProfile.student.admission_number}</strong> | Class: {extraStudentProfile.student.class_name} ({extraStudentProfile.student.section_name})
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-[11px] text-slate-500 block">Father / Contact:</span>
                  <strong className="text-xs text-slate-800">{extraStudentProfile.student.father_name || 'Guardian'} ({extraStudentProfile.student.emergency_phone || 'N/A'})</strong>
                </div>
              </div>
            )}

            {/* Extra Fee Form */}
            <form onSubmit={handleSubmitExtraFee} className="grid grid-cols-1 md:grid-cols-2 gap-4 pt-2">
              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-700">Fee Category / Head</label>
                <select
                  value={extraCategory}
                  onChange={(e) => setExtraCategory(e.target.value)}
                  className="w-full px-3 py-2 rounded-lg border border-slate-200 bg-white text-xs font-semibold text-slate-800 outline-none focus:border-teal-500"
                >
                  <option value="LATE FEE FINE">LATE FEE FINE</option>
                  <option value="EXAM RE-TEST FEE">EXAM RE-TEST FEE</option>
                  <option value="UNIFORM & ATTIRE KIT">UNIFORM & ATTIRE KIT</option>
                  <option value="BOOKS & NOTEBOOKS SET">BOOKS & NOTEBOOKS SET</option>
                  <option value="ID CARD REPLACEMENT">ID CARD REPLACEMENT</option>
                  <option value="ACTIVITY & CLUB CHARGES">ACTIVITY & CLUB CHARGES</option>
                  <option value="TC (TRANSFER CERTIFICATE) FEE">TC (TRANSFER CERTIFICATE) FEE</option>
                  <option value="MISCELLANEOUS CHARGES">MISCELLANEOUS CHARGES</option>
                </select>
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-700">Amount (₹)</label>
                <input
                  type="number"
                  min="1"
                  value={extraAmount}
                  onChange={(e) => setExtraAmount(e.target.value === '' ? '' : Number(e.target.value))}
                  placeholder="Enter amount in ₹"
                  className="w-full px-3 py-2 rounded-lg border border-slate-200 bg-white text-xs font-bold text-slate-800 outline-none focus:border-teal-500"
                />
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-700">Payment Mode</label>
                <div className="grid grid-cols-3 gap-2">
                  {(['CASH', 'UPI', 'CHEQUE'] as const).map((mode) => (
                    <button
                      key={mode}
                      type="button"
                      onClick={() => setExtraMode(mode)}
                      className={`py-2 rounded-lg text-xs font-bold transition border cursor-pointer ${
                        extraMode === mode
                          ? 'bg-slate-900 text-white border-slate-900 shadow-xs'
                          : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-50'
                      }`}
                    >
                      {mode}
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-1">
                <label className="text-xs font-bold text-slate-700">Remarks / Receipt Note</label>
                <input
                  type="text"
                  value={extraRemarks}
                  onChange={(e) => setExtraRemarks(e.target.value)}
                  placeholder="Optional remarks (e.g. Set of 2 summer uniforms)"
                  className="w-full px-3 py-2 rounded-lg border border-slate-200 bg-white text-xs font-medium text-slate-800 outline-none focus:border-teal-500"
                />
              </div>

              <div className="md:col-span-2 pt-4">
                <button
                  type="submit"
                  disabled={submittingExtra || !extraStudentProfile || !extraAmount}
                  className="w-full py-3 rounded-xl bg-[#10B981] hover:bg-[#059669] text-white font-extrabold text-sm transition shadow-sm cursor-pointer disabled:opacity-50"
                >
                  {submittingExtra ? 'Collecting & Generating Receipt...' : `Collect Extra Fee (₹${Number(extraAmount || 0).toLocaleString('en-IN')}) & Print Voucher`}
                </button>
              </div>
            </form>
          </div>
        )}

        {/* =================================================================== */}
        {/* VIEW 8: TRANSPORT FEE COLLECTION (Live Real-Time Counter)           */}
        {/* =================================================================== */}
        {activeSubTab === 'transport-collection' && (
          <div className="bg-white rounded-2xl border border-slate-200 shadow-xs p-6 space-y-6">
            <div className="border-b border-slate-100 pb-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h3 className="text-base font-bold text-slate-800">Transport Fee Collection</h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  Route-wise distance billing slabs, multi-month transport billing, and bus stop receipts.
                </p>
              </div>
              <span className="px-3 py-1 rounded-full bg-amber-50 border border-amber-200 text-amber-900 font-bold text-xs">
                Billing Mode: {transportHead.collection_method || 'Monthly'}
              </span>
            </div>

            {/* Student Search Bar */}
            <form onSubmit={handleSearchTransStudent} className="flex flex-col sm:flex-row items-center gap-3 bg-slate-50 p-4 rounded-xl border border-slate-200">
              <div className="relative flex-1 w-full">
                <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Enter Student Admission No. or Name..."
                  value={transSearchText}
                  onChange={(e) => setTransSearchText(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 rounded-lg border border-slate-200 bg-white text-xs font-medium text-slate-800 outline-none focus:border-teal-500"
                />
              </div>
              <button
                type="submit"
                disabled={transSearching || !transSearchText.trim()}
                className="w-full sm:w-auto px-6 py-2 rounded-lg bg-[#023E8A] hover:bg-[#001938] text-white font-bold text-xs transition cursor-pointer disabled:opacity-50"
              >
                {transSearching ? 'Searching...' : 'Find Student'}
              </button>
            </form>

            {transStudentProfile && (
              <div className="p-4 rounded-xl bg-indigo-50/60 border border-indigo-200 flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-indigo-600 text-white flex items-center justify-center font-bold text-sm">
                    <Bus className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="font-bold text-slate-900 text-sm">{transStudentProfile.student.student_name}</h4>
                    <p className="text-xs text-slate-500">
                      Adm No: <strong className="font-mono text-slate-800">{transStudentProfile.student.admission_number}</strong> | Class: {transStudentProfile.student.class_name}
                    </p>
                  </div>
                </div>
                <div className="text-right">
                  <span className="text-[11px] text-slate-500 block">Parent Phone:</span>
                  <strong className="text-xs text-slate-800">{transStudentProfile.student.emergency_phone || 'N/A'}</strong>
                </div>
              </div>
            )}

            <form onSubmit={handleSubmitTransFee} className="space-y-4 pt-2">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="space-y-1">
                  <label className="text-xs font-bold text-slate-700">Select Bus Route & Distance Slab</label>
                  <select
                    value={transRoute}
                    onChange={(e) => {
                      setTransRoute(e.target.value);
                      if (e.target.value.includes('₹800')) setTransRate(800);
                      else if (e.target.value.includes('₹1,200')) setTransRate(1200);
                      else if (e.target.value.includes('₹1,500')) setTransRate(1500);
                      else if (e.target.value.includes('₹2,000')) setTransRate(2000);
                    }}
                    className="w-full px-3 py-2 rounded-lg border border-slate-200 bg-white text-xs font-semibold text-slate-800 outline-none focus:border-teal-500"
                  >
                    <option value="Route 1: Civil Lines & Station (₹800/mo)">Route 1: Civil Lines & Station (₹800/mo)</option>
                    <option value="Route 2: City Center & Chowk (₹1,200/mo)">Route 2: City Center & Chowk (₹1,200/mo)</option>
                    <option value="Route 3: Highway Bypass & Cantt (₹1,500/mo)">Route 3: Highway Bypass & Cantt (₹1,500/mo)</option>
                    <option value="Route 4: Rural Outskirts & Feeder (₹2,000/mo)">Route 4: Rural Outskirts & Feeder (₹2,000/mo)</option>
                  </select>
                </div>

                <div className="space-y-1">
                  <label className="text-xs font-bold text-slate-700">Payment Mode</label>
                  <div className="grid grid-cols-3 gap-2">
                    {(['CASH', 'UPI', 'CHEQUE'] as const).map((mode) => (
                      <button
                        key={mode}
                        type="button"
                        onClick={() => setTransMode(mode)}
                        className={`py-2 rounded-lg text-xs font-bold transition border cursor-pointer ${
                          transMode === mode
                            ? 'bg-slate-900 text-white border-slate-900 shadow-xs'
                            : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-50'
                        }`}
                      >
                        {mode}
                      </button>
                    ))}
                  </div>
                </div>
              </div>

              {/* Month Multi-Select Pills */}
              <div className="space-y-1.5">
                <label className="text-xs font-bold text-slate-700 block">
                  Select Months to Pay ({transMonths.length} Months Selected)
                </label>
                <div className="flex flex-wrap gap-2">
                  {[
                    'APRIL',
                    'MAY',
                    'JUNE',
                    'JULY',
                    'AUGUST',
                    'SEPTEMBER',
                    'OCTOBER',
                    'NOVEMBER',
                    'DECEMBER',
                    'JANUARY',
                    'FEBRUARY',
                    'MARCH',
                  ].map((m) => {
                    const isSelected = transMonths.includes(m);
                    return (
                      <button
                        key={m}
                        type="button"
                        onClick={() => {
                          if (isSelected) {
                            setTransMonths(transMonths.filter((x) => x !== m));
                          } else {
                            setTransMonths([...transMonths, m]);
                          }
                        }}
                        className={`px-3 py-1.5 rounded-full text-xs font-bold transition cursor-pointer border ${
                          isSelected
                            ? 'bg-teal-600 text-white border-teal-600 shadow-xs'
                            : 'bg-slate-50 text-slate-600 border-slate-200 hover:bg-slate-100'
                        }`}
                      >
                        {m}
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Live Calculation Banner */}
              <div className="p-4 rounded-xl bg-slate-900 text-white flex flex-col sm:flex-row items-center justify-between gap-3">
                <div>
                  <span className="text-xs text-slate-300 block">
                    Formula: {transMonths.length} Months × ₹{transRate}/mo:
                  </span>
                  <strong className="text-2xl text-teal-300">
                    ₹{(transMonths.length * transRate).toLocaleString('en-IN')}
                  </strong>
                </div>

                <button
                  type="submit"
                  disabled={submittingTrans || !transStudentProfile || transMonths.length === 0}
                  className="px-8 py-2.5 rounded-full bg-[#10B981] hover:bg-[#059669] text-white font-extrabold text-xs transition shadow-sm cursor-pointer disabled:opacity-50"
                >
                  {submittingTrans ? 'Collecting...' : 'Collect Transport Fee & Print Receipt'}
                </button>
              </div>
            </form>
          </div>
        )}
      </div>

      {/* =================================================================== */}
      {/* BOTTOM FOOTER STATUS BAR (Exact from image footer)                 */}
      {/* =================================================================== */}
      <footer className="w-full bg-[#E5E9F0] border-t border-slate-300/80 px-4 py-2 text-[11px] font-semibold text-slate-600 flex flex-col sm:flex-row items-center justify-between gap-2 shadow-2xs">
        <div className="flex items-center gap-2">
          <span className="font-bold text-slate-900 uppercase tracking-tight">
            {branding.name}
          </span>
          <span className="text-slate-400">|</span>
          <span>Logged in User : <strong className="text-rose-700">ACC OFFICE</strong></span>
          <span className="text-slate-400">|</span>
          <span>Session : <strong className="text-slate-800">2026-2027</strong></span>
          <span className="text-slate-400">|</span>
          <span className="text-slate-500 font-medium">Powered by <strong className="text-slate-900 font-bold">{branding.platformBrand || 'SAMAGRA'}</strong></span>
        </div>

        <div className="text-slate-500 font-mono text-[11px]">
          Thursday, 5 November 2026, {currentTime}
        </div>
      </footer>

      {/* =================================================================== */}
      {/* MODAL: COLLECT FEE                                                  */}
      {/* =================================================================== */}
      {collectModalOpen && collectStudent && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="font-bold text-slate-900 text-sm">Record Fee Payment (Smart POS)</h3>
              <button onClick={() => setCollectModalOpen(false)} className="p-1 text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-3 rounded-xl bg-slate-50 text-xs space-y-1">
              <div className="flex justify-between">
                <span className="text-slate-500">Student:</span>
                <strong className="text-slate-900">{collectStudent.student_name}</strong>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Admission No:</span>
                <span className="font-mono">{collectStudent.admission_number}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Head:</span>
                <span className="font-semibold text-teal-700">{collectStudent.fee_title}</span>
              </div>
              <div className="flex justify-between border-t border-slate-200 pt-1">
                <span className="text-slate-500">Balance:</span>
                <strong className="text-rose-600">₹{Number(collectStudent.balance).toLocaleString('en-IN')}</strong>
              </div>
            </div>

            <form onSubmit={handleCollectSubmit} className="space-y-3">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase mb-1">Amount (₹) *</label>
                <input
                  type="number"
                  min="1"
                  required
                  value={collectAmount}
                  onChange={(e) => setCollectAmount(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl border border-slate-300 text-sm font-bold text-slate-900"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase mb-1">Payment Mode</label>
                <select
                  value={paymentMode}
                  onChange={(e) => setPaymentMode(e.target.value as any)}
                  className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs bg-white font-semibold"
                >
                  <option value="CASH">Cash</option>
                  <option value="ONLINE">Online (UPI / QR Code)</option>
                  <option value="CHEQUE">Cheque</option>
                  <option value="BANK_TRANSFER">Bank NEFT/RTGS</option>
                </select>
              </div>

              {paymentMode === 'CHEQUE' ? (
                <div className="p-3 bg-amber-50/60 border border-amber-200 rounded-xl space-y-2 text-xs">
                  <div className="font-bold text-amber-900 text-[11px] uppercase">Cheque Details</div>
                  <div className="grid grid-cols-2 gap-2">
                    <div>
                      <label className="block text-[10px] text-slate-600 mb-0.5">Cheque Number *</label>
                      <input
                        type="text"
                        required
                        placeholder="6-digit cheque #"
                        value={chequeNumber}
                        onChange={(e) => setChequeNumber(e.target.value)}
                        className="w-full px-2.5 py-1.5 rounded-lg border border-slate-300 text-xs bg-white"
                      />
                    </div>
                    <div>
                      <label className="block text-[10px] text-slate-600 mb-0.5">Bank Name *</label>
                      <input
                        type="text"
                        required
                        placeholder="e.g. SBI, HDFC"
                        value={chequeBank}
                        onChange={(e) => setChequeBank(e.target.value)}
                        className="w-full px-2.5 py-1.5 rounded-lg border border-slate-300 text-xs bg-white"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-[10px] text-slate-600 mb-0.5">Cheque Date</label>
                    <input
                      type="date"
                      value={chequeDate}
                      onChange={(e) => setChequeDate(e.target.value)}
                      className="w-full px-2.5 py-1.5 rounded-lg border border-slate-300 text-xs bg-white"
                    />
                  </div>
                </div>
              ) : (
                <div>
                  <label className="block text-xs font-bold text-slate-700 uppercase mb-1">
                    Reference / UTR / Transaction No
                  </label>
                  <input
                    type="text"
                    placeholder="Optional transaction reference"
                    value={transactionRef}
                    onChange={(e) => setTransactionRef(e.target.value)}
                    className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs"
                  />
                </div>
              )}

              <div className="pt-2 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setCollectModalOpen(false)}
                  className="px-4 py-2 rounded-xl border border-slate-200 text-xs text-slate-600"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submittingPayment}
                  className="px-5 py-2 rounded-xl bg-[#10B981] hover:bg-[#059669] text-white text-xs font-bold"
                >
                  {submittingPayment ? 'Processing...' : 'Collect & Issue Receipt'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =================================================================== */}
      {/* MODAL: VIEW / PRINT RECEIPT SLIP                                    */}
      {/* =================================================================== */}
      {activeReceiptModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 space-y-4 font-sans text-xs">
            <div className="border border-slate-300 rounded-xl p-5 bg-slate-50/50 space-y-4">
              <div className="text-center border-b border-slate-200 pb-3">
                <div className="text-sm font-bold text-slate-900 uppercase">
                  SANSKAR GLOBAL SCHOOL / SAMAGRA PLATFORM
                </div>
                <div className="text-[10px] text-slate-500">Official Fee Payment Receipt</div>
                <div className="text-xs font-mono font-bold text-teal-700 mt-1">
                  Receipt No: {activeReceiptModal.receipt_number}
                </div>
              </div>

              <div className="grid grid-cols-2 gap-2 text-[11px]">
                <div>
                  <span className="text-slate-400 block">Date:</span>
                  <strong>{activeReceiptModal.payment_date}</strong>
                </div>
                <div>
                  <span className="text-slate-400 block">Mode:</span>
                  <strong>{activeReceiptModal.payment_mode}</strong>
                </div>
                <div>
                  <span className="text-slate-400 block">Student:</span>
                  <strong>{activeReceiptModal.student_name}</strong>
                </div>
                <div>
                  <span className="text-slate-400 block">Admission No:</span>
                  <span className="font-mono">{activeReceiptModal.admission_number}</span>
                </div>
              </div>

              <div className="p-3 rounded-lg bg-emerald-50 border border-emerald-200 flex items-center justify-between">
                <span className="font-bold text-emerald-900">Amount Received:</span>
                <span className="text-base font-bold text-emerald-700">
                  ₹{Number(activeReceiptModal.amount_paid).toLocaleString('en-IN')}
                </span>
              </div>
            </div>

            <div className="flex items-center justify-between">
              <button
                onClick={() => window.print()}
                className="px-4 py-2 rounded-xl bg-slate-900 text-white text-xs font-bold cursor-pointer"
              >
                Print Slip
              </button>
              <button
                onClick={() => setActiveReceiptModal(null)}
                className="px-4 py-2 rounded-xl border border-slate-200 text-xs text-slate-700"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* =================================================================== */}
      {/* MODAL: 3-PART OFFICIAL PRINTABLE FEE VOUCHER (School / Student / Bank) */}
      {/* =================================================================== */}
      {threePartReceipt && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4 overflow-y-auto">
          <div className="bg-white rounded-2xl max-w-4xl w-full p-6 shadow-2xl border border-slate-200 space-y-4 my-8">
            <div className="flex items-center justify-between border-b border-slate-200 pb-3">
              <div>
                <h3 className="font-extrabold text-slate-900 text-base">Official 3-Part Fee Payment Voucher</h3>
                <span className="text-xs text-slate-500 font-mono">
                  Receipt #{threePartReceipt.receipt_number} • Date: {threePartReceipt.payment_date}
                </span>
              </div>
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => window.print()}
                  className="px-4 py-1.5 rounded-full bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-bold transition flex items-center gap-1.5 cursor-pointer shadow-xs"
                >
                  <Printer className="w-3.5 h-3.5" /> Print 3-Part Voucher
                </button>
                <button
                  type="button"
                  onClick={() => setThreePartReceipt(null)}
                  className="p-1.5 rounded-full hover:bg-slate-100 text-slate-400 hover:text-slate-600"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
            </div>

            {/* Printable 3-Part Container (School Copy, Student Copy, Bank Copy) */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 divide-y md:divide-y-0 md:divide-x divide-slate-200 text-xs font-sans">
              {(['SCHOOL COPY', 'STUDENT COPY', 'ACCOUNTS / BANK COPY'] as const).map((copyType, idx) => (
                <div key={copyType} className={`${idx > 0 ? 'pt-4 md:pt-0 md:pl-4' : ''} space-y-3`}>
                  {/* Voucher Header */}
                  <div className="text-center border-b border-slate-200 pb-2">
                    <div className="text-[10px] font-bold tracking-widest text-emerald-800 uppercase bg-emerald-50 py-0.5 rounded">
                      {copyType}
                    </div>
                    <div className="font-extrabold text-slate-900 text-xs mt-1 uppercase">
                      {branding.name}
                    </div>
                    <div className="text-[9px] text-slate-500">{branding.address || branding.affiliation}</div>
                    <div className="text-[8px] text-teal-800 font-semibold tracking-wide">
                      ⚡ Powered by {branding.platformBrand || 'SAMAGRA'}
                    </div>
                    <div className="text-[10px] font-mono font-bold text-teal-700 mt-0.5">
                      Rec: {threePartReceipt.receipt_number}
                    </div>
                  </div>

                  {/* Student & Payment Metadata */}
                  <div className="space-y-1 text-[11px]">
                    <div className="flex justify-between">
                      <span className="text-slate-500">Date:</span>
                      <strong className="text-slate-800">{threePartReceipt.payment_date}</strong>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Student:</span>
                      <strong className="text-slate-900">{threePartReceipt.student_name}</strong>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Adm No:</span>
                      <span className="font-mono">{threePartReceipt.admission_number}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Class:</span>
                      <span>Class {threePartReceipt.class_name} ({threePartReceipt.section_name})</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Mode:</span>
                      <span className="font-semibold text-slate-800">{threePartReceipt.payment_mode}</span>
                    </div>
                    {threePartReceipt.cheque_number && (
                      <div className="flex justify-between text-[10px] text-amber-800 bg-amber-50 p-1 rounded">
                        <span>Chq #{threePartReceipt.cheque_number}</span>
                        <span>{threePartReceipt.cheque_bank}</span>
                      </div>
                    )}
                  </div>

                  {/* Line Items Table */}
                  <div className="border border-slate-200 rounded-lg overflow-hidden text-[10px]">
                    <table className="w-full text-left">
                      <thead className="bg-slate-100 font-bold text-slate-600">
                        <tr>
                          <th className="p-1 pl-2">Fee Head</th>
                          <th className="p-1 pr-2 text-right">Amount</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {threePartReceipt.items?.map((item: any) => (
                          <tr key={item.id}>
                            <td className="p-1 pl-2 text-slate-800">{item.fee_head_name}</td>
                            <td className="p-1 pr-2 text-right font-semibold text-slate-900">
                              ₹{Number(item.net_paid).toLocaleString('en-IN')}
                            </td>
                          </tr>
                        ))}
                      </tbody>
                      <tfoot className="bg-emerald-50 font-bold border-t border-slate-200 text-emerald-950">
                        <tr>
                          <td className="p-1.5 pl-2">TOTAL PAID:</td>
                          <td className="p-1.5 pr-2 text-right text-xs">
                            ₹{Number(threePartReceipt.amount_paid).toLocaleString('en-IN')}
                          </td>
                        </tr>
                      </tfoot>
                    </table>
                  </div>

                  {/* Signatures */}
                  <div className="pt-6 flex justify-between items-end text-[9px] text-slate-400">
                    <div>
                      <span>Cashier: <strong>ACC OFFICE</strong></span>
                    </div>
                    <div className="border-t border-slate-400 pt-0.5 text-center w-20">
                      Authorised Sign
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}

      {/* =================================================================== */}
      {/* MODAL: 1-CLICK CHEQUE BOUNCE / DISHONOUR REVERSAL                   */}
      {/* =================================================================== */}
      {bouncingReceipt && (
        <div className="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="font-bold text-rose-900 text-sm flex items-center gap-1.5">
                <AlertTriangle className="w-4 h-4 text-rose-600" /> Mark Cheque Dishonoured / Bounced
              </h3>
              <button onClick={() => setBouncingReceipt(null)} className="p-1 text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-900 space-y-1">
              <div>Receipt No: <strong>{bouncingReceipt.receipt_number}</strong></div>
              <div>Student: <strong>{bouncingReceipt.student_name}</strong></div>
              <div>Amount to Reverse: <strong>₹{Number(bouncingReceipt.amount_paid).toLocaleString('en-IN')}</strong></div>
              <div className="text-[11px] text-rose-700 pt-1">
                This will automatically cancel the receipt, restore student unpaid dues, and append a penalty fine.
              </div>
            </div>

            <form onSubmit={handleMarkChequeBounceSubmit} className="space-y-3">
              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase mb-1">
                  Bank Bounce Penalty (₹)
                </label>
                <input
                  type="number"
                  min="0"
                  value={bouncePenalty}
                  onChange={(e) => setBouncePenalty(Number(e.target.value))}
                  className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs font-bold"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-slate-700 uppercase mb-1">
                  Dishonour Reason *
                </label>
                <input
                  type="text"
                  required
                  value={bounceReason}
                  onChange={(e) => setBounceReason(e.target.value)}
                  className="w-full px-3 py-2 rounded-xl border border-slate-300 text-xs"
                />
              </div>

              <div className="pt-2 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setBouncingReceipt(null)}
                  className="px-4 py-2 rounded-xl border border-slate-200 text-xs text-slate-600"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submittingBounce}
                  className="px-5 py-2 rounded-xl bg-rose-600 hover:bg-rose-500 text-white text-xs font-bold cursor-pointer"
                >
                  {submittingBounce ? 'Reversing...' : 'Confirm Dishonour & Restore Dues'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* =================================================================== */}
      {/* MODAL: COUNTER SHIFT DAY-BOOK CLOSING & DENOMINATIONS               */}
      {/* =================================================================== */}
      {shiftModalOpen && currentShiftData && (
        <div className="fixed inset-0 z-50 bg-slate-900/50 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="font-bold text-slate-900 text-sm flex items-center gap-1.5">
                <Activity className="w-4 h-4 text-emerald-600" /> Counter Shift Day-Book Closing
              </h3>
              <button onClick={() => setShiftModalOpen(false)} className="p-1 text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>

            <div className="grid grid-cols-3 gap-2 text-center text-xs">
              <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200">
                <span className="text-[10px] text-slate-500 block">System Cash</span>
                <strong className="text-sm text-emerald-700">
                  ₹{Number(currentShiftData.system_cash_total || 0).toLocaleString('en-IN')}
                </strong>
              </div>
              <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200">
                <span className="text-[10px] text-slate-500 block">System UPI</span>
                <strong className="text-sm text-indigo-700">
                  ₹{Number(currentShiftData.system_upi_total || 0).toLocaleString('en-IN')}
                </strong>
              </div>
              <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200">
                <span className="text-[10px] text-slate-500 block">System Cheques</span>
                <strong className="text-sm text-amber-700">
                  ₹{Number(currentShiftData.system_cheque_total || 0).toLocaleString('en-IN')}
                </strong>
              </div>
            </div>

            <form onSubmit={handleCloseShiftSubmit} className="space-y-3 text-xs">
              <div>
                <label className="block text-[11px] font-bold text-slate-700 uppercase mb-1">
                  Cash Physical Currency Notes Count (Tally):
                </label>
                <div className="grid grid-cols-2 sm:grid-cols-3 gap-2">
                  {['500', '200', '100', '50', '20', '10'].map((denom) => (
                    <div key={denom} className="flex items-center gap-1.5 p-1.5 rounded-lg border border-slate-200 bg-slate-50">
                      <span className="font-bold text-slate-700 w-12 text-[11px]">₹{denom} x</span>
                      <input
                        type="number"
                        min="0"
                        value={denominations[denom] || 0}
                        onChange={(e) =>
                          setDenominations((prev) => ({
                            ...prev,
                            [denom]: Math.max(0, parseInt(e.target.value) || 0),
                          }))
                        }
                        className="w-full px-2 py-1 rounded bg-white border border-slate-300 text-xs font-bold text-center"
                      />
                    </div>
                  ))}
                </div>
              </div>

              {/* Tally calculation */}
              {(() => {
                const totalPhysical = Object.entries(denominations).reduce(
                  (sum, [denom, count]) => sum + Number(denom) * Number(count || 0),
                  0
                );
                const variance = totalPhysical - Number(currentShiftData.system_cash_total || 0);
                return (
                  <div className="p-3 rounded-xl bg-slate-100 flex items-center justify-between text-xs">
                    <div>
                      <span className="text-slate-500 block">Physical Count Total:</span>
                      <strong className="text-base text-slate-900">₹{totalPhysical.toLocaleString('en-IN')}</strong>
                    </div>
                    <div className="text-right">
                      <span className="text-slate-500 block">Variance (Diff):</span>
                      <strong className={`text-base ${variance === 0 ? 'text-emerald-600' : 'text-rose-600'}`}>
                        {variance === 0 ? 'Exact Match (₹0)' : `₹${variance > 0 ? '+' : ''}${variance.toLocaleString('en-IN')}`}
                      </strong>
                    </div>
                  </div>
                );
              })()}

              <div>
                <label className="block text-[10px] text-slate-600 uppercase mb-1">Closing Remarks / Vault Deposit</label>
                <input
                  type="text"
                  placeholder="Optional notes for accountant"
                  value={shiftClosingNotes}
                  onChange={(e) => setShiftClosingNotes(e.target.value)}
                  className="w-full px-3 py-1.5 rounded-xl border border-slate-300 text-xs"
                />
              </div>

              <div className="pt-2 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShiftModalOpen(false)}
                  className="px-4 py-2 rounded-xl border border-slate-200 text-xs text-slate-600"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={submittingShiftClose}
                  className="px-5 py-2 rounded-xl bg-slate-900 hover:bg-slate-800 text-white text-xs font-bold cursor-pointer"
                >
                  {submittingShiftClose ? 'Reconciling...' : 'Reconcile & Close Shift'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
      {activityLogsModalOpen && (
        <div className="fixed inset-0 z-50 bg-slate-900/40 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center justify-between border-b border-slate-100 pb-3">
              <h3 className="font-bold text-slate-900 text-sm">Fee Heads Activity Log</h3>
              <button onClick={() => setActivityLogsModalOpen(false)} className="p-1 text-slate-400 hover:text-slate-600">
                <X className="w-4 h-4" />
              </button>
            </div>
            <div className="space-y-2 text-xs text-slate-600 max-h-60 overflow-y-auto">
              <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-between">
                <span>Fee Heads Definition updated by <strong>ACC OFFICE</strong></span>
                <span className="text-[10px] text-slate-400">Just now</span>
              </div>
              <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-between">
                <span>Head 1 set to <strong>LAST YEAR DUE</strong></span>
                <span className="text-[10px] text-slate-400">Today, 11:15 AM</span>
              </div>
              <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-100 flex items-center justify-between">
                <span>Head 2 set to <strong>ADMISSION FEE</strong></span>
                <span className="text-[10px] text-slate-400">Today, 11:15 AM</span>
              </div>
            </div>
            <div className="flex justify-end pt-2">
              <button
                onClick={() => setActivityLogsModalOpen(false)}
                className="px-4 py-1.5 rounded-xl bg-slate-900 text-white text-xs font-semibold"
              >
                Close
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
