package com.library.service;

import com.library.dto.AuthorDTO;
import java.util.List;
/*
* Step 5 — Service interface
* This defines what operations your application supports.
Think of this as a contract.

It says:

An Author service must provide these five operations.
 */
public interface AuthorService {

    List<AuthorDTO> findAll(int page, int size, String search);

    AuthorDTO findById(Long id);

    AuthorDTO create(AuthorDTO dto);

    AuthorDTO update(Long id, AuthorDTO dto);

    void delete(Long id);
}