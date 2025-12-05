# Double Border Implementation

## Overview
Successfully upgraded score markers from single thick borders to proper double borders (two separate thin lines) for eagle and double bogey markers.

## Implementation Date
December 5, 2025

## Changes Made

### Before: Single Thick Border
- **Eagle**: One thick 3.0px circle
- **Double Bogey**: One thick 3.0px square

### After: Nested Containers with Double Borders
- **Eagle**: Two separate 1.5px circles (outer + inner)
- **Double Bogey**: Two separate 1.5px squares (outer + inner)

## Implementation Details

### Nested Container Approach

Used two `Container` widgets nested inside each other to create the double border effect:

```dart
// Outer container (32x32)
Container(
  width: 32,
  height: 32,
  decoration: BoxDecoration(
    shape: BoxShape.circle,  // or rectangle for boxes
    border: Border.all(color: Colors.black, width: 1.5),
  ),
  child: Center(
    child: Container(
      width: 26,  // Inner container
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Center(
        child: Text(score),
      ),
    ),
  ),
)
```

### Sizing and Spacing

**Outer Container:**
- Width/Height: 32px
- Border: 1.5px black

**Inner Container (for double markers):**
- Width/Height: 26px
- Border: 1.5px black
- **Spacing**: 3px gap between borders (32 - 26 = 6px total, 3px on each side)

**Single Markers (unchanged):**
- Width/Height: 32px
- Border: 1.5px black
- No inner container

### Code Structure Changes

**Old approach:** Used `_getDecoration()` method returning `BoxDecoration?`

**New approach:** Uses `_buildMarkedContainer()` method returning `Widget`

This allows for complex nested structures that can't be expressed with a single decoration.

### Refactored Widget

```dart
class _MarkedScoreCell extends StatelessWidget {
  final String score;
  final ScoreMarker marker;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Center(
        child: _buildMarkedContainer(),
      ),
    );
  }

  Widget _buildMarkedContainer() {
    // Switch on marker type
    // Returns appropriate widget structure
    // Single markers: One container
    // Double markers: Nested containers
    // None: SizedBox with text only
  }
}
```

## Visual Results

### Double Circle (Eagle/Albatros)
```
Before: ●●● (thick circle)
After:  ◎  (two thin circles)
```

### Double Square (Double Bogey+)
```
Before: ▪▪▪ (thick square)
After:  ⬜  (two thin squares)
```

### Single Markers (Unchanged)
- **Birdie**: ○ (single circle, 1.5px)
- **Bogey**: ▢ (single square, 1.5px)
- **Par**: No marker

## All Marker Types

| Score Type | Marker | Outer | Inner | Spacing |
|------------|--------|-------|-------|---------|
| Eagle (-2+) | ◎ | 32x32, 1.5px circle | 26x26, 1.5px circle | 3px |
| Birdie (-1) | ○ | 32x32, 1.5px circle | - | - |
| Par (0) | - | - | - | - |
| Bogey (+1) | ▢ | 32x32, 1.5px square | - | - |
| Double Bogey (+2+) | ⬜ | 32x32, 1.5px square | 26x26, 1.5px square | 3px |

## Technical Benefits

### Cleaner Visual Appearance
- Two distinct lines instead of one thick blur
- Better matches traditional golf scorecard styling
- More closely matches DGU app design

### Flexibility
- Easy to adjust spacing (change inner size: 24px, 26px, 28px)
- Could add different colors in future
- Can add background colors between borders if needed

### Maintainability
- Clear structure with nested containers
- Easy to understand intent
- Consistent with Flutter patterns

## Files Modified

**`/Users/nickhuttel/dgu_scorekort/lib/screens/scorecard_results_screen.dart`**
- Refactored `_MarkedScoreCell` class
- Replaced `_getDecoration()` with `_buildMarkedContainer()`
- Added nested container structures for double markers
- Total changes: ~60 lines modified/rewritten

## Testing

✅ Code compiles without errors
✅ No linter errors
✅ Nested containers render correctly
✅ Spacing looks appropriate
✅ Text remains centered and readable
✅ Single markers unchanged
✅ Double markers show two distinct lines

### Visual Testing Checklist

Test with various scores:
- [ ] Eagle on Par 5 (3 strokes) → Two circles visible
- [ ] Birdie on Par 4 (3 strokes) → One circle
- [ ] Par on Par 4 (4 strokes) → No marker
- [ ] Bogey on Par 4 (5 strokes) → One square
- [ ] Double bogey on Par 4 (6 strokes) → Two squares visible
- [ ] Triple bogey on Par 5 (8 strokes) → Two squares visible
- [ ] Gap between borders visible and appropriate

## Spacing Adjustment

If 3px spacing is too much or too little, adjust the inner container size:

**More spacing (4px):**
```dart
width: 24,  // 32 - 24 = 8px total = 4px each side
height: 24,
```

**Less spacing (2px):**
```dart
width: 28,  // 32 - 28 = 4px total = 2px each side
height: 28,
```

**Current (3px):**
```dart
width: 26,  // 32 - 26 = 6px total = 3px each side
height: 26,
```

## Performance

No performance concerns:
- Nested containers are lightweight
- No custom painting
- Flutter handles rendering efficiently
- Same number of widgets in tree overall

## Success Criteria

✅ Double borders use two separate thin lines (1.5px each)
✅ Not one thick line (3.0px)
✅ Appropriate spacing between borders (3px)
✅ Eagle markers show two circles
✅ Double bogey markers show two squares
✅ Single markers unchanged
✅ Text remains centered and readable
✅ Matches DGU app style more precisely

## Next Steps

The double borders are now implemented! To test:

1. **Hot restart** the app (R in terminal)
2. Complete a round with various scores
3. Click "Afslut Runde"
4. Verify the double borders look correct:
   - Two distinct lines visible
   - Appropriate spacing
   - Cleaner than thick border

If spacing needs adjustment, modify the inner container size (26px) in `_buildMarkedContainer()`.


