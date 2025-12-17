# OAuth 2.0 PKCE Implementation - Lessons Learned

> **Context**: Flutter Web POC implementation of GolfBox OAuth 2.0 with PKCE.
> Built by amateur developer (customer/product owner) with Cursor AI assistance.
> 
> This documents the complete debugging journey, errors encountered, and solutions found.
> **Purpose**: Save future developers (including ourselves) from repeating this painful debugging process.

---

## 1. Implementation Overview

### 1.1 What We Built
- OAuth 2.0 PKCE flow for Flutter Web
- Cloud Function relay for callback handling
- Token exchange proxy (CORS workaround)
- Persistent login with token + unionId storage
- DGU-nummer input post-OAuth (API limitation)

### 1.2 Architecture

```
User clicks "Log ind med DGU"
    ↓
Flutter generates PKCE (code_verifier + code_challenge)
    ↓
Redirect to: auth.golfbox.io/connect/authorize
    ↓
User logs in (GolfBox credentials)
    ↓
Redirect to: europe-west1-dgu-scorekort.cloudfunctions.net/golfboxCallback
    ↓ (relay)
Cloud Function → Redirect back to app with code + state
    ↓
Flutter: exchangeCodeForToken (via Cloud Function proxy)
    ↓
Token stored → Ask for DGU-nummer → Fetch player data (Basic Auth)
    ↓
Persistent login (token + unionId in SharedPreferences)
```

### 1.3 Key Design Decisions

**Decision 1: Cloud Function Callback Relay**
- **Why**: OAuth redirect URI must be HTTPS with valid domain
- **What**: `golfboxCallback` receives callback, relays to app
- **Tradeoff**: Extra hop, but enables web deployment

**Decision 2: Token Exchange via Cloud Function**
- **Why**: CORS blocks direct browser → auth.golfbox.io token exchange
- **What**: `exchangeOAuthToken` proxies the POST request
- **Alternative Tried**: Direct HTTP from Flutter (failed due to CORS)

**Decision 3: DGU-nummer Manual Input**
- **Why**: OAuth response doesn't include unionId/DGU-nummer
- **What**: Prompt user after OAuth success
- **Limitation**: Can't validate against OAuth user (yet)

---

## 2. Critical Errors Encountered

### Error #1: "Invalid state parameter (not valid base64 or JSON)"

**What Happened:**
```
golfboxCallback Cloud Function rejected callback
Error: "Bad Request: Invalid state parameter"
```

**Root Cause:**
- Cloud Function expected `state` to be base64-encoded JSON with `targetUrl`
- Flutter sent simple base64-encoded `code_verifier` string
- Function tried to parse as JSON → crash

**Initial Code (BROKEN):**
```javascript
// golfboxCallback expected this format:
const state = JSON.parse(base64Decode(queryParams.state));
const targetUrl = state.targetUrl; // CRASH - state is string, not object
```

**Solution:**
```javascript
// Simplified to not parse state as JSON
// Use referer header or default URL instead
const code = queryParams.code;
const state = queryParams.state; // Keep as-is, don't parse
const targetUrl = 'https://dgu-app-poc.web.app/login'; // Default
```

**Lesson:**
- Keep state parameter simple (base64 string is enough)
- Don't over-engineer early - add complexity only when needed
- Document expected format clearly

---

### Error #2: "Unauthorized redirect URL"

**What Happened:**
```
golfboxCallback returned 400 Bad Request
"Unauthorized redirect URL"
```

**Root Cause:**
- `ALLOW_LIST` in Cloud Function didn't include POC URL
- Only had: `http://localhost`, `https://dgu-scorekort.web.app`
- Missing: `https://dgu-app-poc.web.app`

**Solution:**
```javascript
const ALLOW_LIST = [
  'http://localhost',
  'https://dgu-scorekort.web.app',
  'https://dgu-app-poc.web.app', // ADDED
];
```

