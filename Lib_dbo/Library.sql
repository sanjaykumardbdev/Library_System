

-- School Library Management System Database Schema

-- Create Database
CREATE DATABASE IF NOT EXISTS school_library;
USE school_library;

-- 1. Authors Table
CREATE TABLE authors (
    author_id INT PRIMARY KEY AUTO_INCREMENT,
    author_name VARCHAR(100) NOT NULL,
    birth_year INT,
    nationality VARCHAR(50),
    biography TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Categories/Subjects Table
CREATE TABLE categories (
    category_id INT PRIMARY KEY AUTO_INCREMENT,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Books Table
CREATE TABLE books (
    book_id INT PRIMARY KEY AUTO_INCREMENT,
    isbn VARCHAR(20) UNIQUE,
    title VARCHAR(200) NOT NULL,
    author_id INT NOT NULL,
    category_id INT NOT NULL,
    publisher VARCHAR(100),
    publication_year INT,
    pages INT,
    language VARCHAR(50),
    quantity INT DEFAULT 1,
    available_quantity INT DEFAULT 1,
    shelf_location VARCHAR(50),
    acquisition_date DATE,
    book_condition VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (author_id) REFERENCES authors(author_id),
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
);

-- 4. Students Table
CREATE TABLE students (
    student_id INT PRIMARY KEY AUTO_INCREMENT,
    student_name VARCHAR(100) NOT NULL,
    student_email VARCHAR(100),
    class_name VARCHAR(50),
    roll_number VARCHAR(20),
    contact_number VARCHAR(15),
    address TEXT,
    enrollment_date DATE,
    membership_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Librarians/Staff Table
CREATE TABLE librarians (
    librarian_id INT PRIMARY KEY AUTO_INCREMENT,
    librarian_name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(15),
    employee_id VARCHAR(20) UNIQUE,
    hire_date DATE,
    position VARCHAR(50),
    department VARCHAR(50),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Book Issues Table
CREATE TABLE book_issues (
    issue_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT NOT NULL,
    student_id INT NOT NULL,
    issue_date DATE NOT NULL,
    due_date DATE NOT NULL,
    return_date DATE,
    librarian_id INT,
    status ENUM('Issued', 'Returned', 'Overdue') DEFAULT 'Issued',
    fine_amount DECIMAL(10, 2) DEFAULT 0.00,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (librarian_id) REFERENCES librarians(librarian_id)
);

-- 7. Fine Management Table
CREATE TABLE fines (
    fine_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    issue_id INT NOT NULL,
    fine_amount DECIMAL(10, 2) NOT NULL,
    fine_date DATE,
    payment_date DATE,
    payment_status ENUM('Paid', 'Pending') DEFAULT 'Pending',
    payment_method VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (issue_id) REFERENCES book_issues(issue_id)
);

-- 8. Reservations Table
CREATE TABLE reservations (
    reservation_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT NOT NULL,
    student_id INT NOT NULL,
    reservation_date DATE NOT NULL,
    expected_availability DATE,
    status ENUM('Active', 'Fulfilled', 'Cancelled') DEFAULT 'Active',
    priority INT DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- 9. Book Inventory History Table
CREATE TABLE inventory_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    book_id INT NOT NULL,
    transaction_type ENUM('Added', 'Removed', 'Damaged', 'Lost') NOT NULL,
    quantity_changed INT NOT NULL,
    transaction_date DATE NOT NULL,
    notes TEXT,
    processed_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (book_id) REFERENCES books(book_id),
    FOREIGN KEY (processed_by) REFERENCES librarians(librarian_id)
);

-- 10. Notifications Table
CREATE TABLE notifications (
    notification_id INT PRIMARY KEY AUTO_INCREMENT,
    student_id INT NOT NULL,
    message TEXT NOT NULL,
    notification_type ENUM('Overdue', 'Due_Soon', 'Available', 'Fine_Due') DEFAULT 'Due_Soon',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- ============================================================
-- INDEXES FOR PERFORMANCE OPTIMIZATION
-- ============================================================

CREATE INDEX idx_book_author ON books(author_id);
CREATE INDEX idx_book_category ON books(category_id);
CREATE INDEX idx_issue_student ON book_issues(student_id);
CREATE INDEX idx_issue_book ON book_issues(book_id);
CREATE INDEX idx_issue_status ON book_issues(status);
CREATE INDEX idx_reservation_book ON reservations(book_id);
CREATE INDEX idx_reservation_student ON reservations(student_id);
CREATE INDEX idx_fine_student ON fines(student_id);
CREATE INDEX idx_inventory_book ON inventory_history(book_id);

-- ============================================================
-- SAMPLE VIEWS FOR REPORTING
-- ============================================================

-- View: Overdue Books
CREATE VIEW overdue_books AS
SELECT 
    bi.issue_id,
    s.student_name,
    s.student_email,
    b.title,
    bi.due_date,
    DATEDIFF(CURDATE(), bi.due_date) as days_overdue
FROM book_issues bi
JOIN students s ON bi.student_id = s.student_id
JOIN books b ON bi.book_id = b.book_id
WHERE bi.status = 'Overdue' AND bi.return_date IS NULL;

-- View: Student Book History
CREATE VIEW student_book_history AS
SELECT 
    s.student_name,
    s.class_name,
    b.title,
    a.author_name,
    bi.issue_date,
    bi.due_date,
    bi.return_date,
    bi.status
FROM book_issues bi
JOIN students s ON bi.student_id = s.student_id
JOIN books b ON bi.book_id = b.book_id
JOIN authors a ON b.author_id = a.author_id;

-- View: Available Books
CREATE VIEW available_books AS
SELECT 
    b.book_id,
    b.title,
    a.author_name,
    c.category_name,
    b.available_quantity,
    b.quantity,
    b.shelf_location
FROM books b
JOIN authors a ON b.author_id = a.author_id
JOIN categories c ON b.category_id = c.category_id
WHERE b.available_quantity > 0;

-- ============================================================
-- SAMPLE STORED PROCEDURES
-- ============================================================

-- Procedure: Issue a Book
DELIMITER //
CREATE PROCEDURE issue_book(
    IN p_book_id INT,
    IN p_student_id INT,
    IN p_librarian_id INT,
    IN p_issue_days INT
)
BEGIN
    DECLARE v_available_qty INT;
    
    -- Check if book is available
    SELECT available_quantity INTO v_available_qty 
    FROM books WHERE book_id = p_book_id;
    
    IF v_available_qty > 0 THEN
        -- Insert into book_issues
        INSERT INTO book_issues (book_id, student_id, issue_date, due_date, librarian_id, status)
        VALUES (p_book_id, p_student_id, CURDATE(), DATE_ADD(CURDATE(), INTERVAL p_issue_days DAY), p_librarian_id, 'Issued');
        
        -- Update available quantity
        UPDATE books SET available_quantity = available_quantity - 1 WHERE book_id = p_book_id;
        
        SELECT 'Book issued successfully' as message;
    ELSE
        SELECT 'Book is not available' as message;
    END IF;
END//
DELIMITER ;

-- Procedure: Return a Book
DELIMITER //
CREATE PROCEDURE return_book(
    IN p_issue_id INT,
    IN p_librarian_id INT
)
BEGIN
    DECLARE v_book_id INT;
    DECLARE v_due_date DATE;
    DECLARE v_fine DECIMAL(10, 2) DEFAULT 0.00;
    
    -- Get book_id and due_date
    SELECT book_id, due_date INTO v_book_id, v_due_date 
    FROM book_issues WHERE issue_id = p_issue_id;
    
    -- Calculate fine if overdue
    IF CURDATE() > v_due_date THEN
        SET v_fine = DATEDIFF(CURDATE(), v_due_date) * 5; -- 5 units per day fine
    END IF;
    
    -- Update book_issues
    UPDATE book_issues 
    SET return_date = CURDATE(), status = 'Returned', fine_amount = v_fine
    WHERE issue_id = p_issue_id;
    
    -- Update available quantity
    UPDATE books SET available_quantity = available_quantity + 1 WHERE book_id = v_book_id;
    
    SELECT 'Book returned successfully' as message, v_fine as fine_amount;
END//
DELIMITER ;