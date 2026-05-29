package com.bousselha.application.service;

import com.bousselha.application.dto.response.ExpenseRecordResponse;
import com.bousselha.application.dto.response.IncomeRecordResponse;
import com.bousselha.domain.enums.ExpenseSource;
import com.bousselha.domain.enums.IncomeSource;
import com.bousselha.domain.model.Car;
import com.bousselha.domain.model.Contract;
import com.bousselha.domain.model.ExpenseRecord;
import com.bousselha.domain.model.IncomeRecord;
import com.bousselha.domain.model.Maintenance;
import com.bousselha.domain.repository.ExpenseRecordRepository;
import com.bousselha.domain.repository.IncomeRecordRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class FinancialService {
    private final IncomeRecordRepository incomeRecordRepository;
    private final ExpenseRecordRepository expenseRecordRepository;
    public FinancialService(
            IncomeRecordRepository incomeRecordRepository,
            ExpenseRecordRepository expenseRecordRepository
    ) {
        this.incomeRecordRepository = incomeRecordRepository;
        this.expenseRecordRepository = expenseRecordRepository;
    }

    public BigDecimal totalIncome() {
        return incomeRecordRepository.sumAll();
    }

    public BigDecimal totalExpense() {
        return expenseRecordRepository.sumAll();
    }

    public List<IncomeRecordResponse> listAllIncome() {
        return incomeRecordRepository.findAllByOrderByRecordedAtDesc().stream()
                .map(this::mapIncome)
                .toList();
    }

    public List<ExpenseRecordResponse> listAllExpenses() {
        return expenseRecordRepository.findAllByOrderByRecordedAtDesc().stream()
                .map(this::mapExpense)
                .toList();
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
        record.setClientId(contract.getClient().getId());
        record.setClientName(contract.getClient().getFullName());
        record.setDescription("Contrat #" + contract.getId() + " — " + contract.getClient().getFullName());
        incomeRecordRepository.save(record);
    }

    /** Enregistre le revenu une seule fois (activation, clôture ou suppression d’un contrat terminé). */
    public void ensureIncomeForContract(Contract contract) {
        if (incomeRecordRepository.findByContractId(contract.getId()).isPresent()) {
            return;
        }
        recordIncomeFromContract(contract);
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
        Car car = maintenance.getCar();
        if (car != null) {
            record.setCarName(car.getBrand() + " — " + car.getMatricule());
        }
        expenseRecordRepository.save(record);
    }

    private IncomeRecordResponse mapIncome(IncomeRecord i) {
        return new IncomeRecordResponse(
                i.getId(),
                i.getAmount(),
                i.getRecordedAt(),
                i.getSource(),
                i.getDescription(),
                i.getContractId(),
                i.getClientId(),
                i.getClientName()
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
                e.getCarName()
        );
    }
}
