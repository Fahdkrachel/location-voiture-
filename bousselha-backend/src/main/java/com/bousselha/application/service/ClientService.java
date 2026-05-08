package com.bousselha.application.service;

import com.bousselha.application.dto.request.ClientRequest;
import com.bousselha.application.dto.response.ClientResponse;
import com.bousselha.domain.model.Client;
import com.bousselha.domain.repository.ClientRepository;
import com.bousselha.infrastructure.exception.ResourceNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class ClientService {
    private final ClientRepository clientRepository;

    public ClientService(ClientRepository clientRepository) {
        this.clientRepository = clientRepository;
    }

    public List<ClientResponse> findAll() {
        return clientRepository.findAll().stream().map(this::map).toList();
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
                client.getPhone()
        );
    }
}