**Lesson:**
- Maintain allowlist for all deployment URLs
- Consider wildcard subdomain matching for flexibility
- Log rejected URLs for easier debugging

---

### Error #3: CORS Error on Token Exchange

**What Happened:**
```
ClientException: Failed to fetch
uri=https://auth.golfbox.io/connect/token
```

**Root Cause:**
- Browser blocks direct POST to auth.golfbox.io (CORS policy)
- auth.golfbox.io doesn't set CORS headers for browser requests
- This is standard OAuth security (server-side token exchange only)

**Initial Solution Attempt (FAILED):**
```dart
// Direct HTTP from Flutter Web
final response = await http.post(
  Uri.parse('https://auth.golfbox.io/connect/token'),
  // ... CORS blocked!
);
```

**Final Solution:**
```dart
// Client-side: Call Cloud Function proxy
final response = await http.post(
  Uri.parse('https://europe-west1-dgu-scorekort.cloudfunctions.net/exchangeOAuthToken'),
  body: json.encode({'code': code, 'codeVerifier': codeVerifier}),
);

// Server-side: Cloud Function makes actual token exchange
exports.exchangeOAuthToken = functions.https.onCall(async (data) => {
  const response = await axios.post('https://auth.golfbox.io/connect/token', ...);
  return response.data;
});
```

**Lesson:**
- OAuth token exchange MUST be server-side for web apps
- Cloud Functions = perfect CORS proxy
- Don't fight browser security - work with it

---

### Error #4: "Int64 accessor not supported by dart2js"

**What Happened:**
```
Unsupported operation: Int64 accessor not supported by dart2js
```

**Root Cause:**
- `exchangeOAuthToken` returned `expires_in` as Int64 type
- Node.js uses 64-bit integers natively
- Flutter Web (dart2js) can't deserialize Int64 from JSON

**Initial Code (BROKEN):**
```javascript
return {
  success: true,
  access_token: response.data.access_token,
  expires_in: response.data.expires_in, // Int64!
};
```

**Solution:**
```javascript
// Explicitly convert to standard Number
const expiresIn = parseInt(response.data.expires_in, 10);
return {
  success: true,
  access_token: String(response.data.access_token),
  token_type: String(response.data.token_type),
  expires_in: expiresIn, // Now a regular number
  scope: String(response.data.scope)
};
```

**Lesson:**
- **Always explicitly convert types** in Cloud Functions returning to Flutter Web
- Use `parseInt()`, `String()`, `Number()` for safety
- Return only needed fields (avoid passing through entire API response)

---

### Error #5: Authorization Code Reuse on Page Refresh

**What Happened:**
```
Token exchange failed: invalid_grant
"Authorization code has already been used"
```

**Root Cause:**
- After successful OAuth, URL still had `?code=xxx&state=yyy`
- User refreshed page → App tried to reuse one-time code → Failed

**Solution:**
```dart
// After successful OAuth, clean URL
if (kIsWeb) {
  final uri = Uri.parse(html.window.location.href);
  final cleanUri = uri.replace(queryParameters: {}, fragment: '');
  html.window.history.replaceState({}, '', cleanUri.toString());
}
```

**Lesson:**
- OAuth codes are **one-time use only**
- Clean URL parameters after consuming them
- Use `replaceState()` not `pushState()` (no back button issues)

---

### Error #6: cloud_functions SDK vs Direct HTTP

**What Happened:**
```
// Using cloud_functions package:
final callable = FirebaseFunctions.instanceFor(region: 'europe-west1')
    .httpsCallable('exchangeOAuthToken');
final result = await callable.call({'code': code, 'codeVerifier': verifier});
// Still got Int64 errors despite server-side conversion!
```

**Root Cause:**
- `cloud_functions` Flutter package has its own deserialization
- May still try to deserialize Int64 even if server converts
- SDK adds wrapper complexity

