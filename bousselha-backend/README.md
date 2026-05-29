# BOUSSELHA CARS — Backend Spring Boot 3

Ce répertoire contient l'API REST développée en **Spring Boot 3** et **Java 17** pour le système **BOUSSELHA CARS**.

## 📌 Informations de démarrage rapide

Pour comprendre l'architecture globale (DDD - Domain-Driven Design), la configuration de la base de données MySQL (manuelle due à `ddl-auto=none`), les variables d'environnement, Swagger et les flux métier, merci de consulter le **README principal** à la racine du projet :

👉 **[README Principal du Monorepo](../README.md)**

## ⚡ Commandes de base

### 1. Lancer le serveur de développement
```bash
mvn spring-boot:run
```

### 2. Accéder à l'API Interactive (Swagger UI)
Une fois le serveur démarré avec succès :
👉 **[http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)**

### 3. Emplacement des scripts de base de données
Tous les scripts SQL de structure et de correctifs sont disponibles dans :
`src/main/resources/db/` (ex: `schema_once.sql`).
