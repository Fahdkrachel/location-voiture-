package com.bousselha.infrastructure.exception;

import jakarta.validation.ConstraintViolationException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.mail.MailException;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.authentication.LockedException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.multipart.MaxUploadSizeExceededException;

import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {

    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    // ──────────────────────────────────────────────────────────────────
    // Ressource introuvable
    // ──────────────────────────────────────────────────────────────────
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity<Map<String, String>> handleNotFound(ResourceNotFoundException ex) {
        log.warn("Ressource introuvable : {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(Map.of("error", translateMessage(ex.getMessage())));
    }

    // ──────────────────────────────────────────────────────────────────
    // Validation des champs (@Valid)
    // ──────────────────────────────────────────────────────────────────
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<Map<String, Object>> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> fields = new HashMap<>();
        for (FieldError error : ex.getBindingResult().getFieldErrors()) {
            fields.put(error.getField(), translateFieldError(error.getField(), error.getDefaultMessage()));
        }
        return ResponseEntity.badRequest()
                .body(Map.of("error", "Données invalides. Veuillez corriger les champs ci-dessous.", "fields", fields));
    }

    // ──────────────────────────────────────────────────────────────────
    // Contraintes métier (IllegalArgumentException)
    // ──────────────────────────────────────────────────────────────────
    @ExceptionHandler({ConstraintViolationException.class, IllegalArgumentException.class})
    public ResponseEntity<Map<String, String>> handleBadRequest(Exception ex) {
        String raw = ex.getMessage();
        log.warn("Erreur métier : {}", raw);
        Map<String, String> body = new LinkedHashMap<>();
        body.put("error", translateMessage(raw));
        if (raw != null) body.put("code", raw);
        return ResponseEntity.badRequest().body(body);
    }

    // ──────────────────────────────────────────────────────────────────
    // Erreur d'envoi d'e-mail (SMTP)
    // ──────────────────────────────────────────────────────────────────
    @ExceptionHandler(MailException.class)
    public ResponseEntity<Map<String, String>> handleMailException(MailException ex) {
        log.error("Échec d'envoi du mail : {}", ex.getMessage());
        return ResponseEntity.status(HttpStatus.SERVICE_UNAVAILABLE)
                .body(Map.of(
                        "error", "L'envoi de l'e-mail a échoué. Vérifiez votre connexion ou réessayez dans quelques instants.",
                        "code", "MAIL_SEND_FAILED"
                ));
    }

    // ──────────────────────────────────────────────────────────────────
    // Authentification
    // ──────────────────────────────────────────────────────────────────
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<Map<String, String>> handleBadCredentials(BadCredentialsException ex) {
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                .body(Map.of("error", "Email ou mot de passe incorrect. Veuillez vérifier vos identifiants."));
    }

    @ExceptionHandler(DisabledException.class)
    public ResponseEntity<Map<String, String>> handleDisabled(DisabledException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(Map.of("error", "Ce compte est désactivé. Contactez un administrateur."));
    }

    @ExceptionHandler(LockedException.class)
    public ResponseEntity<Map<String, String>> handleLocked(LockedException ex) {
        return ResponseEntity.status(HttpStatus.FORBIDDEN)
                .body(Map.of("error", "Ce compte est verrouillé. Contactez un administrateur."));
    }

    // ──────────────────────────────────────────────────────────────────
    // Fichier trop grand
    // ──────────────────────────────────────────────────────────────────
    @ExceptionHandler(MaxUploadSizeExceededException.class)
    public ResponseEntity<Map<String, String>> handleFileTooLarge(MaxUploadSizeExceededException ex) {
        return ResponseEntity.status(HttpStatus.PAYLOAD_TOO_LARGE)
                .body(Map.of("error", "Le fichier est trop volumineux. La taille maximale autorisée est 10 Mo."));
    }

    // ──────────────────────────────────────────────────────────────────
    // Erreur générique (500)
    // ──────────────────────────────────────────────────────────────────
    @ExceptionHandler(Exception.class)
    public ResponseEntity<Map<String, String>> handleGeneric(Exception ex) {
        log.error("Erreur inattendue : {}", ex.getMessage(), ex);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body(Map.of("error", "Une erreur inattendue s'est produite. Veuillez réessayer ou contacter le support."));
    }

    // ──────────────────────────────────────────────────────────────────
    // Traduction des codes d'erreur techniques vers le français
    // ──────────────────────────────────────────────────────────────────
    private String translateMessage(String raw) {
        if (raw == null) return "Une erreur s'est produite.";
        return switch (raw.trim()) {
            // ── Véhicules ──
            case "NEW_CAR_MUST_BE_AVAILABLE"
                    -> "Un nouveau véhicule doit avoir le statut « Disponible ».";
            case "ONLY_RENTED_OR_MAINTENANCE_CAN_BECOME_AVAILABLE"
                    -> "Seuls les véhicules en location ou en maintenance peuvent être remis disponibles.";
            case "MAINTENANCE_NOT_FINISHED"
                    -> "Impossible : une maintenance est toujours en cours. Terminez-la d'abord dans le module Maintenance.";
            case "CAR_HAS_ACTIVE_CONTRACT"
                    -> "Impossible : ce véhicule est lié à un contrat actif. Clôturez le contrat d'abord.";
            case "CAR_HAS_RENTAL_HISTORY"
                    -> "Impossible de supprimer cette voiture, car elle contient un historique de locations ou de maintenance. Cette restriction protège les contrats, les PDF et les données financières. Vous pouvez la retirer de l'utilisation en l'archivant.";
            case "MILEAGE_REQUIRED"
                    -> "Le kilométrage est obligatoire.";
            case "MILEAGE_MUST_BE_POSITIVE"
                    -> "Le kilométrage doit être un nombre positif.";
            case "MILEAGE_CANNOT_DECREASE"
                    -> "Le kilométrage ne peut pas être inférieur au kilométrage actuel.";
            case "Unsupported image format"
                    -> "Format d'image non supporté. Utilisez JPG, JPEG ou PNG.";
            // ── Maintenance ──
            case "USE_COMPLETE_ENDPOINT"
                    -> "Pour terminer une maintenance, utilisez le bouton « Terminer » dédié.";
            case "MAINTENANCE_ALREADY_COMPLETED"
                    -> "Cette maintenance est déjà marquée comme terminée.";
            // ── Contrats ──
            case "Seul un contrat IN_PROGRESS peut passer en ACTIVE"
                    -> "Seul un contrat en préparation peut être activé.";
            case "Seul un contrat ACTIVE peut être terminé"
                    -> "Seul un contrat actif peut être clôturé.";
            case "Impossible de modifier un contrat déjà terminé"
                    -> "Ce contrat est déjà terminé et ne peut plus être modifié.";
            case "Impossible : terminez le contrat avant de le supprimer"
                    -> "Impossible de supprimer un contrat actif. Clôturez-le d'abord.";
            case "Cannot change assigned car while contract is active"
                    -> "Impossible de changer le véhicule d'un contrat en cours d'activité.";
            // ── Clients ──
            case "Impossible de supprimer : client a des contrats en cours"
                    -> "Impossible de supprimer ce client : il a des contrats en cours ou actifs.";
            // ── Paramètres ──
            case "Format non supporté. Utilisez JPG ou PNG."
                    -> "Format de logo non supporté. Veuillez utiliser un fichier JPG ou PNG.";
            case "RESET_REQUEST_LIMIT_REACHED"
                    -> "Trop de demandes de réinitialisation. Veuillez réessayer dans une heure.";
            case "INVALID_RESET_CODE"
                    -> "Code de vérification invalide.";
            case "RESET_CODE_ALREADY_USED"
                    -> "Ce code a déjà été utilisé. Demandez un nouveau code.";
            case "RESET_CODE_EXPIRED"
                    -> "Ce code a expiré. Demandez un nouveau code.";
            case "RESET_CODE_BLOCKED"
                    -> "Trop de tentatives incorrectes. Demandez un nouveau code.";
            case "PASSWORD_CONFIRMATION_MISMATCH"
                    -> "Le nouveau mot de passe et sa confirmation ne correspondent pas.";
            case "WEAK_PASSWORD"
                    -> "Le mot de passe doit contenir au moins 8 caractères, une majuscule, une minuscule, un chiffre et un caractère spécial.";
            default -> {
                // Messages déjà en français (contenant des espaces/caractères accentués)
                if (raw.contains("est déjà réservée") || raw.contains("réservée ou louée"))
                    yield "Ce véhicule est déjà réservé ou loué sur cette période. Choisissez une autre date ou un autre véhicule.";
                if (raw.contains("n'est pas disponible pour une location") || raw.contains("statut actuel"))
                    yield "Ce véhicule n'est pas disponible actuellement. Vérifiez son statut dans la liste des véhicules.";
                if (raw.contains("n'est pas disponible") && raw.contains("matricule"))
                    yield "Ce véhicule n'est plus disponible. Rafraîchissez la liste et réessayez.";
                if (raw.contains("Transition de statut non autorisée"))
                    yield "Changement de statut non autorisé pour ce contrat.";
                if (raw.contains("Impossible de supprimer") || raw.contains("contrat en cours"))
                    yield "Suppression impossible : ce contrat a des dépendances actives.";
                if (raw.contains("Unable to store image") || raw.contains("Impossible d'enregistrer"))
                    yield "Erreur lors de l'enregistrement du fichier. Vérifiez les permissions du dossier uploads.";
                // Message déjà lisible → retourner tel quel
                yield raw;
            }
        };
    }

    private String translateFieldError(String field, String message) {
        if (message == null) return "Valeur invalide.";
        return switch (message) {
            case "must not be blank", "must not be null" -> "Ce champ est obligatoire.";
            case "must not be empty" -> "Ce champ ne peut pas être vide.";
            case "must be a well-formed email address" -> "Adresse e-mail invalide.";
            case "must be greater than or equal to 0" -> "La valeur doit être positive ou nulle.";
            case "must be greater than 0" -> "La valeur doit être supérieure à zéro.";
            case "size must be between 6 and 2147483647" -> "Ce champ doit contenir au moins 6 caractères.";
            case "size must be between 1 and 2147483647" -> "Ce champ doit contenir au moins 1 caractère.";
            default -> message;
        };
    }
}
