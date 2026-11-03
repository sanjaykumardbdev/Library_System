// Import React and the React hooks that we need
import React, { useEffect, useState } from 'react';

// Import Axios to call the Spring Boot REST APIs
import axios from 'axios';

// Import the AuthorForm component used for Add and Edit operations
import AuthorForm from '../components/AuthorForm';


// This is the main React component for the Authors page
export default function AuthorLists() {

  // Stores the list of authors returned by the backend
  const [authors, setAuthors] = useState([]);

  // Controls whether the page is loading data
  const [loading, setLoading] = useState(true);

  // Stores an error message if the API call fails
  const [error, setError] = useState('');

  // Controls whether the Add/Edit form is visible
  const [showForm, setShowForm] = useState(false);

  // Stores the author selected for editing
  // It is null when we are adding a new author
  const [selectedAuthor, setSelectedAuthor] = useState(null);


  // useEffect runs when this component is loaded
  useEffect(() => {

    // Load author records from the backend
    loadAuthors();

  }, []); // Empty array means this runs only once when the page loads


  // Function to fetch all authors from Spring Boot
  const loadAuthors = async () => {

    try {

      // Show the loading message
      setLoading(true);

      // Clear any previous error message
      setError('');

      // Call the backend GET API
      const response = await axios.get(
        'http://localhost:8082/api/authors'
      );

      // response.data contains the JSON array returned by Spring Boot
      // Example:
      // [
      //   {
      //     "authorId": 110,
      //     "authorName": "Sanjay Kumar",
      //     "country": "India"
      //   }
      // ]

      // Create a copy of the response array and sort by author ID
      const sortedAuthors = [...response.data].sort(
        (a, b) => a.authorId - b.authorId
      );

      // Store the sorted author list in React state
      // Updating state causes React to refresh the table
      setAuthors(sortedAuthors);

    } catch (error) {

      // Print the actual error in the browser console
      console.error('Error loading authors:', error);

      // Display a user-friendly error message on the page
      setError('Unable to load authors');

    } finally {

      // Hide the loading message whether the API succeeds or fails
      setLoading(false);
    }
  };


  // This function runs when the user clicks "Add Author"
  const handleAddAuthor = () => {

    // null means that no existing author is being edited
    setSelectedAuthor(null);

    // Display the AuthorForm component
    setShowForm(true);
  };


  // This function runs when the user clicks "Edit"
  const handleEditAuthor = (author) => {

    // Store the selected author in state
    // Example:
    // {
    //   authorId: 110,
    //   authorName: "Sanjay Kumar",
    //   country: "India"
    // }
    setSelectedAuthor(author);

    // Display the form in Edit mode
    setShowForm(true);
  };


  // This function runs after Add or Edit is successfully completed
  const handleAuthorSaved = async () => {

    // Reload the latest data from Oracle through the backend
    await loadAuthors();

    // Hide the Add/Edit form
    setShowForm(false);

    // Clear the selected author
    setSelectedAuthor(null);
  };


  // This function runs when the user clicks "Delete"
  const handleDeleteAuthor = async (authorId) => {

    // Display a confirmation popup before deleting
    const confirmed = window.confirm(
      `Are you sure you want to delete author ${authorId}?`
    );

    // If the user clicks Cancel, stop the function
    if (!confirmed) {
      return;
    }

    try {

      // Call the DELETE API using the selected author ID
      // Example:
      // DELETE http://localhost:8082/api/authors/110
      await axios.delete(
        `http://localhost:8082/api/authors/${authorId}`
      );

      // Remove the deleted author from the current React state
      // This immediately removes the row from the UI
      setAuthors((previousAuthors) =>
        previousAuthors.filter(
          (author) => author.authorId !== authorId
        )
      );

    } catch (error) {

      // Print the error in the browser console
      console.error('Error deleting author:', error);

      // Show an error message to the user
      alert('Unable to delete author. Please check the backend.');
    }
  };


  // Display this message while the GET API is running
  if (loading) {
    return <h2>Loading authors...</h2>;
  }


  // Display this message if loading failed
  if (error) {
    return <h2>{error}</h2>;
  }


  // JSX is the HTML-like code displayed on the browser
  return (
    <div>

      {/* Header section containing the page title and Add button */}
      <div style={styles.header}>

        {/* Page heading */}
        <h2>Authors</h2>

        {/* Button to open the Add Author form */}
        <button
          onClick={handleAddAuthor}
          style={styles.addButton}
        >
          Add Author
        </button>

      </div>


      {/* Table used to display the authors */}
      <table
        border="1"
        cellPadding="8"
        style={styles.table}
      >

        {/* Table heading section */}
        <thead>
          <tr>
            <th>Author ID</th>
            <th>Author Name</th>
            <th>Country</th>
            <th>Actions</th>
          </tr>
        </thead>


        {/* Table data section */}
        <tbody>

          {/* Loop through every author in the authors array */}
          {authors.map((author) => (

            // React requires a unique key for every table row
            <tr key={author.authorId}>

              {/* Display the author ID */}
              <td>{author.authorId}</td>

              {/* Display the author name */}
              <td>{author.authorName}</td>

              {/* Display the country */}
              <td>{author.country || ''}</td>

              {/* Display Edit and Delete buttons */}
              <td>

                {/* Edit button */}
                <button
                  onClick={() => handleEditAuthor(author)}
                  style={styles.editButton}
                >
                  Edit
                </button>


                {/* Delete button */}
                <button
                  onClick={() =>
                    handleDeleteAuthor(author.authorId)
                  }
                  style={styles.deleteButton}
                >
                  Delete
                </button>

              </td>
            </tr>
          ))}

        </tbody>
      </table>


      {/* Display AuthorForm only when showForm is true */}
      {showForm && (

        <AuthorForm

          // Pass the selected author to the form
          // null means Add mode
          // object means Edit mode
          initial={selectedAuthor}

          // Function that runs after saving successfully
          onSaved={handleAuthorSaved}

          // Function to close the form
          onClose={() => {
            setShowForm(false);
            setSelectedAuthor(null);
          }}

        />
      )}

    </div>
  );
}


// CSS-like inline style objects
const styles = {

  // Styles for the page heading and Add button
  header: {
    display: 'flex',
    alignItems: 'center',
    gap: '20px',
    marginBottom: '15px'
  },

  // Style for the Add Author button
  addButton: {
    padding: '8px 14px',
    cursor: 'pointer'
  },

  // Style for the authors table
  table: {
    borderCollapse: 'collapse',
    width: '800px'
  },

  // Style for the Edit button
  editButton: {
    padding: '5px 10px',
    marginRight: '8px',
    cursor: 'pointer'
  },

  // Style for the Delete button
  deleteButton: {
    padding: '5px 10px',
    cursor: 'pointer'
  }
};