**Solution:**
```dart
// Bypass SDK, use direct HTTP POST
final url = Uri.parse(
  'https://europe-west1-dgu-scorekort.cloudfunctions.net/exchangeOAuthToken'
);
final response = await http.post(
  url,
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'data': {'code': code, 'codeVerifier': codeVerifier}
  }),
);
final data = json.decode(response.body);
```

**Lesson:**
- When SDK causes issues, try direct HTTP
- Cloud Functions work fine via direct HTTP POST
- Adds one extra `data` wrapper layer

---

## 3. Flutter Web Specific Challenges

### Challenge: dart2js Number Limitations
- No Int64 support (only 53-bit precision in JavaScript)
- Solution: Convert all large numbers to String on server

### Challenge: CORS Everything
- Can't call external APIs directly from browser
- Solution: Proxy ALL external APIs through Cloud Functions

### Challenge: URL State Management
- OAuth parameters stay in URL after callback
- Solution: Clean with `history.replaceState()`

### Challenge: SharedPreferences Persistence
- Works across sessions (good for persistent login)
- Need explicit `clearAuth()` on logout

---

## 4. Best Practices Discovered

### 4.1 Cloud Function Design

**golfboxCallback (Relay):**
```javascript
✅ DO:
- Validate code and state exist
- Check targetUrl against allowlist
- Simple redirect (302)
- Extensive logging for debugging

❌ DON'T:
- Parse complex state formats
- Make additional API calls
- Store session data
- Trust referer header completely
```

**exchangeOAuthToken (Proxy):**
```javascript
✅ DO:
- Explicitly convert all types (String, Number)
- Return only needed fields
- Set timeout (25s recommended)
- Detailed error logging
- Handle both 200 and error responses

❌ DON'T:
- Pass through raw API response
- Rely on auto-serialization
- Use short timeouts (<10s)
- Return sensitive debugging info to client
```

### 4.2 Flutter Client Design

**Auth Flow:**
```dart
✅ DO:
- Store both token AND unionId for persistent login
- Clean URL after OAuth callback
- Use direct HTTP for Cloud Functions (avoid SDK issues)
- Implement logout that clears ALL stored data
- Add loading states everywhere

❌ DON'T:
- Trust cloud_functions SDK for complex types
- Leave OAuth params in URL
- Forget to handle errors gracefully
- Skip URL cleanup
```

### 4.3 Debugging Strategies

**When stuck:**
1. Check Cloud Function logs FIRST
   ```bash
   firebase functions:log --only exchangeOAuthToken | tail -50
   ```

2. Add console.log EVERYWHERE in Cloud Functions
   ```javascript
   console.log('📥 Input:', JSON.stringify(data));
   console.log('📦 Response:', JSON.stringify(response.data));
   console.log('✅ Converted:', typeof expiresIn, expiresIn);
   ```

3. Test Cloud Function directly (bypass Flutter)
   ```bash
   curl -X POST https://...exchangeOAuthToken \
     -H "Content-Type: application/json" \
     -d '{"data":{"code":"test","codeVerifier":"test"}}'
   ```

4. Use incognito for fresh OAuth session
   - Avoids cached tokens
   - Clean slate for testing

---

## 5. Current Limitations & Known Issues

### 5.1 DGU-nummer Not in OAuth Response
- Must ask user manually after OAuth
- Can't validate match with OAuth user
- Future: GolfBox may add unionId to token claims

### 5.2 Persistent Sessions After Logout
- Browser may cache OAuth session
- Workaround: Incognito or clear browser data
- Future: Implement explicit session termination

### 5.3 Development Workflow
- OAuth popup interrupts rapid testing
- Solution: `useSimpleLogin` toggle for development
- Production: OAuth only

---

## 6. Timeline & Effort

**Total Implementation Time:** ~3-4 days
- Initial OAuth setup: 4 hours
- CORS debugging: 6 hours (!)
- Int64 error fixing: 4 hours (!)
- URL cleanup: 1 hour
- UX improvements: 2 hours
- Documentation: 2 hours

