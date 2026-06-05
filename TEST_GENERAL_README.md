# BOUSSELHA CARS - README de test general

Ce document sert de guide QA pour tester toutes les fonctionnalites principales du projet BOUSSELHA CARS : backend Spring Boot, application Flutter desktop, scenarios metier, cas limites et exceptions attendues.

Date de reference pour les exemples de dates : 2026-06-05.

---

## 1. Objectif du test

Verifier que le systeme permet de gerer correctement :

- les voitures ;
- les clients ;
- les contrats de location ;
- le cycle de vie des contrats ;
- les maintenances ;
- le dashboard ;
- les alertes ;
- les revenus et depenses ;
- le calendrier de disponibilite ;
- la generation PDF ;
- les erreurs metier et validations.

---

## 2. Preparation avant test

### 2.1 Lancer le backend

Depuis le dossier backend :

```bash
cd bousselha-backend
mvn spring-boot:run
```

Verifier :

```text
http://localhost:8080/swagger-ui.html
```

### 2.2 Lancer Flutter Windows

Depuis le dossier Flutter :

```bash
cd bousselha-flutter
flutter pub get
flutter run -d windows
```

### 2.3 Verifier la base de donnees

La base doit etre disponible :

```text
bousselha_db
```

Verifier que `application.properties` pointe vers la bonne base MySQL.

### 2.4 Jeu de donnees conseille

Creer au minimum :

| Type | Exemple |
|---|---|
| Voiture 1 | Dacia Logan, ESSENCE, `12345-B-67` |
| Voiture 2 | Renault Clio, DIESEL, `98765-A-12` |
| Voiture 3 | Hyundai i10, ESSENCE, `45678-C-90` |
| Client 1 | Client test contrat actif |
| Client 2 | Client test contrat termine |

Pour tester les alertes, garder une voiture avec :

```text
insuranceExpiryDate = 2026-06-15
nextInspectionDate = 2026-06-20
lastOilChangeDate = 2025-11-01
```

---

## 3. Tests backend rapides via Swagger

URL Swagger :

```text
http://localhost:8080/swagger-ui.html
```

Tester les familles d'API :

| Module | Endpoint principal |
|---|---|
| Voitures | `/api/cars` |
| Clients | `/api/clients` |
| Contrats | `/api/contracts` |
| Maintenance | `/api/maintenance` |
| Dashboard | `/api/dashboard/stats`, `/api/dashboard/alerts`, `/api/dashboard/calendar` |
| Finance | `/api/financial/income`, `/api/financial/expenses` |

Resultat attendu :

- les appels valides retournent `200`, `201` ou `204` selon le cas ;
- les erreurs metier retournent `400` avec `{ "error": "..." }` ;
- les objets inexistants retournent `404` avec `{ "error": "..." }`.

---

## 4. Tests du module Voitures

### 4.1 Ajouter une voiture

Chemin UI :

```text
Voitures -> Ajouter voiture
```

Remplir :

```text
Marque = Dacia Logan
Matricule = 12345-B-67
Carburant = ESSENCE
Prochaine visite = 2026-12-01
Derniere vidange = 2026-03-01
Expiration assurance = 2026-12-31
Photo = fichier jpg/png optionnel
```

Resultat attendu :

- la voiture apparait dans la liste ;
- le statut est `Disponible` ;
- l'image apparait si elle a ete choisie ;
- l'API `GET /api/cars` retourne la voiture.

### 4.2 Modifier une voiture

Chemin UI :

```text
Voitures -> menu de la carte -> Modifier
```

Changer :

```text
Marque
Matricule
Dates assurance / visite / vidange
Photo
```

Resultat attendu :

- les nouvelles donnees s'affichent apres enregistrement ;
- le statut ne doit pas etre modifie manuellement par ce formulaire ;
- l'image doit etre visible apres rafraichissement des donnees.

### 4.3 Supprimer une voiture sans contrat ouvert

Precondition :

- voiture sans contrat `IN_PROGRESS` ou `ACTIVE`.

Action :

```text
Voitures -> menu -> Supprimer
```

