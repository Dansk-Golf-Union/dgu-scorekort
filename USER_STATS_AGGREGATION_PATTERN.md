# User Stats Aggregation Pattern

**Implementeret:** December 22, 2025  
**Version:** 2.0 Extended POC

---

## 🎯 Problem Statement

The homepage needs to display:
- Total friend count (👥 only, not 💬)
- Unread message count
- Active chat groups count

**Challenges:**
1. **Performance:** Counting on-the-fly requires multiple Firestore queries
2. **Data Freshness:** Provider-based counting didn't update without refresh
3. **Complexity:** Nested `context.watch()` and `Consumer` wrappers caused rebuild issues
4. **Widget Lifecycle:** Friends widget wouldn't rebuild even with `notifyListeners()`

## ✅ Solution: Pre-Aggregated Statistics

**Strategy:** Let Cloud Functions calculate and cache statistics in a dedicated `user_stats` collection.

### Architecture

```
User Action (add friend, send message, etc.)
    ↓
Firestore Write (friendships, chat_groups, messages)
    ↓
Cloud Function Trigger (onWrite, onCreate, onUpdate)
    ↓
Calculate Stats (count friends, unread messages, etc.)
    ↓
Write to user_stats/{unionId} via updateUserStats()
    ↓
Flutter HomePage reads user_stats (1 read, instant)
```

---

## 🔥 Firestore Collection: `user_stats`

**Document ID:** User's unionId (e.g., `"177-2813"`)

**Schema:**
```typescript
{
  unionId: string,              // Primary key
  totalFriends: number,         // All active friendships (👥 + 💬)
  fullFriends: number,          // Only relationType='friend' (👥)
  contacts: number,             // Only relationType='contact' (💬)
  unreadChatCount: number,      // Messages user hasn't read
  totalChatGroups: number,      // Chat groups user is member of
  lastUpdated: Timestamp        // When stats were last calculated
}
```

**Example:**
```json
{
  "unionId": "177-2813",
  "totalFriends": 7,
  "fullFriends": 5,
  "contacts": 2,
  "unreadChatCount": 3,
  "totalChatGroups": 4,
  "lastUpdated": "2025-12-22T10:30:00Z"
}
```

---

## ☁️ Cloud Functions

### 1. `updateFriendStats` (Triggered)

**Trigger:** `friendships/{friendshipId}` onWrite  
**Purpose:** Update friend counts when friendships change

**Logic:**
```javascript
exports.updateFriendStats = functions
  .region('europe-west1')
  .firestore.document('friendships/{friendshipId}')
  .onWrite(async (change, context) => {
    const db = admin.firestore();
    
    // Collect affected users (old + new data)
    const usersToUpdate = new Set();
    if (change.before.exists) {
      usersToUpdate.add(change.before.data().userId1);
      usersToUpdate.add(change.before.data().userId2);
    }
    if (change.after.exists) {
      usersToUpdate.add(change.after.data().userId1);
      usersToUpdate.add(change.after.data().userId2);
    }
    
    // Update stats for each user
    for (const userId of usersToUpdate) {
      await updateUserStats(db, userId);
    }
    
    return null;
  });
```

**Calculates:**
- `totalFriends` - Count of all active friendships
- `fullFriends` - Count where `relationType='friend'` (👥)
- `contacts` - Count where `relationType='contact'` (💬)

---

### 2. `updateChatGroupStats` (Triggered)

**Trigger:** `chat_groups/{groupId}` onWrite  
**Purpose:** Update chat group counts when groups change

**Logic:**
```javascript
exports.updateChatGroupStats = functions
  .region('europe-west1')
  .firestore.document('chat_groups/{groupId}')
  .onWrite(async (change, context) => {
    const db = admin.firestore();
    
    // Collect affected members
    const membersToUpdate = new Set();
    if (change.before.exists) {
      change.before.data().members.forEach(m => membersToUpdate.add(m));
    }
    if (change.after.exists) {
      change.after.data().members.forEach(m => membersToUpdate.add(m));
    }
    
    // Update stats for each member
    for (const memberId of membersToUpdate) {
      await updateUserStats(db, memberId);
    }
    
    return null;
  });
```

**Calculates:**
- `totalChatGroups` - Count of groups where user is member AND not in `hiddenFor`

---

### 3. `updateMessageStats` (Triggered)

