package com.library.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.SequenceGenerator;
import jakarta.persistence.Table;

/**
 * Author.java
 * Step 2 — Entity
 * Represents the Oracle AUTHORS table in Java.
 */

@Entity
@Table(name = "AUTHORS", schema = "LIBRARY_ETL")
public class Author {

    @Id
    @GeneratedValue(
        strategy = GenerationType.SEQUENCE,
        generator = "author_sequence_generator"
    )
    @SequenceGenerator(
        name = "author_sequence_generator",
        sequenceName = "SEQ_AUTHORS",
        schema = "LIBRARY_ETL",
        allocationSize = 1
    )
    @Column(name = "AUTHOR_ID")
    private Long authorId;

    @Column(name = "AUTHOR_NAME", nullable = false, length = 200)
    private String authorName;

    @Column(name = "COUNTRY", length = 100)
    private String country;

    public Author() {
    }

    public Long getAuthorId() {
        return authorId;
    }

    public void setAuthorId(Long authorId) {
        this.authorId = authorId;
    }

    public String getAuthorName() {
        return authorName;
    }

    public void setAuthorName(String authorName) {
        this.authorName = authorName;
    }

    public String getCountry() {
        return country;
    }

    public void setCountry(String country) {
        this.country = country;
    }
}