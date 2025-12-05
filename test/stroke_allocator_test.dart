import 'package:flutter_test/flutter_test.dart';
import 'package:dgu_scorekort/utils/stroke_allocator.dart';
import 'package:dgu_scorekort/models/course_model.dart';

void main() {
  group('StrokeAllocator Tests', () {
    // Create mock holes for 18-hole course
    List<Hole> create18Holes() {
      return List.generate(18, (i) {
        return Hole(
          id: 'hole-${i + 1}',
          number: i + 1,
          par: 4,
          length: 400,
          index: ((i * 7) % 18) + 1, // Create varied indices
        );
      });
    }

    // Create mock holes for 9-hole course
    List<Hole> create9Holes() {
      return List.generate(9, (i) {
        return Hole(
          id: 'hole-${i + 1}',
          number: i + 1,
          par: 4,
          length: 400,
          index: ((i * 3) % 9) + 1, // Create varied indices
        );
      });
    }

    test('18-hole course, HCP 18 - 1 stroke per hole', () {
      final holes = create18Holes();
      final strokes = StrokeAllocator.calculateStrokesPerHole(18, holes, false);

      // Should give 1 stroke to all 18 holes
      expect(strokes.length, 18);
      for (var i = 1; i <= 18; i++) {
        expect(strokes[i], 1, reason: 'Hole $i should get 1 stroke');
      }
    });

    test('18-hole course, HCP 9 - 1 stroke on 9 hardest holes', () {
      final holes = create18Holes();
      final strokes = StrokeAllocator.calculateStrokesPerHole(9, holes, false);

      // Should give strokes to the 9 hardest holes (index 1-9)
      final totalStrokes = strokes.values.fold<int>(0, (sum, s) => sum + s);
      expect(totalStrokes, 9);

      // Find holes with index 1-9
      final holesWithStrokes = strokes.entries.where((e) => e.value > 0).length;
      expect(holesWithStrokes, 9);
    });

    test('18-hole course, HCP 0 - no strokes', () {
      final holes = create18Holes();
      final strokes = StrokeAllocator.calculateStrokesPerHole(0, holes, false);

      final totalStrokes = strokes.values.fold<int>(0, (sum, s) => sum + s);
      expect(totalStrokes, 0);
    });

    test('18-hole course, HCP 36 - 2 strokes per hole', () {
      final holes = create18Holes();
      final strokes = StrokeAllocator.calculateStrokesPerHole(36, holes, false);

      // Should give 2 strokes to all 18 holes
      for (var i = 1; i <= 18; i++) {
        expect(strokes[i], 2, reason: 'Hole $i should get 2 strokes');
      }
    });

    test('18-hole course, HCP 20 - 1 stroke on all + 2 extra', () {
      final holes = create18Holes();
      final strokes = StrokeAllocator.calculateStrokesPerHole(20, holes, false);

      final totalStrokes = strokes.values.fold<int>(0, (sum, s) => sum + s);
      expect(totalStrokes, 20);

      // All holes should get at least 1
      for (var i = 1; i <= 18; i++) {
        expect(strokes[i]! >= 1, true, reason: 'Hole $i should get at least 1 stroke');
      }

      // 2 holes should get 2 strokes
      final holesWithTwoStrokes = strokes.values.where((s) => s == 2).length;
      expect(holesWithTwoStrokes, 2);
    });

    test('9-hole course, HCP 7 - 7 strokes distributed', () {
      final holes = create9Holes();
      final strokes = StrokeAllocator.calculateStrokesPerHole(7, holes, true);

      final totalStrokes = strokes.values.fold<int>(0, (sum, s) => sum + s);
      expect(totalStrokes, 7);

      // 7 holes should get 1 stroke each
      final holesWithStrokes = strokes.values.where((s) => s > 0).length;
      expect(holesWithStrokes, 7);
    });

    test('9-hole course, HCP 18 - 2 strokes per hole', () {
      final holes = create9Holes();
      final strokes = StrokeAllocator.calculateStrokesPerHole(18, holes, true);

      final totalStrokes = strokes.values.fold<int>(0, (sum, s) => sum + s);
      expect(totalStrokes, 18);

      // All 9 holes should get 2 strokes
      for (var i = 1; i <= 9; i++) {
        expect(strokes[i], 2, reason: 'Hole $i should get 2 strokes');
      }
    });

    test('9-hole course, HCP 20 - 2 strokes on all + 2 extra', () {
      final holes = create9Holes();
      final strokes = StrokeAllocator.calculateStrokesPerHole(20, holes, true);

      final totalStrokes = strokes.values.fold<int>(0, (sum, s) => sum + s);
      expect(totalStrokes, 20);

      // All holes should get at least 2
      for (var i = 1; i <= 9; i++) {
        expect(strokes[i]! >= 2, true, reason: 'Hole $i should get at least 2 strokes');
      }

      // 2 holes should get 3 strokes (2 full rounds + 2 remainder)
      final holesWithThreeStrokes = strokes.values.where((s) => s == 3).length;
      expect(holesWithThreeStrokes, 2);
    });

    test('Description for 18-hole, HCP 16', () {
      final description = StrokeAllocator.getStrokeAllocationDescription(16, false);
      expect(description, '16 slag på de 16 sværeste huller');
    });

    test('Description for 18-hole, HCP 18', () {
      final description = StrokeAllocator.getStrokeAllocationDescription(18, false);
      expect(description, '1 slag på alle 18 huller');
    });

    test('Description for 18-hole, HCP 20', () {
      final description = StrokeAllocator.getStrokeAllocationDescription(20, false);
      expect(description, '1 slag på alle huller + 2 ekstra på de sværeste');
    });

    test('Description for 9-hole, HCP 7', () {
      final description = StrokeAllocator.getStrokeAllocationDescription(7, true);
      expect(description, '7 slag på de 7 sværeste huller');
    });
  });
}


