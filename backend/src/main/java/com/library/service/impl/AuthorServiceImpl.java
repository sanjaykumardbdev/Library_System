package com.library.service.impl;

import com.library.dto.AuthorDTO;
import com.library.entity.Author;
import com.library.repository.AuthorRepository;
import com.library.service.AuthorService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class AuthorServiceImpl implements AuthorService {

    private final AuthorRepository repo;

    public AuthorServiceImpl(AuthorRepository repo) { this.repo = repo; }

    @Override
    public List<AuthorDTO> findAll() {
        return repo.findAll().stream().map(this::toDto).collect(Collectors.toList());
    }

    @Override
    public AuthorDTO findById(Long id) {
        return repo.findById(id).map(this::toDto).orElse(null);
    }

    @Override
    public AuthorDTO create(AuthorDTO dto) {
        Author a = new Author();
        a.setAuthorId(dto.getAuthorId());
        a.setAuthorName(dto.getAuthorName());
        a.setCountry(dto.getCountry());
        Author saved = repo.save(a);
        return toDto(saved);
    }

    @Override
    public AuthorDTO update(Long id, AuthorDTO dto) {
        return repo.findById(id).map(e -> {
            e.setAuthorName(dto.getAuthorName());
            e.setCountry(dto.getCountry());
            return toDto(repo.save(e));
        }).orElse(null);
    }

    @Override
    public void delete(Long id) { repo.deleteById(id); }

    private AuthorDTO toDto(Author a) {
        AuthorDTO d = new AuthorDTO();
        d.setAuthorId(a.getAuthorId());
        d.setAuthorName(a.getAuthorName());
        d.setCountry(a.getCountry());
        return d;
    }
}
