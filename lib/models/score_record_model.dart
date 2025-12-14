import 'package:intl/intl.dart';

/// Model for a WHS score record from Statistik API
/// 
/// Represents a single round with handicap information.
/// Used for score history, handicap trends, and activity feed.
class ScoreRecord {
  final String courseName;
  final int totalPoints;
  final int totalStrokes;
  final bool isQualifying;
  final DateTime roundDate;
  final int holesPlayed;
  final double handicapBefore; // Player's handicap BEFORE this round
  final double? scoreDifferential; // Score differential (SGD)
  final int? teePar;
  final double? teeRating;
  final int? teeSlope;
  
  ScoreRecord({
    required this.courseName,
    required this.totalPoints,
    required this.totalStrokes,
    required this.isQualifying,
    required this.roundDate,
    required this.holesPlayed,
    required this.handicapBefore,
    this.scoreDifferential,
    this.teePar,
    this.teeRating,
    this.teeSlope,
  });
  
  /// Parse from WHS API JSON response
  /// 
  /// Sample response:
  /// ```json
  /// {
  ///   "HCP": "139000",
  ///   "Result": {
  ///     "IsQualifying": true,
  ///     "SGD": "246000",
  ///     "TotalPoints": 23,
  ///     "TotalStrokes": 95
  ///   },
  ///   "Round": {
  ///     "StartTime": "20240724T110000",
  ///     "HolesPlayed": 18
  ///   },
  ///   "Course": {
  ///     "Name": "Nordvestjysk Golfklub 18 huller",
  ///     "TeePar": 72,
  ///     "TeeRating": 725000,
  ///     "TeeSlope": 129
  ///   }
  /// }
  /// ```
  factory ScoreRecord.fromJson(Map<String, dynamic> json) {
    // Parse handicap (format: "139000" = 13.9)
    final hcpStr = json['HCP'] as String? ?? '0';
    final hcpInt = int.tryParse(hcpStr) ?? 0;
    final handicap = hcpInt / 10000.0;
    
    // Parse result (web-safe: handle Map<Object?, Object?> from dart2js)
    final resultRaw = json['Result'];
    final result = resultRaw is Map<String, dynamic> 
        ? resultRaw 
        : (resultRaw != null ? Map<String, dynamic>.from(resultRaw as Map) : <String, dynamic>{});
    
    final isQualifying = result['IsQualifying'] as bool? ?? false;
    
    // Web-safe int parsing (dart2js might send as double)
    final totalPoints = _safeParseInt(result['TotalPoints']);
    final totalStrokes = _safeParseInt(result['TotalStrokes']);
    
    // Parse score differential (format: "246000" = 24.6)
    final sgdStr = result['SGD'] as String?;
    double? scoreDiff;
    if (sgdStr != null) {
      final sgdInt = int.tryParse(sgdStr);
      if (sgdInt != null) {
        scoreDiff = sgdInt / 1000.0;
      }
    }
    
    // Parse round info (web-safe)
    final roundRaw = json['Round'];
    final round = roundRaw is Map<String, dynamic> 
        ? roundRaw 
        : (roundRaw != null ? Map<String, dynamic>.from(roundRaw as Map) : <String, dynamic>{});
    
    final startTimeStr = round['StartTime'] as String? ?? '';
    final roundDate = _parseApiDate(startTimeStr);
    final holesPlayed = _safeParseInt(round['HolesPlayed']) ?? 18;
    
    // Parse course info (web-safe)
    final courseRaw = json['Course'];
    final course = courseRaw is Map<String, dynamic> 
        ? courseRaw 
        : (courseRaw != null ? Map<String, dynamic>.from(courseRaw as Map) : <String, dynamic>{});
    
    final courseName = course['Name'] as String? ?? 'Ukendt bane';
    final teePar = _safeParseInt(course['TeePar']);
    
    // Parse tee rating (format: "725000" = 72.5)
    final teeRatingStr = course['TeeRating'];
    double? teeRating;
    if (teeRatingStr != null) {
      if (teeRatingStr is String) {
        final ratingInt = int.tryParse(teeRatingStr);
        if (ratingInt != null) {
          teeRating = ratingInt / 10000.0;
        }
      } else if (teeRatingStr is int) {
        teeRating = teeRatingStr / 10000.0;
      }
    }
    
    final teeSlope = _safeParseInt(course['TeeSlope']);
    
    return ScoreRecord(
      courseName: courseName,
      totalPoints: totalPoints ?? 0,
      totalStrokes: totalStrokes ?? 0,
      isQualifying: isQualifying,
      roundDate: roundDate,
      holesPlayed: holesPlayed,
      handicapBefore: handicap,
      scoreDifferential: scoreDiff,
      teePar: teePar,
      teeRating: teeRating,
      teeSlope: teeSlope,
    );
  }
  
  /// Web-safe int parser (handles dart2js type variations)
  /// 
  /// dart2js might send integers as doubles or other numeric types.
  /// This ensures we get an int or null.
  static int? _safeParseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
  
  /// Parse API date format ("20240724T110000") to DateTime
  static DateTime _parseApiDate(String dateStr) {
    if (dateStr.isEmpty) {
      return DateTime.now();
    }
    
    try {
      // Format: "20240724T110000"
      // Parse: YYYYMMDDTHHMMSS
      final year = int.parse(dateStr.substring(0, 4));
      final month = int.parse(dateStr.substring(4, 6));
      final day = int.parse(dateStr.substring(6, 8));
      
      int hour = 0, minute = 0, second = 0;
      if (dateStr.length >= 15) {
        hour = int.parse(dateStr.substring(9, 11));
        minute = int.parse(dateStr.substring(11, 13));
        second = int.parse(dateStr.substring(13, 15));
      }
      
      return DateTime(year, month, day, hour, minute, second);
    } catch (e) {
      // Fallback to now if parsing fails
      return DateTime.now();
    }
  }
  
  /// Format date for display (Danish format: "10. Dec 2024")
  String get formattedDate {
    final formatter = DateFormat('d. MMM yyyy');
    return formatter.format(roundDate);
  }
  
  /// Format date for display (short: "10. Dec")
  String get formattedDateShort {
    final formatter = DateFormat('d. MMM');
    return formatter.format(roundDate);
  }
  
  /// Get handicap display string (e.g., "HCP 13.9")
  String get handicapDisplay {
    return 'HCP ${handicapBefore.toStringAsFixed(1)}';
  }
  
  /// Get qualifying status emoji
  String get qualifyingEmoji {
    return isQualifying ? '✅' : '❌';
  }
  
  /// Get qualifying status text
  String get qualifyingText {
    return isQualifying ? 'Tæller' : 'Tæller ikke';
  }
  
  @override
  String toString() {
    return 'ScoreRecord(course: $courseName, points: $totalPoints, date: $formattedDate, hcp: ${handicapBefore.toStringAsFixed(1)})';
  }
}

