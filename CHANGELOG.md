# Changelog

Alle væsentlige ændringer til dette projekt dokumenteres i denne fil.

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

