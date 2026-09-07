import React, { useEffect, useState } from 'react';
import axios from 'axios';
import BookForm from '../components/BookForm';

type Book = {
  bookId: number;
  title: string;
  authorId?: number;
  publisherId?: number;
  isbn?: string;
  totalCopies?: number;
};

export default function BooksList() {
  const [books, setBooks] = useState<Book[]>([]);
  const [search, setSearch] = useState('');
  const [page, setPage] = useState(0);
  const [size, setSize] = useState(10);
  const [loading, setLoading] = useState(false);
  const [showForm, setShowForm] = useState(false);
  const [editing, setEditing] = useState<Book | null>(null);

  const load = () => {
    setLoading(true);
    axios
      .get('/api/books', { params: { page, size, search } })
      .then((r) => setBooks(r.data))
      .catch(() => setBooks([]))
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    load();
  }, [page, size]);

  function openCreate() {
    setEditing(null);
    setShowForm(true);
  }

  function openEdit(b: Book) {
    setEditing(b);
    setShowForm(true);
  }

  function onSaved() {
    setShowForm(false);
    load();
  }

  return (
    <div>
      <h2>Books</h2>

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
        <button onClick={openCreate} style={{ marginLeft: 12 }}>
          + Add Book
        </button>
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
                <td>
                  <button onClick={() => openEdit(b)}>Edit</button>
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
