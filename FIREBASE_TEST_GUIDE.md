# Firebase Integration Test Guide

## ✅ Hvad er implementeret

1. **Firestore Service Layer** (`lib/services/scorecard_storage_service.dart`)
   - Gem scorekort til Firestore
   - Hent scorekort efter ID
   - Godkend/afvis scorekort
   - Stream af pending scorekort for markører
   - Stream af alle scorekort for spillere
   - Konverter mellem Firestore og Scorecard model

2. **Test-funktion** i Results Screen
   - Automatisk test af Firebase integration
   - Gemmer scorekort
   - Henter det igen
   - Viser resultat med document ID og markør URL

3. **Setup dokumentation**
   - `FIRESTORE_SETUP.md` med trin-for-trin guide til Firestore setup

## 🔥 Test Firebase Integration

### Trin 1: Opsæt Firestore Database

Følg instruktionerne i `FIRESTORE_SETUP.md`:

1. Gå til Firebase Console
2. Enable Firestore Database
3. Start i **test mode** (vi kan stramme security senere)
4. Vælg location: **europe-west1**
5. Publicer security rules (fra setup guiden)

### Trin 2: Kør appen

```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

### Trin 3: Spil en runde

1. Log ind med dit DGU nummer
2. Vælg klub, bane og tee
3. Start en runde (enten Indberet eller Hul-for-hul)
4. Indtast scores (eller brug test-data hvis du har det)
5. Naviger til results screen

### Trin 4: Test Firebase

På results screen vil du se en ny knap:

**🔥 Test Firebase Integration**

Klik på denne knap og observér:

1. **Loading snackbar** vises: "Testing Firebase - Gemmer scorekort..."
2. Scorekortet gemmes til Firestore
3. Scorekortet hentes igen fra Firestore
4. **Success dialog** vises med:
   - ✅ Confirmation
   - Document ID
   - Spiller info
   - Status og points
   - **Markør URL** (format: `https://dgu-scorekort.web.app/marker-approval/{documentId}`)

### Trin 5: Verificer i Firebase Console

1. Gå til Firebase Console → Firestore Database
2. Du skulle nu se en collection kaldet **scorecards**
3. Klik ind i collectionen for at se det gemte scorekort
4. Verificer at alle felter er til stede:
   - `playerId`, `playerName`
   - `markerId`, `markerName`
   - `courseName`, `teeId`
   - `holes` array med alle hul-data
   - `status: "pending"`
   - `createdAt` timestamp

## 🐛 Hvis testen fejler

### Fejl: "Firebase not initialized"
- Tjek at Firebase blev initialiseret i `main.dart`
- Se efter "Firebase initialized successfully" i konsollen

### Fejl: "Permission denied"
- Tjek Firestore security rules i Firebase Console
- Sikr at de er sat til `allow read, write: if true;` under test

### Fejl: "Network error"
- Tjek din internetforbindelse
- Verificer at Firebase project ID matcher i `firebase_options.dart`

### Fejl: "Collection not found"
- Helt normalt første gang - Firestore opretter collection automatisk ved første write
- Prøv igen

## 📋 Næste skridt efter test er successfuld

1. ✅ **Firebase service virker!**
2. 🔜 Integrer i normal flow (gem efter runde er færdig)
3. 🔜 Lav marker approval screen der læser fra URL
4. 🔜 Integrer push notification API
5. 🔜 Send til DGU når markør godkender

## 💡 Tips

- Document ID er unikt og kan bruges direkte i markør URL
- Test med forskellige scorekort for at se flere i Firestore
- Brug Firebase Console til at manuelt opdatere/slette test-data
- Tag screenshots af success dialog til dokumentation

## 🔒 Husk før production

- Stram Firestore security rules
- Tilføj authentication check
- Implementer proper error handling
- Tilføj loading states
- Test med rigtige DGU numre




