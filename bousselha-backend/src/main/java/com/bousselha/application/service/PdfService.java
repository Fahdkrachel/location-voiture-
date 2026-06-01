package com.bousselha.application.service;

import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.model.Contract;
import com.bousselha.domain.repository.ContractRepository;
import com.bousselha.infrastructure.exception.ResourceNotFoundException;
import org.apache.pdfbox.pdmodel.PDDocument;
import org.apache.pdfbox.pdmodel.PDPage;
import org.apache.pdfbox.pdmodel.PDPageContentStream;
import org.apache.pdfbox.pdmodel.common.PDRectangle;
import org.apache.pdfbox.pdmodel.font.Standard14Fonts;
import org.apache.pdfbox.pdmodel.font.PDType1Font;
import org.apache.pdfbox.pdmodel.font.PDFont;
import org.apache.pdfbox.pdmodel.graphics.image.PDImageXObject;
import org.springframework.stereotype.Service;

import java.awt.Color;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Service
public class PdfService {
    private final ContractRepository contractRepository;

    public PdfService(ContractRepository contractRepository) {
        this.contractRepository = contractRepository;
    }

    public byte[] generateContractPdf(Long id) throws IOException {
        Contract contract = contractRepository.findDetailedById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contract not found: " + id));

        if (contract.getStatus() != ContractStatus.ACTIVE && contract.getStatus() != ContractStatus.COMPLETED) {
            throw new IllegalArgumentException(
                    "Le PDF est disponible uniquement après activation du contrat (statut ACTIVE ou termine)");
        }

        try (PDDocument doc = new PDDocument(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);

            PDType1Font bold = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
            PDType1Font regular = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
            PDType1Font italic = new PDType1Font(Standard14Fonts.FontName.HELVETICA_OBLIQUE);

            Color darkBlue = new Color(11, 59, 140);
            Color lightBlue = new Color(208, 225, 253);
            Color borderGrey = new Color(127, 127, 127);
            Color textBlack = Color.BLACK;

            try (PDPageContentStream cs = new PDPageContentStream(doc, page)) {
                // Outer Border of the entire document grid area
                // Width = 555 (from 20 to 575), Height = 692 (from 130 to 822)
                drawRect(cs, 20, 130, 555, 692, 1f, darkBlue);

                // --- 1. HEADER (Y = 752 to 822) ---
                // Left header box (Logo space): X = 20 to 200 (width = 180)
                drawVerticalLine(cs, 200, 752, 822, 1f, darkBlue);
                drawHorizontalLine(cs, 20, 575, 752, 1f, darkBlue);

                // Check logo
                File logoFile = new File("src/main/resources/static/images/logo.png");
                if (!logoFile.exists()) {
                    logoFile = new File("bousselha-backend/src/main/resources/static/images/logo.png");
                }
                if (logoFile.exists() && logoFile.isFile()) {
                    try {
                        PDImageXObject pdImage = PDImageXObject.createFromFileByExtension(logoFile, doc);
                        // Draw image scaled inside the left header box
                        cs.drawImage(pdImage, 25, 757, 170, 60);
                    } catch (Exception e) {
                        // Fallback to text if error loading logo
                        drawHeaderTextFallback(cs, bold, regular, darkBlue);
                    }
                } else {
                    drawHeaderTextFallback(cs, bold, regular, darkBlue);
                }

                // Right header box (Company contact info)
                drawText(cs, "Branes 1, Rue Ibn Chahid N°11 - Tanger", 210, 804, bold, 9, textBlack);
                drawText(cs, "Tél/Fax : 05 39 31 54 63", 210, 790, regular, 9, textBlack);
                drawText(cs, "Gsm : 06 89 12 48 89 / 06 61 54 99 92", 210, 776, regular, 9, textBlack);
                drawText(cs, "E-mail : bousselhaa@gmail.com", 210, 762, regular, 9, textBlack);


                // --- 2. BANNER (Y = 734 to 752) ---
                fillRect(cs, 20, 734, 555, 18, darkBlue);
                drawTextAligned(cs, "CONTRAT DE LOCATION", 30, 739, bold, 10, Color.WHITE, "left", 305);
                drawTextAligned(cs, "Contrat de Location de Voiture", 340, 739, regular, 9, Color.WHITE, "left", 230);


                // --- 3. VEHICLE & DATES SECTION (Y = 644 to 734) ---
                drawHorizontalLine(cs, 20, 575, 644, 1f, darkBlue);
                drawVerticalLine(cs, 335, 644, 734, 1f, darkBlue);

                // Left Column: Vehicle details
                float rowH = 22.5f;
                // Vertical split inside left column for label vs value
                drawVerticalLine(cs, 130, 644, 734, 0.5f, borderGrey);
                for (int i = 1; i <= 3; i++) {
                    drawHorizontalLine(cs, 20, 335, 734 - i * rowH, 0.5f, borderGrey);
                }
                
                // Labels
                drawText(cs, "Marque", 25, 720, bold, 9, darkBlue);
                drawText(cs, "N° Immatriculation", 25, 697.5f, bold, 9, darkBlue);
                drawText(cs, "Lieu de Livraison", 25, 675, bold, 9, darkBlue);
                drawText(cs, "Lieu de Reprise", 25, 652.5f, bold, 9, darkBlue);

                // Values
                if (contract.getCar() != null) {
                    drawText(cs, contract.getCar().getBrand(), 135, 720, regular, 9, textBlack);
                    drawText(cs, contract.getCar().getMatricule(), 135, 697.5f, regular, 9, textBlack);
                }
                drawText(cs, contract.getDeparturePlace(), 135, 675, regular, 9, textBlack);
                drawText(cs, contract.getReturnPlace(), 135, 652.5f, regular, 9, textBlack);

                // Right Column: Date table
                // Header (dark blue background)
                fillRect(cs, 335, 711.5f, 240, 22.5f, darkBlue);
                drawVerticalLine(cs, 430, 644, 734, 0.5f, borderGrey);
                drawVerticalLine(cs, 465, 644, 734, 0.5f, borderGrey);
                drawVerticalLine(cs, 500, 644, 734, 0.5f, borderGrey);
                drawVerticalLine(cs, 535, 644, 734, 0.5f, borderGrey);
                drawVerticalLine(cs, 555, 644, 734, 0.5f, borderGrey);

                drawTextAligned(cs, "J", 430, 719, bold, 9, Color.WHITE, "center", 35);
                drawTextAligned(cs, "M", 465, 719, bold, 9, Color.WHITE, "center", 35);
                drawTextAligned(cs, "A", 500, 719, bold, 9, Color.WHITE, "center", 35);
                drawTextAligned(cs, "H", 535, 719, bold, 9, Color.WHITE, "center", 20);
                drawTextAligned(cs, "mn", 555, 719, bold, 9, Color.WHITE, "center", 20);

                for (int i = 1; i <= 3; i++) {
                    drawHorizontalLine(cs, 335, 575, 734 - i * rowH, 0.5f, borderGrey);
                }

                // Row labels
                drawText(cs, "Départ", 340, 697.5f, bold, 9, textBlack);
                drawText(cs, "Retour Prévu", 340, 675, bold, 9, textBlack);
                drawText(cs, "Retour Définitif", 340, 652.5f, bold, 9, textBlack);
                drawText(cs, "Durée", 340, 630, bold, 9, textBlack); // Note: Y = 620 to 644 is Durée

                // Fill Date Departure
                LocalDateTime dep = contract.getDepartureDatetime();
                if (dep != null) {
                    drawTextAligned(cs, String.format("%02d", dep.getDayOfMonth()), 430, 697.5f, regular, 9, textBlack, "center", 35);
                    drawTextAligned(cs, String.format("%02d", dep.getMonthValue()), 465, 697.5f, regular, 9, textBlack, "center", 35);
                    drawTextAligned(cs, String.valueOf(dep.getYear()), 500, 697.5f, regular, 9, textBlack, "center", 35);
                    drawTextAligned(cs, String.format("%02d", dep.getHour()), 535, 697.5f, regular, 9, textBlack, "center", 20);
                    drawTextAligned(cs, String.format("%02d", dep.getMinute()), 555, 697.5f, regular, 9, textBlack, "center", 20);
                }

                // Fill Date Expected Return
                LocalDateTime ret = contract.getExpectedReturnDatetime();
                if (ret != null) {
                    drawTextAligned(cs, String.format("%02d", ret.getDayOfMonth()), 430, 675, regular, 9, textBlack, "center", 35);
                    drawTextAligned(cs, String.format("%02d", ret.getMonthValue()), 465, 675, regular, 9, textBlack, "center", 35);
                    drawTextAligned(cs, String.valueOf(ret.getYear()), 500, 675, regular, 9, textBlack, "center", 35);
                    drawTextAligned(cs, String.format("%02d", ret.getHour()), 535, 675, regular, 9, textBlack, "center", 20);
                    drawTextAligned(cs, String.format("%02d", ret.getMinute()), 555, 675, regular, 9, textBlack, "center", 20);
                }

                // Duration Days (placed in 'J' column of Durée row)
                if (contract.getDurationDays() != null) {
                    drawTextAligned(cs, String.valueOf(contract.getDurationDays()), 430, 630, regular, 9, textBlack, "center", 35);
                }


                // --- 4. LOCATAIRE & PRICING SECTION (Y = 410 to 644) ---
                drawHorizontalLine(cs, 20, 575, 410, 1f, darkBlue);
                drawVerticalLine(cs, 335, 410, 644, 1f, darkBlue);

                // Left Column: Customer Details (Locataire)
                // Customer Header (light blue background)
                fillRect(cs, 20, 628, 315, 16, lightBlue);
                drawText(cs, "Locataire", 25, 632, bold, 9, darkBlue);

                float custRowH = 19.8f;
                drawVerticalLine(cs, 130, 410, 628, 0.5f, borderGrey);
                for (int i = 1; i <= 10; i++) {
                    drawHorizontalLine(cs, 20, 335, 628 - i * custRowH, 0.5f, borderGrey);
                }

                // Labels
                drawText(cs, "Nom & Prénom", 25, 613, bold, 8, darkBlue);
                drawText(cs, "Date de naissance", 25, 593, bold, 8, darkBlue);
                drawText(cs, "Adresse au Maroc", 25, 573, bold, 8, darkBlue);
                drawText(cs, "Adresse à l'Étranger", 25, 553, bold, 8, darkBlue);
                drawText(cs, "Profession", 25, 533, bold, 8, darkBlue);
                drawText(cs, "Permis de Conduire N°", 25, 513, bold, 8, darkBlue);
                drawText(cs, "Délivré à", 25, 493, bold, 8, darkBlue);
                drawText(cs, "C.I.N. N°", 25, 473, bold, 8, darkBlue);
                drawText(cs, "Passeport N°", 25, 453, bold, 8, darkBlue);
                drawText(cs, "Délivré Le", 25, 433, bold, 8, darkBlue);
                drawText(cs, "Tél", 25, 413, bold, 8, darkBlue);

                // Values
                if (contract.getClient() != null) {
                    drawText(cs, contract.getClient().getFullName(), 135, 613, regular, 8, textBlack);
                    drawText(cs, formatDate(contract.getClient().getBirthDate()), 135, 593, regular, 8, textBlack);
                    drawText(cs, contract.getClient().getAddressMorocco(), 135, 573, regular, 8, textBlack);
                    drawText(cs, contract.getClient().getAddressAbroad(), 135, 553, regular, 8, textBlack);
                    drawText(cs, contract.getClient().getProfession(), 135, 533, regular, 8, textBlack);
                    drawText(cs, contract.getClient().getDrivingLicenseNumber(), 135, 513, regular, 8, textBlack);
                    drawText(cs, contract.getClient().getDrivingLicenseIssuedAt(), 135, 493, regular, 8, textBlack);
                    drawText(cs, contract.getClient().getCinNumber(), 135, 473, regular, 8, textBlack);
                    drawText(cs, contract.getClient().getPassportNumber(), 135, 453, regular, 8, textBlack);
                    drawText(cs, formatDate(contract.getClient().getPassportIssuedAt()), 135, 433, regular, 8, textBlack);
                    drawText(cs, contract.getClient().getPhone(), 135, 413, regular, 8, textBlack);
                }

                // Right Column: Pricing details
                // Pricing Header
                fillRect(cs, 335, 628, 240, 16, darkBlue);
                drawTextAligned(cs, "Q", 465, 632, bold, 8, Color.WHITE, "center", 30);
                drawTextAligned(cs, "Prix", 495, 632, bold, 8, Color.WHITE, "center", 40);
                drawTextAligned(cs, "Prix Total", 535, 632, bold, 8, Color.WHITE, "center", 40);

                // Vertical lines in price table
                drawVerticalLine(cs, 465, 410, 628, 0.5f, borderGrey);
                drawVerticalLine(cs, 495, 410, 628, 0.5f, borderGrey);
                drawVerticalLine(cs, 535, 410, 628, 0.5f, borderGrey);

                float priceRowH = 24.2f;
                for (int i = 1; i <= 8; i++) {
                    // Highlight backgrounds for TOTAL rows
                    if (i == 6 || i == 8) {
                        fillRect(cs, 335, 628 - i * priceRowH, 240, priceRowH, lightBlue);
                    }
                    drawHorizontalLine(cs, 335, 575, 628 - i * priceRowH, 0.5f, borderGrey);
                }

                // Pricing Row Labels
                drawText(cs, "Heures", 340, 613, bold, 8, textBlack);
                drawText(cs, "Jours", 340, 589, bold, 8, textBlack);
                drawText(cs, "Semaines", 340, 565, bold, 8, textBlack);
                drawText(cs, "Mois", 340, 541, bold, 8, textBlack);
                drawText(cs, "Avec Assurance", 340, 517, bold, 8, textBlack);
                drawText(cs, "TOTAL", 340, 493, bold, 8, textBlack);
                drawText(cs, "Supplément", 340, 468, bold, 8, textBlack);
                drawText(cs, "TOTAL Général (Au Retour)", 340, 444, bold, 8, textBlack);

                // Pricing fields must be empty but print DH in Prix Total column
                for (int i = 1; i <= 8; i++) {
                    drawTextAligned(cs, "DH", 535, 628 - i * priceRowH + 6, bold, 8, textBlack, "right", 35);
                }


                // --- 5. ADDITIONAL DRIVER & PAYMENT (Y = 320 to 410) ---
                drawHorizontalLine(cs, 20, 575, 320, 1f, darkBlue);
                drawVerticalLine(cs, 335, 320, 410, 1f, darkBlue);

                // Left Column: Additional Driver
                fillRect(cs, 20, 394, 315, 16, lightBlue);
                drawText(cs, "Le Conducteur Supplémentaire", 25, 398, bold, 9, darkBlue);

                float addRowH = 18.5f;
                drawVerticalLine(cs, 130, 320, 394, 0.5f, borderGrey);
                for (int i = 1; i <= 3; i++) {
                    drawHorizontalLine(cs, 20, 335, 394 - i * addRowH, 0.5f, borderGrey);
                }

                // Labels
                drawText(cs, "Nom & Prénom", 25, 381, bold, 8, darkBlue);
                drawText(cs, "Permis de Conduire N°", 25, 362.5f, bold, 8, darkBlue);
                drawText(cs, "Délivré le", 25, 344, bold, 8, darkBlue);
                drawText(cs, "Passeport N°", 25, 325.5f, bold, 8, darkBlue);

                // Fill Values if additional driver exists
                if (contract.getAdditionalDriverName() != null && !contract.getAdditionalDriverName().trim().isEmpty()) {
                    drawText(cs, contract.getAdditionalDriverName(), 135, 381, regular, 8, textBlack);
                    drawText(cs, contract.getAdditionalDriverLicense(), 135, 362.5f, regular, 8, textBlack);
                    if (contract.getClient() != null) {
                        drawText(cs, formatDate(contract.getClient().getAdditionalDriverDrivingLicenseIssuedAt()), 135, 344, regular, 8, textBlack);
                    }
                    drawText(cs, contract.getAdditionalDriverPassport(), 135, 325.5f, regular, 8, textBlack);
                }

                // Right Column: Payment
                fillRect(cs, 335, 394, 240, 16, darkBlue);
                drawText(cs, "Paiement", 340, 398, bold, 9, Color.WHITE);

                float payRowH = 24.6f;
                for (int i = 1; i <= 2; i++) {
                    drawHorizontalLine(cs, 335, 575, 394 - i * payRowH, 0.5f, borderGrey);
                }

                // Labels
                drawText(cs, "Espèces :", 340, 380, bold, 8, textBlack);
                drawText(cs, "Chèque :", 340, 355, bold, 8, textBlack);
                drawText(cs, "Caution :", 340, 330, bold, 8, textBlack);

                // Values (with DH if non-null and greater than 0)
                if (contract.getPaymentCash() != null && contract.getPaymentCash().compareTo(BigDecimal.ZERO) > 0) {
                    drawText(cs, contract.getPaymentCash().toString() + " DH", 450, 380, regular, 8, textBlack);
                }
                if (contract.getPaymentCheck() != null && contract.getPaymentCheck().compareTo(BigDecimal.ZERO) > 0) {
                    drawText(cs, contract.getPaymentCheck().toString() + " DH", 450, 355, regular, 8, textBlack);
                }
                if (contract.getPaymentDeposit() != null && contract.getPaymentDeposit().compareTo(BigDecimal.ZERO) > 0) {
                    drawText(cs, contract.getPaymentDeposit().toString() + " DH", 450, 330, regular, 8, textBlack);
                }


                // --- 6. DEPART, DOMMAGES, RETOUR (Y = 130 to 320) ---
                drawVerticalLine(cs, 205, 130, 320, 1f, darkBlue);
                drawVerticalLine(cs, 390, 130, 320, 1f, darkBlue);

                // Column A: DEPART
                fillRect(cs, 20, 304, 185, 16, darkBlue);
                drawTextAligned(cs, "DEPART", 20, 308, bold, 9, Color.WHITE, "center", 185);

                drawText(cs, "Véhicule En parfait état", 25, 290, bold, 8, textBlack);
                drawText(cs, "(rayer la mention inutile)", 115, 290, italic, 7, Color.GRAY);

                // Draw Checkboxes [ ] Oui   [ ] Non
                drawRect(cs, 30, 274, 10, 10, 0.5f, textBlack);
                drawText(cs, "Oui", 45, 275, regular, 8, textBlack);

                drawRect(cs, 75, 274, 10, 10, 0.5f, textBlack);
                drawText(cs, "Non", 90, 275, regular, 8, textBlack);

                // Pre-check if value matches
                String depCondition = contract.getVehicleConditionDeparture();
                if (depCondition != null) {
                    if ("oui".equalsIgnoreCase(depCondition.trim()) || depCondition.toLowerCase().contains("parfait")) {
                        drawText(cs, "X", 32, 275, bold, 8, textBlack);
                    } else if ("non".equalsIgnoreCase(depCondition.trim()) || depCondition.toLowerCase().contains("mauvais")) {
                        drawText(cs, "X", 77, 275, bold, 8, textBlack);
                    }
                }

                drawText(cs, "Commentaires :", 25, 258, bold, 8, textBlack);
                // Draw 5 comment lines
                float lineY = 242;
                for (int i = 0; i < 5; i++) {
                    drawHorizontalLine(cs, 25, 200, lineY - i * 18, 0.5f, borderGrey);
                    drawText(cs, (i + 1) + ".", 25, lineY - i * 18 + 2, regular, 8, Color.GRAY);
                }
                // Pre-fill comments if they are not just "Oui" or "Non"
                if (depCondition != null && !depCondition.equalsIgnoreCase("Oui") && !depCondition.equalsIgnoreCase("Non")) {
                    drawText(cs, truncateText(depCondition, 30), 40, lineY + 2, regular, 8, textBlack);
                }


                // Column B: DOMMAGES IDENTIFIES ET ACCEPTES
                fillRect(cs, 205, 304, 185, 16, darkBlue);
                drawTextAligned(cs, "DOMMAGES IDENTIFIES ET ACCEPTES", 205, 308, bold, 8, Color.WHITE, "center", 185);

                drawText(cs, "// Eraflure", 215, 290, bold, 8, textBlack);
                drawText(cs, "X Bosse", 280, 290, bold, 8, textBlack);
                drawRect(cs, 335, 288, 10, 10, 0.5f, textBlack);
                drawText(cs, "Manque", 350, 289, bold, 8, textBlack);

                // Check damages from data to cross the checkbox
                String damages = contract.getDamagesIdentified();
                if (damages != null && damages.toLowerCase().contains("manque")) {
                    drawText(cs, "X", 337, 289, bold, 8, textBlack);
                }

                // Table Nombre / Paraphe client
                fillRect(cs, 205, 256, 185, 16, lightBlue);
                drawHorizontalLine(cs, 205, 390, 256, 0.5f, borderGrey);
                drawHorizontalLine(cs, 205, 390, 272, 0.5f, borderGrey);
                drawVerticalLine(cs, 297.5f, 130, 272, 0.5f, borderGrey);

                drawTextAligned(cs, "Nombre", 205, 260, bold, 8, darkBlue, "center", 92.5f);
                drawTextAligned(cs, "Paraphe client", 297.5f, 260, bold, 8, darkBlue, "center", 92.5f);

                // Draw 5 blank table rows
                float damRowH = 22f;
                for (int i = 1; i <= 5; i++) {
                    drawHorizontalLine(cs, 205, 390, 272 - 16 - i * damRowH, 0.5f, borderGrey);
                }
                // Pre-fill damages if they exist
                if (damages != null && !damages.trim().isEmpty()) {
                    drawText(cs, truncateText(damages, 16), 210, 240, regular, 8, textBlack);
                }


                // Column C: RETOUR
                fillRect(cs, 390, 304, 185, 16, darkBlue);
                drawTextAligned(cs, "RETOUR", 390, 308, bold, 9, Color.WHITE, "center", 185);

                drawText(cs, "Véhicule En parfait état", 395, 290, bold, 8, textBlack);
                drawText(cs, "(rayer la mention inutile)", 485, 290, italic, 7, Color.GRAY);

                // Checkboxes
                drawRect(cs, 400, 274, 10, 10, 0.5f, textBlack);
                drawText(cs, "Oui", 415, 275, regular, 8, textBlack);

                drawRect(cs, 445, 274, 10, 10, 0.5f, textBlack);
                drawText(cs, "Non", 460, 275, regular, 8, textBlack);

                String retCondition = contract.getVehicleConditionReturn();
                if (retCondition != null) {
                    if ("oui".equalsIgnoreCase(retCondition.trim()) || retCondition.toLowerCase().contains("parfait")) {
                        drawText(cs, "X", 402, 275, bold, 8, textBlack);
                    } else if ("non".equalsIgnoreCase(retCondition.trim()) || retCondition.toLowerCase().contains("mauvais")) {
                        drawText(cs, "X", 447, 275, bold, 8, textBlack);
                    }
                }

                drawText(cs, "Commentaires :", 395, 258, bold, 8, textBlack);
                for (int i = 0; i < 5; i++) {
                    drawHorizontalLine(cs, 395, 570, lineY - i * 18, 0.5f, borderGrey);
                    drawText(cs, (i + 1) + ".", 395, lineY - i * 18 + 2, regular, 8, Color.GRAY);
                }
                if (retCondition != null && !retCondition.equalsIgnoreCase("Oui") && !retCondition.equalsIgnoreCase("Non")) {
                    drawText(cs, truncateText(retCondition, 30), 410, lineY + 2, regular, 8, textBlack);
                }


                // --- 7. FOOTER / SIGNATURES (Y = 20 to 130) ---
                drawText(cs, "Observation : En cas d'accident ou de vol, je m'engage à régler la valeur totale de la voiture.", 25, 115, italic, 8, textBlack);
                drawText(cs, "SIGNATURE CLIENT", 25, 95, bold, 9, darkBlue);
                // Underline SIGNATURE CLIENT
                drawHorizontalLine(cs, 25, 120, 92, 1f, darkBlue);

                String dateString = LocalDate.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
                drawText(cs, "Fait à Tanger, le " + dateString, 300, 95, regular, 9, textBlack);
            }

            doc.save(out);
            return out.toByteArray();
        }
    }

