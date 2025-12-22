# Contact vs. Friend System

**Implementeret:** December 22, 2025  
**Version:** 2.0 Extended POC

---

## 🎯 Purpose

Enable different levels of connection for different social needs:
- **Kontakt (💬):** For tee-time partners and casual golf contacts
- **Ven (👥):** For real friends you track handicap progress with

## 📊 Comparison Table

| Feature | Kontakt (💬) | Ven (👥) |
|---------|-------------|---------|
| **Chat** | ✅ Yes | ✅ Yes |
| **Plan Rounds** | ✅ Yes | ✅ Yes |
| **See Handicap** | ❌ No | ✅ Yes |
| **See Trends** | ❌ No | ✅ Yes |
| **See Recent Scores** | ❌ No | ✅ Yes |
| **Appears in Homepage Stats** | ❌ No | ✅ Yes |
| **Privacy Settings** | ❌ Not listed | ✅ Listed |
| **Badge Count** | ❌ No | ✅ Yes |

## 🔄 Friend Request Flow

1. **Sender:** Opens "Tilføj Ven" dialog, enters DGU number
2. **System:** Fetches player info, shows preview
3. **Sender:** Presented with choice dialog:
   - "Kontakt (💬) - Chat om golf"
   - "Ven (👥) - Del handicap"
4. **System:** Sends notification to "Mit Golf" app with appropriate consent message
5. **Receiver:** Opens deep link, sees consent screen with dynamic message:
   - Kontakt: "vil gerne chatte med dig om golf"
   - Ven: "vil følge dit handicap"
6. **Receiver:** Accepts → Friendship created with `relationType`
7. **System:** Both users see each other in appropriate tab

## 🗂️ Data Model

### Friendship

```dart
class Friendship {
  final String userId1;
  final String userId2;
  final String relationType; // 'contact' | 'friend'
  final DateTime createdAt;
  final String status; // 'active' | 'pending' | 'removed'
  final bool consent; // Always true for active friendships
}
```

### FriendRequest

```dart
class FriendRequest {
  final String fromUserId;
  final String toUserId;
  final String requestedRelationType; // 'contact' | 'friend'
  final String consentMessage;
  final DateTime createdAt;
  final String status; // 'pending' | 'accepted' | 'declined' | 'expired'
}
```

## 🎨 UI Implementation

### Friends List Screen Tabs

**Tab 1: Venner 👥**
- Shows only `friendsProvider.fullFriends` (relationType='friend')
- Displays handicap badges
- Shows relation icon: 👥
- Empty state: "Ingen venner endnu - Tilføj venner for at følge deres handicap"

**Tab 2: Kontakter 💬**
- Shows only `friendsProvider.contactsOnly` (relationType='contact')
- NO handicap displayed
- Shows relation icon: 💬
- Empty state: "Ingen kontakter endnu - Tilføj kontakter for at kunne chatte"

**Tab 3: Anmodninger**
- Shows pending incoming requests
- Badge with count if > 0
- Empty state: "Ingen anmodninger"

### Homepage Integration

**"Mine Venner & Chats" Widget:**
- Left button: "Se venner" (no count)
- Right button: "X beskeder" with unread badge
- Uses `user_stats.fullFriends` for friend count (only 👥, not 💬)

### Privacy Settings

**"Personer der kan se dit handicap":**
- Lists only `friendsProvider.fullFriends` (👥)
- Contacts (💬) are NOT shown
- Reason: Contacts have no handicap visibility by design

## 🔐 Security & Privacy

### Firestore Rules

```javascript
match /friendships/{friendshipId} {
  allow read: if isAuthenticated() && 
    (resource.data.userId1 == request.auth.token.unionId || 
     resource.data.userId2 == request.auth.token.unionId);
  allow create: if isAuthenticated();
  allow update, delete: if isAuthenticated() && 
    (resource.data.userId1 == request.auth.token.unionId || 
     resource.data.userId2 == request.auth.token.unionId);
}
```

### Data Visibility

**Contacts (💬):**
- Can see: Name, home club
- Cannot see: Handicap, trends, scores

**Friends (👥):**
- Can see: Name, home club, handicap, trends, scores
- Requires: Active friendship with `relationType='friend'`

## 📁 Relevant Files

**Models:**
- `lib/models/friendship_model.dart`
- `lib/models/friend_request_model.dart`
- `lib/models/friend_profile_model.dart`

**Providers:**
- `lib/providers/friends_provider.dart`
  - `.fullFriends` getter (👥 only)
  - `.contactsOnly` getter (💬 only)
  - `.getFriendship()` helper

**Services:**
- `lib/services/friends_service.dart`
  - `sendFriendRequest(requestedRelationType)`
  - `acceptFriendRequest()`

**Screens:**
- `lib/screens/friends_list_screen.dart` - Tabs
- `lib/screens/friend_detail_screen.dart` - Only shows full info for 👥
- `lib/screens/friend_request_from_url_screen.dart` - Dynamic consent
- `lib/screens/friend_request_success_screen.dart` - Dynamic success message
- `lib/screens/privacy_settings_screen.dart` - Filtered list
- `lib/widgets/add_friend_dialog.dart` - Relation type selection

**Backend:**
- `functions/index.js` - `updateFriendStats` (calculates fullFriends vs contacts)
- `firestore.rules` - Security rules

## 🧪 Testing

**Test Accounts:**
- 177-2813 (Nick) - Main test account
- 8-9994 (Mit Golf Tester) - Friend (👥)
- 8-9995 (Test Mellemnavn) - Friend (👥)
- 8-9997 (Test II App) - Contact (💬)
- 16-2553 (Søren Hvid) - Contact (💬)

**Test Scenarios:**
1. ✅ Create contact → Check privacy settings (should NOT appear)
2. ✅ Create friend → Check privacy settings (should appear)
3. ✅ Create contact → Check homepage count (should NOT count)
4. ✅ Create friend → Check homepage count (should count)
5. ✅ View friend detail → Should show handicap
6. ✅ View contact detail → Should NOT show handicap
7. ✅ Create chat with contact → Should work
8. ✅ Create chat with friend → Should work

---

## 💡 Learnings

1. **Backward Compatibility:** Default `relationType='friend'` ensures existing friendships work
2. **UI Clarity:** Icons (💬 vs 👥) make distinction immediately obvious
3. **Privacy First:** Contacts excluded from privacy settings by design
4. **Flexible:** Can change relation type in future (upgrade contact → friend)
5. **Clean Separation:** `.fullFriends` and `.contactsOnly` getters keep logic simple

---

**Status:** Fully implemented and tested. Production ready! ✅

