import React, { useEffect, useState } from 'react';
import axios from 'axios';

type Member = {
  memberId: number;
  fullName: string;
  memberType?: string;
  email?: string;
  phone?: string;
  joinDate?: string;
  status?: string;
};

export default function MembersList() {
  const [members, setMembers] = useState<Member[]>([]);
  const [memberId, setMemberId] = useState<string>('');
  const [name, setName] = useState<string>('');
  const [memberType, setMemberType] = useState<string>('');
  const [loading, setLoading] = useState(false);

  const load = () => {
    setLoading(true);
    const params: any = {};
    if (memberId) params.memberId = Number(memberId);
    if (name) params.name = name;
    if (memberType) params.memberType = memberType;

    axios
      .get('/api/members', { params })
      .then((r) => setMembers(r.data))
      .catch(() => setMembers([]))
      .finally(() => setLoading(false));
  };

  useEffect(() => { load(); }, []);

  return (
    <div style={{ marginTop: 24 }}>
      <h2>Members</h2>

      <div style={{ marginBottom: 12 }}>
        <input placeholder="Member ID" value={memberId} onChange={(e) => setMemberId(e.target.value)} style={{ marginRight: 8 }} />
        <input placeholder="Name" value={name} onChange={(e) => setName(e.target.value)} style={{ marginRight: 8 }} />
        <input placeholder="Type (STUDENT/PROFESSIONAL)" value={memberType} onChange={(e) => setMemberType(e.target.value)} style={{ marginRight: 8 }} />
        <button onClick={() => { load(); }}>Search</button>
        <button onClick={() => { setMemberId(''); setName(''); setMemberType(''); load(); }} style={{ marginLeft: 8 }}>Reset</button>
      </div>

      {loading ? (
        <div>Loading...</div>
      ) : (
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Type</th>
              <th>Email</th>
              <th>Phone</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {members.map((m) => (
              <tr key={m.memberId}>
                <td>{m.memberId}</td>
                <td>{m.fullName}</td>
                <td>{m.memberType}</td>
                <td>{m.email}</td>
                <td>{m.phone}</td>
                <td>{m.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}
