package com.bousselha.application.controller;

import com.bousselha.application.dto.response.ExpenseRecordResponse;
import com.bousselha.application.dto.response.IncomeRecordResponse;
import com.bousselha.application.service.FinancialService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/financial")
public class FinancialController {
    private final FinancialService financialService;

    public FinancialController(FinancialService financialService) {
        this.financialService = financialService;
    }

    @GetMapping("/income")
    public List<IncomeRecordResponse> income() {
        return financialService.listAllIncome();
    }

    @GetMapping("/expenses")
    public List<ExpenseRecordResponse> expenses() {
        return financialService.listAllExpenses();
    }
}
