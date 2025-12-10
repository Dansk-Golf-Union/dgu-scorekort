# DGU Scorekort

Flutter Web App til danske golfspillere til at rapportere scorekort.

## Status: ✅ Version 1.4 - Med Firebase Backend, Remote Markør Godkendelse & Firestore Caching

**Live App (Firebase):** [https://dgu-scorekort.web.app](https://dgu-scorekort.web.app)  
**Live App (GitHub):** [https://dansk-golf-union.github.io/dgu-scorekort/](https://dansk-golf-union.github.io/dgu-scorekort/)

## Overview

DGU Scorekort er en moderne web-applikation bygget med Flutter, der gør det muligt for danske golfspillere at:
- Vælge golfklub, bane og tee fra DGU Basen API
- Beregne spillehandicap efter danske WHS regler
- Indtaste scores på to måder (Plus/Minus eller Hurtig keypad)
- **Få remote markør godkendelse via URL** (nyt i v1.3!)
- Se detaljeret scorekort med Stableford points
- Beregne handicap resultat (score differential)
- Gemme scorekort i Firebase Firestore
- **Firestore caching af klubber og baner** (nyt i v1.4!)
- Indsende scores til DGU (klar til API integration)

## ✨ Nye Features i v1.4

### ⚡ Firestore Caching (Performance Boost)
- ✅ **Cache Management Screen**: UI til cache kontrol
- ✅ **Club & Course Caching**: Gem alle DGU klubber og baner i Firestore
- ✅ **Course Filtering**: Filtrerer inaktive og gamle course versioner før caching
- ✅ **Split Data Structure**: `info` (lightweight) + `courses` (separate)
- ✅ **Metadata-based Club List**: Hent 213 klubber med 1 read (instant!)
- ✅ **API Fallback**: Automatisk fallback til API hvis cache tom/ugyldig
- ✅ **Manual Seeding**: Seed cache fra UI (~2 min for alle klubber)
- ✅ **Performance**: Reduktion fra 2-3s til <0.2s for klub-valg
- ✅ **Data Optimization**: 
  - Før: ~42MB data, 213 Firestore reads
  - Nu: ~20KB metadata, 1 Firestore read

### ✨ Features fra v1.3

### 🔥 Firebase Backend
- ✅ **Firebase Core & Firestore** integration
- ✅ **Cloud Database**: Scorekort gemmes i Firestore
- ✅ **Real-time Updates**: Marker approval opdaterer live
- ✅ **Persistent Storage**: Scorekort overlever page reload

### 🌐 Remote Markør Godkendelse
- ✅ **Marker Assignment**: Vælg markør ved DGU nummer før gemning
- ✅ **Eksterne URLs**: Generer unik godkendelses-URL
- ✅ **Email/SMS Ready**: Send URL til markør (via mail indtil videre)
- ✅ **Standalone Approval Screen**: Markør kan godkende uden at logge ind
- ✅ **Read-only Scorecard View**: Markør ser komplet scorekort
- ✅ **Approve/Reject**: Markør kan godkende eller afvise med begrundelse
- ✅ **Status Tracking**: Pending → Approved → Submitted flow
- ✅ **"Luk Scorekort" knap**: Nem exit efter godkendelse

### 🚀 Deployment & Routing
- ✅ **Firebase Hosting**: Deployed til dgu-scorekort.web.app
- ✅ **go_router**: Deep linking til marker approval URLs
- ✅ **Dual Deployment**: Både Firebase og GitHub Pages
- ✅ **Hash Routing**: Korrekt Flutter web routing

## 🔥 Implementerede Features

### 🔐 Authentication & Player
- ✅ **Union ID Login**: Simpel login med DGU nummer (aktiv)
- ✅ **OAuth 2.0 PKCE**: Komplet implementation (deaktiveret, klar til brug)
- ✅ Hent spiller data fra GolfBox API
- ✅ Automatisk parsing af navn, handicap, hjemmeklub
- ✅ Gender-based tee filtering (kun relevante tees vises)
- ✅ Persistent login med localStorage
- ✅ Logout funktionalitet

### 🏌️ Setup & Handicap
- ✅ Vælg mellem alle 190+ danske golfklubber
- ✅ Filtrer og vælg aktive baner
- ✅ Vælg tee (filtreret efter køn) med Course Rating og Slope
- ✅ Beregning af spillehandicap (dansk WHS formel)
- ✅ Understøtter både 9 og 18 hullers baner
- ✅ WHS-korrekt afrunding for 9-hullers handicap
- ✅ Moderne dropdown design med card styling

### ⛳ Scorekort Input
- ✅ To input metoder:
  - **Tæller +/-**: Traditionel op/ned tæller fra netto par
  - **Keypad**: Hurtig indtastning med dynamiske golf-term labels (Par, Birdie, Bogey, etc.)
- ✅ Automatisk stroke allocation baseret på hole index
- ✅ Real-time Stableford point beregning
- ✅ Visual feedback for hver score
- ✅ Auto-advance til næste hul (kun Keypad)

### 📊 Resultat & Analyse
- ✅ Detaljeret scorekort i DGU app stil
- ✅ Visual markers for birdie, eagle, par, bogey, double bogey
- ✅ Ud/Ind/Total summering (18 huller)
- ✅ Handicap resultat (score differential) med Net Double Bogey regel
- ✅ WHS-korrekt afrunding af negative handicap resultater

### ✍️ Markør Godkendelse & Submission

#### Lokal Markør (Original Flow)
- ✅ **In-Person Approval**: "Få Markør Underskrift Her"
- ✅ **Digital Signature Pad**: Touch-optimeret signature canvas
- ✅ **Signature Preview**: Vises på results screen
- ✅ **Direct Submission**: Indsend direkte efter underskrift

#### Remote Markør (Ny Firebase Flow)
- ✅ **"Send til Markør" knap**: Starter remote approval
- ✅ **Marker Selection Dialog**: Indtast markørs DGU nummer
- ✅ **Fetch Marker Info**: Slå markør op i DGU database
- ✅ **Save to Firestore**: Gem scorekort med "pending" status
- ✅ **Generate URLs**: Både localhost og production URLs
- ✅ **Clickable Links**: Åbn i ny tab direkte fra app
- ✅ **Marker Approval Screen**: Standalone screen med:
  - Assigned marker info (navn, DGU nummer)
  - Komplet read-only scorekort
  - Spiller information
  - Bane/tee detaljer
  - Approve/Reject knapper
- ✅ **Status Updates**: Real-time opdatering af scorecard status
- ✅ **"Luk Scorekort" knap**: Luk browser tab efter godkendelse
- ✅ **Rejection Reason**: Valgfri begrundelse ved afvisning

### 🗄️ Firebase & Database
- ✅ **Firebase Core**: Initialiseret med web config
- ✅ **Cloud Firestore**: Database til scorekort
- ✅ **Firestore Security Rules**: Åben læsning for marker approval
- ✅ **ScorecardStorageService**: Centraliseret data layer
- ✅ **Document References**: Unikke IDs til hver scorecard
- ✅ **Status Tracking**: pending → approved/rejected → submitted
- ✅ **Timestamp Fields**: createdAt, updatedAt tracking

## 🛠️ Teknisk Stack

### Framework & Libraries
- **Flutter 3.38.4** (Dart SDK)
- **Provider 6.1.1** - State management
- **Firebase Core 3.8.1** - Firebase initialization *(nyt)*
- **Cloud Firestore 5.5.1** - NoSQL database *(nyt)*
- **go_router 14.8.1** - Deep linking & routing *(nyt)*
- **HTTP 1.2.0** - API kommunikation
- **URL Launcher 6.2.2** - Åbn eksterne URLs
- **Google Fonts 6.1.0** - Typography (Roboto)
- **Intl 0.19.0** - Date formatting
- **Crypto 3.0.3** - SHA256 for PKCE
- **SharedPreferences 2.2.2** - Token storage
- **Signature 5.5.0** - Digital signature pad

### Arkitektur
- **State Management**: Provider pattern (AuthProvider, MatchSetupProvider, ScorecardProvider)
- **Backend**: Firebase (Firestore Database + Hosting)
- **Routing**: go_router med deep linking til marker approval
- **Design System**: Material 3 med DGU farver og custom theming
- **API**: DGU Basen REST API med Basic Auth (public) og Bearer tokens (OAuth)
- **CORS**: Handled via corsproxy.io for production
- **Platform**: Web (Chrome primary target, deployed til Firebase Hosting og GitHub Pages)

## 📁 Projekt Struktur

```
lib/
├── main.dart                          # Entry point, Firebase init & routing
├── config/
│   ├── auth_config.dart               # OAuth & API konfiguration
│   └── firebase_options.dart          # Firebase config (nyt)
├── theme/
│   └── app_theme.dart                 # DGU farver og Material 3 theme
├── models/
│   ├── club_model.dart                # Club, GolfCourse, Tee, Hole
│   ├── player_model.dart              # Player (med OAuth fields & gender)
│   └── scorecard_model.dart           # Scorecard, HoleScore
├── providers/
│   ├── auth_provider.dart             # Authentication state (OAuth & Simple)
│   ├── match_setup_provider.dart      # Club/Course/Tee selection state
│   └── scorecard_provider.dart        # Scorecard state & score input
├── services/
│   ├── auth_service.dart              # OAuth 2.0 PKCE service
│   ├── dgu_service.dart               # DGU Basen API client (public endpoints)
│   ├── player_service.dart            # Player API service (OAuth & Union ID)
│   ├── scorecard_storage_service.dart # Firestore scorecard operations
│   ├── course_cache_service.dart      # Firestore cache read + API fallback (nyt v1.4)
│   └── cache_seed_service.dart        # Firestore cache seeding (nyt v1.4)
├── utils/
│   ├── handicap_calculator.dart       # WHS handicap beregninger
│   ├── stroke_allocator.dart          # Stroke allocation algoritme
│   └── score_helper.dart              # Golf term labels
└── screens/
    ├── login_screen.dart              # OAuth login screen
    ├── simple_login_screen.dart       # Union ID login (aktiv)
    ├── scorecard_screen.dart          # Plus/Minus scorecard
    ├── scorecard_keypad_screen.dart   # Hurtig keypad scorecard
    ├── marker_approval_screen.dart    # In-person markør godkendelse
    ├── marker_assignment_dialog.dart  # Remote marker selection
    ├── marker_approval_from_url_screen.dart # Remote approval screen
    ├── scorecard_results_screen.dart  # Resultat visning & submission
    └── cache_management_screen.dart   # Cache control & seeding (nyt v1.4)
```

## 🔥 Firebase Setup

### Firebase Project
**Project ID**: `dgu-scorekort`  
**Hosting URL**: `https://dgu-scorekort.web.app`

### Firestore Collection: `scorecards`

**Document Structure:**
```json
{
  "playerId": "177-2813",
  "playerName": "Nick Hüttel",
  "clubName": "Outrup Golfklub",
  "courseName": "Aarhus Golf Club 18H Ny",
  "teeColor": "Gul",
  "playingHandicap": 12,
  "totalPoints": 39,
  "handicapResult": 13.0,
  "playedDate": "10.12.2025",
  "holes": [...],
  "assignedMarker": {
    "markerId": "72-4197",
    "markerName": "Jonas Meyer",
    "markerClub": "Dragør Golfklub"
  },
  "status": "pending|approved|rejected|submitted",
  "rejectionReason": "...",
  "createdAt": Timestamp,
  "updatedAt": Timestamp
}
```

### Firestore Collections

#### 1. `scorecards` - Scorekort med markør godkendelse
#### 2. `course-cache-metadata` - Cache metadata
#### 3. `course-cache-clubs` - Cached klub/bane data

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Scorecards (marker approval)
    match /scorecards/{documentId} {
      allow read: if true;  // Anyone can read (for marker approval)
      allow write: if true; // Anyone can write (should be authenticated later)
    }
    
    // Course cache metadata
    match /course-cache-metadata/{document=**} {
      allow read: if true;  // Public read for app
      allow write: if true; // Anyone can seed (should be admin only later)
    }
    
    // Course cache clubs
    match /course-cache-clubs/{document=**} {
      allow read: if true;  // Public read for app
      allow write: if true; // Anyone can seed (should be admin only later)
    }
  }
}
```

### Firestore Cache Structure

**Purpose:** Cache all Danish golf clubs and courses in Firestore to reduce API calls and improve performance.

**Collections:**

#### `course-cache-metadata/data`
```json
{
  "lastUpdated": Timestamp,
  "clubCount": 213,
  "courseCount": 876,
  "version": 2,
  "clubs": [
    {"ID": "club-id-1", "Name": "Aalborg Golf Klub"},
    {"ID": "club-id-2", "Name": "Aarhus Golf Club"},
    ...
  ]
}
```

**Why club list in metadata?**
- ⚡ Load all 213 clubs with **1 Firestore read** instead of 213!
- Metadata doc size: ~20KB (all club names)
- Load time: <0.2s (before: 2-3s)

#### `course-cache-clubs/{clubId}`
```json
{
  "info": {
    "ID": "club-id",
    "Name": "Aalborg Golf Klub",
    "Address": "...",
    // Other club metadata WITHOUT courses
  },
  "courses": [
    {
      "ID": "course-id",
      "Name": "Aalborg GK 18H",
      "IsActive": true,
      "ActivationDate": "2025-01-01T00:00:00",
      "TemplateID": "template-123",
      "Tees": [...],
      "Holes": [...],
      // Full course data
    }
  ],
  "updatedAt": Timestamp
}
```

**Cache Flow:**

1. **App starts** → Load clubs from metadata (1 read, instant!)
2. **User selects club** → Load courses for that club (1 read, ~0.2s)
3. **Cache invalid/empty** → Automatic fallback to API
4. **Manual seeding** → Cache Management screen (~2 min for all data)

**Data Optimization:**
- **Course Filtering** before caching:
  - Only `IsActive: true` courses
  - Only courses with `ActivationDate <= now`
  - Only latest version per `TemplateID` (removes old course versions)
- **Result**: 50-70% less data than raw API response
- **Size per club**: 150-250KB (after filtering, before: 300KB-1MB+)

**Cache Validity:**
- Valid for 24 hours
- Checked on each app load
- Falls back to API if stale

### Firebase Hosting Config (`firebase.json`)
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

## 🌐 Marker Approval Flow

### 1. Player Creates Scorecard
1. Spiller afslutter runde
2. Klikker "Send til Markør"
3. Indtaster markørs DGU nummer
4. System henter markør info fra DGU API
5. Bekræfter markør valg

### 2. Save to Firebase
1. Scorecard gemmes i Firestore med status "pending"
2. Unikt document ID genereres
3. Markør info inkluderes i document

### 3. Generate Approval URLs
**Localhost:**
```
http://localhost:PORT/#/marker-approval/DOCUMENT_ID
```

**Production:**
```
https://dgu-scorekort.web.app/#/marker-approval/DOCUMENT_ID
```

### 4. Marker Opens URL
1. Markør modtager URL (via mail/SMS)
2. Åbner URL i browser (ingen login påkrævet)
3. Ser komplet scorecard i read-only mode
4. Ser egen info som assigned marker

### 5. Marker Approves/Rejects
**Approve:**
- Klikker "✅ Godkend Scorekort"
- Status opdateres til "approved"
- Klikker "Luk Scorekort" for at lukke tab

**Reject:**
- Klikker "❌ Afvis Scorekort"
- Indtaster begrundelse
- Status opdateres til "rejected"
- Klikker "Luk Scorekort" for at lukke tab

### 6. Player Receives Confirmation
*(Kommer i fremtidig version - push notification eller email)*

## 🌐 API Integration

### GolfBox DGU Basen API

**Base URL:** `https://dgubasen.api.union.golfbox.io/info@ingeniumgolf.dk`

