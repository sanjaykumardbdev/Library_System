import React, { useEffect, useState } from 'react';
import axios from 'axios';

export default function AuthorLists() {

  const [authors, setAuthors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadAuthors();
  }, []);

  const loadAuthors = async () => {
    try {
      const response = await axios.get(
        'http://localhost:8082/api/authors'
      );

      setAuthors(response.data);
      setLoading(false);

    } catch (error) {
      console.error('Error loading authors:', error);
      setError('Unable to load authors');
      setLoading(false);
    }
  };

  if (loading) {
    return <h2>Loading authors...</h2>;
  }

  if (error) {
    return <h2>{error}</h2>;
  }

  return (
    <div>

      <h2>Authors</h2>

      <table
        border="1"
        cellPadding="8"
        style={{
          borderCollapse: 'collapse',
          width: '600px'
        }}
      >

        <thead>
          <tr>
            <th>Author ID</th>
            <th>Author Name</th>
            <th>Country</th>
          </tr>
        </thead>

        <tbody>

          {authors.map((author) => (
            <tr key={author.authorId}>

              <td>{author.authorId}</td>

              <td>{author.authorName}</td>

              <td>{author.country}</td>

            </tr>
          ))}

        </tbody>

      </table>

    </div>
  );
}