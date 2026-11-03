package com.library.controller;

import com.library.dto.BookDTO;
import com.library.dto.TopBorrowedBookResponse;
import com.library.service.BookService;
import com.library.service.LoanService;
import org.springframework.data.domain.Page;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/books")
public class BookController {

    private final BookService service;
    private final LoanService loanService;

    public BookController(BookService service, LoanService loanService) {
        this.service = service;
        this.loanService = loanService;
    }

    @GetMapping("/top-borrowed")
    public List<TopBorrowedBookResponse> topBorrowed(@RequestParam(defaultValue = "5") int limit) {
        return loanService.findTopBorrowedBooks(limit);
    }

    @GetMapping
    public ResponseEntity<Page<BookDTO>> list(@RequestParam(defaultValue = "0") int page,
                                              @RequestParam(defaultValue = "5") int size,
                                              @RequestParam(required = false) String search) {
        return ResponseEntity.ok(service.findAll(page, size, search));
    }

    @GetMapping("/{id}")
    public ResponseEntity<BookDTO> get(@PathVariable Long id) {
        BookDTO dto = service.findById(id);
        if (dto == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(dto);
    }

    @PostMapping
    public ResponseEntity<BookDTO> create(@RequestBody BookDTO dto) { return ResponseEntity.ok(service.create(dto)); }

    @PutMapping("/{id}")
    public ResponseEntity<BookDTO> update(@PathVariable Long id, @RequestBody BookDTO dto) {
        BookDTO updated = service.update(id, dto);
        if (updated == null) return ResponseEntity.notFound().build();
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) { service.delete(id); return ResponseEntity.noContent().build(); }
}
