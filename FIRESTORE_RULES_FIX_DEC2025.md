# Firestore Rules Fix - December 2025

## Problem Summary

**Date Discovered:** December 18, 2025  
**Symptom:** Scorecard submission failing with "Firebase test fejl: Exception: Kunne ikke gemme scorekort: [cloud_firestore/permission-denied] Missing or insufficient permissions."

## Root Cause Analysis

### Timeline

1. **November 2024/2025**: Scorecard feature implemented
   - Code uses `scorecards` collection for all scorecard operations
   - No `firestore.rules` file in repository
   - Firestore running without deployed security rules (test mode or default allow)
   - ✅ Everything works perfectly

2. **December 15, 2025**: Friends System deployed
   - First deployment of `firestore.rules` to repository
   - Rules included for: `friendships`, `friend_requests`, `activities`, etc.
   - Rules included for `pending_scorecards` and `completed_scorecards` (never used in code)
   - ❌ **Missing rule for `scorecards`** (the actual collection used by code)
   - Default deny rule (line 107-109) blocks all unmatched collections

3. **December 18, 2025**: Bug discovered
   - User attempts scorecard submission
   - Firestore write to `scorecards` blocked by missing rule
   - Push notification never sent (code crashes before reaching notification logic)

### Technical Details

**Code uses:**
- `lib/services/scorecard_storage_service.dart` line 10:
  ```dart
  CollectionReference get _scorecards => _firestore.collection('scorecards');
  ```

**Firestore rules had:**
- `pending_scorecards` rule (lines 19-26) ❌ Never used
- `completed_scorecards` rule (lines 29-34) ❌ Never used
- No rule for `scorecards` ❌ Blocked by default deny

**Impact:**
Three critical operations blocked:
1. Initial scorecard creation (player → marker)
2. Approval update (marker approves)
3. Submission status update (after WHS API success)

## Solution Implemented

### Changes to `firestore.rules`

**Removed unused rules:**
- `pending_scorecards` collection (never referenced in code)
- `completed_scorecards` collection (never referenced in code)

**Added missing rules:**
```javascript
// Scorecards collection - main storage for marker approval flow
match /scorecards/{documentId} {
  allow read, write: if true; // TEMP: Open for testing
}

// Course cache collections (read-only for client, written by Cloud Functions)
match /course-cache-clubs/{clubId} {
  allow read: if true;
  allow write: if false; // Only Cloud Functions via Admin SDK
}

match /course-cache-metadata/{docId} {
  allow read: if true;
  allow write: if false; // Only Cloud Functions via Admin SDK
}
```

### Deployment

```bash
firebase deploy --only firestore:rules --project dgu-scorekort
```

**Result:** ✅ Rules compiled and deployed successfully

## Scorecard Flow Architecture

### Current Implementation (Correct)

All scorecard operations use a **single collection** (`scorecards`) with status tracking:

```
Player creates scorecard
  ↓
Save to Firestore: scorecards collection
  status: 'pending'
  isSubmittedToDgu: false
  ↓
Send push notification to marker
  ↓
Marker opens approval link
  ↓
[APPROVE PATH]                    [REJECT PATH]
  ↓                                 ↓
Update: status = 'approved'      Update: status = 'rejected'
  ↓                                 ↓
Submit to WHS API                 ❌ No WHS submission
  ↓
Update: isSubmittedToDgu = true
  ↓
✅ Complete
```

### WHS API Integration

**Endpoint:**
```
POST https://dgubasen.api.union.golfbox.io/DGUScorkortAapp/Clubs/Members/ExchangedScorecards
```

**Trigger:** Marker approval (`marker_approval_from_url_screen.dart` line 87-127)

