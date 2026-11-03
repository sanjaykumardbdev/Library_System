package com.library.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;

public class BookLoanRequest {

    @NotNull
    @Positive
    private Long bookId;

    public Long getBookId() {
        return bookId;
    }

    public void setBookId(Long bookId) {
        this.bookId = bookId;
    }
}
