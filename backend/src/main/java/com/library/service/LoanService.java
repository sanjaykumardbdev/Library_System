package com.library.service;

import com.library.dto.BorrowedBookResponse;
import com.library.dto.TopBorrowedBookResponse;
import com.library.repository.LoanRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.List;

@Service
public class LoanService {

    private final LoanRepository loanRepository;

    public LoanService(LoanRepository loanRepository) {
        this.loanRepository = loanRepository;
    }

    @Transactional(readOnly = true)
    public List<BorrowedBookResponse> findMemberHistory(Long memberId) {
        return loanRepository.findByMemberId(memberId);
    }

    @Transactional(readOnly = true)
    public List<BorrowedBookResponse> findActiveLoans() {
        return loanRepository.findActiveLoans();
    }

    @Transactional(readOnly = true)
    public List<BorrowedBookResponse> findAllLoans() {
        return loanRepository.findAllLoans();
    }

    @Transactional(readOnly = true)
    public List<TopBorrowedBookResponse> findTopBorrowedBooks(int limit) {
        return loanRepository.findTopBorrowedBooks(limit);
    }

    @Transactional
    public BorrowedBookResponse issue(Long memberId, Long bookId) {
        return loanRepository.issueBook(memberId, bookId);
    }

    @Transactional
    public BorrowedBookResponse returnLoan(Long loanId) {
        return loanRepository.returnBook(loanId);
    }

    @Transactional
    public BorrowedBookResponse returnMemberLoan(Long loanId, Long memberId) {
        return loanRepository.returnMemberBook(loanId, memberId);
    }

    @Transactional
    public BorrowedBookResponse markLost(Long loanId, BigDecimal amount) {
        return loanRepository.markLost(loanId, amount);
    }

    @Transactional
    public BorrowedBookResponse recordPayment(Long loanId, BigDecimal amount, Long receivedBy) {
        return loanRepository.recordPayment(loanId, amount, receivedBy);
    }
}