**Endpoints:**
- `GET /clubs` - Alle danske golfklubber (Basic Auth)
- `GET /clubs/{clubId}/courses` - Baner for klub (Basic Auth)
- `GET /clubs/golfer?unionid={unionId}` - Spiller info (Basic Auth)
- `GET /clubs/golfer` - Spiller info fra OAuth token (Bearer)
- `POST /ScorecardExchange` - Indsend scorekort (TODO: implementer)

**Authentication:**
- **Public endpoints**: Basic Auth via token fra GitHub Gist
- **Player endpoints**: Bearer token fra OAuth eller Basic Auth
- **CORS**: Handled via `https://corsproxy.io/?` proxy for production

### 🔐 API Token Configuration

**Location:** `lib/config/auth_config.dart`

**Basic Auth Token (Public API):**
```dart
class AuthConfig {
  // Basic Auth token for public endpoints (clubs, courses)
  static const String basicAuthToken = 'Basic aW5mb0Bpbmdlbm...'; // Hent fra Gist
  
  // GitHub Gist URL med aktuel token
  static const String tokenGistUrl = 
    'https://gist.githubusercontent.com/[USER]/[GIST_ID]/raw/token.txt';
}
```

**Hvor er token?**
1. **Production token**: Hentes fra privat GitHub Gist ved app start
2. **Token format**: Base64 encoded `username:password`
3. **Gist URL**: Defineret i `auth_config.dart`
4. **Token refresh**: Opdater Gist fil hvis DGU ændrer credentials

