package com.library.controller;

import com.library.dto.BorrowedBookResponse;
import com.library.dto.ChargeRequest;
import com.library.dto.IssueBookRequest;
import com.library.dto.PaymentRequest;
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
@RequestMapping("/api/admin/loans")
public class AdminLoanController {

    private final LoanService loanService;

    public AdminLoanController(LoanService loanService) {
        this.loanService = loanService;
    }

    @GetMapping
    public List<BorrowedBookResponse> activeLoans() {
        return loanService.findActiveLoans();
    }

    @GetMapping("/history")
    public List<BorrowedBookResponse> loanHistory() {
        return loanService.findAllLoans();
    }

    @PostMapping
    public BorrowedBookResponse issue(@Valid @RequestBody IssueBookRequest request) {
        return loanService.issue(request.getMemberId(), request.getBookId());
    }

    @PostMapping("/{loanId}/return")
    public BorrowedBookResponse returnLoan(@PathVariable Long loanId) {
        if (loanId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Loan ID must be positive");
        }
        return loanService.returnLoan(loanId);
    }

    @PostMapping("/{loanId}/lost")
    public BorrowedBookResponse markLost(
            @PathVariable Long loanId,
            @Valid @RequestBody ChargeRequest request) {
        if (loanId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Loan ID must be positive");
        }
        return loanService.markLost(loanId, request.getAmount());
    }

    @PostMapping("/{loanId}/payments")
    public BorrowedBookResponse receivePayment(
            @PathVariable Long loanId,
            @Valid @RequestBody PaymentRequest request,
            @AuthenticationPrincipal AppUser user) {
        if (loanId <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Loan ID must be positive");
        }
        return loanService.recordPayment(loanId, request.getAmount(), user.getId());
    }
}