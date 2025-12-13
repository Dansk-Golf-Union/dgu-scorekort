# Check om automatisk cache opdatering virker

## 1. Check om functionen er deployed

Kør i terminal:
```bash
firebase functions:list
```

Du skal se:
- `updateCourseCache` (scheduled)
- `forceFullReseed` (callable)
- `sendNotification` (callable)
- `golfboxCallback` (https)

## 2. Check function logs

Kør i terminal:
```bash
# Se logs for updateCourseCache
firebase functions:log --only updateCourseCache

# Eller se alle function logs
firebase functions:log
```

Logs skal vise:
```
🕒 Starting scheduled course cache update...
🔍 Determining update strategy...
📋 Strategy: incremental, changedsince: 20251212T020000
...
✅ Cache update (incremental) completed successfully in 45s
```

## 3. Check Firestore metadata

I Firebase Console:
1. Gå til Firestore Database
2. Åbn collection: `course-cache-metadata`
3. Åbn document: `data`
4. Check felter:
   - `lastUpdated`: Skal være fra i nat kl. 02:00
   - `lastSeeded`: Skal være fra i nat kl. 02:00
   - `lastUpdateType`: "full" eller "incremental"
   - `clubsUpdatedLastRun`: Antal klubber opdateret
   - `coursesUpdatedLastRun`: Antal baner opdateret

## 4. Force en manuel opdatering (for test)

Hvis du vil teste at det virker UDEN at vente til kl. 02:00:

### Option A: Deploy og kør manuelt
```bash
# Deploy functions
firebase deploy --only functions

# Kør updateCourseCache manuelt via Firebase Console:
# 1. Gå til Firebase Console → Functions
# 2. Find "updateCourseCache"
# 3. Klik på funktionen
# 4. Gå til "Logs" tab
# 5. Eller brug gcloud CLI (se nedenfor)
```

### Option B: Brug gcloud CLI (kræver setup)
```bash
# Trigger scheduled function manuelt
gcloud functions call updateCourseCache --region=europe-west1
```

### Option C: Force full reseed ved næste kørsel (02:00)
Du kan kalde `forceFullReseed` functionen fra appen eller via console.

## 5. Fejlfinding

### Hvis functionen ikke kører:
- Check at den er deployed: `firebase functions:list`
- Check at Cloud Scheduler er enabled i Google Cloud Console
- Check billing (scheduled functions kræver Blaze plan)

### Hvis der er fejl:
- Check logs: `firebase functions:log --only updateCourseCache`
- Common issues:
  - Timeout (9 min max for scheduled functions)
  - API rate limiting (der er 300ms delay mellem requests)
  - Firestore write limits

## 6. Forventede resultater

**Første kørsel (full seed):**
- ~2-3 minutter
- 213 klubber processeret
- ~800-1000 baner gemt
- Metadata opdateret med club list

**Daglige kørsler (incremental):**
- ~30-60 sekunder
- Kun ændrede klubber/baner opdateres
- Metadata opdateret med sidste kørsel info

## 7. Verificer cache virker i appen

1. Åbn https://dgu-scorekort.web.app
2. Log ind
3. Start en ny runde (eller match play)
4. Vælg klub - skal loade **instant** (<0.2s)
5. Vælg bane - skal være hurtig (~0.2-0.5s)

Hvis klubber loader instant, virker cachen! ✅


