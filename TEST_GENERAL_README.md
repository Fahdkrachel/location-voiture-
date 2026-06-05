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
- les reservations futures ;
- l'activation automatique des contrats ;
- les alertes de retour vehicule ;
- l'affichage des matricules avec lettre arabe ;
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
| Dashboard | `/api/dashboard/stats`, `/api/dashboard/alerts`, `/api/dashboard/calendar`, `/api/dashboard/future-reservations` |
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

### 4.7 Matricule avec lettre arabe dans l'UI

Precondition :

- creer ou modifier une voiture avec un matricule contenant une lettre arabe.

Exemples :

```text
12345-ب-67
12345-أ-67
12345-د-67
```

Zones a verifier :

- formulaire ajout voiture ;
- formulaire modification voiture ;
- liste des voitures ;
- detail voiture ;
- calendrier ;
- dashboard ;
- contrats ;
- maintenance ;
- PDF contrat.

Resultat attendu :

- le matricule garde exactement l'ordre saisi ;
- la lettre arabe reste a sa position ;
- il ne doit pas devenir `67-ب-12345`, `00-0000-ب` ou une autre permutation ;
- le champ de saisie reste lisible de gauche a droite pour un format plaque.

### 4.8 Image voiture actualisee immediatement

Action :

1. Creer une voiture sans image.
2. Modifier la voiture.
3. Choisir une image `.jpg`, `.jpeg` ou `.png`.
4. Enregistrer.

Resultat attendu :

- l'image apparait dans la liste sans redemarrer l'application ;
- l'image apparait dans le detail voiture ;
- l'image apparait dans Dashboard / Calendrier quand la voiture est listee ;
- le chemin API `imageUrl` pointe vers `/uploads/cars/...`.

### 4.9 Ouverture image en plein ecran

Precondition :

- voiture avec image.

Action :

```text
Detail voiture -> cliquer sur l'image
```

Resultat attendu :

- l'image s'ouvre en plein ecran ;
- le bouton fermer revient au detail ;
- l'image garde un affichage correct avec zoom/contain.

### 4.10 Remettre disponible

Action disponible dans la liste ou le detail voiture si statut :

```text
RENTED
MAINTENANCE
```

Scenario autorise :

1. Avoir une voiture `RENTED` sans contrat ouvert, ou `MAINTENANCE` sans maintenance en cours.
2. Cliquer `Remettre disponible`.

Resultat attendu :

- confirmation affichee ;
- voiture repasse `AVAILABLE`.

Scenario interdit : voiture louee avec contrat ouvert.

Resultat attendu :

```json
{
  "error": "CAR_HAS_ACTIVE_CONTRACT"
}
```

Scenario interdit : voiture en maintenance avec maintenance en cours.

Resultat attendu :

