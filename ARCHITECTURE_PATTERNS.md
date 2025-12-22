# DGU Scorekort - Unikke Arkitektur Patterns

**Dato:** 19. december 2025

---

## 🏗️ 1. Server-Side Caching Pattern (Course Data)

### Koncept
I stedet for at kalde eksterne API'er direkte fra Flutter appen, bruger vi Firebase Cloud Functions til at cache data i Firestore. Dette giver os:

- ⚡ **Instant loading** (1 Firestore read vs. 3-5 sekunder API call)
- 💰 **Reducerede API costs** (1 call/nat vs. tusindvis fra app)
- 📱 **Offline support** (data cached lokalt via Firestore)
- 🔄 **Smart incremental updates** (kun ændringer siden sidste sync)

### Implementation

#### Cloud Function: `updateCourseCache`
```javascript
// Scheduled: Kl. 02:00 hver nat (Europe/Copenhagen)
exports.updateCourseCache = functions
  .region('europe-west1')
  .runWith({ timeoutSeconds: 540, memory: '1GB' })
  .pubsub.schedule('0 2 * * *')
  .timeZone('Europe/Copenhagen')
  .onRun(async (context) => {
    // 1. Check last sync timestamp
    const lastSync = await getLastSyncTimestamp();
    
    // 2. Smart update strategy
    if (shouldRunFullReseed(lastSync)) {
      // Full reseed every 30 days or if cache empty
      await fullReseed();
    } else {
      // Incremental: Only changed data
      await incrementalUpdate(lastSync);
    }
    
    // 3. Store in Firestore
    await storeInFirestore(data);
    
    // 4. Update metadata
    await updateMetadata({ lastSync: now, type: 'incremental' });
  });
```

#### Firestore Structure
```
firestore/
├── course_cache_metadata/
│   └── info/
│       ├── lastSync: Timestamp
│       ├── clubCount: 213
│       ├── courseCount: 876
│       └── updateType: "incremental"
│
├── course_cache_clubs/
│   └── {clubId}/
│       ├── id: "4000"
│       ├── name: "Lyngby Golf Klub"
│       ├── city: "Lyngby"
│       ├── region: "Hovedstaden"
│       └── lastUpdated: Timestamp
│
└── course_cache_courses/
    └── {courseId}/
        ├── id: "4000-A"
        ├── name: "Lyngby A-bane"
        ├── clubId: "4000"
        ├── rating: 72.3
        ├── slope: 131
        ├── par: 72
        ├── holes: [...]
        └── lastUpdated: Timestamp
```

#### Flutter Client: Instant Metadata Loading
```dart
class CourseCacheService {
  // Load metadata first (1 read, instant)
  Future<CourseCacheMetadata> getMetadata() async {
    final doc = await _db.collection('course_cache_metadata').doc('info').get();
    return CourseCacheMetadata.fromFirestore(doc);
  }

  // Load clubs on-demand (stream, lazy)
  Stream<List<Club>> streamClubs() {
    return _db.collection('course_cache_clubs')
      .orderBy('name')
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => Club.fromFirestore(doc)).toList());
  }
}
```

### Performance Metrics
- **Metadata Load:** <100ms (1 Firestore read)
- **Club List:** 300-500ms (213 clubs streamed)
- **Full Course Data:** 1-2s first load, <100ms cached
- **Nightly Update:** 15-20 sekunder (incremental), 45-60 sekunder (full reseed)

### Cost Analysis
**UDEN Server-Side Caching:**
- 1,000 brugere × 5 club searches/dag = 5,000 DGU API calls/dag
- DGU API rate limits ville være et problem

**MED Server-Side Caching:**
- 1 Cloud Function call/nat (scheduled)
- 1,000 brugere × 5 Firestore reads/dag = 5,000 reads/dag
- **Firestore Cost:** ~$0.03/dag = $0.90/måned
- **Cloud Function Cost:** ~$0.01/dag = $0.30/måned
- **Total:** ~$1.20/måned for 1,000 aktive brugere

---

## 🔥 2. Hybrid Icon Loading Pattern (Tournaments/Rankings)

### Problem
DGU API returnerer `iconUrl` for turneringer og ranglister, men:
- URL'er kan være fra forskellige domæner
- CORS policies blokkerer Flutter Web's `Image.network()`
- Ikoner skal loades hurtigt uden CORS issues

### Løsning: Cloud Function Pre-Caching

