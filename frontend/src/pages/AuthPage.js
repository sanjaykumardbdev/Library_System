import React, { useState } from 'react';
import { Link, Navigate, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { getErrorMessage } from '../api/client';

export default function AuthPage({ mode }) {
  const isRegister = mode === 'register';
  const { user, login, register } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [form, setForm] = useState({
    username: '',
    email: '',
    password: '',
    memberType: 'STUDENT',
    accountType: 'STUDENT',
    phone: '',
  });
  const [error, setError] = useState('');
  const [message, setMessage] = useState(location.state?.registrationSuccess || '');
  const [showPassword, setShowPassword] = useState(false);
  const [saving, setSaving] = useState(false);

  if (user) return <Navigate to="/books" replace />;

  function update(event) {
    setForm((current) => ({ ...current, [event.target.name]: event.target.value }));
  }

  async function submit(event) {
    event.preventDefault();
    setError('');
    setSaving(true);
    try {
      if (isRegister) {
        if (form.memberType === 'ADMIN') {
          setError('Admin accounts cannot be created through public registration. Ask an existing administrator to grant admin access.');
          return;
        }
        await register(form);
        navigate('/login', {
          replace: true,
          state: { registrationSuccess: 'Account created successfully. Please sign in with your new account.' },
        });
        return;
      } else {
        await login({ email: form.email, password: form.password, accountType: form.accountType });
      }
      navigate('/books', { replace: true });
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Check your details and try again.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="auth-card">
      <h1 style={{ marginTop: 0 }}>{isRegister ? 'Create your library account' : 'Sign in'}</h1>
      {message && <p role="status" className="notice notice-success">{message}</p>}
      <form onSubmit={submit} className="form-grid">
        {isRegister && <label>Full name<input name="username" autoComplete="name" required maxLength={200} value={form.username} onChange={update} /></label>}
        {!isRegister && (
          <label>Sign in as
            <select name="accountType" value={form.accountType} onChange={update}>
              <option value="STUDENT">Student</option>
              <option value="PROFESSIONAL">Professional</option>
              <option value="ADMIN">Admin</option>
            </select>
          </label>
        )}
        <label>Email<input name="email" type="email" autoComplete="email" required maxLength={200} value={form.email} onChange={update} /></label>
        <label>Password
          <div className="password-input-row">
            <input name="password" type={showPassword ? 'text' : 'password'} autoComplete={isRegister ? 'new-password' : 'current-password'} required minLength={isRegister ? 12 : 1} maxLength={72} value={form.password} onChange={update} />
            <button type="button" className="button-secondary password-toggle" aria-pressed={showPassword} onClick={() => setShowPassword((shown) => !shown)}>{showPassword ? 'Hide' : 'Show'}</button>
          </div>
        </label>
        {isRegister && (
          <>
            <label>Member type<select name="memberType" value={form.memberType} onChange={update}><option value="STUDENT">Student</option><option value="PROFESSIONAL">Professional</option><option value="ADMIN">Admin (administrator setup required)</option></select></label>
            {form.memberType === 'ADMIN' && <p className="notice notice-info">Admin access cannot be self-assigned. An existing administrator must create or authorize an admin account.</p>}
            <label>Phone<input name="phone" type="tel" maxLength={20} value={form.phone} onChange={update} /></label>
          </>
        )}
        {error && <p role="alert" className="notice notice-error">{error}</p>}
        <button type="submit" disabled={saving}>{saving ? 'Please wait...' : isRegister ? 'Create account' : 'Sign in'}</button>
      </form>
      <p>{!isRegister && <><Link to="/forgot-password">Forgot password?</Link><br /></>}{isRegister ? 'Already registered?' : 'New to the library?'}{' '}<Link to={isRegister ? '/login' : '/register'}>{isRegister ? 'Sign in' : 'Create an account'}</Link></p>
    </main>
  );
}