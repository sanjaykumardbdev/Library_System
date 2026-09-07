package com.library.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "BOOKS")
public class Book {

    @Id
    @Column(name = "BOOK_ID")
    private Long bookId;

    @Column(name = "TITLE", nullable = false)
    private String title;

    @Column(name = "CATEGORY")
    private String category;

    @Column(name = "AUTHOR_ID")
    private Long authorId;

    @Column(name = "PUBLISHER_ID")
    private Long publisherId;

    @Column(name = "ISBN")
    private String isbn;

    @Column(name = "PUBLISH_YEAR")
    private Integer publishYear;

    @Column(name = "TOTAL_COPIES")
    private Integer totalCopies;

    public Long getBookId() { return bookId; }
    public void setBookId(Long bookId) { this.bookId = bookId; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public Long getAuthorId() { return authorId; }
    public void setAuthorId(Long authorId) { this.authorId = authorId; }
    public Long getPublisherId() { return publisherId; }
    public void setPublisherId(Long publisherId) { this.publisherId = publisherId; }
    public String getIsbn() { return isbn; }
    public void setIsbn(String isbn) { this.isbn = isbn; }
    public Integer getPublishYear() { return publishYear; }
    public void setPublishYear(Integer publishYear) { this.publishYear = publishYear; }
    public Integer getTotalCopies() { return totalCopies; }
    public void setTotalCopies(Integer totalCopies) { this.totalCopies = totalCopies; }
}
