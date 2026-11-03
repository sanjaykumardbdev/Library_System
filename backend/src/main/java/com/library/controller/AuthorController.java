package com.library.controller;

import com.library.dto.AuthorDTO;
import com.library.service.AuthorService;
import org.springframework.web.bind.annotation.*;

import java.util.List;
/*
* Step 7 — Controller
Last backend layer:

AuthorController.java

Its job is to expose REST APIs.
The controller should generally be thin.

Don't put database logic here.

Don't put complicated business logic here.

The controller's main responsibility is:

HTTP request
    ↓
Controller
    ↓
Service
    ↓
HTTP response

 */
@RestController
@RequestMapping("/api/authors")
@CrossOrigin
public class AuthorController {

    private final AuthorService authorService;

    public AuthorController(AuthorService authorService) {
        this.authorService = authorService;
    }

    @GetMapping
    public List<AuthorDTO> findAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "100") int size,
            @RequestParam(required = false) String search) {

        return authorService.findAll(page, size, search);
    }

    @GetMapping("/{id}")
    public AuthorDTO findById(@PathVariable Long id) {

        return authorService.findById(id);
    }

    @PostMapping
    public AuthorDTO create(@RequestBody AuthorDTO dto) {

        return authorService.create(dto);
    }

    @PutMapping("/{id}")
    public AuthorDTO update(
            @PathVariable Long id,
            @RequestBody AuthorDTO dto) {

        return authorService.update(id, dto);
    }

    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) {

        authorService.delete(id);
    }
}