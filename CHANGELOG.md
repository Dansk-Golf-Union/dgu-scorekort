# Changelog

Alle væsentlige ændringer til dette projekt dokumenteres i denne fil.

## [1.7.0-dev] - 2025-12-15 (In Progress)

### 🎨 UI/UX Features
- **Tilføjet**: Dark Mode med manual toggle i Drawer
- **Tilføjet**: Golf.dk News Feed integration på Home screen (3 seneste artikler)
- **Tilføjet**: Scorearkiv med live fetch fra WHS/Statistik API
- **Opdateret**: Bottom navigation bar (Hjem, Venner, Feed, Tops, Menu)
- **Opdateret**: White header med DGU logo
- **Opdateret**: Login screen title: "DGU App 2.0 POC"

### 👥 Friends System (Data Layer - In Progress)
- **Tilføjet**: `Friendship`, `FriendRequest`, `FriendProfile`, `HandicapTrend` models
- **Tilføjet**: `FriendsService` med Firestore CRUD operations
- **Tilføjet**: `FriendsProvider` for state management
- **Tilføjet**: Firestore security rules for `friendships` og `friend_requests`
- **Tilføjet**: Cloud Function extended: `sendNotification` støtter friend requests
- **Tilføjet**: Deep link route: `/friend-request/:requestId`
- **Tilføjet**: `FriendRequestFromUrlScreen` med consent flow
- **Tilføjet**: Test dialog: "TEST: Tilføj Ven" knap i Drawer
- **Testet**: Friend request flow (notification sendt, modtaget, consent screen virker)
- **Note**: Login redirect efter friend request accept har timing issues (parked)

### 🔐 OAuth Infrastructure
- **Modtaget**: OAuth callback URL fra GolfBox: `https://europe-west1-dgu-scorekort.cloudfunctions.net/golfboxCallback`
- **Klar**: `golfboxCallback` Cloud Function deployed og verificeret
- **Pending**: Skift fra simple login til rigtig OAuth implementation

### 🔧 Tekniske Forbedringer
- **Tilføjet**: Path-based URL strategy (fjernet hash routing)
- **Tilføjet**: `ThemeProvider` for Dark Mode state management
- **Tilføjet**: `shared_preferences` for theme persistence
- **Tilføjet**: `fl_chart` dependency for handicap trend graphs
- **Tilføjet**: `flutter_web_plugins` for URL strategy
- **Opdateret**: `corsproxy.io` for Golf.dk news images i production
- **Opdateret**: Firebase multi-site hosting (dgu-app-poc.web.app)

### 📦 Dependencies
- **Tilføjet**: `shared_preferences: ^2.2.2`
- **Tilføjet**: `fl_chart: ^0.65.0`
- **Tilføjet**: `flutter_web_plugins: ^0.0.1`
- **Tilføjet**: `url_launcher: ^6.2.2`

## [1.5.0] - 2025-12-12

### 🔔 Push Notifications
- **Tilføjet**: Automatisk push notification til markør når scorekort sendes
- **Tilføjet**: Firebase Cloud Function proxy for DGU Notification API
- **Tilføjet**: Notification token management via GitHub Gist
- **Tilføjet**: Notification status feedback i UI (grøn/orange)
- **Tilføjet**: 7-dages udløb på notifications
- **Tilføjet**: NotificationService med Cloud Function integration

### 🎯 WHS API Submission
- **Tilføjet**: Automatisk submission til WHS API ved markør godkendelse
- **Tilføjet**: Test whitelist for gradvis udrulning (kun test-brugere)
- **Tilføjet**: ExternalID tracking med Firestore document ID
- **Tilføjet**: Minimum API payload med påkrævede felter
- **Tilføjet**: Status tracking med `isSubmittedToDgu` flag
- **Tilføjet**: WHSSubmissionService med detaljeret error handling

### 🔧 Firebase Cloud Functions
- **Tilføjet**: `sendNotification` callable function (europe-west1)
- **Tilføjet**: CORS-fri API kald til DGU notification endpoint
- **Tilføjet**: Automatisk token fetching fra GitHub Gist
- **Tilføjet**: Detaljeret logging for debugging

### 🛠️ Tekniske Forbedringer
- **Opdateret**: Results screen med notification feedback
- **Opdateret**: Marker approval flow med WHS submission
- **Fixet**: Web compatibility ved brug af HTTP POST i stedet for cloud_functions package

## [1.4.0] - 2025-12-10

### ⚡ Firestore Caching (Performance Boost)
- **Tilføjet**: Cache Management Screen med UI kontrol
- **Tilføjet**: Club & Course caching i Firestore
- **Tilføjet**: Course filtering (kun aktive, nyeste versioner)
- **Tilføjet**: Split data structure (info + courses)
- **Tilføjet**: Metadata-based club list (1 read, instant load!)
- **Tilføjet**: Automatisk API fallback ved invalid cache
- **Tilføjet**: Manual cache seeding fra UI (~2 min)
- **Tilføjet**: CourseCacheService med optimeret data struktur

