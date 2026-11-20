'use client';

import React, { useState } from 'react';
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
const SCHOOL_NAME    = 'Little Angels Public School';
const SCHOOL_TAGLINE = 'Learn • Grow • Lead';
const SCHOOL_ABBR    = 'LA';   // shown in the avatar when no logo is uploaded
// ─────────────────────────────────────────────────────────────────────────────

const FEATURE_CARDS = [
  { icon: Users,      iconColor: '#1b2f5c', iconBg: '#e3e8f1', title: 'Unified Access',    desc: 'One login for all roles.'     },
  { icon: ShieldCheck,iconColor: '#16a34a', iconBg: '#dcfce7', title: 'Secure & Reliable', desc: 'Your data is always safe.'    },
  { icon: TrendingUp, iconColor: '#d4480a', iconBg: '#ffe6d5', title: 'Smart Insights',    desc: 'AI-powered decisions.'        },
  { icon: Bell,       iconColor: '#d97706', iconBg: '#fef3c7', title: 'Real-time Updates', desc: 'Stay informed, always.'       },
];

const BG_ICONS = [
  { Icon: GraduationCap, top: '8%',  left: '6%',  size: 26, opacity: 0.12 },
  { Icon: BookOpen,      top: '20%', left: '76%', size: 20, opacity: 0.10 },
  { Icon: BarChart2,     top: '48%', left: '66%', size: 22, opacity: 0.09 },
  { Icon: School,        top: '68%', left: '4%',  size: 24, opacity: 0.11 },
  { Icon: GraduationCap, top: '78%', left: '52%', size: 18, opacity: 0.08 },
  { Icon: BookOpen,      top: '36%', left: '3%',  size: 18, opacity: 0.09 },
];

