import React, { useEffect, useState } from 'react';
import axios from 'axios';

export default function AuthorForm({ initial, onSaved, onClose }) {

  const [authorName, setAuthorName] = useState('');
  const [country, setCountry] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const isEditMode = Boolean(initial);

  useEffect(() => {
    setAuthorName(initial?.authorName || '');
    setCountry(initial?.country || '');
    setError('');
  }, [initial]);

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!authorName.trim()) {
      setError('Author Name is required');
      return;
    }

    try {
      setSaving(true);
      setError('');

      const payload = {
        authorName: authorName.trim(),
        country: country.trim()
      };

      let response;

      if (isEditMode) {
        response = await axios.put(
          `http://localhost:8082/api/authors/${initial.authorId}`,
          payload
        );
      } else {
        response = await axios.post(
          'http://localhost:8082/api/authors',
          payload
        );
      }

      onSaved(response.data);

    } catch (error) {
      console.error('Error saving author:', error);

      if (error.response) {
        setError(
          `Save failed: ${error.response.status} - ${
            typeof error.response.data === 'string'
              ? error.response.data
              : JSON.stringify(error.response.data)
          }`
        );
      } else if (error.request) {
        setError('No response received from Spring Boot on port 8082.');
      } else {
        setError(`Request error: ${error.message}`);
      }

    } finally {
      setSaving(false);
    }
  };

  return (
    <div style={styles.overlay}>
      <div style={styles.formContainer}>

        <h2>{isEditMode ? 'Edit Author' : 'Add Author'}</h2>

        <form onSubmit={handleSubmit}>

          <div style={styles.field}>
            <label>Author Name</label>

            <input
              type="text"
              value={authorName}
              onChange={(event) => setAuthorName(event.target.value)}
              disabled={saving}
              style={styles.input}
            />
          </div>

          <div style={styles.field}>
            <label>Country</label>

            <input
              type="text"
              value={country}
              onChange={(event) => setCountry(event.target.value)}
              disabled={saving}
              style={styles.input}
            />
          </div>

          {error && (
            <p style={styles.error}>{error}</p>
          )}

          <div style={styles.buttonContainer}>

            <button
              type="submit"
              disabled={saving}
              style={styles.button}
            >
              {saving ? 'Saving...' : 'Save'}
            </button>

            <button
              type="button"
              onClick={onClose}
              disabled={saving}
              style={styles.button}
            >
              Cancel
            </button>

          </div>

        </form>
      </div>
    </div>
  );
}

const styles = {
  overlay: {
    position: 'fixed',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    backgroundColor: 'rgba(0, 0, 0, 0.4)',
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
    zIndex: 1000
  },

  formContainer: {
    backgroundColor: 'white',
    padding: '25px',
    borderRadius: '8px',
    width: '400px',
    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.3)'
  },

  field: {
    marginBottom: '15px'
  },

  input: {
    width: '100%',
    padding: '8px',
    marginTop: '5px',
    boxSizing: 'border-box'
  },

  error: {
    color: 'red'
  },

  buttonContainer: {
    display: 'flex',
    gap: '10px',
    marginTop: '20px'
  },

  button: {
    padding: '8px 16px',
    cursor: 'pointer'
  }
};