import React, { useCallback, useEffect, useState } from 'react';
import api, { getErrorMessage, refreshCsrfToken } from '../api/client';
import { useAuth } from '../auth/AuthContext';
import BookForm from '../components/BookForm';

export default function BooksList() {
  const { user } = useAuth();
  const isAdmin = user?.roles?.includes('ADMIN');
  const [books, setBooks] = useState([]);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(0);
  const [size, setSize] = useState(5);
  const [totalPages, setTotalPages] = useState(0);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState(null);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [borrowingId, setBorrowingId] = useState(null);

  const load = useCallback(() => {
    setLoading(true);
    api
      .get('/api/books', { params: { page, size, search } })
      .then((r) => {
        setBooks(r.data.content);
        setTotalPages(r.data.totalPages);
        setError('');
      })
      .catch((requestError) => setError(getErrorMessage(requestError, 'Could not load the book catalog.')))
      .finally(() => setLoading(false));
  }, [page, search, size]);

  useEffect(() => {
    load();
  }, [load]);

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
    setBorrowingId(book.bookId);
    try {
      await refreshCsrfToken();
      await api.post('/api/me/loans', { bookId: book.bookId });
      setMessage(`Borrowed "${book.title}". You can review its due date under My loans.`);
      await load();
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not borrow this book.'));
    } finally {
      setBorrowingId(null);
    }
  }

  async function removeBook(bookId) {
    if (!window.confirm('Delete this book from the catalog?')) return;
    setError('');
    setMessage('');
    try {
      await api.delete(`/api/books/${bookId}`);
      setMessage('Book removed from the catalog.');
      await load();
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not delete the book.'));
    }
  }

  return (
    <section>
      <div className="page-heading">
        <div><p className="eyebrow">DISCOVER YOUR NEXT READ</p><h1>Books</h1></div>
        {isAdmin && <button onClick={openCreate}>+ Add book</button>}
      </div>
      {error && <p role="alert" className="notice notice-error">{error}</p>}
      {message && <p role="status" className="notice notice-success">{message}</p>}

      <div className="toolbar">
        <input
          aria-label="Search books"
          placeholder="Search title or ISBN"
          value={search}
          onChange={(e) => { setSearch(e.target.value); setPage(0); }}
        />
        <button onClick={() => setPage(0)}>Search</button>
        <button className="button-secondary" onClick={() => { setSearch(''); setPage(0); }}>Reset</button>
      </div>

      {loading ? (
        <p role="status">Loading books...</p>
      ) : (
        books.length === 0 ? <p>No books found. Try a different search.</p> : (
          <div className="table-scroll">
            <table className="data-table">
              <thead><tr><th>ID</th><th>Title</th><th>ISBN</th><th>Copies</th><th>Available</th><th>Action</th></tr></thead>
              <tbody>
                {books.map((book) => (
                  <tr key={book.bookId}>
                    <td>{book.bookId}</td>
                    <td className="book-title">{book.title}</td>
                    <td>{book.isbn || '—'}</td>
                    <td>{book.totalCopies}</td>
                    <td>
                      <span className={`availability ${book.availableCopies > 0 ? 'availability-in' : 'availability-out'}`}>
                        {book.availableCopies ?? 0}
                      </span>
                    </td>
                    <td>
                      {isAdmin ? (
                        <div className="action-group">
                          <button className="button-secondary" onClick={() => openEdit(book)}>Edit</button>
                          <button className="button-danger" onClick={() => removeBook(book.bookId)}>Delete</button>
                        </div>
                      ) : (
                        <button
                          disabled={(book.availabilityKnown && book.availableCopies <= 0) || borrowingId === book.bookId}
                          onClick={() => borrowBook(book)}
                          title={book.availabilityKnown && book.availableCopies <= 0 ? 'No copies are currently available' : 'Borrow this book'}
                        >
                          {borrowingId === book.bookId
                            ? 'Borrowing...'
                            : book.availabilityKnown && book.availableCopies <= 0 ? 'Unavailable' : 'Borrow'}
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )
      )}

      <div className="pagination">
        <button disabled={page === 0 || loading} onClick={() => setPage((p) => Math.max(0, p - 1))}>Previous</button>
        <span style={{ margin: '0 8px' }}>Page {totalPages === 0 ? 0 : page + 1} of {totalPages}</span>
        <button disabled={loading || page + 1 >= totalPages} onClick={() => setPage((p) => p + 1)}>Next</button>
        <select
          aria-label="Books per page"
          value={size}
          onChange={(e) => setSize(Number(e.target.value))}
        >
          <option value={5}>5</option>
          <option value={10}>10</option>
          <option value={25}>25</option>
        </select>
      </div>

      {showForm && (
        <BookForm onClose={() => setShowForm(false)} onSaved={onSaved} onError={setError} initial={editing} />
      )}
    </section>
  );
}