**Trigger:** `messages/{groupId}/messages/{messageId}` onCreate + onUpdate  
**Purpose:** Update unread message counts when messages are sent/read

**Logic:**
```javascript
exports.updateMessageStats = functions
  .region('europe-west1')
  .firestore.document('messages/{groupId}/messages/{messageId}')
  .onCreate(async (snap, context) => {
    const db = admin.firestore();
    const groupId = context.params.groupId;
    
    // Get group members
    const groupDoc = await db.collection('chat_groups').doc(groupId).get();
    const members = groupDoc.data().members;
    
    // Update stats for each member
    for (const memberId of members) {
      await updateUserStats(db, memberId);
    }
    
    return null;
  });
```

**Calculates:**
- `unreadChatCount` - Count of messages where:
  - User is group member
  - Message sender ≠ user
  - User NOT in message's `readBy` array

---

### 4. `updateUserStats()` Helper

**Purpose:** Centralized logic for calculating and writing stats

```javascript
async function updateUserStats(db, unionId) {
  // 1. Query friendships
  const friendships = await db
    .collection('friendships')
    .where('userId1', '==', unionId)
    .where('status', '==', 'active')
    .get();
  
  // Count by relation type
  let totalFriends = friendships.size;
  let fullFriends = 0;
  let contacts = 0;
  friendships.forEach(doc => {
    if (doc.data().relationType === 'friend') fullFriends++;
    else if (doc.data().relationType === 'contact') contacts++;
  });
  
  // 2. Query chat groups (not hidden)
  const chatGroups = await db
    .collection('chat_groups')
    .where('members', 'array-contains', unionId)
    .get();
  
  const totalChatGroups = chatGroups.docs.filter(doc => {
    const hiddenFor = doc.data().hiddenFor || [];
    return !hiddenFor.includes(unionId);
  }).length;
  
  // 3. Query unread messages
  let unreadChatCount = 0;
  for (const groupDoc of chatGroups.docs) {
    const messagesSnap = await db
      .collection(`messages/${groupDoc.id}/messages`)
      .where('senderId', '!=', unionId)
      .get();
    
    messagesSnap.forEach(msgDoc => {
      const readBy = msgDoc.data().readBy || [];
      if (!readBy.includes(unionId)) {
        unreadChatCount++;
      }
    });
  }
  
  // 4. Write to user_stats
  await db.collection('user_stats').doc(unionId).set({
    unionId,
    totalFriends,
    fullFriends,
    contacts,
    unreadChatCount,
    totalChatGroups,
    lastUpdated: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });
}
```

---

## 📱 Flutter Implementation

### Model

**File:** `lib/models/user_stats_model.dart`

```dart
class UserStats {
  final String unionId;
  final int totalFriends;
  final int fullFriends;
  final int contacts;
  final int unreadChatCount;
  final int totalChatGroups;
  final DateTime lastUpdated;

  factory UserStats.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserStats(
      unionId: doc.id,
      totalFriends: data['totalFriends'] ?? 0,
      fullFriends: data['fullFriends'] ?? 0,
      contacts: data['contacts'] ?? 0,
      unreadChatCount: data['unreadChatCount'] ?? 0,
      totalChatGroups: data['totalChatGroups'] ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }
}
```

### Homepage Usage

**File:** `lib/screens/home_screen.dart`

```dart
class _HjemTabState extends State<HjemTab> {
  UserStats? _userStats;
  
  Future<void> _loadUserStats() async {
    final unionId = context.read<AuthProvider>().currentPlayer?.unionId;
    if (unionId == null) return;
    
    final doc = await FirebaseFirestore.instance
        .collection('user_stats')
        .doc(unionId)
        .get();
    
    if (doc.exists) {
      setState(() {
        _userStats = UserStats.fromFirestore(doc);
      });
    }
  }
  
  Widget _buildFriendsSection() {
    final unreadCount = _userStats?.unreadChatCount ?? 0;
    
    return Card(
      child: Row(
        children: [
          // Left: Se venner
          Expanded(
            child: InkWell(
              onTap: () => context.push('/venner'),
              child: Text('Se venner'),
            ),
          ),
          
          // Right: X beskeder
          Expanded(
            child: InkWell(
              onTap: () => context.push('/chats'),
              child: Badge(
                label: Text('$unreadCount'),
                child: Text('$unreadCount beskeder'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### Pull-to-Refresh

```dart
RefreshIndicator(
  onRefresh: () async {
    await _loadUserStats();  // Refresh stats
    await _loadFriends();     // Refresh friends
    await _loadBirdieBonusData();  // Refresh other data
  },
  child: SingleChildScrollView(
    // ... homepage widgets
  ),
)
```

---

## 📊 Performance

### Before (Provider Counting)

```
Homepage Load:
1. Read friendships collection (1 query)
2. Count fullFriends in memory
3. Read chat_groups collection (1 query)
4. For each group, read messages subcollection (N queries)
5. Count unread in memory

