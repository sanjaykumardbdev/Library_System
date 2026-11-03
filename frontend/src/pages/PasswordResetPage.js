import React, { useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import api, { getErrorMessage, refreshCsrfToken } from '../api/client';

export default function PasswordResetPage({ reset = false }) {
  const location = useLocation();
  const token = new URLSearchParams(location.search).get('token') || '';
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [saving, setSaving] = useState(false);
  const [showPassword, setShowPassword] = useState(false);

  async function submit(event) {
    event.preventDefault();
    setError('');
    setMessage('');
    if (reset && password !== confirmPassword) {
      setError('The passwords do not match.');
      return;
    }

    setSaving(true);
    try {
      await refreshCsrfToken();
      if (reset) {
        await api.post('/api/auth/reset-password', { token, password });
        setMessage('Your password has been reset. You can now sign in.');
      } else {
        const response = await api.post('/api/auth/forgot-password', { email });
        setMessage(response.data.message);
      }
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not complete the password reset.'));
    } finally {
      setSaving(false);
    }
  }

  return (
    <main className="auth-card">
      <h1>{reset ? 'Choose a new password' : 'Forgot password'}</h1>
      <p>{reset
        ? 'Reset links expire after 60 minutes and can only be used once.'
        : 'Enter your account email. If an account exists, we will email a secure reset link.'}</p>
      {!reset || token ? (
        <form onSubmit={submit} className="form-grid">
          {!reset && (
            <label>Email
              <input type="email" autoComplete="email" required maxLength={200} value={email} onChange={(event) => setEmail(event.target.value)} />
            </label>
          )}
          {reset && (
            <>
              <label>New password
                <div className="password-input-row">
                  <input type={showPassword ? 'text' : 'password'} autoComplete="new-password" required minLength={12} maxLength={72} value={password} onChange={(event) => setPassword(event.target.value)} />
                  <button type="button" className="button-secondary password-toggle" aria-pressed={showPassword} onClick={() => setShowPassword((shown) => !shown)}>{showPassword ? 'Hide' : 'Show'}</button>
                </div>
              </label>
              <label>Confirm new password
                <input type={showPassword ? 'text' : 'password'} autoComplete="new-password" required minLength={12} maxLength={72} value={confirmPassword} onChange={(event) => setConfirmPassword(event.target.value)} />
              </label>
            </>
          )}
          {error && <p role="alert" className="notice notice-error">{error}</p>}
          {message && <p role="status" className="notice notice-success">{message}</p>}
          <button type="submit" disabled={saving}>{saving ? 'Please wait...' : reset ? 'Reset password' : 'Send reset link'}</button>
        </form>
      ) : (
        <p role="alert" className="notice notice-error">This reset link is missing its token. Request a new link to continue.</p>
      )}
      <p><Link to="/login">Back to sign in</Link></p>
    </main>
  );
}
