// Import React and two React hooks:
// useEffect  -> runs code when the component loads
// useState   -> stores data that can change in the UI
import React, { useEffect, useState } from 'react';

// Import Axios to call the Spring Boot REST APIs
import axios from 'axios';

// Import the AuthorForm component used for adding and editing authors
import AuthorForm from '../components/AuthorForm';


// Main React component for the Authors page
export default function AuthorLists() {

  // Stores all author records returned from the backend
  // Initially, the array is empty
  const [authors, setAuthors] = useState([]);

  // Indicates whether author data is currently being loaded
  // Initially true because data must be fetched when the page opens
  const [loading, setLoading] = useState(true);

  // Stores an error message if an API request fails
  // Initially, there is no error
  const [error, setError] = useState('');

  // Controls whether the Add/Edit form is displayed
  // false means the form is hidden initially
  const [showForm, setShowForm] = useState(false);

  // Stores the author selected for editing
  // null means that no author is currently selected
  const [selectedAuthor, setSelectedAuthor] = useState(null);


  // useEffect runs after the component is loaded
  useEffect(() => {

    // Call the function that loads authors from the backend
    loadAuthors();

  }, []); // Empty array means this runs only when the component first loads


  // Function to retrieve all authors from the Spring Boot backend
  const loadAuthors = async () => {

    try {

      // Set loading to true while the API request is running
      setLoading(true);

      // Clear any previous error message
      setError('');


      // Send a GET request to the Spring Boot API
      const response = await axios.get(
        'http://localhost:8082/api/authors'
      );

      // response.data contains the author records returned by the backend
      //
      // Example response.data:
      // [
      //   {
      //     authorId: 100,
      //     authorName: "Rabindranath Tagore",
      //     country: "India"
      //   },
      //   {
      //     authorId: 110,
      //     authorName: "Sanjay Kumar",
      //     country: "India"
      //   }
      // ]


      // Sort the authors by authorId in ascending order
      //
      // a.authorId - b.authorId means:
      // smaller IDs appear before larger IDs
      //
      // sort() changes the original array returned by the API
      const sortedAuthors = response.data.sort(
        (a, b) => a.authorId - b.authorId
      );


      // Store the sorted author list in React state
      // React will re-render the page and display the records in the table
      setAuthors(sortedAuthors);


    } catch (error) {

      // Print the technical error details in the browser console
      // Useful for debugging API or backend problems
      console.error('Error loading authors:', error);

      // Display a simple error message to the user
      setError('Unable to load authors');


    } finally {

      // This code runs whether the API succeeds or fails
      // Hide the loading message
      setLoading(false);
    }
  };


  // Function executed when the user clicks the "Add Author" button
  const handleAddAuthor = () => {

    // Set selectedAuthor to null because we are adding a new author
    // No existing author should be loaded into the form
    setSelectedAuthor(null);

    // Make the AuthorForm component visible
    setShowForm(true);
  };


  // Function executed when the user clicks an "Edit" button
  // The selected author record is received as an argument
  const handleEditAuthor = (author) => {

    // Store the selected author for editing
    // Example:
    // {
    //   authorId: 110,
    //   authorName: "Sanjay Kumar",
    //   country: "India"
    // }
    setSelectedAuthor(author);

    // Display the AuthorForm component
    setShowForm(true);
  };


  // Function executed after an author is successfully added or edited
  // savedAuthor contains the record returned by the backend
  const handleAuthorSaved = (savedAuthor) => {

    // Update the authors array in React state
    // previousAuthors represents the current list of authors
    setAuthors((previousAuthors) => {


      // Check whether the saved author already exists in the list
      //
      // some() returns true if at least one author has the same authorId
      //
      // If true  -> the record is being edited
      // If false -> the record is newly added
      const exists = previousAuthors.some(
        (author) => author.authorId === savedAuthor.authorId
      );


      // Variable that will contain the new author list
      let updatedAuthors;


      // If the author already exists, update that author
      if (exists) {

        // map() loops through every author
        //
        // If the IDs match:
        //     replace the old record with savedAuthor
        //
        // If the IDs do not match:
        //     keep the existing author
        updatedAuthors = previousAuthors.map((author) =>
          author.authorId === savedAuthor.authorId
            ? savedAuthor
            : author
        );


      } else {

        // If the author does not exist, add the new author
        //
        // ...previousAuthors copies all existing records
        // savedAuthor is added at the end of the array
        updatedAuthors = [
          ...previousAuthors,
          savedAuthor
        ];
      }


      // Sort the updated list by author ID
      // This keeps the table in ascending ID order
      return updatedAuthors.sort(
        (a, b) => a.authorId - b.authorId
      );
    });


    // Hide the Add/Edit form after successful saving
    setShowForm(false);

    // Clear the selected author
    setSelectedAuthor(null);
  };


  // Function executed when the user clicks the "Delete" button
  // authorId identifies which author should be deleted
  const handleDeleteAuthor = async (authorId) => {


    // Display a confirmation popup before deleting
    const confirmed = window.confirm(
      `Are you sure you want to delete author ${authorId}?`
    );


    // If the user clicks Cancel, stop the function
    // No DELETE request will be sent
    if (!confirmed) {
      return;
    }


    try {

      // Send a DELETE request to the Spring Boot backend
      //
      // Example:
      // DELETE http://localhost:8082/api/authors/110
      await axios.delete(
        `http://localhost:8082/api/authors/${authorId}`
      );


      // Remove the deleted author from the React state
      //
      // filter() creates a new array
      // Only authors whose ID is different from authorId are retained
      //
      // This immediately removes the deleted row from the UI
      setAuthors((previousAuthors) =>
        previousAuthors.filter(
          (author) => author.authorId !== authorId
        )
      );


    } catch (error) {

      // Print the technical error in the browser console
      console.error('Error deleting author:', error);

      // Display an error message to the user
      alert('Unable to delete author. Please check the backend.');
    }
  };


  // If data is still loading, display a loading message
  //
  // The return statement stops the rest of the component from rendering
  if (loading) {
    return <h2>Loading authors...</h2>;
  }


  // If an error occurred while loading authors, display the error message
  if (error) {
    return <h2>{error}</h2>;
  }


  // JSX starts here
  // JSX is HTML-like syntax used to describe what should appear on the screen
  return (
    <div>

      {/* Header section containing the page title and Add Author button */}
      <div
        style={{
          // Display the title and button horizontally
          display: 'flex',

          // Vertically align the title and button
          alignItems: 'center',

          // Add 20 pixels of space between the title and button
          gap: '20px',

          // Add space below the header
          marginBottom: '15px'
        }}
      >

        {/* Page heading */}
        <h2>Authors</h2>


        {/* Button used to open the Add Author form */}
        <button
          // Call handleAddAuthor when the button is clicked
          onClick={handleAddAuthor}

          // Apply the button styling defined at the bottom of the file
          style={styles.button}
        >
          Add Author
        </button>

      </div>


      {/* Table that displays all author records */}
      <table
        // Add a border around the table
        border="1"

        // Add space inside each table cell
        cellPadding="8"

        // Apply table styling
        style={{
          // Combine adjacent borders into one border
          borderCollapse: 'collapse',

          // Set the table width to 800 pixels
          width: '800px'
        }}
      >

        {/* Table header section */}
        <thead>
          <tr>

            {/* Column heading for author ID */}
            <th>Author ID</th>

            {/* Column heading for author name */}
            <th>Author Name</th>

            {/* Column heading for country */}
            <th>Country</th>

            {/* Column heading for action buttons */}
            <th>Actions</th>

          </tr>
        </thead>


        {/* Table body section containing the author records */}
        <tbody>

          {/* 
            map() loops through the authors array.

            For every author, React creates one table row.
          */}
          {authors.map((author) => (

            // key uniquely identifies each row for React
            // authorId is used because every author has a unique ID
            <tr key={author.authorId}>

              {/* Display the author ID */}
              <td>{author.authorId}</td>

              {/* Display the author name */}
              <td>{author.authorName}</td>

              {/* Display the country */}
              <td>{author.country}</td>


              {/* Cell containing Edit and Delete buttons */}
              <td>

                {/* Edit button */}
                <button

                  // Pass the complete author object to handleEditAuthor
                  onClick={() => handleEditAuthor(author)}

                  // Apply Edit button styling
                  style={styles.actionButton}
                >
                  Edit
                </button>


                {/* Delete button */}
                <button

                  // Pass only the selected author's ID to the delete function
                  onClick={() => handleDeleteAuthor(author.authorId)}

                  // Apply Delete button styling
                  style={styles.deleteButton}
                >
                  Delete
                </button>

              </td>

            </tr>
          ))}

        </tbody>
      </table>


      {/* 
        Conditional rendering:

        If showForm is true, display AuthorForm.
        If showForm is false, do not display AuthorForm.
      */}
      {showForm && (

        <AuthorForm

          // Pass the selected author to AuthorForm
          //
          // null       -> Add mode
          // author obj -> Edit mode
          initial={selectedAuthor}


          // Pass the save callback function to AuthorForm
          // AuthorForm calls this after POST or PUT succeeds
          onSaved={handleAuthorSaved}


          // Pass a function to close the form
          onClose={() => {

            // Hide the form
            setShowForm(false);

            // Clear the selected author
            setSelectedAuthor(null);
          }}

        />
      )}

    </div>
  );
}