**JSON Payload Example:**
```json
[
  {
    "CreateDateTime": "20251218T143052",
    "ExternalID": "dgu_abc123def456",
    "HCP": "158000",
    "CourseHandicap": 16,
    "Course": {
      "CourseID": "1234",
      "ClubID": "5678",
      "TeeID": "9012"
    },
    "Marker": {
      "UnionID": "8-9995"
    },
    "Result": {
      "Strokes": [5, 4, 6, 5, 4, 5, 6, 4, 5, 4, 5, 6, 5, 4, 5, 6, 4, 5],
      "IsQualifying": true
    },
    "Round": {
      "HolesPlayed": 18,
      "RoundType": 1,
      "StartTime": "20251218T090200"
    },
    "Player": {
      "UnionID": "177-2813"
    }
  }
]
```

**Key Fields:**
- `ExternalID`: Firestore document ID with `dgu_` prefix (e.g., `dgu_abc123`)
- `HCP`: Handicap × 10000 (15.8 → `158000`)
- `Strokes`: Array of strokes per hole
- API expects **ARRAY** format (not single object)

## Collections Audit

### After Fix - All Collections with Proper Rules

| Collection | Client Access | Cloud Functions | Rule Status |
|------------|---------------|-----------------|-------------|
| `scorecards` | read/write | - | ✅ Added |
| `friendships` | read/write | - | ✅ Existing |
| `friend_requests` | read/write | - | ✅ Existing |
| `user_privacy_settings` | read/write | - | ✅ Existing |
| `activities` | read only | write only | ✅ Existing |
| `birdie_bonus_cache` | read only | write only | ✅ Existing |
| `user_score_cache` | read only | write only | ✅ Existing |
| `course-cache-clubs` | read only | write only | ✅ Added |
| `course-cache-metadata` | read only | write only | ✅ Added |

**Note:** All "TEMP: Open" rules follow the existing Friends System pattern. Future work can implement proper Firebase Auth with custom claims for `unionId`.

## Testing Verification

### Test Steps

1. Login to app (OAuth or simple login)
2. Create new scorecard:
   - Select course and tee
   - Enter scores for all holes
   - Click "Afslut Runde"
3. Click "Send til Markør"
4. Search for and select a marker
5. Verify:
   - ✅ No "permission denied" error
   - ✅ Success dialog shows "Scorekort gemt!"
   - ✅ Push notification status displayed
   - ✅ Scorecard document created in Firestore Console → `scorecards` collection

### Expected Result

```
✅ Scorekort gemt til Firebase...
✅ Push notification sent to marker
✅ Dialog: "Scorekort gemt!" with notification status
```

## Lessons Learned

1. **Always deploy security rules with new collections**
   - When adding Firestore writes, immediately add corresponding rules
   - Test with rules enabled, not just in test mode

2. **Clean up unused rules**
   - `pending_scorecards` and `completed_scorecards` were design artifacts
   - Caused confusion during debugging
   - Removed to prevent future issues

3. **Document collection usage**
   - Clear mapping between code and Firestore collections
   - Status tracking patterns documented

4. **Test mode expiration**
   - Firestore test mode expires after 30 days
   - Production apps need proper security rules from day one

## Files Modified

- `firestore.rules` (+15 lines, -16 lines)

## Future Improvements

1. **Implement Firebase Auth with custom claims**
   - Current: No Firebase Auth (OAuth tokens in SharedPreferences)
   - Target: Firebase Auth with `unionId` in custom claims
   - Benefits: Proper authentication for security rules

2. **Granular permissions**
   - Current: Open access (`if true`) for testing
   - Target: Role-based access control
   - Example: Only marker can approve their assigned scorecards

3. **Audit logging**
   - Track who modified scorecards and when
   - Helpful for debugging and compliance

## References

- Scorecard Storage Service: `lib/services/scorecard_storage_service.dart`
- WHS Submission Service: `lib/services/whs_submission_service.dart`
- Marker Approval Screen: `lib/screens/marker_approval_from_url_screen.dart`
- Firestore Rules: `firestore.rules`

---

**Fix Implemented By:** Cursor AI  
**Approved By:** Nick Hüttel  
**Date:** December 18, 2025

