package com.library.repository;

import com.library.dto.BorrowedBookResponse;
import org.springframework.dao.EmptyResultDataAccessException;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.web.server.ResponseStatusException;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.List;

@Repository
public class LoanRepository {

    private static final String LOAN_SELECT = """
            SELECT lt.loan_id, lt.member_id, m.full_name AS member_name,
                   b.book_id, bc.copy_id, b.title AS book_title,
                   lt.loan_date, lt.due_date, lt.return_date,
                   CASE WHEN lt.status = 'ISSUED' AND lt.return_date IS NULL AND lt.due_date < SYSDATE
                        THEN 'OVERDUE' ELSE lt.status END AS loan_status
                   , NVL((SELECT SUM(lc.amount) FROM loan_charges lc WHERE lc.loan_id = lt.loan_id), 0)
                     + CASE WHEN lt.status = 'ISSUED' AND lt.return_date IS NULL
                            THEN GREATEST(TRUNC(SYSDATE - lt.due_date), 0) * 5 ELSE 0 END AS fine_amount
                   , NVL((SELECT SUM(lcp.amount)
                          FROM loan_charge_payments lcp
                          JOIN loan_charges lc ON lc.charge_id = lcp.charge_id
                          WHERE lc.loan_id = lt.loan_id), 0) AS amount_paid
            FROM loan_transactions lt
            JOIN members m ON m.member_id = lt.member_id
            JOIN book_copies bc ON bc.copy_id = lt.copy_id
            JOIN books b ON b.book_id = bc.book_id
            """;

    private final JdbcTemplate jdbcTemplate;

    public LoanRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<BorrowedBookResponse> findByMemberId(Long memberId) {
        return jdbcTemplate.query(
                LOAN_SELECT + " WHERE lt.member_id = ? ORDER BY lt.loan_date DESC",
                this::mapLoan,
                memberId);
    }

    public List<BorrowedBookResponse> findActiveLoans() {
        return jdbcTemplate.query(
                LOAN_SELECT + " WHERE lt.return_date IS NULL ORDER BY lt.due_date, lt.loan_id",
                this::mapLoan);
    }

    public List<BorrowedBookResponse> findAllLoans() {
        return jdbcTemplate.query(
                LOAN_SELECT + " ORDER BY lt.loan_date DESC, lt.loan_id DESC",
                this::mapLoan);
    }