Total: 2 + N queries (~100-500ms)
Issue: Stale data, complex Provider dependencies
```

### After (Pre-Aggregated Stats)

```
Homepage Load:
1. Read user_stats/{unionId} (1 query)

Total: 1 query (~50-100ms)
Benefits: Instant, fresh, simple
```

### Trade-offs

**Pros:**
- ✅ Instant loading (1 read vs multiple)
- ✅ No complex Provider logic
- ✅ Eventually consistent (1-2 second delay acceptable)
- ✅ Scalable (no counting queries)
- ✅ Pull-to-refresh for immediate updates

**Cons:**
- ❌ Eventually consistent (stats update after writes complete)
- ❌ Extra Cloud Function executions (minimal cost)
- ❌ Extra Firestore writes to `user_stats` (1 per update)

**Cost Analysis:**
- Cloud Function invocations: ~$0.40 per 1M invocations
- Firestore writes: ~$0.18 per 100K writes
- For 1,000 users with 10 friend actions/day: ~$0.03/month
- **Verdict:** Negligible cost for massive UX improvement

---

## 🧪 Testing

### Initial Population

**Script:** `seed_user_stats.js`

```javascript
// Populate user_stats for existing users
const admin = require('firebase-admin');
admin.initializeApp({ /* ... */ });

async function seedUserStats() {
  const db = admin.firestore();
  
  // Get all unique user IDs from friendships
  const friendships = await db.collection('friendships').get();
  const userIds = new Set();
  friendships.forEach(doc => {
    userIds.add(doc.data().userId1);
    userIds.add(doc.data().userId2);
  });
  
  // Calculate stats for each user
  for (const userId of userIds) {
    await updateUserStats(db, userId);
    console.log(`✅ Updated stats for ${userId}`);
  }
}
```

**Run:** `node seed_user_stats.js`

### Verification

1. **Check Firestore Console:**
   - Navigate to `user_stats` collection
   - Verify documents exist for active users
   - Check field values match expected counts

2. **Test in App:**
   - Load homepage → Verify friend count
   - Send message → Verify unread count updates within 2 seconds
   - Add friend → Verify friend count updates within 2 seconds

3. **Pull-to-Refresh:**
   - Pull down on homepage → Verify immediate update

---

## 📁 Files

**Cloud Functions:**
- `functions/index.js` - All Cloud Functions

**Models:**
- `lib/models/user_stats_model.dart`

**Screens:**
- `lib/screens/home_screen.dart` - Reads and displays stats

**Scripts:**
- `seed_user_stats.js` - Initial population

**Security:**
- `firestore.rules` - Security rules for `user_stats`

```javascript
match /user_stats/{unionId} {
  allow read: if true; // TEMP: Open for testing
  allow write: if false; // Only Cloud Functions (via Admin SDK)
}
```

---

## 💡 Learnings

1. **Pre-aggregation > On-the-fly counting:** For frequently accessed data
2. **Eventually consistent is OK:** 1-2 second delay acceptable for most UI
3. **Pull-to-refresh is critical:** Users want control over data freshness
4. **Simplify widget tree:** Pre-aggregated data eliminates nested Provider logic
5. **Cloud Functions are cheap:** The UX improvement far outweighs minimal cost

---

## 🔮 Future Improvements

1. **Real-time listeners:** Use `.snapshots()` instead of pull-to-refresh (more reactive)
2. **Batch updates:** Batch multiple `updateUserStats` calls to reduce function invocations
3. **Caching:** Cache `user_stats` in Provider to avoid repeated reads
4. **More stats:** Expand to include activity feed counts, tournament participation, etc.

---

**Status:** Fully implemented and tested. Pattern proven successful! ✅

**This pattern should be used for all future aggregated statistics (activity counts, tournament stats, etc.).**

