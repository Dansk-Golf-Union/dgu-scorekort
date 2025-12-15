# Push Notification Pattern

## ⚠️ VIGTIG: Flutter Web + Cloud Functions Begrænsning

**Problem:** `cloud_functions` package virker IKKE pålidelig i Flutter Web production builds.

**Løsning:** Brug HTTP endpoints (`onRequest`) i stedet for Callable Functions (`onCall`).

---

## 📤 Flutter → Cloud Function

### Endpoint
```
POST https://europe-west1-dgu-scorekort.cloudfunctions.net/sendNotificationHttp
```

### Headers
```json
{
  "Content-Type": "application/json"
}
```

### Request Body Format

#### Friend Request
```json
{
  "type": "FRIEND_REQUEST",
  "fromUserName": "Mit Golf Tester",
  "toUnionId": "177-2813",
  "requestId": "abc123xyz"
}
```

#### Marker Approval (fremtidig)
```json
{
  "type": "MARKER_APPROVAL",
  "markerUnionId": "177-2813",
  "playerName": "Nick Hüttel",
  "approvalUrl": "https://dgu-app-poc.web.app/marker-approval/xyz789"
}
```

### Response Format

#### Success (200)
```json
{
  "success": true,
  "message": "Notification sent",
  "result": {
    "message": "Messages sent to 1 out of 1 recipients.",
    "success": true
  }
}
```

#### Error (400/500)
```json
{
  "error": "Missing required fields: toUnionId, fromUserName, or requestId"
}
```

---

## 🔧 Implementation

### Flutter Service (Copy-Paste Ready)

```dart
// lib/services/friends_service.dart (eller anden service)

import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendNotification({
  required String type,
  required Map<String, dynamic> data,
}) async {
  try {
    final url = Uri.parse(
      'https://europe-west1-dgu-scorekort.cloudfunctions.net/sendNotificationHttp',
    );
    
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'type': type,
        ...data,  // fromUserName, toUnionId, requestId, etc.
      }),
    );

    if (response.statusCode == 200) {
      print('✅ Notification sent successfully');
    } else {
      print('⚠️ Notification failed: ${response.statusCode}');
      print('   Response: ${response.body}');
    }
  } catch (e) {
    print('⚠️ Failed to send notification: $e');
    // Don't throw - notification is optional
  }
}

// Brug eksempel - Friend Request:
await sendNotification(
  type: 'FRIEND_REQUEST',
  data: {
    'fromUserName': 'Mit Golf Tester',
    'toUnionId': '177-2813',
    'requestId': docRef.id,
  },
);
```

### Cloud Function (Copy-Paste Ready)

**VIGTIGT:** Genbruger `sendNotificationRequest()` helper function.

```javascript
// functions/index.js

/**
 * sendNotificationHttp - HTTP endpoint for notifications
 * 
 * VIGTIGT: Brug denne pattern for alle notifications fra Flutter Web!
 * cloud_functions package virker IKKE pålidelig i production builds.
 */
exports.sendNotificationHttp = functions
  .region('europe-west1')
  .https.onRequest(async (req, res) => {
    // Enable CORS
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type');
    
    // Handle preflight
    if (req.method === 'OPTIONS') {
      res.status(204).send('');
      return;
    }
    
    // Only allow POST
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }
    
    console.log('📤 Push notification HTTP request received');
    
    try {
      const data = req.body;
      const notificationType = data.type || 'MARKER_APPROVAL';
      console.log(`  Type: ${notificationType}`);
      
      let payload;
      
      if (notificationType === 'FRIEND_REQUEST') {
        const { toUnionId, fromUserName, requestId } = data;
        
        if (!toUnionId || !fromUserName || !requestId) {
          res.status(400).json({
            error: 'Missing required fields: toUnionId, fromUserName, or requestId'
          });
          return;
        }
        
        console.log(`  To: ${toUnionId}`);
        console.log(`  From: ${fromUserName}`);
        
        const notificationToken = await fetchNotificationToken();
        const expiryDate = new Date();
        expiryDate.setDate(expiryDate.getDate() + 30);
        
        payload = {
          data: {
            recipients: [toUnionId],
            title: 'Ny venneanmodning',
            message: `${fromUserName} vil gerne være venner med dig og følge dit handicap.`,
            message_type: 'DGUMessage',
            message_link: `https://dgu-app-poc.web.app/friend-request/${requestId}`,
            expire_at: formatNotificationDate(expiryDate),
            token: notificationToken
          }
        };
      } else {
        res.status(400).json({ error: 'Unsupported notification type' });
        return;
      }
      
      // VIGTIGT: Genbruger sendNotificationRequest() helper
      console.log('  Sending to DGU notification API...');
      const result = await sendNotificationRequest(payload);
      
      console.log('  ✅ Notification sent successfully!');
      res.status(200).json({ 
        success: true,
        message: 'Notification sent',
        result: result
      });
      
    } catch (error) {
      console.error('❌ Error:', error.message);
      res.status(500).json({ 
        error: error.message 
      });
    }
  });
```

---

## 📋 Checklist når du tilføjer ny notification type

- [ ] Tilføj ny `type` i `sendNotificationHttp` Cloud Function
- [ ] Validér required fields
- [ ] Byg payload med korrekt `title`, `message`, `message_link`
- [ ] Test i localhost først
- [ ] Deploy Cloud Function: `firebase deploy --only functions:sendNotificationHttp`
- [ ] Deploy Flutter app: `flutter build web --release && firebase deploy --only hosting:dgu-app-poc`
- [ ] Test i production

---

## 🐛 Debug Guide

### Cloud Function bliver ikke kaldt
1. Tjek browser console for fejl
2. Verificer endpoint URL er korrekt
3. Tjek Cloud Function logs: `firebase functions:log --only sendNotificationHttp`

### 500 Error
1. Tjek Cloud Function logs for stack trace
2. Verificér at alle dependencies er tilgængelige
3. Test med curl direkte:
```bash
curl -X POST https://europe-west1-dgu-scorekort.cloudfunctions.net/sendNotificationHttp \
  -H "Content-Type: application/json" \
  -d '{
    "type": "FRIEND_REQUEST",
    "fromUserName": "Test",
    "toUnionId": "177-2813",
    "requestId": "test-123"
  }'
```

### Notification sendes men modtages ikke
1. Verificér `toUnionId` er korrekt
2. Tjek at modtager har "Mit Golf" app installeret og logget ind
3. Verificér `message_link` URL er korrekt (skal være production URL)

---

## 📖 Relaterede Filer

- **Flutter Service:** [`lib/services/friends_service.dart`](lib/services/friends_service.dart)
- **Cloud Function:** [`functions/index.js`](functions/index.js) (linje 340-430)
- **Helper Function:** [`functions/index.js`](functions/index.js) (linje 865-900) - `sendNotificationRequest()`

---

**Sidste opdatering:** 2025-12-15
**Status:** ✅ Virker i production

