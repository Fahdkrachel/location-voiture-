# Contrat PDF - BOUSSELHA CARS

Ce document explique en detail comment le systeme remplit les informations du contrat et comment il genere le PDF.

## 1. Vue generale

Le projet est compose de deux parties:

- `bousselha-flutter`: interface utilisateur. Elle affiche les contrats, ouvre le formulaire de creation/modification et telecharge le PDF.
- `bousselha-backend`: API Spring Boot. Elle enregistre les contrats en base de donnees et genere le PDF avec Apache PDFBox.

Le PDF n'est pas cree au moment exact ou le contrat est sauvegarde. Il est genere a la demande quand l'utilisateur clique sur le bouton PDF dans l'application.

Flux complet:

1. L'utilisateur choisit une voiture, un client, les dates, les prix, le paiement et les lieux dans Flutter.
2. Flutter envoie ces informations au backend avec `POST /api/contracts` ou `PUT /api/contracts/{id}`.
3. Le backend sauvegarde le contrat dans la table `contracts`.
4. Quand l'utilisateur demande le PDF, Flutter appelle `GET /api/contracts/{id}/pdf`.
5. Le backend recharge le contrat avec sa voiture et son client, dessine le contrat dans un document PDFBox, puis renvoie les bytes PDF.
6. Flutter sauvegarde le fichier dans le dossier `Downloads`.

## 2. Fichiers importants

Backend:

- `bousselha-backend/src/main/java/com/bousselha/infrastructure/controller/ContractController.java`
  - expose les routes REST des contrats.
  - expose la route PDF `GET /api/contracts/{id}/pdf`.

- `bousselha-backend/src/main/java/com/bousselha/application/service/ContractService.java`
  - cree, modifie, active, termine et supprime les contrats.
  - copie les champs recus dans l'entite `Contract`.
  - gere le statut du contrat et le statut de la voiture.

- `bousselha-backend/src/main/java/com/bousselha/application/service/PdfService.java`
  - genere le PDF avec Apache PDFBox.
  - dessine les cadres, textes, tableaux, cases a cocher et signatures.

- `bousselha-backend/src/main/java/com/bousselha/domain/model/Contract.java`
  - entite JPA sauvegardee dans la table `contracts`.

- `bousselha-backend/src/main/java/com/bousselha/domain/model/Client.java`
  - contient les informations du locataire et du conducteur supplementaire.

- `bousselha-backend/src/main/java/com/bousselha/domain/model/Car.java`
  - contient les informations de la voiture.

Flutter:

- `bousselha-flutter/lib/presentation/contracts/contract_list_screen.dart`
  - affiche la liste et le detail des contrats.
  - ouvre le formulaire contrat.
  - declenche le telechargement du PDF.

- `bousselha-flutter/lib/data/repositories/contract_repository.dart`
  - appelle l'API backend.
  - contient `createContract`, `updateContract`, `updateContractStatus` et `downloadContractPdf`.

- `bousselha-flutter/lib/data/models/contract_model.dart`
  - modele utilise cote Flutter pour lire les donnees renvoyees par l'API.

## 3. Creation ou modification d'un contrat

Dans Flutter, le formulaire contrat construit les champs suivants:

- voiture: `carId`
- client: `clientId`
- date depart: `departureDatetime`
- retour prevu: `expectedReturnDatetime`
- retour definitif: `actualReturnDatetime`
- duree en jours: `durationDays`
- prix par heure: `pricePerHour`
- prix par jour: `pricePerDay`
- prix par semaine: `pricePerWeek`
- prix par mois: `pricePerMonth`
- assurance: `withInsurance`
- total: `totalPrice`
- supplement: `supplement`
- total general: `totalGeneral`
- paiement espece: `paymentCash`
- paiement cheque: `paymentCheck`
- caution: `paymentDeposit`
- lieu depart/livraison: `departurePlace`
- lieu retour/reprise: `returnPlace`

Ces donnees sont envoyees au backend:

- creation: `POST /api/contracts`
- modification: `PUT /api/contracts/{id}`

Le backend recoit ces champs dans `ContractRequest`.

Dans `ContractService`, la methode `apply(Contract c, ContractRequest r)` copie les valeurs du request vers l'entite `Contract`:

- `r.departurePlace()` devient `contract.departurePlace`
- `r.returnPlace()` devient `contract.returnPlace`
- `r.departureDatetime()` devient `contract.departureDatetime`
- `r.expectedReturnDatetime()` devient `contract.expectedReturnDatetime`
- `r.durationDays()` devient `contract.durationDays`
- `r.pricePerDay()` devient `contract.pricePerDay`
- `r.totalGeneral()` devient `contract.totalGeneral`
- etc.