    private void drawHeaderTextFallback(PDPageContentStream cs, PDFont bold, PDFont regular, Color darkBlue) throws IOException {
        cs.beginText();
        cs.setFont(bold, 14);
        cs.setNonStrokingColor(darkBlue);
        cs.newLineAtOffset(25, 796);
        cs.showText("BOUSSELHA");
        cs.newLineAtOffset(18, -14);
        cs.showText("CARS");
        cs.endText();

        cs.beginText();
        cs.setFont(regular, 7);
        cs.setNonStrokingColor(darkBlue);
        cs.newLineAtOffset(35, 770);
        cs.showText("Location de Voitures");
        cs.newLineAtOffset(12, -8);
        cs.showText("Tanger - Maroc");
        cs.endText();
    }

    private void drawText(PDPageContentStream cs, String text, float x, float y, PDFont font, float fontSize, Color color) throws IOException {
        if (text == null) return;
        String sanitized = sanitize(text);
        cs.beginText();
        cs.setFont(font, fontSize);
        cs.setNonStrokingColor(color);
        cs.newLineAtOffset(x, y);
        try {
            cs.showText(sanitized);
        } catch (IllegalArgumentException e) {
            cs.showText(cleanToAscii(text));
        }
        cs.endText();
    }

    private void drawTextAligned(PDPageContentStream cs, String text, float x, float y, PDFont font, float fontSize, Color color, String alignment, float width) throws IOException {
        if (text == null || text.trim().isEmpty()) return;
        float textWidth = getStringWidth(text, font, fontSize);
        float targetX = x;
        if ("center".equalsIgnoreCase(alignment)) {
            targetX = x + (width - textWidth) / 2;
        } else if ("right".equalsIgnoreCase(alignment)) {
            targetX = x + width - textWidth;
        }
        drawText(cs, text, targetX, y, font, fontSize, color);
    }

