'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import {
  LayoutDashboard,
  CalendarDays,
  FileSpreadsheet,
  LogOut,
  Users,
  UserCheck,
  BookOpen,
  Library,
  UserCog,
  ClipboardCheck,
  Receipt,
  Megaphone,
  Bell,
  MessageSquare,
  Globe,
  FolderOpen,
} from 'lucide-react';
import { clearSession, getCurrentUser } from '@/lib/api';

type NavItem    = { name: string; href: string; icon: any; badge?: string; };
type NavSection = { title: string; items: NavItem[]; };

const navSections: NavSection[] = [
  {
    title: 'Core ERP',
    items: [
      { name: 'Command Center', href: '/dashboard',              icon: LayoutDashboard, badge: 'Live' },
    ],
  },
  {
    title: 'Students & Academics',
    items: [
      { name: 'Student list',       href: '/students',                  icon: Users         },
      { name: 'Subject master',     href: '/subjects',                  icon: Library       },
      { name: 'Timetable',          href: '/timetable',                 icon: CalendarDays  },
      { name: 'Report cards',       href: '/reports/greensheet',        icon: FileSpreadsheet },
      { name: 'Student attendance', href: '/attendance/students',       icon: UserCheck     },
      { name: 'Homework',           href: '/homework',                  icon: BookOpen      },
      { name: 'Study material',     href: '/academics/study-material',  icon: FolderOpen    },
    ],
  },
  {
    title: 'Staff Management',
    items: [
      { name: 'Staff list',       href: '/staff',            icon: UserCog       },
      { name: 'Staff attendance', href: '/attendance/staff', icon: ClipboardCheck },
    ],
  },
  {
    title: 'Finance & Accounts',
    items: [
      { name: 'Fees section', href: '/fees', icon: Receipt },
    ],
  },
  {
    title: 'Communication & Alerts',
    items: [
      { name: 'Add notice',          href: '/notices',       icon: Megaphone    },
      { name: 'Push notifications',  href: '/notifications', icon: Bell         },
      { name: 'View feedback',       href: '/feedback',      icon: MessageSquare },
    ],
  },
];

type SidebarProps = { open?: boolean; onClose?: () => void; };

