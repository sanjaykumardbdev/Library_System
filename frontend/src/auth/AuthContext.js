import React, { createContext, useContext, useEffect, useState } from 'react';
import api, { refreshCsrfToken } from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let active = true;
    async function initialize() {
      try {
        await refreshCsrfToken();
        const response = await api.get('/api/auth/me');
        if (active) setUser(response.data);
      } catch {
        if (active) setUser(null);
      } finally {
        if (active) setLoading(false);
      }
    }
    initialize();
    return () => { active = false; };
  }, []);

  async function login(credentials) {
    await refreshCsrfToken();
    const response = await api.post('/api/auth/login', credentials);
    setUser(response.data);
    return response.data;
  }

  async function register(profile) {
    await refreshCsrfToken();
    const response = await api.post('/api/auth/register', profile);
    setUser(response.data);
    return response.data;
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
    <AuthContext.Provider value={{ user, loading, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) throw new Error('useAuth must be used within AuthProvider');
  return context;
}