Resultat attendu :

- la voiture disparait ;
- `GET /api/cars/{id}` retourne `404`.

### 4.4 Exception : supprimer une voiture avec contrat ouvert

Precondition :

- voiture avec contrat `IN_PROGRESS` ou `ACTIVE`.

Action :

```text
Supprimer la voiture
```

Resultat attendu :

```json
{
  "error": "Impossible : voiture avec contrat en cours"
}
```

La voiture reste visible.

### 4.5 Exception : creer une voiture avec statut non disponible

Via API, envoyer `status = RENTED` ou `MAINTENANCE` a la creation.

Resultat attendu :

```json
{
  "error": "NEW_CAR_MUST_BE_AVAILABLE"
}
```

### 4.6 Exception : image non supportee

Uploader un fichier `.gif`, `.pdf` ou autre extension non autorisee.

Resultat attendu :

```json
{
  "error": "Unsupported image format"
}
```

---

## 5. Tests du module Clients

### 5.1 Creation client via nouveau contrat

Dans l'UI actuelle, le client est surtout cree via :

```text
Contrats -> Nouveau contrat -> Etape 1 Client
```

Remplir :

```text
Nom complet = Client Test
Telephone = 0600000000
CIN = optionnel
Permis = optionnel
Passeport = optionnel
Adresse = optionnel
```

Resultat attendu :

- au moment de valider le contrat, le client est cree ;
- il apparait dans la liste Clients ;
- le detail client affiche les champs saisis.

### 5.2 Modifier un client

Chemin UI :

```text
Clients -> ouvrir client -> Modifier
```

Resultat attendu :

- les nouvelles informations sont conservees ;
- les contrats deja crees restent lies au client.

### 5.3 Exception : supprimer un client avec contrat ouvert

Via API :

```http
DELETE /api/clients/{id}
```

Si le client a un contrat `IN_PROGRESS` ou `ACTIVE`, resultat attendu :

```json
{
  "error": "Impossible de supprimer : client a des contrats en cours"
}
```

---

## 6. Tests du module Contrats

### 6.1 Creer un nouveau contrat

Chemin UI :

```text
Contrats -> Nouveau contrat
```

Etape 1 : client

```text
Nom complet = Client Contrat Test
Telephone = 0611111111
```

Etape 2 : contrat

```text
Voiture = voiture disponible
Depart = 2026-06-05 10:00
Retour prevu = 2026-06-08 10:00
Duree = 3 jours
Total general = 1200
Paiement cash = 1200
```

Resultat attendu :

- contrat cree avec statut `IN_PROGRESS` ;
- voiture reste `AVAILABLE` tant que le contrat n'est pas active ;
- le contrat apparait dans la liste Contrats ;
- le client apparait dans la liste Clients.

### 6.2 Exception : creer contrat sur voiture non disponible

Precondition :

- voiture `RENTED` ou `MAINTENANCE`.

Action :

```text
Creer un contrat avec cette voiture
```

Resultat attendu :

```json
{
  "error": "Car is not available for rental: ..."
}
```

### 6.3 Exception : creer deux contrats ouverts sur la meme voiture

Precondition :

- voiture avec contrat `IN_PROGRESS` ou `ACTIVE`.

Action :

```text
Creer un deuxieme contrat sur la meme voiture
```

Resultat attendu :

```json
{
  "error": "Car already has an open contract: ..."
}
```

### 6.4 Activer un contrat

Precondition :

- contrat `IN_PROGRESS`.

Action UI :

```text
Contrat detail -> Activer
```

Resultat attendu :

- contrat passe a `ACTIVE` ;
- voiture passe a `RENTED` ;
- un revenu est cree dans `income_records` ;
- le dashboard augmente le compteur `Louees` ;
- `GET /api/financial/income` contient une ligne liee au contrat.

### 6.5 Exception : activer un contrat qui n'est pas IN_PROGRESS

Action API :

```http
PATCH /api/contracts/{id}/status
{ "status": "ACTIVE" }
```

Sur un contrat deja `ACTIVE` ou `COMPLETED`.

