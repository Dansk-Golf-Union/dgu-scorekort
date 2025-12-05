# DGU Scorekort

Flutter Web App til danske golfspillere til at rapportere scorekort.

## Status: ✅ Version 1.1 - Med Login & Gender Filtering

**Live App:** [https://dansk-golf-union.github.io/dgu-scorekort/](https://dansk-golf-union.github.io/dgu-scorekort/)

## Overview

DGU Scorekort er en moderne web-applikation bygget med Flutter, der gør det muligt for danske golfspillere at:
- Vælge golfklub, bane og tee fra DGU Basen API
- Beregne spillehandicap efter danske WHS regler
- Indtaste scores på to måder (Tæller +/- eller Keypad)
- Se detaljeret scorekort med Stableford points
- Beregne handicap resultat (score differential)

## ✨ Implementerede Features

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

## 🛠️ Teknisk Stack

### Framework & Libraries
- **Flutter 3.38.4** (Dart SDK)
- **Provider 6.1.1** - State management
- **HTTP 1.2.0** - API kommunikation
- **Google Fonts 6.1.0** - Typography (Roboto)
- **Intl 0.19.0** - Date formatting
- **URL Launcher 6.2.2** - OAuth browser flow
- **Crypto 3.0.3** - SHA256 for PKCE
- **SharedPreferences 2.2.2** - Token storage

### Arkitektur
- **State Management**: Provider pattern (AuthProvider, MatchSetupProvider, ScorecardProvider)
- **Design System**: Material 3 med DGU farver og custom theming
- **API**: DGU Basen REST API med Basic Auth (public) og Bearer tokens (OAuth)
- **CORS**: Handled via corsproxy.io for production
- **Platform**: Web (Chrome primary target, deployed to GitHub Pages)

## 📁 Projekt Struktur

```
lib/
├── main.dart                          # Entry point & SetupRoundScreen
├── config/
│   └── auth_config.dart               # OAuth & API konfiguration
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
│   └── player_service.dart            # Player API service (OAuth & Union ID)
├── utils/
│   ├── handicap_calculator.dart       # WHS handicap beregninger
│   ├── stroke_allocator.dart          # Stroke allocation algoritme
│   └── score_helper.dart              # Golf term labels
└── screens/
    ├── login_screen.dart              # OAuth login screen
    ├── simple_login_screen.dart       # Union ID login (aktiv)
    ├── scorecard_screen.dart          # Tæller +/- scorecard
    ├── scorecard_keypad_screen.dart   # Keypad scorecard
    └── scorecard_results_screen.dart  # Resultat visning
```

## 🌐 API Integration

### GolfBox DGU Basen API

**Base URL:** `https://dgubasen.api.union.golfbox.io/info@ingeniumgolf.dk`

**Endpoints:**
- `GET /clubs` - Alle danske golfklubber (Basic Auth)
- `GET /clubs/{clubId}/courses` - Baner for klub (Basic Auth)
- `GET /clubs/golfer?unionid={unionId}` - Spiller info (Basic Auth)
- `GET /clubs/golfer` - Spiller info fra OAuth token (Bearer)

**Authentication:**
- **Public endpoints**: Basic Auth via token fra GitHub Gist (sikkerhed)
- **Player endpoints**: Bearer token fra OAuth eller Basic Auth
- **CORS**: Handled via `https://corsproxy.io/?` proxy for production

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

## 📋 Feature Status

### ✅ Completed (v1.1)
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

### 🔄 In Progress
- [ ] OAuth redirect URI configuration (venter på setup)

### 📅 Future Enhancements
- [ ] Gem scorekort lokalt (Local Storage/IndexedDB)
- [ ] Historik over tidligere runder
- [ ] Export til PDF/print
- [ ] Multiple spillere (flightmode)
- [ ] Integration med DGU for at sende scores
- [ ] Statistik over tid (gennemsnit, trends)
- [ ] Dark mode
- [ ] Offline support med sync
- [ ] Native mobile apps (iOS/Android)
- [ ] PWA support (install som app)

## 🔧 Tekniske Detaljer

### State Management

Bruger **Provider** pattern med to hovedproviders:

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
- `Player` - Spiller med navn og HCP (mock)
- `Scorecard` - Aktiv runde med scores og beregninger
- `HoleScore` - Score for enkelt hul med points og netto

### Performance
- Lazy loading af courses (kun når klub vælges)
- Filtering og grouping i memory (ikke API)
- Hot reload friendly architecture
- Effektiv state updates med notifyListeners

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
- **No Persistence**: Scorekort gemmes ikke - forsvinder ved reload
- **Token Security**: Basic Auth token hentes fra privat GitHub Gist
- **CORS**: Løst via corsproxy.io for production
- **Web Only**: Primært testet i Chrome web browser

### Current Limitations
- **No Score History**: Tidligere runder gemmes ikke
- **No Error Recovery**: Begrænsede retry strategier
- **Single Player**: Ingen flight/gruppe support endnu

### Future Considerations
- Aktivér OAuth login når redirect URI er konfigureret
- Tilføj persistent storage for scorekort (IndexedDB)
- Backend for token proxy (i stedet for Gist)
- Implementer proper error handling og retry logic
- Tilføj loading states og skeleton screens
- Implementer proper logging og analytics
- Tilføj unit tests og widget tests
- Performance monitoring og optimization
- Multi-player support (flights)

## 🧪 Testing

### Manual Testing Checklist
- [ ] Vælg klub → Skal vise baner
- [ ] Vælg bane → Skal vise tees
- [ ] Vælg tee → Skal beregne spillehandicap
- [ ] Start runde (Tæller) → Indtast scores → Se resultat
- [ ] Start runde (Keypad) → Indtast scores → Se resultat
- [ ] Test 9-hullers bane → Verificer handicap beregning
- [ ] Test 18-hullers bane → Verificer Ud/Ind/Total
- [ ] Verificer score markers (circles/boxes)
- [ ] Verificer handicap resultat beregning

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

## 👥 Contributing

Dette er et personligt projekt. Pull requests er velkomne!

### Development Guidelines
1. Follow Flutter/Dart style guide
2. Run `flutter analyze` before committing
3. Test både 9 og 18 hullers baner
4. Behold DGU design consistency
5. Dokumenter komplekse beregninger

## 📞 Contact

Nick Hüttel

## 📄 License

[License info hvis relevant]

---

**Bygget med ❤️ og Flutter**
