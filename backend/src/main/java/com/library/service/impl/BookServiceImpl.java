package com.library.service.impl;

import com.library.dto.BookDTO;
import com.library.entity.Book;
import com.library.repository.BookRepository;
import com.library.service.BookService;
import org.springframework.http.HttpStatus;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class BookServiceImpl implements BookService {

    private final BookRepository repo;
    private final JdbcTemplate jdbcTemplate;

    public BookServiceImpl(BookRepository repo, JdbcTemplate jdbcTemplate) {
        this.repo = repo;
        this.jdbcTemplate = jdbcTemplate;
    }

    @Override
    public List<BookDTO> findAll(int page, int size, String search) {
        // Simple implementation: ignore pagination/search for now
        Map<Long, Integer> availableCounts = new HashMap<>();
        jdbcTemplate.query(
                "SELECT book_id, COUNT(*) AS available_copies FROM book_copies " +
                        "WHERE status = 'AVAILABLE' GROUP BY book_id",
                rs -> availableCounts.put(rs.getLong("book_id"), rs.getInt("available_copies")));
        return repo.findAll().stream()
                .map(book -> toDto(book, availableCounts.getOrDefault(book.getBookId(), 0)))
                .collect(Collectors.toList());
    }

    @Override
    public BookDTO findById(Long id) {
        return repo.findById(id).map(book -> toDto(book, availableCopyCount(id))).orElse(null);
    }

    @Override
    @Transactional
    public BookDTO create(BookDTO dto) {
        int copyCount = validateCopyCount(dto.getTotalCopies() == null ? 1 : dto.getTotalCopies());
        Book b = toEntity(dto);
        b.setBookId(jdbcTemplate.queryForObject("SELECT seq_books.NEXTVAL FROM dual", Long.class));
        b.setTotalCopies(copyCount);
        Book saved = repo.saveAndFlush(b);
        addCopies(saved.getBookId(), copyCount);
        return toDto(saved, availableCopyCount(saved.getBookId()));
    }

    @Override
    @Transactional
    public BookDTO update(Long id, BookDTO dto) {
        return repo.findById(id).map(e -> {
            int requestedCopyCount = validateCopyCount(
                    dto.getTotalCopies() == null ? e.getTotalCopies() : dto.getTotalCopies());
            reconcileCopies(id, requestedCopyCount);
            e.setTitle(dto.getTitle());
            e.setCategory(dto.getCategory());
            e.setAuthorId(dto.getAuthorId());
            e.setPublisherId(dto.getPublisherId());
            e.setIsbn(dto.getIsbn());
            e.setPublishYear(dto.getPublishYear());
            e.setTotalCopies(requestedCopyCount);
            Book saved = repo.saveAndFlush(e);
            return toDto(saved, availableCopyCount(id));
        }).orElse(null);
    }

    @Override
    public void delete(Long id) { repo.deleteById(id); }

    private BookDTO toDto(Book b, int availableCopies) {
        BookDTO d = new BookDTO();
        d.setBookId(b.getBookId());
        d.setTitle(b.getTitle());
        d.setCategory(b.getCategory());
        d.setAuthorId(b.getAuthorId());
        d.setPublisherId(b.getPublisherId());
        d.setIsbn(b.getIsbn());
        d.setPublishYear(b.getPublishYear());
        d.setTotalCopies(b.getTotalCopies());
        d.setAvailableCopies(availableCopies);
        return d;
    }

    private int availableCopyCount(Long bookId) {
        Integer count = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM book_copies WHERE book_id = ? AND status = 'AVAILABLE'",
                Integer.class,
                bookId);
        return count == null ? 0 : count;
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

    private int validateCopyCount(Integer copyCount) {
        if (copyCount < 0 || copyCount > 10000) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Total copies must be between 0 and 10000");
        }
        return copyCount;
    }

    private void addCopies(Long bookId, int count) {
        for (int index = 0; index < count; index++) {
            jdbcTemplate.update(
                    "INSERT INTO book_copies (copy_id, book_id, branch_id, status) " +
                            "VALUES (seq_book_copies.NEXTVAL, ?, NULL, 'AVAILABLE')",
                    bookId);
        }
    }

    private void reconcileCopies(Long bookId, int requestedCount) {
        Integer currentCount = jdbcTemplate.queryForObject(
                "SELECT COUNT(*) FROM book_copies WHERE book_id = ?",
                Integer.class,
                bookId);
        int difference = requestedCount - (currentCount == null ? 0 : currentCount);
        if (difference > 0) {
            addCopies(bookId, difference);
        } else if (difference < 0) {
            int toRemove = -difference;
            List<Long> availableCopyIds = jdbcTemplate.query(
                    "SELECT copy_id FROM book_copies WHERE book_id = ? AND status = 'AVAILABLE' ORDER BY copy_id",
                    (rs, rowNum) -> rs.getLong("copy_id"),
                    bookId);
            if (availableCopyIds.size() < toRemove) {
                throw new ResponseStatusException(
                        HttpStatus.CONFLICT,
                        "Cannot reduce copies while some copies are issued or unavailable");
            }
            for (int index = 0; index < toRemove; index++) {
                int deleted = jdbcTemplate.update(
                        "DELETE FROM book_copies WHERE copy_id = ? AND status = 'AVAILABLE'",
                        availableCopyIds.get(index));
                if (deleted != 1) {
                    throw new ResponseStatusException(HttpStatus.CONFLICT, "Inventory changed; retry the update");
                }
            }
        }
    }
}
