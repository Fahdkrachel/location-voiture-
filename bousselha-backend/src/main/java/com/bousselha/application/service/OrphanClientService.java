package com.bousselha.application.service;

import com.bousselha.domain.model.Contract;
import com.bousselha.domain.repository.ClientRepository;
import com.bousselha.domain.repository.ContractRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * Suppression contrôlée des clients sans contrat actif, en respectant les clés étrangères.
 * Les revenus (income_records) sont conservés même après suppression des contrats.
 */
@Service
@Transactional
public class OrphanClientService {
    private final ContractRepository contractRepository;
    private final ClientRepository clientRepository;

    public OrphanClientService(
            ContractRepository contractRepository,
            ClientRepository clientRepository
    ) {
        this.contractRepository = contractRepository;
        this.clientRepository = clientRepository;
    }

    /**
     * Supprime le client si aucun contrat non supprimé ne lui est rattaché.
     * Les contrats archivés sont supprimés physiquement ; les lignes income_records restent en base.
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
            contractRepository.delete(contract);
        }
    }
}
