# DGU Scorekort v2.0 - Extended POC

**Flutter Web App** til danske golfspillere med scorecard indtastning og **handicap-focused social features**.

## 🎯 Status: Version 2.0 Extended POC (In Development)

**Branch:** `feature/extended-version`

**Live URLs:**
- **POC (v2.0):** [https://dgu-app-poc.web.app](https://dgu-app-poc.web.app) - Extended version med social features
- **Production (v1.6):** [https://dgu-scorekort.web.app](https://dgu-scorekort.web.app) - Stable version

---

## 📱 What's New in v2.0

### Strategic Context

**DGU Scorekort v2.0** er en **Proof of Concept (POC)** for integration i **DGU Mit Golf** app.

**Goals:**
- ✅ Demonstrate at native Flutter UI > GolfBox webview
- ✅ Prove at **social features driver engagement** (især handicap tracking)
- ✅ Production-ready code til integration i Mit Golf app

### New Navigation Structure

**From:** Single page scorecard app

**To:** Multi-tab app med Home dashboard (Mit Golf style!)

**Navigation:**
- 🏠 **Hjem** - Dashboard med quick actions + previews
- 👥 **Venner** - Handicap tracking for friends (Coming in Phase 2)
- 📰 **Feed** - Activity feed med handicap milestones (Coming in Phase 2)
- 🏆 **Tops** - Leaderboards (Coming in Phase 2)
- ☰ **Menu** - Settings, privacy, om app

**Design:**
- White header med DGU logo
- Bottom navigation bar (like Mit Golf app)
- Player info card med HCP badge
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

### 🎨 Mit Golf Design Language - NEW!
- ✅ **White Header**: DGU logo centered (matches Mit Golf app)
- ✅ **Bottom Navigation**: 5 tabs (Hjem, Venner, Feed, Tops, Menu)
- ✅ **Player Info Card**: Name, home club, HCP badge på Hjem tab
- ✅ **iOS Status Bar Spacing**: Proper spacing for Dynamic Island
- ✅ **Taller Bottom Nav**: Better touch targets (72px height)
- ✅ **Light Grey Background**: Clean, modern look
- ✅ **Simplified Menu**: Settings, privacy, om app, log ud

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

## 🚀 Coming in Phase 2: Social Features

### 👥 Friends System (HANDICAP-FOCUSED!)
- **Add Friends**: Via DGU nummer
- **Handicap Dashboard**: Se venners aktuelle handicap
- **Handicap Trends**: Graf over udvikling (3/6/12 mdr)
- **Handicap Changes**: "Jonas: 12.8 → 12.0 📉 (-0.8)"
- **Challenge Friend**: Link til match play

### 📰 Activity Feed (MILESTONE-FOCUSED!)
- **Auto-detect Milestones**:
  - Handicap improvements
  - Major milestones (single-digit, scratch)
  - Personal bests
- **Score Highlights**: Eagles, match wins
- **Like & Comment**: Social interaction
- **Push Notifications**: Stay updated

### 🏆 Leaderboards (HANDICAP FIRST!)
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
│   └── score_record_model.dart            # WHS score record (NEW v2.0)
├── providers/
│   ├── auth_provider.dart                 # Auth state
│   ├── match_setup_provider.dart          # Club/course/tee selection
│   ├── scorecard_provider.dart            # Scorecard state
│   └── match_play_provider.dart           # Match play state
├── services/
│   ├── auth_service.dart                  # OAuth 2.0 PKCE
│   ├── dgu_service.dart                   # DGU Basen API
│   ├── player_service.dart                # Player API
│   ├── course_cache_service.dart          # Firestore cache
│   ├── scorecard_storage_service.dart     # Firestore scorecards
│   ├── notification_service.dart          # Push notifications
│   ├── whs_submission_service.dart        # WHS submission
│   └── whs_statistik_service.dart         # WHS scores (NEW v2.0)
├── utils/
│   ├── handicap_calculator.dart           # WHS calculations
│   ├── stroke_allocator.dart              # Stroke allocation
│   └── score_helper.dart                  # Golf terms
└── screens/
    ├── home_screen.dart                   # Home dashboard (NEW v2.0)
    ├── score_archive_screen.dart          # Score archive (NEW v2.0)
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

### Firestore Collections

#### `scorecards`
Scorekort med marker approval

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
- `/match-play` - Match play (no auth required)
- `/marker-approval/:id` - Remote approval (no auth required)
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
3. ✅ **Notification token** - Push to Mit Golf

**Cloud Functions fetch tokens serverside** - never exposed to browser!

### Token URLs (Private Gists)
```dart
// Stored in services, fetched by Cloud Functions
const DGU_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/.../dgu_token.txt';
const WHS_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/.../statistik%20token';
const NOTIF_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/.../notification_token.txt';
```

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
- [ ] Dark mode (pending)

### 🔄 Phase 2: Social Features (IN PROGRESS)
- [ ] Friends System
- [ ] Friend detail (handicap trends)
- [ ] Activity Feed
- [ ] Feed interaction (likes, comments)
- [ ] Leaderboards
- [ ] Cloud Function: calculateLeaderboards

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

### Current Limitations
- **Test Whitelist**: WHS submission kun for test-brugere
- **No Offline Support**: Requires internet
- **Web Only**: Primært Chrome (mobile responsive)
- **Firestore Security**: Open rules (auth kommer senere)
- **No Dark Mode**: Coming in Phase 1
- **Social Features**: Coming in Phase 2-3

### CORS Handling
- **Local**: `--disable-web-security` flag
- **Production**: Cloud Functions proxy for all APIs

---

## 📚 Documentation

### Related Files
- `FIREBASE_FUNCTIONS_V5_UPGRADE_PLAN.md` - Future function upgrades
- `DEPLOYMENT_GUIDE.md` - Detailed deployment steps
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

**Version:** 2.0 Extended POC (In Development)

**Last Updated:** December 2024
