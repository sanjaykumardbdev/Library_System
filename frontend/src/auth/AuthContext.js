import React, { createContext, useContext, useEffect, useState } from 'react';
import api, { getErrorMessage, refreshCsrfToken } from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  const [authError, setAuthError] = useState('');

  useEffect(() => {
    let active = true;
    async function initialize() {
      try {
        await refreshCsrfToken();
        const response = await api.get('/api/auth/me');
        if (active) setUser(response.data);
      } catch (error) {
        if (active) {
          setUser(null);
          if (error.response?.status !== 401 && error.response?.status !== 403) {
            setAuthError(getErrorMessage(error, 'Could not verify your saved sign-in.'));
          }
        }
      } finally {
        if (active) setLoading(false);
      }
    }
    initialize();
    return () => { active = false; };
  }, []);

  async function login(credentials) {
    setAuthError('');
    await refreshCsrfToken();
    const response = await api.post('/api/auth/login', credentials);
    setUser(response.data);
    return response.data;
  }

  async function register(profile) {
    await refreshCsrfToken();
    return api.post('/api/auth/register', profile);
  }

  async function logout() {
    try {
      await refreshCsrfToken();
      await api.post('/api/auth/logout');
    } finally {
      setUser(null);
    }
  }

  return (
    <AuthContext.Provider value={{ user, loading, authError, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}