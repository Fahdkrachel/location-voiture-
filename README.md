# BOUSSELHA CARS

Monorepo de demarrage pour un systeme de gestion de location de voitures.

## Documentation fonctionnelle

Pour la **liste détaillée de toutes les fonctionnalités** (API REST, règles métier, écrans Flutter, matrice backend/front), voir :

**[FONCTIONNALITES.md](./FONCTIONNALITES.md)**

Pour tout ce qui **dépend du contrat de location** (cycle de vie, impact voitures/clients/revenus/calendrier), voir la **section 19** du même document.

### Tester les alertes du Dashboard

Le panneau **Alertes** (à droite du calendrier) affiche les rappels assurance / visite technique / vidange pour chaque voiture.

**Procédure** (détail dans [FONCTIONNALITES.md §7 et §12](./FONCTIONNALITES.md#comment-tester-les-alertes-manuellement)) :

1. Lancer backend + Flutter (`voir ci-dessous`).
2. **Voitures** → **Modifier** une voiture → renseigner par exemple **Expiration assurance** à une date dans moins de 30 jours (`YYYY-MM-DD`).
3. Ouvrir **Dashboard** → une alerte **INSURANCE** doit apparaître à droite (icône orange ou rouge si date dépassée).
4. Pour vider les alertes : remettre les dates loin dans le futur ou vides → message **« Aucune alerte. »**

Test API optionnel : `GET http://localhost:8080/api/dashboard/alerts` (Swagger).

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
