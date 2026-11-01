import React from 'react';
import { HashRouter, Routes, Route, Link, Navigate, Outlet } from 'react-router-dom';
import BooksList from './pages/BooksList';
import MembersList from './pages/MembersList';
import AuthPage from './pages/AuthPage';
import MyLoans from './pages/MyLoans';
import AdminCirculation from './pages/AdminCirculation';
import { AuthProvider, useAuth } from './auth/AuthContext';

function RequireAuth() {
  const { user, loading } = useAuth();
  if (loading) return <p>Loading account...</p>;
  return user ? <Outlet /> : <Navigate to="/login" replace />;
}

function RequireAdmin() {
  const { user } = useAuth();
  return user?.roles?.includes('ADMIN') ? <Outlet /> : <Navigate to="/books" replace />;
}

function AppLayout() {
  const { user, logout } = useAuth();

  return (
    <div style={{ maxWidth: 1180, margin: '0 auto', padding: '24px 20px' }}>
      <header style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 16, borderBottom: '1px solid #d5d9d5', paddingBottom: 16, marginBottom: 24 }}>
        <Link to={user ? '/books' : '/login'} style={{ color: '#183a32', textDecoration: 'none', fontSize: 22, fontWeight: 700 }}>
          Library System
        </Link>
        <nav style={{ display: 'flex', alignItems: 'center', gap: 14, flexWrap: 'wrap' }}>
          {user ? (
            <>
              <Link to="/books">Books</Link>
              <Link to="/my-loans">My loans</Link>
              {user.roles?.includes('ADMIN') && <Link to="/admin/circulation">Circulation</Link>}
              {user.roles?.includes('ADMIN') && <Link to="/members">Members</Link>}
              <span>{user.username}</span>
              <button onClick={logout}>Sign out</button>
            </>
          ) : (
            <>
              <Link to="/login">Sign in</Link>
              <Link to="/register">Register</Link>
            </>
          )}
        </nav>
      </header>

      <Routes>
        <Route path="/login" element={<AuthPage mode="login" />} />
        <Route path="/register" element={<AuthPage mode="register" />} />
        <Route element={<RequireAuth />}>
          <Route path="/" element={<Navigate to="/books" replace />} />
          <Route path="/books" element={<BooksList />} />
          <Route path="/my-loans" element={<MyLoans />} />
          <Route element={<RequireAdmin />}>
            <Route path="/members" element={<MembersList />} />
            <Route path="/admin/circulation" element={<AdminCirculation />} />
          </Route>
        </Route>
        <Route path="*" element={<Navigate to={user ? '/books' : '/login'} replace />} />
      </Routes>
    </div>
  );
}

export default function App() {
  return (
    <HashRouter>
      <AuthProvider>
        <AppLayout />
      </AuthProvider>
    </HashRouter>
  );
}
