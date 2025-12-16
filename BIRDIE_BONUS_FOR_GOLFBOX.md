# Birdie Bonus Bar - POC Implementation Reference

> **Context**: This document describes how we implemented the Birdie Bonus Bar in our Flutter POC app.
> This POC was built by an amateur developer (the customer/product owner) with Cursor AI assistance as a proof of concept for the DGU Scorekort integration into Mit Golf.
> 
> The native Mit Golf app has proper OAuth infrastructure, established Firebase patterns, and professional architecture. You'll likely take a different (and better) approach.
> 
> **This is shared purely as reference** - not as prescriptive guidance. Take what's useful, discard what's not.

---

## 1. POC Context & Overview

### 1.1 What We Built

A "Birdie Bonus Bar" component that displays on the home screen for users participating in the DGU Birdie Bonus competition:

- **Birdie count**: Total birdies scored in the competition
- **Ranking position**: Player's position in their region/handicap group
- **Conditional display**: Bar only shows if user is registered as participant
- **Clickable**: Opens Birdie Bonus leaderboard website

### 1.2 Architecture We Chose

```
Birdie Bonus API (paginated)
    ↓ (nightly @ 04:00 CET)
Cloud Function: cacheBirdieBonusData
    ↓ (batch writes to Firestore)
Firestore Collection: birdie_bonus_cache
    ↓ (server read with Source.server workaround)
Flutter Service: BirdieBonusService
    ↓ (loaded in didChangeDependencies lifecycle)
Home Screen Widget: BirdieBonusBar (conditional render)
```

**Why this pattern**: Server-side caching to avoid exposing API credentials to client, similar to how we cache course data.

### 1.3 Your Advantages (Native App)

The native Mit Golf app has several advantages that will simplify your implementation:

1. **Proper OAuth**: You have `unionId` (DGU-nummer) in auth tokens - no workarounds needed
2. **Established Firebase patterns**: You already have working Cloud Functions and Firestore security rules
3. **No cache issues**: You won't need our `Source.server` hack (Flutter-specific bug)
4. **Native UI**: No cross-platform compromises - can use native iOS/Android components

---

## 2. How We Integrated the Birdie Bonus API

### 2.1 API Discovery

We received API access to the Birdie Bonus system:

**Endpoint**: `https://birdie.bonus.sdmdev.dk/api/member/rating_list/{page}`

**Authentication**: Basic Auth
- Credentials stored in private GitHub Gist (not in code)
- Format: `Authorization: Basic [base64-encoded-credentials]`
- Gist URL fetched by Cloud Function server-side

**Important**: The API is **paginated** - you must fetch all pages to get complete data.

### 2.2 Pagination Implementation

The API uses numeric page indices starting from `/0`:

**Request**:
```
GET https://birdie.bonus.sdmdev.dk/api/member/rating_list/0
GET https://birdie.bonus.sdmdev.dk/api/member/rating_list/1
GET https://birdie.bonus.sdmdev.dk/api/member/rating_list/2
... (continue until next_page is null)
```

**Response Structure**:
```json
{
  "data": [
    {
      "dguNumber": "177-2813",
      "Birdiebonuspoints": 5,
      "rankInRegionGroup": 630,
      "regionLabel": "Sjælland",
      "hcpGroupLabel": "11.5-18.4",
      "BB participant": 2
    }
    // ... more participants
  ],
  "next_page": 1  // or null when done
}
```

**Key Field Notes**:
- `dguNumber`: Player's DGU union ID (string, e.g., "177-2813")
- `Birdiebonuspoints`: Total birdies (note lowercase 'p')
- `rankInRegionGroup`: Position in leaderboard
- `"BB participant"`: Participant sequence number (note: has space in name!)
  - Values: `2`, `3`, `4`, etc. (sequential participant IDs)
  - **All values > 0 mean active participant** (not a status code!)
  - If present in API, player is participating in Birdie Bonus

### 2.3 Our Pagination Loop

We implemented a simple loop that fetches pages sequentially until `next_page` is `null`:

```javascript
let page = 0;
let nextPage = 0; // Start at page 0
const allParticipants = [];

while (nextPage !== null) {
  const result = await fetchBirdieBonusPage(page, authToken);
  
  if (result.participants.length > 0) {
    allParticipants.push(...result.participants);
  }
  
  nextPage = result.nextPage;
  if (nextPage !== null) {
    page = nextPage;
  }
}
```

