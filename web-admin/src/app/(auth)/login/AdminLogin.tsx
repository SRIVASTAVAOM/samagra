'use client';

import React, { useState } from 'react';
import Image from 'next/image';
import { useRouter } from 'next/navigation';
import {
  AlertCircle,
  Eye,
  EyeOff,
  Users,
  ShieldCheck,
  TrendingUp,
  Bell,
  School,
  BookOpen,
  GraduationCap,
  BarChart2,
  Home,
} from 'lucide-react';
import { api, setSession } from '@/lib/api';
import ForgotPasswordModal from './ForgotPasswordModal';
import './AdminLogin.css';

// ─── Configurable school branding ────────────────────────────────────────────
const SCHOOL_NAME = 'Little Angels Public School';
const SCHOOL_TAGLINE = 'Learn • Grow • Lead';
// Use /school-logo.png if you place a custom school logo in public/
// Falls back to logo-icon.png (the SAMAGRA icon) if no dedicated school logo exists.
const SCHOOL_LOGO_SRC = '/logo-icon.png';
// ─────────────────────────────────────────────────────────────────────────────

const FEATURE_CARDS = [
  {
    icon: Users,
    iconColor: '#2563eb',
    iconBg: '#dbeafe',
    title: 'Unified Access',
    desc: 'One login for all roles.',
  },
  {
    icon: ShieldCheck,
    iconColor: '#16a34a',
    iconBg: '#dcfce7',
    title: 'Secure & Reliable',
    desc: 'Your data is always safe.',
  },
  {
    icon: TrendingUp,
    iconColor: '#7c3aed',
    iconBg: '#ede9fe',
    title: 'Smart Insights',
    desc: 'AI-powered decisions.',
  },
  {
    icon: Bell,
    iconColor: '#d97706',
    iconBg: '#fef3c7',
    title: 'Real-time Updates',
    desc: 'Stay informed, always.',
  },
];

// Decorative background icons (educational theme)
const BG_ICONS = [
  { Icon: GraduationCap, top: '10%', left: '8%', size: 28, opacity: 0.13 },
  { Icon: BookOpen,       top: '22%', left: '78%', size: 22, opacity: 0.11 },
  { Icon: BarChart2,      top: '50%', left: '68%', size: 24, opacity: 0.10 },
  { Icon: School,         top: '70%', left: '5%',  size: 26, opacity: 0.12 },
  { Icon: GraduationCap, top: '80%', left: '55%', size: 20, opacity: 0.09 },
  { Icon: BookOpen,       top: '38%', left: '4%',  size: 20, opacity: 0.10 },
];

