package com.library.repository;

import com.library.dto.BorrowedBookResponse;
import org.h2.jdbcx.JdbcDataSource;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.datasource.DataSourceTransactionManager;
import org.springframework.transaction.support.TransactionTemplate;
import org.springframework.web.server.ResponseStatusException;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

class LoanRepositoryIntegrationTest {

    private JdbcTemplate jdbcTemplate;
    private LoanRepository loanRepository;
    private TransactionTemplate transactions;

    @BeforeEach
    void setUp() {
        JdbcDataSource dataSource = new JdbcDataSource();
        dataSource.setURL("jdbc:h2:mem:loans;MODE=Oracle;DB_CLOSE_DELAY=-1");
        jdbcTemplate = new JdbcTemplate(dataSource);
        jdbcTemplate.execute("DROP ALL OBJECTS");
        jdbcTemplate.execute("CREATE SEQUENCE seq_loans START WITH 100000");
        jdbcTemplate.execute("CREATE TABLE members (member_id BIGINT PRIMARY KEY, full_name VARCHAR(200), status VARCHAR(20))");
        jdbcTemplate.execute("CREATE TABLE books (book_id BIGINT PRIMARY KEY, title VARCHAR(300))");
        jdbcTemplate.execute("CREATE TABLE book_copies (copy_id BIGINT PRIMARY KEY, book_id BIGINT, status VARCHAR(20))");
        jdbcTemplate.execute("CREATE TABLE loan_transactions (loan_id BIGINT, member_id BIGINT, copy_id BIGINT, " +
                "loan_date TIMESTAMP, due_date TIMESTAMP, return_date TIMESTAMP, status VARCHAR(20), " +
                "PRIMARY KEY (loan_id, loan_date))");
        jdbcTemplate.update("INSERT INTO members VALUES (1001, 'Test Member', 'ACTIVE')");
        jdbcTemplate.update("INSERT INTO books VALUES (2001, 'Test Book')");
        jdbcTemplate.update("INSERT INTO book_copies VALUES (3001, 2001, 'AVAILABLE')");
        loanRepository = new LoanRepository(jdbcTemplate);
        transactions = new TransactionTemplate(new DataSourceTransactionManager(dataSource));
    }

    @Test
    void issueAndReturnUpdateLoanAndCopyTogether() {
        BorrowedBookResponse issued = transactions.execute(status -> loanRepository.issueBook(1001L, 2001L));

        assertEquals("ISSUED", issued.getStatus());
        assertEquals("ISSUED", jdbcTemplate.queryForObject(
                "SELECT status FROM book_copies WHERE copy_id = 3001", String.class));

        BorrowedBookResponse returned = transactions.execute(status -> loanRepository.returnBook(issued.getLoanId()));

        assertEquals("RETURNED", returned.getStatus());
        assertEquals("AVAILABLE", jdbcTemplate.queryForObject(
                "SELECT status FROM book_copies WHERE copy_id = 3001", String.class));
        assertEquals(1, jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM loan_transactions WHERE loan_id = ? AND return_date IS NOT NULL",
                Integer.class,
                issued.getLoanId()));
    }

    @Test
    void unavailableCopyDoesNotCreateLoanOrChangeInventory() {
        jdbcTemplate.update("UPDATE book_copies SET status = 'ISSUED' WHERE copy_id = 3001");

        assertThrows(ResponseStatusException.class,
                () -> transactions.execute(status -> loanRepository.issueBook(1001L, 2001L)));

        assertEquals(0, jdbcTemplate.queryForObject("SELECT COUNT(*) FROM loan_transactions", Integer.class));
        assertEquals("ISSUED", jdbcTemplate.queryForObject(
                "SELECT status FROM book_copies WHERE copy_id = 3001", String.class));
    }
}