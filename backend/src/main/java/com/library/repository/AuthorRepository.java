package com.library.repository;

import com.library.entity.Author;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
/*
 * Step 4 — Repository
 Step 4 — Repository
 You normally don't write SQL for these basic operations.

Spring Data JPA provides them.

 */
@Repository
public interface AuthorRepository extends JpaRepository<Author, Long> {
}