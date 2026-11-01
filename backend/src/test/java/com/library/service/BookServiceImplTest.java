package com.library.service;

import com.library.dto.BookDTO;
import com.library.entity.Book;
import com.library.repository.BookRepository;
import com.library.service.impl.BookServiceImpl;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.jdbc.core.JdbcTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class BookServiceImplTest {

    @Mock private BookRepository bookRepository;
    @Mock private JdbcTemplate jdbcTemplate;
    @InjectMocks private BookServiceImpl bookService;

    @Test
    void createUsesSequenceAndCreatesAvailablePhysicalCopies() {
        BookDTO request = new BookDTO();
        request.setTitle("Test title");
        request.setTotalCopies(2);
        when(jdbcTemplate.queryForObject("SELECT seq_books.NEXTVAL FROM dual", Long.class)).thenReturn(10001L);
        when(bookRepository.saveAndFlush(any(Book.class))).thenAnswer(invocation -> invocation.getArgument(0));
        when(jdbcTemplate.update(any(String.class), eq(10001L))).thenReturn(1);

        BookDTO created = bookService.create(request);

        assertEquals(10001L, created.getBookId());
        assertEquals(2, created.getTotalCopies());
        ArgumentCaptor<Book> savedBook = ArgumentCaptor.forClass(Book.class);
        verify(bookRepository).saveAndFlush(savedBook.capture());
        assertEquals(10001L, savedBook.getValue().getBookId());
        verify(jdbcTemplate, times(2)).update(
                "INSERT INTO book_copies (copy_id, book_id, branch_id, status) VALUES (seq_book_copies.NEXTVAL, ?, NULL, 'AVAILABLE')",
                10001L);
    }
}