    public BorrowedBookResponse issueBook(Long memberId, Long bookId) {
        Integer activeMember = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM members WHERE member_id = ? AND status = 'ACTIVE'",
                Integer.class,
                memberId);
        if (activeMember == null || activeMember == 0) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Active member not found");
        }

        List<Long> availableCopyIds = jdbcTemplate.query(
                "SELECT copy_id FROM book_copies WHERE book_id = ? AND status = 'AVAILABLE' ORDER BY copy_id",
                (rs, rowNum) -> rs.getLong("copy_id"),
                bookId);
        for (Long copyId : availableCopyIds) {
            int claimed = jdbcTemplate.update(
                    "UPDATE book_copies SET status = 'ISSUED' WHERE copy_id = ? AND status = 'AVAILABLE'",
                    copyId);
            if (claimed == 1) {
                Long loanId = jdbcTemplate.queryForObject("SELECT seq_loans.NEXTVAL FROM dual", Long.class);
                jdbcTemplate.update(
                        "INSERT INTO loan_transactions " +
                                "(loan_id, member_id, copy_id, loan_date, due_date, status) " +
                                "VALUES (?, ?, ?, SYSDATE, SYSDATE + 14, 'ISSUED')",
                        loanId,
                        memberId,
                        copyId);
                return findByLoanId(loanId);
            }
        }
        throw new ResponseStatusException(HttpStatus.CONFLICT, "No available copy exists for this book");
    }

    public BorrowedBookResponse returnBook(Long loanId) {
        return returnBook(loanId, null);
    }

    public BorrowedBookResponse returnMemberBook(Long loanId, Long memberId) {
        return returnBook(loanId, memberId);
    }

    private BorrowedBookResponse returnBook(Long loanId, Long memberId) {
        String memberCondition = memberId == null ? "" : " AND member_id = ?";
        List<Long> copyIds = jdbcTemplate.query(
                "SELECT copy_id FROM loan_transactions " +
                        "WHERE loan_id = ? AND return_date IS NULL AND status = 'ISSUED'" +
                        memberCondition + " FOR UPDATE",
                (rs, rowNum) -> rs.getLong("copy_id"),
                memberId == null ? new Object[]{loanId} : new Object[]{loanId, memberId});
        if (copyIds.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Loan is not currently issued or does not belong to this member");
        }

        int returned = jdbcTemplate.update(
                "UPDATE loan_transactions SET status = 'RETURNED', return_date = SYSDATE " +
                        "WHERE loan_id = ? AND return_date IS NULL AND status = 'ISSUED'",
                loanId);
        int copyAvailable = jdbcTemplate.update(
                "UPDATE book_copies SET status = 'AVAILABLE' WHERE copy_id = ? AND status = 'ISSUED'",
                copyIds.get(0));
        if (returned != 1 || copyAvailable != 1) {
            throw new IllegalStateException("Loan and copy state could not be updated consistently");
        }
        addLateFee(loanId);
        return findByLoanId(loanId);
    }

    public BorrowedBookResponse markLost(Long loanId, BigDecimal lostBookAmount) {
        validateMoney(lostBookAmount);
        List<Long> copyIds = jdbcTemplate.query(
                "SELECT copy_id FROM loan_transactions " +
                        "WHERE loan_id = ? AND return_date IS NULL AND status = 'ISSUED' FOR UPDATE",
                (rs, rowNum) -> rs.getLong("copy_id"),
                loanId);
        if (copyIds.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Loan is not currently issued");
        }

        int updatedLoan = jdbcTemplate.update(
                "UPDATE loan_transactions SET status = 'LOST' WHERE loan_id = ? AND return_date IS NULL AND status = 'ISSUED'",
                loanId);
        int updatedCopy = jdbcTemplate.update(
                "UPDATE book_copies SET status = 'LOST' WHERE copy_id = ? AND status = 'ISSUED'",
                copyIds.get(0));
        if (updatedLoan != 1 || updatedCopy != 1) {
            throw new IllegalStateException("Loan and copy state could not be updated consistently");
        }
        addLateFee(loanId);
        addCharge(loanId, "LOST_BOOK", lostBookAmount);
        return findByLoanId(loanId);
    }

    public BorrowedBookResponse recordPayment(Long loanId, BigDecimal amount, Long receivedBy) {
        validateMoney(amount);
        String status;
        try {
            status = jdbcTemplate.queryForObject(
                    "SELECT status FROM loan_transactions WHERE loan_id = ? FOR UPDATE",
                    String.class,
                    loanId);
        } catch (EmptyResultDataAccessException exception) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Loan not found");
        }
        if (!"RETURNED".equals(status) && !"LOST".equals(status)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Fine payment can be recorded after a book is returned or marked lost");
        }

        List<ChargeBalance> charges = jdbcTemplate.query(
                "SELECT lc.charge_id, lc.amount - NVL(SUM(lcp.amount), 0) AS balance " +
                        "FROM loan_charges lc LEFT JOIN loan_charge_payments lcp ON lcp.charge_id = lc.charge_id " +
                        "WHERE lc.loan_id = ? GROUP BY lc.charge_id, lc.amount " +
                        "ORDER BY lc.charge_id",
                (rs, rowNum) -> new ChargeBalance(rs.getLong("charge_id"), rs.getBigDecimal("balance")),
                loanId);
        BigDecimal outstanding = charges.stream()
                .map(ChargeBalance::balance)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        if (amount.compareTo(outstanding) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Payment exceeds the outstanding balance");
        }
        if (outstanding.signum() == 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "This loan has no outstanding balance");
        }

        BigDecimal remaining = amount;
        for (ChargeBalance charge : charges) {
            if (remaining.signum() == 0) {
                break;
            }
            BigDecimal allocation = remaining.min(charge.balance());
            if (allocation.signum() > 0) {
                jdbcTemplate.update(
                        "INSERT INTO loan_charge_payments (charge_id, amount, received_by, received_at) " +
                                "VALUES (?, ?, ?, SYSDATE)",
                        charge.chargeId(),
                        allocation,
                        receivedBy);
                remaining = remaining.subtract(allocation);
            }
        }
        return findByLoanId(loanId);
    }

    private void addLateFee(Long loanId) {
        BigDecimal amount = jdbcTemplate.queryForObject(
                "SELECT GREATEST(TRUNC(SYSDATE - due_date), 0) * 5 FROM loan_transactions WHERE loan_id = ?",
                BigDecimal.class,
                loanId);
        if (amount != null && amount.signum() > 0) {
            addCharge(loanId, "LATE_FEE", amount);
        }
    }

    private void addCharge(Long loanId, String chargeType, BigDecimal amount) {
        Long memberId = jdbcTemplate.queryForObject(
                "SELECT member_id FROM loan_transactions WHERE loan_id = ?",
                Long.class,
                loanId);
        jdbcTemplate.update(
                "INSERT INTO loan_charges (loan_id, member_id, charge_type, amount, created_at) " +
                        "VALUES (?, ?, ?, ?, SYSDATE)",
                loanId,
                memberId,
                chargeType,
                amount);
    }

    private void validateMoney(BigDecimal amount) {
        if (amount == null || amount.signum() <= 0 || amount.scale() > 2) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Amount must be positive and have at most two decimal places");
        }
    }

    private BorrowedBookResponse findByLoanId(Long loanId) {
        return jdbcTemplate.queryForObject(LOAN_SELECT + " WHERE lt.loan_id = ?", this::mapLoan, loanId);
    }

    private BorrowedBookResponse mapLoan(ResultSet rs, int rowNum) throws SQLException {
        BorrowedBookResponse loan = new BorrowedBookResponse();
        loan.setLoanId(rs.getLong("loan_id"));
        loan.setMemberId(rs.getLong("member_id"));
        loan.setMemberName(rs.getString("member_name"));
        loan.setBookId(rs.getLong("book_id"));
        loan.setCopyId(rs.getLong("copy_id"));
        loan.setBookTitle(rs.getString("book_title"));
        loan.setBorrowedAt(toInstant(rs.getTimestamp("loan_date")));
        loan.setDueDate(toInstant(rs.getTimestamp("due_date")));
        loan.setReturnedAt(toInstant(rs.getTimestamp("return_date")));
        loan.setStatus(rs.getString("loan_status"));
        loan.setFineAmount(rs.getBigDecimal("fine_amount"));
        loan.setAmountPaid(rs.getBigDecimal("amount_paid"));
        loan.setBalanceDue(rs.getBigDecimal("fine_amount").subtract(rs.getBigDecimal("amount_paid")));
        return loan;
    }

    private Instant toInstant(java.sql.Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toInstant();
    }

    private record ChargeBalance(Long chargeId, BigDecimal balance) { }
}