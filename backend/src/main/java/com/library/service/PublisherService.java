package com.library.service;

import com.library.dto.PublisherDTO;
import java.util.List;

public interface PublisherService {
    List<PublisherDTO> findAll();
    PublisherDTO findById(Long id);
    PublisherDTO create(PublisherDTO dto);
    PublisherDTO update(Long id, PublisherDTO dto);
    void delete(Long id);
}