## 4. Gestion du statut du contrat

Le PDF est disponible seulement si le contrat est:

- `ACTIVE`
- ou `COMPLETED`

Dans `PdfService.generateContractPdf(Long id)`, le backend refuse la generation si le contrat n'est pas dans un de ces deux statuts.

Regles importantes:

- Si la date de depart est maintenant ou deja passee, le contrat devient `ACTIVE`.
- Si la voiture est disponible, son statut devient `RENTED`.
- Si la date de depart est dans le futur, le contrat reste `IN_PROGRESS`.
- Un contrat `IN_PROGRESS` peut etre active avec `PATCH /api/contracts/{id}/status`.
- Un contrat `ACTIVE` peut etre termine avec `PATCH /api/contracts/{id}/status` ou `PUT /api/contracts/{id}/return`.
- Quand un contrat est termine, son statut devient `COMPLETED` et la voiture redevient `AVAILABLE`.

## 5. Generation du PDF

La route backend est:

```http
GET /api/contracts/{id}/pdf
```

Dans `ContractController.pdf(Long id)`:

1. Le backend recupere le contrat avec `contractService.findById(id)`.
2. Il prepare le nom du fichier:

```text
Contrat_{clientName}_{carMatricule}.pdf
```

3. Il appelle:

```java
pdfService.generateContractPdf(id)
```

4. Il renvoie la reponse HTTP avec:

- `Content-Type: application/pdf`
- `Content-Disposition: inline`
- le contenu PDF en bytes

Dans `PdfService.generateContractPdf(Long id)`:

1. Le contrat est recharge par `contractRepository.findDetailedById(id)`.
2. La requete charge aussi le client et la voiture avec `join fetch`.
3. Les parametres societe sont charges avec `settingsService.getRawSettings()`.
4. Un document PDF A4 est cree avec `new PDDocument()` et `new PDPage(PDRectangle.A4)`.
5. Le service charge les polices Cairo si elles existent:
   - `/static/fonts/Cairo-Regular.ttf`
   - `/static/fonts/Cairo-Bold.ttf`
6. Si les polices ne sont pas trouvees, le systeme utilise Helvetica.
7. Le service dessine le contrat section par section avec `PDPageContentStream`.
8. Le document est sauvegarde dans un `ByteArrayOutputStream`.
9. Le backend renvoie `out.toByteArray()`.

## 6. Informations remplies dans le PDF

### En-tete societe

Source: `CompanySettings`.

Champs affiches:

- logo: `settings.logoPath`
- nom societe en fallback si logo absent
- adresse: `settings.address`
- telephone/fax: `settings.phone`, `settings.fax`
- GSM: `settings.gsm`
- email: `settings.email`

Si aucun logo valide n'est trouve, le PDF affiche un en-tete texte avec le nom de la societe.

### Voiture et lieux

Source: `Contract.car` et `Contract`.

Champs affiches:

- marque: `contract.car.brand`
- immatriculation: `contract.car.matricule`
- lieu de livraison/depart: `contract.departurePlace`
- lieu de reprise/retour: `contract.returnPlace`

### Dates

Source: `Contract`.

Champs affiches dans les colonnes J/M/A/H/mn:

- depart: `contract.departureDatetime`
- retour prevu: `contract.expectedReturnDatetime`
- duree: `contract.durationDays`

Le code prepare aussi une ligne "Retour Definitif", mais dans la version actuelle le PDF ne remplit pas `actualReturnDatetime` dans cette ligne.

### Locataire

Source: `Contract.client`.

Champs affiches:

- nom et prenom: `client.fullName`
- date de naissance: `client.birthDate`
- adresse au Maroc: `client.addressMorocco`
- adresse a l'etranger: `client.addressAbroad`
- profession: `client.profession`
- permis de conduire numero: `client.drivingLicenseNumber`
- permis delivre a: `client.drivingLicenseIssuedAt`
- CIN: `client.cinNumber`
- passeport: `client.passportNumber`
- passeport delivre le: `client.passportIssuedAt`
- telephone: `client.phone`

### Prix

Le PDF dessine la grille:

- Heures
- Jours
- Semaines
- Mois
- Avec Assurance
- TOTAL
- Supplement
- TOTAL General

Important: dans la version actuelle, le service PDF affiche surtout les libelles et "DH" dans la colonne prix total. Les valeurs numeriques `pricePerHour`, `pricePerDay`, `pricePerWeek`, `pricePerMonth`, `totalPrice`, `supplement` et `totalGeneral` sont sauvegardees dans le contrat, mais elles ne sont pas vraiment imprimees dans cette grille PDF.

