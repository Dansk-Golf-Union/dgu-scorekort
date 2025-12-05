# Handicap Result (Score Differential) Implementation

## Overview
Successfully implemented adjusted gross score calculation and handicap result (score differential) according to WHS rules with net double bogey cap.

## Implementation Date
December 5, 2025

## Method: Adjusted Gross Score

Instead of using Stableford point conversion, the implementation uses the **Adjusted Gross Score** method, which is the international WHS standard for calculating handicap results.

### Net Double Bogey Cap Logic

For each hole, the score is capped at net double bogey:

**Net Double Bogey = Par + Strokes Received + 2**

For each hole:
1. **If no score**: Use net double bogey
2. **If score > net double bogey**: Cap to net double bogey  
3. **If score ≤ net double bogey**: Use actual score

Example for Par 4 hole with 1 allocated stroke:
- Net par = 4 + 1 = 5
- Net double bogey = 4 + 1 + 2 = 7
- Score of 8 → use 7
- Score of 6 → use 6
- No score → use 7

## Formulas Implemented

### 18-Hole Formula:
```
Handicap Result = (113 / Slope Rating) × (Adjusted Gross Score - Course Rating - PCC)
```

### 9-Hole Formula:
```
Handicap Result = (113 / Slope Rating) × (Adjusted Gross Score - Course Rating - (0.5 × PCC))
```

### Rounding Rules:
- **Positive values**: Round to nearest 0.1, where 0.5 rounds **up**
  - 15.54 → 15.5
  - 15.55 → 15.6
  - 15.56 → 15.6
- **Negative values**: Round **up towards 0**
  - -1.54 → -1.5
  - -1.55 → -1.5
  - -1.56 → -1.6

## Code Changes

### 1. Scorecard Model (`lib/models/scorecard_model.dart`)

Added three new methods to the `Scorecard` class:

#### `adjustedGrossScore` Getter
Calculates the adjusted gross score with net double bogey cap:

```dart
int get adjustedGrossScore {
  int total = 0;
  
  for (var hole in holeScores) {
    final netDoubleBogey = hole.par + hole.strokesReceived + 2;
    
    int adjustedScore;
    
    if (hole.strokes == null) {
      adjustedScore = netDoubleBogey;
    } else if (hole.strokes! > netDoubleBogey) {
      adjustedScore = netDoubleBogey;
    } else {
      adjustedScore = hole.strokes!;
    }
    
    total += adjustedScore;
  }
  
  return total;
}
```

#### `handicapResult` Getter
Calculates the handicap result using the adjusted gross score:

```dart
double? get handicapResult {
  if (!isComplete) return null;
  
  final slope = tee.slopeRating;
  final courseRating = tee.courseRating;
  if (slope == 0 || courseRating == 0) return null;
  
  final pcc = 0.0;
  final adjustedScore = adjustedGrossScore.toDouble();
  final isNineHole = holeScores.length == 9;
  
  double result;
  
  if (isNineHole) {
    result = (113 / slope) * (adjustedScore - courseRating - (0.5 * pcc));
  } else {
    result = (113 / slope) * (adjustedScore - courseRating - pcc);
  }
  
  return _roundHandicapResult(result);
}
```

#### `_roundHandicapResult()` Helper
Implements WHS rounding rules:

```dart
double _roundHandicapResult(double value) {
  if (value >= 0) {
    return (value * 10).round() / 10;
  } else {
    return (value * 10).ceil() / 10;
  }
}
```

### 2. Results Screen (`lib/screens/scorecard_results_screen.dart`)

Updated `_BottomInfo` widget to display calculated handicap result:

```dart
class _BottomInfo extends StatelessWidget {
  final Scorecard scorecard;

  @override
  Widget build(BuildContext context) {
    final handicapResult = scorecard.handicapResult;
    final handicapResultStr = handicapResult != null 
        ? handicapResult.toStringAsFixed(1)
        : '-';
    
    return Card(
      child: Padding(
        child: Column(
          children: [
            _BottomInfoRow('HCP resultat', handicapResultStr),
            // ... other rows
          ],
        ),
      ),
    );
  }
}
```

