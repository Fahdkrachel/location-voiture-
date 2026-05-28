package com.bousselha.application.service;

import com.bousselha.domain.model.Contract;
import com.bousselha.domain.repository.ClientRepository;
import com.bousselha.domain.repository.ContractRepository;
import com.bousselha.domain.repository.IncomeRecordRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Suppression contrôlée des clients sans contrat actif, en respectant les clés étrangères.
 */
@Service
@Transactional
public class OrphanClientService {
    private final ContractRepository contractRepository;
    private final ClientRepository clientRepository;
    private final IncomeRecordRepository incomeRecordRepository;

    public OrphanClientService(
            ContractRepository contractRepository,
            ClientRepository clientRepository,
            IncomeRecordRepository incomeRecordRepository
    ) {
        this.contractRepository = contractRepository;
        this.clientRepository = clientRepository;
        this.incomeRecordRepository = incomeRecordRepository;
    }

    /**
     * Supprime le client si aucun contrat non supprimé ne lui est rattaché.
     * Les contrats soft-deleted restants (et leurs revenus liés) sont supprimés physiquement avant le client.
     */
    public void removeClientIfOrphan(Long clientId) {
        if (contractRepository.countByDeletedFalseAndClientId(clientId) > 0) {
            return;
        }
        if (!clientRepository.existsById(clientId)) {
            return;
        }
        deleteAllContractsForClient(clientId);
        clientRepository.deleteById(clientId);
    }

    private void deleteAllContractsForClient(Long clientId) {
        List<Contract> contracts = contractRepository.findByClientId(clientId);
        for (Contract contract : contracts) {
            incomeRecordRepository.deleteByContractId(contract.getId());
            contractRepository.delete(contract);
        }
    }
}
