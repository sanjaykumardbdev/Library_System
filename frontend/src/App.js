import React from 'react';
import { HashRouter, Routes, Route, Link, Navigate } from 'react-router-dom';
import BooksList from './pages/BooksList';
import MembersList from './pages/MembersList';

export default function App() {
  return (
    <HashRouter>
      <div style={{ padding: 20 }}>
        <h1 style={{ marginBottom: 16 }}>Library Management - Demo UI</h1>

        <div style={{
          display: 'flex',
          alignItems: 'center',
          gap: 12,
          marginBottom: 20,
          justifyContent: 'flex-start'
        }}>
          <Link to="/books" style={{ textDecoration: 'none' }}>
            <button style={{ cursor: 'pointer' }}>Books</button>
          </Link>
          <Link to="/members" style={{ textDecoration: 'none' }}>
            <button style={{ cursor: 'pointer' }}>Members</button>
          </Link>
        </div>

        <Routes>
          <Route path="/" element={<Navigate to="/members" replace />} />
          <Route path="/books" element={<BooksList />} />
          <Route path="/members" element={<MembersList />} />
          <Route path="*" element={<MembersList />} />
        </Routes>
      </div>
    </HashRouter>
  );
}
