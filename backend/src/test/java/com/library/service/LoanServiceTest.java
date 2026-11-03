package com.library.service;

import com.library.dto.BorrowedBookResponse;
import com.library.repository.LoanRepository;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class LoanServiceTest {

    @Mock private LoanRepository loanRepository;
    @InjectMocks private LoanService loanService;

    @Test
    void memberHistoryUsesOnlyTheAuthenticatedMemberId() {
        BorrowedBookResponse loan = new BorrowedBookResponse();
        loan.setLoanId(123L);
        when(loanRepository.findByMemberId(1001L)).thenReturn(List.of(loan));

        List<BorrowedBookResponse> history = loanService.findMemberHistory(1001L);

        assertEquals(123L, history.get(0).getLoanId());
        verify(loanRepository).findByMemberId(1001L);
    }
}