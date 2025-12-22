# DGU Scorekort URL Guide 🌐

## 📍 Dine Apps URLs

### 1. Firebase Hosting (Primary Production URL) ⭐
```
https://dgu-scorekort.web.app
```

**Dette er din primære URL!**

- ✅ **Backend Integration** - Fungerer med Firestore database
- ✅ **SSL/HTTPS** - Sikker forbindelse
- ✅ **CDN** - Hurtig loading globalt
- ✅ **Custom Domain** - Du kan tilføje eget domain navn senere
- ✅ **Marker Approval Links** - Virker perfekt!

**Marker Approval Format:**
```
https://dgu-scorekort.web.app/#/marker-approval/{documentId}
```

**Deploy Opdateringer:**
```bash
flutter build web
firebase deploy --only hosting
```

---

### 2. GitHub Repository (Kildekode)
```
https://github.com/[dit-username]/dgu_scorekort
```

**Bruges til:**
- ✅ Version control (git commits, branches)
- ✅ Code backup og historik
- ✅ Collaboration med andre udviklere
- ✅ CI/CD via GitHub Actions (optional)

**Ikke til:**
- ❌ Hosting af appen (brug Firebase i stedet)
- ❌ Marker approval links

---

### 3. Lokal Development
```
http://localhost:[dynamic-port]
```

**Dynamisk port ændrer sig hver gang** (f.eks. 51248, 55048, etc.)

**Start lokal udvikling:**
```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

**Lokal Marker Approval Test:**
- URL genereres automatisk baseret på nuværende port
- Vises som "Test lokalt (localhost:XXXX)" i success dialog

---

## 🎯 Hvilken URL Skal Jeg Bruge?

### For Markør Godkendelse (Production)
✅ **Brug:** `https://dgu-scorekort.web.app/#/marker-approval/{id}`
- Send via mail/SMS til markør
- Fungerer på alle enheder
- Ingen app installation nødvendig
- Permanent og pålidelig

### For App Udvikling
✅ **Brug:** `http://localhost:[port]`
- Test nye features
- Debug problemer
- Hurtig iteration
- Ikke til deling med andre

### For Code Backup
✅ **Brug:** GitHub repository
- Git commit og push regelmæssigt
- Aldrig mist kode
- Collaboration ready

---

## 🔄 Deployment Workflow

```
1. Udvikle lokalt
   flutter run -d chrome
   ↓
2. Test funktionalitet
   ↓
3. Commit til GitHub
   git add .
   git commit -m "Add feature X"
   git push
   ↓
4. Build for production
   flutter build web
   ↓
5. Deploy til Firebase
   firebase deploy --only hosting
   ↓
6. App er live på:
   https://dgu-scorekort.web.app
```

---

## 📧 Eksempel Mail til Markør

```
Hej [Markør Navn],

Vil du godkende mit scorekort fra [Dato] på [Bane Navn]?

Klik på dette link for at se scorekortet og godkende:
https://dgu-scorekort.web.app/#/marker-approval/QlVojNbqcoJ6YZ0fGUV

Det tager kun 1 minut, og du behøver ikke installere noget.

Mvh
[Dit Navn]
```

---

## ❓ FAQ

### Q: Kan jeg bruge et custom domain?
**A:** Ja! Firebase Hosting understøtter custom domains:
1. Gå til Firebase Console → Hosting
2. Klik "Add custom domain"
3. Følg instruktionerne (f.eks. `scorekort.dgu.dk`)

### Q: Hvorfor har URL'en `#` i sig?
**A:** Flutter web bruger hash-routing som standard. Det fungerer perfekt og er standard praksis.

### Q: Hvor mange marker approval links kan jeg sende?
**A:** Ubegrænset! Hver gang du afslutter en runde og gemmer til Firebase, får du et unikt link.

### Q: Kan markøren se alle mine scorekort?
**A:** Nej! Hvert link er unikt og viser kun ét specifikt scorekort. Security by obscurity.

### Q: Hvad hvis jeg sender forkert link?
**A:** Intet problem! Det gamle link virker stadig, men du kan bare sende et nyt link til den rigtige markør.

### Q: Udløber links?
**A:** Nej, ikke lige nu. Men du kan senere tilføje expiry (f.eks. 7 dage) i Firestore rules.

---

## 🔒 Sikkerhed

### Nuværende Setup
- ✅ Firestore test mode (alle kan læse/skrive)
- ✅ URL'er er svære at gætte (UUID)
- ✅ HTTPS encryption

### Før Production
Når du går i produktion, husk at:
1. Stram Firestore security rules
2. Tilføj authentication check
3. Implementer link expiry
4. Rate limiting på godkendelser

---

## 📊 Monitoring

**Firebase Console:**
```
https://console.firebase.google.com/project/dgu-scorekort
```

**Se:**
- Hosting deployment history
- Firestore database indhold
- Traffic og performance
- Error logs

---

## ✅ Quick Reference

| Formål | URL | Command |
|--------|-----|---------|
| **Production App** | https://dgu-scorekort.web.app | `firebase deploy --only hosting` |
| **Lokal Udvikling** | http://localhost:[port] | `flutter run -d chrome` |
| **Code Repository** | GitHub | `git push` |
| **Firebase Console** | console.firebase.google.com | - |
| **Marker Approval** | .../#/marker-approval/{id} | Send via mail/SMS |

---

## 🎉 Du Er Klar!

Din app er nu live på **https://dgu-scorekort.web.app**

Marker approval links virker perfekt, og du kan sende dem til hvem som helst! 🚀