### 📊 Performance Forbedringer
- **Forbedret**: Klub-liste load tid fra 2-3s til <0.2s
- **Reduceret**: Data fra ~42MB til ~20KB metadata
- **Optimeret**: Kun 1 Firestore read i stedet for 213

## [1.3.0] - 2025-12-08

### 🔥 Firebase Backend
- **Tilføjet**: Firebase Core & Cloud Firestore integration
- **Tilføjet**: Firestore security rules for public marker approval
- **Tilføjet**: ScorecardStorageService for database operations
- **Tilføjet**: Real-time status updates (pending → approved/rejected)
- **Tilføjet**: Timestamp tracking (createdAt, updatedAt)

### 🌐 Remote Markør Godkendelse
- **Tilføjet**: Marker Assignment Dialog med DGU nummer lookup
- **Tilføjet**: Fetch marker info fra DGU API
- **Tilføjet**: Save scorecard til Firestore med "pending" status
- **Tilføjet**: Generer unik godkendelses-URL
- **Tilføjet**: Standalone Marker Approval Screen
- **Tilføjet**: Read-only scorecard view for markør
- **Tilføjet**: Approve/Reject med valgfri begrundelse
- **Tilføjet**: "Luk Scorekort" knap efter godkendelse
- **Tilføjet**: Status tracking flow (pending → approved/rejected → submitted)

### 🚀 Deployment & Routing
- **Tilføjet**: Firebase Hosting deployment
- **Tilføjet**: go_router med deep linking support
- **Tilføjet**: Hash routing for Flutter web
- **Tilføjet**: Dual deployment (Firebase + GitHub Pages)

### 📦 Dependencies
- **Tilføjet**: `firebase_core: ^3.8.1`
- **Tilføjet**: `cloud_firestore: ^5.5.1`
- **Tilføjet**: `go_router: ^14.6.2`

## [1.1.0] - 2025-12-05

### 🔐 Authentication & Player Management
- **Tilføjet**: Simple Union ID login screen (aktiv løsning)
- **Tilføjet**: OAuth 2.0 PKCE implementation (deaktiveret, klar til brug)
- **Tilføjet**: AuthProvider for authentication state management
- **Tilføjet**: Gender field til Player model
- **Tilføjet**: Hent spiller data fra GolfBox API
- **Tilføjet**: Parse handicap, navn, køn, hjemmeklub fra API
- **Tilføjet**: Logout funktionalitet i AppBar

### ⛳ Golf Features
- **Tilføjet**: Gender-based tee filtering (kun relevante tees vises)
- **Fjernet**: Gender ikoner fra tee dropdown (ikke længere nødvendige)

### 🎨 UI/UX Forbedringer
- **Tilføjet**: Dropdown card styling med borders og spacing
- **Tilføjet**: MenuButtonTheme med elevation og shadows
- **Forbedret**: Input validation med helper text
- **Ændret**: Hint text til generisk eksempel (ikke rigtige numre)

### 🛠️ Tekniske Ændringer
- **Tilføjet**: `url_launcher`, `crypto`, `shared_preferences` packages
- **Tilføjet**: OAuth state parameter for web-kompatibilitet
- **Tilføjet**: Feature flag: `useSimpleLogin` for at skifte mellem login metoder
- **Fixet**: OAuth endpoints med `/connect/` path
- **Fixet**: Tilføjet `country_iso_code` parameter til OAuth
- **Fjernet**: Legacy `loadCurrentPlayer()` metode
- **Fjernet**: PlayerService dependency fra MatchSetupProvider

### 🚀 Deployment
- **Forbedret**: GitHub Actions workflow kommentar
- **Fixet**: CORS proxy for production (corsproxy.io)
- **Fixet**: Token security via privat GitHub Gist

### 🐛 Bug Fixes
- Fixet: Build errors i GitHub Actions
- Fixet: Code verifier storage issues på web
- Fixet: Union ID validation regex (1-3 cifre, dash, 1-6 cifre)
- Fixet: Player info card error handling
- Fixet: Gender parsing fra GolfBox API

## [1.0.0] - 2025-12-04

### Initial Release (MVP)
- ✅ DGU API integration (klubber, baner, tees)
- ✅ Playing handicap beregning (dansk WHS)
- ✅ Stroke allocation algoritme
- ✅ To scorecard varianter (Tæller +/- og Keypad)
- ✅ Stableford point calculation
- ✅ Resultat screen i DGU stil
- ✅ Score markers (cirkler/bokse)
- ✅ Handicap resultat med Net Double Bogey
- ✅ Material 3 theme med DGU farver
- ✅ Mobil-optimeret layout

---

**Format:** Baseret på [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)


