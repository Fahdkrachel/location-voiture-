package com.bousselha.infrastructure.controller;

import com.bousselha.application.dto.request.ContractRequest;
import com.bousselha.application.dto.request.ContractStatusRequest;
import com.bousselha.application.dto.response.ContractResponse;
import com.bousselha.application.service.ContractService;
import com.bousselha.application.service.PdfService;
import jakarta.validation.Valid;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/contracts")
public class ContractController {
    private final ContractService contractService;
    private final PdfService pdfService;

    public ContractController(ContractService contractService, PdfService pdfService) {
        this.contractService = contractService;
        this.pdfService = pdfService;
    }

    @GetMapping
    public List<ContractResponse> findAll(@RequestParam(required = false) Long carId) {
        return carId == null ? contractService.findAll() : contractService.findAllByCarId(carId);
    }
    @GetMapping("/{id}")
    public ContractResponse findById(@PathVariable Long id) { return contractService.findById(id); }
    @GetMapping("/active")
    public List<ContractResponse> active() { return contractService.findActive(); }
    @PostMapping
    public ContractResponse create(@Valid @RequestBody ContractRequest request) { return contractService.create(request); }
    @PutMapping("/{id}/return")
    public ContractResponse registerReturn(@PathVariable Long id) { return contractService.registerReturn(id); }

    @PatchMapping("/{id}/status")
    public ContractResponse updateStatus(@PathVariable Long id, @Valid @RequestBody ContractStatusRequest request) {
        return contractService.updateStatus(id, request.status());
    }

    @PutMapping("/{id}")
    public ContractResponse update(@PathVariable Long id, @Valid @RequestBody ContractRequest request) {
        return contractService.update(id, request);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> softDelete(@PathVariable Long id) {
        contractService.softDelete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/{id}/pdf")
    public ResponseEntity<byte[]> pdf(@PathVariable Long id) throws IOException {
        byte[] bytes = pdfService.generateContractPdf(id);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION, "inline; filename=contract-" + id + ".pdf")
                .contentType(MediaType.APPLICATION_PDF)
                .body(bytes);
    }
}
