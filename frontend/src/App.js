import React, { useEffect, useState } from 'react';
import { HashRouter, Routes, Route, Link, Navigate, Outlet } from 'react-router-dom';
import BooksList from './pages/BooksList';
import MembersList from './pages/MembersList';
import AuthPage from './pages/AuthPage';
import MyLoans from './pages/MyLoans';
import AdminCirculation from './pages/AdminCirculation';
import AdminUsers from './pages/AdminUsers';
import PasswordResetPage from './pages/PasswordResetPage';
import api, { getErrorMessage } from './api/client';
import { AuthProvider, useAuth } from './auth/AuthContext';
import ErrorBoundary from './components/ErrorBoundary';

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
  const { user, logout, authError } = useAuth();
  const [topBooks, setTopBooks] = useState([]);
  const [popularError, setPopularError] = useState('');
  const isAdmin = user?.roles?.includes('ADMIN');

  useEffect(() => {
    let active = true;
    if (!user) {
      setTopBooks([]);
      return () => { active = false; };
    }
    api.get('/api/books/top-borrowed', { params: { limit: 5 } })
      .then((response) => {
        if (active) {
          setTopBooks(response.data);
          setPopularError('');
        }
      })
      .catch((error) => {
        if (active) setPopularError(getErrorMessage(error, 'Could not load popular books.'));
      });
    return () => { active = false; };
  }, [user]);

  async function signOut() {
    try {
      await logout();
    } catch (error) {
      setPopularError(getErrorMessage(error, 'Could not sign out cleanly. Your local session was cleared.'));
    }
  }

  return (
    <div className="app-shell">
      <header className="site-header">
        <div className="brand-row">
          <Link to={user ? '/books' : '/login'} className="brand">
            <span className="brand-mark" aria-hidden="true">B</span>
            <span>Book Haven<small>Library System</small></span>
          </Link>
          <nav className="site-nav" aria-label="Main navigation">
          {user ? (
            <>
              <Link to="/books">Books</Link>
              <Link to="/my-loans">My loans</Link>
              {isAdmin && <Link to="/admin/circulation">Circulation</Link>}
              {isAdmin && <Link to="/admin/users">User access</Link>}
              {isAdmin && <Link to="/members">Members</Link>}
              <span className="signed-in-user">{user.username}</span>
              <button className="button-secondary" onClick={signOut}>Sign out</button>
            </>
          ) : (
            <>
              <Link to="/login">Sign in</Link>
              <Link to="/register">Register</Link>
            </>
          )}
          </nav>
        </div>
        <div className="hero-banner">
          <img src="/library-header.svg" alt="" className="hero-image" />
          <div className="hero-copy">
            <p className="eyebrow">A WORLD OF STORIES</p>
            <h1>Your next chapter<br />starts here.</h1>
            <p>Find a book, borrow it, and make time for a little wonder.</p>
            {user && <Link className="hero-link" to="/books">Explore the collection <span aria-hidden="true">→</span></Link>}
          </div>
        </div>
      </header>

      {(authError || popularError) && (
        <p role="alert" className="notice notice-error global-notice">{authError || popularError}</p>
      )}
      <div className="page-grid">
        <aside className="sidebar-card">
          <p className="eyebrow">READER FAVORITES</p>
          <h2>Top borrowed</h2>
          {topBooks.length > 0 ? (
            <ol className="popular-list">
              {topBooks.map((book) => (
                <li key={book.bookId}>
                  <Link to="/books">{book.title}</Link>
                  <span>{book.borrowCount} {book.borrowCount === 1 ? 'borrow' : 'borrows'}</span>
                </li>
              ))}
            </ol>
          ) : (
            <p className="sidebar-empty">{user ? 'Borrowing favorites will appear here.' : 'Sign in to explore reader favorites.'}</p>
          )}
          {user && <Link className="sidebar-link" to="/books">Browse all books <span aria-hidden="true">→</span></Link>}
        </aside>
        <main className="main-content">
          <Routes>
            <Route path="/login" element={<AuthPage mode="login" />} />
            <Route path="/register" element={<AuthPage mode="register" />} />
            <Route path="/forgot-password" element={<PasswordResetPage />} />
            <Route path="/reset-password" element={<PasswordResetPage reset />} />
            <Route element={<RequireAuth />}>
              <Route path="/" element={<Navigate to="/books" replace />} />
              <Route path="/books" element={<BooksList />} />
              <Route path="/my-loans" element={<MyLoans />} />
              <Route element={<RequireAdmin />}>
                <Route path="/members" element={<MembersList />} />
                <Route path="/admin/circulation" element={<AdminCirculation />} />
                <Route path="/admin/users" element={<AdminUsers />} />
              </Route>
            </Route>
            <Route path="*" element={<Navigate to={user ? '/books' : '/login'} replace />} />
          </Routes>
        </main>
      </div>
      <footer className="site-footer">
        <span>Book Haven Library</span>
        <span>Stories connect us. Thank you for reading.</span>
      </footer>
    </div>
  );
}

export default function App() {
  return (
    <ErrorBoundary>
      <HashRouter>
        <AuthProvider>
          <AppLayout />
        </AuthProvider>
      </HashRouter>
    </ErrorBoundary>
  );
}
