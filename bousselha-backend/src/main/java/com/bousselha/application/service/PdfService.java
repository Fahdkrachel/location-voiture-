package com.bousselha.application.service;

import com.bousselha.domain.enums.ContractStatus;
import com.bousselha.domain.model.CompanySettings;
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
import java.util.List;
import java.util.ArrayList;

@Service
public class PdfService {
    private final ContractRepository contractRepository;
    private final SettingsService settingsService;

    public PdfService(ContractRepository contractRepository, SettingsService settingsService) {
        this.contractRepository = contractRepository;
        this.settingsService = settingsService;
    }

    public byte[] generateContractPdf(Long id) throws IOException {
        Contract contract = contractRepository.findDetailedById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Contract not found: " + id));

        if (contract.getStatus() != ContractStatus.ACTIVE && contract.getStatus() != ContractStatus.COMPLETED) {
            throw new IllegalArgumentException(
                    "Le PDF est disponible uniquement après activation du contrat (statut ACTIVE ou termine)");
        }

        // Charger les paramètres société dynamiques
        CompanySettings settings = settingsService.getRawSettings();

        try (PDDocument doc = new PDDocument(); ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            PDPage page = new PDPage(PDRectangle.A4);
            doc.addPage(page);

            PDFont bold;
            PDFont regular;
            PDFont italic;

            try {
                java.io.InputStream regularStream = getClass().getResourceAsStream("/static/fonts/Cairo-Regular.ttf");
                if (regularStream == null) {
                    java.io.File f = new java.io.File("src/main/resources/static/fonts/Cairo-Regular.ttf");
                    if (f.exists()) {
                        regular = org.apache.pdfbox.pdmodel.font.PDType0Font.load(doc, f);
                    } else {
                        f = new java.io.File("bousselha-backend/src/main/resources/static/fonts/Cairo-Regular.ttf");
                        if (f.exists()) {
                            regular = org.apache.pdfbox.pdmodel.font.PDType0Font.load(doc, f);
                        } else {
                            regular = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
                        }
                    }
                } else {
                    regular = org.apache.pdfbox.pdmodel.font.PDType0Font.load(doc, regularStream);
                }

                java.io.InputStream boldStream = getClass().getResourceAsStream("/static/fonts/Cairo-Bold.ttf");
                if (boldStream == null) {
                    java.io.File f = new java.io.File("src/main/resources/static/fonts/Cairo-Bold.ttf");
                    if (f.exists()) {
                        bold = org.apache.pdfbox.pdmodel.font.PDType0Font.load(doc, f);
                    } else {
                        f = new java.io.File("bousselha-backend/src/main/resources/static/fonts/Cairo-Bold.ttf");
                        if (f.exists()) {
                            bold = org.apache.pdfbox.pdmodel.font.PDType0Font.load(doc, f);
                        } else {
                            bold = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
                        }
                    }
                } else {
                    bold = org.apache.pdfbox.pdmodel.font.PDType0Font.load(doc, boldStream);
                }
                
                italic = regular;
            } catch (Exception e) {
                regular = new PDType1Font(Standard14Fonts.FontName.HELVETICA);
                bold = new PDType1Font(Standard14Fonts.FontName.HELVETICA_BOLD);
                italic = new PDType1Font(Standard14Fonts.FontName.HELVETICA_OBLIQUE);
            }

            Color textBlack = Color.BLACK;

            try (PDPageContentStream cs = new PDPageContentStream(doc, page)) {
                // --- PAGE 1: CONTRAT DE LOCATION ---

                // 1. EN-TETE
                // Logo centré
                File logoFile = null;
                if (settings.getLogoPath() != null && !settings.getLogoPath().isBlank()) {
                    logoFile = new File(settings.getLogoPath());
                    if (!logoFile.exists()) {
                        logoFile = new File("bousselha-backend/" + settings.getLogoPath());
                    }
                }
                if (logoFile == null || !logoFile.exists()) {
                    File staticLogo = new File("src/main/resources/static/images/logo.png");
                    if (!staticLogo.exists()) {
                        staticLogo = new File("bousselha-backend/src/main/resources/static/images/logo.png");
                    }
                    if (staticLogo.exists()) logoFile = staticLogo;
                }

                if (logoFile != null && logoFile.exists() && logoFile.isFile()) {
                    try {
                        PDImageXObject pdImage = PDImageXObject.createFromFileByExtension(logoFile, doc);
                        cs.drawImage(pdImage, 237.5f, 755, 120, 45);
                    } catch (Exception e) {
                        drawTextAligned(cs, settings.getCompanyName() != null ? settings.getCompanyName() : "BOUSSELHA CARS", 20, 775, bold, 13, Color.BLACK, "center", 555);
                    }
                } else {
                    drawTextAligned(cs, settings.getCompanyName() != null ? settings.getCompanyName() : "BOUSSELHA CARS", 20, 775, bold, 13, Color.BLACK, "center", 555);
                }

                // Left header text
                drawText(cs, "LOCATION DE VOITURE", 20, 790, bold, 12, Color.BLACK);
                drawText(cs, "GSM: " + safe(settings.getGsm()), 20, 775, regular, 9, Color.BLACK);

                // Right header text
                float rX = 390f;
                float curY = 810f;
                drawText(cs, safe(settings.getCompanyName()), rX, curY, bold, 9, Color.BLACK);
                curY -= 11;
                drawText(cs, truncateText(safe(settings.getAddress()), 35), rX, curY, regular, 7, Color.BLACK);
                curY -= 11;
                drawText(cs, buildTelFax(settings), rX, curY, regular, 7, Color.BLACK);
                curY -= 11;
                drawText(cs, "GSM: " + safe(settings.getGsm()), rX, curY, regular, 7, Color.BLACK);
                curY -= 11;
                drawText(cs, "Email: " + safe(settings.getEmail()), rX, curY, regular, 7, Color.BLACK);

                // Title centered
                drawTextAligned(cs, "Contrat de Location N° : " + contract.getId(), 20, 725, bold, 12, Color.BLACK, "center", 555);
                drawHorizontalLine(cs, 20, 575, 718, 0.5f, Color.LIGHT_GRAY);

                // Columns
                // Left Column: X = 20 to 292.5 (width = 272.5)
                // Right Column: X = 302.5 to 575 (width = 272.5)

                // 2. SECTION VEHICULE (cadre)
                drawRect(cs, 20, 620, 272.5f, 85, 0.75f, Color.BLACK);
                fillRect(cs, 20, 690, 272.5f, 15, new Color(240, 240, 240));
                drawHorizontalLine(cs, 20, 292.5f, 690, 0.5f, Color.BLACK);
                drawTextAligned(cs, "VEHICULE", 20, 694, bold, 8, Color.BLACK, "center", 272.5f);

                drawVerticalLine(cs, 135, 620, 690, 0.5f, Color.BLACK);
                for (int i = 1; i <= 4; i++) {
                    drawHorizontalLine(cs, 20, 292.5f, 690 - i * 14, 0.5f, Color.BLACK);
                }

                drawText(cs, "Marque", 25, 679, bold, 7.5f, Color.BLACK);
                drawText(cs, "Immatriculation", 25, 665, bold, 7.5f, Color.BLACK);
                drawText(cs, "Carburant", 25, 651, bold, 7.5f, Color.BLACK);
                drawText(cs, "Lieu de départ", 25, 637, bold, 7.5f, Color.BLACK);
                drawText(cs, "Lieu de retour", 25, 623, bold, 7.5f, Color.BLACK);

                drawText(cs, contract.getCar() != null ? contract.getCar().getBrand() : "", 140, 679, regular, 7.5f, Color.BLACK);
                drawText(cs, contract.getCar() != null ? contract.getCar().getMatricule() : "", 140, 665, regular, 7.5f, Color.BLACK);
                drawText(cs, "Diesel", 140, 651, regular, 7.5f, Color.BLACK);
                drawText(cs, contract.getDeparturePlace(), 140, 637, regular, 7.5f, Color.BLACK);
                drawText(cs, contract.getReturnPlace(), 140, 623, regular, 7.5f, Color.BLACK);

                // 3. SECTION LOCATAIRE (cadre) - Ajout Passeport N° et Profession, affichage adresse complet
                drawRect(cs, 20, 455, 272.5f, 155, 0.75f, Color.BLACK);
                fillRect(cs, 20, 596, 272.5f, 14, new Color(240, 240, 240));
                drawHorizontalLine(cs, 20, 292.5f, 596, 0.5f, Color.BLACK);
                drawTextAligned(cs, "LOCATAIRE", 20, 600, bold, 8, Color.BLACK, "center", 272.5f);

                drawVerticalLine(cs, 135, 455, 596, 0.5f, Color.BLACK);
                for (int i = 1; i <= 9; i++) {
                    drawHorizontalLine(cs, 20, 292.5f, 596 - i * 14, 0.5f, Color.BLACK);
                }

                drawText(cs, "Nom et Prénom", 25, 585, bold, 7.5f, Color.BLACK);
                drawText(cs, "Date de naissance", 25, 571, bold, 7.5f, Color.BLACK);
                drawText(cs, "N° CIN", 25, 557, bold, 7.5f, Color.BLACK);
                drawText(cs, "Nationalité", 25, 543, bold, 7.5f, Color.BLACK);
                drawText(cs, "Permis de conduire N°", 25, 529, bold, 7.5f, Color.BLACK);
                drawText(cs, "Délivré le", 25, 515, bold, 7.5f, Color.BLACK);
                drawText(cs, "Téléphone", 25, 501, bold, 7.5f, Color.BLACK);
                drawText(cs, "Adresse", 25, 487, bold, 7.5f, Color.BLACK);
                drawText(cs, "Passeport N°", 25, 473, bold, 7.5f, Color.BLACK);
                drawText(cs, "Profession", 25, 459, bold, 7.5f, Color.BLACK);

                drawText(cs, contract.getClient() != null ? contract.getClient().getFullName() : "", 140, 585, regular, 7.5f, Color.BLACK);
                drawText(cs, contract.getClient() != null ? formatDate(contract.getClient().getBirthDate()) : "", 140, 571, regular, 7.5f, Color.BLACK);
                drawText(cs, contract.getClient() != null ? contract.getClient().getCinNumber() : "", 140, 557, regular, 7.5f, Color.BLACK);
                drawText(cs, "", 140, 543, regular, 7.5f, Color.BLACK); // Nationalité (vide)
                drawText(cs, contract.getClient() != null ? contract.getClient().getDrivingLicenseNumber() : "", 140, 529, regular, 7.5f, Color.BLACK);
                drawText(cs, contract.getClient() != null ? contract.getClient().getDrivingLicenseIssuedAt() : "", 140, 515, regular, 7.5f, Color.BLACK);
                drawText(cs, contract.getClient() != null ? contract.getClient().getPhone() : "", 140, 501, regular, 7.5f, Color.BLACK);
                // Adresse complète (pas de truncate)
                drawText(cs, contract.getClient() != null ? safe(contract.getClient().getAddressMorocco()) : "", 140, 487, regular, 7f, Color.BLACK);
                drawText(cs, contract.getClient() != null ? safe(contract.getClient().getPassportNumber()) : "", 140, 473, regular, 7.5f, Color.BLACK);
                drawText(cs, contract.getClient() != null ? safe(contract.getClient().getProfession()) : "", 140, 459, regular, 7.5f, Color.BLACK);

                // 4. SECTION CONDUCTEUR SUPPLEMENTAIRE (cadre) - Ajout Passeport N°
                drawRect(cs, 20, 374, 272.5f, 71, 0.75f, Color.BLACK);
                fillRect(cs, 20, 430, 272.5f, 15, new Color(240, 240, 240));
                drawHorizontalLine(cs, 20, 292.5f, 430, 0.5f, Color.BLACK);
                drawTextAligned(cs, "CONDUCTEUR SUPPLEMENTAIRE", 20, 434, bold, 8, Color.BLACK, "center", 272.5f);

                drawVerticalLine(cs, 135, 374, 430, 0.5f, Color.BLACK);
                for (int i = 1; i <= 3; i++) {
                    drawHorizontalLine(cs, 20, 292.5f, 430 - i * 14, 0.5f, Color.BLACK);
                }

                drawText(cs, "Nom et Prénom", 25, 419, bold, 7.5f, Color.BLACK);
                drawText(cs, "N° CIN", 25, 405, bold, 7.5f, Color.BLACK);
                drawText(cs, "Permis de conduire N°", 25, 391, bold, 7.5f, Color.BLACK);
                drawText(cs, "Passeport N°", 25, 377, bold, 7.5f, Color.BLACK);

                drawText(cs, contract.getAdditionalDriverName(), 140, 419, regular, 7.5f, Color.BLACK);
                drawText(cs, "", 140, 405, regular, 7.5f, Color.BLACK); // CIN vide
                drawText(cs, contract.getAdditionalDriverLicense(), 140, 391, regular, 7.5f, Color.BLACK);
                drawText(cs, contract.getAdditionalDriverPassport() != null ? contract.getAdditionalDriverPassport() : "", 140, 377, regular, 7.5f, Color.BLACK);

                // 5. TABLEAU DATES (4 colonnes)
                drawRect(cs, 302.5f, 642, 272.5f, 63, 0.75f, Color.BLACK);
                fillRect(cs, 302.5f, 690, 272.5f, 15, new Color(240, 240, 240));
                drawHorizontalLine(cs, 302.5f, 575, 690, 0.5f, Color.BLACK);

                drawVerticalLine(cs, 412.5f, 642, 705, 0.5f, Color.BLACK);
                drawVerticalLine(cs, 447.5f, 642, 705, 0.5f, Color.BLACK);
                drawVerticalLine(cs, 482.5f, 642, 705, 0.5f, Color.BLACK);
                drawVerticalLine(cs, 532.5f, 642, 705, 0.5f, Color.BLACK);

                drawTextAligned(cs, "JJ", 412.5f, 694, bold, 7.5f, Color.BLACK, "center", 35);
                drawTextAligned(cs, "MM", 447.5f, 694, bold, 7.5f, Color.BLACK, "center", 35);
                drawTextAligned(cs, "AAAA", 482.5f, 694, bold, 7.5f, Color.BLACK, "center", 50);
                drawTextAligned(cs, "H:m", 532.5f, 694, bold, 7.5f, Color.BLACK, "center", 42.5f);

                drawHorizontalLine(cs, 302.5f, 575, 674, 0.5f, Color.BLACK);
                drawHorizontalLine(cs, 302.5f, 575, 658, 0.5f, Color.BLACK);

                drawText(cs, "DEPART", 307.5f, 677, bold, 7.5f, Color.BLACK);
                drawText(cs, "RETOUR PREVU", 307.5f, 661, bold, 7.5f, Color.BLACK);
                drawText(cs, "RETOUR DEFINITIF", 307.5f, 645, bold, 7.5f, Color.BLACK);

                LocalDateTime dep = contract.getDepartureDatetime();
                if (dep != null) {
                    drawTextAligned(cs, String.format("%02d", dep.getDayOfMonth()), 412.5f, 677, regular, 7.5f, Color.BLACK, "center", 35);
                    drawTextAligned(cs, String.format("%02d", dep.getMonthValue()), 447.5f, 677, regular, 7.5f, Color.BLACK, "center", 35);
                    drawTextAligned(cs, String.valueOf(dep.getYear()), 482.5f, 677, regular, 7.5f, Color.BLACK, "center", 50);
                    drawTextAligned(cs, String.format("%02d:%02d", dep.getHour(), dep.getMinute()), 532.5f, 677, regular, 7.5f, Color.BLACK, "center", 42.5f);
                }
                LocalDateTime exp = contract.getExpectedReturnDatetime();
                if (exp != null) {
                    drawTextAligned(cs, String.format("%02d", exp.getDayOfMonth()), 412.5f, 661, regular, 7.5f, Color.BLACK, "center", 35);
                    drawTextAligned(cs, String.format("%02d", exp.getMonthValue()), 447.5f, 661, regular, 7.5f, Color.BLACK, "center", 35);
                    drawTextAligned(cs, String.valueOf(exp.getYear()), 482.5f, 661, regular, 7.5f, Color.BLACK, "center", 50);
                    drawTextAligned(cs, String.format("%02d:%02d", exp.getHour(), exp.getMinute()), 532.5f, 661, regular, 7.5f, Color.BLACK, "center", 42.5f);
                }
                LocalDateTime act = contract.getActualReturnDatetime();
                if (act != null) {
                    drawTextAligned(cs, String.format("%02d", act.getDayOfMonth()), 412.5f, 645, regular, 7.5f, Color.BLACK, "center", 35);
                    drawTextAligned(cs, String.format("%02d", act.getMonthValue()), 447.5f, 645, regular, 7.5f, Color.BLACK, "center", 35);
                    drawTextAligned(cs, String.valueOf(act.getYear()), 482.5f, 645, regular, 7.5f, Color.BLACK, "center", 50);
                    drawTextAligned(cs, String.format("%02d:%02d", act.getHour(), act.getMinute()), 532.5f, 645, regular, 7.5f, Color.BLACK, "center", 42.5f);
                } else {
                    drawTextAligned(cs, "______", 412.5f, 645, regular, 7.5f, Color.BLACK, "center", 35);
                    drawTextAligned(cs, "______", 447.5f, 645, regular, 7.5f, Color.BLACK, "center", 35);
                    drawTextAligned(cs, "________", 482.5f, 645, regular, 7.5f, Color.BLACK, "center", 50);
                    drawTextAligned(cs, "______", 532.5f, 645, regular, 7.5f, Color.BLACK, "center", 42.5f);
                }

                // 6. GRILLE TARIFAIRE - Suppression "Avec Assurance" et tous les champs de calculs sont vides
                drawRect(cs, 302.5f, 519, 272.5f, 113, 0.75f, Color.BLACK);
                fillRect(cs, 302.5f, 604, 272.5f, 15, new Color(240, 240, 240));
                drawHorizontalLine(cs, 302.5f, 575, 604, 0.5f, Color.BLACK);

                drawVerticalLine(cs, 412.5f, 519, 619, 0.5f, Color.BLACK);
                drawVerticalLine(cs, 452.5f, 519, 619, 0.5f, Color.BLACK);
                drawVerticalLine(cs, 512.5f, 519, 619, 0.5f, Color.BLACK);

                drawTextAligned(cs, "Q", 412.5f, 608, bold, 7.5f, Color.BLACK, "center", 40);
                drawTextAligned(cs, "Prix", 452.5f, 608, bold, 7.5f, Color.BLACK, "center", 60);
                drawTextAligned(cs, "Total", 512.5f, 608, bold, 7.5f, Color.BLACK, "center", 62.5f);

                for (int i = 1; i <= 5; i++) {
                    drawHorizontalLine(cs, 302.5f, 575, 604 - i * 14, 0.5f, Color.BLACK);
                }

                drawText(cs, "Heures", 307.5f, 591, bold, 7.5f, Color.BLACK);
                drawText(cs, "Jours", 307.5f, 577, bold, 7.5f, Color.BLACK);
                drawText(cs, "Semaines", 307.5f, 563, bold, 7.5f, Color.BLACK);
                drawText(cs, "Mois", 307.5f, 549, bold, 7.5f, Color.BLACK);
                drawText(cs, "TOTAL", 307.5f, 535, bold, 7.5f, Color.BLACK);
                drawText(cs, "Supplément", 307.5f, 521, bold, 7.5f, Color.BLACK);
                drawText(cs, "TOTAL Général", 307.5f, 507, bold, 7.5f, Color.BLACK);

                // Note: Q, Prix, et Total restent vides comme demandé.

                // Note: 7. PAIEMENT et 8. FRANCHISE ET ASSURANCE ont été supprimés complètement.

                // 9. ETAT VEHICULE DEPART ET RETOUR & 10. ZONE SCHEMAS VOITURE
                boolean depOui = false;
                boolean depNon = false;
                String depCond = contract.getVehicleConditionDeparture();
                if (depCond != null) {
                    String lower = depCond.toLowerCase();
                    if (lower.contains("parfait") || lower.contains("oui")) {
                        depOui = true;
                    } else if (lower.contains("mauvais") || lower.contains("non")) {
                        depNon = true;
                    }
                }

                boolean retOui = false;
                boolean retNon = false;
                String retCond = contract.getVehicleConditionReturn();
                if (retCond != null) {
                    String lower = retCond.toLowerCase();
                    if (lower.contains("parfait") || lower.contains("oui")) {
                        retOui = true;
                    } else if (lower.contains("mauvais") || lower.contains("non")) {
                        retNon = true;
                    }
                }

                // Col 1 (Schema Départ) - Support d'image
                drawRect(cs, 20, 250, 120, 120, 0.75f, Color.BLACK);
                drawTextAligned(cs, "Départ", 20, 355, bold, 8, Color.BLACK, "center", 120);

                File imgDepartFile = new File("src/main/resources/static/images/schema_depart.png");
                if (!imgDepartFile.exists()) {
                    imgDepartFile = new File("bousselha-backend/src/main/resources/static/images/schema_depart.png");
                }
                if (imgDepartFile.exists() && imgDepartFile.isFile()) {
                    try {
                        PDImageXObject pdImage = PDImageXObject.createFromFileByExtension(imgDepartFile, doc);
                        cs.drawImage(pdImage, 25, 255, 110, 110);
                    } catch (Exception e) {
                        // ignore
                    }
                } else {
                    try {
                        java.io.InputStream is = getClass().getResourceAsStream("/static/images/schema_depart.png");
                        if (is != null) {
                            byte[] bytes = is.readAllBytes();
                            PDImageXObject pdImage = PDImageXObject.createFromByteArray(doc, bytes, "schema_depart.png");
                            cs.drawImage(pdImage, 25, 255, 110, 110);
                        }
                    } catch (Exception e) {
                        // ignore
                    }
                }

                // Col 2 (Etat Départ checklist)
                drawRect(cs, 150, 250, 142.5f, 120, 0.75f, Color.BLACK);
                fillRect(cs, 150, 355, 142.5f, 15, Color.BLACK);
                drawTextAligned(cs, "Départ", 150, 359, bold, 8, Color.WHITE, "center", 142.5f);
                drawTextAligned(cs, "Véhicule En parfait état", 150, 344, bold, 7, Color.BLACK, "center", 142.5f);
                
                drawRect(cs, 165, 328, 25, 11, 0.5f, Color.BLACK);
                drawTextAligned(cs, "OUI", 165, 330, bold, 6.5f, Color.BLACK, "center", 25);
                if (depOui) drawTextAligned(cs, "X", 165, 330, bold, 6.5f, Color.BLACK, "center", 25);

                drawRect(cs, 205, 328, 25, 11, 0.5f, Color.BLACK);
                drawTextAligned(cs, "NON", 205, 330, bold, 6.5f, Color.BLACK, "center", 25);
                if (depNon) drawTextAligned(cs, "X", 205, 330, bold, 6.5f, Color.BLACK, "center", 25);

                for (int i = 1; i <= 5; i++) {
                    drawHorizontalLine(cs, 150, 292.5f, 325 - i * 12.5f, 0.5f, Color.LIGHT_GRAY);
                }
                drawText(cs, "1. CARTE GRISE", 155, 314, regular, 6.5f, Color.BLACK);
                drawText(cs, "2. VIGNETTE", 155, 301.5f, regular, 6.5f, Color.BLACK);
                drawText(cs, "3. ASSURANCE", 155, 289, regular, 6.5f, Color.BLACK);
                drawText(cs, "4. VISITE TECHNIQUE", 155, 276.5f, regular, 6.5f, Color.BLACK);
                drawText(cs, "5. AUTORISATION", 155, 264, regular, 6.5f, Color.BLACK);
                drawText(cs, "6. CARTE VERTE", 155, 251.5f, regular, 6.5f, Color.BLACK);

                // Col 3 (Etat Retour checklist)
                drawRect(cs, 302.5f, 250, 142.5f, 120, 0.75f, Color.BLACK);
                fillRect(cs, 302.5f, 355, 142.5f, 15, Color.BLACK);
                drawTextAligned(cs, "Retour", 302.5f, 359, bold, 8, Color.WHITE, "center", 142.5f);
                drawTextAligned(cs, "Véhicule En parfait état", 302.5f, 344, bold, 7, Color.BLACK, "center", 142.5f);

                drawRect(cs, 317.5f, 328, 25, 11, 0.5f, Color.BLACK);
                drawTextAligned(cs, "OUI", 317.5f, 330, bold, 6.5f, Color.BLACK, "center", 25);
                if (retOui) drawTextAligned(cs, "X", 317.5f, 330, bold, 6.5f, Color.BLACK, "center", 25);

                drawRect(cs, 357.5f, 328, 25, 11, 0.5f, Color.BLACK);
                drawTextAligned(cs, "NON", 357.5f, 330, bold, 6.5f, Color.BLACK, "center", 25);
                if (retNon) drawTextAligned(cs, "X", 357.5f, 330, bold, 6.5f, Color.BLACK, "center", 25);

                for (int i = 1; i <= 5; i++) {
                    drawHorizontalLine(cs, 302.5f, 445, 325 - i * 12.5f, 0.5f, Color.LIGHT_GRAY);
                }
                drawText(cs, "1. CARTE GRISE", 307.5f, 314, regular, 6.5f, Color.BLACK);
                drawText(cs, "2. VIGNETTE", 307.5f, 301.5f, regular, 6.5f, Color.BLACK);
                drawText(cs, "3. ASSURANCE", 307.5f, 289, regular, 6.5f, Color.BLACK);
                drawText(cs, "4. VISITE TECHNIQUE", 307.5f, 276.5f, regular, 6.5f, Color.BLACK);
                drawText(cs, "5. AUTORISATION", 307.5f, 264, regular, 6.5f, Color.BLACK);
                drawText(cs, "6. CARTE VERTE", 307.5f, 251.5f, regular, 6.5f, Color.BLACK);

                // Col 4 (Schema Retour) - Support d'image
                drawRect(cs, 455, 250, 120, 120, 0.75f, Color.BLACK);
                drawTextAligned(cs, "Retour", 455, 355, bold, 8, Color.BLACK, "center", 120);

                File imgRetourFile = new File("src/main/resources/static/images/schema_retour.png");
                if (!imgRetourFile.exists()) {
                    imgRetourFile = new File("bousselha-backend/src/main/resources/static/images/schema_retour.png");
                }
                if (imgRetourFile.exists() && imgRetourFile.isFile()) {
                    try {
                        PDImageXObject pdImage = PDImageXObject.createFromFileByExtension(imgRetourFile, doc);
                        cs.drawImage(pdImage, 460, 255, 110, 110);
                    } catch (Exception e) {
                        // ignore
                    }
                } else {
                    try {
                        java.io.InputStream is = getClass().getResourceAsStream("/static/images/schema_retour.png");
                        if (is != null) {
                            byte[] bytes = is.readAllBytes();
                            PDImageXObject pdImage = PDImageXObject.createFromByteArray(doc, bytes, "schema_retour.png");
                            cs.drawImage(pdImage, 460, 255, 110, 110);
                        }
                    } catch (Exception e) {
                        // ignore
                    }
                }

                // Phrase Commentaires sous le tableau
                drawText(cs, "Commentaires: Positionner les numéros à l'endroit précis du dommage, sur la matrice à gauche.", 20, 236, bold, 7.2f, Color.BLACK);

                // 11. PIED DE PAGE
                String dateString = LocalDate.now().format(DateTimeFormatter.ofPattern("dd/MM/yyyy"));
                drawText(cs, "Fait à Tanger, le " + dateString, 25, 210, regular, 9, Color.BLACK);
                drawText(cs, "En cas d'accident contacter immédiatement l'agence : " + safe(settings.getGsm()), 25, 190, bold, 8.5f, new Color(200, 0, 0));
                
                drawText(cs, "VISEE PAR " + safe(settings.getCompanyName()).toUpperCase(), 25, 140, bold, 9, Color.BLACK);
                drawText(cs, "SIGNATURE CLIENT", 450, 140, bold, 9, Color.BLACK);

                // Phrase en bas de signature client
                drawTextAligned(cs, "Je reconnais avoir pris connaissance des Présentes conditions générales", 300, 95, italic, 7f, Color.BLACK, "center", 250);
                drawTextAligned(cs, "(recto verso) que je m'engage à respecter.", 300, 83, italic, 7f, Color.BLACK, "center", 250);
            }

            // --- PAGE 2: CONDITIONS GENERALES ---
            PDPage page2 = new PDPage(PDRectangle.A4);
            doc.addPage(page2);
            try (PDPageContentStream cs2 = new PDPageContentStream(doc, page2)) {
                // Background color (light green legal paper style)
                cs2.setNonStrokingColor(new Color(242, 249, 242));
                cs2.addRect(0, 0, 595, 842);
                cs2.fill();

                // Title centered
                drawTextAligned(cs2, "CONDITIONS GENERALES DE LOCATION", 20, 800, bold, 12, Color.BLACK, "center", 555);

                float leftColX = 20;
                float rightColX = 307.5f;
                float colWidth = 267.5f;
                float startY = 775;
                float lineSpacing = 8.5f;

                String leftText = "Art. 1 - UTILISATION DE LA VOITURE\n" +
                        "Le locataire s'engage à ne pas laisser conduire la voiture par d'autres personnes que lui même ou celles agréées par le loueur et dont il se porte garant, et à réutiliser le véhicule que pour ses besoins personnels. Il est interdit de participer à toute compétition, quelle qu'elle soit, et d'utiliser le véhicule aux fins illicites ou des transports de marchandises. Le locataire s'engage à ne pas solliciter directement des documents douaniers. Il est interdit au locataire de surcharger le véhicule loué en transportant un nombre de passagers supérieur à celui porté sur le contrat, sous peine d'être déchu de l'Assurance. Le locataire ne doit jamais faire circuler le véhicule ailleurs qu'au Maroc et en dehors des routes asphaltées, seules les routes carrossables goudronnées doivent être empruntées.\n\n" +
                        "Art. 2 - ETAT DE LA VOITURE\n" +
                        "La voiture est livrée en parfait état de marche et de propreté. Les compteurs et leurs prises sont plombés, et les plombs ne pourront être enlevés ou volés sous peine de devoir payer la location sur la base de 500 Kilomètres par jour. La voiture sera rendue dans le même état de propreté, à défaut le locataire devra acquitter les frais de nettoyages et remises en état les 5 pneus sont en bon état sans coupures, l'usure est normale. En cas de détérioration de l'un d'eux pour une cause autre que l'usure normale. Le locataire s'engage à le remplacer immédiatement par un pneu neuf de mêmes dimensions ou d'en payer le Montant.\n\n" +
                        "Art. 3 - ESSENCE ET HUILE\n" +
                        "L'essence est à la charge du client. Le locataire doit vérifier en permanence les niveaux d'huile et d'eau, et vérifier les niveaux de la boite de vitesse et du pont arrière tous les 1000 Kilomètres. Il justifiera ces travaux par des factures correspondantes (qui lui seront remboursées) sous peine d'avoir à payer une indemnité pour usure anormale.\n\n" +
                        "Art. 4 - ENTRETIEN ET REPARATION\n" +
                        "L'usure mécanique normale est à la charge du loueur. Toutes les réparations provenants, soit d'une usure anormale, soit d'une négligence de la part du locataire ou d'un accident accidentel, sont à sa charge et exécutées par nos soins. Dans le cas ou le véhicule serait immobilisé en dehors de la région, les réparations qu'elles soient dues à l'usure normale ou à une cause accidentelle, ne seront exécutées qu'après accord télégraphique du loueur ou par l'Agent régional de la marque du véhicule. Elles devront faire l'objet d'une facture acquittée et très détaillée. Les pièces défectueuses remplacées devront être présentées avec la facture acquittée. En aucun cas et en aucune circonstance, le locataire ne pourra réclamer des dommages et intérêts, soit pour retard de la remise de la voiture, ou annulation de la location, soit pour immobilisation dans le cas de réparation nécessités par une usure normale et exécutées au cours de la location. La responsabilité du loueur ne pourra jamais être invoquée, même en cas d'accidents de personnes ou de choses ayant pu résulter de vices ou de défauts de construction ou de réparations antérieures.\n\n" +
                        "Art. 5 - ASSURANCE\n" +
                        "Le locataire est garanti pour les risques suivants: En cas d'accidents fortuit ou fautif le locataire est entièrement responsable des dommages causés au véhicule en conséquence il est tenu de nous régler le montant total des réparations. Le Locataire est le seul conducteur du véhicule et s'engage à ne pas céder à autrui à moins d'une stipulation sur le présent contrat. Les frais de rapatriement et d'immobilisation reste toujours à la charge du locataire, quelle que soit la formule d'assurance contractées. ASSURANCE-Assure tiers illimitée vol et incendie est inclus dans le prix de location assure complémentaire de 35 dhs par jour en cas d'accident fautif 30% et fortuite 50% restent à la charge du client. Assure des personnes transportées peut être souscrite pour 15 dhs par jour. La voiture n'est assurée que pour la durée de la location. Passé ce délai, le loueur décline toute responsabilité pour les accidents que le locataire aurait pu causer et dont il devra faire son affaire personnelle. Enfin, il n'y a pas Assurance pour tout conducteur non muni d'un permis en état de validité ou d'un permis datant de moins de 1 an. Le Loueur décline toute responsabilité pour les accidents aux tiers ou dégâts à la voiture que le locataire pourrait causer pendant la période de location si le locataire a délibérément fourni au loueur des informations fausses concernant son identité, son adresse ou la validité de son permis de conduire.";

                String rightText = "Art. 6 - LOCATION, CAUTION, PROLONGATION\n" +
                        "Les prix de la location, ainsi que la caution, sont payables d'avance. La caution ne pourra servir, en aucun cas au loueur, faire parvenir le montant de la location en cours, sous peine d'éviter toute contestation et pour le cas où le locataire voudrait conserver la voiture pour un temps supérieur à celui indiqué sur le contrat, il devra après avoir obtenu l'accord de s'exposer à des poursuites pour détournement de voiture ou abus de confiance. La journée de location compte de 0 heures à 24 heures et toute journée commencée est due en entier.\n\n" +
                        "Art. 7 - RAPATRIEMENT DE LA VOITURE\n" +
                        "Le locataire s'interdit formellement d'abandonner le véhicule. En cas d'impossibilité matérielle, celle-ci sera rapatriée aux frais et par les soins du locataire, la location restant due jusqu'à retour du véhicule.\n\n" +
                        "Art. 8 - PAPIERS DE LA VOITURE\n" +
                        "Le locataire remettra dès la fin de la location et à la rentrée de la voiture, la carte grise et tous les papiers nécessaires à sa circulation, faute de quoi, ces pièces étant indispensables à de nouvelles locations, la location continuera à courir aux frais du locataire initial jusqu'à leur remise à la société. En cas de perte de ces papiers le locataire devra acquitter le montant des frais de duplicata, ainsi que de l'immobilisation.\n\n" +
                        "Art. 9 - RESPONSABILITE\n" +
                        "Le locataire demeure seul responsable des amendes, contraventions et procès-verbaux établis contre lui.\n\n" +
                        "Art. 10 - COMPETENCE\n" +
                        "De convention expresse et en cas de contestation quelconque, le tribunal de Tanger sera seul compétent, les frais de timbres et d'enregistrement restant à la charge du locataire.";

                drawParagraphJustified(cs2, leftText, leftColX, startY, colWidth, lineSpacing, regular, 6.5f, Color.BLACK);
                drawParagraphJustified(cs2, rightText, rightColX, startY, colWidth, lineSpacing, regular, 6.5f, Color.BLACK);

                // Bottom Page 2 elements
                drawText(cs2, "je reconnais avoir pris connaissance des présentes conditions générales (recto et verso) Que je m'engage à les respecter.", 20, 80, italic, 7.5f, Color.BLACK);
                drawText(cs2, "Signature Client", 450, 60, bold, 9, Color.BLACK);
            }

            doc.save(out);
            return out.toByteArray();
        }
    }