Resultat attendu :

```json
{
  "error": "Seul un contrat IN_PROGRESS peut passer en ACTIVE"
}
```

### 6.6 Terminer un contrat

Precondition :

- contrat `ACTIVE`.

Action UI :

```text
Contrat detail -> Terminer
```

Ou API :

```http
PUT /api/contracts/{id}/return
```

Resultat attendu :

- contrat passe a `COMPLETED` ;
- `actualReturnDatetime` est renseigne avec la date/heure actuelle ;
- voiture repasse `AVAILABLE` ;
- revenu conserve, pas de doublon.

### 6.7 Exception : terminer un contrat non ACTIVE

Action :

```http
PATCH /api/contracts/{id}/status
{ "status": "COMPLETED" }
```

Sur un contrat `IN_PROGRESS` ou `COMPLETED`.

Resultat attendu :

```json
{
  "error": "Seul un contrat ACTIVE peut etre termine"
}
```

### 6.8 Modifier un contrat

Precondition :

- contrat `IN_PROGRESS`.

Action :

```text
Contrat detail -> Modifier
```

Resultat attendu :

- modification acceptee ;
- changement de voiture accepte seulement si la nouvelle voiture est disponible.

### 6.9 Exception : modifier un contrat ACTIVE ou COMPLETED

Resultat attendu :

```json
{
  "error": "Impossible de modifier un contrat en location ou deja termine"
}
```

### 6.10 Supprimer un contrat

Cas autorise :

- contrat `COMPLETED`.

Resultat attendu :

- le contrat est supprime logiquement (`deleted = true`) ;
- il disparait de la liste ;
- si le client n'a plus aucun contrat actif ou visible, il peut etre retire automatiquement.

Cas interdit :

- contrat `ACTIVE`.

Resultat attendu :

```json
{
  "error": "Impossible : terminez le contrat avant de le supprimer"
}
```

---

## 7. Tests PDF contrat

### 7.1 Generer PDF

Precondition :

- contrat `ACTIVE` ou `COMPLETED`.

Action UI :

```text
Contrat detail -> Telecharger PDF
```

Resultat attendu :

- un fichier PDF est cree dans `Downloads` ;
- le nom contient le client et le matricule ;
- le PDF contient au minimum : client, voiture, dates, paiement, sections du contrat.

### 7.2 Exception : PDF sur contrat IN_PROGRESS

Action API :

```http
GET /api/contracts/{id}/pdf
```

Sur un contrat `IN_PROGRESS`.

Resultat attendu :

```json
{
  "error": "Le PDF est disponible uniquement apres activation du contrat..."
}
```

---

## 8. Tests du module Maintenance

### 8.1 Creer une maintenance

Chemin UI :

```text
Maintenance -> Ajouter maintenance
```

Remplir :

```text
Voiture = voiture disponible
Type = Vidange
Date debut = 2026-06-05
Date fin = vide
Cout = 500
Description = Vidange complete
```

Resultat attendu :

- maintenance creee en `IN_PROGRESS` ;
- voiture passe en `MAINTENANCE` si la maintenance est en cours ;
- une depense est creee dans `expense_records` ;
- dashboard met a jour `Dépenses (Expense)`.

### 8.2 Terminer une maintenance

Action UI :

```text
Maintenance -> bouton Terminer
```

Resultat attendu :

- maintenance passe a `COMPLETED` ;
- `endDate` est renseignee si elle etait vide ;
- voiture repasse `AVAILABLE` s'il n'y a pas d'autre maintenance en cours ;
- la depense reste visible.

### 8.3 Exception : terminer une maintenance deja terminee

Resultat attendu :

```json
{
  "error": "MAINTENANCE_ALREADY_COMPLETED"
}
```

### 8.4 Exception : modifier une maintenance pour la passer COMPLETED directement

Via `PUT /api/maintenance/{id}` avec `status = COMPLETED`.

Resultat attendu :

```json
{
  "error": "USE_COMPLETE_ENDPOINT"
}
```

### 8.5 Supprimer une maintenance

