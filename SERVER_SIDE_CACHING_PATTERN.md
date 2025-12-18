# Server-Side Caching Pattern

**Date:** December 2025  
**App:** DGU Scorekort v2.0 POC

## 🎯 The Unique Pattern

This app uses a **consistent server-side caching pattern** for ALL external API integrations. This pattern solves multiple problems simultaneously:

1. ✅ **CORS issues** (browser security restrictions)
2. ✅ **Performance** (instant loading from cache)
3. ✅ **Rate limiting** (controlled server-side)
4. ✅ **Cost efficiency** (data fetched once, served to many users)
5. ✅ **Reliability** (cached data always available)

---

## 🏗️ Architecture

```
External API (Golf.dk, DGU, Statistik)
    ↓ (nightly scheduled fetch)
Cloud Function (Node.js, server-side)
    ↓ (Firestore batch writes)
Firestore Cache (single source of truth)
    ↓ (Source.server forced read)
Flutter Service (client-side)
    ↓ (Provider/Widget consumption)
Flutter UI (instant rendering)
```

---

## 📊 Implementations

### 1. **Birdie Bonus** (04:00 CET daily)
- **Source:** `https://api.danskgolfunion.dk/birdiebonus`
- **Cloud Function:** `cacheBirdieBonusData`
- **Firestore:** `birdie_bonus_cache/{dguNumber}`
- **Flutter Service:** `BirdieBonusService.getParticipantData()`
- **Widgets:** `BirdieBonusBar` (conditional rendering)

### 2. **Course Cache** (02:00 CET daily)
- **Source:** `https://dgubasen.api.union.golfbox.io/DGUScorkortAapp/Courses`
- **Cloud Function:** `updateCourseCache`
- **Firestore:** `course-cache-clubs`, `course-cache-metadata`
- **Flutter Service:** `CourseCacheService.getClubs()`
- **Widgets:** Course selection dropdowns

### 3. **Tournaments & Rankings** (02:30 CET daily)
- **Sources:**
  - Tournaments: `https://drupal.golf.dk/rest/taxonomy_lists/current_tournaments`
  - Rankings: `https://drupal.golf.dk/rest/taxonomy_lists/rankings`
  - Icons: `https://drupal.golf.dk/media/{iconId}/edit`
- **Cloud Function:** `cacheTournamentsAndRankings`
- **Firestore:**
  - `tournaments_cache/current`
  - `rankings_cache/current`
  - `tournament_icons_cache/{iconId}`
- **Flutter Service:** `GolfEventsService.getCurrentTournaments()`
- **Widgets:** `_TournamentsWidget`, `_RankingsWidget`
- **Special:** HTML `<img>` tags to bypass CORS for images

### 4. **WHS Scores** (on-demand)
- **Source:** `https://api.danskgolfunion.dk/statistik/players/{unionId}/scores`
- **Cloud Function:** `getWhsScores` (callable)
- **Firestore:** `user_score_cache/{unionId}` (optional caching)
- **Flutter Service:** `WhsStatistikService.fetchScores()`
- **Widgets:** `_MineSenesteScoresWidget`

---

## 🔑 Key Principles

### 1. **Server-Side Fetching**
```javascript
// Cloud Function (Node.js)
https.get(API_URL, {
  headers: {
    'Authorization': authToken,
    'Accept': 'application/json'
  }
}, (res) => {
  // Process response server-side
  // No CORS issues!
});
```

**Why?**
- Node.js is NOT subject to CORS
- Can add auth headers without exposing tokens
- Can transform/normalize data before caching

### 2. **Firestore as Cache Layer**
```javascript
// Write to Firestore
await db.collection('cache_name').doc('document_id').set({
  data: processedData,
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  count: data.length
});
```

**Why?**
- Single source of truth
- Real-time updates possible
- Built-in security rules
- Automatic indexing

### 3. **Forced Server Reads**
```dart
// Flutter Service
final doc = await _firestore
    .collection('cache_name')
    .doc('document_id')
    .get(const GetOptions(source: Source.server)); // ← Force fresh!
```

**Why?**
- Bypass Firestore client-side cache
- Always get latest nightly data
- Avoid stale data issues
- Max 24-hour delay acceptable

### 4. **Scheduled Execution**
```javascript
exports.cacheFunction = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 540,
    memory: '512MB'
  })
  .pubsub.schedule('30 2 * * *') // 02:30 CET daily
  .timeZone('Europe/Copenhagen')
  .onRun(async (context) => {
    // Fetch and cache data
  });
```

**Why?**
- Runs during low-traffic hours
- Data ready when users wake up
- Controlled execution window
- Predictable resource usage

---

## 🚨 Special Case: CORS for Images

