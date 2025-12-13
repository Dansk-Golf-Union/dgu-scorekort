# Match Play / Hulspil Feature - Test Guide

## Implementerede Features

### ✅ Completed Implementation

1. **MatchPlayProvider** - State management for match play
   - Player setup (Player 1 from auth, Player 2 via DGU lookup)
   - Club/Course/Tee selection with caching
   - Handicap calculation for both players
   - Stroke distribution in match play format
   - Live scoring with match status tracking
   - Early finish detection
   - Match result calculation

2. **StrokeAllocator Extensions** - Match play stroke logic
   - `calculateMatchPlayStrokes()` - Distributes only the difference
   - Strokes allocated on handicap index 1 through difference

3. **MatchPlayScreen** - Complete UI with 3 phases
   - **Setup Phase**: Opponent input, club/course/tee selection, handicap preview
   - **Stroke View Phase**: Visual display of which holes have strokes
   - **Scoring Phase**: Hole-by-hole scoring with live match status

4. **Navigation** - Route and header icon
   - New route: `/match-play`
   - Icon in AppBar leading position (left corner)
   - Icon: `Icons.people` (two players)

## Manual Testing Checklist

### Prerequisites
```bash
cd /Users/nickhuttel/dgu_scorekort
flutter run -d chrome --web-browser-flag "--disable-web-security"
```

### Test 1: Basic Setup Flow (18-huller)
- [ ] Log ind med dit DGU-nummer
- [ ] Klik på hulspil-ikonet (to personer) i venstre hjørne
- [ ] Indtast modstanders DGU-nummer (fx 72-4197)
- [ ] Klik "Hent modstander"
- [ ] Verificer modstander info vises (navn, handicap, klub)
- [ ] Vælg en klub (fx "Aalborg Golf Klub")
- [ ] Vælg en 18-hullers bane
- [ ] Vælg et tee
- [ ] Verificer begge spilleres spillehandicap vises
- [ ] Verificer forskel beregnes korrekt
- [ ] Verificer hvem der får slag vises
- [ ] Klik "Se Slag Fordeling"

**Forventet resultat:**
- Handicap beregning skal være korrekt ifølge WHS regler
- Forskel = |Player1Hcp - Player2Hcp|
- Spilleren med højest handicap får slag

### Test 2: Stroke Distribution View
- [ ] Fra stroke view: Verificer antal huller med slag matcher forskellen
- [ ] Verificer slag er på de sværeste huller (laveste index)
- [ ] Hvis forskel er 8: Huller med index 1-8 skal have ⭐
- [ ] Hvis forskel er 0: Ingen huller skal have slag
- [ ] Klik "Start Match"

**Forventet resultat:**
- Strokes fordeles kun på index 1 til difference
- Grønne highlights på huller med slag
- Korrekt antal slag vist

### Test 3: Live Scoring - Normal Match
- [ ] Start scoring phase
- [ ] Hul 1: Klik på "Spiller 1"
- [ ] Verificer match status: "Spiller 1: 1 op"
- [ ] Hul 2: Klik på "Delt"
- [ ] Verificer match status forbliver: "Spiller 1: 1 op"
- [ ] Hul 3: Klik på "Spiller 2"
- [ ] Verificer match status: "Match lige"
- [ ] Continue gennem flere huller
- [ ] Verificer progress bar opdateres
- [ ] Verificer "Hul X af 18" vises korrekt

**Forventet resultat:**
- Match status opdateres korrekt efter hvert hul
- Progress bar viser fremskridt
- Knapper virker som forventet

### Test 4: Early Finish Detection
Setup: Spiller 1 skal vinde mange huller i træk

- [ ] Lad Spiller 1 vinde hul 1-13 i træk
- [ ] Efter hul 13: Status skal være "Spiller 1: 13 op"
- [ ] Klik næste hul (14): Match skal afsluttes automatisk
- [ ] Verificer resultat: "13/5" (13 op med 5 huller tilbage)

**Forventet resultat:**
- Match slutter når lead > huller tilbage
- Korrekt format: "X/Y"

**Matematisk test:**
- Efter hul 16: Hvis 3 op → Match slut (3/2)
- Efter hul 17: Hvis 2 op → Match slut (2/1)
- Efter hul 17: Hvis 1 op → Må spille hul 18

### Test 5: Match til Sidste Hul
- [ ] Hold matchen "lige" gennem alle 18 huller
- [ ] På hul 18: Lad Spiller 1 vinde
- [ ] Verificer resultat: "1 hul" (IKKE "1/0")

**Forventet resultat:**
- Match der afgøres på sidste hul vises som "1 hul"
- Ikke som fraction format

### Test 6: Delt Match
- [ ] Hold matchen "lige" gennem alle 18 huller
- [ ] På hul 18: Klik "Delt"
- [ ] Verificer resultat: "Match delt"

**Forventet resultat:**
- Delt match vises korrekt
- Ingen vinder

### Test 7: 9-Hullers Bane
- [ ] Vælg en 9-hullers bane
- [ ] Verificer spillehandicap beregnes som (HCP/2) afrundet til 1 decimal
- [ ] Verificer stroke distribution kun går til index 9
- [ ] Spil en match gennem alle 9 huller
- [ ] Verificer early finish virker på 9-hullers