**Most Time-Consuming Issues:**
1. CORS (didn't realize token exchange must be server-side)
2. Int64 (obscure dart2js limitation)
3. State parameter parsing (over-engineered initially)

**What Would We Do Differently:**
- Start with Cloud Function proxy from day 1 (avoid CORS struggle)
- Explicitly convert ALL types in Cloud Functions immediately
- Keep state parameter simple (base64 string, nothing fancy)
- Test with incognito from start (avoid cache confusion)

---

## 7. Files & Code References

### Core Files
- `lib/services/auth_service.dart` - PKCE generation, token exchange
- `lib/providers/auth_provider.dart` - Auth state, persistent login
- `lib/screens/login_screen.dart` - OAuth UI, URL cleanup
- `lib/config/auth_config.dart` - OAuth configuration
- `functions/index.js` - golfboxCallback + exchangeOAuthToken

### Key Code Snippets

**PKCE Generation:**
```dart
String generateCodeVerifier() {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(64, (i) => charset[random.nextInt(charset.length)]).join();
}

String generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64Url.encode(digest.bytes).replaceAll('=', '');
}
```

**Token Exchange (Working Version):**
```dart
Future<String> exchangeCodeForToken(String code, String codeVerifier) async {
  final url = Uri.parse(
    'https://europe-west1-dgu-scorekort.cloudfunctions.net/exchangeOAuthToken'
  );
  
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: json.encode({
      'data': {'code': code, 'codeVerifier': codeVerifier}
    }),
  );
  
  if (response.statusCode == 200) {
    final data = json.decode(response.body)['result'];
    return data['access_token'];
  }
  throw Exception('Token exchange failed');
}
```

---

## 8. Lessons for Future OAuth Implementations

### Critical Success Factors
1. ✅ Server-side token exchange (Cloud Function)
2. ✅ Explicit type conversion in Cloud Functions
3. ✅ Simple state parameter (don't over-engineer)
4. ✅ URL cleanup after callback
5. ✅ Extensive logging everywhere

### Red Flags to Watch For
- 🚩 "CORS error" → Need Cloud Function proxy
- 🚩 "Int64 accessor" → Explicit type conversion needed
- 🚩 "Invalid grant" → Code reuse, clean URL
- 🚩 "Invalid state" → State format mismatch
- 🚩 Logout doesn't work → Clear ALL storage + URL

### Questions to Ask Early
- "Does the API return unionId/identifier?" (If no, plan manual input)
- "Will this run in browser?" (If yes, plan CORS proxies)
- "What number types does API return?" (Plan conversions)
- "How long is token valid?" (Plan refresh strategy)

---

## 9. Testing Checklist

### OAuth Flow Testing
- [ ] Fresh browser (incognito) - Complete OAuth flow
- [ ] After successful login - URL cleaned, no params
- [ ] Close and reopen - Persistent login works
- [ ] Logout - Returns to login screen
- [ ] Different DGU-nummer - Can test multiple users
- [ ] Page refresh after OAuth - No "invalid grant" error
- [ ] Network error during token exchange - Graceful error
- [ ] Invalid code - Proper error message

### Edge Cases
- [ ] Extremely long OAuth session - Token still works
- [ ] User denies OAuth - Proper error handling
- [ ] Network drops mid-OAuth - Can retry
- [ ] Multiple tabs - No conflicts
- [ ] Browser back button - Doesn't break flow

---

## 10. Contact & Support

**GolfBox OAuth Documentation:**
- https://auth.golfbox.io/.well-known/openid-configuration

**Our Implementation:**
- Developer: Nick Hüttel (with Cursor AI)
- Timeline: December 2024
- Status: Production-ready for POC

**Questions?**
- Check Cloud Function logs first
- Review this document
- Test in incognito mode
- Check README.md OAuth section

---

**Document Created:** December 17, 2024  
**Last Updated:** December 17, 2024  
**Status:** Complete OAuth 2.0 PKCE implementation with persistent login

