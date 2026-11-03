import React, { useEffect, useState } from 'react';
import api, { getErrorMessage } from '../api/client';

export default function MembersList() {
  const [members, setMembers] = useState([]);
  const [memberId, setMemberId] = useState('');
  const [name, setName] = useState('');
  const [memberType, setMemberType] = useState('');
  const [view, setView] = useState('ALL');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function load(filters = { memberId, name, memberType, view }) {
    setLoading(true);
    const params = {};
    if (filters.memberId) params.memberId = Number(filters.memberId);
    if (filters.name) params.name = filters.name;
    if (filters.memberType) params.memberType = filters.memberType;
    if (filters.view === 'ACTIVE') params.status = 'ACTIVE';
    if (filters.view === 'APP_USERS') params.hasAppUser = true;
    setError('');
    try {
      const response = await api.get('/api/members', { params });
      setMembers(response.data);
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not load library members.'));
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    load();
  }, []);

  return (
    <section>
      <div className="page-heading"><div><p className="eyebrow">LIBRARY DIRECTORY</p><h1>Members</h1></div></div>
      <p>Search members by ID, name, or member type.</p>
      {error && <p role="alert" className="notice notice-error">{error}</p>}

      <div className="action-group member-view-tabs" aria-label="Member list filters">
        <button className={view === 'ACTIVE' ? '' : 'button-secondary'} onClick={() => {
          setView('ACTIVE');
          load({ memberId, name, memberType, view: 'ACTIVE' });
        }}>Active members</button>
        <button className={view === 'ALL' ? '' : 'button-secondary'} onClick={() => {
          setView('ALL');
          load({ memberId, name, memberType, view: 'ALL' });
        }}>All members</button>
        <button className={view === 'APP_USERS' ? '' : 'button-secondary'} onClick={() => {
          setView('APP_USERS');
          load({ memberId, name, memberType, view: 'APP_USERS' });
        }}>Members with app accounts</button>
      </div>

      <div className="toolbar">
        <input aria-label="Member ID" placeholder="Member ID" value={memberId} onChange={(e) => setMemberId(e.target.value)} />
        <input aria-label="Member name" placeholder="Name" value={name} onChange={(e) => setName(e.target.value)} />
        <select aria-label="Member type" value={memberType} onChange={(e) => setMemberType(e.target.value)}>
          <option value="">All member types</option><option value="STUDENT">Student</option><option value="PROFESSIONAL">Professional</option>
        </select>
        <button onClick={() => load()}>Search members</button>
        <button className="button-secondary" onClick={() => {
          setMemberId('');
          setName('');
          setMemberType('');
          setView('ALL');
          load({ memberId: '', name: '', memberType: '', view: 'ALL' });
        }}>Reset</button>
      </div>

      {loading ? (
        <p role="status">Loading members...</p>
      ) : (
        members.length === 0 ? <p>No members matched your search.</p> : (
          <div className="table-scroll">
            <table className="data-table">
              <thead><tr><th>ID</th><th>Name</th><th>Type</th><th>Email</th><th>Phone</th><th>Status</th><th>App user</th></tr></thead>
              <tbody>{members.map((member) => (
                <tr key={member.memberId}>
                  <td>{member.memberId}</td><td>{member.fullName}</td><td>{member.memberType}</td>
                  <td>{member.email}</td><td>{member.phone || '—'}</td><td>{member.status}</td>
                  <td>{member.hasAppUser ? 'Yes' : 'No'}</td>
                </tr>
              ))}</tbody>
            </table>
          </div>
        )
      )}
    </section>
  );
}
