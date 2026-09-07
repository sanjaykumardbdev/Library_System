import React, { useEffect, useState } from 'react';
import axios from 'axios';

type Props = {
  initial?: any;
  onSaved: () => void;
  onClose: () => void;
}

export default function BookForm({ initial, onSaved, onClose }: Props) {
  const [title, setTitle] = useState(initial?.title || '');
  const [isbn, setIsbn] = useState(initial?.isbn || '');
  const [totalCopies, setTotalCopies] = useState(initial?.totalCopies || 1);

  useEffect(() => {
    setTitle(initial?.title || '');
    setIsbn(initial?.isbn || '');
    setTotalCopies(initial?.totalCopies || 1);
  }, [initial]);

  function save() {
    const payload = {
      bookId: initial?.bookId,
      title,
      isbn,
      totalCopies
    };
    const req = initial?.bookId ? axios.put(`/api/books/${initial.bookId}`, payload) : axios.post('/api/books', payload);
    req.then(() => onSaved()).catch(err => alert('Save failed'));
  }

  return (
    <div style={{ position: 'fixed', left: 0, top: 0, right: 0, bottom: 0, background: 'rgba(0,0,0,0.3)' }}>
      <div style={{ width: 600, margin: '80px auto', background: '#fff', padding: 20 }}>
        <h3>{initial ? 'Edit Book' : 'Add Book'}</h3>
        <div>
          <label>Title</label><br />
          <input value={title} onChange={e => setTitle(e.target.value)} style={{ width: '100%' }} />
        </div>
        <div>
          <label>ISBN</label><br />
          <input value={isbn} onChange={e => setIsbn(e.target.value)} />
        </div>
        <div>
          <label>Total Copies</label><br />
          <input type="number" value={totalCopies} onChange={e => setTotalCopies(Number(e.target.value))} />
        </div>
        <div style={{ marginTop: 12 }}>
          <button onClick={save}>Save</button>
          <button onClick={onClose} style={{ marginLeft: 8 }}>Cancel</button>
        </div>
      </div>
    </div>
  );
}