**Sådan opdaterer du token:**
1. Få nyt brugernavn/password fra DGU
2. Encode som Base64: `echo -n "username:password" | base64`
3. Tilføj "Basic " prefix
4. Opdater Gist fil på GitHub
5. Appen henter automatisk nyt token ved næste opstart

**OAuth Configuration:**
```dart
class AuthConfig {
  static const String clientId = 'DGU_TEST_DK';
  static const String authorizationEndpoint = 
    'https://auth.golfbox.io/connect/authorize';
  static const String tokenEndpoint = 
    'https://auth.golfbox.io/connect/token';
  static const String redirectUri = 
    'https://dgu-scorekort.web.app/callback'; // Skal konfigureres i GolfBox
}
```

**Data Filtering:**
- Kun aktive baner (`IsActive: true`)
- Activation date ≤ nu
- Nyeste version per `TemplateID`
- Alfabetisk sortering

### GolfBox OAuth 2.0

**Auth Server:** `https://auth.golfbox.io/connect/`

**Endpoints:**
- `/connect/authorize` - OAuth authorization
- `/connect/token` - Token exchange

**Configuration:**
- Client ID: `DGU_TEST_DK`
- Grant Type: Authorization Code with PKCE (S256)
- Scopes: `get_player.information none union`
- No Client Secret (Public Client)