Action UI :

```text
Maintenance -> icone supprimer
```

Resultat attendu :

- maintenance supprimee ;
- statut voiture reconcilie ;
- les donnees se rafraichissent.

---

## 9. Tests Dashboard

### 9.1 Statistiques

Verifier les cartes :

```text
Total voitures
Disponibles
Louees
Maintenance
Revenus
Depenses
```

Scenarios :

- ajouter voiture -> Total voitures augmente ;
- activer contrat -> Louees augmente, Disponibles diminue ;
- terminer contrat -> Louees diminue, Disponibles augmente ;
- creer maintenance en cours -> Maintenance augmente ;
- terminer maintenance -> Maintenance diminue.

### 9.2 Revenus

Precondition :

- contrat avec `totalGeneral > 0`.

Action :

```text
Activer le contrat
```

Resultat attendu :

- dashboard `Revenus` augmente ;
- ecran detail Income affiche une ligne `Contrat #id - client`.

### 9.3 Depenses

Precondition :

- maintenance avec cout > 0.

Action :

```text
Creer ou modifier maintenance
```

Resultat attendu :

- dashboard `Depenses` augmente ;
- ecran detail Expense affiche la maintenance.

---

## 10. Tests des alertes Dashboard

Les alertes viennent de :

```http
GET /api/dashboard/alerts
```

Elles dependent uniquement des dates de voiture.

### 10.1 Assurance

Pour la date de reference 2026-06-05 :

| Valeur `insuranceExpiryDate` | Resultat attendu |
|---|---|
| `2026-06-20` | alerte `INSURANCE`, `MEDIUM` |
| `2026-06-01` | alerte `INSURANCE`, `HIGH` |
| `2026-08-01` | pas d'alerte |

### 10.2 Visite technique

| Valeur `nextInspectionDate` | Resultat attendu |
|---|---|
| `2026-06-25` | alerte `INSPECTION`, `MEDIUM` |
| `2026-06-01` | alerte `INSPECTION`, `HIGH` |
| `2026-09-01` | pas d'alerte |

### 10.3 Vidange

Le seuil est 180 jours. Pour 2026-06-05, une vidange avant 2025-12-07 doit declencher.

| Valeur `lastOilChangeDate` | Resultat attendu |
|---|---|
| `2025-11-01` | alerte `OIL_CHANGE`, `MEDIUM` |
| `2026-02-01` | pas d'alerte |

---

## 11. Tests Calendrier

Chemin UI :

```text
Calendrier
```

### 11.1 Voiture disponible

Choisir une date sans contrat et sans maintenance.

Resultat attendu :

- voiture affichee comme disponible.

### 11.2 Voiture louee

Precondition :

- contrat couvrant la date choisie.

Resultat attendu :

- voiture non disponible dans la liste des voitures disponibles ;
- API `/api/cars/availability?date=YYYY-MM-DD` retourne `RENTED`.

### 11.3 Voiture en maintenance

Precondition :

- maintenance couvrant la date choisie.

Resultat attendu :

- API availability retourne `MAINTENANCE` ;
- la voiture n'apparait pas dans `/availability/available`.

---

## 12. Tests financiers

### 12.1 Income

Endpoint :

```http
GET /api/financial/income
```

Scenarios :

- activer un contrat avec total `1200` ;
- verifier une ligne `CONTRACT` avec `amount = 1200` ;
- reactiver impossible, donc pas de doublon ;
- terminer contrat ne doit pas creer un deuxieme revenu.

### 12.2 Expense

Endpoint :

```http
GET /api/financial/expenses
```

Scenarios :

- creer maintenance avec cout `500` ;
- verifier une ligne `MAINTENANCE` avec `amount = 500` ;
- modifier cout maintenance -> la ligne expense doit etre mise a jour.

---

## 13. Tests des exceptions globales

### 13.1 Ressource inexistante

Exemples :

```http
GET /api/cars/999999
GET /api/clients/999999
GET /api/contracts/999999
GET /api/maintenance/999999
```

Resultat attendu :

```http
404
```

