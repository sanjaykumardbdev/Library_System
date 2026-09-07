package com.library.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "BOOK_COPIES")
public class BookCopy {

    @Id
    @Column(name = "COPY_ID")
    private Long copyId;

    @Column(name = "BOOK_ID")
    private Long bookId;

    @Column(name = "BRANCH_ID")
    private Long branchId;

    @Column(name = "STATUS")
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
