package com.library.dto;

/*
Step 3 — DTO
*Represents the data being transferred through the API.  
They may contain similar fields, but they have different responsibilities.
*/


public class AuthorDTO {

    private Long authorId;
    private String authorName;
    private String country;

    public AuthorDTO() {
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