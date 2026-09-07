package com.library.dto;

public class BookCopyDTO {
    private Long copyId;
    private Long bookId;
    private Long branchId;
    private String status;

    public Long getCopyId() { return copyId; }
    public void setCopyId(Long copyId) { this.copyId = copyId; }
    public Long getBookId() { return bookId; }
    public void setBookId(Long bookId) { this.bookId = bookId; }
    public Long getBranchId() { return branchId; }
    public void setBranchId(Long branchId) { this.branchId = branchId; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}