**Status:** Implementeret men deaktiveret (redirect URI issues)

## 🧮 Handicap Beregninger

### Playing Handicap (Spillehandicap)

**18-hullers:**
```
Playing HCP = (HCP Index × Slope/113) + (Course Rating - Par)
```

**9-hullers (WHS regel):**
```
1. HCP Index / 2 = midlertidig værdi
2. Afrund til én decimal
3. Brug afrundet værdi i formlen

Eksempel: 14.5 / 2 = 7.25 → 7.3 → bruges i beregning
```

### Handicap Resultat (Score Differential)

**Med Net Double Bogey cap:**
```
1. Hver huls max score = Par + Strokes Received + 2
2. Adjusted Gross Score = sum af cappede scores
3. Score Differential = (113 / Slope) × (AGS - CR - PCC)
```

**Afrunding:**
- Positive: Normal afrunding til 0.1
- Negative: Afrund OP mod 0 (ceiling)
  - Eksempel: -1.55 → -1.5 (ikke -1.6)

### Stroke Allocation

Strokes fordeles baseret på hole index og playing handicap:
```
- Holes modtager 1 stroke hvis: hole.index <= playingHcp % 18
- Holes modtager ekstra stroke hvis: hole.index <= playingHcp / 18
```

## 🎨 Design System

