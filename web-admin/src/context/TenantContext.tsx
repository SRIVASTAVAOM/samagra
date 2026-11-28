'use client';

import React, { createContext, useContext, useEffect, useState, useMemo } from 'react';
import { api, getCurrentUser } from '@/lib/api';

export interface TenantFeatures {
  fees: boolean;
  transport: boolean;
  extra_fees: boolean;
  annual_matrix: boolean;
  cheque_management: boolean;
  sibling_discount: boolean;
  defaulters: boolean;
  [key: string]: boolean;
}

export interface TenantBranding {
  name: string;
  code: string;
  platformBrand: string;
  affiliation: string;
  logoUrl: string;
  tagline: string;
  address: string;
  phone: string;
  [key: string]: any;
}

export interface TenantData {
  id: string;
  name: string;
  code: string;
  branding: TenantBranding;
  features: TenantFeatures;
}

interface TenantContextValue {
  tenant: TenantData | null;
  features: TenantFeatures;
  branding: TenantBranding;
  loading: boolean;
  refreshTenant: () => Promise<void>;
}

const defaultFeatures: TenantFeatures = {
  fees: true,
  transport: true,
  extra_fees: true,
  annual_matrix: true,
  cheque_management: true,
  sibling_discount: true,
  defaulters: true,
};

const defaultBranding: TenantBranding = {
  name: 'School Name',
  code: 'SCHOOL',
  platformBrand: 'SAMAGRA',
  affiliation: 'Affiliated to CBSE / State Board',
  logoUrl: '/samagra-mark.png',
  tagline: 'The Complete School Platform',
  address: 'School Campus',
  phone: '+91 00000 00000',
};

const TenantContext = createContext<TenantContextValue>({
  tenant: null,
  features: defaultFeatures,
  branding: defaultBranding,
  loading: true,
  refreshTenant: async () => {},
});

export function TenantProvider({ children }: { children: React.ReactNode }) {
  const [tenant, setTenant] = useState<TenantData | null>(() => {
    if (typeof window === 'undefined') return null;
    const user = getCurrentUser();
    if (user?.school) {
      return {
        id: user.school.id,
        name: user.school.name || '',
        code: user.school.code || '',
        branding: { ...defaultBranding, ...(user.school.branding || {}), name: user.school.branding?.name || user.school.name || '' },
        features: { ...defaultFeatures, ...(user.school.features || {}) },
      };
    }
    return null;
  });
  const [loading, setLoading] = useState(true);

  const refreshTenant = async () => {
    try {
      const user = getCurrentUser();
      if (!user) {
        setTenant(null);
        setLoading(false);
        return;
      }
      
      // If logged in user is Super-Admin, configure dedicated Platform HQ tenant
      if (user?.roles?.includes('SUPER_ADMIN')) {
        setTenant({
          id: 'platform-hq',
          name: 'SAMAGRA Platform HQ',
          code: 'HQ',
          branding: {
            name: 'SAMAGRA Platform HQ',
            code: 'HQ',
            platformBrand: 'SAMAGRA',
            affiliation: 'Central Platform Administration',
            logoUrl: '/samagra-mark.png',
            tagline: 'Multi-Tenant Institutional SaaS',
            address: 'Command Center',
            phone: '',
          },
          features: defaultFeatures,
        });
        setLoading(false);
        return;
      }

      const res = await api.admin.getTenantConfig();
      if (res && res.data) {
        setTenant({
          id: res.data.id,
          name: res.data.name || defaultBranding.name,
          code: res.data.code || defaultBranding.code,
          branding: { ...defaultBranding, ...(res.data.branding || {}) },
          features: { ...defaultFeatures, ...(res.data.features || {}) },
        });
      }
    } catch (_err) {
      // Fallback to local stored user's school if network error
      const user = getCurrentUser();
      if (user?.school) {
        setTenant({
          id: user.school.id,
          name: user.school.name || defaultBranding.name,
          code: user.school.code || defaultBranding.code,
          branding: { ...defaultBranding, ...(user.school.branding || {}) },
          features: { ...defaultFeatures, ...(user.school.features || {}) },
        });
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    refreshTenant();
  }, []);

  const features = useMemo(() => tenant?.features || defaultFeatures, [tenant]);
  const branding = useMemo(
    () =>
      tenant?.branding ||
      (loading ? { ...defaultBranding, name: '', code: '' } : defaultBranding),
    [tenant, loading]
  );

  return (
    <TenantContext.Provider value={{ tenant, features, branding, loading, refreshTenant }}>
      {children}
    </TenantContext.Provider>
  );
}

export function useTenant() {
  return useContext(TenantContext);
}