// Styles used by the buttons
const styles = {

  // Style for the Add Author button
  button: {
    // Add vertical and horizontal space inside the button
    padding: '8px 14px',

    // Display a hand cursor when the mouse is over the button
    cursor: 'pointer'
  },


  // Style for the Edit button
  actionButton: {
    // Add space inside the button
    padding: '5px 10px',

    // Add space between Edit and Delete buttons
    marginRight: '8px',

    // Display a hand cursor
    cursor: 'pointer'
  },


  // Style for the Delete button
  deleteButton: {
    // Add space inside the button
    padding: '5px 10px',

    // Display a hand cursor
    cursor: 'pointer'
  }
};

/**
 * 
Overall execution flow
1. User opens /authors
        ↓
2. AuthorLists component loads
        ↓
3. useEffect() calls loadAuthors()
        ↓
4. Axios sends GET request
        ↓
5. Spring Boot returns author JSON
        ↓
6. setAuthors() stores the data
        ↓
7. React displays the author table
        ↓
8. User clicks Add, Edit, or Delete
        ↓
9. React calls the corresponding API
        ↓
10. React updates the table

API mapping
User action	                      HTTP                  method	API
Load authors	                    GET	                  /api/authors
Add author	                      POST                	/api/authors
Edit author           	          PUT	                  /api/authors/{authorId}
Delete author	                    DELETE	              /api/authors/{authorId}
 */