    private float getStringWidth(String text, PDFont font, float fontSize) throws IOException {
        if (text == null || text.isEmpty()) return 0;
        try {
            return font.getStringWidth(sanitize(text)) / 1000 * fontSize;
        } catch (IllegalArgumentException e) {
            String clean = cleanToAscii(text);
            try {
                return font.getStringWidth(clean) / 1000 * fontSize;
            } catch (Exception ex) {
                return 0;
            }
        }
    }

    private String sanitize(String text) {
        if (text == null) return "";
        StringBuilder sb = new StringBuilder();
        for (char c : text.toCharArray()) {
            if (c >= 32 && c <= 126) {
                sb.append(c);
            } else if (c == '\n' || c == '\r' || c == '\t') {
                sb.append(' ');
            } else {
                if (c >= 160 && c <= 255 || c == 'œ' || c == 'Œ' || c == '€') {
                    sb.append(c);
                } else {
                    sb.append('?');
                }
            }
        }
        return sb.toString();
    }

    private String cleanToAscii(String text) {
        if (text == null) return "";
        String n = text;
        n = n.replace("é", "e").replace("è", "e").replace("à", "a").replace("ç", "c")
             .replace("ù", "u").replace("â", "a").replace("ê", "e").replace("î", "i")
             .replace("ô", "o").replace("û", "u").replace("ë", "e").replace("ï", "i")
             .replace("ü", "u").replace("œ", "oe").replace("É", "E").replace("È", "E")
             .replace("À", "A").replace("Ç", "C").replace("Ù", "U").replace("Â", "A")
             .replace("Ê", "E").replace("Î", "I").replace("Ô", "O").replace("Û", "U")
             .replace("°", "o");
        StringBuilder sb = new StringBuilder();
        for (char c : n.toCharArray()) {
            if (c >= 32 && c <= 126) {
                sb.append(c);
            } else {
                sb.append(" ");
            }
        }
        return sb.toString();
    }

