# Technical Debt & Improvement Opportunities

**Dato:** 28. december 2025  
**Version:** 1.0  
**Projekt:** DGU POC App (dgu-scorekort)  
**Status:** POC/Innovation Lab

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Cloud Functions Architecture](#cloud-functions-architecture)
3. [Security Concerns](#security-concerns)
4. [Monitoring & Observability](#monitoring--observability)
5. [Data Management](#data-management)
6. [Testing](#testing)
7. [Prioritized Action Plan](#prioritized-action-plan)
8. [Cost-Benefit Analysis](#cost-benefit-analysis)
9. [Architecture Decisions](#architecture-decisions)
10. [References](#references)

---

## Executive Summary

### Overall Assessment

**DGU POC App er funktionelt solid** ✅ - alle features virker, deployment er stable, og backend håndterer nuværende load uden problemer. Dette er **innovation-lab kode** designet til hurtig iteration og demo til GolfBox team.

### Key Observations

| Area | Status | Priority |
|------|--------|----------|
| **Functionality** | 🟢 Excellent | - |
| **Security** | 🔴 Needs Work | P0 |
| **Maintainability** | 🟡 Good, but declining | P2 |
| **Monitoring** | 🔴 Missing | P1 |
| **Testing** | 🔴 None | P2 |
| **Documentation** | 🟢 Excellent | - |

### Strategic Context

**Dette er IKKE produktionskode for "Mit Golf" appen.** Det er et innovation lab hvor Nick udvikler features der senere kopieres/reimplementeres af GolfBox team i den rigtige Mit Golf app.

**Derfor:**
- ✅ Pragmatiske løsninger er acceptable (GitHub Gists, open Firestore rules midlertidigt)
- ✅ Hurtig iteration > perfekt arkitektur
- ⚠️ Men: Security bør være ordentlig (selv i POC)
- ⚠️ iOS app skal være stable hvis den demonstreres

### Quick Wins vs. Long-term Investments

**Quick Wins (Høj Impact, Lav Effort):**
1. Firebase Crashlytics setup - 30 min, gratis, immediate visibility
2. Structured logging - 2-3 timer, bedre debugging
3. Rate limiting - 4-6 timer, beskytter mod API bans

**Long-term Investments:**
1. Firestore security rules - 1 dag, critical for production
2. Split index.js - 2-3 dage, bedre maintainability
3. iOS OAuth fix - 2-3 dage, enables iOS deployment

---

## Cloud Functions Architecture

### Current State: Monolithic `index.js`

**Metrics:**
- **Lines of Code:** 2,516 linjer i én fil
- **Functions Count:** 17 separate Cloud Functions
- **File Size:** ~85 KB
- **Complexity:** Høj - shared utilities blandet med function logic

**Structure:**
```
functions/
└── index.js (2,516 lines)
    ├── OAuth (golfboxCallback, exchangeOAuthToken)
    ├── Course Cache (updateCourseCache, forceFullReseed)
    ├── Notifications (sendNotification, sendNotificationHttp)
    ├── WHS Scores (getWhsScores, scanForMilestones)
    ├── Birdie Bonus (cacheBirdieBonusData + 2 helpers)
    ├── Tournaments (cacheTournamentsAndRankings)
    ├── Triggers (friend stats, chat stats, cleanup)
    └── Shared utils (token fetching, CORS, state parsing)
```

### Why It's a Problem

**1. Maintenance Challenges:**
- 🔴 **Navigation:** 2,516 linjer er uoverskueligt - svært at finde specifik logic
- 🔴 **Collaboration:** Merge conflicts hvis flere udviklere arbejder samtidigt
- 🔴 **Code Review:** Reviewers skal scrolle gennem hele filen
- 🔴 **Mental Model:** Svært at holde styr på dependencies mellem functions

**2. Deployment Inefficiency:**
- ⚠️ **All-or-Nothing:** Alle 17 functions deployes sammen, selv hvis kun én ændres
- ⚠️ **Deployment Time:** ~2-3 minutter per deployment (inkl. upload af hele filen)
- ⚠️ **Risk:** Én syntax error crasher alle functions
- ⚠️ **Rollback:** Skal rulle alle functions tilbage, ikke kun den fejlende

**3. Performance Impact:**
- ⚠️ **Cold Start:** Node.js skal parse 2,516 linjer ved hver cold start
- ⚠️ **Memory:** Hele filen loades i memory, selv hvis function kun bruger 50 linjer
- ⚠️ **Build Time:** Webpack/bundler skal process hele filen

**4. Testing Complexity:**
- 🔴 **Unit Tests:** Svært at teste individuelle functions isoleret
- 🔴 **Mocking:** Shared utilities skal mockes for hver test
- 🔴 **Coverage:** Svært at få accurate code coverage metrics

### Recommended Modular Structure

```
functions/
├── index.js                          # Only exports (~50 lines)
│
├── config/
│   ├── firebase.js                  # Firebase Admin init
│   ├── cors.js                      # CORS configuration
│   └── allowlist.js                 # OAuth redirect allowlist
│
├── utils/
│   ├── token-fetcher.js             # GitHub Gist token fetching
│   ├── state-parser.js              # OAuth state parsing (JSON/legacy)
│   ├── date-helpers.js              # Date formatting utilities
│   └── logger.js                    # Structured logging (future)
│
├── oauth/
│   ├── golfbox-callback.js          # ~200 lines - OAuth dispatcher
│   └── exchange-token.js            # ~100 lines - Token exchange
│
├── course-cache/
│   ├── update-cache.js              # ~300 lines - Nightly incremental update
│   ├── force-reseed.js              # ~100 lines - Manual full reseed
│   └── cache-helpers.js             # Shared cache utilities
│
├── notifications/
│   ├── send-notification.js         # ~150 lines - Callable function
│   └── send-http.js                 # ~50 lines - HTTP endpoint
│
├── whs/
│   ├── get-scores.js                # ~100 lines - Fetch WHS scores
│   └── scan-milestones.js           # ~250 lines - Milestone detection
│
├── birdie-bonus/
│   ├── cache-data.js                # ~200 lines - Main caching logic
│   ├── test-api.js                  # ~50 lines - Test endpoint
│   └── manual-cache.js              # ~50 lines - Manual trigger
│
├── tournaments/
│   └── cache-tournaments.js         # ~150 lines - Golf.dk caching
│
└── triggers/
    ├── friend-stats.js              # ~50 lines - Friendship trigger
    ├── chat-stats.js                # ~50 lines - Chat trigger
    └── cleanup-chat.js              # ~100 lines - Message cleanup
```

**New `index.js` Example:**
```javascript
// functions/index.js (~50 lines)
const { golfboxCallback, exchangeOAuthToken } = require('./oauth');
const { updateCourseCache, forceFullReseed } = require('./course-cache');
const { sendNotification, sendNotificationHttp } = require('./notifications');
const { getWhsScores, scanForMilestones } = require('./whs');
const { cacheBirdieBonusData, testBirdieBonusAPI, manualCacheBirdieBonusData } = require('./birdie-bonus');
const { cacheTournamentsAndRankings } = require('./tournaments');
const { updateFriendStats, updateChatGroupStats, updateMessageStats, cleanupOldChatMessages } = require('./triggers');

// OAuth & Authentication
exports.golfboxCallback = golfboxCallback;
exports.exchangeOAuthToken = exchangeOAuthToken;

// Course Cache
exports.updateCourseCache = updateCourseCache;
exports.forceFullReseed = forceFullReseed;

// ... etc for all 17 functions
```

### Impact of Refactoring

**✅ No Changes Required:**
- Flutter app code (function names remain samme)
- `firebase.json` (function entries unchanged)
- `firestore.rules` (ingen relation til functions)
- External integrations (URLs remain samme)
- Scheduled jobs (function names unchanged)
- OAuth callbacks (URLs unchanged)

**⚠️ Minimal Changes Required:**
- Internal imports mellem modules (if functions share utilities)
- `package.json` scripts (if you have test scripts)
- Development workflow (need to know hvor kode er nu)

**Effort Estimate:**
- **Planning:** 2-3 timer (decide module boundaries)
- **Refactoring:** 2-3 dage (split files, update imports, test)
- **Testing:** 1 dag (verify all functions work identically)
- **Documentation:** 2-3 timer (update developer guide)

**Total:** ~3-4 dage for komplet refactoring

### Benefits of Modular Structure

**Immediate:**
- ✅ Faster navigation (find function in <10 seconds vs. <2 minutes)
- ✅ Clearer dependencies (imports make relationships explicit)
- ✅ Better code review (reviewers only see changed files)

**Long-term:**
- ✅ Independent deployment (deploy only changed functions)
- ✅ Better testing (isoleret unit tests per function)
- ✅ Faster cold starts (mindre code per function)
- ✅ Team collaboration (mindre merge conflicts)

### Recommendation

**For POC App:** 🟡 **P2 Priority - Do When Time Permits**

Dette er **ikke kritisk** for POC app's funktion. Det er et maintainability problem, ikke et functional problem.

**Trigger Points:**
- ✅ Når index.js når 3,000+ linjer
- ✅ Når flere udviklere arbejder på functions samtidigt
- ✅ Når deployment time bliver et problem
- ✅ Når du skal tilføje mange nye functions

**For Mit Golf App:** ✅ **Start med modular struktur fra dag 1**

Når GolfBox implementerer features i Mit Golf, anbefal at de bruger modular structure fra starten.

---

## Security Concerns

### P0 - Critical Issues

#### 1. Open Firestore Collections

**Problem:**

Flere Firestore collections har "Open (TEMP)" security rules:

```javascript
// firestore.rules (CURRENT - INSECURE)
match /friendships/{docId} {
  allow read, write: if isAuthenticated();  // ANY logged in user!
}

match /friend_requests/{docId} {
  allow read, write: if isAuthenticated();  // ANY logged in user!
}

match /chat_groups/{docId} {
  allow read, write: if isAuthenticated();  // ANY logged in user!
}

match /messages/{groupId}/messages/{msgId} {
  allow read, write: if isAuthenticated();  // ANY logged in user!
}
```

**Risk:**

🔴 **Data Leakage:**
- Enhver authenticated user kan læse ALLE friendships (inkl. andre users' venner)
- Enhver kan læse ALLE friend requests (se hvem der requester hvem)
- Enhver kan læse ALLE chat messages i alle grupper
- Enhver kan læse ALLE privacy settings

🔴 **Unauthorized Modifications:**
- Enhver kan create falske friendships mellem andre users
- Enhver kan accept/reject andre users' friend requests
- Enhver kan delete chat messages i andres grupper
- Enhver kan modify andre users' privacy settings

🔴 **Abuse Scenarios:**
- Malicious user kan script-scrape alle friendships → build social graph
- Spammer kan send friend requests som andre users
- Troll kan delete alle messages i alle chat grupper
- Attacker kan disable privacy for alle users

**Why It Exists:**

Dette blev implementeret med "TEMP" flag under hurtig udvikling for at få features til at virke. Intentionen var altid at stramme det senere, men det er ikke sket endnu.

**Proper Security Rules:**

```javascript
// friendships - only involved users can read/write
match /friendships/{docId} {
  allow read: if isAuthenticated() && 
    (request.auth.uid == resource.data.userId1 || 
     request.auth.uid == resource.data.userId2);
  
  allow create: if isAuthenticated() && 
    (request.auth.uid == request.resource.data.userId1 || 
     request.auth.uid == request.resource.data.userId2);
  
  allow update, delete: if isAuthenticated() && 
    (request.auth.uid == resource.data.userId1 || 
     request.auth.uid == resource.data.userId2);
}

// friend_requests - sender can create, receiver can read/accept/reject
match /friend_requests/{docId} {
  allow read: if isAuthenticated() && 
    (request.auth.uid == resource.data.fromUserId || 
     request.auth.uid == resource.data.toUserId);
  
  allow create: if isAuthenticated() && 
    request.auth.uid == request.resource.data.fromUserId;
  
  allow update: if isAuthenticated() && 
    request.auth.uid == resource.data.toUserId;  // receiver accepts/rejects
  
  allow delete: if isAuthenticated() && 
    request.auth.uid == resource.data.fromUserId;  // sender can cancel
}

// chat_groups - only members can read/write
match /chat_groups/{docId} {
  allow read: if isAuthenticated() && 
    request.auth.uid in resource.data.memberIds;
  
  allow create: if isAuthenticated() && 
    request.auth.uid in request.resource.data.memberIds;
  
  allow update: if isAuthenticated() && 
    request.auth.uid in resource.data.memberIds;
  
  allow delete: if isAuthenticated() && 
    request.auth.uid == resource.data.creatorId;
}

// messages - only group members can read/write
match /messages/{groupId}/messages/{msgId} {
  allow read: if isAuthenticated() && 
    request.auth.uid in getGroupMembers(groupId);
  
  allow create: if isAuthenticated() && 
    request.auth.uid in getGroupMembers(groupId) &&
    request.auth.uid == request.resource.data.senderId;
  
  allow delete: if isAuthenticated() && 
    request.auth.uid == resource.data.senderId;
}

function getGroupMembers(groupId) {
  return get(/databases/$(database)/documents/chat_groups/$(groupId)).data.memberIds;
}
```

**Solution:**

1. Implement proper security rules (1 dag effort)
2. Test thoroughly med forskellige users
3. Deploy til production
4. Remove "TEMP" comments

**Priority:** 🔴 **P0 - Fix Before Any Production Use**

Selv for POC app, hvis du deler til kollegaer, bør dette fixes.

---

#### 2. iOS OAuth Login Loop

**Problem:**

iOS native app kan ikke login - den går i loop efter OAuth callback.

**Status:**
- ✅ Implementeret deep link detection med `app_links` plugin
- ✅ State-based OAuth redirect (web vs. iOS detection)
- 🔴 LoginScreen rebuild cycle forårsager duplicate processing
- 🔴 Guards (`_lastProcessedCode`, `_isProcessingCallback`) resettes ved rebuild
- 🔴 Multiple token exchanges → `invalid_grant` error

**Root Cause:**

```dart
// lib/screens/login_screen.dart
class _LoginScreenState extends State<LoginScreen> {
  String? _lastProcessedCode;  // Instance variable - reset on rebuild!
  bool _isProcessingCallback = false;  // Instance variable - reset!
  
  @override
  void initState() {
    _appLinks = AppLinks();
    _initDeepLinkListener();  // Creates new listener on every rebuild!
  }
}
```

LoginScreen rebuilds multiple times during OAuth flow → `initState()` runs again → new listener created → guards reset → samme OAuth code processed multiple times → `invalid_grant`.

**Impact:**
- 🔴 iOS app ikke production-ready
- 🔴 Cannot demonstrate iOS app til kollegaer
- 🔴 TestFlight build er deployed men non-functional

**Documentation:**
Comprehensive analysis in [`docs/IOS_OAUTH_LOGIN_LOOP_ISSUE.md`](IOS_OAUTH_LOGIN_LOOP_ISSUE.md)

**Proposed Solutions:**

**Option A: Move State to AuthProvider** (Recommended)
```dart
// lib/providers/auth_provider.dart
class AuthProvider with ChangeNotifier {
  String? _lastProcessedOAuthCode;
  bool _isProcessingOAuth = false;
  
  Future<void> handleOAuthCallback(String code, String? state) async {
    // Guards persist across LoginScreen rebuilds
    if (_lastProcessedOAuthCode == code || _isProcessingOAuth) return;
    
    _isProcessingOAuth = true;
    _lastProcessedOAuthCode = code;
    // ... exchange token ...
    _isProcessingOAuth = false;
  }
}
```

**Option B: Skip "Login lykkedes!" Screen**

Simplify OAuth flow: Browser → App (direct to authenticated state, no intermediate screen)

**Option C: SingletonService for Deep Links**

Create persistent service outside widget lifecycle.

**Effort:** 2-3 dage (implementation + testing på physical device)

**Priority:** 🟡 **P0 if iOS app needed, P3 otherwise**

Hvis iOS app kun er "nice to have" demo, kan dette vente. Hvis det skal bruges i produktion eller demonstreres til GolfBox, skal det fixes.

---

## Monitoring & Observability

### Current State: Blind Flying

**Missing Components:**
- ❌ No error monitoring (Sentry, Firebase Crashlytics)
- ❌ No performance monitoring
- ❌ No alerting for failed Cloud Functions
- ❌ No rate limiting on external API calls
- ❌ No uptime monitoring
- ❌ No user analytics (beyond basic Firebase Analytics)

**Current Visibility:**
- ✅ Firebase Console → Functions logs (manual inspection required)
- ✅ Cloud Logging (retained 30 days, no alerts)
- ✅ Basic console.log statements

**Problems:**

🔴 **You Don't Know When Things Break:**
- OAuth callback fails → users can't login → ingen alert
- Course cache job fails → stale data → ingen alert
- External API returns errors → ingen alert
- iOS app crashes → ingen crash reports

🔴 **Debugging is Hard:**
- Basic console.log med inconsistent formatting
- No request IDs to correlate logs
- No structured logging (can't query by field)
- No stack traces for errors

🔴 **Performance Issues are Invisible:**
- Slow Cloud Functions → no metrics
- External API latency → unknown
- Database query performance → no tracking

### Recommendations

#### 1. Firebase Crashlytics (P1 - Quick Win!)

**Setup:**

```yaml
# pubspec.yaml
dependencies:
  firebase_crashlytics: ^4.1.3
```

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Enable Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  
  runApp(const MyApp());
}
```

**Benefits:**
- ✅ Automatic crash reports (iOS + Web)
- ✅ Stack traces med source maps
- ✅ User impact metrics (how many users affected)
- ✅ Email alerts for new crashes
- ✅ FREE (included in Firebase Spark plan)

**Effort:** 30 minutter  
**Cost:** Gratis  
**Impact:** 🟢 High - Immediate visibility into crashes

---

#### 2. Structured Logging (P1)

**Current:**
```javascript
console.log('Token exchange successful');
console.log('Error:', error);
```

**Recommended:**
```javascript
// functions/utils/logger.js
const { logger } = require('firebase-functions');

function logInfo(message, metadata = {}) {
  logger.info(message, metadata);
}

function logError(message, error, metadata = {}) {
  logger.error(message, {
    error: error.message,
    stack: error.stack,
    ...metadata
  });
}

// Usage
logInfo('OAuth callback received', {
  origin: 'ios-app',
  hasCode: true,
  hasState: true
});

logError('Token exchange failed', error, {
  statusCode: response.status,
  endpoint: 'connect/token'
});
```

**Benefits:**
- ✅ Queryable logs i Cloud Logging
- ✅ Consistent format
- ✅ Severity levels (info, warn, error)
- ✅ Structured metadata (kan filtrere/aggregere)

**Effort:** 2-3 timer (create logger utility + replace console.log)  
**Cost:** Gratis (inkluderet i Cloud Logging quota)  
**Impact:** 🟢 Medium-High - Bedre debugging

---

#### 3. Rate Limiting (P1)

**Problem:**

External API calls har ingen rate limiting:

```javascript
// Birdie Bonus: Unlimited requests i tight loop
for (let page = 0; page <= maxPages; page++) {
  await fetch(`${BIRDIE_API_URL}/rating_list/${page}`);
  // No delay! Can hit API with 100+ requests in <10 seconds
}

// Golf.dk: No retry backoff
await fetch(`${GOLF_DK_URL}/rest/taxonomy_lists/current_tournaments`);
// If it fails, no intelligent retry
```

**Risk:**
- 🔴 IP ban from Birdie Bonus (if rate limit exceeded)
- 🔴 IP ban from Golf.dk/Drupal
- 🔴 DGU Statistik API throttling
- 🔴 Wasted Cloud Function execution time (retry storms)

**Solution:**

```javascript
// functions/utils/rate-limiter.js
class RateLimiter {
  constructor(requestsPerSecond = 5) {
    this.minDelay = 1000 / requestsPerSecond;
    this.lastRequest = 0;
  }
  
  async throttle() {
    const now = Date.now();
    const timeSinceLastRequest = now - this.lastRequest;
    
    if (timeSinceLastRequest < this.minDelay) {
      const delay = this.minDelay - timeSinceLastRequest;
      await new Promise(resolve => setTimeout(resolve, delay));
    }
    
    this.lastRequest = Date.now();
  }
}

// Usage
const birdieLimiter = new RateLimiter(5);  // 5 req/sec max

for (let page = 0; page <= maxPages; page++) {
  await birdieLimiter.throttle();
  await fetch(`${BIRDIE_API_URL}/rating_list/${page}`);
}
```

**Benefits:**
- ✅ Prevent API bans
- ✅ Better external API relations
- ✅ Graceful degradation under load

**Effort:** 4-6 timer (implement + test + rollout)  
**Cost:** Gratis (kan actually reducere costs ved at undgå bans)  
**Impact:** 🟢 Medium - Prevent future incidents

---

#### 4. Cloud Functions Error Alerting (P2)

**Setup:**

```javascript
// functions/index.js - Add to each function
exports.updateCourseCache = functions.pubsub
  .schedule('0 2 * * *')
  .timeZone('Europe/Copenhagen')
  .onRun(async (context) => {
    try {
      // ... cache logic ...
      logger.info('Course cache updated successfully');
    } catch (error) {
      logger.error('Course cache failed!', {
        error: error.message,
        stack: error.stack
      });
      
      // Send alert email (optional)
      await sendAlertEmail({
        subject: '🚨 Course Cache Failed',
        body: `Error: ${error.message}\n\nStack: ${error.stack}`
      });
      
      throw error;  // Re-throw so Cloud Functions marks it as failed
    }
  });
```

**Setup Cloud Logging Alert:**
1. Go to Cloud Logging → Logs Explorer
2. Create alert: `severity = "ERROR" AND resource.type = "cloud_function"`
3. Notification channel: Email til nih@dgu.org
4. Trigger: Immediate (don't batch)

**Benefits:**
- ✅ Know immediately when functions fail
- ✅ Email/SMS alerts
- ✅ Track failure trends

**Effort:** 1 dag (wrap all functions + setup alerts)  
**Cost:** Minimal (Cloud Logging alerts included)  
**Impact:** 🟢 High for production, Low for POC

---

## Data Management

### 1. No Backup Strategy

**Current State:**
- ❌ Firestore har ingen automated backups
- ❌ No disaster recovery plan
- ❌ No point-in-time recovery

**Risk:**

🔴 **Data Loss Scenarios:**
- Accidental bulk delete (e.g., buggy Cloud Function)
- Malicious user (hvis security rules ikke proper)
- Firebase account compromise
- Bug i database migration

🔴 **Recovery Impossible:**
- Hvis friendships collection slettes → permanent tab
- Hvis chat messages corrupted → no rollback
- Hvis course cache destroyed → kun rebuild fra API

**Current Mitigation:**
- ✅ Course cache kan rebuildes fra DGU API (via `forceFullReseed`)
- ✅ WHS scores cached, men source er Statistik API
- ⚠️ User-generated content (friendships, chat) er **NOT** recoverable

**Solution:**

Enable Firebase automated backups:

```bash
# Enable daily backups (via Firebase Console eller gcloud)
gcloud firestore backups schedules create \
  --database='(default)' \
  --recurrence=daily \
  --retention=7d
```

**Cost:**
- ~$0.02/GB/month storage
- ~$0.09/GB egress (if restored)
- Estimated: $5-10/month for POC app

**For POC App:**

🟡 **P3 Priority** - Not critical for POC stage. User-generated data er minimal, og det meste kan rebuildes.

**For Mit Golf App:**

🔴 **P0 Priority** - Production app skal have proper backup strategy.

---

### 2. Token Storage i GitHub Gists

**Current State:**

API tokens stored in private GitHub Gists:

```javascript
// functions/index.js
const TOKEN_GIST_URL = 'https://gist.githubusercontent.com/nhuttel/a907dd7d60bf417b584333dfd5fff74a/raw/.../dgu_token.txt';
```

**Why It's "Debt":**

🟡 **Security Concerns:**
- Gists are "private" men ikke enterprise-grade secret management
- No audit logging (hvem har accessed tokens)
- No automatic rotation support
- Tokens visible i Cloud Functions logs (hvis logged)
- GitHub account compromise = all tokens exposed

🟡 **Operational Concerns:**
- Manual process for token rotation
- Gist URL change → need to redeploy functions
- No versioning (can't rollback to previous token)

**Why It's Actually Fine for POC:**

✅ **Pragmatic Solution:**
- Quick setup (5 minutter per token)
- Easy rotation (just update Gist content)
- Works reliably
- No extra costs
- Clear separation from codebase

✅ **Acceptable Risk Level:**
- POC app ikke handling payment eller sensitive PII
- Limited user base (Nick + test users)
- Easy to monitor (limited access)

**Migration Plan:**

Already documented in [`docs/BACKEND_ARCHITECTURE.md`](BACKEND_ARCHITECTURE.md#api-credentials-reference)

**Future State: Firebase Secret Manager**

```javascript
// functions/utils/secrets.js
const { SecretManagerServiceClient } = require('@google-cloud/secret-manager');
const client = new SecretManagerServiceClient();

async function getSecret(secretName) {
  const [version] = await client.accessSecretVersion({
    name: `projects/dgu-scorekort/secrets/${secretName}/versions/latest`,
  });
  return version.payload.data.toString();
}

// Usage
const dguToken = await getSecret('DGU_API_TOKEN');
```

**Benefits of Secret Manager:**
- ✅ Enterprise-grade security
- ✅ Automatic audit logging (who accessed what, when)
- ✅ Versioning (can rollback tokens)
- ✅ IAM integration (fine-grained permissions)
- ✅ Automatic rotation support

**Effort:** 1 dag migration  
**Cost:** $0.06 per 10,000 access operations (minimal for POC)  
**Priority:** 🟡 **P2** - Not urgent for POC, recommended for Mit Golf

---

## Testing

### Current State: No Automated Tests

**Test Coverage:**
- ❌ 0% unit test coverage
- ❌ No integration tests
- ❌ No end-to-end tests
- ❌ No CI/CD pipeline with tests

**Current Testing Approach:**
- ✅ Manual testing i browser
- ✅ Firebase Emulator for local development
- ✅ Test users (177-2813, 8-9997, etc.)
- ✅ Staging deployments before production

**Why This is OK for POC:**

✅ **POC Context:**
- Single developer (Nick)
- Rapid iteration > stability
- Features demonstrated til GolfBox → de implementerer med deres tests
- Short lifespan (features "graduate" til Mit Golf)

**Why This Would Be Bad for Production:**

🔴 **Production Concerns:**
- Regression bugs når refactoring
- Breaking changes ikke detected før deployment
- Difficult onboarding (new developers don't know if changes broke anything)
- No confidence in deploy safety

### Recommendations

#### 1. Critical Path Testing (P2)

**Focus Areas:**

Test kun de mest kritiske flows:

**OAuth Flow:**
```javascript
// tests/oauth/golfbox-callback.test.js
const { golfboxCallback } = require('../../oauth/golfbox-callback');

describe('golfboxCallback', () => {
  it('redirects iOS app to custom URL scheme', () => {
    const req = {
      query: {
        code: 'abc123',
        state: base64Encode(JSON.stringify({ origin: 'ios-app', verifier: 'xyz' }))
      }
    };
    const res = { redirect: jest.fn() };
    
    golfboxCallback(req, res);
    
    expect(res.redirect).toHaveBeenCalledWith('dgupoc://login?code=abc123&state=...');
  });
  
  it('redirects web app to HTTPS URL', () => {
    // ... test case ...
  });
  
  it('rejects unauthorized redirect URLs', () => {
    // ... test case ...
  });
});
```

**Course Cache:**
```javascript
// tests/course-cache/update-cache.test.js
describe('updateCourseCache', () => {
  it('performs incremental update when cache exists', async () => {
    // ... test case ...
  });
  
  it('performs full reseed when cache is empty', async () => {
    // ... test case ...
  });
  
  it('handles API failures gracefully', async () => {
    // ... test case ...
  });
});
```

**Effort:** 2-3 dage initial setup + writing critical tests  
**Priority:** 🟡 **P2** - Nice to have for POC, critical for Mit Golf

---

#### 2. Test Framework Setup

**Recommended Stack:**

```json
// functions/package.json
{
  "devDependencies": {
    "jest": "^29.5.0",
    "firebase-functions-test": "^3.1.0",
    "@google-cloud/firestore": "^7.10.0"
  },
  "scripts": {
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

**Firebase Emulator for Integration Tests:**

```javascript
// tests/setup.js
const { initializeTestEnvironment } = require('@firebase/rules-unit-testing');

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: 'dgu-scorekort-test',
    firestore: {
      host: 'localhost',
      port: 8080
    }
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});
```

**Benefits:**
- ✅ Catch bugs before deployment
- ✅ Safe refactoring (tests catch regressions)
- ✅ Documentation (tests show how code should be used)
- ✅ Onboarding (new developers can run tests)

**Effort:** 1 dag setup + 2-3 dage writing tests  
**Priority:** 🟡 **P2** for POC, 🔴 **P0** for Mit Golf

---

## Prioritized Action Plan

### P0 - Critical (Fix Nu)

| # | Item | Effort | Impact | Owner | Status |
|---|------|--------|--------|-------|--------|
| 1 | **Firestore Security Rules** | 1 dag | 🔴 High | Nick | Not Started |
| 2 | **Firebase Crashlytics Setup** | 30 min | 🟢 High | Nick | Not Started |
| 3 | **iOS OAuth Loop Fix** | 2-3 dage | 🟡 Medium* | Nick | Documented, Not Fixed |

\*High impact IF iOS app skal bruges i produktion/demo

**Rationale:**

1. **Security rules:** Åben adgang er farligt selv for POC. Hvis kollegaer bruger appen, skal data være beskyttet.
2. **Crashlytics:** Minimal effort, høj værdi. Giver immediate visibility.
3. **iOS OAuth:** Kun kritisk hvis iOS app skal demonstreres/bruges.

---

### P1 - Important (Næste Sprint)

| # | Item | Effort | Impact | Notes |
|---|------|--------|--------|-------|
| 4 | **Rate Limiting for External APIs** | 4-6 timer | 🟢 Medium | Prevent API bans |
| 5 | **Structured Logging** | 2-3 timer | 🟢 Medium | Better debugging |
| 6 | **OAuth Retry Logic** | 4 timer | 🟡 Medium | Single point of failure mitigation |
| 7 | **Error Alerting** | 1 dag | 🟢 Medium | Know when functions fail |

**Rationale:**

Disse forbedringer gør appen mere robust uden at ændre fundamental arkitektur. De er relativt hurtige og giver god value.

---

### P2 - Should Have (Når Tid Tillader)

| # | Item | Effort | Impact | Notes |
|---|------|--------|--------|-------|
| 8 | **Split index.js i Moduler** | 2-3 dage | 🟡 Medium | Better maintainability |
| 9 | **Migrate Tokens til Secret Manager** | 1 dag | 🟡 Low-Medium | Better security |
| 10 | **Critical Path Tests** | 2-3 dage | 🟡 Medium | Prevent regressions |
| 11 | **Firestore Backup Strategy** | 1 time | 🟡 Low | Disaster recovery |

**Rationale:**

Disse er "nice to have" for POC men kritiske for production app. De kan vente til efter P0/P1 er done.

---

### P3 - Nice to Have

| # | Item | Effort | Impact | Notes |
|---|------|--------|--------|-------|
| 12 | **Performance Monitoring** | 1 dag | 🟢 Low | Optimization insights |
| 13 | **Health Check Endpoints** | 4 timer | 🟢 Low | Uptime monitoring |
| 14 | **API Response Caching** | 2 dage | 🟡 Low-Medium | Reduce external API calls |
| 15 | **E2E Tests (Cypress)** | 3-4 dage | 🟡 Low | Full flow testing |

**Rationale:**

Disse er optimizations der giver marginal benefit for POC stage. Kan vente indefinitely for POC, men overvej for Mit Golf.

---

## Cost-Benefit Analysis

### Quick Wins (Høj Impact, Lav Effort)

**1. Firebase Crashlytics**
- **Effort:** 30 minutter
- **Cost:** Gratis
- **Impact:** 🟢 Høj - Immediate visibility into crashes
- **ROI:** ⭐⭐⭐⭐⭐ Excellent

**2. Structured Logging**
- **Effort:** 2-3 timer
- **Cost:** Gratis (inkluderet i Cloud Logging quota)
- **Impact:** 🟢 Medium-High - Bedre debugging
- **ROI:** ⭐⭐⭐⭐⭐ Excellent

**3. Rate Limiting**
- **Effort:** 4-6 timer
- **Cost:** Gratis (kan actually spare costs)
- **Impact:** 🟢 Medium - Prevent API bans
- **ROI:** ⭐⭐⭐⭐ Very Good

**Total Quick Wins:** ~1 arbejdsdag, massiv improvement i observability

---

### Long-term Investments

**1. Firestore Security Rules**
- **Effort:** 1 dag
- **Cost:** Gratis
- **Impact:** 🔴 Critical for any production use
- **ROI:** ⭐⭐⭐⭐⭐ Essential (mandatory for production)

**2. Split index.js**
- **Effort:** 2-3 dage
- **Cost:** Gratis
- **Impact:** 🟡 Medium - Better maintainability
- **ROI:** ⭐⭐⭐ Good (higher for multi-developer teams)

**3. Automated Tests**
- **Effort:** 2-3 dage initial + ongoing
- **Cost:** Gratis (eller minimal for CI/CD)
- **Impact:** 🟡 Medium - Prevent regressions
- **ROI:** ⭐⭐⭐⭐ Very Good (pays off over time)

**4. Token Migration til Secret Manager**
- **Effort:** 1 dag
- **Cost:** ~$5/month
- **Impact:** 🟡 Low-Medium - Better security
- **ROI:** ⭐⭐⭐ Good (higher for production)

---

### Recommended Sequence

**Phase 1: Quick Wins (1 dag)**
1. Firebase Crashlytics setup (30 min)
2. Structured logging implementation (2-3 timer)
3. Rate limiting for external APIs (4-6 timer)

**Phase 2: Critical Security (1-2 dage)**
4. Firestore security rules (1 dag)
5. iOS OAuth fix (2-3 dage) - hvis iOS app skal bruges

**Phase 3: Long-term Maintenance (4-5 dage)**
6. Split index.js i moduler (2-3 dage)
7. Critical path tests (2-3 dage)

**Phase 4: Production Ready (2-3 dage)**
8. Token migration til Secret Manager (1 dag)
9. Error alerting setup (1 dag)
10. Backup strategy (1 time)

**Total:** ~10-12 arbejdsdage for "production ready" status

---

## Architecture Decisions

### Why Shared Firebase Project?

**Decision:** POC App og Short Game deler samme Firebase projekt (`dgu-scorekort`)

**Rationale:**

✅ **Benefits:**
1. **Fælles OAuth Flow:** Begge apps bruger Golfbox OAuth → kun én `golfboxCallback` function nødvendig
2. **Reduced Costs:** Én Firebase Blaze plan, delt quota, shared Cloud Functions execution time
3. **Simplified Management:** Ét projekt at deploye, monitor, og vedligeholde
4. **Shared Authentication:** Users kan bruge samme login på tværs af apps (future integration mulig)
5. **Easy Data Sharing:** Hvis Short Game skal integreres i POC senere, data er allerede i samme database

✅ **Isolation Strategy:**
- Separate Firestore collections (`shortgame_rounds` vs. `friendships`, `activities`, etc.)
- Separate hosting sites (`dgu-app-poc.web.app` vs. `dgu-shortgame.web.app`)
- Separate codebase repositories
- Firestore security rules per collection

✅ **Risk Mitigation:**
- Cloud Functions failure påvirker begge apps (mitigeret ved stable code)
- Firestore quota deles (mitigeret ved efficient queries)
- Deployment er coupled (mitigeret ved `firebase deploy --only hosting:poc`)

**Alternative Considered:** Separate Firebase projects

❌ **Rejected Because:**
- Duplicate OAuth Cloud Function (maintenance burden)
- Double costs (to Blaze plans)
- Complex management (to consoles, to deployments)
- No data sharing muligt uden cross-project API

**Conclusion:** Shared project er optimal for POC stage. Re-evaluate hvis apps diverge significantly eller hvis Mit Golf skal overtage.

**Documentation:** [`docs/BACKEND_ARCHITECTURE.md#multi-app-architecture`](BACKEND_ARCHITECTURE.md#multi-app-architecture)

---

### Why GitHub Gists for Tokens?

**Decision:** API tokens stored i private GitHub Gists, fetched at runtime

**Rationale:**

✅ **POC Stage Benefits:**
1. **Quick Setup:** 5 minutter per token (create Gist, copy URL)
2. **Easy Rotation:** Just update Gist content, no redeploy needed (hvis URL unchanged)
3. **Clear Separation:** Tokens never committed to git
4. **No Extra Tools:** No need for Secret Manager, KMS, eller HashiCorp Vault
5. **Cost:** Gratis (Gists are free)

✅ **Acceptable Risk for POC:**
- Limited user base (Nick + test users)
- No payment processing
- Easy to monitor access (limited scope)
- Can migrate later when needed

❌ **Not Enterprise-Grade:**
- No audit logging (can't see who accessed tokens)
- No automatic rotation
- Gists are "private" men ikke designed som secret store
- GitHub account compromise = all tokens exposed

**Migration Plan:** Documented in [`docs/BACKEND_ARCHITECTURE.md#api-credentials-reference`](BACKEND_ARCHITECTURE.md#api-credentials-reference)

**Future State:** Firebase Secret Manager eller Google Cloud Secret Manager

**Conclusion:** Pragmatic temporary solution. Perfect for POC, migrate for production.

---

### Why No Microservices?

**Decision:** Monolithic Cloud Functions i ét Firebase projekt

**Rationale:**

✅ **Current Scale Doesn't Warrant Microservices:**
- 17 Cloud Functions (manageable in monolith)
- Single developer (Nick)
- Shared utilities (token fetching, CORS, state parsing)
- Limited traffic (POC stage)

✅ **Monolith Benefits:**
- **Simplicity:** Ét deployment, ét repository (for functions)
- **Shared Code:** Utilities bruges på tværs af functions
- **Easy Development:** Kan teste alt lokalt i Firebase Emulator
- **Lower Latency:** Functions kan call each other in-process (no network hop)

❌ **Microservices Would Add Complexity:**
- Multiple repositories/folders
- API versioning between services
- Network calls mellem services (latency)
- Distributed debugging (correlation IDs nødvendige)
- More deployment complexity

**Trigger Points for Microservices:**
- ✅ Når functions antal vokser til 50+
- ✅ Når multiple teams arbejder på different areas
- ✅ Når functions har vidt forskellige dependencies (language, frameworks)
- ✅ Når independent scaling nødvendigt (some functions high-traffic, others low)

**Current Recommendation:** **Split index.js i moduler**, men behold monolithic deployment. Dette giver 80% of benefits uden microservice complexity.

**Conclusion:** Monolith er correct architecture for POC stage. Re-evaluate for Mit Golf baseret på scale og team size.

---

## References

### Internal Documentation

- **[`docs/BACKEND_ARCHITECTURE.md`](BACKEND_ARCHITECTURE.md)**  
  Complete backend overview: Cloud Functions, Firestore, APIs, multi-app architecture
  
- **[`docs/IOS_OAUTH_LOGIN_LOOP_ISSUE.md`](IOS_OAUTH_LOGIN_LOOP_ISSUE.md)**  
  Detailed analysis of iOS OAuth login loop problem
  
- **[`docs/IOS_MIGRATION_LESSONS_LEARNED.md`](IOS_MIGRATION_LESSONS_LEARNED.md)**  
  Lessons learned from adding iOS platform support
  
- **[`docs/IOS_PLATFORM_SUPPORT_GUIDE.md`](IOS_PLATFORM_SUPPORT_GUIDE.md)**  
  Guide for migrating Flutter web app to iOS (for Short Game app)

### Code References

- **[`functions/index.js`](../functions/index.js)**  
  Monolithic Cloud Functions file (2,516 lines)
  
- **[`firestore.rules`](../firestore.rules)**  
  Current Firestore security rules (with "TEMP" open access)
  
- **[`lib/screens/login_screen.dart`](../lib/screens/login_screen.dart)**  
  iOS OAuth deep link handling (with TODO comments referencing login loop issue)

### External Resources

- **[Firebase Security Rules Documentation](https://firebase.google.com/docs/firestore/security/get-started)**  
  Guide to writing proper Firestore security rules
  
- **[Firebase Crashlytics Documentation](https://firebase.google.com/docs/crashlytics)**  
  Setup guide for crash reporting
  
- **[Google Cloud Secret Manager](https://cloud.google.com/secret-manager/docs)**  
  Enterprise secret management solution
  
- **[Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)**  
  Local testing environment for Cloud Functions and Firestore

---

## Changelog

| Date | Version | Changes | Author |
|------|---------|---------|--------|
| 2025-12-28 | 1.0 | Initial technical debt documentation | Nick Hüttel |

---

## Appendix: Quick Reference Commands

**Deploy Functions:**
```bash
firebase deploy --only functions
```

**Deploy Specific Function:**
```bash
firebase deploy --only functions:golfboxCallback
```

**Test Locally with Emulator:**
```bash
firebase emulators:start --only functions,firestore
```

**View Cloud Function Logs:**
```bash
firebase functions:log --only updateCourseCache --limit 50
```

**Check Firestore Rules:**
```bash
firebase firestore:rules get
```

**Run Tests (when implemented):**
```bash
cd functions && npm test
```

---

**End of Document**