**Our Implementation**: See `functions/index.js` lines 538-570

---

## 3. Our Backend Implementation (Cloud Function)

### 3.1 cacheBirdieBonusData Function

We created a scheduled Cloud Function that runs nightly to refresh the participant cache.

**Function Name**: `cacheBirdieBonusData`

**Our Implementation**:
- **File**: `functions/index.js` lines 475-606
- **Region**: `europe-west1` (same as our other functions)
- **Memory**: 512MB
- **Timeout**: 9 minutes (540 seconds)
- **Trigger**: PubSub scheduled

### 3.2 Why We Chose Nightly Scheduling

**Schedule**: Every night at 04:00 Copenhagen time

**Reasoning**:
- Birdie Bonus data changes slowly (only after rounds are completed)
- 24-hour cache staleness is acceptable for leaderboard data
- Avoids rate-limiting or excessive API calls
- Runs after our course cache update (which runs at 02:00)

**Cron Expression**: `0 4 * * *`

**Implementation**:
```javascript
exports.cacheBirdieBonusData = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 540,
    memory: '512MB'
  })
  .pubsub.schedule('0 4 * * *')
  .timeZone('Europe/Copenhagen')
  .onRun(async (context) => {
    // Implementation...
  });
```

### 3.3 Our Batch Write Strategy

Firestore has a limit of 500 operations per batch, so we chunk writes:

**Our Approach**:
1. Fetch all paginated data first (build complete array)
2. Split into chunks of 500
3. Create batch for each chunk
4. Write to Firestore collection `birdie_bonus_cache`
5. Document ID = `dguNumber` (e.g., "177-2813")

**Implementation** (`functions/index.js` lines 572-598):
```javascript
const BATCH_SIZE = 500;
for (let i = 0; i < allParticipants.length; i += BATCH_SIZE) {
  const batch = db.batch();
  const chunk = allParticipants.slice(i, i + BATCH_SIZE);
  
  for (const participant of chunk) {
    const dguNumber = participant.dguNumber;
    if (!dguNumber) continue;
    
    const docRef = db.collection('birdie_bonus_cache').doc(dguNumber);
    batch.set(docRef, {
      dguNumber,
      birdieCount: participant.Birdiebonuspoints || 0,
      rankingPosition: participant.rankInRegionGroup || 0,
      regionLabel: participant.regionLabel || 'Ukendt',
      hcpGroupLabel: participant.hcpGroupLabel || 'Ukendt',
      isParticipant: (participant["BB participant"] || 0) > 0, // Any value > 0 = participant
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
  }
  
  await batch.commit();
}
```

**Note**: We normalize field names to camelCase and add `isParticipant` boolean for easier client-side checks. The API's `"BB participant"` field is a sequence number (2, 3, 4, etc.), not a status code - we convert any value > 0 to `true`.

### 3.4 Error Handling We Added

We wrapped everything in try/catch with console logging:

```javascript
try {
  // Fetch token
  const authToken = await fetchBirdieBonusToken();
  
  // Paginate through API
  // ...
  
  // Write to Firestore
  // ...
  
  console.log('🎉 Birdie Bonus cache complete!');
  return { success: true, participants: count, duration };
} catch (error) {
  console.error('❌ Cache update failed:', error);
  throw error; // Let Cloud Functions handle retry logic
}
```

**Logging**: Includes page count, participant count, and duration for monitoring.

---

## 4. Our Firestore Cache Structure

### 4.1 Collection & Document Structure

**Collection Name**: `birdie_bonus_cache`

**Document ID**: Player's `dguNumber` (e.g., `"177-2813"`)

**Document Fields**:
```typescript
{
  dguNumber: string;          // "177-2813"
  birdieCount: number;        // 5
  rankingPosition: number;    // 630
  regionLabel: string;        // "Sjælland"
  hcpGroupLabel: string;      // "11.5-18.4"
  isParticipant: boolean;     // true if "BB participant" > 0 (sequence number, not status)
  updatedAt: Timestamp;       // Server timestamp
}
```

