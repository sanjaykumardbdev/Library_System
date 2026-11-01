// Import React and the React hooks used in this component
//
// useState  -> stores values that can change in the form
// useEffect -> runs code when the component loads or when initial changes
import React, { useEffect, useState } from 'react';

// Import Axios to send HTTP requests to the Spring Boot backend
import axios from 'axios';


// AuthorForm is a reusable form component for both Add and Edit operations
//
// Props received from AuthorLists.js:
//
// initial  -> selected author object for editing, or null for adding
// onSaved  -> function called after the author is successfully saved
// onClose  -> function used to close the form
export default function AuthorForm({
  initial,
  onSaved,
  onClose
}) {


  // Stores the value entered in the Author Name input field
  // Initially, the field is empty
  const [authorName, setAuthorName] = useState('');


  // Stores the value entered in the Country input field
  // Initially, the field is empty
  const [country, setCountry] = useState('');


  // Indicates whether the Save operation is in progress
  //
  // false -> Save operation is not running
  // true  -> API request is currently running
  const [saving, setSaving] = useState(false);


  // Stores validation errors or backend error messages
  const [error, setError] = useState('');


  // Determine whether the form is in Edit mode
  //
  // initial = null       -> Add mode
  // initial = author obj -> Edit mode
  //
  // Boolean(null) is false
  // Boolean(object) is true
  const isEditMode = Boolean(initial);


  // useEffect runs when the component loads
  // It also runs whenever the initial prop changes
  useEffect(() => {

    // If an existing author is supplied, populate the Author Name field
    //
    // initial?.authorName means:
    // Read authorName only if initial is not null or undefined
    //
    // || '' means:
    // If no value exists, use an empty string
    setAuthorName(initial?.authorName || '');


    // Populate the Country field when editing
    // Use an empty string when adding a new author
    setCountry(initial?.country || '');


    // Clear any previous error message
    setError('');

  }, [initial]); // Run this effect whenever initial changes


  // This function runs when the user submits the form
  const handleSubmit = async (event) => {

    // Prevent the browser's default form submission behavior
    //
    // Without this, the browser may refresh the page
    event.preventDefault();


    // Validate that the Author Name is not empty
    //
    // trim() removes spaces from the beginning and end
    if (!authorName.trim()) {

      // Display a validation message
      setError('Author Name is required');

      // Stop the function
      // No API request will be sent
      return;
    }


    try {

      // Disable the Save button while the API request is running
      setSaving(true);


      // Clear any previous error message
      setError('');


      // Create the JSON object that will be sent to Spring Boot
      //
      // Example:
      // {
      //   "authorName": "Sanjay Kumar",
      //   "country": "India"
      // }
      const payload = {
        authorName: authorName.trim(),
        country: country.trim()
      };


      // This variable will store the Axios response
      let response;


      // Check whether the form is being used for editing
      if (isEditMode) {

        // Update an existing author using the HTTP PUT method
        //
        // initial.authorId contains the ID of the author being edited
        //
        // Example:
        // PUT http://localhost:8082/api/authors/110
        //
        // payload contains the updated author information
        response = await axios.put(
          `http://localhost:8082/api/authors/${initial.authorId}`,
          payload
        );


      } else {

        // Create a new author using the HTTP POST method
        //
        // Example:
        // POST http://localhost:8082/api/authors
        response = await axios.post(
          'http://localhost:8082/api/authors',
          payload
        );
      }


      // response.data contains the saved author returned by Spring Boot
      //
      // Example:
      // {
      //   "authorId": 110,
      //   "authorName": "Sanjay Kumar",
      //   "country": "India"
      // }
      //
      // Send this data back to the parent AuthorLists component
      onSaved(response.data);


    } catch (error) {

      // Print technical error details in the browser console
      // This helps during debugging
      console.error('Error saving author:', error);


      // Check whether the backend returned an HTTP error response
      //
      // Examples:
      // 400 Bad Request
      // 404 Not Found
      // 500 Internal Server Error
      if (error.response) {

        // Display the HTTP status and backend response
        setError(
          `Save failed: ${error.response.status} - ${
            typeof error.response.data === 'string'
              ? error.response.data
              : JSON.stringify(error.response.data)
          }`
        );


      // error.request means the request was sent,
      // but no response was received from the backend
      //
      // Possible causes:
      // - Spring Boot is not running
      // - Wrong port
      // - Network problem
      // - CORS issue
      } else if (error.request) {

        // Display a message explaining that no backend response arrived
        setError(
          'No response received from Spring Boot on port 8082.'
        );


      // This handles other errors, such as JavaScript or Axios configuration errors
      } else {

        // Display the error message
        setError(`Request error: ${error.message}`);
      }


    } finally {

      // This block executes whether the request succeeds or fails
      //
      // Enable the Save button again
      setSaving(false);
    }
  };


  // JSX defines the form displayed in the browser
  return (

    // Overlay covers the page with a semi-transparent background
    <div style={styles.overlay}>

      {/* White box containing the Add/Edit form */}
      <div style={styles.formContainer}>


        {/* 
          Display a different heading based on the mode:

          true  -> Edit Author
          false -> Add Author
        */}
        <h2>
          {isEditMode ? 'Edit Author' : 'Add Author'}
        </h2>


        {/* 
          HTML form element.

          When the user submits the form,
          handleSubmit() will execute.
        */}
        <form onSubmit={handleSubmit}>


          {/* Author Name input section */}
          <div style={styles.field}>

            {/* Label displayed above the input */}
            <label>Author Name</label>


            {/* Input field for entering the author name */}
            <input

              // Specifies that this is a text input
              type="text"


              // Displays the current authorName state value
              value={authorName}


              // Runs whenever the user types into the input
              //
              // event.target.value contains the latest input value
              // setAuthorName updates the React state
              onChange={(event) =>
                setAuthorName(event.target.value)
              }


              // Disable the input while saving
              disabled={saving}


              // Apply the input styling
              style={styles.input}
            />

          </div>


          {/* Country input section */}
          <div style={styles.field}>

            {/* Label displayed above the input */}
            <label>Country</label>


            {/* Input field for entering the country */}
            <input

              // Specifies that this is a text input
              type="text"


              // Displays the current country state value
              value={country}


              // Updates the country state whenever the user types
              onChange={(event) =>
                setCountry(event.target.value)
              }


              // Disable the input while saving
              disabled={saving}


              // Apply the input styling
              style={styles.input}
            />

          </div>


          {/* 
            Conditional rendering:

            If error contains a message, display the paragraph.
            If error is an empty string, display nothing.
          */}
          {error && (
            <p style={styles.error}>
              {error}
            </p>
          )}


          {/* Container for Save and Cancel buttons */}
          <div style={styles.buttonContainer}>


            {/* Save button */}
            <button

              // Submit this form when clicked
              type="submit"


              // Prevent clicking while an API request is running
              disabled={saving}


              // Apply button styling
              style={styles.button}
            >

              {/* 
                Display:

                "Saving..." while the request is running
                "Save" when no request is running
              */}
              {saving ? 'Saving...' : 'Save'}

            </button>


            {/* Cancel button */}
            <button

              // type="button" prevents this button from submitting the form
              type="button"


              // Call the onClose function passed by AuthorLists.js
              onClick={onClose}


              // Disable Cancel while saving
              disabled={saving}


              // Apply button styling
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


// Styling definitions used by the form
const styles = {


  // Full-screen semi-transparent background behind the form
  overlay: {

    // Keep the overlay fixed relative to the browser window
    position: 'fixed',

    // Position the overlay at the top-left corner
    top: 0,
    left: 0,

    // Stretch the overlay to the right and bottom edges
    right: 0,
    bottom: 0,

    // Add a dark transparent background
    backgroundColor: 'rgba(0, 0, 0, 0.4)',

    // Use Flexbox to position the form
    display: 'flex',

    // Center the form horizontally
    justifyContent: 'center',

    // Center the form vertically
    alignItems: 'center',

    // Place the overlay above other page elements
    zIndex: 1000
  },


  // Styling for the white form box
  formContainer: {

    // Set the background color of the form
    backgroundColor: 'white',

    // Add space inside the form box
    padding: '25px',

    // Round the corners
    borderRadius: '8px',

    // Set the form width
    width: '400px',

    // Add a shadow around the form
    boxShadow: '0 4px 12px rgba(0, 0, 0, 0.3)'
  },


  // Add space below each input field
  field: {
    marginBottom: '15px'
  },


  // Styling for the text input boxes
  input: {

    // Make the input use the available width
    width: '100%',

    // Add space inside the input
    padding: '8px',

    // Add space above the input
    marginTop: '5px',

    // Include padding inside the specified width
    boxSizing: 'border-box'
  },


  // Styling for error messages
  error: {
    color: 'red'
  },


  // Layout for the Save and Cancel buttons
  buttonContainer: {

    // Display the buttons next to each other
    display: 'flex',

    // Add space between the buttons
    gap: '10px',

    // Add space above the buttons
    marginTop: '20px'
  },


  // Styling shared by Save and Cancel buttons
  button: {

    // Add space inside each button
    padding: '8px 16px',

    // Display a hand cursor when hovering over the button
    cursor: 'pointer'
  }
};


/*
Simple execution flow

User clicks Add Author
        ↓
AuthorLists.js sends initial = null
        ↓
AuthorForm.js opens in Add mode
        ↓
User enters author name and country
        ↓
User clicks Save
        ↓
React sends POST request
        ↓
Spring Boot inserts the record into Oracle
        ↓
Backend returns the saved author
        ↓
onSaved(response.data) runs
        ↓
AuthorLists.js updates the table


For editing:

User clicks Edit
        ↓
AuthorLists.js sends selected author
        ↓
AuthorForm.js fills existing values
        ↓
User changes the values
        ↓
User clicks Save
        ↓
React sends PUT /api/authors/{authorId}
        ↓
Spring Boot updates Oracle
        ↓
Backend returns the updated author
        ↓
AuthorLists.js updates the UI

*/