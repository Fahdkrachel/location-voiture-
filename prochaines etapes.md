# 🚗 BOUSSELHA CARS — Documentation Projet

> Documentation des prochaines étapes pour passer du MVP vers le produit complet conforme au cahier des charges.

Voici une description textuelle des besoins fonctionnels du logiciel **BOUSSELHA CARS** :

---

## Gestion de la Flotte de Véhicules

Le système doit permettre à l'administrateur d'ajouter, modifier, consulter et supprimer des véhicules. Chaque véhicule est décrit par sa marque, son type de carburant (Essence ou Diesel), son numéro d'immatriculation, ainsi que des dates clés de suivi technique : la date du prochain contrôle technique, la date de la dernière vidange d'huile et la date d'expiration de l'assurance. Chaque véhicule possède un statut dynamique qui évolue automatiquement selon son utilisation : Disponible, Loué ou En Maintenance. Le système doit également afficher un historique complet par véhicule, présentant en ordre chronologique toutes les locations et les interventions de maintenance effectuées sur ce véhicule.

---

## Gestion des Clients

Le système doit permettre d'enregistrer et de gérer les fiches clients. Chaque fiche contient les informations personnelles du client : nom complet, date de naissance, adresse au Maroc et à l'étranger, profession, numéro de permis de conduire et lieu de délivrance, numéro de CIN, numéro de passeport et date de délivrance, ainsi que le numéro de téléphone. Ces informations sont ensuite réutilisées automatiquement lors de la création d'un contrat de location.

---

## Gestion des Contrats de Location

C'est le cœur du système. L'administrateur doit pouvoir créer un contrat de location complet qui reproduit fidèlement le contrat physique officiel de Bousselha Cars. Un contrat relie un véhicule à un client et couvre toutes les informations nécessaires à une location : le lieu de départ et de retour du véhicule, les dates et heures de départ et de retour prévues et réelles, la durée totale de la location, et les informations d'un éventuel conducteur supplémentaire avec son permis et passeport. Le contrat intègre une grille tarifaire complète avec des prix par heure, par jour, par semaine et par mois, avec ou sans assurance, ainsi que le calcul automatique du montant total, des suppléments éventuels et du total général. Le règlement peut être enregistré en plusieurs modes : espèces, chèque et caution. Le système doit aussi permettre d'enregistrer l'état du véhicule au départ et au retour, avec identification des dommages constatés (éraflures, bosses, manques) et leur localisation sur un schéma du véhicule. Lorsqu'un véhicule est loué, son statut passe automatiquement à "Loué", et revient à "Disponible" lors de l'enregistrement du retour.

---

## Génération de Contrats PDF

Le système doit générer automatiquement un document PDF à partir des données saisies dans le contrat. Ce PDF doit être une reproduction fidèle du contrat physique officiel de l'entreprise, avec l'en-tête Bousselha Cars (logo, adresse, téléphones, e-mail), le titre bilingue en français et en arabe, toutes les sections du contrat remplies avec les données du client et du véhicule, le tableau tarifaire, le schéma du véhicule avec les dommages marqués, les zones de signature et la mention "Fait à Tanger, le ...". Ce PDF doit être directement imprimable par l'administrateur depuis l'application.

---

## Gestion de la Maintenance

Le système doit permettre d'enregistrer toutes les interventions de maintenance effectuées sur les véhicules : le type d'intervention, une description, la date de début et de fin, ainsi que le coût. Lorsqu'un véhicule est en maintenance, son statut est mis à jour en conséquence et il n'apparaît plus comme disponible à la location.

---

## Tableau de Bord

Le système doit offrir une vue synthétique et en temps réel de l'activité de l'entreprise. Cette vue affiche des indicateurs clés : le nombre total de véhicules, le nombre de véhicules disponibles, loués et en maintenance. Un calendrier interactif montre visuellement toutes les locations en cours et à venir avec le nom du véhicule, le nom du client et la plage de dates. Le tableau de bord doit également afficher des alertes automatiques pour signaler les véhicules dont l'assurance est expirée ou proche de l'expiration, ceux dont la vidange est en retard ou dont le contrôle technique approche.

---

## Alertes et Suivi Documentaire

Le système doit surveiller en permanence les échéances administratives et techniques de chaque véhicule et notifier l'administrateur via des alertes visibles sur le tableau de bord, afin d'éviter toute irrégularité dans la gestion du parc automobile.

---

## 📋 Table des matières

