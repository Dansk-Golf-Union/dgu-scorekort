# Firebase Hosting Deployment Guide

## 🚀 Quick Deploy

For at deploye til Firebase Hosting og få din eksterne URL til at virke:

### 1. Install Firebase CLI (kun én gang)

```bash
npm install -g firebase-tools
```

### 2. Login til Firebase

```bash
firebase login
```

### 3. Build Flutter Web App

```bash
flutter build web
```

Dette opretter `build/web/` mappen med din compiled app.

### 4. Deploy til Firebase Hosting

```bash
firebase deploy --only hosting
```

### 5. Din app er nu live! 🎉

```
https://dgu-scorekort.web.app
```

## 📋 Fuld Deployment Flow

### Første Gang Setup

1. **Verificer Firebase projekt**
```bash
firebase projects:list
```

Du skulle se `dgu-scorekort` i listen.

2. **Test lokalt først (optional)**
```bash
flutter build web
firebase serve --only hosting
```

Åbner på `http://localhost:5000`

3. **Deploy til production**
```bash
firebase deploy --only hosting
```

### Efterfølgende Deployments

Hver gang du vil deploye nye ændringer:

```bash
# 1. Build appen
flutter build web

# 2. Deploy
firebase deploy --only hosting
```

## 🔗 URLs Efter Deployment

Efter successful deployment har du:

### Main App
- **Production**: `https://dgu-scorekort.web.app`
- **Alternative**: `https://dgu-scorekort.firebaseapp.com`

### Marker Approval Links
- **Format**: `https://dgu-scorekort.web.app/marker-approval/{documentId}`
- **Eksempel**: `https://dgu-scorekort.web.app/marker-approval/nLFCjbJN0rpdO8CXoCwd`

## 🧪 Test Marker Approval Flow

### Lokalt (før deployment)

1. Start appen lokalt:
```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

2. Spil en runde og klik "🔥 Test Firebase Integration"

3. Klik på "Test lokalt" knappen i success dialog

4. URL åbner: `http://localhost:51248/#/marker-approval/{documentId}`

### Efter Deployment

1. Klik på "Åbn i ny tab (Production)" knappen

2. URL åbner: `https://dgu-scorekort.web.app/marker-approval/{documentId}`

3. Send denne URL til en markør via mail/SMS

4. Markør kan godkende/afvise scorekortet direkte fra linket

## 📱 Test Flow (Komplet)

```
1. Spiller starter app → Log ind → Spil runde
   ↓
2. Afslutter runde → Test Firebase Integration
   ↓
3. Scorekort gemmes i Firestore
   ↓
4. Success dialog viser URLs (lokal + production)
   ↓
5. Kopiér production URL eller klik "Åbn i ny tab"
   ↓
6. Send URL til markør (mail/SMS)
   ↓
7. Markør åbner link → Ser scorekort
   ↓
8. Markør klikker "Godkend" eller "Afvis"
   ↓
9. Status opdateres i Firestore
   ↓
10. Success! 🎉
```

## 🛠️ Troubleshooting

### Deployment Fails

**Problem**: `Error: HTTP Error: 403, Permission denied`

**Løsning**: 
```bash
firebase login --reauth
firebase use dgu-scorekort
firebase deploy --only hosting
```

### URL Returns 404

**Problem**: Direct links til `/marker-approval/{id}` giver 404

**Løsning**: Verificer at `firebase.json` har korrekt rewrites:

```json
"rewrites": [
  {
    "source": "**",
    "destination": "/index.html"
  }
]
```

### Routing Virker Ikke

**Problem**: Links virker lokalt men ikke i production

**Løsning**: Flutter web routing bruger `#` som standard. URLs ser ud som:
- `https://dgu-scorekort.web.app/#/marker-approval/{id}`

Dette er normalt og virker fint!

### Build Fejler

**Problem**: `flutter build web` fejler

**Løsning**:
```bash
flutter clean
flutter pub get
flutter build web
```

## 📊 Firebase Hosting Dashboard

Se deployment status og statistik:

1. Gå til [Firebase Console](https://console.firebase.google.com/)
2. Vælg projekt: **dgu-scorekort**
3. Klik på **Hosting** i venstre menu
4. Se:
   - Deployment history
   - Domain status
   - Traffic statistics
   - Performance data

## 🔄 Continuous Deployment (Optional)

For automatisk deployment via GitHub Actions, se `.github/workflows/deploy.yml`.

**Bemærk**: Kræver Firebase service account token:

```bash
firebase login:ci
```

Gem token som GitHub Secret: `FIREBASE_TOKEN`

## 💡 Pro Tips

1. **Test lokalt først** - Brug `flutter run -d chrome` før deployment
2. **Branch protection** - Deploy kun fra main branch
3. **Versioning** - Tag deployments i git: `git tag v1.0.0`
4. **Monitor errors** - Brug Firebase Console til at se fejl
5. **Caching** - Første load er langsom, derefter cached

## ✅ Deployment Checklist

- [ ] Flutter build kører uden fejl
- [ ] Firestore rules er opdateret
- [ ] Firebase CLI installeret og logged ind
- [ ] `flutter build web` executed successfully
- [ ] `firebase deploy --only hosting` completed
- [ ] Test main app URL
- [ ] Test marker approval URL med real document ID
- [ ] Send test URL til markør
- [ ] Verificer godkendelse opdaterer Firestore

## 🎯 Næste Skridt Efter Deployment

1. ✅ Test fuld flow med rigtig markør
2. ✅ Integrer i normal app flow (auto-save efter runde)
3. ✅ Tilføj push notification integration
4. ✅ Automatisk send URL til markør
5. ✅ Submit til DGU når godkendt

## 🆘 Brug for Hjælp?

- Firebase Hosting Docs: https://firebase.google.com/docs/hosting
- Flutter Web Docs: https://flutter.dev/web
- Go Router Docs: https://pub.dev/packages/go_router