**Why this structure**:
- Document ID = dguNumber makes lookups simple: `.doc(unionId).get()`
- Normalized field names (camelCase)
- Added `isParticipant` boolean for clean conditional logic
- Added `updatedAt` for cache monitoring

### 4.2 Security Rules We Used (POC-Specific)

**Our Rules** (`firestore.rules` lines 87-104):
```javascript
match /birdie_bonus_cache/{dguNumber} {
  allow read: if true; // TEMP: Open for testing
  allow write: if false; // Only Cloud Functions
}
```

**Why `if true`**: We hit permission errors with `isAuthenticated()` when using Flutter's `Source.server` (force fresh read). This is a POC workaround.

**Your Rules Will Be Simpler**:
Since you have proper OAuth with `unionId` in auth tokens, you can use:
```javascript
match /birdie_bonus_cache/{dguNumber} {
  allow read: if request.auth != null && request.auth.token.unionId != null;
  allow write: if false; // Only Cloud Functions (Admin SDK)
}
```

### 4.3 No Indexing Required

Simple document lookups by ID - no composite indexes needed.

---

## 5. How We Built the Client (Flutter)

### 5.1 Our Service Layer Pattern

We created a dedicated service class for Birdie Bonus data fetching.

**File**: `lib/services/birdie_bonus_service.dart`

**Pattern**: Similar to our other services (WHS Statistik, Course Cache)

**Key Methods**:

1. **`isParticipating(String unionId)`** - Check if user is in competition
   ```dart
   Future<bool> isParticipating(String unionId) async {
     final doc = await _firestore
         .collection('birdie_bonus_cache')
         .doc(unionId)
         .get(const GetOptions(source: Source.server)); // POC workaround
     
     return doc.exists && (doc.data()?['isParticipant'] ?? false);
   }
   ```

2. **`getBirdieBonusData(String unionId)`** - Fetch full data
   ```dart
   Future<BirdieBonusData> getBirdieBonusData(String unionId) async {
     final doc = await _firestore
         .collection('birdie_bonus_cache')
         .doc(unionId)
         .get(const GetOptions(source: Source.server));
     
     if (doc.exists) {
       final data = doc.data()!;
       return BirdieBonusData(
         birdieCount: data['birdieCount'] ?? 0,
         rankingPosition: data['rankingPosition'] ?? 0,
         isParticipant: data['isParticipant'] ?? false,
         unionId: unionId,
       );
     } else {
       return BirdieBonusData.notParticipant(unionId: unionId);
     }
   }
   ```

**Note**: The `GetOptions(source: Source.server)` is a POC-specific workaround (see section 6.3). You won't need this.

### 5.2 Data Model Structure

**File**: `lib/models/birdie_bonus_model.dart`

Simple immutable data class:
```dart
class BirdieBonusData {
  final int birdieCount;
  final int rankingPosition;
  final bool isParticipant;
  final String? unionId;

  const BirdieBonusData({
    required this.birdieCount,
    required this.rankingPosition,
    this.isParticipant = false,
    this.unionId,
  });
  
  factory BirdieBonusData.notParticipant({String? unionId}) {
    return BirdieBonusData(
      birdieCount: 0,
      rankingPosition: 0,
      isParticipant: false,
      unionId: unionId,
    );
  }
}
```

### 5.3 Conditional Rendering Logic

**Where**: `lib/screens/home_screen.dart` (lines 281-355)

**Our Approach**:
1. Check if user is participating (`isParticipating()`)
2. If yes, fetch data (`getBirdieBonusData()`)
3. Set state flag `_isBirdieBonusParticipant`
4. Conditionally render bar in UI

**Implementation**:
```dart
Future<void> _loadBirdieBonusData() async {
  final player = authProvider.currentPlayer;
  
  if (player == null || player.unionId == null) {
    setState(() => _isBirdieBonusParticipant = false);
    return;
  }

  try {
    // First check participation
    final isParticipating = await _birdieBonusService.isParticipating(player.unionId!);
    
    if (isParticipating) {
      // Fetch full data if participating
      final data = await _birdieBonusService.getBirdieBonusData(player.unionId!);
      setState(() {
        _birdieBonusData = data;
        _isBirdieBonusParticipant = true;
      });
    } else {
      setState(() => _isBirdieBonusParticipant = false);
    }
  } catch (e) {
    setState(() => _isBirdieBonusParticipant = false);
  }
}
```

