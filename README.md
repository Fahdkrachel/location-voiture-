# BOUSSELHA CARS

Monorepo de demarrage pour un systeme de gestion de location de voitures.

## Projets

- `bousselha-backend`: Spring Boot 3 + MySQL + Swagger + PDFBox
- `bousselha-flutter`: Flutter desktop + Riverpod + Dio

## Lancer le backend

1. Configurer Java 17 (`JAVA_HOME`) et MySQL.
2. Mettre a jour `bousselha-backend/src/main/resources/application.properties`.
3. Executer:

```bash
cd "C:\Users\pc\Desktop\BOUSSELHA CARS"
cd bousselha-backend
mvn spring-boot:run
```

Swagger: `http://localhost:8080/swagger-ui.html`

## Lancer le frontend

```bash
cd "C:\Users\pc\Desktop\BOUSSELHA CARS"
cd bousselha-flutter
flutter pub get
flutter run -d windows
```