```json
{
  "error": "MAINTENANCE_NOT_FINISHED"
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

- si la date de depart est future : contrat cree avec statut `IN_PROGRESS` ;
- si la date de depart est maintenant ou deja passee : contrat cree directement avec statut `ACTIVE` ;
- pour un contrat futur, la voiture reste `AVAILABLE` tant que la date de depart n'est pas atteinte ;
- pour un contrat immediat, la voiture passe directement `RENTED` ;
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
  "error": "La voiture n'est pas disponible pour une location immediate (statut actuel: ...)."
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
  "error": "La voiture ... est deja reservee ou louee sur cette periode."
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

- contrat `IN_PROGRESS` ou `ACTIVE`.

Action :

```text
Contrat detail -> Modifier
```

Resultat attendu :

- pour `IN_PROGRESS` : modification acceptee si la periode ne chevauche pas une autre reservation ;
- pour `ACTIVE` : modification acceptee, mais la voiture assignee ne peut pas changer ;
- pour `IN_PROGRESS`, le changement de voiture est accepte seulement si la nouvelle voiture est disponible et sans chevauchement.

### 6.9 Exception : modifier un contrat COMPLETED

Resultat attendu :

```json
{
  "error": "Impossible de modifier un contrat deja termine"
}
```

### 6.9.1 Exception : changer la voiture d'un contrat ACTIVE

Precondition :

- contrat `ACTIVE`.

Action :

```text
Modifier le contrat en changeant carId
```

Resultat attendu :

```json
{
  "error": "Cannot change assigned car while contract is active"
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

### 6.11 Contrat futur / reservation

Precondition :

- voiture `AVAILABLE` ;
- aucune reservation qui chevauche la periode choisie.

Action :

```text
Contrats -> Nouveau contrat
Date depart = demain ou une date future
Retour prevu = apres la date de depart
```

Resultat attendu :

- contrat cree avec statut `IN_PROGRESS` ;
- voiture reste `AVAILABLE` ;
- le contrat apparait dans `GET /api/dashboard/future-reservations` ;
- la section Dashboard `Reservations a venir` affiche le contrat avec le nombre de jours restants ;
- cliquer sur la reservation dans le Dashboard ouvre le detail du contrat.

### 6.12 Activation automatique d'une reservation

Le backend contient une tache planifiee toutes les 10 secondes :

```text
scheduledAutoActivate()
```

Elle active automatiquement les contrats `IN_PROGRESS` dont `departureDatetime <= maintenant`.

Scenario de test :

1. Creer une reservation avec depart dans 1 ou 2 minutes.
2. Verifier que le contrat est `IN_PROGRESS`.
3. Attendre que l'heure de depart soit atteinte, puis attendre au moins 10 secondes.
4. Rafraichir les contrats ou le Dashboard.

Resultat attendu :

- contrat passe automatiquement `ACTIVE` ;
- voiture passe `RENTED` ;
- revenu cree une seule fois ;
- la reservation disparait de `Reservations a venir` ;
- le contrat apparait dans `Calendrier des locations actives`.

### 6.13 Chevauchement de reservation

Precondition :

- voiture avec contrat `IN_PROGRESS` ou `ACTIVE` sur la periode `2026-06-10 -> 2026-06-15`.

Action :

```text
Creer un autre contrat sur la meme voiture avec depart/retour qui chevauchent cette periode
```

Exemples de periodes interdites :

```text
2026-06-09 -> 2026-06-11
2026-06-12 -> 2026-06-14
2026-06-14 -> 2026-06-20
```

Resultat attendu :

```json
{
  "error": "La voiture ... est deja reservee ou louee sur cette periode."
}
```

### 6.14 Reservation non chevauchante

Precondition :

- voiture avec contrat du `2026-06-10` au `2026-06-15`.

Action :

```text
Creer un contrat sur la meme voiture du 2026-06-16 au 2026-06-20
```

Resultat attendu :

- contrat accepte ;
- statut `IN_PROGRESS` si depart futur ;
- les deux contrats sont visibles dans l'historique de la voiture.

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

### 7.2 PDF avec matricule contenant une lettre arabe

Precondition :

- voiture avec matricule contenant une lettre arabe, par exemple :

```text
12345-ب-67
```

Action :

1. Creer un contrat avec cette voiture.
2. Activer ou terminer le contrat.
3. Telecharger le PDF.

Resultat attendu :

- le matricule garde exactement l'ordre saisi ;
- la lettre arabe ne devient pas `?` ;
- le fichier PDF utilise les polices Cairo si elles sont presentes dans :

```text
bousselha-backend/src/main/resources/static/fonts/Cairo-Regular.ttf
bousselha-backend/src/main/resources/static/fonts/Cairo-Bold.ttf
```

Tester plusieurs lettres :

```text
12345-ب-67
12345-أ-67
12345-د-67
12345-و-67
```

### 7.3 Exception : PDF sur contrat IN_PROGRESS

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

### 9.2 Graphique financier global

Le Dashboard affiche un graphique qui combine les revenus et les depenses.

Preconditions :

- au moins un contrat active avec revenu ;
- au moins une maintenance avec cout.

Action :

```text
Dashboard
```

Resultat attendu :

- le graphique s'affiche sans erreur ;
- les points ou courbes Income / Expense correspondent aux donnees de `GET /api/financial/income` et `GET /api/financial/expenses` ;
- si aucune donnee n'existe, le graphique ne doit pas casser l'ecran.

### 9.3 Revenus

Precondition :

- contrat avec `totalGeneral > 0`.

Action :

```text
Activer le contrat
```

Resultat attendu :

- dashboard `Revenus` augmente ;
- ecran detail Income affiche une ligne `Contrat #id - client`.

### 9.4 Depenses

Precondition :

- maintenance avec cout > 0.

Action :

```text
Creer ou modifier maintenance
```

Resultat attendu :

- dashboard `Depenses` augmente ;
- ecran detail Expense affiche la maintenance.

### 9.5 Reservations a venir

Nouvelle section Dashboard :

```text
Reservations a venir
```

Elle consomme :

```http
GET /api/dashboard/future-reservations
```

Precondition :

- creer un contrat avec date de depart future ;
- statut attendu : `IN_PROGRESS`.

Resultat attendu :

- la reservation apparait dans la section ;
- l'image de la voiture apparait si elle existe ;
- le libelle affiche voiture, matricule, client et date de depart ;
- le badge a droite affiche `Aujourd'hui`, `Demain` ou `Dans X jours` ;
- cliquer sur la reservation ouvre l'ecran detail du contrat ;
- apres activation automatique, la reservation disparait de cette section.

### 9.6 Navigation depuis le Dashboard vers un contrat

Tester les zones cliquables :

| Zone | Action | Resultat attendu |
|---|---|---|
| Calendrier des locations actives | cliquer sur une ligne | ouverture detail contrat |
| Reservations a venir | cliquer sur une ligne | ouverture detail contrat |
| Alerte `RETURN` | cliquer sur l'alerte | ouverture detail contrat |

Apres retour au Dashboard, les providers doivent etre invalides et les donnees rafraichies.

---

## 10. Tests des alertes Dashboard

Les alertes viennent de :

```http
GET /api/dashboard/alerts
```

Les alertes `INSURANCE`, `INSPECTION` et `OIL_CHANGE` dependent des dates de voiture.
Les alertes `RETURN` dependent des contrats `ACTIVE` et de leur date de retour prevue.

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

### 10.4 Retour vehicule proche ou depasse

Type d'alerte :

```text
RETURN
```

Cette alerte depend des contrats `ACTIVE`, pas des dates de maintenance.

Scenario A - retour dans moins de 24h :

1. Creer ou modifier un contrat `ACTIVE`.
2. Mettre `expectedReturnDatetime` dans moins de 24 heures.
3. Appeler `GET /api/dashboard/alerts` ou ouvrir Dashboard.

Resultat attendu :

```json
{
  "type": "RETURN",
  "severity": "MEDIUM",
  "message": "Retour prevu dans moins de 24h pour ..."
}
```

Scenario B - retour depasse :

1. Avoir un contrat `ACTIVE`.
2. Mettre `expectedReturnDatetime` dans le passe.
3. Ouvrir Dashboard.

Resultat attendu :

```json
{
  "type": "RETURN",
  "severity": "HIGH",
  "message": "Retour depasse pour ..."
}
```

Dans l'UI, cliquer sur l'alerte `RETURN` doit ouvrir le detail du contrat lie (`contractId`).

---

## 11. Tests Calendrier

Chemin UI :

```text
Calendrier
```

L'UI utilise principalement :

```http
GET /api/cars/availability/available?date=YYYY-MM-DD
```

Pour verifier tous les statuts, utiliser aussi :

```http
GET /api/cars/availability?date=YYYY-MM-DD
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

### 11.4 Recherche dans le calendrier

Action :

1. Ouvrir `Calendrier`.
2. Choisir une date.
3. Saisir une marque dans le champ de recherche.

Resultat attendu :

- la liste se filtre par marque ;
- si aucun resultat ne correspond, l'UI affiche un message de resultat vide ;
- le compteur de vehicules disponibles est mis a jour.

### 11.5 Changement de date

Action :

```text
Calendrier -> bouton date -> choisir une autre date
```

Resultat attendu :

- la liste est rechargee ;
- les voitures disponibles changent selon les contrats et maintenances de cette date.

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
- [ ] matricule avec lettre arabe affiche dans le bon ordre ;
- [ ] image voiture visible immediatement apres upload ;
- [ ] image voiture ouvrable en plein ecran ;
- [ ] action `Remettre disponible` OK et exceptions OK ;
- [ ] suppression voiture sans contrat OK ;
- [ ] blocage suppression voiture avec contrat OK ;
- [ ] creation client via contrat OK ;
- [ ] creation contrat `IN_PROGRESS` OK ;
- [ ] creation contrat immediat -> `ACTIVE` OK ;
- [ ] reservation future visible dans Dashboard ;
- [ ] activation automatique apres date de depart OK ;
- [ ] chevauchement de reservation bloque ;
- [ ] activation contrat OK ;
- [ ] revenu cree une seule fois ;
- [ ] fin contrat OK ;
- [ ] PDF telechargeable pour contrat ACTIVE/COMPLETED ;
- [ ] PDF affiche correctement les matricules avec lettre arabe ;
- [ ] PDF bloque pour IN_PROGRESS ;
- [ ] maintenance creation OK ;
- [ ] depense creee ;
- [ ] maintenance complete OK ;
- [ ] dashboard stats correctes ;
- [ ] graphique financier charge correctement ;
- [ ] navigation Dashboard -> detail contrat OK ;
- [ ] alertes assurance / visite / vidange correctes ;
- [ ] alerte retour vehicule `RETURN` correcte ;
- [ ] calendrier disponibilite correct ;
- [ ] recherche calendrier correcte ;
- [ ] erreurs 400/404 lisibles dans l'UI ou Swagger.

---

## 16. Notes importantes

- Les statuts voiture sont principalement pilotes par les actions metier : contrat et maintenance.
- Un contrat futur commence par `IN_PROGRESS`.
- Un contrat immediat ou dont la date de depart est deja atteinte peut passer directement `ACTIVE`.
- Les contrats `IN_PROGRESS` sont auto-actives par une tache planifiee quand la date de depart arrive.
- Le revenu est cree a l'activation du contrat, pas a la creation.
- La depense est creee a partir de la maintenance.
- Les alertes voiture dependent des dates assurance / visite / vidange.
- Les alertes `RETURN` dependent des contrats `ACTIVE` et de leur retour prevu.
- Les contrats sont supprimes logiquement.
- Les clients peuvent etre purges automatiquement s'ils deviennent orphelins.
- Les images sont stockees dans `bousselha-backend/src/main/resources/static/uploads/cars`.
- Le PDF est genere par le backend avec PDFBox.
- Les polices Cairo sont utilisees pour mieux supporter l'arabe et Unicode dans les PDF.
