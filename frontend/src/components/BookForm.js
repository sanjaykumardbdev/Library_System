import React, { useEffect, useState } from 'react';
import api, { getErrorMessage } from '../api/client';

export default function BookForm({ initial, onSaved, onClose, onError }) {
  const [title, setTitle] = useState(initial?.title || '');
  const [isbn, setIsbn] = useState(initial?.isbn || '');
  const [totalCopies, setTotalCopies] = useState(initial?.totalCopies || 1);
  const [error, setError] = useState('');

  useEffect(() => {
    setTitle(initial?.title || '');
    setIsbn(initial?.isbn || '');
    setTotalCopies(initial?.totalCopies || 1);
  }, [initial]);

  async function save() {
    if (!title.trim()) {
      setError('Book title is required.');
      return;
    }
    const payload = {
      bookId: initial?.bookId,
      title,
      isbn,
      totalCopies,
    };

    const req = initial?.bookId
      ? api.put(`/api/books/${initial.bookId}`, payload)
      : api.post('/api/books', payload);

    try {
      await req;
      onSaved();
    } catch (error) {
      const message = getErrorMessage(error, 'Could not save this book.');
      setError(message);
      onError(message);
    }
  }

  return (
    <div
      style={{
        position: 'fixed',
        left: 0,
        top: 0,
        right: 0,
        bottom: 0,
        background: 'rgba(0,0,0,0.3)',
      }}
    >
      <div className="book-form-dialog" role="dialog" aria-modal="true" aria-labelledby="book-form-title">
        <h3 id="book-form-title">{initial ? 'Edit Book' : 'Add Book'}</h3>
        {error && <p role="alert" className="notice notice-error">{error}</p>}
        <div>
          <label htmlFor="book-title">Title</label>
          <input id="book-title" value={title} onChange={(e) => setTitle(e.target.value)} style={{ width: '100%' }} />
        </div>
        <div>
          <label htmlFor="book-isbn">ISBN</label>
          <input id="book-isbn" value={isbn} onChange={(e) => setIsbn(e.target.value)} />
        </div>
        <div>
          <label htmlFor="book-copies">Total Copies</label>
          <input id="book-copies" type="number" min="0" max="10000" value={totalCopies} onChange={(e) => setTotalCopies(Number(e.target.value))} />
        </div>
        <div className="action-group">
          <button onClick={save}>Save</button>
          <button className="button-secondary" onClick={onClose}>
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}
