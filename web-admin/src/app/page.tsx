'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getCurrentUser } from '@/lib/api';

export default function RootPage() {
  const router = useRouter();

  useEffect(() => {
    const token = typeof window !== 'undefined' ? localStorage.getItem('school_erp_token') : null;
    if (token) {
      const user = getCurrentUser();
      if (user?.roles?.includes('SUPER_ADMIN')) {
        router.replace('/super-admin');
      } else {
        router.replace('/dashboard');
      }
    } else {
      router.replace('/login');
    }
  }, [router]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 text-slate-500 text-xs">
      Directing to SAMAGRA Command Center...
    </div>
  );
}
