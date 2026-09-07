package com.library.service.impl;

import com.library.dto.BookDTO;
import com.library.entity.Book;
import com.library.repository.BookRepository;
import com.library.service.BookService;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class BookServiceImpl implements BookService {

    private final BookRepository repo;

    public BookServiceImpl(BookRepository repo) { this.repo = repo; }

    @Override
    public List<BookDTO> findAll(int page, int size, String search) {
        // Simple implementation: ignore pagination/search for now
        return repo.findAll().stream().map(this::toDto).collect(Collectors.toList());
    }

    @Override
    public BookDTO findById(Long id) {
        return repo.findById(id).map(this::toDto).orElse(null);
    }

    @Override
    public BookDTO create(BookDTO dto) {
        Book b = toEntity(dto);
        Book saved = repo.save(b);
        return toDto(saved);
    }

    @Override
    public BookDTO update(Long id, BookDTO dto) {
        return repo.findById(id).map(e -> {
            e.setTitle(dto.getTitle());
            e.setCategory(dto.getCategory());
            e.setAuthorId(dto.getAuthorId());
            e.setPublisherId(dto.getPublisherId());
            e.setIsbn(dto.getIsbn());
            e.setPublishYear(dto.getPublishYear());
            e.setTotalCopies(dto.getTotalCopies());
            return toDto(repo.save(e));
        }).orElse(null);
    }

    @Override
    public void delete(Long id) { repo.deleteById(id); }

    private BookDTO toDto(Book b) {
        BookDTO d = new BookDTO();
        d.setBookId(b.getBookId());
        d.setTitle(b.getTitle());
        d.setCategory(b.getCategory());
        d.setAuthorId(b.getAuthorId());
        d.setPublisherId(b.getPublisherId());
        d.setIsbn(b.getIsbn());
        d.setPublishYear(b.getPublishYear());
        d.setTotalCopies(b.getTotalCopies());
        return d;
    }

    private Book toEntity(BookDTO d) {
        Book b = new Book();
        b.setBookId(d.getBookId());
        b.setTitle(d.getTitle());
        b.setCategory(d.getCategory());
        b.setAuthorId(d.getAuthorId());
        b.setPublisherId(d.getPublisherId());
        b.setIsbn(d.getIsbn());
        b.setPublishYear(d.getPublishYear());
        b.setTotalCopies(d.getTotalCopies());
        return b;
    }
}
