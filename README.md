# DGU Scorekort v2.0 - Extended POC

**Flutter Web App** til danske golfspillere med scorecard indtastning og **handicap-focused social features**.

## 🎯 Status: Version 2.0 Extended POC (Production)

**Main Branch:** `main` - v2.0 (Stable, deployed to all URLs)  
**Development Branch:** `feature/extended-version` - Active development (continues here)

**Live URLs:**
- **Primary:** [https://dgu-app-poc.web.app](https://dgu-app-poc.web.app) - v2.0 Extended POC (Firebase Hosting)
- **Mirror:** [https://dgu-scorekort.web.app](https://dgu-scorekort.web.app) - v2.0 (Firebase Hosting, same deployment)
- **Backup:** [GitHub Pages](https://dansk-golf-union.github.io/dgu-scorekort/) - v2.0 (Auto-deploy from main)

**All three URLs now show v2.0 with OAuth, Dashboard, Birdie Bonus, and social features.**

---

## 📱 What's New in v2.0

### Strategic Context

**DGU Scorekort v2.0** er en **Proof of Concept (POC)** for integration i **DGU Mit Golf** app.

**Goals:**
- ✅ Demonstrate at native Flutter UI > GolfBox webview
- ✅ Prove at **social features driver engagement** (især handicap tracking)
- ✅ Production-ready code til integration i Mit Golf app

### Dashboard Redesign (December 2025)

**Navigation Change:**
- **Removed:** Bottom navigation bar (conflicts with native Mit Golf app)
- **New:** Single-page dashboard with glanceable widgets
- **Full-screen views:** Accessible via "Se alle →" links with back buttons

**Dashboard Widgets:**
1. **Player Card** - Name, HCP, home club
2. **Birdie Bonus Bar** - Conditional (only if participating)
3. **Quick Actions** - 4 green buttons (Bestil tid, DGU score, Indberet, Scorekort)
4. **Golf.dk News Feed** - Latest articles from Golf.dk
5. **Mine Venner** - Friend summary (live from FriendsProvider)
6. **Seneste Aktivitet** - 2 recent activity items (live from Firestore)
7. **Ugens Bedste** - Weekly highlight (placeholder)
8. **Mine Seneste Scores** - 2 recent scores (live from WHS API)

**Navigation Pattern:**
- Widgets clickable → Full-screen views
- Full-screen routes: `/feed`, `/venner`, `/score-archive`
- AppBar with back button on full-screen views
- All text in Danish

**Rationale:**
- Better compatibility with native "Mit Golf" app
- Cleaner single-page experience
- Glanceable dashboard pattern

### Navigation Structure

**From:** Single page scorecard app

**To:** Dashboard-style POC (compatible with Mit Golf native navigation)

**Home Screen:**
- 🏠 **Dashboard** - Glanceable widgets with "Se alle →" links
- No bottom nav (defers to Mit Golf app's native navigation)

**Full-Screen Views:**
- 📰 **Feed** (`/feed`) - Activity feed
- 👥 **Venner** (`/venner`) - Friends list
- 📊 **Score Archive** (`/score-archive`) - Score history

**Design:**
- White header med DGU logo (centered)
- Single-page scrollable dashboard
- Clean, modern Material 3 design

---

## ✨ New Features in v2.0

### 📊 Scorearkiv (WHS API Integration) - NEW!
- ✅ **Fetch Score History**: Hent seneste 20 runder fra WHS/Statistik API
- ✅ **Score Preview**: Se sidste 3 scores på Hjem tab
- ✅ **Full Archive Screen**: Komplet oversigt over scores
- ✅ **Handicap Before Round**: Vis HCP før hver runde
- ✅ **Qualifying Status**: Markering af om runde tæller til handicap
- ✅ **Cloud Function Proxy**: CORS-fri API access via Firebase
- ✅ **Pull-to-Refresh**: Opdater scores
- ✅ **Loading & Error States**: Smooth UX

**Foundation for Phase 2 social features!**

### 🗞️ Golf.dk News Feed - NEW!
- ✅ **Latest News**: Fetch 3 seneste artikler fra Golf.dk API
- ✅ **Article Preview**: Image, title, og manchet (teaser)
- ✅ **External Links**: Åbn artikler i browser via url_launcher
- ✅ **CORS Handling**: corsproxy.io for web production builds
- ✅ **Error States**: Retry button ved fejl
- ✅ **Pull-to-Refresh**: Opdater news feed
- ✅ **Seamless UX**: Loading states og fallback messages

**Placering:** Nederst på Hjem tab, under Mine Seneste Scores

### 🎨 Mit Golf Design Language - NEW!
- ✅ **White Header**: DGU logo centered (matches Mit Golf app)
- ✅ **Bottom Navigation**: 5 tabs (Hjem, Venner, Feed, Tops, Menu)
- ✅ **Player Info Card**: Name, home club, HCP badge på Hjem tab
- ✅ **iOS Status Bar Spacing**: Proper spacing for Dynamic Island
- ✅ **Taller Bottom Nav**: Better touch targets (72px height)
- ✅ **Light Grey Background**: Clean, modern look
- ✅ **Simplified Menu**: Settings, privacy, om app, log ud

### 🏷️ POC Branding - NEW!
- ✅ **Login Screen**: Updated title "DGU App 2.0 POC"
- ✅ **Subtitle**: "Test af features i kommende version"
- ✅ **Clear POC Messaging**: Tydeligt at det er test-version

### 🌙 Dark Mode - NEW!
- ✅ **Manual Toggle**: Simple on/off switch i Drawer menu
- ✅ **Persistent Settings**: Gemmes i SharedPreferences
- ✅ **Dark Theme**: Material 3 dark theme med DGU branding
- ✅ **Instant Switch**: Skift tema uden reload
- ✅ **All Screens**: Konsistent dark mode på alle sider

**Placering:** ☰ Menu → "Dark Mode" med Switch (ingen ikon)

### 👥 Friends System - NEW!
- ✅ **Add Friends**: Via DGU nummer med validation
- ✅ **Friend Request Notifications**: Push til Mit Golf app
- ✅ **Consent Flow**: Explicit samtykke ved accept
- ✅ **Friends List**: Oversigt over venner med HCP badges
- ✅ **Friend Detail Screen**: Detaljeret profil med stats
- ✅ **Handicap Trend Chart**: Visual graf med fl_chart
- ✅ **Period Filters**: 3 mdr, 6 mdr, 1 år
- ✅ **Trend Statistics**: Tendens, bedste HCP, udvikling/måned
- ✅ **Recent Scores**: Se venners seneste runder
- ✅ **Privacy & Samtykke**: GDPR-compliant data sharing
- ✅ **Remove Friend**: Fjern venskab + træk samtykke tilbage

**Highlights:**
- Real WHS data integration (score history)
- Smart caching (1 hour freshness)
- Pull-to-refresh for live updates
- Loading states & error handling
- Deep linking for friend requests

---

## ✨ Features from v1.6 (Included in v2.0)

### ⚔️ Match Play / Hulspil
- ✅ **Match Play Mode**: Spil hulspil mod modstander
- ✅ **Opponent Lookup**: Hent info via DGU-nummer
- ✅ **Handicap Calculation**: Beregn spillehandicap for begge
- ✅ **Stroke Distribution**: Visualiser hvor modstander får slag
- ✅ **Match Play Rules**: Kun forskel fordeles (index 1-N)
- ✅ **Multiple Strokes**: Support for >18 slag forskel
- ✅ **Live Scoring**: Hole-by-hole med match status
- ✅ **Early Finish**: Automatisk når match ikke kan nås
- ✅ **Undo**: Fortryd sidste hul

### 🔔 Push Notifications & Remote Marker
- ✅ **Push til Markør**: Automatisk besked i DGU Mit Golf app
- ✅ **Remote Approval**: Markør godkender via URL (ingen login)
- ✅ **Automatic WHS Submission**: Sendes til WHS ved godkendelse
- ✅ **Status Tracking**: pending → approved → submitted

### ⚡ Performance & Caching
- ✅ **Firestore Cache**: 213 klubber + ~876 baner cached
- ✅ **Automated Updates**: Cloud Function kører hver nat kl. 02:00
- ✅ **Incremental Updates**: Kun ændringer opdateres (~15-20 sek)
- ✅ **Instant Loading**: Metadata-based club list (1 read!)

### 🏌️ Scorecard Features
- ✅ **Two Input Methods**: Plus/Minus tæller + Keypad
- ✅ **WHS Handicap**: Dansk WHS spillehandicap beregning
- ✅ **9 & 18 Holes**: Support for begge
- ✅ **Stableford Points**: Real-time point beregning
- ✅ **Score Markers**: Visual feedback (birdie, eagle, bogey)
- ✅ **Handicap Result**: Score differential med Net Double Bogey

---

## 🚀 Social Features Status

### ✅ Phase 2A: Friends System (COMPLETED!)
- ✅ **Add Friends**: Via DGU nummer
- ✅ **Handicap Dashboard**: Se venners aktuelle handicap
- ✅ **Handicap Trends**: Graf over udvikling (3/6/12 mdr)
- ✅ **Friend Detail View**: Comprehensive stats & charts
- ✅ **Privacy & Consent**: GDPR-compliant samtykke flow
- ⏳ **Challenge Friend**: Link til match play (pending)

### 📰 Phase 2B: Activity Feed (COMPLETED!)
- ✅ **Auto-detect Milestones**: Scratch, single-digit, sub-20, sub-30
- ✅ **Improvement Detection**: Significant improvements (≥1.0 slag)
- ✅ **Personal Best Tracking**: New lowest HCP
- ✅ **Eagle/Albatross Detection**: Special achievements
- ✅ **Feed UI**: Activity cards med filter chips
- ✅ **Real-time Updates**: Firestore stream
- ✅ **Nightly Scanning**: Cloud Function kører kl. 03:00
- ⏳ **Like & Comment**: Social interaction (future)
- ⏳ **Push Notifications**: Notify ved milestones (future)
- ⏳ **Swipe-to-Dismiss**: Dismiss activities (future)
- ⏳ **Activity Details**: Tap for full scorecard (future)

### 🏆 Phase 2C: Leaderboards (NEXT!)
- **Handicap Rankings**: Lowest, biggest improvement
- **Score Rankings**: Best rounds, most consistent
- **Friend Circles**: Compete with friends

---

## 🛠️ Tech Stack

### Framework & Core
- **Flutter 3.38.4** (Dart SDK)
- **Provider 6.1.1** - State management
- **go_router 14.6.2** - Routing & deep linking
- **Material 3** - Modern design system

### Firebase
- **Firebase Core 3.8.1** - Firebase initialization
- **Cloud Firestore 5.5.1** - Database
- **Cloud Functions 5.1.4** - Backend logic (NEW for v2.0)
- **Firebase Hosting** - Deployment

### API Integration
- **HTTP 1.2.0** - API client
- **DGU Basen API** - Clubs, courses, players
- **WHS/Statistik API** - Score history (NEW for v2.0)
- **DGU Notification API** - Push notifications

### Other
- **Google Fonts 6.1.0** - Typography
- **Intl 0.19.0** - Date formatting (Danish)
- **Crypto 3.0.3** - OAuth PKCE
- **SharedPreferences 2.2.2** - Storage
- **Signature 5.5.0** - Digital signatures
- **fl_chart 0.65.0** - Handicap trend charts
- **url_launcher 6.2.2** - External links (news)

---

## 📁 Project Structure

```
lib/
├── main.dart                              # Entry + routing
├── config/
│   ├── auth_config.dart                   # OAuth & API config
│   └── firebase_options.dart              # Firebase config
├── theme/
│   └── app_theme.dart                     # DGU theme + Material 3
├── models/
│   ├── club_model.dart                    # Club, Course, Tee, Hole
│   ├── player_model.dart                  # Player (OAuth + gender)
│   ├── scorecard_model.dart               # Scorecard, HoleScore
│   ├── score_record_model.dart            # WHS score record (NEW v2.0)
│   ├── friendship_model.dart              # Friendship (NEW v2.0)
│   ├── friend_request_model.dart          # Friend requests (NEW v2.0)
│   ├── friend_profile_model.dart          # Friend profiles (NEW v2.0)
│   ├── handicap_trend_model.dart          # Trend analysis (NEW v2.0)
│   └── news_article_model.dart            # Golf.dk news (NEW v2.0)
├── providers/
│   ├── auth_provider.dart                 # Auth state
│   ├── match_setup_provider.dart          # Club/course/tee selection
│   ├── scorecard_provider.dart            # Scorecard state
│   ├── match_play_provider.dart           # Match play state
│   ├── theme_provider.dart                # Dark mode (NEW v2.0)
│   └── friends_provider.dart              # Friends & trends (NEW v2.0)
├── services/
│   ├── auth_service.dart                  # OAuth 2.0 PKCE
│   ├── dgu_service.dart                   # DGU Basen API
│   ├── player_service.dart                # Player API
│   ├── course_cache_service.dart          # Firestore cache
│   ├── scorecard_storage_service.dart     # Firestore scorecards
│   ├── notification_service.dart          # Push notifications
│   ├── whs_submission_service.dart        # WHS submission
│   ├── whs_statistik_service.dart         # WHS scores (NEW v2.0)
│   ├── friends_service.dart               # Friends CRUD (NEW v2.0)
│   └── golfdk_news_service.dart           # Golf.dk news (NEW v2.0)
├── utils/
│   ├── handicap_calculator.dart           # WHS calculations
│   ├── stroke_allocator.dart              # Stroke allocation
│   └── score_helper.dart                  # Golf terms
└── screens/
    ├── home_screen.dart                   # Home dashboard (NEW v2.0)
    ├── score_archive_screen.dart          # Score archive (NEW v2.0)
    ├── friends_list_screen.dart           # Friends list (NEW v2.0)
    ├── friend_detail_screen.dart          # Friend profile + trends (NEW v2.0)
    ├── privacy_settings_screen.dart       # Privacy & samtykke (NEW v2.0)
    ├── friend_request_from_url_screen.dart # Friend consent (NEW v2.0)
    ├── friend_request_success_screen.dart # Success confirmation (NEW v2.0)
    ├── login_screen.dart                  # OAuth login
    ├── simple_login_screen.dart           # Union ID login
    ├── scorecard_keypad_screen.dart       # Keypad input
    ├── scorecard_bulk_screen.dart         # Bulk input
    ├── scorecard_results_screen.dart      # Results + submission
    ├── marker_approval_from_url_screen.dart # Remote approval
    └── match_play_screen.dart             # Match play

functions/
└── index.js                               # Cloud Functions
    ├── updateCourseCache                  # Scheduled (02:00 daily)
    ├── scanForMilestones                  # Scheduled (03:00 daily, NEW v2.0)
    ├── cacheBirdieBonusData               # Scheduled (04:00 daily, NEW v2.0)
    ├── sendNotification                   # Push notifications
    ├── getWhsScores                       # WHS API proxy (NEW v2.0)
    ├── forceFullReseed                    # Manual cache reset
    └── golfboxCallback                    # OAuth callback
```

---

## 🔥 Firebase Setup

### Project
**Project ID**: `dgu-scorekort`  
**Regions**: `europe-west1` (Frankfurt)

### Multi-Site Hosting
| URL | Version | Branch | Purpose |
|-----|---------|--------|---------|
| `dgu-scorekort.web.app` | v1.6 | `main` | Production (stable) |
| `dgu-app-poc.web.app` | v2.0 | `feature/extended-version` | POC Testing |

**Both share:**
- Same Firestore database
- Same Cloud Functions
- Same Firebase Auth
- Same course cache

### Cloud Functions

#### `updateCourseCache` ⏰ (Scheduled)
- **Schedule**: Hver nat kl. 02:00 (Copenhagen)
- **Purpose**: Auto-update club/course cache
- **Duration**: ~15-20 sek (incremental), ~2 min (full reseed)
- **Memory**: 1GB, Timeout: 9 min

#### `sendNotification` (Callable)
- **Purpose**: Push notifications til Mit Golf app (CORS proxy)
- **Input**: `{ markerUnionId, playerName, approvalUrl }`

#### `getWhsScores` (Callable) - NEW v2.0!
- **Purpose**: Fetch WHS scores (CORS proxy)
- **Input**: `{ unionId, limit, dateFrom, dateTo }`
- **Output**: `{ success, scores, count }`
- **Auth**: Fetches token from GitHub Gist serverside

#### `forceFullReseed` (Callable)
- **Purpose**: Force full cache reseed på næste scheduled run

#### `golfboxCallback` (HTTP)
- **Purpose**: OAuth callback dispatcher

#### `cacheBirdieBonusData` ⏰ (Scheduled) - NEW v2.0!
- **Schedule**: Hver nat kl. 04:00 (Copenhagen)
- **Purpose**: Fetch paginated Birdie Bonus data and cache in Firestore
- **Duration**: ~30-60 sek (depends on participant count and pagination)
- **Memory**: 512MB, Timeout: 9 min
- **Auth**: Basic Auth token from GitHub Gist
- **API**: https://birdie.bonus.sdmdev.dk/api/member/rating_list/{page}
- **Cache**: `birdie_bonus_cache` collection (document per player, keyed by dguNumber)
- **Strategy**: Full refresh nightly via paginated API (loops through `/0`, `/1`, `/2`... until `next_page: null`)
- **Client**: Flutter reads from cache (no direct API calls) - 24h delay acceptable

### Firestore Collections

#### `scorecards`
Scorekort med marker approval

#### `friendships` - NEW v2.0!
Active friendships (user1Id, user2Id, createdAt)

#### `friend_requests` - NEW v2.0!
Pending friend requests (fromUserId, toUserId, status, consentMessage)

#### `user_privacy_settings` - NEW v2.0!
Privacy toggles per user (shareHandicapWithFriends)

#### `birdie_bonus_cache` - NEW v2.0!
Birdie Bonus participant cache (dguNumber, birdieCount, rankingPosition, regionLabel, hcpGroupLabel, isParticipant)
Updated nightly by `cacheBirdieBonusData` at 04:00

#### `course-cache-metadata`
Cache metadata (lastUpdated, club list)

#### `course-cache-clubs/{clubId}`
Cached course data per club

---

## 🌐 API Integration

### 1. DGU Basen API ✅
**Base:** `https://dgubasen.api.union.golfbox.io/DGUScorkortAapp`

**Endpoints:**
- `GET /clubs` - All clubs
- `GET /clubs/{clubId}/courses` - Courses for club
- `GET /clubs/golfer?unionid={id}` - Player info
- `POST /ScorecardExchange` - Submit scorecard

**Auth:** Basic (token from GitHub Gist)

### 2. WHS/Statistik API ✅ NEW v2.0!
**Base:** `https://api.danskgolfunion.dk`

**Endpoints:**
- `GET /Statistik/GetWHSScores` - Player's score history

**Auth:** Basic (separate token from GitHub Gist)

**Access:** Via Cloud Function `getWhsScores` (CORS proxy)

**Response:** Array of scorecards med:
- Handicap before round (`HCP`)
- Total points, strokes
- Qualifying status
- Score differential (`SGD`)
- Course info, date

**Usage:**
- Scorearkiv view
- Handicap trend graphs (Phase 2)
- Activity feed (Phase 2)
- Leaderboards (Phase 2)

### 3. DGU Notification API ✅
**Endpoint:** `https://sendsinglenotification-d3higuw2ca-ey.a.run.app`

**Purpose:** Push notifications til DGU Mit Golf app

**Access:** Via Cloud Function `sendNotification`

---

## 🏗️ Architecture

### State Management
**Provider Pattern:**
- `AuthProvider` - Authentication
- `MatchSetupProvider` - Club/course/tee selection
- `ScorecardProvider` - Scorecard input
- `MatchPlayProvider` - Match play state

### Routing
**go_router** med routes:
- `/` - Home (requires auth)
- `/setup-round` - Scorecard setup (requires auth)
- `/score-archive` - Score history (requires auth) - NEW v2.0!
- `/friend-request/:id` - Friend consent (public) - NEW v2.0!
- `/match-play` - Match play (public)
- `/marker-approval/:id` - Remote approval (public)
- `/login` - Login screen

### Backend
**Firebase:**
- Firestore for database
- Cloud Functions for backend logic
- Hosting for deployment

**CORS Strategy:**
- Cloud Functions proxy for all external APIs
- No direct browser API calls in production

---

## 🐛 Birdie Bonus Integration: Lessons Learned

During Birdie Bonus Bar implementation (Dec 2025), we encountered two critical bugs that required architectural fixes. These lessons apply to **any Flutter + Firestore + Provider integration**.

### Integration Architecture

```
Birdie Bonus API (paginated)
    ↓ (nightly @ 04:00 CET)
Cloud Function: cacheBirdieBonusData
    ↓ (batch writes)
Firestore: birdie_bonus_cache collection
    ↓ (server read with Source.server)
Flutter Service: BirdieBonusService
    ↓ (loaded in didChangeDependencies)
Home Screen: Conditional Birdie Bonus Bar
```

### Critical Bug #1: Flutter Lifecycle Timing ⏱️

**Problem:**
- Initial implementation loaded Birdie Bonus data in `initState()`
- At this point in widget lifecycle, Provider dependencies are NOT yet established
- `context.read<AuthProvider>().currentPlayer` returned `null` even when user was logged in
- Result: Birdie Bonus Bar never appeared, load failed silently

**Root Cause:**
Flutter widget lifecycle order:
1. `initState()` - Runs BEFORE Provider context is ready
2. `didChangeDependencies()` - Runs AFTER Provider context is established
3. `build()` - Renders UI

**Solution:**
```dart
// ❌ WRONG - initState() called before Provider ready
@override
void initState() {
  super.initState();
  _loadBirdieBonusData(); // player is null!
}

// ✅ CORRECT - didChangeDependencies() called after Provider ready
@override
void didChangeDependencies() {
  super.didChangeDependencies();
  if (!_hasLoaded) { // Prevent multiple loads
    _hasLoaded = true;
    _loadBirdieBonusData(); // player is available!
  }
}
```

**Key Takeaway:**
When loading data that depends on **Provider state**, always use `didChangeDependencies()` with a flag to prevent multiple loads. This pattern is essential for Provider-based apps.

**Files:**
- `lib/screens/home_screen.dart` - See `_HjemTabState.didChangeDependencies()`

---

### Critical Bug #2: Firestore Client-Side Cache 💾

**Problem:**
- Data was manually updated in Firebase Console (`isParticipant: false` → `true`)
- Flutter app continued showing old cached value (`false`)
- Birdie Bonus Bar remained hidden even after manual fix
- Browser refresh, hard reload, incognito mode - nothing helped!

**Root Cause:**
- Flutter's Firestore SDK aggressively caches data locally (IndexedDB)
- Default `.get()` reads from local cache indefinitely
- Cache is only updated when server pushes changes (which didn't happen for manual edits)
- Result: Stale data persisted across app restarts

**Solution:**
```dart
// ❌ WRONG - Uses local cache (stale data)
final doc = await _firestore
    .collection('birdie_bonus_cache')
    .doc(unionId)
    .get();

// ✅ CORRECT - Forces fresh read from server
final doc = await _firestore
    .collection('birdie_bonus_cache')
    .doc(unionId)
    .get(const GetOptions(source: Source.server));
```

**Trade-offs:**
- ✅ **Always shows latest data** (critical for participation check)
- ❌ **Requires network request** (adds ~200-500ms latency)
- ✅ **Acceptable for infrequent checks** (once per app load)

**When to Use:**
- ✅ Critical data that must be fresh (user participation status)
- ✅ Data that can be manually changed in Firestore Console
- ✅ Infrequent reads (once per session)
- ❌ Frequently accessed data (use default cache)
- ❌ Real-time data (use snapshots instead)

**Files:**
- `lib/services/birdie_bonus_service.dart` - See `isParticipating()` and `getBirdieBonusData()`

---

### Security Rules Workaround 🔒

**Current Implementation:**
```javascript
// firestore.rules
match /birdie_bonus_cache/{dguNumber} {
  allow read: if true; // TEMP: Open for testing
  allow write: if false; // Only Cloud Functions
}
```

**Issue:**
Even with `isAuthenticated()` check, permission errors occurred when forcing server reads. This suggests a deeper issue with Firebase Auth token propagation.

**TODO:**
- Implement proper Firebase Auth with custom claims for `unionId`
- Update security rules to: `allow read: if request.auth != null && request.auth.token.unionId != null;`
- See Security TODO section below

---

### Debugging Tips 🔍

**Problem:** "Why isn't my data loading?"

1. **Check lifecycle timing:**
   ```dart
   print('initState: player = $player'); // Likely null!
   print('didChangeDependencies: player = $player'); // Should be available
   ```

2. **Check Firestore cache:**
   ```dart
   // Add debug logging
   print('📊 Firestore doc.exists: ${doc.exists}');
   print('📊 Raw data: ${doc.data()}');
   print('📊 Field value: ${doc.data()?['fieldName']} (type: ${value.runtimeType})');
   ```

3. **Force server read temporarily:**
   ```dart
   .get(const GetOptions(source: Source.server))
   ```

4. **Check Firestore Console:**
   - Verify data exists
   - Check field **types** (boolean vs string!)
   - Verify document ID matches query

**Common Gotchas:**
- Field type mismatch: `boolean true` vs `string "true"`
- Document ID case sensitivity: `"177-2813"` ≠ `"177-2813 "`
- Provider not ready in `initState()`
- Firestore cache showing stale data

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.38.4+
- Chrome browser
- Firebase CLI

### Installation

```bash
# Clone repository
git clone https://github.com/Dansk-Golf-Union/dgu-scorekort.git
cd dgu_scorekort

# Switch to v2.0 branch
git checkout feature/extended-version

# Install dependencies
flutter pub get

# Run locally
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

**Note:** `--disable-web-security` only needed for localhost. Production uses Cloud Functions.

### Development

```bash
# Hot reload
r

# Hot restart
R

# Analyze code
flutter analyze

# Run tests
flutter test
```

---

## 📦 Deployment

### Deploy POC (v2.0)

```bash
# 1. Ensure you're on correct branch
git checkout feature/extended-version

# 2. Build web version
flutter build web --release

# 3. Deploy hosting to POC URL
firebase deploy --only hosting:dgu-app-poc

# 4. Deploy Cloud Functions (if changed)
firebase deploy --only functions

# 5. Or deploy everything
firebase deploy
```

**Result:** Live at `https://dgu-app-poc.web.app`

### Deploy Stable (v1.6)

```bash
# 1. Switch to main branch
git checkout main

# 2. Build + deploy
flutter build web --release
firebase deploy --only hosting:dgu-scorekort
```

**Result:** Live at `https://dgu-scorekort.web.app`

### Deploy Cloud Functions Separately

```bash
# Deploy all functions
firebase deploy --only functions

# Deploy specific function
firebase deploy --only functions:getWhsScores

# Check logs
firebase functions:log --only getWhsScores
```

---

## 🔐 API Tokens

### Token Management
All tokens stored in **private GitHub Gists** for security.

**Tokens:**
1. ✅ **DGU Basen token** - Clubs, courses, players
2. ✅ **Statistik API token** - WHS scores (NEW v2.0)
3. ✅ **Birdie Bonus token** - Birdie Bonus participants (NEW v2.0)
4. ✅ **Notification token** - Push to Mit Golf

**Cloud Functions fetch tokens serverside** - never exposed to browser!

### Token URLs (Private Gists)
```dart
// Stored in services, fetched by Cloud Functions
const DGU_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/.../dgu_token.txt';
const WHS_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/.../statistik%20token';
const BIRDIE_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/.../Birdie%20bonus%20deltagere'; // NEW v2.0
const NOTIF_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/.../notification_token.txt';
```

### Security Best Practices
- ✅ **ALL tokens stored in private GitHub Gists**
- ✅ **NEVER commit tokens in code or comments**
- ✅ **Cloud Functions fetch tokens server-side**
- ✅ **Tokens never exposed to browser**
- ⚠️ **Avoid example tokens in comments** (triggers security scanners like GitGuardian)
- 🔄 **Rotate tokens immediately** if accidentally committed
- 🔒 **Use environment variables** for local development

---

## 🧮 Handicap Calculations

### Playing Handicap
**18-hole:**
```
Playing HCP = (HCP Index × Slope/113) + (Course Rating - Par)
```

**9-hole (WHS correct):**
```
1. HCP Index / 2 → Round to 1 decimal
2. Use rounded value in formula
Example: 14.5 / 2 = 7.25 → 7.3
```

### Stroke Allocation

**Stroke Play:**
- Strokes distributed based on hole index and playing handicap
- Formula: `index <= (playingHcp % 18)` gets 1 stroke

**Match Play:**
- Only difference distributed
- Index 1-N (where N = handicap difference)
- Supports >18 strokes (wrap around, multiple strokes per hole)

---

## 📋 Feature Roadmap

### ✅ Phase 0: Setup (DONE)
- [x] Git branch: `feature/extended-version`
- [x] Firebase multi-site hosting
- [x] Test deploy to POC URL
- [x] Statistik API token (GitHub Gist)

### ✅ Phase 1: Navigation & Foundation (DONE)
- [x] Home screen structure (tab navigation)
- [x] Mit Golf design implementation
- [x] Scorearkiv view (WHS API integration)
- [x] Dark mode
- [x] Golf.dk news feed

### ✅ Phase 2A: Friends System (DONE)
- [x] Friends data models (Friendship, FriendRequest, FriendProfile)
- [x] FriendsService + FriendsProvider
- [x] Friend request notifications (push to Mit Golf)
- [x] Consent flow (deep linking + authentication)
- [x] Friends list UI (FriendsListScreen + FriendCard)
- [x] Friend detail screen (comprehensive stats)
- [x] Handicap trend chart (fl_chart with 3/6/12 month filters)
- [x] Privacy & Samtykke screen (GDPR compliance)
- [x] Remove friend + withdraw consent

### ✅ Phase 2B: Activity Feed (DONE)
- [x] Feed data models (ActivityItem, ActivityType, MilestoneType)
- [x] Milestone detection Cloud Function (scanForMilestones, nightly 03:00)
- [x] Feed UI (activity cards with filter chips)
- [x] Real-time Firestore stream
- [x] User score caching
- [ ] Like & comment functionality (future)
- [ ] Activity notifications (future)
- [ ] Swipe-to-dismiss (future)

### 📅 Phase 2C: Leaderboards (NEXT)
- [ ] Leaderboard data models
- [ ] calculateLeaderboards Cloud Function
- [ ] Leaderboard UI (rankings)
- [ ] Friend circles

### 📅 Phase 3: Polish & Testing
- [ ] Flight Mode (multi-player)
- [ ] User testing (20+ users)
- [ ] Error handling + Sentry
- [ ] GDPR compliance

### 🎯 Phase 4: Production
- [ ] Code review
- [ ] Final QA
- [ ] Merge to main
- [ ] Production deploy

**Timeline:** 8-10 uger total

---

## 🧪 Testing

### Manual Testing Checklist

**v2.0 Features:**
- [ ] Home screen loads med tabs
- [ ] Bottom navigation switches tabs
- [ ] Menu button opens drawer
- [ ] DGU logo displays correctly
- [ ] Player info card shows name, club, HCP
- [ ] Score preview loads (last 3 scores)
- [ ] "Se arkiv →" navigation works
- [ ] Full score archive displays
- [ ] Pull-to-refresh works
- [ ] Error states display correctly

**v1.6 Features (Regression Testing):**
- [ ] Login with Union ID
- [ ] Select club/course/tee
- [ ] Calculate playing handicap
- [ ] Enter scores (Plus/Minus + Keypad)
- [ ] View results
- [ ] Send to marker (push notification)
- [ ] Remote marker approval
- [ ] WHS submission on approval
- [ ] Match play opponent lookup
- [ ] Match play scoring
- [ ] Tilbage buttons with confirmation

---

## 🔧 Configuration

### Environment Setup

**Firebase:**
```bash
# Login to Firebase
firebase login

# Set project
firebase use dgu-scorekort

# List hosting sites
firebase hosting:sites:list
```

**Flutter:**
```bash
# Check Flutter version
flutter --version

# Doctor check
flutter doctor

# Clean build
flutter clean
flutter pub get
```

### Local Development

**Chrome with CORS disabled:**
```bash
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

**Hot Reload:**
- Press `r` for hot reload
- Press `R` for hot restart
- Press `q` to quit

---

## 📊 Success Metrics (Phase 3)

**Goals for POC validation:**
- 20+ test users
- Track engagement:
  - Friend adds per user
  - Activity feed opens per day
  - Leaderboard views
  - Handicap trend views
- Compare with GolfBox webview metrics
- User feedback surveys

---

## ⚠️ Known Issues

### OAuth Login Status ✅ (December 2025)

**Implementation:** OAuth 2.0 PKCE login is **fully implemented and active**

**Current Setup:**
- ✅ **OAuth 2.0 PKCE**: Complete implementation in `auth_service.dart`
- ✅ **Cloud Function Relay**: `golfboxCallback` deployed in `europe-west1`
- ✅ **Redirect URI**: `https://europe-west1-dgu-scorekort.cloudfunctions.net/golfboxCallback`
- ✅ **Token Exchange Proxy**: `exchangeOAuthToken` Cloud Function (CORS fix)
- ✅ **Login Screen**: OAuth popup with GolfBox credentials
- ✅ **UX Improvements** (Dec 17, 2025):
  - Login button hidden during DGU-nummer input
  - Clear success message: "✅ Login lykkedes!"
  - Prompt to enter DGU-nummer "igen" (clarity)
  - Persistent login with stored token + unionId
  - Logout button in drawer menu (burger icon)
- ⏸️ **Simple Login**: Available as development toggle (`useSimpleLogin` flag in `main.dart`)

**Login Flow:**
1. User clicks "Log ind med DGU" → OAuth popup
2. After successful OAuth → "✅ Login lykkedes!" message
3. User enters DGU-nummer → Fetches player data (Basic Auth)
4. Both token and unionId stored for persistent login
5. Future app opens skip login (auto-login)

**Development Toggle:**
```dart
// lib/main.dart
const bool useSimpleLogin = false; // OAuth enabled (production)
// const bool useSimpleLogin = true; // Quick Union ID login (development)
```

**Benefits:**
- Switch between OAuth (production) and SimpleLogin (development convenience)
- No conflicts - both flows work independently
- Quick refresh testing during UI development without OAuth popup

**Files:**
- `lib/config/auth_config.dart` - OAuth configuration
- `lib/services/auth_service.dart` - OAuth 2.0 PKCE service + token storage
- `lib/providers/auth_provider.dart` - Auth state + persistent login
- `lib/screens/login_screen.dart` - OAuth login UI with UX improvements
- `lib/screens/simple_login_screen.dart` - Development login
- `lib/screens/home_screen.dart` - Burger menu for logout
- `functions/index.js` - `golfboxCallback` + `exchangeOAuthToken` functions

### OAuth Session & Validation Limitations

**Issue 1: OAuth Session Persistence After Logout**

**Beskrivelse:**
- Efter logout kan OAuth session stadig være aktiv i browser
- Ved return til URL kan app auto-login selv efter logout
- Afhænger af browser cache og GolfBox OAuth session cookies

**Workaround:**
- Hard refresh (Ctrl+Shift+F5) eller incognito mode for frisk login
- Clear browser data for komplet logout
- Normal brugere oplever ikke dette (logger sjældent ud)

**Impact:**
- Low - Primært et test/development issue
- End users vil typisk bruge persistent login (ønsket adfærd)

**Future Fix:**
- Implementer explicit session clear på logout
- Eller: "Switch User" funktion i stedet for fuld logout
- Vurder efter user testing feedback

**Issue 2: DGU-nummer Validation**

**Beskrivelse:**
- OAuth flow returnerer ikke DGU-nummer fra GolfBox
- App beder bruger om at indtaste DGU-nummer manuelt
- Ingen validering at indtastet nummer matcher OAuth bruger
- Bruger kan indtaste hvilket som helst DGU-nummer

**Current Behavior:**
1. OAuth success → Gem token
2. Bed om DGU-nummer via TextField
3. Fetch player data med Basic Auth (ikke OAuth token)
4. Success - uanset om det matcher OAuth bruger

**Use Case:**
- **Testing:** Nyttigt for at skifte mellem test-brugere hurtigt
- **Production:** Potentielt forvirrende hvis bruger indtaster forkert nummer

**Future Fix:**
- Når GolfBox OAuth returnerer unionId/DGU-nummer:
  - Fjern manuel input
  - Brug OAuth token direkte til player data
  - Full OAuth-baseret flow uden Basic Auth
- Alternativt: Valider at indtastet nummer findes i OAuth scope/claims

**Priority:** Medium - Afvent GolfBox API updates og user feedback

**Status:** Documented Dec 17, 2025 - Acceptabel for POC fase

### Current Limitations
- **Test Whitelist**: WHS submission kun for test-brugere
- **No Offline Support**: Requires internet
- **Web Only**: Primært Chrome (mobile responsive)
- **Firestore Security**: Open rules for Birdie Bonus cache (proper auth coming)
- **Social Features**: Friends system in Phase 2 (in development)

### Security TODO
- 🔐 **Token Rotation Needed**: Statistik API token skal roteres (var exposed i git history)
  - Generer nyt password i DGU/Statistik system
  - Opdater Gist med nyt token
  - Test at app virker med nyt token

- 🔒 **Firestore Rules - Birdie Bonus Cache**: Midlertidig åben read access
  - **Current**: `allow read: if true;` (open for all)
  - **Issue**: Permission errors med `isAuthenticated()` check + `Source.server`
  - **TODO**: Implementer proper Firebase Auth med custom claims for `unionId`
  - **Target**: `allow read: if request.auth != null && request.auth.token.unionId != null;`
  - **Files**: `firestore.rules`, `lib/services/birdie_bonus_service.dart`
  - **Priority**: Medium (POC environment, low risk)

### CORS Handling
- **Local**: `--disable-web-security` flag
- **Production**: Cloud Functions proxy for all APIs

---

## 📚 Documentation

### Related Files
- `FIREBASE_FUNCTIONS_V5_UPGRADE_PLAN.md` - Future function upgrades
- `DEPLOYMENT_GUIDE.md` - Detailed deployment steps
- `BIRDIE_BONUS_FOR_GOLFBOX.md` - **Birdie Bonus implementation reference for GolfBox** (English)
- `/Users/nickhuttel/.cursor/plans/dgu_app_v2.0_extended_poc_c6b753fb.plan.md` - Master roadmap

### External Resources
- [World Handicap System](https://www.worldhandicapsystem.com/)
- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)

---

## 👥 Contributing

Dette er et POC projekt for DGU. Pull requests velkomne!

### Development Guidelines
1. Follow Flutter/Dart style guide
2. Run `flutter analyze` før commit
3. Test både 9 og 18-hole courses
4. Test all authentication flows
5. Keep DGU design consistency
6. Document complex calculations

---

## 📞 Contact

**Developer:** Nick Hüttel

**Organization:** Dansk Golf Union (DGU)

**Purpose:** POC for integration i DGU Mit Golf app

---

## 🎯 Next Steps

**After Phase 1 (Scorearkiv + Dark Mode):**
1. Implement Friends System
2. Build Activity Feed
3. Create Leaderboards
4. User testing (20+ users)
5. Evaluate POC success
6. Prepare for Mit Golf integration

---

**Bygget med ❤️, Flutter og Firebase**

**Version:** 2.0 Extended POC - Dashboard Redesign + OAuth Login

**Last Updated:** December 17, 2025 - Merged v2.0 to main, deployed to all URLs