**Problem:**
```dart
// Flutter Web: Image.network() uses XMLHttpRequest
Image.network('https://drupal.golf.dk/.../icon.jpg')
// ❌ BLOCKED by CORS policy
```

**Solution:**
```dart
// Use HTML <img> tag via HtmlElementView
ui_web.platformViewRegistry.registerViewFactory(
  viewType,
  (int viewId) {
    final img = html.ImageElement()
      ..src = imageUrl
      ..style.objectFit = 'cover';
    return img;
  },
);

return HtmlElementView(viewType: viewType);
// ✅ HTML <img> tags are NOT subject to CORS
```

**Why This Works:**
- HTML `<img>` tags can load images from ANY domain
- XMLHttpRequest/Fetch API are subject to CORS
- Flutter Web's `Image.network()` uses XMLHttpRequest
- `HtmlElementView` embeds raw HTML → bypasses CORS

**Implementation:**
- Cache icon URLs in Firestore (not images)
- Use `HtmlElementView` to display images
- Browser caches images automatically
- No storage costs (images served by Golf.dk)

---

## 📈 Benefits

### Performance
- ⚡ **Instant loading** - No API latency
- 🚀 **Scalable** - 1000 users = 1 API call (not 1000)
- 💾 **Efficient** - Data fetched once per night

### Reliability
- ✅ **Always available** - Cached data even if API down
- 🔒 **Consistent** - All users see same data
- 🕐 **Predictable** - Max 24-hour delay

### Cost
- 💰 **Low bandwidth** - Users read from Firestore, not external APIs
- 📉 **Rate limit friendly** - 1 request per night vs. per user
- 🎯 **No proxy costs** - Direct from cache

### Security
- 🔐 **Token safety** - Auth tokens never exposed to browser
- 🛡️ **CORS solved** - Server-side fetching bypasses CORS
- 🔒 **Security rules** - Firestore rules control access

---

## 🎓 Lessons Learned

### 1. **Always Force Server Reads**
```dart
// ❌ BAD: May return stale client cache
.get()

// ✅ GOOD: Always gets latest server data
.get(const GetOptions(source: Source.server))
```

### 2. **Use Batch Writes for Efficiency**
```javascript
// For multiple documents (e.g., icons)
const batch = db.batch();
for (const [id, data] of entries) {
  batch.set(db.collection('cache').doc(id), data);
}
await batch.commit();
```

### 3. **HTML Images Bypass CORS**
```dart
// For external images without CORS headers
// Use HtmlElementView + <img> tag
// NOT Image.network()
```

### 4. **Log Everything**
```javascript
console.log('🎨 Fetching icons...');
console.log(`  Found ${count} unique IDs`);
console.log(`  ✅ Fetched ${success}/${total} URLs`);
// Makes debugging nightly functions MUCH easier
```

---

## 🔮 Future Considerations

### Option A: Keep Current Pattern
- ✅ Works perfectly for POC
- ✅ Simple to understand
- ✅ Easy to maintain
- ⚠️ 24-hour max delay

### Option B: Add Real-Time Updates
- Use Firestore listeners for instant updates
- Good for: Live scores, real-time leaderboards
- Trade-off: More complex, higher costs

### Option C: Hybrid Approach
- Nightly cache for static data (tournaments, courses)
- Real-time for dynamic data (scores, activities)
- Best of both worlds

---

## 📚 Related Documentation

- `README.md` - Full app documentation
- `BIRDIE_BONUS_FIX_EXPLANATION.md` - Birdie Bonus integration details
- `OAUTH_IMPLEMENTATION_LESSONS.md` - OAuth flow details
- `functions/index.js` - All Cloud Functions source code
- `firestore.rules` - Security rules for cache collections

---

## 🎯 Summary

**This pattern is THE architecture for DGU Scorekort v2.0:**

1. **External API** → Server-side only
2. **Cloud Function** → Scheduled nightly fetch
3. **Firestore** → Single source of truth
4. **Flutter Service** → Force server reads
5. **Flutter UI** → Instant rendering

**Special cases:**
- **Images:** Use HTML `<img>` tags to bypass CORS
- **On-demand:** Use callable functions (e.g., WHS scores)
- **Real-time:** Use Firestore listeners (e.g., activities)

**This pattern solves:**
- ✅ CORS issues
- ✅ Performance bottlenecks
- ✅ Rate limiting
- ✅ Cost efficiency
- ✅ Token security

**It is applied consistently across:**
- Birdie Bonus
- Course cache
- Tournaments & Rankings (+ CORS bypass)
- WHS Scores

---

**Last Updated:** December 18, 2025  
**Author:** Nick Hüttel (with Cursor AI assistance)

