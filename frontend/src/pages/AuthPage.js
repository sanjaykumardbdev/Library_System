import React, { useState } from 'react';
import { Link, Navigate, useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { getErrorMessage } from '../api/client';

export default function AuthPage({ mode }) {
  const isRegister = mode === 'register';
  const { user, login, register } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({ username: '', email: '', password: '', memberType: 'STUDENT', phone: '' });
  const [error, setError] = useState('');
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
        await register(form);
      } else {
        await login({ email: form.email, password: form.password });
      }
      navigate('/books', { replace: true });
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Check your details and try again.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <main style={{ maxWidth: 440, margin: '48px auto', padding: 24, border: '1px solid #d5d9d5', borderRadius: 6 }}>
      <h1 style={{ marginTop: 0 }}>{isRegister ? 'Create your library account' : 'Sign in'}</h1>
      <form onSubmit={submit} style={{ display: 'grid', gap: 14 }}>
        {isRegister && <label>Full name<input name="username" autoComplete="name" required maxLength={200} value={form.username} onChange={update} /></label>}
        <label>Email<input name="email" type="email" autoComplete="email" required maxLength={200} value={form.email} onChange={update} /></label>
        <label>Password<input name="password" type="password" autoComplete={isRegister ? 'new-password' : 'current-password'} required minLength={isRegister ? 12 : 1} maxLength={72} value={form.password} onChange={update} /></label>
        {isRegister && (
          <>
            <label>Member type<select name="memberType" value={form.memberType} onChange={update}><option value="STUDENT">Student</option><option value="PROFESSIONAL">Professional</option></select></label>
            <label>Phone<input name="phone" type="tel" maxLength={20} value={form.phone} onChange={update} /></label>
          </>
        )}
        {error && <p role="alert" style={{ color: '#a32222', margin: 0 }}>{error}</p>}
        <button type="submit" disabled={saving}>{saving ? 'Please wait...' : isRegister ? 'Create account' : 'Sign in'}</button>
      </form>
      <p>{isRegister ? 'Already registered?' : 'New to the library?'}{' '}<Link to={isRegister ? '/login' : '/register'}>{isRegister ? 'Sign in' : 'Create an account'}</Link></p>
    </main>
  );
}