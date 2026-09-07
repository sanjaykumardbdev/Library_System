package com.library.service;

import com.library.dto.AuthorDTO;
import java.util.List;

public interface AuthorService {
    List<AuthorDTO> findAll();
    AuthorDTO findById(Long id);
    AuthorDTO create(AuthorDTO dto);
    AuthorDTO update(Long id, AuthorDTO dto);
    void delete(Long id);
}
