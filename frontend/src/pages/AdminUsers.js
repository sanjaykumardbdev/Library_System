import React, { useEffect, useState } from 'react';
import api, { getErrorMessage } from '../api/client';

export default function AdminUsers() {
  const [users, setUsers] = useState([]);
  const [activity, setActivity] = useState([]);
  const [edits, setEdits] = useState({});
  const [savingUserId, setSavingUserId] = useState(null);
  const [error, setError] = useState('');
  const [message, setMessage] = useState('');

  async function load() {
    try {
      const [userResponse, activityResponse] = await Promise.all([
        api.get('/api/admin/users'),
        api.get('/api/admin/login-activity', { params: { limit: 100 } }),
      ]);
      setUsers(userResponse.data);
      setActivity(activityResponse.data);
      setEdits(Object.fromEntries(userResponse.data.map((user) => [
        user.userId,
        { roles: user.roles, status: user.status },
      ])));
      setError('');
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not load user administration data.'));
    }
  }

  useEffect(() => { load(); }, []);

  function updateUser(userId, update) {
    setEdits((current) => ({ ...current, [userId]: { ...current[userId], ...update } }));
  }

  function toggleRole(userId, role, checked) {
    const roles = new Set(edits[userId]?.roles || []);
    if (checked) roles.add(role);
    else roles.delete(role);
    updateUser(userId, { roles: Array.from(roles) });
  }

  async function saveUser(userId) {
    setSavingUserId(userId);
    setError('');
    setMessage('');
    try {
      await api.patch(`/api/admin/users/${userId}`, edits[userId]);
      setMessage('Account access updated.');
      await load();
    } catch (requestError) {
      setError(getErrorMessage(requestError, 'Could not update this account.'));
    } finally {
      setSavingUserId(null);
    }
  }

  return (
    <main>
      <h1>App users and access</h1>
      <p>Manage account status and member or administrator roles. At least one active administrator must remain.</p>
      {error && <p role="alert" className="notice notice-error">{error}</p>}
      {message && <p role="status" className="notice notice-success">{message}</p>}

      <div style={{ overflowX: 'auto' }}>
        <table className="data-table">
          <thead>
            <tr><th>User</th><th>Member</th><th>Email</th><th>Roles</th><th>Status</th><th>Action</th></tr>
          </thead>
          <tbody>
            {users.map((user) => {
              const edit = edits[user.userId] || { roles: user.roles, status: user.status };
              return (
                <tr key={user.userId}>
                  <td>{user.username} (#{user.userId})</td>
                  <td>{user.memberName ? `${user.memberName} (#${user.memberId})` : 'No linked member'}</td>
                  <td>{user.email}</td>
                  <td>
                    {['MEMBER', 'ADMIN'].map((role) => (
                      <label key={role} style={{ marginRight: 10 }}>
                        <input
                          type="checkbox"
                          checked={edit.roles.includes(role)}
                          onChange={(event) => toggleRole(user.userId, role, event.target.checked)}
                        />
                        {role}
                      </label>
                    ))}
                  </td>
                  <td>
                    <select value={edit.status} onChange={(event) => updateUser(user.userId, { status: event.target.value })}>
                      <option value="ACTIVE">Active</option>
                      <option value="DISABLED">Disabled</option>
                    </select>
                  </td>
                  <td>
                    <button disabled={savingUserId === user.userId} onClick={() => saveUser(user.userId)}>
                      {savingUserId === user.userId ? 'Saving...' : 'Save access'}
                    </button>
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      <h2>Successful login activity</h2>
      <p>Most recent 100 successful sign-ins.</p>
      {activity.length === 0 ? <p>No login activity recorded.</p> : (
        <div style={{ overflowX: 'auto' }}>
          <table className="data-table">
            <thead><tr><th>User</th><th>Email</th><th>Signed in</th></tr></thead>
            <tbody>{activity.map((entry) => (
              <tr key={entry.loginId}>
                <td>{entry.username} (#{entry.userId})</td>
                <td>{entry.email}</td>
                <td>{new Date(entry.loggedInAt).toLocaleString()}</td>
              </tr>
            ))}</tbody>
          </table>
        </div>
      )}
    </main>
  );
}
