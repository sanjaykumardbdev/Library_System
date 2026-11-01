package com.library.dto;

import java.math.BigDecimal;
import java.time.Instant;

public class FineDepositResponse {
    private Long depositId;
    private BigDecimal amount;
    private String depositedBy;
    private Instant depositedAt;

    public Long getDepositId() { return depositId; }
    public void setDepositId(Long depositId) { this.depositId = depositId; }
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    public String getDepositedBy() { return depositedBy; }
    public void setDepositedBy(String depositedBy) { this.depositedBy = depositedBy; }
    public Instant getDepositedAt() { return depositedAt; }
    public void setDepositedAt(Instant depositedAt) { this.depositedAt = depositedAt; }
}