export default function AdminLogin() {
  const router = useRouter();
  const [identifier, setIdentifier] = useState('admin');
  const [password, setPassword] = useState('Password@123');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);
  const [isForgotOpen, setIsForgotOpen] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setInfo(null);
    setLoading(true);

    try {
      const data = await api.auth.login(identifier.trim(), password);
      const userRoles = data.user.roles || [];
      const isAllowed = userRoles.some((r: string) =>
        ['SUPER_ADMIN', 'ADMIN', 'TEACHER'].includes(r)
      );

      if (!isAllowed) {
        setError('Access Restricted: Student accounts should log in via the School Mobile App.');
        setLoading(false);
        return;
      }

      setSession(data.token, data.user);
      if (userRoles.includes('SUPER_ADMIN')) {
        router.push('/super-admin');
      } else {
        router.push('/dashboard');
      }
    } catch (err) {
      setError(
        (err instanceof Error && err.message) || 'Login failed. Please check your credentials.'
      );
      setLoading(false);
    }
  };

  return (
    <div className="aln-root">
      {/* ── Header ────────────────────────────────────────────────────────── */}
      <header className="aln-header">
        {/* Left: School branding */}
        <div className="aln-header-school">
          <Image
            src={SCHOOL_LOGO_SRC}
            alt={`${SCHOOL_NAME} Logo`}
            width={44}
            height={44}
            className="aln-school-logo"
            priority
          />
          <div className="aln-school-text">
            <span className="aln-school-name">{SCHOOL_NAME}</span>
            <span className="aln-school-tagline">{SCHOOL_TAGLINE}</span>
          </div>
        </div>

        {/* Right: SAMAGRA branding */}
        <div className="aln-header-samagra">
          <Image
            src="/samagra-logo.jpg"
            alt="Samagra – The Complete School Platform"
            width={130}
            height={50}
            className="aln-samagra-logo"
            priority
          />
        </div>
      </header>

      {/* ── Main body ─────────────────────────────────────────────────────── */}
      <main className="aln-main">
        {/* ── Left panel ──────────────────────────────────────────────────── */}
        <section className="aln-left" aria-label="Platform information">
          {/* Decorative background icons */}
          <div className="aln-bg-icons" aria-hidden="true">
            {BG_ICONS.map(({ Icon, top, left, size, opacity }, i) => (
              <span
                key={i}
                className="aln-bg-icon"
                style={{ top, left, opacity }}
              >
                <Icon size={size} />
              </span>
            ))}
          </div>

          {/* Hero heading */}
          <div className="aln-hero">
            <h1 className="aln-hero-title">{SCHOOL_NAME}</h1>
            <p className="aln-hero-subtitle">
              Empowering schools with AI-powered tools to simplify operations and enhance learning.
            </p>
          </div>

          {/* Feature cards */}
          <div className="aln-features" role="list">
            {FEATURE_CARDS.map(({ icon: Icon, iconColor, iconBg, title, desc }) => (
              <div key={title} className="aln-feature-card" role="listitem">
                <span
                  className="aln-feature-icon"
                  style={{ color: iconColor, background: iconBg }}
                  aria-hidden="true"
                >
                  <Icon size={20} />
                </span>
                <span className="aln-feature-title">{title}</span>
                <span className="aln-feature-desc">{desc}</span>
              </div>
            ))}
          </div>

          {/* Bottom row: illustration + quote */}
          <div className="aln-bottom-row">
            {/* School illustration (SVG inline for zero-dependency) */}
            <div className="aln-illustration" aria-hidden="true">
              <svg
                viewBox="0 0 200 160"
                xmlns="http://www.w3.org/2000/svg"
                className="aln-school-svg"
              >
                {/* Sky */}
                <rect x="0" y="0" width="200" height="160" fill="none" />
                {/* Ground */}
                <rect x="0" y="128" width="200" height="32" rx="4" fill="#d1e9c8" />
                {/* Main building */}
                <rect x="30" y="60" width="100" height="70" rx="4" fill="#3b82f6" />
                <rect x="30" y="60" width="100" height="70" rx="4" fill="url(#bwall)" />
                {/* Roof */}
                <polygon points="25,60 130,60 77,28" fill="#1e40af" />
                {/* Flag pole */}
                <line x1="77" y1="28" x2="77" y2="10" stroke="#374151" strokeWidth="2" />
                {/* Flag */}
                <polygon points="77,10 97,16 77,22" fill="#ef4444" />
                {/* Clock circle */}
                <circle cx="77" cy="52" r="10" fill="white" stroke="#1e40af" strokeWidth="1.5" />
                <line x1="77" y1="52" x2="77" y2="45" stroke="#1e40af" strokeWidth="1.5" strokeLinecap="round" />
                <line x1="77" y1="52" x2="82" y2="52" stroke="#1e40af" strokeWidth="1.5" strokeLinecap="round" />
                {/* Door */}
                <rect x="65" y="98" width="22" height="32" rx="3" fill="#1d4ed8" />
                <circle cx="83" cy="115" r="1.5" fill="white" />
                {/* Windows row */}
                <rect x="38" y="74" width="18" height="14" rx="2" fill="#bfdbfe" />
                <rect x="62" y="74" width="18" height="14" rx="2" fill="#bfdbfe" />
                <rect x="86" y="74" width="18" height="14" rx="2" fill="#bfdbfe" />
                <rect x="110" y="74" width="14" height="14" rx="2" fill="#bfdbfe" />
                {/* Left wing */}
                <rect x="8" y="88" width="24" height="42" rx="3" fill="#60a5fa" />
                <rect x="12" y="96" width="10" height="10" rx="1" fill="#bfdbfe" />
                {/* Right wing */}
                <rect x="128" y="88" width="24" height="42" rx="3" fill="#60a5fa" />
                <rect x="138" y="96" width="10" height="10" rx="1" fill="#bfdbfe" />
                {/* Trees */}
                <circle cx="170" cy="120" r="14" fill="#22c55e" />
                <rect x="168" y="128" width="4" height="12" fill="#854d0e" />
                <circle cx="185" cy="122" r="10" fill="#16a34a" />
                <rect x="183" y="128" width="3" height="10" fill="#854d0e" />
                <circle cx="20" cy="122" r="12" fill="#22c55e" />
                <rect x="18" y="128" width="4" height="10" fill="#854d0e" />
                <defs>
                  <linearGradient id="bwall" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#3b82f6" />
                    <stop offset="100%" stopColor="#2563eb" />
                  </linearGradient>
                </defs>
              </svg>
            </div>

            {/* Mandela quote */}
            <blockquote className="aln-quote">
              <span className="aln-quote-mark" aria-hidden="true">"</span>
              <p className="aln-quote-text">
                Education is the most powerful weapon which you can use to change the world.
              </p>
              <footer className="aln-quote-author">— Nelson Mandela</footer>
            </blockquote>
          </div>
        </section>

        {/* ── Right panel: login card ──────────────────────────────────────── */}
        <section className="aln-right" aria-label="Sign in">
          <div className="aln-login-card">
            {/* Card header */}
            <div className="aln-card-header">
              <span className="aln-card-icon" aria-hidden="true">
                <ShieldCheck size={22} />
              </span>
              <div>
                <h2 className="aln-card-title">Welcome back!</h2>
                <p className="aln-card-subtitle">Sign in to access your dashboard.</p>
              </div>
            </div>

            {/* Error / info banners */}
            {error && (
              <div className="aln-alert" role="alert">
                <AlertCircle size={15} className="aln-alert-icon" aria-hidden="true" />
                <span>{error}</span>
              </div>
            )}
            {info && (
              <div className="aln-info" role="status">
                {info}
              </div>
            )}

            {/* Login form */}
            <form onSubmit={handleSubmit} className="aln-form" noValidate>
              {/* Login ID */}
              <div className="aln-field-group">
                <label htmlFor="aln-identifier" className="aln-label">
                  Login ID
                </label>
                <div className="aln-field">
                  <span className="aln-field-prefix" aria-hidden="true">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                      <circle cx="12" cy="7" r="4" />
                    </svg>
                  </span>
                  <input
                    id="aln-identifier"
                    type="text"
                    required
                    autoComplete="username"
                    value={identifier}
                    onChange={(e) => setIdentifier(e.target.value)}
                    placeholder="ADM202600001"
                    className="aln-input aln-input-with-prefix"
                  />
                </div>
              </div>

              {/* Password */}
              <div className="aln-field-group">
                <label htmlFor="aln-password" className="aln-label">
                  Password
                </label>
                <div className="aln-field">
                  <span className="aln-field-prefix" aria-hidden="true">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <rect x="3" y="11" width="18" height="11" rx="2" ry="2" />
                      <path d="M7 11V7a5 5 0 0 1 10 0v4" />
                    </svg>
                  </span>
                  <input
                    id="aln-password"
                    type={showPassword ? 'text' : 'password'}
                    required
                    autoComplete="current-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    className="aln-input aln-input-with-prefix aln-input-with-suffix"
                  />
                  <button
                    type="button"
                    className="aln-eye-btn"
                    onClick={() => setShowPassword((prev) => !prev)}
                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                    aria-pressed={showPassword}
                  >
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    <span className="aln-sr-only">{showPassword ? 'Hide' : 'Show'}</span>
                  </button>
                </div>
              </div>

              {/* Forgot password */}
              <div className="aln-forgot">
                <button
                  type="button"
                  className="aln-link"
                  onClick={() => {
                    setError(null);
                    setInfo(null);
                    setIsForgotOpen(true);
                  }}
                >
                  Forgot Password?
                </button>
              </div>

              {/* Sign in button */}
              <button
                type="submit"
                disabled={loading}
                className="aln-submit-btn"
              >
                {loading ? (
                  <span className="aln-spinner" aria-hidden="true" />
                ) : null}
                {loading ? 'Signing in…' : 'Sign in'}
              </button>
            </form>

            {/* Back to home */}
            <div className="aln-back-home">
              <Home size={14} aria-hidden="true" />
              <a href="/" className="aln-link">
                Back to home
              </a>
            </div>

            {/* Quick-test presets (dev helper) */}
            <div className="aln-presets">
              <span>Quick test:</span>
              <button
                type="button"
                className="aln-link aln-preset-super"
                onClick={() => {
                  setIdentifier('superadmin');
                  setPassword('Password@123');
                  setError(null);
                  setInfo(null);
                }}
              >
                Super Admin
              </button>
              <span aria-hidden="true">·</span>
              <button
                type="button"
                className="aln-link aln-preset-admin"
                onClick={() => {
                  setIdentifier('admin');
                  setPassword('Password@123');
                  setError(null);
                  setInfo(null);
                }}
              >
                School Admin
              </button>
            </div>
          </div>

          {/* ── Stats strip ───────────────────────────────────────────────── */}
          <div className="aln-stats" role="list" aria-label="Platform statistics">
            <div className="aln-stat" role="listitem">
              <span className="aln-stat-icon" style={{ color: '#2563eb', background: '#dbeafe' }} aria-hidden="true">
                <School size={18} />
              </span>
              <div>
                <span className="aln-stat-value">500+</span>
                <span className="aln-stat-label">Schools</span>
              </div>
            </div>
            <div className="aln-stat" role="listitem">
              <span className="aln-stat-icon" style={{ color: '#16a34a', background: '#dcfce7' }} aria-hidden="true">
                <Users size={18} />
              </span>
              <div>
                <span className="aln-stat-value">50K+</span>
                <span className="aln-stat-label">Users</span>
              </div>
            </div>
            <div className="aln-stat" role="listitem">
              <span className="aln-stat-icon" style={{ color: '#d97706', background: '#fef3c7' }} aria-hidden="true">
                <BookOpen size={18} />
              </span>
              <div>
                <span className="aln-stat-value">1M+</span>
                <span className="aln-stat-label">Students</span>
              </div>
            </div>
            <div className="aln-stat" role="listitem">
              <span className="aln-stat-icon" style={{ color: '#7c3aed', background: '#ede9fe' }} aria-hidden="true">
                <BarChart2 size={18} />
              </span>
              <div>
                <span className="aln-stat-value">99.9%</span>
                <span className="aln-stat-label">Uptime</span>
              </div>
            </div>
          </div>
        </section>
      </main>

      {/* ── Footer ────────────────────────────────────────────────────────── */}
      <footer className="aln-footer">
        <span className="aln-footer-left">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" style={{ display: 'inline', verticalAlign: 'middle', marginRight: 4 }}>
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
          </svg>
          Built with passion for schools by Kushagra Saxena
        </span>
        <span className="aln-footer-mid">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" style={{ display: 'inline', verticalAlign: 'middle', marginRight: 4 }}>
            <polyline points="16 18 22 12 16 6" />
            <polyline points="8 6 2 12 8 18" />
          </svg>
          React Frontend | Existing API &amp; functionality unchanged
        </span>
        <span className="aln-footer-right">© 2026 SAMAGRA. All rights reserved.</span>
      </footer>

      {/* Forgot Password Modal – unchanged */}
      <ForgotPasswordModal
        isOpen={isForgotOpen}
        onClose={() => setIsForgotOpen(false)}
        initialIdentifier={identifier}
        onSuccess={(resetId, newPass) => {
          setIdentifier(resetId);
          setPassword(newPass);
          setError(null);
          setInfo(`Password successfully updated for ${resetId}! Click Sign in to proceed.`);
        }}
      />
    </div>
  );
}
