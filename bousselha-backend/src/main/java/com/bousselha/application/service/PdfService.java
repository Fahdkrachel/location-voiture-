package com.bousselha.application.service;

import com.bousselha.domain.model.Contract;
import com.bousselha.domain.repository.ContractRepository;
import com.bousselha.infrastructure.exception.ResourceNotFoundException;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;

@Service
public class PdfService {
    private final ContractRepository contractRepository;

    public PdfService(ContractRepository contractRepository) {
        this.contractRepository = contractRepository;
    }

    public byte[] generateContractPdf(Long id) throws IOException {
        Contract contract = contractRepository.findById(id)
                .filter(c -> !c.isDeleted())
                .orElseThrow(() -> new ResourceNotFoundException("Contract not found: " + id));

        try (PDDocument doc = new PDDocument(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);
            PDType1Font bold = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
            PDType1Font regular = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
            try (PDPageContentStream cs = new PDPageContentStream(doc, page)) {
                cs.beginText();
                cs.setFont(bold, 14);
                cs.newLineAtOffset(50, 780);
                cs.showText("BOUSSELHA CARS - CONTRAT DE LOCATION");
                cs.endText();

                cs.beginText();
                cs.setFont(regular, 11);
                cs.newLineAtOffset(50, 750);
                cs.showText("Client: " + contract.getClient().getFullName());
                cs.newLineAtOffset(0, -18);
                cs.showText("Vehicule: " + contract.getCar().getBrand() + " (" + contract.getCar().getMatricule() + ")");
                cs.newLineAtOffset(0, -18);
                cs.showText("Depart: " + contract.getDepartureDatetime());
                cs.newLineAtOffset(0, -18);
                cs.showText("Retour prevu: " + contract.getExpectedReturnDatetime());
                cs.newLineAtOffset(0, -18);
                cs.showText("Total general: " + contract.getTotalGeneral());
                cs.endText();
            }
            doc.save(out);
            return out.toByteArray();
        }
    }
}
