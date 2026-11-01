import React, { useEffect, useState } from 'react';
import api from '../api/client';
import { useAuth } from '../auth/AuthContext';
import BookForm from '../components/BookForm';

export default function BooksList() {
  const { user } = useAuth();
  const isAdmin = user?.roles?.includes('ADMIN');
  const [books, setBooks] = useState([]);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(0);
  const [size, setSize] = useState(10);
  const [loading, setLoading] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState(null);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  const load = () => {
    setLoading(true);
    api
      .get('/api/books', { params: { page, size, search } })
      .then((r) => {
        setBooks(r.data);
        setError('');
      })
      .catch(() => setError('Could not load the book catalog.'))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, [page, size]);

  function openCreate() {
    setEditing(null);
    setShowForm(true);
  }

  function openEdit(b) {
    setEditing(b);
    setShowForm(true);
  }

  function onSaved() {
    setShowForm(false);
    load();
  }

  async function borrowBook(book) {
    setError('');
    setMessage('');
    try {
      await api.post('/api/me/loans', { bookId: book.bookId });
      setMessage(`Borrowed "${book.title}". You can review its due date under My loans.`);
      await load();
    } catch (requestError) {
      setError(requestError.response?.data?.detail || 'Could not borrow this book.');
    }
  }

  function removeBook(bookId) {
    if (!window.confirm('Delete this book from the catalog?')) return;
    api.delete(`/api/books/${bookId}`).then(load).catch(() => window.alert('Delete failed'));
  }

  return (
    <div>
      <h2>Books</h2>
      {error && <p role="alert" style={{ color: '#a32222' }}>{error}</p>}
      {message && <p role="status">{message}</p>}

      <div style={{ marginBottom: 12 }}>
        <input
          placeholder="Search title or ISBN"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
        <button
          onClick={() => {
            setPage(0);
            load();
          }}
        >
          Search
        </button>
        <button
          onClick={() => {
            setSearch('');
            setPage(0);
            load();
          }}
        >
          Reset
        </button>
        {isAdmin && <button onClick={openCreate} style={{ marginLeft: 12 }}>+ Add Book</button>}
      </div>

      {loading ? (
        <div>Loading...</div>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr>
              <th>ID</th>
              <th>Title</th>
              <th>ISBN</th>
              <th>Copies</th>
              <th>Available</th>
              <th>Action</th>
            </tr>
          </thead>
          <tbody>
            {books.map((b) => (
              <tr key={b.bookId}>
                <td>{b.bookId}</td>
                <td>{b.title}</td>
                <td>{b.isbn}</td>
                <td>{b.totalCopies}</td>
                <td>{b.availableCopies ?? 0}</td>
                <td>
                  {isAdmin ? (
                    <><button onClick={() => openEdit(b)}>Edit</button>{' '}<button onClick={() => removeBook(b.bookId)}>Delete</button></>
                  ) : (
                    <button disabled={!b.availableCopies} onClick={() => borrowBook(b)}>Borrow</button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      <div style={{ marginTop: 12 }}>
        <button onClick={() => setPage((p) => Math.max(0, p - 1))}>Prev</button>
        <span style={{ margin: '0 8px' }}>Page {page + 1}</span>
        <button onClick={() => setPage((p) => p + 1)}>Next</button>
        <select
          value={size}
          onChange={(e) => setSize(Number(e.target.value))}
          style={{ marginLeft: 12 }}
        >
          <option value={5}>5</option>
          <option value={10}>10</option>
          <option value={25}>25</option>
        </select>
      </div>

      {showForm && (
        <BookForm onClose={() => setShowForm(false)} onSaved={onSaved} initial={editing} />
      )}
    </div>
  );
}
