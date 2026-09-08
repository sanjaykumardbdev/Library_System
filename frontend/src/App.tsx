import React from 'react';
import { BrowserRouter, Routes, Route, Link, Navigate } from 'react-router-dom';
import BooksList from './pages/BooksList';
import MembersList from './pages/MembersList';

export default function App() {
  return (
    <BrowserRouter>
      <div style={{ padding: 20 }}>
        <h1>Library Management - Demo UI</h1>

        <div style={{ marginBottom: 16 }}>
          <Link to="/books"><button style={{ marginRight: 8 }}>Books</button></Link>
          <Link to="/members"><button>Members</button></Link>
        </div>

        <Routes>
          <Route path="/" element={<Navigate to="/members" replace />} />
          <Route path="/books" element={<BooksList />} />
          <Route path="/members" element={<MembersList />} />
          <Route path="*" element={<MembersList />} />
        </Routes>
      </div>
    </BrowserRouter>
  );
}