### Farver (fra DGU app)
- **Primary Green**: `#1B5E20` - Buttons, AppBar, accents
- **Secondary Olive**: `#9E9D24` - (reserve, ikke brugt i nuværende version)
- **Background**: `#F5F5F5` - Let grå
- **Cards**: `#FFFFFF` - Hvide cards med elevation 2
- **Text**: Sort primær, `#757575` sekundær
- **Borders**: `#E0E0E0` - Let grå dividers

### Spacing & Layout
- Card padding: 16px
- Card spacing: 16px
- Border radius: 12px (cards), 8px (buttons)
- Max width: 600px (mobil-first design)
- Screen padding: 16px

### Typography
- Font: Google Fonts Roboto
- Headers: 20px bold
- Body: 14-16px regular
- Labels: 12-14px medium

## 🚀 Kom i Gang

### Prerequisites
- Flutter SDK 3.38.4 eller nyere
- Chrome browser (til web development)
- Firebase CLI (til deployment)

### Installation

```bash
# Clone repository
git clone https://github.com/Dansk-Golf-Union/dgu-scorekort.git
cd dgu_scorekort

# Hent dependencies
flutter pub get

# Kør lokalt i Chrome
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

**Note**: `--disable-web-security` flag kun nødvendigt lokalt. Production bruger CORS proxy.

### Development

```bash
# Hot reload (hurtigere, bevarer state)
r

