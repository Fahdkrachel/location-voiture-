package com.bousselha.application.service;

import com.bousselha.application.dto.request.ClientRequest;
import com.bousselha.application.dto.response.ClientResponse;
import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.model.Client;
import com.bousselha.domain.repository.ClientRepository;
import com.bousselha.domain.repository.ContractRepository;
import com.bousselha.infrastructure.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class ClientService {
    private final ClientRepository clientRepository;
    private final ContractRepository contractRepository;
    private final OrphanClientService orphanClientService;

    public ClientService(
            ClientRepository clientRepository,
            ContractRepository contractRepository,
            OrphanClientService orphanClientService
    ) {
        this.clientRepository = clientRepository;
        this.contractRepository = contractRepository;
        this.orphanClientService = orphanClientService;
    }

    public List<ClientResponse> findAll() {
        return clientRepository.findAll().stream()
                .filter(c -> contractRepository.countByDeletedFalseAndClientId(c.getId()) > 0)
                .map(this::map)
                .toList();
    }

    public ClientResponse findById(Long id) {
        return map(getClient(id));
    }

    public ClientResponse create(ClientRequest request) {
        Client client = new Client();
        apply(client, request);
        return map(clientRepository.save(client));
    }

    public ClientResponse update(Long id, ClientRequest request) {
        Client client = getClient(id);
        apply(client, request);
        return map(clientRepository.save(client));
    }

    public void delete(Long id) {
        Client client = getClient(id);
        boolean hasOpenContracts = contractRepository.existsByClientIdAndDeletedFalseAndStatusIn(
                client.getId(), java.util.EnumSet.of(ContractStatus.IN_PROGRESS, ContractStatus.ACTIVE));
        if (hasOpenContracts) {
            throw new IllegalArgumentException("Impossible de supprimer : client a des contrats en cours");
        }
        orphanClientService.removeClientIfOrphan(id);
    }

    private Client getClient(Long id) {
        return clientRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Client not found: " + id));
    }

    private void apply(Client client, ClientRequest request) {
        client.setFullName(request.fullName());
        client.setBirthDate(request.birthDate());
        client.setAddressMorocco(request.addressMorocco());
        client.setAddressAbroad(request.addressAbroad());
        client.setProfession(request.profession());
        client.setDrivingLicenseNumber(request.drivingLicenseNumber());
        client.setDrivingLicenseIssuedAt(request.drivingLicenseIssuedAt());
        client.setCinNumber(request.cinNumber());
        client.setPassportNumber(request.passportNumber());
        client.setPassportIssuedAt(request.passportIssuedAt());
        client.setPhone(request.phone());

        client.setAdditionalDriverFullName(request.additionalDriverFullName());
        client.setAdditionalDriverDrivingLicenseNumber(request.additionalDriverDrivingLicenseNumber());
        client.setAdditionalDriverDrivingLicenseIssuedAt(request.additionalDriverDrivingLicenseIssuedAt());
        client.setAdditionalDriverPassportNumber(request.additionalDriverPassportNumber());
    }

    private ClientResponse map(Client client) {
        return new ClientResponse(
                client.getId(),
                client.getFullName(),
                client.getBirthDate(),
                client.getAddressMorocco(),
                client.getAddressAbroad(),
                client.getProfession(),
                client.getDrivingLicenseNumber(),
                client.getDrivingLicenseIssuedAt(),
                client.getCinNumber(),
                client.getPassportNumber(),
                client.getPassportIssuedAt(),
                client.getPhone(),
                client.getAdditionalDriverFullName(),
                client.getAdditionalDriverDrivingLicenseNumber(),
                client.getAdditionalDriverDrivingLicenseIssuedAt(),
                client.getAdditionalDriverPassportNumber()
        );
    }
}
