import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// AppErrorHandler
// Centralise la gestion des erreurs dans toute l'application.
// Traduit les exceptions techniques en messages clairs pour l'administrateur.
// ─────────────────────────────────────────────────────────────────────────────

class AppErrorHandler {
  AppErrorHandler._();

  /// Extrait un message lisible depuis n'importe quelle exception.
  static String getMessage(Object error) {
    // 1. DioException : l'intercepteur a déjà construit un message propre
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        // Erreur de validation avec détail des champs
        if (data.containsKey('fields') && data['fields'] is Map) {
          final fields = data['fields'] as Map;
          final buf = StringBuffer('Données invalides :\n');
          fields.forEach((key, val) {
            buf.writeln('• ${_fieldLabel(key.toString())} : $val');
          });
          return buf.toString().trim();
        }
        // Message d'erreur simple
        if (data.containsKey('error')) {
          return data['error'].toString();
        }
        if (data.containsKey('message')) {
          return data['message'].toString();
        }
      }

      // Erreurs de connexion / timeout
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Délai de connexion dépassé. Vérifiez que le serveur est démarré et que la connexion réseau est active.';
        case DioExceptionType.connectionError:
          return 'Impossible de joindre le serveur. Assurez-vous que le backend est démarré sur le port 8080.';
        case DioExceptionType.badResponse:
          return _httpStatusMessage(error.response?.statusCode);
        case DioExceptionType.cancel:
          return 'La requête a été annulée.';
        default:
          break;
      }

      // Message propre généré par l'intercepteur DioClient
      if (error.message != null && error.message!.isNotEmpty) {
        return error.message!;
      }
    }

    // 2. Exception standard (ex: FormatException, etc.)
    final raw = error.toString();

    // Supprimer le préfixe "Exception: " ou "Error: "
    final cleaned = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^Error:\s*'), '')
        .trim();

    // Si ça ressemble à du code technique, afficher un message générique
    if (_isTechnicalMessage(cleaned)) {
      return 'Une erreur inattendue s\'est produite. Veuillez réessayer.';
    }

    return cleaned.isEmpty ? 'Une erreur s\'est produite.' : cleaned;
  }

  /// Affiche un SnackBar d'erreur rouge stylisé.
  static void showError(BuildContext context, Object error, {String? prefix}) {
    if (!context.mounted) return;
    final msg = prefix != null
        ? '$prefix : ${getMessage(error)}'
        : getMessage(error);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  msg,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 5),
        ),
      );
  }

  /// Affiche un SnackBar de succès vert stylisé.
  static void showSuccess(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
  }

  /// Affiche un SnackBar d'avertissement orange.
  static void showWarning(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD97706),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
  }

  /// Message d'erreur adapté au code HTTP.
  static String _httpStatusMessage(int? code) {
    switch (code) {
      case 400:
        return 'Données incorrectes envoyées au serveur. Vérifiez les champs saisis.';
      case 401:
        return 'Session expirée ou identifiants incorrects. Veuillez vous reconnecter.';
      case 403:
        return 'Accès refusé. Vous n\'avez pas les permissions pour cette action.';
      case 404:
        return 'Élément introuvable. Il a peut-être été supprimé.';
      case 409:
        return 'Conflit : cet élément existe déjà ou est utilisé par un autre enregistrement.';
      case 413:
        return 'Fichier trop volumineux. La taille maximale autorisée est 10 Mo.';
      case 422:
        return 'Données non traitables. Vérifiez les informations saisies.';
      case 500:
        return 'Erreur interne du serveur. Veuillez réessayer ou contacter le support.';
      case 502:
      case 503:
      case 504:
        return 'Le serveur est temporairement indisponible. Veuillez réessayer dans quelques instants.';
      default:
        return 'Erreur serveur (code $code). Veuillez réessayer.';
    }
  }

  /// Noms lisibles des champs de formulaire.
  static String _fieldLabel(String field) {
    const labels = {
      'email': 'Adresse e-mail',
      'password': 'Mot de passe',
      'fullName': 'Nom complet',
      'brand': 'Marque',
      'matricule': 'Immatriculation',
      'mileage': 'Kilométrage',
      'fuelType': 'Type de carburant',
      'carId': 'Véhicule',
      'clientId': 'Client',
      'totalGeneral': 'Total général',
      'departureDatetime': 'Date de départ',
      'expectedReturnDatetime': 'Date de retour prévue',
      'companyName': 'Nom de la société',
      'phone': 'Téléphone',
      'address': 'Adresse',
      'type': 'Type de maintenance',
      'startDate': 'Date de début',
      'cost': 'Coût',
    };
    return labels[field] ?? field;
  }

  /// Détecte si un message est trop technique pour être affiché.
  static bool _isTechnicalMessage(String msg) {
    final technicalPatterns = [
      RegExp(r'SocketException'),
      RegExp(r'HandshakeException'),
      RegExp(r'HttpException'),
      RegExp(r'FormatException'),
      RegExp(r'NullCheck'),
      RegExp(r'Null check operator'),
      RegExp(r"type '.*' is not a subtype"),
      RegExp(r'Connection refused'),
      RegExp(r'java\.'),
      RegExp(r'org\.springframework'),
      RegExp(r'com\.mysql'),
      RegExp(r'HibernateJpaDialect'),
      RegExp(r'DataIntegrityViolation'),
    ];
    return technicalPatterns.any((p) => p.hasMatch(msg));
  }
}
