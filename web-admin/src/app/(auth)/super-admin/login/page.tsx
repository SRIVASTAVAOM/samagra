import AdminLogin from '../../login/AdminLogin';

export default function SuperAdminLoginPage() {
  return <AdminLogin isSuperAdminOnly={true} />;
}
