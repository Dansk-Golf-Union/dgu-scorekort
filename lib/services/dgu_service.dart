import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/course_model.dart';
import '../models/club_model.dart';

class DguService {
  static const String baseUrl =
      "https://corsproxy.io/?https://dgubasen.api.union.golfbox.io/info@ingeniumgolf.dk";

  // Token is fetched from external gist to keep it out of GitHub
  static const String _tokenUrl =
      'https://gist.githubusercontent.com/nhuttel/a907dd7d60bf417b584333dfd5fff74a/raw/9b743740c4a7476c79d6a03c726e0d32b4034ec6/dgu_token.txt';

  // Cache token in memory to avoid fetching on every request
  static String? _cachedToken;

  /// Fetches the authentication token from external source
  /// Caches the token to avoid repeated fetches
  Future<String> _getAuthToken() async {
    if (_cachedToken != null) {
      return _cachedToken!;
    }

    try {
      final response = await http.get(Uri.parse(_tokenUrl));
      if (response.statusCode == 200) {
        _cachedToken = response.body.trim();
        return _cachedToken!;
      } else {
        throw Exception('Failed to load auth token: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching auth token: $e');
    }
  }

  /// Fetches all clubs from DGU
  ///
  /// Returns a list of Club objects sorted alphabetically by name
  Future<List<Club>> fetchClubs() async {
    final url = Uri.parse('$baseUrl/clubs');
    final authToken = await _getAuthToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': authToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final clubs = jsonData.map((json) => Club.fromJson(json)).toList();

        // Sort alphabetically by name
        clubs.sort((a, b) => a.name.compareTo(b.name));

        return clubs;
      } else {
        throw Exception('Failed to load clubs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching clubs: $e');
    }
  }

  /// Fetches clubs and returns RAW JSON data (for caching)
  Future<List<Map<String, dynamic>>> fetchClubsRaw() async {
    final url = Uri.parse('$baseUrl/clubs');
    final authToken = await _getAuthToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': authToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load clubs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching clubs: $e');
    }
  }

  /// Fetches courses for a given club ID and returns RAW JSON data
  Future<List<Map<String, dynamic>>> fetchCoursesRaw(String clubId) async {
    final url = Uri.parse(
      '$baseUrl/clubs/$clubId/courses?active=1&sort=ActivationDate:1&sortTee=TotalLength:1&changedsince=20250301T000000',
    );
    final authToken = await _getAuthToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': authToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching courses: $e');
    }
  }

  /// Fetches courses for a given club ID
  ///
  /// [clubId] - The club ID (e.g., "5DC79960-5813-4E6D-BA83-82F981F61E23")
  /// Returns a list of GolfCourse objects
  Future<List<GolfCourse>> fetchCourses(String clubId) async {
    final url = Uri.parse(
      '$baseUrl/clubs/$clubId/courses?active=1&sort=ActivationDate:1&sortTee=TotalLength:1&changedsince=20250301T000000',
    );
    final authToken = await _getAuthToken();

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': authToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final allCourses = jsonData
            .map((json) => GolfCourse.fromJson(json))
            .toList();

        // 1. Filtrer: Behold kun aktive baner
        final activeCourses = allCourses
            .where((course) => course.isActive)
            .toList();

        // 2. Filtrer dato: Behold kun baner hvor ActivationDate <= DateTime.now()
        // VIGTIGT: Hvis alle baner ligger i fremtiden pga test-data, udkommenter nedenstående linje
        final currentDate = DateTime.now();
        final coursesBeforeNow = activeCourses
            .where(
              (course) =>
                  course.activationDate.isBefore(currentDate) ||
                  course.activationDate.isAtSameMomentAs(currentDate),
            )
            .toList();
        // Hvis alle baner ligger i fremtiden, brug i stedet: final coursesBeforeNow = activeCourses;

        // 3. Gruppering: Behold kun den nyeste version for hvert TemplateID
        final Map<String, GolfCourse> latestCoursesByTemplate = {};
        final List<GolfCourse> coursesWithoutTemplate = [];

        for (final course in coursesBeforeNow) {
          if (course.templateID.isEmpty) {
            // Hvis TemplateID mangler, behold banen (kan være unik)
            coursesWithoutTemplate.add(course);
          } else {
            // Gruppér efter TemplateID og behold den nyeste version
            if (!latestCoursesByTemplate.containsKey(course.templateID) ||
                course.activationDate.isAfter(
                  latestCoursesByTemplate[course.templateID]!.activationDate,
                )) {
              latestCoursesByTemplate[course.templateID] = course;
            }
          }
        }

        // Kombiner baner med TemplateID og baner uden TemplateID
        final coursesWithTemplate = latestCoursesByTemplate.values.toList();
        final filteredCourses = [
          ...coursesWithTemplate,
          ...coursesWithoutTemplate,
        ];

        // 4. Sortering: Sorter alfabetisk efter Name
        filteredCourses.sort((a, b) => a.name.compareTo(b.name));

        return filteredCourses;
      } else {
        throw Exception('Failed to load courses: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching courses: $e');
    }
  }
}