    private String safe(String s) { return s != null ? s : ""; }

    private String buildTelFax(CompanySettings s) {
        if (s.getPhone() != null && s.getFax() != null && s.getPhone().equals(s.getFax())) {
            return "Tél/Fax : " + s.getPhone();
        } else if (s.getPhone() != null && s.getFax() != null) {
            return "Tél : " + s.getPhone() + "  Fax : " + s.getFax();
        } else if (s.getPhone() != null) {
            return "Tél : " + s.getPhone();
        }
        return "";
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

    private void drawParagraphJustified(PDPageContentStream cs, String text, float x, float yStart, float width, float lineSpacing, PDFont font, float fontSize, Color color) throws IOException {
        String[] paragraphs = text.split("\n");
        float currentY = yStart;
        
        for (String para : paragraphs) {
            if (para.trim().isEmpty()) {
                currentY -= lineSpacing;
                continue;
            }
            
            String[] rawWords = para.split("\\s+");
            List<String> words = new ArrayList<>();
            for (String w : rawWords) {
                if (w != null && !w.trim().isEmpty()) {
                    words.add(w);
                }
            }
            if (words.isEmpty()) continue;
            
            List<String> currentLineWords = new ArrayList<>();
            float currentLineWidth = 0;
            float spaceWidth = getStringWidth(" ", font, fontSize);
            
            for (String word : words) {
                String sanitizedWord = sanitize(word);
                float wordWidth = getStringWidth(sanitizedWord, font, fontSize);
                float spacingNeeded = currentLineWords.isEmpty() ? 0 : spaceWidth;
                
                if (currentLineWidth + spacingNeeded + wordWidth <= width) {
                    currentLineWords.add(sanitizedWord);
                    currentLineWidth += spacingNeeded + wordWidth;
                } else {
                    drawLineJustified(cs, currentLineWords, x, currentY, width, font, fontSize, color);
                    currentY -= lineSpacing;
                    
                    currentLineWords.clear();
                    currentLineWords.add(sanitizedWord);
                    currentLineWidth = wordWidth;
                }
            }
            
            if (!currentLineWords.isEmpty()) {
                drawLineLeftAligned(cs, currentLineWords, x, currentY, font, fontSize, color);
                currentY -= lineSpacing;
            }
            
            currentY -= lineSpacing * 0.4f;
        }
    }

    private void drawLineJustified(PDPageContentStream cs, List<String> words, float x, float y, float width, PDFont font, float fontSize, Color color) throws IOException {
        if (words.isEmpty()) return;
        if (words.size() == 1) {
            drawText(cs, words.get(0), x, y, font, fontSize, color);
            return;
        }
        
        float totalWordsWidth = 0;
        for (String word : words) {
            totalWordsWidth += getStringWidth(word, font, fontSize);
        }
        
        float totalSpaceWidth = width - totalWordsWidth;
        float spaceBetweenWords = totalSpaceWidth / (words.size() - 1);
        
        float currentX = x;
        for (String word : words) {
            drawText(cs, word, currentX, y, font, fontSize, color);
            currentX += getStringWidth(word, font, fontSize) + spaceBetweenWords;
        }
    }

    private void drawLineLeftAligned(PDPageContentStream cs, List<String> words, float x, float y, PDFont font, float fontSize, Color color) throws IOException {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < words.size(); i++) {
            sb.append(words.get(i));
            if (i < words.size() - 1) sb.append(" ");
        }
        drawText(cs, sb.toString(), x, y, font, fontSize, color);
    }

    private String sanitize(String text) {
        if (text == null) return "";
        String cleaned = text.replaceAll("\u202D", "").replaceAll("\u202C", "");
        StringBuilder sb = new StringBuilder();
        for (char c : cleaned.toCharArray()) {
            if (c >= 32 && c <= 126) {
                sb.append(c);
            } else if (c == '\n' || c == '\r' || c == '\t') {
                sb.append(' ');
            } else {
                if ((c >= 160 && c <= 255) || c == 'œ' || c == 'Œ' || c == '€' 
                        || (c >= 0x0600 && c <= 0x06FF) || (c >= 0xFE70 && c <= 0xFEFF)) {
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
