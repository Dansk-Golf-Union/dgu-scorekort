# DGU Scorekort - Testing Guide

## Phase 4: Scorecard & Stroke Allocation

### Completed Implementation

✅ **All components implemented:**
1. Added `index` field to `Hole` model
2. Created `scorecard_model.dart` with HoleScore and Scorecard classes
3. Created `stroke_allocator.dart` with stroke distribution logic
4. Created `scorecard_provider.dart` for state management
5. Created `scorecard_screen.dart` with full UI
6. Integrated navigation from SetupRoundScreen
7. Added MultiProvider to main.dart
8. Fixed overflow issue in SetupRoundScreen

✅ **Unit Tests Passed:**
All 12 stroke allocation tests passed successfully, verifying:
- 18-hole courses with various handicaps (0, 9, 18, 20, 36)
- 9-hole courses with various handicaps (7, 18, 20)
- Correct stroke distribution algorithms
- Description generation

### Manual Testing Steps

#### 1. Hot Reload the App
In the terminal running Flutter, press `r` to hot reload with all changes.

#### 2. Test 18-Hole Course

**Steps:**
1. Select a club (e.g., Kokkedal Golf Klub)
2. Select an 18-hole course
3. Select a tee (e.g., Yellow Men)
4. Verify playing handicap is calculated correctly
5. Click "Start Runde"

**Expected Behavior:**
- Navigate to scorecard screen
- See "Hul 1/18" in app bar
- See total points "0p" initially
- Hole card shows:
  - Hole number and index
  - Par and strokes received (if any)
  - Score input with +/- buttons
  - Points calculation after entering score

**Test Scenarios:**
- Enter score equal to par → should show appropriate points (typically 2)
- Enter score under par → should show higher points (green display)
- Enter score over par → should show lower points (red/orange display)
- Navigate through all 18 holes using "Næste" button
- Verify stroke allocation matches handicap:
  - HCP 16 → 1 stroke on 16 holes
  - HCP 18 → 1 stroke on all holes
  - HCP 20 → 1 stroke on all + 2 extra on hardest

#### 3. Test 9-Hole Course

**Steps:**
1. Select a club with 9-hole courses
2. Select a 9-hole course
3. Verify `isNineHole` is true
4. Verify playing handicap is calculated using (hcp / 2)
5. Click "Start Runde"

**Expected Behavior:**
- Navigate to scorecard screen
- See "Hul 1/9" in app bar
- Hole cards show correct information
- Stroke allocation works correctly for 9 holes:
  - HCP 7 (from 14.5) → 1 stroke on 7 holes
  - HCP 9 → 1 stroke on all 9 holes
  - HCP 10 → 1 stroke on all + 1 extra

**Test Scenarios:**
- Complete all 9 holes
- Verify points calculation
- Verify "Afslut Runde" appears when all holes completed
- Click "Afslut Runde" → see completion dialog

#### 4. Navigation & State Tests

**Test:**
- Use PageView swipe gestures to navigate between holes
- Use "Forrige" and "Næste" buttons
- Go back to previous holes and change scores
- Verify total points update immediately
- Verify front 9 / back 9 subtotals (for 18 holes)

#### 5. Edge Cases

**Test:**
- Score = 1 (verify minimum works)
- Score = 15 (verify maximum works)
- Navigate away mid-round (currently loses state - known limitation)
- Complete all holes → "Afslut Runde" button appears
- Completion dialog shows correct summary

### Known Issues to Watch For

1. **Course data may not have hole index:**
   - If holes don't have explicit `Index` field in JSON, it defaults to hole number
   - May need to verify with actual API data

2. **Navigation state:**
   - Currently no persistence if user navigates back
   - Future enhancement: add confirmation dialog

3. **Visual overflow:**
   - Fixed with SingleChildScrollView in main.dart
   - Should now scroll properly on all screen sizes

### Success Criteria

✅ **Phase 4 is complete when:**
- [x] Stroke allocation tests pass
- [ ] Can start and complete a full 18-hole round
- [ ] Can start and complete a full 9-hole round
- [ ] Points calculate correctly using Stableford rules
- [ ] Stroke allocation matches playing handicap
- [ ] UI is responsive and intuitive
- [ ] Navigation works smoothly
- [ ] Completion dialog shows correct summary

### Next Steps (Future Phases)

**Phase 5: Persistence & History**
- Save completed rounds to local storage
- View round history
- Statistics and trends

**Phase 6: Multi-Player**
- Add multiple players to a round
- Individual scorecards
- Leaderboard view

**Phase 7: Live Scoring**
- Sync scores to cloud
- Share live scores with friends
- Real-time leaderboards


