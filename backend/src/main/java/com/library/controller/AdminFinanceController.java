package com.library.controller;

import com.library.dto.BankAccountResponse;
import com.library.dto.FineDepositResponse;
import com.library.entity.AppUser;
import com.library.repository.FinanceRepository;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/admin/finance")
public class AdminFinanceController {

    private final FinanceRepository financeRepository;

    public AdminFinanceController(FinanceRepository financeRepository) {
        this.financeRepository = financeRepository;
    }

    @GetMapping("/account")
    public BankAccountResponse account() {
        return financeRepository.getAccount();
    }

    @GetMapping("/deposits")
    public List<FineDepositResponse> deposits() {
        return financeRepository.findDeposits();
    }

    @PostMapping("/deposits")
    public BankAccountResponse deposit(@AuthenticationPrincipal AppUser admin) {
        return financeRepository.depositCollectedFines(admin.getId());
    }
}