**UI Rendering** (lines 435-438):
```dart
// Only show if participating
if (_isBirdieBonusParticipant && _birdieBonusData != null)
  BirdieBonusBar(data: _birdieBonusData!),
```

**Result**: Bar seamlessly disappears for non-participants, other sections move up.

### 5.4 UI Component Structure (Flutter Widget)

**File**: `lib/widgets/birdie_bonus_bar.dart`

Simple clickable card with:
- Custom SVG icons (birdie and trophy)
- Birdie count and ranking position
- Clickable → opens `https://www.golf.dk/birdie-bonus-ranglisten`

**Flutter-Specific Details** (not relevant to native):
- Uses `flutter_svg` package for custom icons
- `InkWell` for tap handling
- `url_launcher` package to open external URL

**Visual Design**:
- White card with shadow
- Birdie icon + count on left
- Trophy icon + position on right
- Green DGU color accents

---

## 6. What's Different for Native App

### 6.1 OAuth Advantages

**Your Advantage**: You have `unionId` (DGU-nummer) in the user's auth token.

**Our Problem**: We don't have proper OAuth, so we use a simple login system. We had to carefully manage when `player.unionId` is available (see section 7.1).

**Your Benefit**: You can trust the auth token's `unionId` is always available and correct.

### 6.2 Simpler Security Rules

**Your Rules Can Be**:
```javascript
match /birdie_bonus_cache/{dguNumber} {
  allow read: if request.auth != null && request.auth.token.unionId != null;
  allow write: if false;
}
```

**Our Workaround**: We had to use `if true` (open read) because of POC auth limitations.

### 6.3 Cache Management (No Workaround Needed)

**Our Problem**: Flutter's Firestore SDK cached data aggressively. When we manually changed data in Firebase Console for testing, the app kept showing stale data even after hard refresh. We had to force server reads with `GetOptions(source: Source.server)`.

**Your Situation**: The native Firebase iOS/Android SDKs handle cache invalidation properly. You can use default `.get()` behavior - it will fetch fresh data when needed.

**Trade-off We Made**: Our `Source.server` forces network request (~200-500ms latency) on every read. You'll get better performance with default caching.

### 6.4 POC Workarounds You Won't Need

