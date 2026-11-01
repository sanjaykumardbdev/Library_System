package com.library.repository;

import com.library.dto.BankAccountResponse;
import com.library.dto.FineDepositResponse;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Instant;
import java.util.List;

@Repository
public class FinanceRepository {

    private static final long FINE_ACCOUNT_ID = 1L;
    private final JdbcTemplate jdbcTemplate;

    public FinanceRepository(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public BankAccountResponse getAccount() {
        return jdbcTemplate.query(
                "SELECT account_id, account_name, account_reference, current_balance, updated_at, " +
                        "GREATEST((SELECT NVL(SUM(amount), 0) FROM loan_charge_payments) - " +
                        "(SELECT NVL(SUM(amount), 0) FROM fine_deposits), 0) AS available_to_deposit " +
                        "FROM library_bnk_account WHERE account_id = ?",
                rs -> {
                    if (!rs.next()) {
                        throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Library fine account is not configured");
                    }
                    return mapAccount(rs);
                },
                FINE_ACCOUNT_ID);
    }

    @Transactional
    public BankAccountResponse depositCollectedFines(Long adminId) {
        List<Long> accounts = jdbcTemplate.query(
                "SELECT account_id FROM library_bnk_account WHERE account_id = ? FOR UPDATE",
                (rs, rowNum) -> rs.getLong("account_id"),
                FINE_ACCOUNT_ID);
        if (accounts.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Library fine account is not configured");
        }

        BigDecimal collected = total("SELECT NVL(SUM(amount), 0) FROM loan_charge_payments");
        BigDecimal deposited = total("SELECT NVL(SUM(amount), 0) FROM fine_deposits");
        BigDecimal amount = collected.subtract(deposited);
        if (amount.signum() <= 0) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "There are no collected fines awaiting deposit");
        }
        jdbcTemplate.update(
                "INSERT INTO fine_deposits (account_id, amount, deposited_by, deposited_at) VALUES (?, ?, ?, SYSDATE)",
                FINE_ACCOUNT_ID,
                amount,
                adminId);
        jdbcTemplate.update(
                "UPDATE library_bnk_account SET current_balance = current_balance + ?, updated_at = SYSDATE WHERE account_id = ?",
                amount,
                FINE_ACCOUNT_ID);
        return getAccount();
    }

    public List<FineDepositResponse> findDeposits() {
        return jdbcTemplate.query(
                "SELECT d.deposit_id, d.amount, u.username AS deposited_by, d.deposited_at " +
                        "FROM fine_deposits d JOIN app_users u ON u.user_id = d.deposited_by " +
                        "ORDER BY d.deposited_at DESC, d.deposit_id DESC",
                (rs, rowNum) -> mapDeposit(rs));
    }

    private BigDecimal total(String sql) {
        BigDecimal value = jdbcTemplate.queryForObject(sql, BigDecimal.class);
        return value == null ? BigDecimal.ZERO : value;
    }

    private BankAccountResponse mapAccount(ResultSet rs) throws SQLException {
        BankAccountResponse response = new BankAccountResponse();
        response.setAccountId(rs.getLong("account_id"));
        response.setAccountName(rs.getString("account_name"));
        response.setAccountReference(rs.getString("account_reference"));
        response.setCurrentBalance(rs.getBigDecimal("current_balance"));
        response.setAvailableToDeposit(rs.getBigDecimal("available_to_deposit"));
        response.setUpdatedAt(toInstant(rs.getTimestamp("updated_at")));
        return response;
    }

    private FineDepositResponse mapDeposit(ResultSet rs) throws SQLException {
        FineDepositResponse response = new FineDepositResponse();
        response.setDepositId(rs.getLong("deposit_id"));
        response.setAmount(rs.getBigDecimal("amount"));
        response.setDepositedBy(rs.getString("deposited_by"));
        response.setDepositedAt(toInstant(rs.getTimestamp("deposited_at")));
        return response;
    }

    private Instant toInstant(java.sql.Timestamp timestamp) {
        return timestamp == null ? null : timestamp.toInstant();
    }
}
