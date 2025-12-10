import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/club_model.dart';
import '../models/course_model.dart';
import 'dgu_service.dart';

/// Service for reading cached golf course data from Firestore
/// Falls back to API if cache is empty or stale
class CourseCacheService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DguService _dguService = DguService();
  
  static const String _metadataCollection = 'course-cache-metadata';
  static const String _metadataDocId = 'data';
  static const String _clubsCollection = 'course-cache-clubs';
  static const int _cacheValidityHours = 24;
  
  /// Fetches clubs from Firestore cache
  /// Falls back to API if cache is invalid or missing
  Future<List<Club>> fetchCachedClubs() async {
    try {
      print('📦 Attempting to fetch from Firestore cache...');
      
      // Check metadata first
      final metadataDoc = await _firestore
          .collection(_metadataCollection)
          .doc(_metadataDocId)
          .get();
      
      if (!metadataDoc.exists || metadataDoc.data() == null) {
        print('⚠️ Cache metadata does not exist, falling back to API');
        return await _fallbackToApi();
      }
      
      final metadata = metadataDoc.data()!;
      
      // Check if cache is valid
      if (!_isCacheValid(metadata)) {
        print('⚠️ Cache is stale (>24 hours old), falling back to API');
        return await _fallbackToApi();
      }
      
      final clubCount = metadata['clubCount'] as int? ?? 0;
      if (clubCount == 0) {
        print('⚠️ Cache is empty, falling back to API');
        return await _fallbackToApi();
      }
      
      // ⚡ Fast path: Get club list from metadata (only 1 read!)
      final clubListData = metadata['clubs'] as List?;
      
      if (clubListData != null && clubListData.isNotEmpty) {
        print('⚡ Fast loading $clubCount clubs from metadata...');
        
        final clubs = clubListData
            .map((clubData) => Club.fromJson(clubData as Map<String, dynamic>))
            .toList();
        
        // Sort alphabetically
        clubs.sort((a, b) => a.name.compareTo(b.name));
        
        print('✅ Instantly loaded ${clubs.length} clubs from metadata!');
        return clubs;
      }
      
      // Fallback: Fetch all club documents (old method, 213 reads)
      print('⚠️ No club list in metadata, using slow method...');
      print('📦 Fetching $clubCount clubs from cache...');
      
      final clubDocs = await _firestore
          .collection(_clubsCollection)
          .get();
      
      if (clubDocs.docs.isEmpty) {
        print('⚠️ No club documents found, falling back to API');
        return await _fallbackToApi();
      }
      
      // Parse each club document (only 'info' field, NOT courses!)
      final clubs = clubDocs.docs.map((doc) {
        final data = doc.data();
        final clubInfo = data['info'] as Map<String, dynamic>?;
        
        // Fallback to old structure if needed
        if (clubInfo == null) {
          final rawData = data['rawData'] as Map<String, dynamic>;
          return Club.fromJson(rawData);
        }
        
        return Club.fromJson(clubInfo);
      }).toList();
      
      // Sort alphabetically
      clubs.sort((a, b) => a.name.compareTo(b.name));
      
      print('✅ Successfully loaded ${clubs.length} clubs from cache');
      return clubs;
      
    } catch (e) {
      print('❌ Error reading from cache: $e');
      print('⚠️ Falling back to API');
      return await _fallbackToApi();
    }
  }
  
  /// Fetches courses for a club from cache
  /// Returns courses embedded in the cached club data
  Future<List<GolfCourse>> fetchCachedCourses(String clubId) async {
    try {
      print('📦 Attempting to fetch courses for club $clubId from cache...');
      
      // Check metadata validity first
      final metadataDoc = await _firestore
          .collection(_metadataCollection)
          .doc(_metadataDocId)
          .get();
      
      if (!metadataDoc.exists || metadataDoc.data() == null) {
        print('⚠️ Cache metadata missing, falling back to API');
        return await _dguService.fetchCourses(clubId);
      }
      
      if (!_isCacheValid(metadataDoc.data()!)) {
        print('⚠️ Cache is stale, falling back to API');
        return await _dguService.fetchCourses(clubId);
      }
      
      // Fetch specific club document from flat collection
      final clubDoc = await _firestore
          .collection(_clubsCollection)
          .doc(clubId)
          .get();
      
      if (!clubDoc.exists || clubDoc.data() == null) {
        print('⚠️ Club $clubId not found in cache, falling back to API');
        return await _dguService.fetchCourses(clubId);
      }
      
      final data = clubDoc.data()!;
      
      // Try new structure first (courses field)
      List? coursesData = data['courses'] as List?;
      
      // Fallback to old structure if needed
      if (coursesData == null) {
        final rawData = data['rawData'] as Map<String, dynamic>?;
        if (rawData != null) {
          coursesData = rawData['courses'] as List?;
        }
      }
      
      if (coursesData == null || coursesData.isEmpty) {
        print('⚠️ No courses found for club, falling back to API');
        return await _dguService.fetchCourses(clubId);
      }
      
      print('✅ Cache hit! Found ${coursesData.length} courses in cache');
      
      final courses = coursesData
          .map((courseJson) => GolfCourse.fromJson(courseJson as Map<String, dynamic>))
          .toList();
      
      return courses;
      
    } catch (e) {
      print('❌ Error reading courses from cache: $e');
      return await _dguService.fetchCourses(clubId);
    }
  }
  
  /// Checks if cache is valid (less than 24 hours old)
  bool _isCacheValid(Map<String, dynamic> data) {
    final lastUpdated = data['lastUpdated'];
    
    if (lastUpdated == null) {
      return false;
    }
    
    final timestamp = (lastUpdated as Timestamp).toDate();
    final age = DateTime.now().difference(timestamp);
    
    return age.inHours < _cacheValidityHours;
  }
  
  /// Fallback to direct API call
  Future<List<Club>> _fallbackToApi() async {
    print('🌐 Fetching clubs directly from API...');
    return await _dguService.fetchClubs();
  }
  
  /// Test method to verify Firestore read access
  Future<bool> testFirestoreAccess() async {
    try {
      print('🧪 Testing Firestore access...');
      
      final doc = await _firestore
          .collection(_metadataCollection)
          .doc(_metadataDocId)
          .get();
      
      print('✅ Firestore read successful! Document exists: ${doc.exists}');
      return true;
    } catch (e) {
      print('❌ Firestore access test failed: $e');
      return false;
    }
  }
}

