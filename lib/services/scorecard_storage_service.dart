import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scorecard_model.dart';
import '../models/course_model.dart';
import '../models/player_model.dart';

class ScorecardStorageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference for scorecards
  CollectionReference get _scorecards => _firestore.collection('scorecards');

  /// Save a scorecard to Firestore with status "pending"
  /// Returns the document ID which can be used in the approval URL
  Future<String> saveScorecardForApproval({
    required Scorecard scorecard,
    required String markerId,
    required String markerName,
  }) async {
    try {
      final docRef = await _scorecards.add({
        // Player information
        'playerId': scorecard.player.unionId,
        'playerName': scorecard.player.name,
        'playerLifetimeId': scorecard.player.lifetimeId,
        'playerHomeClubName': scorecard.player.homeClubName,
        'playerHandicap': scorecard.player.hcp,
        'playingHandicap': scorecard.playingHandicap,

        // Marker information (assigned)
        'markerId': markerId,
        'markerName': markerName,

        // Course information
        'clubId': scorecard.course.clubId,
        'courseName': scorecard.course.name,
        'courseId': scorecard.course.id,
        'teeId': scorecard.tee.id,
        'teeName': scorecard.tee.name,
        'teeGender': scorecard.tee.gender,
        'teeLength': scorecard.tee.totalLength,
        'courseRating': scorecard.tee.courseRating,
        'slopeRating': scorecard.tee.slopeRating,

        // Scores
        'holes': scorecard.holeScores
            .map(
              (hole) => {
                'holeNumber': hole.holeNumber,
                'par': hole.par,
                'index': hole.index,
                'strokesReceived': hole.strokesReceived,
                'strokes': hole.strokes,
                'putts': hole.putts,
                'isPickedUp': hole.isPickedUp,
              },
            )
            .toList(),

        // Calculated scores
        'totalStrokes': scorecard.totalStrokes,
        'totalPoints': scorecard.totalPoints,
        'adjustedGrossScore': scorecard.adjustedGrossScore,
        'handicapResult': scorecard.handicapResult,
        'front9Points': scorecard.front9Points,
        'back9Points': scorecard.back9Points,

        // Timestamps
        'playedDate': Timestamp.fromDate(scorecard.startTime),
        'createdAt': FieldValue.serverTimestamp(),
        'approvedAt': null,

        // Status tracking
        'status': 'pending', // pending, approved, rejected
        'isSubmittedToDgu': false,

        // Optional marker approval fields (filled when approved)
        'markerLifetimeId': null,
        'markerHomeClubName': null,
        'markerSignature': null,
        'markerApprovedAt': null,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Kunne ikke gemme scorekort: $e');
    }
  }

  /// Fetch a scorecard by its document ID
  /// Used when marker opens the approval link
  Future<Map<String, dynamic>?> getScorecardById(String documentId) async {
    try {
      final doc = await _scorecards.doc(documentId).get();

      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add document ID to the data

      return data;
    } catch (e) {
      throw Exception('Kunne ikke hente scorekort: $e');
    }
  }

  /// Approve a scorecard (called when marker confirms)
  Future<void> approveScorecardById({
    required String documentId,
    required String markerLifetimeId,
    required String markerHomeClubName,
    required String markerSignature,
  }) async {
    try {
      await _scorecards.doc(documentId).update({
        'status': 'approved',
        'markerLifetimeId': markerLifetimeId,
        'markerHomeClubName': markerHomeClubName,
        'markerSignature': markerSignature,
        'markerApprovedAt': FieldValue.serverTimestamp(),
        'approvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Kunne ikke godkende scorekort: $e');
    }
  }

  /// Reject a scorecard with a reason
  Future<void> rejectScorecardById({
    required String documentId,
    required String reason,
  }) async {
    try {
      await _scorecards.doc(documentId).update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Kunne ikke afvise scorekort: $e');
    }
  }

  /// Get all pending scorecards for a specific marker (by their DGU number)
  Stream<List<Map<String, dynamic>>> getPendingScorecardsByMarkerId(
    String markerId,
  ) {
    return _scorecards
        .where('markerId', isEqualTo: markerId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Get all scorecards for a player (any status)
  Stream<List<Map<String, dynamic>>> getScorecardsByPlayerId(String playerId) {
    return _scorecards
        .where('playerId', isEqualTo: playerId)
        .orderBy('playedDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Mark a scorecard as submitted to DGU
  Future<void> markAsSubmittedToDgu({
    required String documentId,
    String? submissionResponse,
  }) async {
    try {
      print(
        '📝 Updating Firestore: isSubmittedToDgu = true for doc: $documentId',
      );

      await _scorecards.doc(documentId).update({
        'isSubmittedToDgu': true,
        'submittedToDguAt': FieldValue.serverTimestamp(),
        'submissionResponse': submissionResponse ?? 'Success',
      });

      print('✅ Firestore updated successfully');

      // Verify the update
      final doc = await _scorecards.doc(documentId).get();
      final data = doc.data() as Map<String, dynamic>?;
      final updatedValue = data?['isSubmittedToDgu'];
      print('🔍 Verification: isSubmittedToDgu = $updatedValue');
    } catch (e) {
      print('❌ Failed to update Firestore: $e');
      throw Exception('Kunne ikke opdatere submission status: $e');
    }
  }

  /// Convert Firestore data back to Scorecard model
  /// Used when you need to work with the full Scorecard object
  Scorecard firestoreToScorecard(Map<String, dynamic> data) {
    // Reconstruct Player
    final player = Player(
      name: data['playerName'] as String,
      memberNo: data['playerId'] as String, // Use unionId as memberNo
      unionId: data['playerId'] as String,
      lifetimeId: data['playerLifetimeId'] as String?,
      homeClubName: data['playerHomeClubName'] as String?,
      hcp: (data['playerHandicap'] as num).toDouble(),
    );

    // Reconstruct hole data from Firestore (for GolfCourse.holes)
    final holeDataList = (data['holes'] as List).cast<Map<String, dynamic>>();
    final holes = holeDataList.map((hole) {
      return Hole(
        id: '', // Not stored
        number: hole['holeNumber'] as int,
        par: hole['par'] as int,
        length: 0, // Not stored
        index: hole['index'] as int,
      );
    }).toList();

    // Reconstruct Tee
    final tee = Tee(
      id: data['teeId'] as String,
      name: data['teeName'] as String,
      gender: data['teeGender'] as int,
      courseRating: (data['courseRating'] as num).toDouble(),
      slopeRating: data['slopeRating'] as int,
      totalLength: data['teeLength'] as int,
      holes: holes,
    );

    // Reconstruct GolfCourse (simplified)
    final course = GolfCourse(
      id: data['courseId'] as String,
      name: data['courseName'] as String,
      clubId: data['clubId'] as String? ?? '',
      tees: [tee],
      holes: holes,
      isActive: true,
      activationDate: DateTime.now(),
      templateID: '',
    );

    // Reconstruct HoleScores
    final holeScores = (data['holes'] as List).map((hole) {
      return HoleScore(
        holeNumber: hole['holeNumber'] as int,
        par: hole['par'] as int,
        index: hole['index'] as int,
        strokesReceived: hole['strokesReceived'] as int,
        strokes: hole['strokes'] as int?,
        putts: hole['putts'] as int?,
        isPickedUp: hole['isPickedUp'] as bool,
      );
    }).toList();

    // Reconstruct Scorecard
    final playedDate = (data['playedDate'] as Timestamp).toDate();
    final approvedAt = data['approvedAt'] != null
        ? (data['approvedAt'] as Timestamp).toDate()
        : null;

    return Scorecard(
      course: course,
      tee: tee,
      player: player,
      playingHandicap: data['playingHandicap'] as int,
      holeScores: holeScores,
      startTime: playedDate,
      endTime: playedDate,
      markerFullName: data['status'] == 'approved' ? data['markerName'] : null,
      markerUnionId: data['status'] == 'approved' ? data['markerId'] : null,
      markerLifetimeId: data['markerLifetimeId'] as String?,
      markerHomeClubName: data['markerHomeClubName'] as String?,
      markerApprovedAt: approvedAt,
      markerSignature: data['markerSignature'] as String?,
      isSubmitted: data['isSubmittedToDgu'] as bool? ?? false,
      submittedAt: data['submittedToDguAt'] != null
          ? (data['submittedToDguAt'] as Timestamp).toDate()
          : null,
      submissionResponse: data['submissionResponse'] as String?,
    );
  }
}
