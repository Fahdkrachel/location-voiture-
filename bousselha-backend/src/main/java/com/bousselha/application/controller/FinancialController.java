package com.bousselha.application.controller;

import com.bousselha.application.dto.response.ExpenseRecordResponse;
import com.bousselha.application.dto.response.IncomeRecordResponse;
import com.bousselha.application.service.FinancialService;
import com.bousselha.domain.enums.ExpenseSource;
import com.bousselha.domain.enums.IncomeSource;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/financial")
public class FinancialController {
    private final FinancialService financialService;

    public FinancialController(FinancialService financialService) {
        this.financialService = financialService;
    }

    @GetMapping("/income")
    public List<IncomeRecordResponse> income(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) IncomeSource source,
            @RequestParam(required = false) BigDecimal minAmount,
            @RequestParam(required = false) BigDecimal maxAmount
    ) {
        return financialService.listIncome(from, to, source, minAmount, maxAmount);
    }

    @GetMapping("/expenses")
    public List<ExpenseRecordResponse> expenses(
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(required = false) ExpenseSource source,
            @RequestParam(required = false) String category
    ) {
        return financialService.listExpenses(from, to, source, category);
    }
}