1. [Vérifications MVP](#1-vérifications-mvp)
2. [Améliorations fonctionnelles](#2-améliorations-fonctionnelles-priorité-élevée)
3. [Dashboard & Admin](#3-améliorations-dashboard--admin)
4. [Qualité & Sécurité](#4-qualité--sécurité--cohérence)

---

## 1. Vérifications MVP

### ✅ Valider le flux PDF

- Génération via `GET /api/contracts/{id}/pdf` fonctionne sans erreur de session
  - Corrigé via `findDetailedById` dans `ContractRepository` et `PdfService`
- Côté Flutter, depuis `contract_list_screen.dart`, tester :
  - **"Voir PDF"** → ouverture navigateur automatique via `url_launcher`
  - **"Télécharger PDF"** → sauvegarde locale via `downloadContractPdf` dans `contract_repository.dart`

### ✅ Valider les statuts dynamiques

| Action | Statut voiture |
|--------|---------------|
| Création contrat | `RENTED` → via `ContractService.create` |
| Retour contrat | `AVAILABLE` → via `ContractService.registerReturn` |
| Maintenance sans date fin | `MAINTENANCE` |
| Maintenance avec date fin | `AVAILABLE` → via `MaintenanceService` |

### ✅ Valider le dashboard

```
GET /api/dashboard/stats
GET /api/dashboard/calendar
GET /api/dashboard/alerts
```

---

## 2. Améliorations fonctionnelles (priorité élevée)

### 2.1 Contrat "officiel" — Formulaire complet + calcul

Actuellement l'UI permet de créer un contrat avec un sous-ensemble (voiture/client/dates/total/lieux).

#### À implémenter côté UI (`contract_list_screen.dart` ou écran dédié "Contrat") :

- **Conducteur supplémentaire** : nom + permis + passeport
- **Données départ/retour** : dates/lieux prévus vs réels
- **Grille tarifaire complète** :
  - Prix heure / jour / semaine / mois
  - Avec ou sans assurance
- **Suppléments + total général** (calcul automatique, pas saisie libre)
- **Paiements** : espèces / chèque / caution (stockage + affichage)

#### À implémenter côté backend :

- Étendre `ContractRequest` pour permettre le calcul (ex: fournir heures/jours ou dates)
- Mettre à jour `ContractService.apply(...)` pour calculer :
  - `totalPrice`
  - `supplement`
  - `totalGeneral`

---

### 2.2 PDF "fidèle" — Gabarit officiel bilingue + signatures

Le `PdfService` actuel génère un PDF simplifié. Prochaine étape : reconstruire le gabarit officiel.

#### Approche recommandée avec PDFBox :

1. Utiliser un **template PDF statique** (contrat officiel vierge) dans les ressources backend
2. Ouvrir le template et overlay les champs :
   - En-tête BOUSSELHA CARS (logo + contacts + adresse)
   - Titre FR/AR
   - Tableau tarifaire + montants calculés
   - Zones de signature
   - Mention *"Fait à Tanger, le …"*

#### Fichier à modifier :
```
bousselha-backend/src/main/java/com/bousselha/application/service/PdfService.java
```

---

### 2.3 Dommages voiture — Schéma + localisation + stockage

#### Modèle de données :
- Ajouter un champ `damages` (JSON) ou une table `contract_damages`
- Coordonnées / identifiant de zone (ex: `"front-left"`, `"hood"`, etc.)

#### UI :
- Visualiser le schéma (image du véhicule)
- Permettre de marquer des zones et le type de dommage

#### PDF :
- Réafficher le schéma avec les marques de dommages

---

## 3. Améliorations Dashboard / Admin

### 3.1 Calendrier interactif

Aujourd'hui le dashboard affiche une liste. Prochaine étape :

- Ajouter une vraie vue calendrier (ex: package `table_calendar` côté Flutter)
- Sourcer les périodes depuis `GET /api/dashboard/calendar`
- Permettre clic sur une location pour détails + PDF

### 3.2 Alertes sophistiquées

Alertes actuelles : assurance / inspection / vidange. Prochaine étape :

- Ajuster les seuils (ex: "proche expiration" = 15 jours vs 30)
- Option "historiser / marquer comme traité"
- *(Optionnel)* Notifier hors UI (mail/SMS) plus tard

---

## 4. Qualité / Sécurité / Cohérence

- **Bloquer** la saisie du champ `car.status` côté UI (statut piloté uniquement par la logique métier)
- **Contrôler** la validité de la période contrat :
  - Incohérences date/heure
  - Chevauchement de locations sur la même voiture
- **Nettoyage Git** :
  - `target/` et `*.class` ne doivent pas être committés
  - Vérifier que `.gitignore` les exclut bien

---

## ❓ Prochaine étape — Choisir la priorité

| N° | Fonctionnalité |
|----|---------------|
| 1️⃣ | Contrat complet (formulaire + calcul grille tarifaire + paiements) |
| 2️⃣ | PDF fidèle (gabarit officiel + champs + signatures) |
| 3️⃣ | Dommages voiture sur schéma (UI + stockage + rendu PDF) |

> Indiquez le numéro choisi pour démarrer immédiatement sur la meilleure trajectoire.

---

*BOUSSELHA CARS — Système de gestion de location de voitures*