### Conducteur supplementaire

Source mixte:

- nom: `contract.additionalDriverName`
- permis: `contract.additionalDriverLicense`
- passeport: `contract.additionalDriverPassport`
- date de permis: `contract.client.additionalDriverDrivingLicenseIssuedAt`

Remarque importante: quand un nouveau client est cree depuis le flux "nouveau contrat", Flutter sauvegarde les informations du conducteur supplementaire dans le client. Mais lors de la creation du contrat, `createContract` n'envoie pas `additionalDriverName`, `additionalDriverLicense` et `additionalDriverPassport` dans le JSON du contrat. Donc le PDF peut ne pas afficher ces champs sauf si le contrat les contient deja ou si une modification les preserve.

### Paiement

Source: `Contract`.

Champs affiches seulement s'ils sont superieurs a zero:

- especes: `contract.paymentCash`
- cheque: `contract.paymentCheck`
- caution: `contract.paymentDeposit`

Chaque montant est affiche avec `DH`.

### Etat vehicule depart

Source: `contract.vehicleConditionDeparture`.

Le PDF affiche:

- case "Oui"
- case "Non"
- lignes de commentaires

Regles de cochage:

- si la valeur est `Oui` ou contient `parfait`, la case Oui est cochee.
- si la valeur est `Non` ou contient `mauvais`, la case Non est cochee.
- si la valeur est autre chose que Oui/Non, elle est affichee comme commentaire.

### Dommages identifies

Source: `contract.damagesIdentified`.

Le PDF affiche:

- zones "Eraflure", "Bosse", "Manque"
- tableau "Nombre / Paraphe client"

Regles:

- si le texte contient `manque`, la case Manque est cochee.
- si le texte n'est pas vide, une version courte du texte est affichee dans le tableau.

### Etat vehicule retour

Source: `contract.vehicleConditionReturn`.

Le fonctionnement est similaire a l'etat de depart:

- `Oui` ou texte contenant `parfait` coche Oui.
- `Non` ou texte contenant `mauvais` coche Non.
- un commentaire libre est affiche sur les lignes.

### Pied de page

Le PDF ajoute:

- une observation sur accident/vol
- la zone signature client
- la date du jour au format `dd/MM/yyyy`
- le texte `Fait a Tanger, le ...`

## 7. Telechargement cote Flutter

Dans l'ecran de detail contrat, le bouton PDF apparait seulement si le contrat peut etre telecharge, donc pour les statuts compatibles.

Quand l'utilisateur clique sur le bouton:

1. Flutter appelle `repo.downloadContractPdf(c.id)`.
2. `ContractRepository.downloadContractPdf` fait un `GET /contracts/{id}/pdf`.
3. La reponse est lue en bytes.
4. Flutter lit le header `content-disposition` pour recuperer le nom du fichier.
5. Le fichier est ecrit dans:

```text
{USERPROFILE}/Downloads
```

Si le dossier Downloads n'existe pas, Flutter utilise le dossier courant.

## 8. Points d'attention detectes

1. Les valeurs de la grille tarifaire ne sont pas imprimees dans le PDF.
   - Les montants existent dans le contrat.
   - Mais `PdfService` ne les dessine pas, sauf les montants de paiement.

2. `actualReturnDatetime` est dans le modele et dans le formulaire, mais la ligne "Retour Definitif" du PDF n'est pas remplie.

3. Les champs `vehicleConditionDeparture`, `vehicleConditionReturn` et `damagesIdentified` existent dans le backend et dans le PDF, mais le formulaire principal de creation ne semble pas permettre de les saisir directement dans la partie contrat affichee.

4. Les informations du conducteur supplementaire sont partiellement stockees dans `Client`, mais le PDF lit aussi des champs dans `Contract`. Cela peut creer un decalage si ces champs ne sont pas copies dans le contrat.

5. Le message d'erreur PDF dit que le contrat doit etre active ou termine. Donc un contrat `IN_PROGRESS` ne peut pas generer de PDF tant qu'il n'est pas active.

## 9. Resume rapide

Le systeme remplit le PDF a partir de trois sources principales:

- `CompanySettings`: logo et informations societe.
- `Contract`: dates, lieux, prix, paiement, etat vehicule, dommages, statut.
- `Client` et `Car`: informations locataire et voiture.

La generation est faite avec Apache PDFBox dans `PdfService`. Le PDF est genere seulement a la demande via `GET /api/contracts/{id}/pdf`, puis Flutter le sauvegarde dans le dossier `Downloads`.
