import React, { useEffect, useState } from 'react';
import api, { getErrorMessage } from '../api/client';

export default function AdminCirculation() {
  const [members, setMembers] = useState([]);
  const [books, setBooks] = useState([]);
  const [loans, setLoans] = useState([]);
  const [memberId, setMemberId] = useState('');
  const [bookId, setBookId] = useState('');
  const [error, setError] = useState('');

  async function load() {
    try {
      const [memberResponse, bookResponse, loanResponse] = await Promise.all([
        api.get('/api/members'),
        api.get('/api/books', { params: { page: 0, size: 1000 } }),
        api.get('/api/admin/loans'),
      ]);
      setMembers(memberResponse.data);
      setBooks(bookResponse.data);
      setLoans(loanResponse.data);
      setError('');
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not load circulation data.'));
    }
  }

  useEffect(() => { load(); }, []);

  async function issue(event) {
    event.preventDefault();
    setError('');
    try {
      await api.post('/api/admin/loans', { memberId: Number(memberId), bookId: Number(bookId) });
      setMemberId('');
      setBookId('');
      await load();
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not issue this book.'));
    }
  }

  async function returnLoan(loanId) {
    setError('');
    try {
      await api.post(`/api/admin/loans/${loanId}/return`);
      await load();
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not return this book.'));
    }
  }

  return (
    <main>
      <h1>Circulation</h1>
      {error && <p role="alert" style={{ color: '#a32222' }}>{error}</p>}
      <form onSubmit={issue} style={{ display: 'flex', gap: 10, alignItems: 'end', flexWrap: 'wrap', padding: '16px 0', borderBottom: '1px solid #d5d9d5' }}>
        <label>Member<select required value={memberId} onChange={(event) => setMemberId(event.target.value)}><option value="">Select member</option>{members.map((member) => <option key={member.memberId} value={member.memberId}>{member.fullName} (#{member.memberId})</option>)}</select></label>
        <label>Book<select required value={bookId} onChange={(event) => setBookId(event.target.value)}><option value="">Select book</option>{books.map((book) => <option key={book.bookId} value={book.bookId}>{book.title}</option>)}</select></label>
        <button type="submit">Issue book</button>
      </form>
      <h2>Active loans</h2>
      {loans.length === 0 ? <p>No active loans.</p> : (
        <div style={{ overflowX: 'auto' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse', textAlign: 'left' }}>
            <thead><tr><th>Member</th><th>Book</th><th>Copy</th><th>Due</th><th>Action</th></tr></thead>
            <tbody>{loans.map((loan) => (
              <tr key={loan.loanId}>
                <td>{loan.memberName} (#{loan.memberId})</td><td>{loan.bookTitle}</td><td>{loan.copyId}</td>
                <td>{new Date(loan.dueDate).toLocaleDateString()}</td>
                <td><button onClick={() => returnLoan(loan.loanId)}>Return</button></td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}
    </main>
  );
}