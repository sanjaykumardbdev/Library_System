import React, { useEffect, useState } from 'react';
import api, { getErrorMessage } from '../api/client';

export default function AdminCirculation() {
  const [members, setMembers] = useState([]);
  const [books, setBooks] = useState([]);
  const [loans, setLoans] = useState([]);
  const [history, setHistory] = useState([]);
  const [account, setAccount] = useState(null);
  const [deposits, setDeposits] = useState([]);
  const [memberId, setMemberId] = useState('');
  const [bookId, setBookId] = useState('');
  const [error, setError] = useState('');

  async function load() {
    try {
      const [memberResponse, bookResponse, loanResponse, historyResponse, accountResponse, depositsResponse] = await Promise.all([
        api.get('/api/members'),
        api.get('/api/books', { params: { page: 0, size: 100 } }),
        api.get('/api/admin/loans'),
        api.get('/api/admin/loans/history'),
        api.get('/api/admin/finance/account'),
        api.get('/api/admin/finance/deposits'),
      ]);
      const firstBookPage = bookResponse.data;
      const remainingBookPages = await Promise.all(
        Array.from({ length: Math.max(0, firstBookPage.totalPages - 1) }, (_, index) =>
          api.get('/api/books', { params: { page: index + 1, size: 100 } }))
      );
      setMembers(memberResponse.data);
      setBooks([
        ...firstBookPage.content,
        ...remainingBookPages.flatMap((response) => response.data.content),
      ]);
      setLoans(loanResponse.data);
      setHistory(historyResponse.data);
      setAccount(accountResponse.data);
      setDeposits(depositsResponse.data);
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

  async function markLost(loan) {
    const enteredAmount = window.prompt(`Enter the lost-book charge for "${loan.bookTitle}" (amount in units):`, '0.00');
    if (enteredAmount === null) return;
    const amount = Number(enteredAmount);
    if (!Number.isFinite(amount) || amount <= 0) {
      setError('Enter a lost-book charge greater than zero.');
      return;
    }
    setError('');
    try {
      await api.post(`/api/admin/loans/${loan.loanId}/lost`, { amount });
      await load();
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not mark this book as lost.'));
    }
  }

  async function receivePayment(loan) {
    const enteredAmount = window.prompt(
      `Outstanding balance: ${Number(loan.balanceDue).toFixed(2)} units. Enter amount collected:`,
      Number(loan.balanceDue).toFixed(2));
    if (enteredAmount === null) return;
    const amount = Number(enteredAmount);
    if (!Number.isFinite(amount) || amount <= 0) {
      setError('Enter a payment greater than zero.');
      return;
    }
    setError('');
    try {
      await api.post(`/api/admin/loans/${loan.loanId}/payments`, { amount });
      await load();
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not record this payment.'));
    }
  }

  async function depositCollectedFines() {
    setError('');
    try {
      await api.post('/api/admin/finance/deposits');
      await load();
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not deposit collected fines.'));
    }
  }

  return (
    <main>
      <h1>Circulation</h1>
      {error && <p role="alert" className="notice notice-error">{error}</p>}
      <form onSubmit={issue} style={{ display: 'flex', gap: 10, alignItems: 'end', flexWrap: 'wrap', padding: '16px 0', borderBottom: '1px solid #d5d9d5' }}>
        <label>Member<select required value={memberId} onChange={(event) => setMemberId(event.target.value)}><option value="">Select member</option>{members.map((member) => <option key={member.memberId} value={member.memberId}>{member.fullName} (#{member.memberId})</option>)}</select></label>
        <label>Book<select required value={bookId} onChange={(event) => setBookId(event.target.value)}><option value="">Select available book</option>{books.filter((book) => book.availableCopies > 0).map((book) => <option key={book.bookId} value={book.bookId}>{book.title} ({book.availableCopies} available)</option>)}</select></label>
        <button type="submit">Issue book</button>
      </form>
      <h2>Active loans</h2>
      {loans.length === 0 ? <p>No active loans.</p> : (
        <div style={{ overflowX: 'auto' }}>
          <table className="data-table">
            <thead><tr><th>Member</th><th>Book</th><th>Copy</th><th>Due</th><th>Status</th><th>Fine (units)</th><th>Action</th></tr></thead>
            <tbody>{loans.map((loan) => (
              <tr key={loan.loanId}>
                <td>{loan.memberName} (#{loan.memberId})</td><td>{loan.bookTitle}</td><td>{loan.copyId}</td>
                <td>{new Date(loan.dueDate).toLocaleDateString()}</td><td>{loan.status}</td>
                <td>{Number(loan.fineAmount || 0).toFixed(2)}</td>
                <td><button onClick={() => returnLoan(loan.loanId)}>Return</button>{' '}<button onClick={() => markLost(loan)}>Mark lost</button></td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}

      <h2>Loan balances</h2>
      {history.length === 0 ? <p>No loan history.</p> : (
        <div style={{ overflowX: 'auto' }}>
          <table className="data-table">
            <thead><tr><th>Member</th><th>Book</th><th>Status</th><th>Fine / charge (units)</th><th>Paid</th><th>Balance due</th><th>Action</th></tr></thead>
            <tbody>{history.map((loan) => (
              <tr key={loan.loanId}>
                <td>{loan.memberName} (#{loan.memberId})</td><td>{loan.bookTitle}</td><td>{loan.status}</td>
                <td>{Number(loan.fineAmount || 0).toFixed(2)}</td>
                <td>{Number(loan.amountPaid || 0).toFixed(2)}</td>
                <td>{Number(loan.balanceDue || 0).toFixed(2)}</td>
                <td>{Number(loan.balanceDue) > 0 && (loan.status === 'RETURNED' || loan.status === 'LOST')
                  ? <button onClick={() => receivePayment(loan)}>Collect payment</button>
                  : '—'}</td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}

      <h2>Library fine account</h2>
      {account && (
        <section>
          <p>{account.accountName} · Account reference: {account.accountReference || 'Not configured'} · Balance: {Number(account.currentBalance || 0).toFixed(2)} units</p>
          <p>Collected and awaiting deposit: {Number(account.availableToDeposit || 0).toFixed(2)} units</p>
          <button disabled={Number(account.availableToDeposit) <= 0} onClick={depositCollectedFines}>Deposit all collected fines</button>
          <p>This records the deposit in the library account ledger; it does not initiate a bank transfer.</p>
        </section>
      )}
      <h3>Deposit history</h3>
      {deposits.length === 0 ? <p>No fine deposits recorded.</p> : (
        <ul>{deposits.map((deposit) => (
          <li key={deposit.depositId}>
            {Number(deposit.amount).toFixed(2)} units · {deposit.depositedBy} · {new Date(deposit.depositedAt).toLocaleString()}
          </li>
        ))}</ul>
      )}
    </main>
  );
}