import React, { useEffect, useState } from 'react';
import api, { getErrorMessage } from '../api/client';

export default function MyLoans() {
  const [loans, setLoans] = useState([]);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');
  const [busyLoanId, setBusyLoanId] = useState(null);

  async function load() {
    try {
      const response = await api.get('/api/me/loans');
      setLoans(response.data);
      setError('');
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not load loan history.'));
    }
  }

  useEffect(() => { load(); }, []);

  async function returnBook(loan) {
    setBusyLoanId(loan.loanId);
    setError('');
    setMessage('');
    try {
      await api.post(`/api/me/loans/${loan.loanId}/return`);
      setMessage(`Returned "${loan.bookTitle}".`);
      await load();
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not return this book.'));
    } finally {
      setBusyLoanId(null);
    }
  }

  return (
    <main>
      <h1>My loans</h1>
      {error && <p role="alert" className="notice notice-error">{error}</p>}
      {message && <p role="status" className="notice notice-success">{message}</p>}
      {!error && loans.length === 0 && <p>No loan history found.</p>}
      {loans.length > 0 && (
        <div style={{ overflowX: 'auto' }}>
          <table className="data-table">
            <thead><tr><th>Book</th><th>Copy</th><th>Borrowed</th><th>Due</th><th>Returned</th><th>Status</th><th>Fine (units)</th><th>Paid</th><th>Balance due</th><th>Action</th></tr></thead>
            <tbody>{loans.map((loan) => (
              <tr key={loan.loanId}>
                <td>{loan.bookTitle}</td><td>{loan.copyId}</td>
                <td>{new Date(loan.borrowedAt).toLocaleDateString()}</td>
                <td>{new Date(loan.dueDate).toLocaleDateString()}</td>
                <td>{loan.returnedAt ? new Date(loan.returnedAt).toLocaleDateString() : 'Not returned'}</td>
                <td>{loan.status}</td>
                <td>{Number(loan.fineAmount || 0).toFixed(2)}</td>
                <td>{Number(loan.amountPaid || 0).toFixed(2)}</td>
                <td>{Number(loan.balanceDue || 0).toFixed(2)}</td>
                <td>{!loan.returnedAt && loan.status !== 'LOST' && <button disabled={busyLoanId === loan.loanId} onClick={() => returnBook(loan)}>{busyLoanId === loan.loanId ? 'Returning...' : 'Return book'}</button>}</td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}
    </main>
  );
}