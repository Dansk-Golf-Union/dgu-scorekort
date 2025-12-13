# Firebase Functions v5 Opgraderingsplan

## Oversigt

Når I i fremtiden skal opgradere til firebase-functions v5, er det vigtigt at have en solid teststrategi og migrationsplan. Denne plan sikrer at I kan opgradere trygt uden at bryde produktionen.

## Nuværende Status

**Versioner i dag:**
- `firebase-functions`: v4.9.0 ✅
- `firebase-admin`: v12.0.0 ✅
- `firebase-functions-test`: v3.1.0 ✅

**Dine 4 Cloud Functions:**
1. `updateCourseCache` - Scheduled (nightly kl. 02:00)
2. `forceFullReseed` - Callable
3. `sendNotification` - Callable  
4. `golfboxCallback` - HTTP Request

## Breaking Changes i v5

### API Ændringer

**V4 Syntax (hvad I bruger nu):**
```javascript
exports.myFunction = functions
  .region('europe-west1')
  .runWith({ timeoutSeconds: 540, memory: '1GB' })
  .pubsub.schedule('0 2 * * *')
  .onRun(async (context) => { ... });
```

**V5 Syntax (fremtidig):**
```javascript
const { onSchedule } = require('firebase-functions/v2/scheduler');

exports.myFunction = onSchedule({
  schedule: '0 2 * * *',
  timeZone: 'Europe/Copenhagen',
  region: 'europe-west1',
  timeoutSeconds: 540,
  memory: '1GiB', // Note: 1GiB not 1GB
}, async (event) => { ... });
```

### Vigtige Forskelle

- **Import struktur:** v5 bruger `/v2/` namespaces (`firebase-functions/v2/scheduler`, `/v2/https`, osv.)
- **Config format:** Options flyttes fra `.runWith()` ind i options object
- **Memory units:** `1GB` → `1GiB`
- **Context parameter:** Hedder nu `event` i stedet for `context`
- **Callable functions:** Returnerer `CallableRequest` med `event.data` og `event.auth`

## Fase 1: Test Infrastructure (Gør Dette Først!)

### 1.1 Unit Tests for Eksisterende Functions

Opret `functions/test/index.test.js`:

```javascript
const test = require('firebase-functions-test')();
const admin = require('firebase-admin');

describe('Cloud Functions Tests', () => {
  let myFunctions;

  before(() => {
    myFunctions = require('../index');
  });

  after(() => {
    test.cleanup();
  });

  describe('updateCourseCache', () => {
    it('should run successfully', async () => {
      const wrapped = test.wrap(myFunctions.updateCourseCache);
      const result = await wrapped({});
      // Add assertions here
    });
  });

  describe('sendNotification', () => {
    it('should validate required fields', async () => {
      const data = { markerUnionId: '123', playerName: 'Test', approvalUrl: 'https://...' };
      const context = { auth: { uid: 'testUser' } };
      const wrapped = test.wrap(myFunctions.sendNotification);
      const result = await wrapped(data, context);
      // Add assertions
    });
  });
});
```

### 1.2 Integration Tests med Firebase Emulator

Opdater `functions/package.json`:

```json
{
  "scripts": {
    "test": "mocha test/**/*.test.js --timeout 10000",
    "test:watch": "mocha test/**/*.test.js --watch",
    "emulator": "firebase emulators:start --only functions,firestore",
    "test:integration": "firebase emulators:exec --only functions,firestore 'npm test'"
  },
  "devDependencies": {
    "firebase-functions-test": "^3.1.0",
    "mocha": "^10.0.0",
    "chai": "^4.3.0",
    "sinon": "^15.0.0"
  }
}
```

### 1.3 Lokal Test Workflow

```bash
# Kør emulator + test
npm run test:integration

# Eller manuelt
firebase emulators:start --only functions
# I anden terminal:
npm test
```

## Fase 2: Pre-Migration Forberedelse

### 2.1 Tilføj Monitoring

Tilføj logging i kritiske steder i `functions/index.js`:

```javascript
// Ved start af hver function
console.log('Function invoked:', {
  functionName: 'updateCourseCache',
  timestamp: new Date().toISOString(),
  version: '4.9.0' // Skift til '5.0.0' efter migration
});

// Ved success
console.log('Function completed:', {
  functionName: 'updateCourseCache',
  duration: duration,
  success: true
});
```

### 2.2 Dokumenter Nuværende Adfærd

Kør functions og dokumenter output:

```bash
# Check logs for normal operation
firebase functions:log --only updateCourseCache --limit 5

# Document expected behavior:
# - Expected execution time: ~15-20 sek
# - Expected clubs updated: 213
# - Expected courses: ~876
```

## Fase 3: Migration til v5

### 3.1 Opret Migration Branch

```bash
git checkout -b upgrade/firebase-functions-v5
```

### 3.2 Installer v5 Pakker

```bash
cd functions
npm install --save firebase-functions@^5.0.0
npm install --save firebase-functions-test@^3.3.0
```

### 3.3 Migrer Hver Function Individuelt

**Start med den simpleste:** `golfboxCallback` (HTTP request)

**V4 (før):**
```javascript
exports.golfboxCallback = functions
  .region('europe-west1')
  .https.onRequest((req, res) => { ... });
```

**V5 (efter):**
```javascript
const { onRequest } = require('firebase-functions/v2/https');

exports.golfboxCallback = onRequest({
  region: 'europe-west1',
  cors: true, // Explicit CORS config if needed
}, (req, res) => { ... });
```

### 3.4 Migration Rækkefolge

