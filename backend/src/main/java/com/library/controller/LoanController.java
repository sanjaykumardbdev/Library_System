package com.library.controller;

import com.library.dto.BorrowedBookResponse;
import com.library.dto.BookLoanRequest;
import com.library.entity.AppUser;
import com.library.service.LoanService;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/me/loans")
public class LoanController {

    private final LoanService loanService;

    public LoanController(LoanService loanService) {
        this.loanService = loanService;
    }

    @GetMapping
    public List<BorrowedBookResponse> history(@AuthenticationPrincipal AppUser user) {
        return loanService.findMemberHistory(requireMember(user));
    }

    @PostMapping
    public BorrowedBookResponse borrow(
            @AuthenticationPrincipal AppUser user,
            @Valid @RequestBody BookLoanRequest request) {
        return loanService.issue(requireMember(user), request.getBookId());
    }

    @PostMapping("/{loanId}/return")
    public BorrowedBookResponse returnLoan(
            @AuthenticationPrincipal AppUser user,
            @PathVariable Long loanId) {
        if (loanId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Loan ID must be positive");
        }
        return loanService.returnMemberLoan(loanId, requireMember(user));
    }

    private Long requireMember(AppUser user) {
        if (user.getMemberId() == null) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Borrowing requires an account linked to an active Student or Professional membership. Ask a library administrator to link or activate your membership.");
        }
        if (user.getAuthorities().stream().noneMatch(authority -> "ROLE_MEMBER".equals(authority.getAuthority()))) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Borrowing is available to Student and Professional member accounts, not administrator-only accounts.");
        }
        return user.getMemberId();
    }
}