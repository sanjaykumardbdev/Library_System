package com.library.service.impl;

import com.library.dto.PublisherDTO;
import com.library.entity.Publisher;
import com.library.repository.PublisherRepository;
import com.library.service.PublisherService;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class PublisherServiceImpl implements PublisherService {

    private final PublisherRepository repo;

    public PublisherServiceImpl(PublisherRepository repo) { this.repo = repo; }

    @Override
    public List<PublisherDTO> findAll() {
        return repo.findAll().stream().map(this::toDto).collect(Collectors.toList());
    }

    @Override
    public PublisherDTO findById(Long id) {
        return repo.findById(id).map(this::toDto).orElse(null);
    }

    @Override
    public PublisherDTO create(PublisherDTO dto) {
        Publisher p = new Publisher();
        p.setPublisherId(dto.getPublisherId());
        p.setName(dto.getName());
        p.setLocation(dto.getLocation());
        Publisher saved = repo.save(p);
        return toDto(saved);
    }

    @Override
    public PublisherDTO update(Long id, PublisherDTO dto) {
        return repo.findById(id).map(e -> {
            e.setName(dto.getName());
            e.setLocation(dto.getLocation());
            return toDto(repo.save(e));
        }).orElse(null);
    }

    @Override
    public void delete(Long id) { repo.deleteById(id); }

    private PublisherDTO toDto(Publisher p) {
        PublisherDTO d = new PublisherDTO();
        d.setPublisherId(p.getPublisherId());
        d.setName(p.getName());
        d.setLocation(p.getLocation());
        return d;
    }
}
