import 'package:cloud_firestore/cloud_firestore.dart';
import 'dgu_service.dart';

/// Service for populating the Firestore course cache
/// This is used for initial seeding and can be triggered manually
class CacheSeedService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DguService _dguService = DguService();
  
  static const String _metadataCollection = 'course-cache-metadata';
  static const String _metadataDocId = 'data';
  static const String _clubsCollection = 'course-cache-clubs';
  
  /// Seeds the cache with all clubs and their courses
  /// This operation may take 2-5 minutes depending on API speed
  Future<SeedResult> seedCache({
    Function(String)? onProgress,
  }) async {
    final startTime = DateTime.now();
    int clubCount = 0;
    int courseCount = 0;
    final List<String> skippedClubs = [];
    final List<String> largeClubs = []; // Clubs >500KB but <1MB
    
    try {
      onProgress?.call('📡 Fetching all clubs from API...');
      
      // 1. Fetch all clubs
      final clubs = await _dguService.fetchClubs();
      clubCount = clubs.length;
      
      onProgress?.call('✅ Found $clubCount clubs');
      onProgress?.call('📡 Fetching courses for each club...');
      
      // 2. Fetch RAW JSON for all clubs and courses
      final clubsRaw = await _dguService.fetchClubsRaw();
      
      onProgress?.call('📊 Clubs JSON size: ${(clubsRaw.toString().length / 1024).toStringAsFixed(2)} KB');
      
      // 3. For each club, fetch its courses and embed them
      final clubsWithCourses = <Map<String, dynamic>>[];
      final clubSizes = <String, int>{};
      
      for (int i = 0; i < clubsRaw.length; i++) {
        final clubData = clubsRaw[i];
        final clubId = clubData['ID'] as String;
        final clubName = clubData['Name'] as String? ?? 'Unknown';
        
        try {
          onProgress?.call('Fetching courses for $clubName (${i + 1}/${clubsRaw.length})');
          
          // Fetch RAW courses for this club
          final coursesRaw = await _dguService.fetchCoursesRaw(clubId);
          
          // FILTER courses before caching (same logic as fetchCourses)
          final filteredCoursesRaw = _filterCourses(coursesRaw);
          courseCount += filteredCoursesRaw.length;
          
          onProgress?.call('  → Filtered ${coursesRaw.length} → ${filteredCoursesRaw.length} courses');
          
          // Embed FILTERED courses in club data
          clubData['courses'] = filteredCoursesRaw;
          
          // Calculate size of this club document
          final clubSize = clubData.toString().length;
          clubSizes[clubName] = clubSize;
          
          if (clubSize > 900000) { // Warn if > 900KB (approaching 1MB limit)
            onProgress?.call('⚠️ Large club: $clubName = ${(clubSize / 1024).toStringAsFixed(0)}KB');
          }
          
          clubsWithCourses.add(clubData);
          
          // Add delay to avoid rate limiting (300ms between requests)
          if (i < clubsRaw.length - 1) {
            await Future.delayed(const Duration(milliseconds: 300));
          }
          
        } catch (e) {
          print('⚠️ Error fetching courses for $clubName: $e');
          // Continue with other clubs even if one fails
          continue;
        }
      }
      
      onProgress?.call('✅ Fetched $courseCount courses total');
      
      // Log total size and largest clubs
      final totalSize = clubsWithCourses.fold<int>(0, (sum, club) => sum + club.toString().length);
      onProgress?.call('📊 Total data size: ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      
      final largestClubs = clubSizes.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      onProgress?.call('📊 Top 5 largest clubs:');
      for (int i = 0; i < 5 && i < largestClubs.length; i++) {
        final entry = largestClubs[i];
        onProgress?.call('  ${i + 1}. ${entry.key}: ${(entry.value / 1024).toStringAsFixed(0)}KB');
      }
      
      onProgress?.call('💾 Saving to Firestore in chunks...');
      
      // 3. Save clubs in batches of 20 to avoid 10MB batch limit
      const chunkSize = 20;
      final totalChunks = (clubsWithCourses.length / chunkSize).ceil();
      
      for (int chunkIndex = 0; chunkIndex < totalChunks; chunkIndex++) {
        final start = chunkIndex * chunkSize;
        final end = (start + chunkSize).clamp(0, clubsWithCourses.length);
        final chunk = clubsWithCourses.sublist(start, end);
        
        onProgress?.call('Saving chunk ${chunkIndex + 1}/$totalChunks (${chunk.length} clubs)');
        
        final batch = _firestore.batch();
        
        for (final clubData in chunk) {
          final clubId = clubData['ID'] as String;
          final clubName = clubData['Name'] as String? ?? 'Unknown';
          final clubSize = clubData.toString().length;
          
          final sizeKB = (clubSize / 1024).toStringAsFixed(0);
          
          // Skip clubs larger than 1MB (Firestore limit)
          if (clubSize > 1048576) {
            skippedClubs.add('$clubName ($sizeKB KB)');
            onProgress?.call('⚠️ Skipping $clubName ($sizeKB KB - too large)');
            continue;
          }
          
          // Track large clubs (>500KB) that are still under limit
          if (clubSize > 512000) {
            largeClubs.add('$clubName ($sizeKB KB)');
            onProgress?.call('📦 $clubName: $sizeKB KB');
          }
          
          // Split club data: info (lightweight) + courses (heavy)
          final clubInfo = Map<String, dynamic>.from(clubData);
          final courses = clubInfo.remove('courses') as List; // Remove and extract courses
          
          final docRef = _firestore
              .collection(_clubsCollection)
              .doc(clubId);
          
          batch.set(docRef, {
            'info': clubInfo,        // Club data WITHOUT courses (light!)
            'courses': courses,      // Courses array (heavy)
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
        
        // Commit this chunk
        await batch.commit();
        onProgress?.call('✅ Chunk ${chunkIndex + 1}/$totalChunks saved');
      }
      
      // Save metadata document with club list (for fast loading!)
      onProgress?.call('💾 Saving metadata with club list...');
      
      // Build lightweight club list (only ID and Name)
      final clubList = clubsWithCourses.map((clubData) {
        return {
          'ID': clubData['ID'],
          'Name': clubData['Name'],
        };
      }).toList();
      
      await _firestore
          .collection(_metadataCollection)
          .doc(_metadataDocId)
          .set({
        'lastUpdated': FieldValue.serverTimestamp(),
        'clubCount': clubsWithCourses.length,
        'courseCount': courseCount,
        'clubs': clubList, // ⚡ Lightweight club list for fast loading!
        'version': 2, // Bump version to indicate new structure
      });
      
      final duration = DateTime.now().difference(startTime);
      
      onProgress?.call('✅ Cache seeded successfully!');
      onProgress?.call('📊 Saved: ${clubsWithCourses.length - skippedClubs.length} clubs, $courseCount courses');
      
      if (largeClubs.isNotEmpty) {
        onProgress?.call('📦 Large clubs (>500KB, saved):');
        for (final club in largeClubs) {
          onProgress?.call('  • $club');
        }
      }
      
      if (skippedClubs.isNotEmpty) {
        onProgress?.call('⚠️ Skipped ${skippedClubs.length} clubs (>1MB):');
        for (final club in skippedClubs) {
          onProgress?.call('  • $club');
        }
      }
      
      onProgress?.call('⏱️ Time: ${duration.inSeconds} seconds');
      
      return SeedResult(
        success: true,
        clubCount: clubsWithCourses.length - skippedClubs.length,
        courseCount: courseCount,
        duration: duration,
        skippedClubs: skippedClubs,
      );
      
    } catch (e) {
      final duration = DateTime.now().difference(startTime);
      
      onProgress?.call('❌ Seeding failed: $e');
      
      return SeedResult(
        success: false,
        clubCount: clubCount,
        courseCount: courseCount,
        duration: duration,
        error: e.toString(),
      );
    }
  }
  
  /// Gets cache info (when last updated, how many clubs)
  Future<CacheInfo?> getCacheInfo() async {
    try {
      final doc = await _firestore
          .collection(_metadataCollection)
          .doc(_metadataDocId)
          .get();
      
      if (!doc.exists || doc.data() == null) {
        return null;
      }
      
      final data = doc.data()!;
      final lastUpdated = data['lastUpdated'] as Timestamp?;
      final clubCount = data['clubCount'] as int? ?? 0;
      final courseCount = data['courseCount'] as int? ?? 0;
      final version = data['version'] as int? ?? 0;
      
      return CacheInfo(
        lastUpdated: lastUpdated?.toDate(),
        clubCount: clubCount,
        courseCount: courseCount,
        version: version,
      );
      
    } catch (e) {
      print('❌ Error getting cache info: $e');
      return null;
    }
  }
  
  /// Filters courses using same logic as DguService.fetchCourses
  /// Removes inactive, future-dated, and old template versions
  List<Map<String, dynamic>> _filterCourses(List<Map<String, dynamic>> coursesRaw) {
    final currentDate = DateTime.now();
    
    // 1. Filter: Only active courses
    final activeCourses = coursesRaw.where((course) {
      final isActive = course['IsActive'] as bool? ?? false;
      return isActive;
    }).toList();
    
    // 2. Filter: Only courses with ActivationDate <= now
    final coursesBeforeNow = activeCourses.where((course) {
      final activationDateStr = course['ActivationDate'] as String?;
      if (activationDateStr == null) return true;
      
      try {
        final activationDate = DateTime.parse(activationDateStr);
        return activationDate.isBefore(currentDate) || 
               activationDate.isAtSameMomentAs(currentDate);
      } catch (e) {
        return true; // Include if can't parse
      }
    }).toList();
    
    // 3. Group by TemplateID and keep only latest version
    final Map<String, Map<String, dynamic>> latestCoursesByTemplate = {};
    final List<Map<String, dynamic>> coursesWithoutTemplate = [];
    
    for (final course in coursesBeforeNow) {
      final templateID = course['TemplateID'] as String? ?? '';
      
      if (templateID.isEmpty) {
        coursesWithoutTemplate.add(course);
      } else {
        if (!latestCoursesByTemplate.containsKey(templateID)) {
          latestCoursesByTemplate[templateID] = course;
        } else {
          final existingDate = DateTime.tryParse(
            latestCoursesByTemplate[templateID]!['ActivationDate'] as String? ?? ''
          );
          final currentCourseDate = DateTime.tryParse(
            course['ActivationDate'] as String? ?? ''
          );
          
          if (existingDate != null && currentCourseDate != null && 
              currentCourseDate.isAfter(existingDate)) {
            latestCoursesByTemplate[templateID] = course;
          }
        }
      }
    }
    
    // Combine
    final filteredCourses = [
      ...latestCoursesByTemplate.values,
      ...coursesWithoutTemplate,
    ];
    
    return filteredCourses;
  }

  /// Clears the cache (for testing)
  Future<bool> clearCache() async {
    try {
      print('🗑️ Clearing cache...');
      
      // Delete all club documents
      final clubDocs = await _firestore
          .collection(_clubsCollection)
          .get();
      
      print('🗑️ Found ${clubDocs.docs.length} club documents to delete...');
      
      // Delete in batches to avoid batch size limits
      const batchSize = 500;
      for (int i = 0; i < clubDocs.docs.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize).clamp(0, clubDocs.docs.length);
        
        for (int j = i; j < end; j++) {
          batch.delete(clubDocs.docs[j].reference);
        }
        
        await batch.commit();
        print('🗑️ Deleted ${end - i} documents...');
      }
      
      // Reset metadata
      await _firestore
          .collection(_metadataCollection)
          .doc(_metadataDocId)
          .set({
        'lastUpdated': FieldValue.serverTimestamp(),
        'clubCount': 0,
        'courseCount': 0,
        'clubs': [],
        'version': 2,
      });
      
      print('✅ Cache cleared - all ${clubDocs.docs.length} club documents deleted');
      return true;
    } catch (e) {
      print('❌ Error clearing cache: $e');
      return false;
    }
  }
}

/// Result of a cache seeding operation
class SeedResult {
  final bool success;
  final int clubCount;
  final int courseCount;
  final Duration duration;
  final String? error;
  final List<String> skippedClubs;
  
  SeedResult({
    required this.success,
    required this.clubCount,
    required this.courseCount,
    required this.duration,
    this.error,
    this.skippedClubs = const [],
  });
}

/// Information about the current cache state
class CacheInfo {
  final DateTime? lastUpdated;
  final int clubCount;
  final int courseCount;
  final int version;
  
  CacheInfo({
    required this.lastUpdated,
    required this.clubCount,
    required this.courseCount,
    required this.version,
  });
  
  /// Returns age of cache in hours
  int get ageInHours {
    if (lastUpdated == null) return 0;
    return DateTime.now().difference(lastUpdated!).inHours;
  }
  
  /// Returns if cache is valid (< 24 hours old)
  bool get isValid => ageInHours < 24;
}