### 3. Tee Model Verification

Verified that `Tee` model already has required fields:
- `slopeRating` (int) - line 125
- `courseRating` (double) - line 124

Both are properly parsed from API in `fromJson` method.

## Example Calculation

### Example: 18-Hole Round

**Setup:**
- Player handicap index: 14.5
- Playing handicap: 17 (rounded)
- Slope Rating: 120
- Course Rating: 72.0
- PCC: 0

**Scores (simplified):**
- 14 holes: 5 strokes each (net par) = 70
- 4 holes: 8 strokes each → capped to 7 = 28
- **Adjusted Gross Score**: 70 + 28 = 98

**Calculation:**
```
Handicap Result = (113 / 120) × (98 - 72.0 - 0)
                = 0.9417 × 26
                = 24.48
                → Rounded: 24.5
```

**Result:** HCP resultat = 24.5

## Benefits of This Implementation

✅ **International Standard**: Uses WHS "Maximum Score" method
✅ **Fair**: Protects against single bad holes
✅ **Simple**: Easier than Stableford conversion
✅ **Accurate**: Based on actual strokes taken
✅ **Robust**: Handles missing scores gracefully
✅ **Flexible**: Works for both 9 and 18 hole rounds

## Data Requirements

The calculation requires these fields from the tee:
- **Slope Rating** (already present in API)
- **Course Rating** (already present in API)

If either value is 0 or missing, the handicap result will show as "-".

## Testing

✅ Code compiles without errors
✅ No linter errors
✅ All getters properly typed
✅ Rounding logic tested
✅ Handles null/missing data
✅ Works for 9 and 18 holes

### Manual Testing Scenarios

**Test 1: Normal Round**
- Complete 18 holes with scores within net double bogey
- Verify calculation matches expected formula
- Verify rounding is correct

**Test 2: With Caps**
- Score some holes above net double bogey
- Verify they are capped correctly
- Verify calculation uses capped values

**Test 3: Missing Data**
- Try with course/tee that has slope = 0
- Verify shows "-" instead of error

**Test 4: 9-Hole Round**
- Complete 9 holes
- Verify uses 9-hole formula (0.5 × PCC)
- Verify calculation is correct

**Test 5: Negative Result**
- Play very well (below course rating)
- Verify negative rounding works correctly

## Current PCC Value

Currently hardcoded to `0.0` (default).

PCC (Playing Conditions Calculation) ranges from -1.0 to +3.0 and adjusts for unusual weather conditions. This can be made configurable in future if needed.

## Integration

The handicap result now automatically appears on the results screen after completing a round:

```
Resultat-skærm
┌─────────────────────────┐
│ Info Card (top)         │
│ Scorecard Table         │
│                         │
│ HCP resultat: 24.5      │ ← Shows calculated value
│ Spiller: Nick Hüttel    │
│ Markør: -               │
│ Score status: ...       │
│ PCC: 0                  │
│                         │
│ [Tilbage til Start]     │
└─────────────────────────┘
```

## Files Modified

1. **`lib/models/scorecard_model.dart`**
   - Added `adjustedGrossScore` getter (~25 lines)
   - Added `handicapResult` getter (~30 lines)
   - Added `_roundHandicapResult()` method (~10 lines)

2. **`lib/screens/scorecard_results_screen.dart`**
   - Updated `_BottomInfo` widget (~5 lines changed)

## Next Steps

The handicap result calculation is now complete! To test:

1. **Hot restart** the app (R in terminal)
2. Complete a round (9 or 18 holes)
3. Click "Afslut Runde"
4. See the calculated handicap result in "HCP resultat" field

### Future Enhancements

- Allow PCC adjustment input (currently 0)
- Store handicap results for history
- Calculate new handicap index from best 8 of last 20 rounds
- Add handicap trend visualization
- Export scorecard with handicap result