    private String formatDate(LocalDate date) {
        if (date == null) return "";
        return date.format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
    }

    private String truncateText(String text, int maxChars) {
        if (text == null) return "";
        if (text.length() <= maxChars) return text;
        return text.substring(0, maxChars - 3) + "...";
    }

    private void drawHorizontalLine(PDPageContentStream cs, float xStart, float xEnd, float y, float width, Color color) throws IOException {
        cs.setStrokingColor(color);
        cs.setLineWidth(width);
        cs.moveTo(xStart, y);
        cs.lineTo(xEnd, y);
        cs.stroke();
    }

    private void drawVerticalLine(PDPageContentStream cs, float x, float yStart, float yEnd, float width, Color color) throws IOException {
        cs.setStrokingColor(color);
        cs.setLineWidth(width);
        cs.moveTo(x, yStart);
        cs.lineTo(x, yEnd);
        cs.stroke();
    }

    private void drawRect(PDPageContentStream cs, float x, float y, float w, float h, float lineWidth, Color color) throws IOException {
        cs.setStrokingColor(color);
        cs.setLineWidth(lineWidth);
        cs.addRect(x, y, w, h);
        cs.stroke();
    }

    private void fillRect(PDPageContentStream cs, float x, float y, float w, float h, Color color) throws IOException {
        cs.setNonStrokingColor(color);
        cs.addRect(x, y, w, h);
        cs.fill();
    }
}