export default function AdminLogin() {
  const router = useRouter();
  const [identifier,    setIdentifier]    = useState('');
  const [password,      setPassword]      = useState('');
  const [showPassword,  setShowPassword]  = useState(false);
  const [loading,       setLoading]       = useState(false);
  const [error,         setError]         = useState<string | null>(null);
  const [info,          setInfo]          = useState<string | null>(null);
  const [isForgotOpen,  setIsForgotOpen]  = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setInfo(null);
    setLoading(true);

    try {
      const data      = await api.auth.login(identifier.trim(), password);
      const userRoles    = data.user.roles || [];
      const isSuperAdmin = userRoles.includes('SUPER_ADMIN');
      const isAdmin      = userRoles.includes('ADMIN');
      const isTeacher    = userRoles.includes('TEACHER');
      const isStudent    = userRoles.includes('STUDENT');

      if (!isSuperAdmin && !isAdmin) {
        if (isTeacher) {
          setError('Access Restricted: Teacher accounts must log in via the SAMAGRA School Mobile App.');
        } else if (isStudent) {
          setError('Access Restricted: Student & Parent accounts must log in via the SAMAGRA School Mobile App.');
        } else {
          setError('Access Restricted: Administrative credentials required to access the Web Portal.');
        }
        setLoading(false);
        return;
      }

      setSession(data.token, data.user);
      router.push(isSuperAdmin ? '/super-admin' : '/dashboard');
    } catch (err) {
      setError((err instanceof Error && err.message) || 'Login failed. Please check your credentials.');
      setLoading(false);
    }
  };

  const fillPreset = (id: string) => {
    setIdentifier(id);
    setPassword('Password@123');
    setError(null);
    setInfo(null);
  };

  return (
    <div className="aln-root">

      {/* ══ HEADER ═══════════════════════════════════════════════════════════ */}
      <header className="aln-header">
        {/* School branding */}
        <div className="aln-header-school">
          <div className="aln-school-avatar" aria-hidden="true">{SCHOOL_ABBR}</div>
          <div className="aln-school-text">
            <span className="aln-school-name">{SCHOOL_NAME}</span>
            <span className="aln-school-tagline">{SCHOOL_TAGLINE}</span>
          </div>
        </div>

        {/* SAMAGRA brand badge */}
        <div className="aln-header-samagra">
          <div className="aln-samagra-badge" aria-label="Samagra">
            <img className="aln-samagra-badge-img" src="/samagra-mark.png" alt="" />
          </div>
          <span className="aln-samagra-text">SAMAGRA</span>
        </div>
      </header>

      {/* ══ MAIN ═════════════════════════════════════════════════════════════ */}
      <main className="aln-main">

        {/* ── LEFT PANEL ─────────────────────────────────────────────────── */}
        <section className="aln-left" aria-label="Platform information">

          {/* Decorative bg icons */}
          <div className="aln-bg-icons" aria-hidden="true">
            {BG_ICONS.map(({ Icon, top, left, size, opacity }, i) => (
              <span key={i} className="aln-bg-icon" style={{ top, left, opacity }}>
                <Icon size={size} />
              </span>
            ))}
          </div>

          {/* Hero */}
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
                <span className="aln-feature-icon" style={{ color: iconColor, background: iconBg }} aria-hidden="true">
                  <Icon size={22} />
                </span>
                <span className="aln-feature-title">{title}</span>
                <span className="aln-feature-desc">{desc}</span>
              </div>
            ))}
          </div>

          {/* Illustration + quote */}
          <div className="aln-bottom-row">
            <div className="aln-illustration" aria-hidden="true">
              <svg viewBox="0 0 200 160" xmlns="http://www.w3.org/2000/svg" className="aln-school-svg">
                <rect x="0"   y="128" width="200" height="32" rx="4" fill="#d1e9c8" />
                <rect x="30"  y="60"  width="100" height="70" rx="4" fill="url(#bwall)" />
                <polygon points="25,60 130,60 77,28" fill="#142449" />
                <line x1="77" y1="28" x2="77" y2="10" stroke="#374151" strokeWidth="2" />
                <polygon points="77,10 97,16 77,22" fill="#ef4444" />
                <circle cx="77" cy="52" r="10" fill="white" stroke="#142449" strokeWidth="1.5" />
                <line x1="77" y1="52" x2="77" y2="45" stroke="#142449" strokeWidth="1.5" strokeLinecap="round" />
                <line x1="77" y1="52" x2="82" y2="52" stroke="#142449" strokeWidth="1.5" strokeLinecap="round" />
                <rect x="65"  y="98"  width="22" height="32" rx="3" fill="#142449" />
                <circle cx="83" cy="115" r="1.5" fill="white" />
                <rect x="38"  y="74"  width="18" height="14" rx="2" fill="#c6cfdf" />
                <rect x="62"  y="74"  width="18" height="14" rx="2" fill="#c6cfdf" />
                <rect x="86"  y="74"  width="18" height="14" rx="2" fill="#c6cfdf" />
                <rect x="110" y="74"  width="14" height="14" rx="2" fill="#c6cfdf" />
                <rect x="8"   y="88"  width="24" height="42" rx="3" fill="#60a5fa" />
                <rect x="12"  y="96"  width="10" height="10" rx="1" fill="#c6cfdf" />
                <rect x="128" y="88"  width="24" height="42" rx="3" fill="#60a5fa" />
                <rect x="138" y="96"  width="10" height="10" rx="1" fill="#c6cfdf" />
                <circle cx="170" cy="120" r="14" fill="#22c55e" />
                <rect x="168" y="128" width="4"  height="12" fill="#854d0e" />
                <circle cx="185" cy="122" r="10" fill="#16a34a" />
                <rect x="183" y="128" width="3"  height="10" fill="#854d0e" />
                <circle cx="20"  cy="122" r="12" fill="#22c55e" />
                <rect x="18"  y="128" width="4"  height="10" fill="#854d0e" />
                <defs>
                  <linearGradient id="bwall" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%"   stopColor="#3f5179" />
                    <stop offset="100%" stopColor="#1b2f5c" />
                  </linearGradient>
                </defs>
              </svg>
            </div>

            <blockquote className="aln-quote">
              <span className="aln-quote-mark" aria-hidden="true">"</span>
              <p className="aln-quote-text">
                Education is the most powerful weapon which you can use to change the world.
              </p>
              <footer className="aln-quote-author">— Nelson Mandela</footer>
            </blockquote>
          </div>
        </section>

        {/* ── RIGHT PANEL ────────────────────────────────────────────────── */}
        <section className="aln-right" aria-label="Sign in">

          {/* Login card */}
          <div className="aln-login-card">
            <div className="aln-card-header">
              <span className="aln-card-icon" aria-hidden="true">
                <ShieldCheck size={22} />
              </span>
              <div>
                <h2 className="aln-card-title">Welcome back!</h2>
                <p className="aln-card-subtitle">Sign in to access your dashboard.</p>
              </div>
            </div>

            {error && (
              <div className="aln-alert" role="alert">
                <AlertCircle size={15} className="aln-alert-icon" aria-hidden="true" />
                <span>{error}</span>
              </div>
            )}
            {info && (
              <div className="aln-info" role="status">{info}</div>
            )}

            <form onSubmit={handleSubmit} className="aln-form" noValidate>

              {/* Login ID */}
              <div className="aln-field-group">
                <label htmlFor="aln-identifier" className="aln-label">Login ID</label>
                <div className="aln-field">
                  <span className="aln-field-prefix" aria-hidden="true">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"/><circle cx="12" cy="7" r="4"/>
                    </svg>
                  </span>
                  <input
                    id="aln-identifier"
                    type="text"
                    required
                    autoComplete="username"
                    value={identifier}
                    onChange={(e) => setIdentifier(e.target.value)}
                    placeholder="Enter your login ID"
                    className="aln-input aln-input-with-prefix"
                  />
                </div>
              </div>

              {/* Password — label row has Forgot Password on the right */}
              <div className="aln-field-group">
                <div className="aln-label-row">
                  <label htmlFor="aln-password" className="aln-label">Password</label>
                  <button
                    type="button"
                    className="aln-link aln-forgot-inline"
                    onClick={() => { setError(null); setInfo(null); setIsForgotOpen(true); }}
                  >
                    Forgot Password?
                  </button>
                </div>
                <div className="aln-field">
                  <span className="aln-field-prefix" aria-hidden="true">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
                      <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/>
                    </svg>
                  </span>
                  <input
                    id="aln-password"
                    type={showPassword ? 'text' : 'password'}
                    required
                    autoComplete="current-password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="Enter your password"
                    className="aln-input aln-input-with-prefix aln-input-with-suffix"
                  />
                  <button
                    type="button"
                    className="aln-eye-btn"
                    onClick={() => setShowPassword(p => !p)}
                    aria-label={showPassword ? 'Hide password' : 'Show password'}
                    aria-pressed={showPassword}
                  >
                    {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                  </button>
                </div>
              </div>

              {/* Sign in button */}
              <button type="submit" disabled={loading} className="aln-submit-btn">
                {loading && <span className="aln-spinner" aria-hidden="true" />}
                {loading ? 'Signing in…' : 'Sign in'}
              </button>
            </form>

            {/* Back to home */}
            <div className="aln-back-home">
              <Home size={14} aria-hidden="true" />
              <a href="/" className="aln-link">Back to home</a>
            </div>

            {/* Quick test presets */}
            <div className="aln-presets">
              <span>Quick test:</span>
              <button type="button" className="aln-link aln-preset-super" onClick={() => fillPreset('superadmin')}>Super Admin</button>
              <span aria-hidden="true">·</span>
              <button type="button" className="aln-link aln-preset-admin" onClick={() => fillPreset('admin')}>School Admin</button>
            </div>
          </div>

          {/* Stats 2×2 grid */}
          <div className="aln-stats" role="list" aria-label="Platform statistics">
            <div className="aln-stat" role="listitem">
              <span className="aln-stat-icon" style={{ color:'#1b2f5c', background:'#e3e8f1' }} aria-hidden="true"><School size={18}/></span>
              <div><span className="aln-stat-value">500+</span><span className="aln-stat-label">Schools</span></div>
            </div>
            <div className="aln-stat" role="listitem">
              <span className="aln-stat-icon" style={{ color:'#16a34a', background:'#dcfce7' }} aria-hidden="true"><Users size={18}/></span>
              <div><span className="aln-stat-value">50K+</span><span className="aln-stat-label">Users</span></div>
            </div>
            <div className="aln-stat" role="listitem">
              <span className="aln-stat-icon" style={{ color:'#d97706', background:'#fef3c7' }} aria-hidden="true"><BookOpen size={18}/></span>
              <div><span className="aln-stat-value">1M+</span><span className="aln-stat-label">Students</span></div>
            </div>
            <div className="aln-stat" role="listitem">
              <span className="aln-stat-icon" style={{ color:'#d4480a', background:'#ffe6d5' }} aria-hidden="true"><BarChart2 size={18}/></span>
              <div><span className="aln-stat-value">99.9%</span><span className="aln-stat-label">Uptime</span></div>
            </div>
          </div>
        </section>
      </main>

      {/* ══ FOOTER ═══════════════════════════════════════════════════════════ */}
      <footer className="aln-footer">
        <span className="aln-footer-left">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" style={{display:'inline',verticalAlign:'middle',marginRight:5}}>
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z"/>
          </svg>
          Built with passion for schools by Kushagra Saxena
        </span>
        <span className="aln-footer-mid">
          <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true" style={{display:'inline',verticalAlign:'middle',marginRight:5}}>
            <polyline points="16 18 22 12 16 6"/><polyline points="8 6 2 12 8 18"/>
          </svg>
          React Frontend | Existing API &amp; functionality unchanged
        </span>
        <span className="aln-footer-right">© 2026 SAMAGRA. All rights reserved.</span>
      </footer>

      {/* Forgot Password Modal */}
      <ForgotPasswordModal
        isOpen={isForgotOpen}
        onClose={() => setIsForgotOpen(false)}
        initialIdentifier={identifier}
        onSuccess={(resetId, newPass) => {
          setIdentifier(resetId);
          setPassword(newPass);
          setError(null);
          setInfo(`Password updated for ${resetId}! Click Sign in to proceed.`);
        }}
      />
    </div>
  );
}
