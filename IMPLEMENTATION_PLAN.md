# IMPLEMENTATION PLAN: DGU Scorekort App

## Nuværende Status

- [x] Opsætning af Flutter Web
- [x] API Service (Clubs & Courses)
- [x] Datamodeller (Club, Course, Tee, Hole, Player)
- [x] UI: Vælg Klub -> Bane -> Tee (Dropdowns)

## Fase 3: Spiller & Handicap ✅ FÆRDIG

Mål: Vi skal have en aktiv spiller og kunne beregne tildelte slag.

1. **Mock Auth Service** ✅
   - ✅ Oprettet `services/player_service.dart`.
   - ✅ Metode `getCurrentPlayer()` returnerer en `Player` model.
   - ✅ Hardcode data: Navn: "Nick Hüttel", Hcp: 14.5, Medlemsnr: "134-2813".

2. **Handicap Engine** ✅
   - ✅ Oprettet `utils/handicap_calculator.dart`.
   - ✅ Implementeret dansk WHS formel:
     `Spille Hcp = (HcpIndex * (Slope / 113)) + (CR - Par)`
   - ✅ Resultatet afrundes matematisk (0.5 runder op).

3. **State Management** ✅
   - ✅ Opdateret `MatchSetupProvider`.
   - ✅ Når Tee vælges -> Beregner straks `playingHandicap` for den aktive spiller.
   - ✅ Gemt resultatet i provideren.

4. **UI: Spiller Info** ✅
   - ✅ På `SetupRoundScreen`: Indsat "Player Card" mellem dropdowns og start-knap.
   - ✅ Viser: Navn, Hcp Index -> Pil -> Spillehandicap (Stort tal).
   - ✅ Viser tekst: "Du har X slag på denne bane".
   - ✅ Bonus: Knap til at vise detaljeret beregning.

## Fase 4: Scorekortet (Næste trin)

Mål: Opret det interaktive scorekort hvor spilleren kan indtaste scores.

1. **Scorecard Model**
   - Opret `models/scorecard_model.dart`.
   - Model til at holde scores for hvert hul.
   - Hold styr på: Slag, Putts, Fairway Hit, etc.

2. **Stroke Allocation**
   - Opret `utils/stroke_allocator.dart`.
   - Beregn tildelte slag pr. hul baseret på:
     - Hullets handicap-indeks (fra Hole model)
     - Spillerens spillehandicap
   - Eksempel: Spillehandicap 18 = 1 slag på alle 18 huller.

3. **Scorecard Screen**
   - Opret `screens/scorecard_screen.dart`.
   - Vis tabel med alle huller:
     - Hulnummer
     - Par
     - Tildelte slag (prikker/streger)
     - Input felt til score
   - Navigation: Tilbage til setup, Gem runde.

4. **Scorecard Provider**
   - Opret `providers/scorecard_provider.dart`.
   - Håndter indtastning af scores.
   - Beregn løbende:
     - Brutto score (faktiske slag)
     - Netto score (brutto - tildelte slag)
     - Stableford points (hvis relevant)
     - Total score (front 9, back 9, total)

5. **UI Features**
   - Input validering (score må ikke være for lav/høj).
   - Visuel feedback for over/under par.
   - Swipe eller pil-navigation mellem huller.
   - Oversigt ved rundens afslutning.

## Fase 5: Persistens & Historie (Fremtid)

- Gem afsluttede runder lokalt (SharedPreferences eller IndexedDB).
- Vis historik af tidligere runder.
- Export til PDF eller deling.

## Fase 6: Multi-Player Support (Fremtid)

- Tilføj mulighed for at spille med andre.
- Indtast flere spillere før runden starter.
- Vis scorekort for alle spillere.

## Fase 7: Live Scoring & Social (Fremtid)

- Real-time sync mellem spillere.
- Leaderboard for flight/turneringer.
- Integration med DGU for officiel scoring.

---

## NÆSTE SKRIDT

**Start Fase 4: Scorekortet**
1. Opret scorekort datamodeller
2. Implementer stroke allocation logik
3. Design scorekort UI
4. Test med forskellige handicaps og baner