export function Sidebar({ open = false, onClose }: SidebarProps) {
  const pathname = usePathname();
  const router   = useRouter();
  const [user, setUser] = React.useState<any>(null);

  React.useEffect(() => { setUser(getCurrentUser()); }, []);

  const handleLogout = () => { clearSession(); router.push('/login'); };

  const isSuperAdmin  = user?.roles?.includes('SUPER_ADMIN');
  const isAdmin       = user?.roles?.includes('ADMIN');
  const isTeacherOnly = user?.roles?.includes('TEACHER') && !isAdmin && !isSuperAdmin;
  const roleName      = isSuperAdmin ? 'Super Admin' : isTeacherOnly ? 'Teacher' : 'Administrator';
  const userInitials  = (user?.identifier || 'AD').slice(0, 2).toUpperCase();

  const sectionsToRender = React.useMemo(() => {
    if (isSuperAdmin) {
      return [
        { title: 'Platform Master', items: [{ name: 'Super Admin Engine', href: '/super-admin', icon: Globe, badge: 'L1' }] },
        ...navSections,
      ];
    }
    if (isTeacherOnly) {
      return navSections
        .filter(s => s.title !== 'Finance & Accounts' && s.title !== 'Staff Management')
        .map(s => s.title === 'Students & Academics'
          ? { ...s, items: s.items.filter(i => i.name !== 'Subject master') }
          : s
        );
    }
    return navSections;
  }, [isSuperAdmin, isTeacherOnly]);

  return (
    <>
      {/* Mobile backdrop */}
      {open && (
        <div
          className="no-print fixed inset-0 z-30 bg-slate-900/40 md:hidden"
          onClick={onClose}
          aria-hidden="true"
        />
      )}

      <aside
        className={`no-print fixed inset-y-0 left-0 z-40 flex flex-col h-screen select-none shrink-0
          transition-transform duration-200 md:static md:translate-x-0
          ${open ? 'translate-x-0' : '-translate-x-full'}`}
        style={{ width: 220, background: '#1e2235', borderRight: '1px solid rgba(255,255,255,0.07)' }}
      >
        {/* ── Brand header ──────────────────────────────────────────── */}
        <div style={{
          height: 64,
          display: 'flex',
          alignItems: 'center',
          gap: 10,
          padding: '0 18px',
          borderBottom: '1px solid rgba(255,255,255,0.08)',
          flexShrink: 0,
        }}>
          {/* "S" badge */}
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: 'linear-gradient(135deg,#635bff 0%,#4f46e5 100%)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
            boxShadow: '0 2px 10px rgba(99,91,255,0.4)',
          }}>
            <span style={{ color: '#fff', fontSize: 17, fontWeight: 800, lineHeight: 1 }}>S</span>
          </div>
          <div style={{ minWidth: 0 }}>
            <div style={{ color: '#fff', fontWeight: 700, fontSize: 14, letterSpacing: '-0.01em', lineHeight: 1.2 }}>
              SAMAGRA
            </div>
            <div style={{ color: 'rgba(255,255,255,0.45)', fontSize: 10.5, marginTop: 2, letterSpacing: 0 }}>
              {isSuperAdmin ? 'Multi-School Hub' : isTeacherOnly ? 'Faculty Portal' : 'Core Suite · Web admin'}
            </div>
          </div>
        </div>

        {/* ── Nav ───────────────────────────────────────────────────── */}
        <nav style={{ flex: 1, overflowY: 'auto', padding: '12px 10px' }}>
          {sectionsToRender.map(section => (
            <div key={section.title} style={{ marginBottom: 20 }}>
              {/* Section label */}
              <div style={{
                fontSize: 10,
                fontWeight: 700,
                letterSpacing: '0.08em',
                textTransform: 'uppercase',
                color: 'rgba(255,255,255,0.28)',
                padding: '0 10px',
                marginBottom: 4,
              }}>
                {section.title}
              </div>

              {section.items.map(item => {
                const isActive = pathname === item.href
                  || (item.href !== '/dashboard' && pathname.startsWith(item.href));
                const Icon = item.icon;

                return (
                  <Link
                    key={item.href}
                    href={item.href}
                    onClick={onClose}
                    aria-current={isActive ? 'page' : undefined}
                    style={{
                      display: 'flex',
                      alignItems: 'center',
                      justifyContent: 'space-between',
                      gap: 8,
                      padding: '8px 10px',
                      borderRadius: 8,
                      marginBottom: 2,
                      fontSize: 13,
                      fontWeight: isActive ? 600 : 400,
                      textDecoration: 'none',
                      transition: 'background 0.15s, color 0.15s',
                      background: isActive ? 'rgba(99,91,255,0.18)' : 'transparent',
                      color: isActive ? '#a5b4fc' : 'rgba(255,255,255,0.58)',
                      position: 'relative',
                    }}
                    onMouseEnter={e => {
                      if (!isActive) (e.currentTarget as HTMLElement).style.background = 'rgba(255,255,255,0.06)';
                      if (!isActive) (e.currentTarget as HTMLElement).style.color = 'rgba(255,255,255,0.85)';
                    }}
                    onMouseLeave={e => {
                      if (!isActive) (e.currentTarget as HTMLElement).style.background = 'transparent';
                      if (!isActive) (e.currentTarget as HTMLElement).style.color = 'rgba(255,255,255,0.58)';
                    }}
                  >
                    {/* Active left bar */}
                    {isActive && (
                      <span style={{
                        position: 'absolute', left: 0, top: 6, bottom: 6,
                        width: 3, borderRadius: '0 3px 3px 0',
                        background: '#818cf8',
                      }} />
                    )}

                    <div style={{ display: 'flex', alignItems: 'center', gap: 9, minWidth: 0 }}>
                      <Icon size={15} style={{ flexShrink: 0, color: isActive ? '#818cf8' : 'rgba(255,255,255,0.35)' }} />
                      <span style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {item.name}
                      </span>
                    </div>

                    {item.badge && (
                      <span style={{
                        fontSize: 9.5,
                        fontWeight: 700,
                        padding: '1px 6px',
                        borderRadius: 4,
                        flexShrink: 0,
                        background: isActive ? 'rgba(129,140,248,0.25)' : 'rgba(255,255,255,0.08)',
                        color: isActive ? '#a5b4fc' : 'rgba(255,255,255,0.45)',
                        letterSpacing: '0.04em',
                      }}>
                        {item.badge}
                      </span>
                    )}
                  </Link>
                );
              })}
            </div>
          ))}
        </nav>

        {/* ── User footer ───────────────────────────────────────────── */}
        <div style={{
          padding: '10px 12px',
          borderTop: '1px solid rgba(255,255,255,0.08)',
          flexShrink: 0,
        }}>
          <div style={{
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'space-between',
            padding: '8px 10px',
            borderRadius: 10,
            background: 'rgba(255,255,255,0.06)',
            border: '1px solid rgba(255,255,255,0.08)',
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 9, minWidth: 0 }}>
              {/* Avatar */}
              <div style={{
                width: 32, height: 32, borderRadius: '50%',
                background: 'linear-gradient(135deg,#635bff,#4f46e5)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                flexShrink: 0,
                fontSize: 11, fontWeight: 700, color: '#fff', letterSpacing: '0.03em',
              }}>
                {userInitials}
              </div>
              <div style={{ minWidth: 0 }}>
                <div style={{ color: '#fff', fontSize: 12, fontWeight: 600, lineHeight: 1.3, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {user?.identifier || 'admin'}
                </div>
                <div style={{ color: 'rgba(255,255,255,0.4)', fontSize: 10.5, marginTop: 1 }}>
                  {roleName}
                </div>
              </div>
            </div>

            <button
              onClick={handleLogout}
              title="Log out"
              style={{
                background: 'none', border: 'none', cursor: 'pointer',
                padding: 6, borderRadius: 6,
                color: 'rgba(255,255,255,0.35)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                transition: 'color 0.15s, background 0.15s',
                flexShrink: 0,
              }}
              onMouseEnter={e => {
                (e.currentTarget as HTMLElement).style.color = '#f87171';
                (e.currentTarget as HTMLElement).style.background = 'rgba(248,113,113,0.12)';
              }}
              onMouseLeave={e => {
                (e.currentTarget as HTMLElement).style.color = 'rgba(255,255,255,0.35)';
                (e.currentTarget as HTMLElement).style.background = 'none';
              }}
            >
              <LogOut size={15} />
            </button>
          </div>
        </div>
      </aside>
    </>
  );
}
