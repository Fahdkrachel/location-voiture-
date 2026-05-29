package com.bousselha.application.service;

import com.bousselha.domain.repository.ClientRepository;
import com.bousselha.domain.repository.ContractRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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
     * Supprime le client uniquement s'il n'a plus aucun contrat (même archivé).
     * Les contrats soft-deleted restent en base pour l'historique des locations par voiture.
     */
    public void removeClientIfOrphan(Long clientId) {
        if (contractRepository.countByDeletedFalseAndClientId(clientId) > 0) {
            return;
        }
        if (!clientRepository.existsById(clientId)) {
            return;
        }
        if (contractRepository.countByClientId(clientId) > 0) {
            return;
        }
        clientRepository.deleteById(clientId);
    }
}
