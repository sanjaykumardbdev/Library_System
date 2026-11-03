package com.library.service;

import com.library.dto.BookDTO;
import org.springframework.data.domain.Page;
import java.util.List;

public interface BookService {
    Page<BookDTO> findAll(int page, int size, String search);
    BookDTO findById(Long id);
    BookDTO create(BookDTO dto);
    BookDTO update(Long id, BookDTO dto);
    void delete(Long id);
}
