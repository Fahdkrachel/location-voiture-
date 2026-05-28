package com.bousselha.infrastructure.controller;

import com.bousselha.application.dto.request.ClientRequest;
import com.bousselha.application.dto.response.ClientResponse;
import com.bousselha.application.service.ClientService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/clients")
public class ClientController {
    private final ClientService clientService;

    public ClientController(ClientService clientService) {
        this.clientService = clientService;
    }

    @GetMapping
    public List<ClientResponse> findAll() { return clientService.findAll(); }
    @GetMapping("/{id}")
    public ClientResponse findById(@PathVariable Long id) { return clientService.findById(id); }
    @PostMapping
    public ClientResponse create(@Valid @RequestBody ClientRequest request) { return clientService.create(request); }
    @PutMapping("/{id}")
    public ClientResponse update(@PathVariable Long id, @Valid @RequestBody ClientRequest request) { return clientService.update(id, request); }
    @DeleteMapping("/{id}")
    public void delete(@PathVariable Long id) { clientService.delete(id); }
}