**Forventet resultat:**
- 9-hullers handicap: (14.5 / 2) = 7.25 → 7.3
- Max 9 strokes kan fordeles
- Early finish: Efter hul 6, hvis 4 op → match slut (4/3)

### Test 8: Lige Handicaps
- [ ] Find to spillere med (næsten) samme handicap
- [ ] Verificer spillehandicap er ens eller forskel = 0
- [ ] Verificer besked: "Ingen får slag - lige handicap"
- [ ] Spil match uden strokes

**Forventet resultat:**
- Ingen strokes fordeles
- Match spilles "straight up"

### Test 9: Stor Handicap Forskel (20+)
- [ ] Find spillere med 20+ slag forskel
- [ ] Verificer stroke distribution
- [ ] På 18-hullers: Alle 18 huller får 1 slag + 2 huller får ekstra slag
- [ ] Verificer korrekt visning i stroke view

**Forventet resultat:**
- Forskel 20: Alle 18 huller + 2 ekstra på index 1-2
- Forskel 25: Alle 18 huller + 7 ekstra på index 1-7
- Correct distribution logic

### Test 10: Undo Funktionalitet
- [ ] Spil 3 huller
- [ ] Klik "Fortryd"
- [ ] Verificer går tilbage til hul 2
- [ ] Verificer match status opdateres korrekt
- [ ] På hul 1: "Fortryd" skal være disabled

**Forventet resultat:**
- Undo virker korrekt
- Match status reverses
- Første hul kan ikke fortrydes

### Test 11: Afslut Match Early
- [ ] Start en match
- [ ] Midt i matchen: Klik "Afslut"
- [ ] Klik "Afslut" i dialog
- [ ] Verificer går tilbage til setup phase

**Forventet resultat:**
- Dialog vises
- Match afbrydes
- Data nulstilles

### Test 12: Tee-Skift
- [ ] Setup en match med et tee
- [ ] Noter spillehandicaps
- [ ] Skift til et andet tee (før start scoring)
- [ ] Verificer handicaps opdateres
- [ ] Verificer stroke distribution opdateres

**Forventet resultat:**
- Handicaps genberegnes automatisk
- Stroke distribution opdateres

### Test 13: Ugyldigt DGU-Nummer
- [ ] Indtast et ugyldigt DGU-nummer (fx "00-0000")
- [ ] Klik "Hent modstander"
- [ ] Verificer fejlbesked vises
- [ ] Prøv et nyt nummer

**Forventet resultat:**
- Fejlbesked: "Kunne ikke hente spiller: ..."
- Kan prøve igen

### Test 14: Navigation
- [ ] Fra hovedside: Klik hulspil-ikon
- [ ] Fra match play: Klik tilbage-pil i AppBar
- [ ] Verificer går tilbage til hovedside
- [ ] Verificer match data nulstilles

**Forventet resultat:**
- Navigation virker korrekt
- Back button tømmer match state

### Test 15: Match Finished Screen
- [ ] Spil en match til ende
- [ ] Verificer "Match Afsluttet" screen vises
- [ ] Verificer vinder navn vises
- [ ] Verificer resultat vises korrekt
- [ ] Klik "Ny Match"
- [ ] Verificer går tilbage til setup
- [ ] Klik "Tilbage til Hovedside"

**Forventet resultat:**
- Finish screen viser korrekt info
- Både "Ny Match" og "Tilbage" virker

## Edge Cases at Verificere

### Handicap Beregning
- [ ] Negativ handicap spiller (scratch eller bedre)
- [ ] Meget høj handicap (54+)
- [ ] 9-hullers afrunding edge cases (0.45 → 0.5, 0.44 → 0.4)

### Stroke Distribution
- [ ] Forskel 1: Kun index 1 hul får slag
- [ ] Forskel 18: Alle 18 huller får slag
- [ ] Forskel 19+: Nogle huller får 2 slag (ikke supporteret i current impl)

### Match Status
- [ ] Fra 5 op til 3 op (spiller 2 vinder 2)
- [ ] Fra 3 ned til 1 ned (spiller 1 vinder 2)
- [ ] Skift mellem lead multiple gange

## Performance Tests

- [ ] Load clubs: Skal være instant med cache (<0.2s)
- [ ] Load courses: Skal være hurtig (~0.2-0.5s)
- [ ] Opponent lookup: API call, kan tage 1-2s
- [ ] Handicap beregning: Instant
- [ ] UI opdateringer: Smooth, ingen lag

## Browser Compatibility

Test i:
- [ ] Chrome (primary)
- [ ] Safari
- [ ] Firefox
- [ ] Mobile browser

## Rapporter Bugs

Ved fund af bugs, noter:
1. Trin for at reproducere
2. Forventet vs faktisk resultat
3. Browser og device
4. Console errors (F12 → Console)

## Kendte Begrænsninger

1. **Ingen persistens**: Match data gemmes ikke - hvis man lukker siden, mistes data
2. **Ingen 2+ strokes per hole**: Hvis forskel > 18, supporteres ikke multiple strokes per hole
3. **Ingen match historie**: Tidligere matches gemmes ikke
4. **Ingen push notifications**: Match status sendes ikke mellem spillere

## Succeskriterie

✅ Alle 15 test cases passed
✅ Ingen console errors
✅ Handicap beregninger er korrekte
✅ Match status opdateres korrekt
✅ Early finish detection virker
✅ UI er responsivt og brugervenligt

