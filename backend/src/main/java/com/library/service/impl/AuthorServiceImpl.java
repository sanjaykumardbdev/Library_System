package com.library.service.impl;

import com.library.dto.AuthorDTO;
import com.library.entity.Author;
import com.library.repository.AuthorRepository;
import com.library.service.AuthorService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;
/*
* Step 6 — Service implementation
This contains the actual business logic.
This is extremely important.

The service converts:

DTO → Entity

before saving.

And after retrieving:

Entity → DTO

before returning the result.

That's the core of your DTO architecture.

 */
@Service
public class AuthorServiceImpl implements AuthorService {

    private final AuthorRepository repo;

    public AuthorServiceImpl(AuthorRepository repo) {
        this.repo = repo;
    }

    @Override
    public List<AuthorDTO> findAll(int page, int size, String search) {

        // Simple implementation for now:
        // pagination and search can be added later.

        return repo.findAll()
                .stream()
                .map(this::toDto)
                .collect(Collectors.toList());
    }

    @Override
    public AuthorDTO findById(Long id) {

        return repo.findById(id)
                .map(this::toDto)
                .orElse(null);
    }

    @Override
    public AuthorDTO create(AuthorDTO dto) {

        Author author = toEntity(dto);

        Author saved = repo.save(author);

        return toDto(saved);
    }

    @Override
    public AuthorDTO update(Long id, AuthorDTO dto) {

        return repo.findById(id)
                .map(author -> {

                    author.setAuthorName(dto.getAuthorName());
                    author.setCountry(dto.getCountry());

                    return toDto(repo.save(author));
                })
                .orElse(null);
    }

    @Override
    public void delete(Long id) {

        repo.deleteById(id);
    }

    private AuthorDTO toDto(Author author) {

        AuthorDTO dto = new AuthorDTO();

        dto.setAuthorId(author.getAuthorId());
        dto.setAuthorName(author.getAuthorName());
        dto.setCountry(author.getCountry());

        return dto;
    }

    private Author toEntity(AuthorDTO dto) {

        Author author = new Author();

        // Do not need to set authorId for a new record.
        // Oracle SEQ_AUTHORS will generate it.

        author.setAuthorName(dto.getAuthorName());
        author.setCountry(dto.getCountry());

        return author;
    }
}