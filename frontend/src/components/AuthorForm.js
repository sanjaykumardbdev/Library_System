import React, { useState } from 'react';
import axios from 'axios';

export default function AuthorForm({ onSaved, onClose }) {
  const [authorName, setAuthorName] = useState('');
  const [country, setCountry] = useState('');
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState('');

  const handleSubmit = async (event) => {
    event.preventDefault();

    if (!authorName.trim()) {
      setError('Author Name is required');
      return;
    }

    try {
      setSaving(true);
      setError('');

      const response = await axios.post(
        'http://localhost:8082/api/authors',
        {
          authorName: authorName.trim(),
          country: country.trim()
        }
      );

      console.log('Created author:', response.data);

      setSaving(false);

      // Tell AuthorLists.js that the author was saved
      onSaved(response.data);

    } catch (error) {
      console.error('Error creating author:', error);

      setError('Unable to save author. Please check the backend.');
      setSaving(false);
    }
  };

  return (
    <div style={styles.overlay}>
      <div style={styles.formContainer}>

        <h2>Add Author</h2>

        <form onSubmit={handleSubmit}>

          <div style={styles.field}>
            <label>Author Name</label>

            <input
              type="text"
              value={authorName}
              onChange={(event) => setAuthorName(event.target.value)}
              placeholder="Enter author name"
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
              placeholder="Enter country"
              disabled={saving}
              style={styles.input}
            />
          </div>

          {error && (
            <p style={styles.error}>
              {error}
            </p>
          )}

          <div style={styles.buttonContainer}>

            <button
              type="submit"
              disabled={saving}
              style={styles.saveButton}
            >
              {saving ? 'Saving...' : 'Save'}
            </button>

            <button
              type="button"
              onClick={onClose}
              disabled={saving}
              style={styles.cancelButton}
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
    padding: 25,
    borderRadius: 8,
    width: 400,
    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.3)'
  },

  field: {
    marginBottom: 15
  },

  input: {
    width: '100%',
    padding: 8,
    marginTop: 5,
    boxSizing: 'border-box'
  },

  error: {
    color: 'red'
  },

  buttonContainer: {
    marginTop: 20,
    display: 'flex',
    gap: 10
  },

  saveButton: {
    padding: '8px 16px',
    cursor: 'pointer'
  },

  cancelButton: {
    padding: '8px 16px',
    cursor: 'pointer'
  }
};