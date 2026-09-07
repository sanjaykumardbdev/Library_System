package com.library.service;

import com.library.dto.BookDTO;
import java.util.List;

public interface BookService {
    List<BookDTO> findAll(int page, int size, String search);
    BookDTO findById(Long id);
    BookDTO create(BookDTO dto);
    BookDTO update(Long id, BookDTO dto);
    void delete(Long id);
}
