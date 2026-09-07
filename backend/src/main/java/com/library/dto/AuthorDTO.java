package com.library.dto;

public class AuthorDTO {
    private Long authorId;
    private String authorName;
    private String country;

    public Long getAuthorId() { return authorId; }
    public void setAuthorId(Long authorId) { this.authorId = authorId; }
    public String getAuthorName() { return authorName; }
    public void setAuthorName(String authorName) { this.authorName = authorName; }
    public String getCountry() { return country; }
    public void setCountry(String country) { this.country = country; }
}