#### Cloud Function: `updateGolfEvents`
```javascript
exports.updateGolfEvents = functions
  .region('europe-west1')
  .runWith({ timeoutSeconds: 180, memory: '512MB' })
  .pubsub.schedule('0 2 * * *')
  .timeZone('Europe/Copenhagen')
  .onRun(async (context) => {
    // 1. Fetch from DGU API
    const events = await fetchDguTournaments();
    
    // 2. Extract unique icon URLs
    const iconUrls = [...new Set(events.map(e => e.iconUrl))];
    
    // 3. Download and convert icons
    const iconData = await Promise.all(
      iconUrls.map(url => downloadAndConvertIcon(url))
    );
    
    // 4. Store in Firestore with base64 data
    await storeEvents(events, iconData);
  });

async function downloadAndConvertIcon(url) {
  const response = await axios.get(url, { responseType: 'arraybuffer' });
  const base64 = Buffer.from(response.data, 'binary').toString('base64');
  const contentType = response.headers['content-type'] || 'image/png';
  
  return {
    url,
    base64,
    contentType,
    dataUri: `data:${contentType};base64,${base64}`
  };
}
```

#### Flutter Client: CORS-free Loading
```dart
// Option 1: Base64 data URI (stored in Firestore)
Image.memory(
  base64Decode(tournament.iconBase64),
  width: 40,
  height: 40,
)

// Option 2: HTML <img> tag (bypasses CORS)
HtmlElementView(
  viewType: 'tournament-icon-${tournament.id}',
)
```

### Why This Works
- Cloud Functions run server-side (no CORS restrictions)
- Base64 data embedded in Firestore documents
- Flutter Web loads from Firestore (same-origin)
- No external HTTP calls from browser

---

## 💬 3. Chat System - In-Memory Sorting Pattern

### Problem
Firestore queries combining `arrayContains` + `orderBy` require composite indexes:
```dart
// ❌ This requires a composite index:
_db.collection('chat_groups')
  .where('members', arrayContains: unionId)
  .orderBy('lastMessageTime', descending: true)
```

### Løsning: Fetch All, Sort In-Memory

#### Service Layer
```dart
class ChatService {
  Stream<List<ChatGroup>> streamUserGroups(String unionId) {
    return _db
      .collection('chat_groups')
      .where('members', arrayContains: unionId)
      // NO orderBy here!
      .snapshots()
      .map((snapshot) =>
        snapshot.docs.map((doc) => ChatGroup.fromFirestore(doc)).toList()
      );
  }
}
```

#### Provider Layer: Smart In-Memory Sorting
```dart
class ChatProvider extends ChangeNotifier {
  List<ChatGroup> _groups = [];
  
  void _sortGroups() {
    _groups.sort((a, b) {
      // Sort by lastMessageTime, nulls last
      if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
      if (a.lastMessageTime == null) return 1;
      if (b.lastMessageTime == null) return -1;
      return b.lastMessageTime!.compareTo(a.lastMessageTime!);
    });
  }
  
  void _handleGroupsUpdate(List<ChatGroup> newGroups) {
    _groups = newGroups;
    _sortGroups(); // Sort after Firestore fetch
    notifyListeners();
  }
}
```

### Why This Works
- **No Composite Index Needed:** Firestore only filters, doesn't sort
- **Fast Enough:** Even 100 groups sorts in <1ms
- **Flexible:** Easy to change sort logic without Firestore index
- **Real-time:** Sorting happens after every Firestore update

### Performance
- 10 groups: <0.1ms sort time
- 50 groups: <0.5ms sort time
- 100 groups: <1ms sort time

For a chat app, users rarely have >50 active groups, so in-memory sorting is perfect.

---

## 🎯 Summary of Unique Patterns

| Pattern | Problem Solved | Key Benefit |
|---------|---------------|-------------|
| **Server-Side Caching** | Slow API calls, rate limits | Instant loading (<100ms) |
| **Hybrid Icon Loading** | CORS blocking images | CORS-free, reliable icons |
| **In-Memory Chat Sorting** | Composite index complexity | Simple, flexible, no index |

**Common Theme:** Move complexity to server-side (Cloud Functions) where possible, keep Flutter client simple and fast.

---

## 📚 Related Files
- `functions/index.js` - All Cloud Functions
- `lib/services/course_cache_service.dart` - Course caching client
- `lib/services/golf_events_service.dart` - Tournament/rankings client  
- `lib/services/chat_service.dart` - Chat service
- `lib/providers/chat_provider.dart` - Chat provider with sorting
- `firestore.rules` - Security rules
- `CHAT_IMPLEMENTATION_STATUS.md` - Chat implementation details

---

**Maintained by:** Nick Hüttel  
**Last Updated:** 19. december 2025

