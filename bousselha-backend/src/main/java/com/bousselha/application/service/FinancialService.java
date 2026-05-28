package com.bousselha.application.service;

import com.bousselha.application.dto.response.ExpenseRecordResponse;
import com.bousselha.application.dto.response.IncomeRecordResponse;
import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.enums.ExpenseSource;
import com.bousselha.domain.enums.IncomeSource;
import com.bousselha.domain.model.Contract;
import com.bousselha.domain.model.ExpenseRecord;
import com.bousselha.domain.model.IncomeRecord;
import com.bousselha.domain.model.Maintenance;
import com.bousselha.domain.repository.ContractRepository;
import com.bousselha.domain.repository.ExpenseRecordRepository;
import com.bousselha.domain.repository.IncomeRecordRepository;
import com.bousselha.domain.repository.MaintenanceRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Service
@Transactional
public class FinancialService {
    private final IncomeRecordRepository incomeRecordRepository;
    private final ExpenseRecordRepository expenseRecordRepository;
    private final ContractRepository contractRepository;
    private final MaintenanceRepository maintenanceRepository;

    public FinancialService(
            IncomeRecordRepository incomeRecordRepository,
            ExpenseRecordRepository expenseRecordRepository,
            ContractRepository contractRepository,
            MaintenanceRepository maintenanceRepository
    ) {
        this.incomeRecordRepository = incomeRecordRepository;
        this.expenseRecordRepository = expenseRecordRepository;
        this.contractRepository = contractRepository;
        this.maintenanceRepository = maintenanceRepository;
    }

    public BigDecimal totalIncome() {
        return incomeRecordRepository.sumAll();
    }

    public BigDecimal totalExpense() {
        return expenseRecordRepository.sumAll();
    }

    public List<IncomeRecordResponse> listIncome(
            LocalDate from,
            LocalDate to,
            IncomeSource source,
            BigDecimal minAmount,
            BigDecimal maxAmount
    ) {
        return incomeRecordRepository.search(
                from != null ? from.atStartOfDay() : null,
                to != null ? to.atTime(LocalTime.MAX) : null,
                source,
                minAmount,
                maxAmount
        ).stream().map(this::mapIncome).toList();
    }

    public List<ExpenseRecordResponse> listExpenses(
            LocalDate from,
            LocalDate to,
            ExpenseSource source,
            String category
    ) {
        return expenseRecordRepository.search(
                from != null ? from.atStartOfDay() : null,
                to != null ? to.atTime(LocalTime.MAX) : null,
                source,
                category
        ).stream().map(this::mapExpense).toList();
    }

    public void recordIncomeFromContract(Contract contract) {
        if (contract.getTotalGeneral() == null || contract.getTotalGeneral().signum() <= 0) {
            return;
        }
        IncomeRecord record = incomeRecordRepository.findByContractId(contract.getId())
                .orElseGet(IncomeRecord::new);
        record.setAmount(contract.getTotalGeneral());
        record.setRecordedAt(LocalDateTime.now());
        record.setSource(IncomeSource.CONTRACT);
        record.setContractId(contract.getId());
        record.setDescription("Contrat #" + contract.getId() + " — " + contract.getClient().getFullName());
        incomeRecordRepository.save(record);
    }

    public void recordExpenseFromMaintenance(Maintenance maintenance) {
        if (maintenance.getCost() == null) {
            return;
        }
        ExpenseRecord record = expenseRecordRepository.findByMaintenanceId(maintenance.getId())
                .orElseGet(ExpenseRecord::new);
        record.setAmount(maintenance.getCost());
        record.setRecordedAt(maintenance.getCreatedAt() != null ? maintenance.getCreatedAt() : LocalDateTime.now());
        record.setSource(ExpenseSource.MAINTENANCE);
        record.setCategory(maintenance.getType());
        record.setDescription(maintenance.getDescription());
        record.setMaintenanceId(maintenance.getId());
        expenseRecordRepository.save(record);
    }

    public void syncLedgerFromExistingData() {
        for (Contract contract : contractRepository.findByDeletedFalse()) {
            if (contract.getStatus() == ContractStatus.ACTIVE || contract.getStatus() == ContractStatus.COMPLETED) {
                if (incomeRecordRepository.findByContractId(contract.getId()).isEmpty()) {
                    recordIncomeFromContract(contract);
                }
            }
        }
        for (Maintenance maintenance : maintenanceRepository.findAll()) {
            if (expenseRecordRepository.findByMaintenanceId(maintenance.getId()).isEmpty()) {
                recordExpenseFromMaintenance(maintenance);
            }
        }
    }

    private IncomeRecordResponse mapIncome(IncomeRecord i) {
        return new IncomeRecordResponse(
                i.getId(),
                i.getAmount(),
                i.getRecordedAt(),
                i.getSource(),
                i.getDescription(),
                i.getContractId(),
                i.getCreatedBy()
        );
    }

    private ExpenseRecordResponse mapExpense(ExpenseRecord e) {
        return new ExpenseRecordResponse(
                e.getId(),
                e.getAmount(),
                e.getRecordedAt(),
                e.getSource(),
                e.getCategory(),
                e.getDescription(),
                e.getMaintenanceId(),
                e.getCreatedBy()
        );
    }
}
