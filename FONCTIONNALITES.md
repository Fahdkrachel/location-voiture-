# BOUSSELHA CARS — Fonctionnalités détaillées (Backend & Frontend)

Document de référence décrivant **toutes les capacités** du système de gestion de location de voitures, module par module, avec les règles métier, les API REST et l’équivalent dans l’application Flutter desktop.

---

## Table des matières

1. [Architecture globale](#1-architecture-globale)
2. [Backend — Vue d’ensemble](#2-backend--vue-densemble)
3. [Backend — Voitures (`/api/cars`)](#3-backend--voitures-apicars)
4. [Backend — Clients (`/api/clients`)](#4-backend--clients-apiclients)
5. [Backend — Contrats (`/api/contracts`)](#5-backend--contrats-apicontracts)
6. [Backend — Maintenance (`/api/maintenance`)](#6-backend--maintenance-apimaintenance)
7. [Backend — Tableau de bord (`/api/dashboard`)](#7-backend--tableau-de-bord-apidashboard)
8. [Backend — Génération PDF](#8-backend--génération-pdf)
9. [Backend — Erreurs & sécurité](#9-backend--erreurs--sécurité)
10. [Frontend — Vue d’ensemble](#10-frontend--vue-densemble)
11. [Frontend — Navigation & shell](#11-frontend--navigation--shell)
12. [Frontend — Dashboard](#12-frontend--dashboard)
13. [Frontend — Voitures](#13-frontend--voitures)
14. [Frontend — Clients](#14-frontend--clients)
15. [Frontend — Contrats](#15-frontend--contrats)
16. [Frontend — Maintenance](#16-frontend--maintenance)
17. [Matrice Backend ↔ Frontend](#17-matrice-backend--frontend)
18. [Limites connues](#18-limites-connues)

---

## 1. Architecture globale

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| **bousselha-backend** | Spring Boot 3.3, Java 17, JPA/Hibernate, MySQL | API REST, persistance, PDF, fichiers images |
| **bousselha-flutter** | Flutter (desktop Windows), Riverpod, Dio | Interface utilisateur, consommation API |
| **Base de données** | MySQL (`bousselha_db`) | Entités : `cars`, `clients`, `contracts`, `maintenance` |

- **URL API** : `http://localhost:8080/api` (configurable via `application.properties`)
- **Swagger UI** : `http://localhost:8080/swagger-ui.html`
- **CORS** : toutes origines autorisées sur `/api/**` (méthodes GET, POST, PUT, DELETE, OPTIONS)
- **Pas d’authentification** : l’API est ouverte (usage interne / démo)

---

## 2. Backend — Vue d’ensemble

### Structure des packages

```
com.bousselha
├── domain/          # Entités JPA, enums, repositories
├── application/     # Services métier, DTO request/response
├── infrastructure/  # Controllers REST, exceptions
└── config/          # CORS, OpenAPI/Swagger
```

### Énumérations métier

| Enum | Valeurs | Usage |
|------|---------|--------|
| `CarStatus` | `AVAILABLE`, `RENTED`, `MAINTENANCE` | Statut de la voiture |
| `FuelType` | `ESSENCE`, `DIESEL` | Type de carburant |
| `ContractStatus` | `ACTIVE`, `COMPLETED`, `CANCELLED` | Statut du contrat |

### Persistance

- `spring.jpa.hibernate.ddl-auto=update` : schéma mis à jour automatiquement au démarrage
- Contrats : **suppression logique** (`deleted = true`), pas de suppression physique
- Voitures / clients : **suppression physique** en base

---

## 3. Backend — Voitures (`/api/cars`)

### Entité `Car`

| Champ | Type | Description |
|-------|------|-------------|
| `id` | Long | Identifiant auto |
| `brand` | String | Marque (obligatoire) |
| `fuelType` | FuelType | ESSENCE / DIESEL |
| `matricule` | String | Immatriculation (unique) |
| `nextInspectionDate` | LocalDate | Prochaine visite technique |
| `lastOilChangeDate` | LocalDate | Dernière vidange |
| `insuranceExpiryDate` | LocalDate | Expiration assurance |
| `imageUrl` | String | Chemin public ex. `/uploads/cars/{uuid}.jpg` |
| `status` | CarStatus | Par défaut `AVAILABLE` |
| `createdAt`, `updatedAt` | LocalDateTime | Horodatage |

### Endpoints

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/api/cars` | Liste de toutes les voitures |
| `GET` | `/api/cars/{id}` | Détail d’une voiture |
| `GET` | `/api/cars/available` | Voitures `AVAILABLE` |
| `GET` | `/api/cars/rented` | Voitures `RENTED` |
| `GET` | `/api/cars/maintenance` | Voitures `MAINTENANCE` |
| `POST` | `/api/cars` | Création (**multipart/form-data**) |
| `PUT` | `/api/cars/{id}` | Mise à jour (**multipart/form-data**) |
| `DELETE` | `/api/cars/{id}` | Suppression |
| `GET` | `/api/cars/{id}/history` | Historique locations + maintenances |

### Création / mise à jour (paramètres formulaire)

- `brand`, `fuelType`, `matricule` : obligatoires
- `nextInspectionDate`, `lastOilChangeDate`, `insuranceExpiryDate` : optionnels (`YYYY-MM-DD`)
- `status` : optionnel (défaut `AVAILABLE` à la création)
- `image` : fichier optionnel (`.jpg`, `.jpeg`, `.png` uniquement)

### Règles métier

1. **Image** : stockée dans `src/main/resources/static/uploads/cars/`, URL publique `/uploads/cars/{uuid}.ext`
2. **Suppression** : refusée si un contrat **ACTIVE** existe pour cette voiture → message `Impossible : voiture en location active`
3. **Historique** (`/history`) : fusionne
   - les contrats non supprimés liés à la voiture (type `RENTAL`, client, dates, montant, statut contrat)
   - les enregistrements maintenance (type `MAINTENANCE`, type, dates, coût)
   - tri par date de début **décroissante**

### Réponse `CarResponse`

`id`, `brand`, `fuelType`, `matricule`, dates d’entretien/assurance, `imageUrl`, `status`

---

## 4. Backend — Clients (`/api/clients`)

### Entité `Client`

**Section locataire**

| Champ | Description |
|-------|-------------|
| `fullName` | Nom & prénom |
| `birthDate` | Date de naissance |
| `addressMorocco`, `addressAbroad` | Adresses |
| `profession` | Profession |
| `drivingLicenseNumber`, `drivingLicenseIssuedAt` | Permis (n° et ville de délivrance) |
| `cinNumber` | CIN |
| `passportNumber`, `passportIssuedAt` | Passeport |
| `phone` | Téléphone |

**Section conducteur supplémentaire** (stockée sur le client)

| Champ | Description |
|-------|-------------|
| `additionalDriverFullName` | Nom |
| `additionalDriverDrivingLicenseNumber` | Permis |
| `additionalDriverDrivingLicenseIssuedAt` | Date délivrance permis |
| `additionalDriverPassportNumber` | Passeport |

### Endpoints

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/api/clients` | Liste |
| `GET` | `/api/clients/{id}` | Détail |
| `POST` | `/api/clients` | Création (JSON, `@Valid`) |
| `PUT` | `/api/clients/{id}` | Mise à jour (JSON) |
| `DELETE` | `/api/clients/{id}` | Suppression |

### Validation `ClientRequest`

- Obligatoires : `fullName`, `cinNumber`, `phone`
- Autres champs optionnels

### Règles métier

- **Suppression** : refusée si le client a un contrat **ACTIVE** → `Impossible de supprimer : client a des contrats en cours`

---

## 5. Backend — Contrats (`/api/contracts`)

### Entité `Contract`

Lie une **voiture** et un **client**, avec tarification, paiements et état du véhicule.

| Groupe | Champs principaux |
|--------|-------------------|
| Relations | `car`, `client` |
| Conducteur supp. (sur contrat) | `additionalDriverName`, `additionalDriverLicense`, `additionalDriverPassport` |
| Lieux / dates | `departurePlace`, `returnPlace`, `departureDatetime`, `expectedReturnDatetime`, `actualReturnDatetime`, `durationDays` |
| Tarifs | `pricePerHour/Day/Week/Month`, `withInsurance`, `totalPrice`, `supplement`, `totalGeneral` |
| Paiement | `paymentCash`, `paymentCheck`, `paymentDeposit` |
| Dommages (PDF / données) | `vehicleConditionDeparture`, `vehicleConditionReturn`, `damagesIdentified` |
| Statut | `status` (défaut `ACTIVE`), `deleted`, `createdAt` |

### Endpoints

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/api/contracts` | Tous les contrats non supprimés |
| `GET` | `/api/contracts?carId={id}` | Contrats d’une voiture |
| `GET` | `/api/contracts/{id}` | Détail (réponse enrichie client + voiture) |
| `GET` | `/api/contracts/active` | Contrats `ACTIVE` uniquement |
| `POST` | `/api/contracts` | Création |
| `PUT` | `/api/contracts/{id}` | Mise à jour |
| `PUT` | `/api/contracts/{id}/return` | **Clôture** : retour véhicule |
| `DELETE` | `/api/contracts/{id}` | **Suppression logique** (204 No Content) |
| `GET` | `/api/contracts/{id}/pdf` | PDF binaire |

### Règles métier — Création

1. La voiture doit exister et être **`AVAILABLE`**
2. Le client doit exister
3. À l’enregistrement : statut contrat **`ACTIVE`**, voiture passée en **`RENTED`**

### Règles métier — Retour (`/return`)

1. Uniquement si statut **`ACTIVE`**
2. `actualReturnDatetime` = maintenant
3. Statut contrat → **`COMPLETED`**
4. Voiture → **`AVAILABLE`**

### Règles métier — Mise à jour

1. Si contrat **ACTIVE** : **interdiction de changer de voiture** (`carId` doit rester le même)
2. Si contrat **ACTIVE** après MAJ : la voiture liée reste **`RENTED`**

### Règles métier — Suppression

1. **Interdit** si statut **ACTIVE** → `Impossible : terminez d'abord le contrat`
2. Sinon : `deleted = true` (le contrat disparaît des listes `findByDeletedFalse`)

### Réponse `ContractResponse`

Réponse très complète pour l’écran détail Flutter : infos voiture, client (y compris adresses, permis, CIN, téléphone), conducteur supplémentaire, dates, grille tarifaire, paiements, dommages, `createdAt`, `status`.

---

## 6. Backend — Maintenance (`/api/maintenance`)

### Entité `Maintenance`

| Champ | Description |
|-------|-------------|
| `car` | Voiture concernée |
| `type` | Type d’intervention |
| `description` | Texte libre |
| `startDate`, `endDate` | Période |
| `cost` | Coût |

### Endpoints

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/api/maintenance` | Toutes les maintenances |
| `GET` | `/api/maintenance/car/{carId}` | Par voiture |
| `POST` | `/api/maintenance` | Création |
| `PUT` | `/api/maintenance/{id}` | Mise à jour |

> **Note** : pas d’endpoint `DELETE` côté API.

### Impact sur le statut voiture

| Situation | Statut voiture |
|-----------|----------------|
| `endDate` est **null** (maintenance en cours) | `MAINTENANCE` |
| `endDate` renseignée et voiture était `MAINTENANCE` | repasse à `AVAILABLE` |

---

## 7. Backend — Tableau de bord (`/api/dashboard`)

### `GET /api/dashboard/stats`

Retourne `DashboardResponse` :

| Champ | Signification |
|-------|---------------|
| `totalCars` | Nombre total de voitures |
| `available` | Compte `AVAILABLE` |
| `rented` | Compte `RENTED` |
| `maintenance` | Compte `MAINTENANCE` |

### `GET /api/dashboard/calendar`

Liste des **contrats actifs** (`ACTIVE`) — même données que `/api/contracts/active`, format `ContractResponse`.

### `GET /api/dashboard/alerts`

Alertes calculées sur **toutes les voitures** :

| Type | Condition | Sévérité |
|------|-----------|----------|
| `INSURANCE` | Assurance expire dans ≤ **30 jours** ou déjà expirée | `MEDIUM` si ≤ 30 j, `HIGH` si date passée |
| `INSPECTION` | Contrôle technique dans ≤ **30 jours** ou dépassé | idem |
| `OIL_CHANGE` | Dernière vidange > **180 jours** | `MEDIUM` |

Chaque alerte : `type`, `carId`, `carLabel`, `message`, `severity`, `dueDate`.

---

## 8. Backend — Génération PDF

### Flux

```
GET /api/contracts/{id}/pdf
  → PdfService.generateContractPdf(id)
  → ContractRepository.findDetailedById (JOIN FETCH car + client)
  → Apache PDFBox 3.0.3 : 1 page A4
  → byte[] renvoyé (Content-Type: application/pdf, inline)
```

### Contenu actuel du PDF (version simplifiée)

Le PDF généré est un **résumé** (pas le formulaire complet affiché dans Flutter) :

- Titre : « BOUSSELHA CARS - CONTRAT DE LOCATION »
- Client, véhicule (marque + immatricule)
- Date de départ, retour prévu
- Total général

Les sections détaillées (dommages, observation légale, signature) ne sont **pas** encore dans le PDF programmatique ; elles peuvent exister en base mais l’UI détail Flutter les masque volontairement (réservées au futur PDF complet).

---

## 9. Backend — Erreurs & sécurité

### `GlobalExceptionHandler`

| Exception | HTTP | Corps |
|-----------|------|-------|
| `ResourceNotFoundException` | 404 | `{ "error": "..." }` |
| `MethodArgumentNotValidException` | 400 | `{ "error": "Validation failed", "fields": {...} }` |
| `IllegalArgumentException` | 400 | `{ "error": "..." }` |
| Autres | 500 | `{ "error": "..." }` |

### Flutter — interception Dio

`DioClient` relaie le champ `error` de la réponse JSON dans le message d’exception Dio.

---

## 10. Frontend — Vue d’ensemble

### Stack

| Élément | Détail |
|---------|--------|
| État global | **Riverpod** (`FutureProvider`, `Provider`) |
| HTTP | **Dio** — base `http://localhost:8080/api` |
| UI | **Material 3**, application **desktop** (Windows cible principale) |
| Packages notables | `intl` (dates), `url_launcher` (PDF navigateur), `file_picker` (images voitures) |

### Fichiers clés

| Fichier | Rôle |
|---------|------|
| `lib/main.dart` | Point d’entrée, thème, `HomeShell` |
| `lib/presentation/home_shell.dart` | Navigation latérale + pages |
| `lib/shared/providers/app_providers.dart` | Providers repositories & données |
| `lib/data/repositories/*.dart` | Appels API par domaine |
| `lib/core/network/dio_client.dart` | Configuration Dio |

---

## 11. Frontend — Navigation & shell

### `HomeShell`

- **NavigationRail** (5 onglets) : Dashboard, Voitures, Clients, Contrats, Maintenance
- **AppBar globale** : titre `BOUSSELHA CARS - {module}` pour tous les onglets **sauf Contrats** (l’écran Contrats a sa propre AppBar intégrée)
- Contenu : `IndexedStack` (état conservé entre onglets)

---

## 12. Frontend — Dashboard

**Fichier** : `lib/presentation/dashboard/dashboard_screen.dart`

### Fonctionnalités

1. **Cartes statistiques** (4 indicateurs colorés)
   - Total voitures, Disponibles, Louées, En maintenance
   - Source : `GET /api/dashboard/stats`

2. **Calendrier des locations actives** (panneau gauche)
   - Liste : voiture, client, dates départ → retour prévu
   - Source : `GET /api/dashboard/calendar`

3. **Alertes** (panneau droit)
   - Icône rouge/orange selon `severity` (`HIGH` / autre)
   - Type, message, date d’échéance
   - Source : `GET /api/dashboard/alerts`

4. **États UI** : chargement (`CircularProgressIndicator`), erreur réseau affichée

---

## 13. Frontend — Voitures

**Fichier** : `lib/presentation/cars/car_list_screen.dart`

### Liste des voitures

| Action | Détail |
|--------|--------|
| Affichage | Carte par voiture : vignette (Hero), marque, immatricule, carburant, prochaine visite, **chip statut** coloré |
| Ajouter | Dialogue formulaire (`showCarFormDialog`) → `POST /api/cars` (multipart + image optionnelle) |
| Modifier | Menu contextuel ou depuis le détail → `PUT /api/cars/{id}` |
| Supprimer | Confirmation → `DELETE /api/cars/{id}` |
| Rafraîchir | `ref.invalidate(carsProvider)` |
| Ouvrir détail | Navigation animée (`carDetailRoute` : fade + slide + **Hero** image) |

### Formulaire voiture

Champs : marque, matricule, carburant (Essence/Diesel), statut (Disponible / Louée / Maintenance), dates visite/vidange/assurance (`YYYY-MM-DD`), **photo** (sélection fichier locale).

Images affichées via URL publique : `http://localhost:8080` + `imageUrl` retourné par l’API.

### Écran détail voiture (`CarDetailScreen`)

| Zone | Contenu |
|------|---------|
| En-tête | `SliverAppBar` expansé, photo pleine largeur (Hero), titre, badge statut |
| Infos | Cartes premium : marque, immatricule, carburant, dates entretien, statut |
| Alertes | Chips si visite technique ou assurance dans les **30 prochains jours** |
| Timeline contrats | Contrats de la voiture (`GET /api/contracts?carId=`) triés par date départ, cartes timeline |
| Actions flottantes | **Modifier**, **Supprimer** (FAB) |

---

## 14. Frontend — Clients

**Fichier** : `lib/presentation/clients/client_list_screen.dart`

### Liste

| Action | Détail |
|--------|--------|
| Affichage | Avatar **initiales** + couleur dérivée du nom, nom, téléphone, CIN, n° permis |
| Ajouter | Formulaire en **2 sections** (FR locataire / AR conducteur supplémentaire) |
| Détail | Clic → `ClientDetailScreen` |
| Rafraîchir | Invalidation `clientsProvider` |

### Formulaire client (création / édition)

**Section 1 — Locataire** : nom, date naissance, adresses Maroc/étranger, profession, permis, CIN, passeport (+ date), téléphone.

**Section 2 — Conducteur supplémentaire** : nom, permis, date délivrance, passeport.

Champs obligatoires côté UI : nom, CIN, téléphone (aligné backend `@NotBlank`).

### Écran détail client

- Affichage structuré de toutes les informations
- Boutons **Modifier** / **Supprimer**
- Suppression bloquée côté serveur si contrats actifs (message d’erreur API affiché)

---

## 15. Frontend — Contrats

**Fichier** : `lib/presentation/contracts/contract_list_screen.dart`

### Liste (design entreprise)

- AppBar marine : **BOUSSELHA CARS — Contrats**
- Bouton doré **Nouveau contrat**, rafraîchir
- Cartes : icône document, titre `Marque - Immat — Client`, sous-titre dates `jj/mm/aaaa`, badge statut, montant en **or**, chevron

### Création / modification (dialogue unifié `_showUnifiedContractSheet`)

| Élément | Détail |
|---------|--------|
| Voiture | Liste disponibles ; en édition d’un contrat **ACTIVE**, voiture **verrouillée** |
| Client | Liste complète |
| Dates | Tableau J / M / A / H / mn (départ, retour prévu, retour définitif, durée) |
| Tarifs | Heures, jours, semaines, mois, assurance — calcul lignes + TOTAL + supplément + TOTAL général |
| Paiement | Espèces, chèque, caution |
| Lieux | Départ / retour |
| Création | `POST /api/contracts` |
| Modification | `PUT /api/contracts/{id}` (+ conservation champs dommages/conducteur existants) |

### Écran détail contrat (`ContractDetailScreen`)

**Sections affichées** (design cartes marine/doré) :

1. Véhicule  
2. Dates  
3. Locataire (المكتري)  
4. Conducteur supplémentaire  
5. Grille tarifaire  
6. Paiement (الأداء)  

**Non affiché** (réservé PDF futur) : section dommages, observation légale, signature, « Fait à Tanger ».

**PDF**

| Bouton | Comportement |
|--------|--------------|
| Enregistrer PDF | Ouvre l’URL dans le navigateur (`launchUrl`) |
| Télécharger PDF | `GET` bytes → fichier dans dossier **Downloads** |

**Barre d’actions fixe en bas**

| Bouton | Comportement |
|--------|--------------|
| Terminer | Si `ACTIVE` : dialogue → `PUT .../return` → SnackBar vert ; si `COMPLETED` : désactivé « Contrat terminé » |
| Modifier | Ouvre le formulaire → SnackBar bleu après succès |
| Supprimer | Si `ACTIVE` : message d’erreur ; sinon dialogue → `DELETE` → retour liste, SnackBar rouge |

### Badges statut (UI)

| Statut | Style |
|--------|-------|
| `ACTIVE` | Vert |
| `COMPLETED` | Bleu |
| `CANCELLED` | Rouge |

---

## 16. Frontend — Maintenance

**Fichier** : `lib/presentation/maintenance/maintenance_list_screen.dart`

| Action | Détail |
|--------|--------|
| Liste | Type, voiture, dates début/fin, coût MAD |
| Ajouter | Dialogue : voiture, type, dates, description, coût → `POST /api/maintenance` |
| Rafraîchir | Invalidation `maintenanceProvider` |

**Non implémenté dans Flutter** : modification d’une maintenance (`PUT` existe côté API), suppression, filtre par voiture via `/maintenance/car/{id}`.

---

## 17. Matrice Backend ↔ Frontend

| Fonctionnalité API | Utilisé Flutter | Écran / remarque |
|--------------------|-----------------|------------------|
| `GET /cars` | Oui | Liste voitures |
| `GET /cars/available` | Oui | Création contrat, édition contrat |
| `GET /cars/rented` | Non | — |
| `GET /cars/maintenance` | Non | — |
| `GET /cars/{id}` | Non | Détail utilise données liste |
| `GET /cars/{id}/history` | Non | Timeline utilise `GET /contracts?carId=` |
| `POST/PUT/DELETE /cars` | Oui | Formulaire voiture |
| `GET/POST/PUT/DELETE /clients` | Oui | Liste + détail client |
| `GET /clients/{id}` | Oui | Détail client |
| `GET /contracts` | Oui | Liste contrats |
| `GET /contracts?carId=` | Oui | Détail voiture (timeline) |
| `GET /contracts/{id}` | Oui | Détail contrat |
| `GET /contracts/active` | Non direct | Dashboard utilise `/dashboard/calendar` |
| `POST /contracts` | Oui | Nouveau contrat |
| `PUT /contracts/{id}` | Oui | Modifier contrat |
| `PUT /contracts/{id}/return` | Oui | Terminer contrat |
| `DELETE /contracts/{id}` | Oui | Supprimer (soft) |
| `GET /contracts/{id}/pdf` | Oui | PDF |
| `GET/POST /maintenance` | Oui | Liste + ajout |
| `PUT /maintenance/{id}` | Non | — |
| `GET /maintenance/car/{id}` | Non | — |
| `GET /dashboard/stats` | Oui | Dashboard |
| `GET /dashboard/calendar` | Oui | Dashboard |
| `GET /dashboard/alerts` | Oui | Dashboard |

---

## 18. Limites connues

1. **Pas d’authentification** ni gestion des rôles.
2. **PDF simplifié** : ne reflète pas toutes les sections du contrat affichées dans l’app.
3. **Historique voiture API** (`/cars/{id}/history`) non consommé par Flutter.
4. **Maintenance** : pas d’édition ni suppression dans l’UI.
5. **Filtres liste** : pas de recherche texte / tri avancé sur les listes.
6. **Images voitures** : URL en `localhost:8080` — à adapter si déploiement distant.
7. **Contrat CANCELLED** : peu ou pas de flux UI dédié pour annuler un contrat (enum existe côté backend).

---

## Démarrage rapide

Voir le fichier racine [`README.md`](README.md) pour les commandes `mvn spring-boot:run` et `flutter run -d windows`.

---

*Document généré à partir de l’analyse du code source du dépôt BOUSSELHA CARS.*