1. ✅ **`golfboxCallback`** (HTTP - simplest, ingen eksterne afhængigheder)
2. ✅ **`forceFullReseed`** (Callable - simpel logic)
3. ✅ **`sendNotification`** (Callable - medium kompleksitet)
4. ✅ **`updateCourseCache`** (Scheduled - mest kritisk, test grundigt!)

### 3.5 Komplet V5 Template for updateCourseCache

```javascript
const { onSchedule } = require('firebase-functions/v2/scheduler');

exports.updateCourseCache = onSchedule({
  schedule: '0 2 * * *',
  timeZone: 'Europe/Copenhagen',
  region: 'europe-west1',
  timeoutSeconds: 540,
  memory: '1GiB', // Changed from '1GB'
  maxInstances: 1, // Prevent concurrent runs
}, async (event) => {
  // ALL YOUR EXISTING LOGIC STAYS THE SAME
  // Just change 'context' → 'event' if you reference it
  console.log('🕒 Starting scheduled course cache update...');
  // ... existing code ...
});
```

## Fase 4: Validering & Testing

### 4.1 Test Checklist

**Lokal testing:**
- [ ] Unit tests pass: `npm test`
- [ ] Functions starter i emulator: `firebase emulators:start`
- [ ] Kan trigger manuelt i emulator UI
- [ ] Output matcher forventet format

**Staging deployment:**
```bash
# Deploy til separate test functions (nye navne)
firebase deploy --only functions:updateCourseCacheV5Test
firebase deploy --only functions:sendNotificationV5Test
```

**Produktions-test (controlled rollout):**
- [ ] Deploy én function ad gangen
- [ ] Vent 24-48 timer mellem hver
- [ ] Monitorer logs: `firebase functions:log`
- [ ] Check Firestore data efter `updateCourseCache` run
- [ ] Test notifications manuelt

### 4.2 Rollback Plan

Hvis noget går galt:

```bash
# Revert til v4 via git
git checkout main -- functions/

# Re-deploy gamle versioner
cd functions
npm install
cd ..
firebase deploy --only functions
```

## Fase 5: Post-Migration

### 5.1 Performance Comparison

Sammenlign metrics før/efter:

| Metric | V4 | V5 | Delta |
|--------|----|----|-------|
| Execution time (updateCourseCache) | ~16s | ? | ? |
| Cold start time | ? | ? | ? |
| Memory usage | ? | ? | ? |
| Cost per run | ? | ? | ? |

### 5.2 Dokumentér Ændringer

Opdater `README.md` med:
- Ny version info
- Breaking changes applied
- Migration date
- Rollback procedure

### 5.3 Cleanup

```bash
# Fjern test functions
firebase functions:delete updateCourseCacheV5Test
firebase functions:delete sendNotificationV5Test
```

## Arkitektur-Forbedringer (Bonus)

### Option 1: Modularisering

Split `functions/index.js` (742 lines!) i separate filer:

```
functions/
├── index.js (exports only)
├── cache/
│   ├── updateCourseCache.js
│   └── forceFullReseed.js
├── notifications/
│   └── sendNotification.js
├── oauth/
│   └── golfboxCallback.js
└── shared/
    ├── dguApi.js
    ├── firestore.js
    └── utils.js
```

**Fordele:**
- Lettere at teste individuelle functions
- Bedre code organization
- Lettere at finde bugs
- Mindre risk ved ændringer

### Option 2: TypeScript Migration

Konverter til TypeScript for bedre type safety:

```typescript
// functions/src/cache/updateCourseCache.ts
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';

interface CacheUpdateResult {
  success: boolean;
  updateType: 'full' | 'incremental';
  clubCount: number;
  courseCount: number;
}

export const updateCourseCache = onSchedule({
  schedule: '0 2 * * *',
  timeZone: 'Europe/Copenhagen',
  region: 'europe-west1',
  timeoutSeconds: 540,
  memory: '1GiB',
}, async (event): Promise<CacheUpdateResult> => {
  logger.info('Starting cache update');
  // ... implementation ...
});
```

**Fordele:**
- Type safety eliminerer mange runtime errors
- Better IDE autocomplete
- Lettere refactoring
- Industry best practice

## Kritiske Punkter at Huske

⚠️ **ALDRIG opgrader direkte i produktion uden test!**

✅ **Test workflow:**
1. Unit tests lokalt
2. Integration tests i emulator
3. Deploy til staging/test functions
4. Monitorer i 24-48 timer
5. Deploy til produktion én function ad gangen
6. Monitorer mellem hver deployment

✅ **Backup plan:**
- Git branch for rollback
- Dokumenterede rollback steps
- Test rollback procedure før migration

✅ **Communication:**
- Planlæg migration i rolig periode (ikke før weekend!)
- Notificer stakeholders
- Vær klar til at overvåge i 24 timer efter deployment

## Tidslinje Estimat

| Fase | Estimeret tid |
|------|---------------|
| 1. Test infrastructure | 1-2 dage |
| 2. Pre-migration prep | 0.5 dag |
| 3. Migration kode | 1 dag |
| 4. Testing & validation | 2-3 dage |
| 5. Staged production rollout | 1 uge |
| **Total** | **~2 uger** |

## Konklusion

Når I er klar til at opgradere til v5:
1. 📋 Start med test infrastructure (Fase 1)
2. 🧪 Test GRUNDIGT lokalt
3. 🚀 Deploy staged til produktion
4. 📊 Monitorer tæt i første uge
5. ✅ Dokumentér alt

**Vigtigst:** Lad v4 være indtil I BEHØVER v5 features. Det virker perfekt nu! 🎯

