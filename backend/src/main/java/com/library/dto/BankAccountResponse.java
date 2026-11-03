package com.library.dto;

import java.math.BigDecimal;
import java.time.Instant;

public class BankAccountResponse {
    private Long accountId;
    private String accountName;
    private String accountReference;
    private BigDecimal currentBalance;
    private BigDecimal availableToDeposit;
    private Instant updatedAt;

    public Long getAccountId() { return accountId; }
    public void setAccountId(Long accountId) { this.accountId = accountId; }
    public String getAccountName() { return accountName; }
    public void setAccountName(String accountName) { this.accountName = accountName; }
    public String getAccountReference() { return accountReference; }
    public void setAccountReference(String accountReference) { this.accountReference = accountReference; }
    public BigDecimal getCurrentBalance() { return currentBalance; }
    public void setCurrentBalance(BigDecimal currentBalance) { this.currentBalance = currentBalance; }
    public BigDecimal getAvailableToDeposit() { return availableToDeposit; }
    public void setAvailableToDeposit(BigDecimal availableToDeposit) { this.availableToDeposit = availableToDeposit; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant updatedAt) { this.updatedAt = updatedAt; }
}