**What We Had To Do** (that you don't):

1. ✅ Load data in `didChangeDependencies()` instead of `initState()` - Flutter lifecycle issue with Provider pattern
2. ✅ Force server reads (`Source.server`) - Flutter cache bug
3. ✅ Open security rules (`if true`) - Auth token issues
4. ✅ Check for `player.unionId` availability - Auth timing issues

**What You Can Do**:
- Use standard SDK patterns
- Trust auth token has `unionId`
- Use default Firestore caching
- Simpler security rules

---

## 7. POC Challenges & Bugs We Hit

### 7.1 Flutter Lifecycle Timing Issue

**Problem**: Initial implementation loaded data in `initState()`, but at that point our Provider (auth state) wasn't ready yet. `player` was `null` even though user was logged in.

**Our Fix**: Moved data loading to `didChangeDependencies()` with a flag to prevent multiple loads.

**Detailed Explanation**: See `README.md` section "Birdie Bonus Integration: Lessons Learned"

**Not Relevant to You**: This is a Flutter + Provider pattern issue. Native iOS/Android apps handle view lifecycle differently.

### 7.2 Firestore Client Cache Problem

**Problem**: Flutter's Firestore SDK cached data locally (IndexedDB). When we updated data in Firebase Console for testing, the app showed stale cached data indefinitely. Hard refresh, incognito mode - nothing worked.

**Our Fix**: Force server read with `GetOptions(source: Source.server)`.

**Detailed Explanation**: See `README.md` section "Birdie Bonus Integration: Lessons Learned"

**Not Relevant to You**: Native Firebase SDKs handle this better. You likely won't see this issue.

### 7.3 Security Rules Workaround

**Problem**: Even with `isAuthenticated()` check in Firestore rules, we got permission errors when using `Source.server`.

**Our Fix**: Temporarily opened read access (`if true`).

**Not Relevant to You**: With proper OAuth and auth tokens, standard security rules will work fine.

### 7.4 DisplayID Confusion (Fixed)

**Problem**: We initially displayed `lifetimeId` on home screen instead of `unionId` (DGU-nummer). These are different IDs:
- `lifetimeId`: Person's lifetime ID (e.g., "160575-073")
- `unionId`: DGU membership number (e.g., "177-2813")

API and Firestore use `unionId`, so displaying `lifetimeId` meant lookups failed.

**Our Fix**: Changed display to show `unionId`.

**Not Relevant to You**: You already use `unionId` consistently throughout Mit Golf.

---

## 8. Code References (This POC)

### 8.1 Backend / Cloud Function

**File**: [`functions/index.js`](functions/index.js)

**Key Functions**:
- `fetchBirdieBonusToken()` - Lines 475-495 (fetch auth token from Gist)
- `fetchBirdieBonusPage()` - Lines 498-535 (single page fetch)
- `cacheBirdieBonusData` - Lines 538-606 (main scheduled function)

**Helper Functions** (reused from Statistik API):
- `fetchStatistikToken()` - Similar pattern for token fetching

### 8.2 Frontend / Flutter App

**Service Layer**:
- [`lib/services/birdie_bonus_service.dart`](lib/services/birdie_bonus_service.dart) - Complete service implementation

**Data Model**:
- [`lib/models/birdie_bonus_model.dart`](lib/models/birdie_bonus_model.dart) - Data structure

**UI Component**:
- [`lib/widgets/birdie_bonus_bar.dart`](lib/widgets/birdie_bonus_bar.dart) - Bar widget (Flutter-specific)

**Integration / Usage**:
- [`lib/screens/home_screen.dart`](lib/screens/home_screen.dart) lines 281-438 - Data loading and conditional rendering

### 8.3 Firebase Configuration

**Security Rules**:
- [`firestore.rules`](firestore.rules) lines 87-104 - Birdie Bonus cache rules

**No Special Indexes**: Simple document ID lookups - no composite indexes needed

### 8.4 Documentation

**Comprehensive Debugging Guide**:
- [`README.md`](README.md) section "Birdie Bonus Integration: Lessons Learned" - Detailed explanation of bugs we hit and fixes

**Security Notes**:
- [`README.md`](README.md) section "Security TODO" - Auth and rules improvements needed

---

## 9. GitHub Sharing Instructions (For Nick)

### How to Invite Sjoni (Read-Only Access)

Since your repo is already public, the cleanest approach is to invite Sjoni as a **read-only collaborator**:

**Steps**:
1. Go to: `https://github.com/[your-username]/dgu_scorekort/settings/access`
2. Click "Add people"
3. Enter Sjoni's GitHub username or email
4. Select **Read** permission (NOT Write or Admin)
5. Send invitation

**What Sjoni Can Do**:
- ✅ Browse all code
- ✅ Clone the repository
- ✅ Read issues and discussions
- ✅ Comment on code
- ❌ Cannot push changes
- ❌ Cannot modify settings

**Branch to Focus**: `feature/extended-version` (most recent work)

**Revoking Access**: You can remove collaborator access anytime in repository settings.

**Alternative (If Privacy Needed)**:
If you want to make the repo fully private first:
1. Settings → General → Danger Zone → Change visibility → Private
2. Then invite Sjoni as described above

---

## 10. Final Notes

This POC implementation represents our learning process and the constraints of building a proof of concept without proper infrastructure. The native Mit Golf app has significant advantages that will make your implementation cleaner:

- ✅ Proper authentication and auth tokens
- ✅ Established Firebase patterns and architecture
- ✅ Professional development practices
- ✅ Native platform capabilities

Feel free to use whatever parts of this implementation are helpful and discard anything that doesn't fit your architecture. The core pattern (API → Cloud Function → Firestore → App) should work well, but the details will naturally differ.

If you have questions about any specific implementation detail, the code is all in the `feature/extended-version` branch with extensive comments and documentation in README.md.

**Good luck with the implementation!** 🏌️

---

*Document created: December 2024*
*POC Version: 2.0 Extended*
*Author: Nick Hüttel (customer/product owner) with Cursor AI assistance*

