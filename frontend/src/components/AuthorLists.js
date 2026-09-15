import React, { useEffect, useState } from 'react';
import axios from 'axios';
import AuthorForm from '../components/AuthorForm';

export default function AuthorLists() {

  const [authors, setAuthors] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showForm, setShowForm] = useState(false);
  const [selectedAuthor, setSelectedAuthor] = useState(null);

  useEffect(() => {
    loadAuthors();
  }, []);

  const loadAuthors = async () => {
    try {
      setLoading(true);
      setError('');

      const response = await axios.get(
        'http://localhost:8082/api/authors'
      );

      const sortedAuthors = response.data.sort(
        (a, b) => a.authorId - b.authorId
      );

      setAuthors(sortedAuthors);

    } catch (error) {
      console.error('Error loading authors:', error);
      setError('Unable to load authors');

    } finally {
      setLoading(false);
    }
  };

  const handleAddAuthor = () => {
    setSelectedAuthor(null);
    setShowForm(true);
  };

  const handleEditAuthor = (author) => {
    setSelectedAuthor(author);
    setShowForm(true);
  };

  const handleAuthorSaved = (savedAuthor) => {
    setAuthors((previousAuthors) => {

      const exists = previousAuthors.some(
        (author) => author.authorId === savedAuthor.authorId
      );

      let updatedAuthors;

      if (exists) {
        updatedAuthors = previousAuthors.map((author) =>
          author.authorId === savedAuthor.authorId
            ? savedAuthor
            : author
        );
      } else {
        updatedAuthors = [
          ...previousAuthors,
          savedAuthor
        ];
      }

      return updatedAuthors.sort(
        (a, b) => a.authorId - b.authorId
      );
    });

    setShowForm(false);
    setSelectedAuthor(null);
  };

  const handleDeleteAuthor = async (authorId) => {

    const confirmed = window.confirm(
      `Are you sure you want to delete author ${authorId}?`
    );

    if (!confirmed) {
      return;
    }

    try {
      await axios.delete(
        `http://localhost:8082/api/authors/${authorId}`
      );

      setAuthors((previousAuthors) =>
        previousAuthors.filter(
          (author) => author.authorId !== authorId
        )
      );

    } catch (error) {
      console.error('Error deleting author:', error);

      alert('Unable to delete author. Please check the backend.');
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

      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: '20px',
          marginBottom: '15px'
        }}
      >
        <h2>Authors</h2>

        <button
          onClick={handleAddAuthor}
          style={styles.button}
        >
          Add Author
        </button>
      </div>

      <table
        border="1"
        cellPadding="8"
        style={{
          borderCollapse: 'collapse',
          width: '800px'
        }}
      >
        <thead>
          <tr>
            <th>Author ID</th>
            <th>Author Name</th>
            <th>Country</th>
            <th>Actions</th>
          </tr>
        </thead>

        <tbody>
          {authors.map((author) => (
            <tr key={author.authorId}>

              <td>{author.authorId}</td>
              <td>{author.authorName}</td>
              <td>{author.country}</td>

              <td>
                <button
                  onClick={() => handleEditAuthor(author)}
                  style={styles.actionButton}
                >
                  Edit
                </button>

                <button
                  onClick={() => handleDeleteAuthor(author.authorId)}
                  style={styles.deleteButton}
                >
                  Delete
                </button>
              </td>

            </tr>
          ))}
        </tbody>
      </table>

      {showForm && (
        <AuthorForm
          initial={selectedAuthor}
          onSaved={handleAuthorSaved}
          onClose={() => {
            setShowForm(false);
            setSelectedAuthor(null);
          }}
        />
      )}

    </div>
  );
}

const styles = {
  button: {
    padding: '8px 14px',
    cursor: 'pointer'
  },

  actionButton: {
    padding: '5px 10px',
    marginRight: '8px',
    cursor: 'pointer'
  },

  deleteButton: {
    padding: '5px 10px',
    cursor: 'pointer'
  }
};