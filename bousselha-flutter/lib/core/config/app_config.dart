import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppConfig {
  static String apiUrl = 'http://localhost:8080/api';
  static String imageUrlPrefix = 'http://localhost:8080';

  static Future<void> init() async {
    try {
      // 1. Essayer de charger le fichier externe s'il existe à côté de l'exécutable
      if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
        final exeFile = File(Platform.resolvedExecutable);
        final exeDir = exeFile.parent.path;
        final separator = Platform.isWindows ? '\\' : '/';
        final externalConfigFile = File('$exeDir${separator}config.json');
        
        if (await externalConfigFile.exists()) {
          final content = await externalConfigFile.readAsString();
          final data = json.decode(content) as Map<String, dynamic>;
          if (data['api_url'] != null) {
            apiUrl = data['api_url'] as String;
          }
          if (data['image_url_prefix'] != null) {
            imageUrlPrefix = data['image_url_prefix'] as String;
          }
          debugPrint('Configuration externe chargée depuis : ${externalConfigFile.path}');
          debugPrint('API URL: $apiUrl');
          return;
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la config externe : $e');
    }

    // 2. Fallback sur le fichier d'assets interne
    try {
      final content = await rootBundle.loadString('assets/config.json');
      final data = json.decode(content) as Map<String, dynamic>;
      if (data['api_url'] != null) {
        apiUrl = data['api_url'] as String;
      }
      if (data['image_url_prefix'] != null) {
        imageUrlPrefix = data['image_url_prefix'] as String;
      }
      debugPrint('Configuration d\'assets par défaut chargée.');
      debugPrint('API URL: $apiUrl');
    } catch (e) {
      debugPrint('Erreur lors du chargement des assets de config : $e');
    }
  }
}