```json
{
  "error": "..."
}
```

### 13.2 Validation de champs obligatoires

Exemples :

- creer client sans `fullName` ;
- creer client sans `phone` ;
- creer contrat sans `carId` ;
- creer contrat sans `clientId` ;
- creer voiture sans `brand` ou `matricule`.

Resultat attendu :

```http
400
```

```json
{
  "error": "Validation failed",
  "fields": {
    "...": "..."
  }
}
```

### 13.3 Erreur metier

Exemples :

- voiture avec contrat ouvert supprimee ;
- contrat ACTIVE modifie ;
- contrat IN_PROGRESS termine directement ;
- maintenance deja terminee terminee encore.

Resultat attendu :

```http
400
```

```json
{
  "error": "message metier"
}
```

---

## 14. Scenarios complets de bout en bout

### Scenario A - Location complete normale

1. Creer une voiture disponible.
2. Creer un nouveau contrat.
3. Verifier statut contrat `IN_PROGRESS`.
4. Activer le contrat.
5. Verifier voiture `RENTED`.
6. Verifier revenu cree.
7. Telecharger PDF.
8. Terminer le contrat.
9. Verifier voiture `AVAILABLE`.
10. Verifier contrat `COMPLETED`.

### Scenario B - Maintenance complete

1. Creer voiture disponible.
2. Ajouter maintenance sans date de fin.
3. Verifier voiture `MAINTENANCE`.
4. Verifier depense creee.
5. Terminer maintenance.
6. Verifier voiture `AVAILABLE`.

### Scenario C - Alertes

1. Modifier voiture.
2. Mettre assurance dans 10 jours.
3. Mettre visite technique dans 15 jours.
4. Mettre derniere vidange il y a plus de 180 jours.
5. Ouvrir Dashboard.
6. Verifier 3 alertes.
7. Mettre dates loin dans le futur.
8. Verifier disparition des alertes.

### Scenario D - Blocages de securite metier

1. Creer contrat `IN_PROGRESS`.
2. Essayer de supprimer la voiture.
3. Attendre erreur.
4. Activer contrat.
5. Essayer de modifier contrat.
6. Attendre erreur.
7. Essayer de supprimer contrat actif.
8. Attendre erreur.
9. Terminer contrat.
10. Supprimer contrat termine.

---

## 15. Checklist de regression rapide

Avant de considerer une version stable, verifier :

- [ ] backend demarre sans erreur ;
- [ ] Flutter demarre et se connecte a `localhost:8080/api` ;
- [ ] ajout voiture OK ;
- [ ] upload image voiture OK ;
- [ ] modification voiture OK ;
- [ ] suppression voiture sans contrat OK ;
- [ ] blocage suppression voiture avec contrat OK ;
- [ ] creation client via contrat OK ;
- [ ] creation contrat `IN_PROGRESS` OK ;
- [ ] activation contrat OK ;
- [ ] revenu cree une seule fois ;
- [ ] fin contrat OK ;
- [ ] PDF telechargeable pour contrat ACTIVE/COMPLETED ;
- [ ] PDF bloque pour IN_PROGRESS ;
- [ ] maintenance creation OK ;
- [ ] depense creee ;
- [ ] maintenance complete OK ;
- [ ] dashboard stats correctes ;
- [ ] alertes assurance / visite / vidange correctes ;
- [ ] calendrier disponibilite correct ;
- [ ] erreurs 400/404 lisibles dans l'UI ou Swagger.

---

## 16. Notes importantes

- Les statuts voiture sont principalement pilotes par les actions metier : contrat et maintenance.
- Un contrat cree commence par `IN_PROGRESS`.
- Le revenu est cree a l'activation du contrat, pas a la creation.
- La depense est creee a partir de la maintenance.
- Les alertes ne dependent pas des contrats.
- Les contrats sont supprimes logiquement.
- Les clients peuvent etre purges automatiquement s'ils deviennent orphelins.
- Les images sont stockees dans `bousselha-backend/src/main/resources/static/uploads/cars`.
- Le PDF est genere par le backend avec PDFBox.