# Hot restart (genstart app)
R

# Analyze code
flutter analyze

# Check for linter errors
flutter analyze lib/

# Run tests (når implementeret)
flutter test
```

### Deployment

#### Deploy til Firebase Hosting
```bash
# Build production version
flutter build web --release

# Deploy til Firebase
firebase deploy --only hosting

# URL: https://dgu-scorekort.web.app
```

**⚠️ Efter deploy: Seed production cache**
1. Åbn https://dgu-scorekort.web.app
2. Log ind med DGU nummer
3. Klik på ⚙️ ikon (Storage) i top højre hjørne
4. Klik "Seed Cache" (~2 minutter)
5. Verificer i Firebase Console at data er gemt
6. Test klub-valg - skal være instant!

#### Deploy til GitHub Pages
```bash
# Commit og push til GitHub
git add .
git commit -m "Deploy updates"
git push

# GitHub Actions deployer automatisk til:
# https://dansk-golf-union.github.io/dgu-scorekort/
```

## 📋 Feature Status

### ✅ Completed (v1.3)
- [x] Union ID login (simple, aktiv)
- [x] OAuth 2.0 PKCE login (komplet, deaktiveret)
- [x] Hent spiller data fra GolfBox API
- [x] Gender-based tee filtering
- [x] DGU API integration (clubs, courses, tees)
- [x] Course filtering (active, latest version)
- [x] Playing handicap beregning (9 & 18 huller)
- [x] 9-hole WHS rounding fix
- [x] Stroke allocation algoritme
- [x] Tæller +/- scorecard
- [x] Keypad scorecard med golf terms (mobil-optimeret)
- [x] Stableford point calculation
- [x] Resultat screen i DGU stil (1:1 match)
- [x] Score markers (circles/boxes for birdie/bogey)
- [x] Handicap resultat med Net Double Bogey
- [x] Material 3 theme med DGU farver
- [x] Dropdown card styling
- [x] GitHub Pages deployment
- [x] CORS proxy for production
- [x] Markør godkendelse flow (in-person)
- [x] Digital signature pad (touch-optimeret)
- [x] Signature preview på results screen
- [x] **Firebase Core & Firestore integration** *(nyt)*
- [x] **Remote marker assignment dialog** *(nyt)*
- [x] **Save scorecards to Firestore** *(nyt)*
- [x] **Generate marker approval URLs** *(nyt)*
- [x] **Standalone marker approval screen** *(nyt)*
- [x] **Approve/Reject with reason** *(nyt)*
- [x] **"Luk Scorekort" button** *(nyt)*
- [x] **Firebase Hosting deployment** *(nyt)*
- [x] **go_router deep linking** *(nyt)*
- [x] **Dual deployment (Firebase + GitHub)** *(nyt)*
- [x] **Firestore caching for clubs/courses** *(nyt v1.4)*
- [x] **Cache Management UI** *(nyt v1.4)*
- [x] **Course filtering before caching** *(nyt v1.4)*
- [x] **Metadata-based club list (instant load)** *(nyt v1.4)*
- [x] **API fallback for invalid cache** *(nyt v1.4)*

### 🔄 In Progress
- [ ] OAuth redirect URI configuration (venter på setup)
- [ ] POST til DGU ScorecardExchange API
- [ ] Push notification til markør (via DGU Mit Golf app)

### 📅 Future Enhancements

#### Cache & Performance
- [ ] Cloud Function for automated cache updates (daglig kl. 02:00)
- [ ] Cache analytics og monitoring
- [ ] Cache version migration strategy

#### Scorecard & Markers
- [ ] Aktivér DGU ScorecardExchange POST endpoint
- [ ] Send marker approval URL via push besked (DGU app integration)
- [ ] Email notification til markør
- [ ] Historik over tidligere runder (query Firestore)
- [ ] Marker kan se alle pending approvals
- [ ] Player kan se approval status
- [ ] Export til PDF/print

#### Features
- [ ] Multiple spillere (flightmode)
- [ ] Statistik over tid (gennemsnit, trends)
- [ ] Dark mode
- [ ] Offline support med sync
- [ ] Native mobile apps (iOS/Android)
- [ ] PWA support (install som app)

#### Security
- [ ] Firestore Security Rules (authentication required)
- [ ] Admin-only cache write access

## 🔧 Tekniske Detaljer

### State Management

Bruger **Provider** pattern med tre hovedproviders:

**AuthProvider:**
- Håndterer login/logout
- OAuth 2.0 eller Union ID
- Token management
- User state

**MatchSetupProvider:**
- Håndterer club/course/tee selection
- Beregner playing handicap
- Loader data fra DGU API
- Validerer om runde kan startes

**ScorecardProvider:**
- Håndterer scorekort state
- Score input og validation
- Stableford point beregning
- Hole navigation (PageView synkronisering)
- Marker approval tracking
- Scorecard submission (ready for API)
- Round completion

### Data Models

**Key models:**
- `Club` - Golf klub med ID og navn
- `GolfCourse` - Bane med tees, holes, metadata
  - `TemplateID` - Bruges til versioning
  - `ActivationDate` - Filtrer på aktiv dato
  - `IsActive` - Filtrer kun aktive baner
- `Tee` - Tee med CR, Slope, par, holes
  - `isNineHole` - Flag for 9 vs 18 huller
  - `courseRating` - Course Rating (divideret med 10000 fra API)
  - `slopeRating` - Slope Rating
- `Hole` - Hul med nummer, par, index
- `Player` - Spiller med navn, HCP, gender, hjemmeklub
- `Scorecard` - Aktiv runde med scores, marker info, signature og submission tracking
  - `markerFullName`, `markerUnionId`, `markerSignature` (base64 PNG)
  - `isSubmitted`, `submittedAt`, `isMarkerApproved`
- `HoleScore` - Score for enkelt hul med points og netto

### Performance
- **Firestore Caching**: 213 clubs loaded with 1 read (<0.2s vs 2-3s)
- **Course filtering**: Pre-filtered data reduces size 50-70%
- **Metadata-based lists**: Instant loading of club names
- **API Fallback**: Automatic fallback if cache invalid
- Lazy loading af courses (kun når klub vælges)
- Filtering og grouping i memory (ikke API)
- Hot reload friendly architecture
- Effektiv state updates med notifyListeners
- Firebase Firestore indexing for queries

### Code Organization
- **Clean Architecture** principper
- **Separation of Concerns**: Models, Services, Providers, Screens
- **Single Responsibility**: Hver fil har ét ansvar
- **Reusable Components**: Widgets genbruges hvor muligt

## ⚠️ Known Issues & Considerations

### Current Implementation
- **Login Method**: Union ID login (midlertidig løsning)
  - OAuth 2.0 PKCE implementeret men deaktiveret
  - Skift til OAuth: Sæt `useSimpleLogin = false` i `main.dart`
  - Kræver OAuth redirect URI konfiguration i GolfBox
- **Marker Notification**: Manuel URL deling (email/SMS)
  - Push notification via DGU app kommer senere
- **Firestore Security**: Åben læsning/skrivning
  - Authentication-based rules kommer senere
- **Signature Storage**: Base64 PNG i Firestore document
  - Firebase Storage integration kan tilføjes senere
- **Token Security**: Basic Auth token hentes fra privat GitHub Gist
- **CORS**: Løst via corsproxy.io for production
- **Web Only**: Primært testet i Chrome web browser, mobil-optimeret

### Current Limitations
- **No Score Submission**: POST til DGU API ikke implementeret endnu
- **Manual URL Sharing**: Markør skal modtage URL manuelt (indtil push notification)
- **No Error Recovery**: Begrænsede retry strategier
- **Single Player**: Ingen flight/gruppe support endnu

### Future Considerations
- **Automated Cache Updates**: Cloud Function til daglig cache opdatering (kl. 02:00)
- **Cache Analytics**: Track cache hit rate og performance metrics
- Aktivér OAuth login når redirect URI er konfigureret
- Implementer push notification til markør (DGU app integration)
- Tilføj Firestore Security Rules med authentication (admin-only cache write)
- Backend for token proxy (i stedet for Gist)
- Implementer proper error handling og retry logic
- Tilføj loading states og skeleton screens
- Implementer proper logging og analytics
- Tilføj unit tests og widget tests
- Performance monitoring og optimization
- Multi-player support (flights)

## 🧪 Testing

### Manual Testing Checklist
- [ ] Log ind med DGU nummer
- [ ] Vælg klub → Skal vise baner
- [ ] Vælg bane → Skal vise tees (filtreret efter køn)
- [ ] Vælg tee → Skal beregne spillehandicap
- [ ] Start runde (Plus/Minus) → Indtast scores → Se resultat
- [ ] Start runde (Hurtig) → Indtast scores → Se resultat
- [ ] Test 9-hullers bane → Verificer handicap beregning
- [ ] Test 18-hullers bane → Verificer Ud/Ind/Total
- [ ] Verificer score markers (circles/boxes)
- [ ] Verificer handicap resultat beregning
- [ ] **Test In-Person Marker**: "Få Markør Underskrift Her" → underskrift → submit
- [ ] **Test Remote Marker**: "Send til Markør" → indtast DGU nummer → gem
- [ ] **Test Marker URLs**: Åbn både localhost og production URL
- [ ] **Test Marker Approval**: Godkend scorekort → klik "Luk Scorekort"
- [ ] **Test Marker Rejection**: Afvis med begrundelse → klik "Luk Scorekort"
- [ ] **Test Firestore**: Verificer data gemmes korrekt i Firebase Console
- [ ] **Test Cache Management**: Åbn Cache Management screen
- [ ] **Test Cache Seeding**: Seed cache (~2 min) → verificer i Firebase Console
- [ ] **Test Cache Loading**: Verificer klub-liste loader instant efter seed
- [ ] **Test Cache Fallback**: Ryd cache → verificer API fallback virker

### Automated Tests (Future)
```bash
# Unit tests
flutter test test/unit/

# Widget tests
flutter test test/widget/

# Integration tests
flutter test test/integration/
```

## 📚 Ressourcer

### Golf Regler
- [World Handicap System (WHS)](https://www.worldhandicapsystem.com/)
- [Danish Golf Union - Handicapregler](https://www.dgu.org/)

### Flutter
- [Flutter Documentation](https://flutter.dev/docs)
- [Provider Package](https://pub.dev/packages/provider)
- [Material 3 Design](https://m3.material.io/)

### Firebase
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Cloud Firestore](https://firebase.google.com/docs/firestore)
- [Firebase Hosting](https://firebase.google.com/docs/hosting)

## 👥 Contributing

Dette er et personligt projekt. Pull requests er velkomne!

### Development Guidelines
1. Follow Flutter/Dart style guide
2. Run `flutter analyze` before committing
3. Test både 9 og 18 hullers baner
4. Test både in-person og remote marker flows
5. Behold DGU design consistency
6. Dokumenter komplekse beregninger

## 📞 Contact

Nick Hüttel

## 📄 License

[License info hvis relevant]

---

**Bygget med ❤️, Flutter og Firebase**
