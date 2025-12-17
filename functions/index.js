/**
 * Firebase Cloud Functions for DGU Scorekort
 * 
 * Scheduled function that updates the course cache nightly at 02:00 CET
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');
const https = require('https');
const http = require('http');

admin.initializeApp();

// Constants
const DGU_API_BASE = 'https://dgubasen.api.union.golfbox.io/DGUScorkortAapp';
const TOKEN_GIST_URL = 'https://gist.githubusercontent.com/nhuttel/a907dd7d60bf417b584333dfd5fff74a/raw/9b743740c4a7476c79d6a03c726e0d32b4034ec6/dgu_token.txt';
const NOTIFICATION_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/ad197ae6de63e78d3d450fd70d604b7d/raw/6036a00fec46c4e5b1d05e4295c5e32566090abf/gistfile1.txt';
const NOTIFICATION_API_URL = 'sendsinglenotification-d3higuw2ca-ey.a.run.app';
const BATCH_SIZE = 20;
const API_DELAY_MS = 300;

// OAuth Dispatcher - Allowlist for redirect URLs
const ALLOW_LIST = [
  'http://localhost',
  'https://dgu-scorekort.web.app',
  'https://dgu-scorekort.firebaseapp.com',
  'https://dgu-app-poc.web.app',           // POC site
  'https://dgu-app-poc.firebaseapp.com'    // POC site (alt domain)
];

/**
 * Scheduled function: Update course cache every night at 02:00 CET
 * Schedule: "0 2 * * *" = At 02:00 every day
 */
exports.updateCourseCache = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 540, // 9 minutes (max for scheduled functions)
    memory: '1GB'
  })
  .pubsub.schedule('0 2 * * *')
  .timeZone('Europe/Copenhagen')
  .onRun(async (context) => {
    console.log('🕒 Starting scheduled course cache update...');
    const startTime = Date.now();
    const db = admin.firestore();
    
    try {
      // 1. Determine update strategy (full vs incremental)
      console.log('🔍 Determining update strategy...');
      const strategy = await determineUpdateType(db);
      console.log(`📋 Strategy: ${strategy.type}, changedsince: ${strategy.changedsince}`);
      
      // 2. Fetch Basic Auth token from Gist
      console.log('📡 Fetching auth token...');
      const authToken = await fetchAuthToken();
      
      // 3. Fetch all clubs from DGU API
      console.log('📡 Fetching all clubs from DGU API...');
      const clubsRaw = await fetchClubsFromAPI(authToken);
      console.log(`✅ Found ${clubsRaw.length} clubs`);
      
      // 4. Fetch courses for each club and filter
      console.log(`📡 Fetching courses for each club (${strategy.type} mode)...`);
      const clubsForBatch = [];
      let totalCourses = 0;
      let clubsUpdated = 0;
      let skippedClubs = 0;
      
      for (let i = 0; i < clubsRaw.length; i++) {
        const club = clubsRaw[i];
        const clubId = club.ID;
        const clubName = club.Name || 'Unknown';
        
        try {
          console.log(`  [${i + 1}/${clubsRaw.length}] ${clubName}...`);
          
          // Fetch raw courses with changedsince parameter
          const coursesRaw = await fetchCoursesFromAPI(clubId, authToken, strategy.changedsince);
          
          if (coursesRaw.length === 0) {
            console.log(`    → No changes`);
            continue; // Skip if no changes
          }
          
          // Filter courses (with +7 days window)
          const filteredCourses = filterCourses(coursesRaw);
          
          console.log(`    → ${coursesRaw.length} raw → ${filteredCourses.length} filtered`);
          
          if (filteredCourses.length === 0) continue;
          
          totalCourses += filteredCourses.length;
          clubsUpdated++;
          
          // Check size (warn if >900KB)
          club.courses = filteredCourses;
          const clubSize = JSON.stringify(club).length;
          if (clubSize > 900000) {
            console.log(`    ⚠️  Large club: ${(clubSize / 1024).toFixed(0)}KB`);
          }
          
          // Skip clubs larger than 1MB (Firestore document limit)
          if (clubSize > 1048576) {
            console.log(`    ❌ Skipping ${clubName}: ${(clubSize / 1024).toFixed(0)}KB (too large)`);
            skippedClubs++;
            continue;
          }
          
          if (strategy.type === 'full') {
            // Full seed: collect for batch write later
            clubsForBatch.push(club);
          } else {
            // Incremental: REPLACE immediately
            const clubInfo = { ...club };
            delete clubInfo.courses;
            await replaceClubCourses(db, clubId, clubInfo, filteredCourses);
          }
          
          // Rate limiting delay
          if (i < clubsRaw.length - 1) {
            await sleep(API_DELAY_MS);
          }
        } catch (error) {
          console.error(`    ❌ Error fetching courses for ${clubName}:`, error.message);
          // Continue with other clubs even if one fails
        }
      }
      
      console.log(`✅ Processed ${clubsUpdated} clubs, ${totalCourses} courses`);
      if (skippedClubs > 0) {
        console.log(`⚠️  Skipped ${skippedClubs} clubs (too large)`);
      }
      
      // 5. Finalize based on strategy
      console.log('💾 Finalizing cache...');
      if (strategy.type === 'full') {
        // Full seed: clear + batch write all
        await saveCacheToFirestore(clubsForBatch, totalCourses);
      } else {
        // Incremental: just update metadata
        await updateMetadataIncremental(db, clubsUpdated, totalCourses);
      }
      
      const duration = ((Date.now() - startTime) / 1000).toFixed(0);
      console.log(`✅ Cache update (${strategy.type}) completed successfully in ${duration}s`);
      
      return {
        success: true,
        updateType: strategy.type,
        clubCount: clubsForBatch.length > 0 ? clubsForBatch.length : clubsUpdated,
        courseCount: totalCourses,
        skippedClubs,
        durationSeconds: duration
      };
      
    } catch (error) {
      console.error('❌ Cache update failed:', error);
      throw error;
    }
  });

/**
 * Callable function: Force full reseed on next scheduled run
 * Resets lastSeeded to null, triggering full reseed at 02:00
 */
exports.forceFullReseed = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    console.log('🔄 Manual force full reseed triggered');
    
    const db = admin.firestore();
    
    try {
      // Reset lastSeeded to trigger full reseed next run
      await db.collection('course-cache-metadata').doc('data').update({
        lastSeeded: null,
        lastUpdateType: 'pending_full_reseed'
      });
      
      console.log('✅ Full reseed scheduled for next run (02:00)');
      
      return { 
        success: true, 
        message: 'Full reseed scheduled for next run at 02:00' 
      };
    } catch (error) {
      console.error('❌ Failed to schedule full reseed:', error);
      throw new functions.https.HttpsError('internal', 'Failed to schedule reseed', error.message);
    }
  });

/**
 * Send Push Notification Proxy
 * 
 * Callable Cloud Function that acts as a CORS-free proxy for sending
 * push notifications to DGU's notification service.
 * 
 * Supports two notification types:
 * 1. MARKER_APPROVAL: Scorecard marker approval request
 * 2. FRIEND_REQUEST: Friend request with consent
 * 
 * This function:
 * 1. Receives notification payload from Flutter app
 * 2. Fetches notification token from GitHub Gist
 * 3. Sends POST request to DGU notification API
 * 4. Returns success/failure response to client
 * 
 * This bypasses CORS restrictions that prevent direct browser->API calls.
 */
exports.sendNotification = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    console.log('📤 Push notification request received');
    
    try {
      // 1. Validate notification type
      const notificationType = data.type || 'MARKER_APPROVAL'; // Default to marker approval
      console.log(`  Type: ${notificationType}`);
      
      // 2. Build payload based on type
      let payload;
      
      if (notificationType === 'MARKER_APPROVAL') {
        // Marker approval notification
        const { markerUnionId, playerName, approvalUrl } = data;
        
        if (!markerUnionId || !playerName || !approvalUrl) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Missing required fields for MARKER_APPROVAL: markerUnionId, playerName, or approvalUrl'
          );
        }
        
        console.log(`  Marker: ${markerUnionId}`);
        console.log(`  Player: ${playerName}`);
        
        // Fetch notification token
        console.log('  Fetching notification token...');
        const notificationToken = await fetchNotificationToken();
        
        // Build payload
        const expiryDate = new Date();
        expiryDate.setDate(expiryDate.getDate() + 7);
        const expiryString = formatNotificationDate(expiryDate);
        
        payload = {
          data: {
            recipients: [markerUnionId],
            title: 'Nyt scorekort afventer din godkendelse',
            message: `${playerName} har sendt et scorekort til godkendelse.\r\n\r\nGå til godkendelse af scorekort herunder.`,
            message_type: 'DGUMessage',
            message_link: approvalUrl,
            expire_at: expiryString,
            token: notificationToken
          }
        };
        
      } else if (notificationType === 'FRIEND_REQUEST') {
        // Friend request notification
        const { toUnionId, fromUserName, requestId } = data;
        
        if (!toUnionId || !fromUserName || !requestId) {
          throw new functions.https.HttpsError(
            'invalid-argument',
            'Missing required fields for FRIEND_REQUEST: toUnionId, fromUserName, or requestId'
          );
        }
        
        console.log(`  To: ${toUnionId}`);
        console.log(`  From: ${fromUserName}`);
        console.log(`  RequestId: ${requestId}`);
        
        // Build deep link URL
        const requestUrl = `https://dgu-app-poc.web.app/friend-request/${requestId}`;
        console.log(`  Deep link: ${requestUrl}`);
        
        // Fetch notification token
        console.log('  Fetching notification token...');
        const notificationToken = await fetchNotificationToken();
        
        // Build payload
        const expiryDate = new Date();
        expiryDate.setDate(expiryDate.getDate() + 30); // 30 days for friend requests
        const expiryString = formatNotificationDate(expiryDate);
        
        payload = {
          data: {
            recipients: [toUnionId],
            title: 'Ny venneanmodning',
            message: `${fromUserName} vil gerne være venner med dig og følge dit handicap.`,
            message_type: 'DGUMessage',
            message_link: requestUrl,
            expire_at: expiryString,
            token: notificationToken
          }
        };
        
      } else {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Unknown notification type: ${notificationType}`
        );
      }
      
      console.log('  Payload prepared');
      
      // 3. Send to DGU notification API
      console.log('  Sending to DGU notification API...');
      const result = await sendNotificationRequest(payload);
      
      console.log(`  ✅ Notification sent successfully: ${result}`);
      
      return {
        success: true,
        response: result
      };
      
    } catch (error) {
      console.error('❌ Notification failed:', error.message);
      throw new functions.https.HttpsError(
        'internal',
        error.message || 'Failed to send notification'
      );
    }
  });

/**
 * GolfBox OAuth Callback Dispatcher (2nd Gen Cloud Function)
 * 
 * Acts as a blind relay for GolfBox OAuth callbacks, enabling PKCE flow
 * from both localhost (development) and production URLs.
 * 
 * GolfBox only supports one Return URI, so this function:
 * 1. Receives the OAuth callback with code and state
 * 2. Decodes the state parameter to find the targetUrl
 * 3. Validates targetUrl against ALLOW_LIST
 * 4. Redirects to targetUrl with all original query parameters
 * 
 * Security: Only allows redirects to pre-approved domains (allowlist)
 */
/**
 * sendNotificationHttp - HTTP endpoint version of sendNotification
 * 
 * Accepts POST requests with JSON body containing notification data.
 * This is a workaround for Flutter Web, where the cloud_functions package
 * doesn't work reliably in production builds.
 * 
 * Usage from Flutter:
 *   POST https://europe-west1-dgu-scorekort.cloudfunctions.net/sendNotificationHttp
 *   Headers: Content-Type: application/json
 *   Body: { type: 'FRIEND_REQUEST', fromUserName: '...', toUnionId: '...', requestId: '...' }
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
      
      // Validate notification type
      const notificationType = data.type || 'MARKER_APPROVAL';
      console.log(`  Type: ${notificationType}`);
      
      // Build payload based on type
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
        console.log(`  RequestId: ${requestId}`);
        
        // Build deep link URL
        const requestUrl = `https://dgu-app-poc.web.app/friend-request/${requestId}`;
        console.log(`  Deep link: ${requestUrl}`);
        
        // Fetch notification token
        console.log('  Fetching notification token...');
        const notificationToken = await fetchNotificationToken();
        
        // Build payload
        const expiryDate = new Date();
        expiryDate.setDate(expiryDate.getDate() + 30);
        const expiryString = formatNotificationDate(expiryDate);
        
        payload = {
          data: {
            recipients: [toUnionId],
            title: 'Ny venneanmodning',
            message: `${fromUserName} vil gerne være venner med dig og følge dit handicap.`,
            message_type: 'DGUMessage',
            message_link: requestUrl,
            expire_at: expiryString,
            token: notificationToken
          }
        };
      } else {
        res.status(400).json({ error: 'Unsupported notification type' });
        return;
      }
      
      // Send to DGU notification API using shared helper function
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

exports.golfboxCallback = functions
  .region('europe-west1')
  .https.onRequest((req, res) => {
    console.log('🔐 GolfBox OAuth callback received');
    console.log('  Method:', req.method);
    console.log('  Query params:', JSON.stringify(req.query));
    
    try {
      // 1. Extract query parameters
      const queryParams = req.query;
      const code = queryParams.code;
      const state = queryParams.state;
      
      // 2. Validate required parameters
      if (!code) {
        console.error('❌ Missing code parameter');
        res.status(400).send('Bad Request: Missing authorization code');
        return;
      }
      
      if (!state) {
        console.error('❌ Missing state parameter');
        res.status(400).send('Bad Request: Missing state parameter');
        return;
      }
      
      console.log('  ✅ Code received (length:', code.length, ')');
      console.log('  ✅ State received (length:', state.length, ')');
      
      // 3. Determine target URL - IGNORE referer from auth.golfbox.io
      const referer = req.headers.referer || req.headers.origin;
      let targetUrl;
      
      // Always use default target (referer from auth.golfbox.io is not useful)
      // The callback comes FROM auth.golfbox.io, but we need to redirect TO our app
      targetUrl = 'https://dgu-app-poc.web.app/login';
      console.log('  📍 Target URL:', targetUrl);
      if (referer) {
        console.log('  📍 (Ignored referer:', referer + ')');
      }
      
      // 4. Validate targetUrl against ALLOW_LIST
      const isAllowed = ALLOW_LIST.some(allowedPrefix => {
        // Check if targetUrl starts with any allowed prefix
        // For localhost, allow any port
        if (allowedPrefix === 'http://localhost') {
          return targetUrl === 'http://localhost' || 
                 targetUrl.startsWith('http://localhost:') ||
                 targetUrl.startsWith('http://localhost/');
        }
        return targetUrl.startsWith(allowedPrefix);
      });
      
      if (!isAllowed) {
        console.error('🚨 SECURITY: Rejected redirect to unauthorized URL:', targetUrl);
        console.error('  Allowed domains:', ALLOW_LIST.join(', '));
        res.status(400).send('Bad Request: Unauthorized redirect URL');
        return;
      }
      
      console.log('  ✅ Target URL validated against allowlist');
      
      // 5. Build redirect URL with OAuth parameters
      const url = new URL(targetUrl);
      url.searchParams.append('code', code);
      url.searchParams.append('state', state);
      
      // Forward any additional query parameters (scope, etc.)
      Object.keys(queryParams).forEach(key => {
        if (key !== 'code' && key !== 'state') {
          url.searchParams.append(key, queryParams[key]);
        }
      });
      
      const redirectUrl = url.toString();
      console.log('  📍 Redirect URL:', redirectUrl);
      console.log('✅ Redirecting (302) to client');
      
      // 6. Perform 302 redirect
      res.redirect(302, redirectUrl);
      
    } catch (error) {
      console.error('❌ Unexpected error in golfboxCallback:', error);
      console.error('  Stack trace:', error.stack);
      res.status(500).send('Internal Server Error');
    }
  });

/**
 * Cloud Function: Exchange OAuth Code for Token (CORS Proxy)
 * 
 * Handles token exchange for OAuth 2.0 PKCE flow to avoid CORS issues in web browsers.
 * Client sends authorization code + code_verifier, function exchanges for access token.
 * 
 * Usage from Flutter:
 * ```dart
 * final callable = FirebaseFunctions.instance.httpsCallable('exchangeOAuthToken');
 * final result = await callable.call({
 *   'code': 'auth_code_here',
 *   'codeVerifier': 'pkce_code_verifier',
 * });
 * final accessToken = result.data['access_token'];
 * ```
 */
exports.exchangeOAuthToken = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onCall(async (data, context) => {
    console.log('🔐 exchangeOAuthToken called');
    console.log('  📥 Input:', JSON.stringify({ code: '***', codeVerifier: '***' }));
    
    // Validate input
    const code = data.code;
    const codeVerifier = data.codeVerifier;
    
    if (!code || !codeVerifier) {
      console.error('  ❌ Missing required parameters');
      throw new functions.https.HttpsError('invalid-argument', 'code and codeVerifier are required');
    }
    
    try {
      // OAuth configuration (matches AuthConfig.dart)
      const clientId = 'DGU_TEST_DK';
      const redirectUri = 'https://europe-west1-dgu-scorekort.cloudfunctions.net/golfboxCallback';
      const tokenUrl = 'https://auth.golfbox.io/connect/token';
      
      console.log('  🔄 Exchanging code for token...');
      console.log('  📍 Token URL:', tokenUrl);
      console.log('  🔑 Client ID:', clientId);
      
      // Build form data for token exchange
      const formData = new URLSearchParams({
        grant_type: 'authorization_code',
        code: code,
        redirect_uri: redirectUri,
        client_id: clientId,
        code_verifier: codeVerifier
      }).toString();
      
      // Use axios for POST request
      const axios = require('axios');
      const response = await axios.post(tokenUrl, formData, {
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json'
        },
        timeout: 25000,
        validateStatus: (status) => status < 500 // Don't throw on 4xx
      });
      
      console.log(`  📥 Response Status: ${response.status}`);
      
      if (response.status === 200) {
        console.log('  ✅ Token exchange successful');
        console.log('  📦 Raw response.data type:', typeof response.data);
        console.log('  📦 Raw response.data:', response.data);
        
        // Extract only the fields we actually need (minimal response)
        const minimalResponse = {
          success: true,
          access_token: String(response.data.access_token || ''),
          token_type: String(response.data.token_type || 'Bearer'),
          expires_in: parseInt(response.data.expires_in || '3600', 10),
          scope: String(response.data.scope || '')
        };
        
        console.log('  📦 Minimal response:', JSON.stringify(minimalResponse));
        console.log('  📦 expires_in type:', typeof minimalResponse.expires_in);
        console.log('  📦 expires_in value:', minimalResponse.expires_in);
        
        return minimalResponse;
      } else {
        console.error(`  ❌ Token exchange failed: HTTP ${response.status}`);
        console.error('  📦 Response:', JSON.stringify(response.data));
        throw new functions.https.HttpsError(
          'internal',
          `Token exchange failed: ${response.status} - ${JSON.stringify(response.data)}`
        );
      }
      
    } catch (error) {
      console.error('  ❌ Error:', error.message);
      
      if (error.response) {
        console.error('  📥 Error Response:', error.response.status, error.response.data);
        throw new functions.https.HttpsError(
          'internal',
          `Token exchange failed: ${error.response.status} - ${JSON.stringify(error.response.data)}`
        );
      } else if (error.message.includes('timeout')) {
        throw new functions.https.HttpsError('deadline-exceeded', 'Request timeout');
      } else {
        throw new functions.https.HttpsError('internal', `Token exchange error: ${error.message}`);
      }
    }
  });

/**
 * Fetch Basic Auth token from GitHub Gist
 */
async function fetchAuthToken() {
  return new Promise((resolve, reject) => {
    https.get(TOKEN_GIST_URL, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data.trim()));
      res.on('error', reject);
    }).on('error', reject);
  });
}

/**
 * Fetch all clubs from DGU API
 */
async function fetchClubsFromAPI(authToken) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'dgubasen.api.union.golfbox.io',
      path: '/DGUScorkortAapp/clubs',
      method: 'GET',
      headers: {
        'Authorization': authToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    };
    
    https.get(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    }).on('error', reject);
  });
}

/**
 * Fetch courses for a specific club from DGU API with dynamic changedsince parameter
 */
async function fetchCoursesFromAPI(clubId, authToken, changedsince = '20250301T000000') {
  return new Promise((resolve, reject) => {
    const path = `/DGUScorkortAapp/clubs/${clubId}/courses?active=1&sort=ActivationDate:1&sortTee=TotalLength:1&changedsince=${changedsince}`;
    
    const options = {
      hostname: 'dgubasen.api.union.golfbox.io',
      path: path,
      method: 'GET',
      headers: {
        'Authorization': authToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    };
    
    https.get(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          resolve(JSON.parse(data));
        } else {
          reject(new Error(`HTTP ${res.statusCode}: ${data}`));
        }
      });
    }).on('error', reject);
  });
}

/**
 * Parse DGU compact date format: 20241010T092806 -> Date object
 */
function parseCompactDate(dateStr) {
  if (!dateStr) return null;
  
  const year = parseInt(dateStr.substring(0, 4));
  const month = parseInt(dateStr.substring(4, 6)) - 1; // Month is 0-indexed
  const day = parseInt(dateStr.substring(6, 8));
  const hour = parseInt(dateStr.substring(9, 11));
  const minute = parseInt(dateStr.substring(11, 13));
  const second = parseInt(dateStr.substring(13, 15));
  
  return new Date(year, month, day, hour, minute, second);
}

/**
 * Format Date to DGU compact format: yyyymmddThhnnss
 */
function formatCompactDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hour = String(date.getHours()).padStart(2, '0');
  const minute = String(date.getMinutes()).padStart(2, '0');
  const second = String(date.getSeconds()).padStart(2, '0');
  
  return `${year}${month}${day}T${hour}${minute}${second}`;
}

/**
 * Determine update type: full or incremental
 */
async function determineUpdateType(db) {
  const metadataRef = db.collection('course-cache-metadata').doc('data');
  const metadataDoc = await metadataRef.get();
  
  if (!metadataDoc.exists || !metadataDoc.data().lastSeeded) {
    console.log('  No lastSeeded found - performing full seed');
    return { type: 'full', changedsince: '20250101T000000' };
  }
  
  const metadata = metadataDoc.data();
  const lastSeededDate = metadata.lastSeeded.toDate();
  const daysSince = (new Date() - lastSeededDate) / (1000 * 60 * 60 * 24);
  
  if (daysSince > 30) {
    console.log(`  Last seed ${daysSince.toFixed(1)} days ago - forcing full reseed`);
    return { type: 'full', changedsince: '20250101T000000' };
  }
  
  const changedsince = formatCompactDate(lastSeededDate);
  console.log(`  Incremental update with changedsince=${changedsince}`);
  return { type: 'incremental', changedsince };
}

/**
 * REPLACE club courses (simple overwrite for incremental updates)
 */
async function replaceClubCourses(db, clubId, clubInfo, courses) {
  await db.collection('course-cache-clubs').doc(clubId).set({
    info: clubInfo,
    courses: courses,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  });
  
  return courses.length;
}

/**
 * Filter courses: Active, activation date <= now + 7 days (HYBRID), latest version per template
 * Server-side caches courses activated in next 7 days
 * Client-side filters to only show courses activated today
 */
function filterCourses(coursesRaw) {
  const currentDate = new Date();
  
  // Add 7 days for future activation window (HYBRID FILTERING)
  const futureDate = new Date(currentDate);
  futureDate.setDate(futureDate.getDate() + 7);
  
  // 1. Filter: Only active courses
  let courses = coursesRaw.filter(course => course.IsActive === true);
  
  // 2. Filter: ActivationDate <= now + 7 days (HYBRID FILTERING)
  courses = courses.filter(course => {
    if (!course.ActivationDate) return true;
    
    try {
      const activationDate = parseCompactDate(course.ActivationDate);
      if (!activationDate) return true;
      // Accept courses activated up to 7 days in the future
      return activationDate <= futureDate;
    } catch (e) {
      return true; // Include if can't parse
    }
  });
  
  // 3. Group by TemplateID and keep only latest version
  const latestByTemplate = {};
  const noTemplate = [];
  
  for (const course of courses) {
    const templateID = course.TemplateID || '';
    
    if (templateID === '') {
      noTemplate.push(course);
    } else {
      if (!latestByTemplate[templateID]) {
        latestByTemplate[templateID] = course;
      } else {
        try {
          // Parse both dates using compact format parser
          const existingDate = parseCompactDate(latestByTemplate[templateID].ActivationDate);
          const currentCourseDate = parseCompactDate(course.ActivationDate);
          
          if (currentCourseDate > existingDate) {
            latestByTemplate[templateID] = course;
          }
        } catch (e) {
          // Keep existing if date parsing fails
        }
      }
    }
  }
  
  // Combine and return
  return [...Object.values(latestByTemplate), ...noTemplate];
}

/**
 * Save cache to Firestore with split structure:
 * - course-cache-metadata/data: metadata + lightweight club list
 * - course-cache-clubs/{clubId}: club info + courses
 */
async function saveCacheToFirestore(clubsWithCourses, totalCourses) {
  const db = admin.firestore();
  
  // 1. Clear existing club documents
  console.log('  🗑️  Clearing existing club cache...');
  const existingDocs = await db.collection('course-cache-clubs').get();
  const deletePromises = [];
  existingDocs.forEach(doc => {
    deletePromises.push(doc.ref.delete());
  });
  await Promise.all(deletePromises);
  console.log(`  ✅ Cleared ${existingDocs.size} existing documents`);
  
  // 2. Build lightweight club list for metadata
  const clubList = clubsWithCourses.map(club => ({
    ID: club.ID,
    Name: club.Name
  }));
  
  // 3. Save clubs in batches
  console.log(`  💾 Saving ${clubsWithCourses.length} clubs in batches of ${BATCH_SIZE}...`);
  
  for (let i = 0; i < clubsWithCourses.length; i += BATCH_SIZE) {
    const batch = db.batch();
    const end = Math.min(i + BATCH_SIZE, clubsWithCourses.length);
    const chunk = clubsWithCourses.slice(i, end);
    
    for (const clubData of chunk) {
      const clubId = clubData.ID;
      const courses = clubData.courses;
      
      // Split: info (without courses) + courses (separate)
      const clubInfo = { ...clubData };
      delete clubInfo.courses;
      
      const docRef = db.collection('course-cache-clubs').doc(clubId);
      batch.set(docRef, {
        info: clubInfo,
        courses: courses,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }
    
    await batch.commit();
    console.log(`    ✅ Saved batch ${Math.floor(i / BATCH_SIZE) + 1}/${Math.ceil(clubsWithCourses.length / BATCH_SIZE)}`);
  }
  
  // 4. Update metadata with club list
  console.log('  💾 Updating metadata...');
  await db.collection('course-cache-metadata').doc('data').set({
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    lastSeeded: admin.firestore.FieldValue.serverTimestamp(),
    lastUpdateType: 'full',
    clubCount: clubsWithCourses.length,
    courseCount: totalCourses,
    clubsUpdatedLastRun: clubsWithCourses.length,
    coursesUpdatedLastRun: totalCourses,
    clubs: clubList, // Lightweight club list for instant loading
    version: 2
  });
  
  console.log('  ✅ Metadata updated');
}

/**
 * Update metadata after incremental update
 */
async function updateMetadataIncremental(db, clubsUpdated, coursesUpdated) {
  const metadataRef = db.collection('course-cache-metadata').doc('data');
  
  await metadataRef.update({
    lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    lastSeeded: admin.firestore.FieldValue.serverTimestamp(),
    lastUpdateType: 'incremental',
    clubsUpdatedLastRun: clubsUpdated,
    coursesUpdatedLastRun: coursesUpdated
  });
  
  console.log(`  ✅ Metadata updated: ${clubsUpdated} clubs, ${coursesUpdated} courses`);
}

/**
 * Fetch notification token from GitHub Gist
 */
async function fetchNotificationToken() {
  return new Promise((resolve, reject) => {
    https.get(NOTIFICATION_TOKEN_URL, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(data.trim()));
      res.on('error', reject);
    }).on('error', reject);
  });
}

/**
 * Format date for notification API: "2025-12-18T23:15:53"
 */
function formatNotificationDate(date) {
  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, '0');
  const day = String(date.getDate()).padStart(2, '0');
  const hour = String(date.getHours()).padStart(2, '0');
  const minute = String(date.getMinutes()).padStart(2, '0');
  const second = String(date.getSeconds()).padStart(2, '0');
  
  return `${year}-${month}-${day}T${hour}:${minute}:${second}`;
}

/**
 * Send notification request to DGU API
 * Uses axios for better compatibility with Cloud Run endpoints
 */
async function sendNotificationRequest(payload) {
  const axios = require('axios');
  
  console.log('  📤 Sending to DGU notification API:');
  console.log('  🌐 URL: https://' + NOTIFICATION_API_URL);
  console.log('  📦 Payload:', JSON.stringify(payload));
  
  try {
    const response = await axios.post(`https://${NOTIFICATION_API_URL}`, payload, {
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'DGU-Scorekort/1.0'
      },
      timeout: 10000, // 10 second timeout
      validateStatus: (status) => status < 500 // Don't throw on 4xx errors
    });
    
    console.log(`  📥 Response Status: ${response.status}`);
    console.log(`  📦 Response Body:`, JSON.stringify(response.data));
    
    if (response.status === 200 || response.status === 201) {
      console.log('  ✅ Notification sent successfully!');
      return response.data;
    } else {
      console.error(`  ❌ Notification failed: HTTP ${response.status}`);
      throw new Error(`HTTP ${response.status}: ${JSON.stringify(response.data)}`);
    }
  } catch (error) {
    console.error('  ❌ Request error:', error.message);
    if (error.response) {
      console.error('  📥 Error Response:', error.response.status, error.response.data);
    }
    throw error;
  }
}

/**
 * Sleep helper function
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Cloud Function: Get WHS Scores (CORS Proxy)
 * 
 * Proxies requests to DGU Statistik API to avoid CORS issues in web browsers.
 * Fetches token from GitHub Gist and forwards request to WHS API.
 * 
 * Usage from Flutter:
 * ```dart
 * final callable = FirebaseFunctions.instance.httpsCallable('getWhsScores');
 * final result = await callable.call({
 *   'unionId': '177-2813',
 *   'limit': 20,
 * });
 * ```
 */
exports.getWhsScores = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 30,
    memory: '256MB'
  })
  .https.onCall(async (data, context) => {
    console.log('📊 getWhsScores called');
    console.log('  📥 Input:', JSON.stringify(data));
    
    // Validate input
    const unionId = data.unionId;
    if (!unionId) {
      console.error('  ❌ Missing unionId');
      throw new functions.https.HttpsError('invalid-argument', 'unionId is required');
    }
    
    const limit = data.limit || 20;
    const dateFrom = data.dateFrom; // Optional: "20240101T000000"
    const dateTo = data.dateTo;     // Optional: "20251231T235959"
    
    try {
      // 1. Fetch Statistik API token from GitHub Gist
      console.log('  🔐 Fetching Statistik API token...');
      const WHS_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/36871c0145d83c3111174b5c87542ee8/raw/17bee0485c5420d473310de8deeaeccd58e3b9cc/statistik%2520token';
      
      const tokenResponse = await new Promise((resolve, reject) => {
        https.get(WHS_TOKEN_URL, (res) => {
          let data = '';
          res.on('data', chunk => data += chunk);
          res.on('end', () => resolve(data.trim()));
          res.on('error', reject);
        }).on('error', reject);
      });
      
      // Token format from Gist: "basic [base64-encoded-credentials]"
      let authHeader;
      if (tokenResponse.toLowerCase().startsWith('basic ')) {
        const credentials = tokenResponse.substring(6);
        authHeader = `Basic ${credentials}`;
      } else {
        throw new Error('Invalid token format in Gist');
      }
      
      console.log('  ✅ Token fetched');
      
      // 2. Calculate date range if not provided
      const now = new Date();
      const oneYearAgo = new Date(now);
      oneYearAgo.setFullYear(now.getFullYear() - 1);
      
      const formatDate = (date) => {
        const year = date.getFullYear();
        const month = String(date.getMonth() + 1).padStart(2, '0');
        const day = String(date.getDate()).padStart(2, '0');
        return `${year}${month}${day}T000000`;
      };
      
      const fromDate = dateFrom || formatDate(oneYearAgo);
      const toDate = dateTo || formatDate(now);
      
      // 3. Build API URL
      const apiUrl = `https://api.danskgolfunion.dk/Statistik/GetWHSScores?UnionID=${encodeURIComponent(unionId)}&RoundDateFrom=${fromDate}&RoundDateTo=${toDate}`;
      console.log('  📡 Calling WHS API:', apiUrl);
      
      // 4. Call WHS API
      const apiResponse = await new Promise((resolve, reject) => {
        https.get(apiUrl, {
          headers: {
            'Authorization': authHeader,
            'Accept': 'application/json',
            'User-Agent': 'DGU-Scorekort/2.0'
          },
          timeout: 25000
        }, (res) => {
          let data = '';
          res.on('data', chunk => data += chunk);
          res.on('end', () => {
            if (res.statusCode === 200) {
              try {
                const parsed = JSON.parse(data);
                resolve(parsed);
              } catch (e) {
                reject(new Error(`Failed to parse JSON: ${e.message}`));
              }
            } else {
              reject(new Error(`HTTP ${res.statusCode}: ${data}`));
            }
          });
          res.on('error', reject);
        }).on('error', reject).on('timeout', () => {
          reject(new Error('Request timeout'));
        });
      });
      
      console.log(`  ✅ Got ${apiResponse.length} scores from API`);
      
      // 5. Sort by date (newest first) and apply limit
      apiResponse.sort((a, b) => {
        const dateA = a.Round?.StartTime || '';
        const dateB = b.Round?.StartTime || '';
        return dateB.localeCompare(dateA);
      });
      
      const limitedScores = apiResponse.slice(0, limit);
      console.log(`  📦 Returning ${limitedScores.length} scores (limit: ${limit})`);
      
      // Explicitly convert to web-safe types (avoid Int64 for dart2js)
      return {
        success: true,
        scores: limitedScores,
        count: Number(limitedScores.length) // Explicit Number() for dart2js compatibility
      };
      
    } catch (error) {
      console.error('  ❌ Error:', error.message);
      
      if (error.message.includes('HTTP 401')) {
        throw new functions.https.HttpsError('unauthenticated', 'Invalid API token');
      } else if (error.message.includes('timeout')) {
        throw new functions.https.HttpsError('deadline-exceeded', 'Request timeout');
      } else {
        throw new functions.https.HttpsError('internal', `Failed to fetch WHS scores: ${error.message}`);
      }
    }
  });

// ==========================================
// ACTIVITY FEED - NIGHTLY MILESTONE SCAN
// ==========================================

/**
 * Scheduled function: Scan for milestones every night at 03:00 CET
 * 
 * Workflow:
 * 1. Get all unique user IDs who have friends (from friendships collection)
 * 2. For each user, fetch latest WHS scores
 * 3. Compare with cached scores to detect new rounds
 * 4. Detect milestones (scratch, single-digit, sub-20, sub-30, improvement, personal best, eagle, albatross)
 * 5. Create activities in Firestore
 * 6. Update user_score_cache
 * 
 * Similar to updateCourseCache, but for user scores instead of courses.
 */
exports.scanForMilestones = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 540, // 9 minutes (same as updateCourseCache)
    memory: '1GB'
  })
  .pubsub.schedule('0 3 * * *') // 03:00 daily (1 hour after course cache)
  .timeZone('Europe/Copenhagen')
  .onRun(async (context) => {
    console.log('🔍 Starting nightly milestone scan...');
    const startTime = Date.now();
    const db = admin.firestore();
    
    try {
      // STEP 1: Get all unique user IDs who have friends
      console.log('📋 Fetching users with friends...');
      const friendshipsSnapshot = await db.collection('friendships').get();
      
      const userIds = new Set();
      friendshipsSnapshot.docs.forEach(doc => {
        const data = doc.data();
        userIds.add(data.userId1);
        userIds.add(data.userId2);
      });
      
      console.log(`✅ Found ${userIds.size} users with friends`);
      
      // STEP 2: For each user, check for new scores/milestones
      const activities = [];
      let apiCalls = 0;
      let cacheHits = 0;
      let errors = 0;
      
      // Fetch Statistik token (similar to updateCourseCache fetching DGU token)
      console.log('📡 Fetching Statistik auth token...');
      const statistikToken = await fetchStatistikToken();
      
      for (const unionId of userIds) {
        try {
          // Fetch cached data
          const cacheDoc = await db.collection('user_score_cache').doc(unionId).get();
          const cachedData = cacheDoc.exists ? cacheDoc.data() : null;
          
          // Skip if no homeClubId (can't fetch scores without it)
          if (!cachedData?.homeClubId) {
            console.log(`⚠️  Skipping ${unionId} (no homeClubId)`);
            continue;
          }
          
          // Fetch fresh scores from WHS API (similar to fetchCoursesFromAPI)
          console.log(`  [${apiCalls + 1}/${userIds.size}] Fetching scores for ${unionId}...`);
          apiCalls++;
          
          const freshScores = await fetchWhsScoresForUser(
            unionId, 
            cachedData.homeClubId, 
            statistikToken
          );
          
          if (!freshScores || freshScores.length === 0) {
            console.log(`    → No scores found`);
            continue;
          }
          
          // Compare with cache to find new scores
          const latestScore = freshScores[0];
          const latestScoreDate = new Date(latestScore.Date || latestScore.roundDate);
          const lastScannedDate = cachedData?.lastScanned?.toDate() || new Date(0);
          
          const isNewScore = latestScoreDate > lastScannedDate;
          
          if (!isNewScore) {
            cacheHits++;
            console.log(`    → No new scores`);
            continue;
          }
          
          console.log(`    ✨ New score detected!`);
          
          // STEP 3: Detect milestones
          const detectedActivities = await detectMilestonesForScore({
            unionId,
            userName: cachedData.userName || latestScore.playerName || 'Ukendt',
            newHcp: latestScore.HCP || latestScore.handicapAfter || latestScore.handicapBefore,
            oldHcp: cachedData.currentHcp || latestScore.handicapBefore,
            bestHcp: cachedData.bestHcp || latestScore.handicapBefore,
            score: latestScore,
          });
          
          activities.push(...detectedActivities);
          
          // STEP 4: Update cache (similar to Firestore batch updates in updateCourseCache)
          await db.collection('user_score_cache').doc(unionId).set({
            unionId,
            userName: cachedData.userName || latestScore.playerName || 'Ukendt',
            homeClubId: cachedData.homeClubId,
            currentHcp: latestScore.HCP || latestScore.handicapAfter || latestScore.handicapBefore,
            lastScanned: admin.firestore.FieldValue.serverTimestamp(),
            recentScores: freshScores.slice(0, 20), // Keep last 20
            bestHcp: Math.min(
              cachedData?.bestHcp || 54,
              ...freshScores.map(s => s.HCP || s.handicapBefore || 54)
            ),
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
          
        } catch (error) {
          console.error(`❌ Error processing ${unionId}:`, error.message);
          errors++;
        }
      }
      
      // STEP 5: Write all activities to Firestore (batch write)
      if (activities.length > 0) {
        console.log(`📝 Writing ${activities.length} activities to Firestore...`);
        const batch = db.batch();
        const activitiesRef = db.collection('activities');
        
        for (const activity of activities) {
          const docRef = activitiesRef.doc();
          batch.set(docRef, {
            ...activity,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        console.log(`✅ Created ${activities.length} activities`);
      }
      
      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      
      console.log('🎉 Nightly scan complete!');
      console.log(`  Users scanned: ${userIds.size}`);
      console.log(`  API calls: ${apiCalls}`);
      console.log(`  Cache hits: ${cacheHits}`);
      console.log(`  Activities created: ${activities.length}`);
      console.log(`  Errors: ${errors}`);
      console.log(`  Duration: ${duration}s`);
      
      return { 
        success: true, 
        usersScanned: userIds.size,
        activitiesCreated: activities.length,
        duration,
        errors
      };
    } catch (error) {
      console.error('❌ Scan failed:', error);
      throw error;
    }
  });

/**
 * Fetch Statistik token from GitHub Gist
 * Similar to fetchAuthToken() for DGU API
 */
async function fetchStatistikToken() {
  // Use same Gist URL as WhsStatistikService
  const STATISTIK_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/36871c0145d83c3111174b5c87542ee8/raw/17bee0485c5420d473310de8deeaeccd58e3b9cc/statistik%2520token';
  
  return new Promise((resolve, reject) => {
    https.get(STATISTIK_TOKEN_URL, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        // Token format from Gist: "basic [base64-encoded-credentials]"
        const tokenLine = data.trim();
        if (tokenLine.toLowerCase().startsWith('basic ')) {
          const credentials = tokenLine.substring(6);
          resolve(`Basic ${credentials}`);
        } else {
          resolve(tokenLine);
        }
      });
    }).on('error', reject);
  });
}

/**
 * Fetch WHS scores for a user
 * Similar to WhsStatistikService.getPlayerScores()
 */
async function fetchWhsScoresForUser(unionId, clubId, authToken) {
  const apiUrl = `https://dgubasen.api.union.golfbox.io/statistik/clubs/${clubId}/Memberships/Scorecards?unionid=${unionId}`;
  
  return new Promise((resolve, reject) => {
    https.get(apiUrl, {
      headers: {
        'Authorization': authToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const scores = JSON.parse(data);
            // Sort by date (newest first) - same as Dart service
            scores.sort((a, b) => {
              const dateA = new Date(a.Date || a.roundDate);
              const dateB = new Date(b.Date || b.roundDate);
              return dateB - dateA;
            });
            resolve(scores);
          } catch (e) {
            console.error(`JSON parse error for ${unionId}:`, e.message);
            resolve([]); // Return empty array on parse error
          }
        } else {
          console.error(`API error for ${unionId}: ${res.statusCode}`);
          resolve([]); // Return empty array on error
        }
      });
    }).on('error', (err) => {
      console.error(`Network error for ${unionId}:`, err.message);
      resolve([]); // Return empty array on error
    });
  });
}

/**
 * Detect milestones from a score
 * Returns array of activity objects
 */
async function detectMilestonesForScore({ unionId, userName, newHcp, oldHcp, bestHcp, score }) {
  const activities = [];
  const delta = newHcp - oldHcp;
  
  // 1. Major milestones (crossing thresholds)
  if (newHcp === 0.0 && oldHcp > 0.0) {
    activities.push({
      userId: unionId,
      userName,
      type: 'milestone',
      timestamp: new Date(score.Date || score.roundDate),
      data: { 
        milestoneType: 'scratch', 
        newHcp, 
        oldHcp,
        courseName: score.CourseName || score.courseName || 'Ukendt bane'
      },
      isDismissed: false,
    });
  } else if (oldHcp >= 10.0 && newHcp < 10.0) {
    activities.push({
      userId: unionId,
      userName,
      type: 'milestone',
      timestamp: new Date(score.Date || score.roundDate),
      data: { 
        milestoneType: 'singleDigit', 
        newHcp, 
        oldHcp,
        courseName: score.CourseName || score.courseName || 'Ukendt bane'
      },
      isDismissed: false,
    });
  } else if (oldHcp >= 20.0 && newHcp < 20.0) {
    activities.push({
      userId: unionId,
      userName,
      type: 'milestone',
      timestamp: new Date(score.Date || score.roundDate),
      data: { 
        milestoneType: 'sub20', 
        newHcp, 
        oldHcp,
        courseName: score.CourseName || score.courseName || 'Ukendt bane'
      },
      isDismissed: false,
    });
  } else if (oldHcp >= 30.0 && newHcp < 30.0) {
    activities.push({
      userId: unionId,
      userName,
      type: 'milestone',
      timestamp: new Date(score.Date || score.roundDate),
      data: { 
        milestoneType: 'sub30', 
        newHcp, 
        oldHcp,
        courseName: score.CourseName || score.courseName || 'Ukendt bane'
      },
      isDismissed: false,
    });
  }
  
  // 2. Significant improvement (≥1.0 slag improvement)
  if (delta <= -1.0) {
    activities.push({
      userId: unionId,
      userName,
      type: 'improvement',
      timestamp: new Date(score.Date || score.roundDate),
      data: { 
        newHcp, 
        oldHcp, 
        delta: Math.abs(delta),
        courseName: score.CourseName || score.courseName || 'Ukendt bane'
      },
      isDismissed: false,
    });
  }
  
  // 3. Personal best (new lowest HCP ever)
  if (newHcp < bestHcp) {
    activities.push({
      userId: unionId,
      userName,
      type: 'personalBest',
      timestamp: new Date(score.Date || score.roundDate),
      data: { 
        newHcp, 
        previousBest: bestHcp,
        courseName: score.CourseName || score.courseName || 'Ukendt bane'
      },
      isDismissed: false,
    });
  }
  
  // 4. Eagles/Albatross (if we have hole data)
  // Note: WHS API hole structure might vary - adjust as needed
  if (score.Holes && Array.isArray(score.Holes)) {
    score.Holes.forEach((hole, index) => {
      const par = hole.Par || hole.par;
      const strokes = hole.Strokes || hole.strokes;
      
      if (par && strokes) {
        const scoreToPar = strokes - par;
        
        if (scoreToPar <= -2) {
          activities.push({
            userId: unionId,
            userName,
            type: scoreToPar === -2 ? 'eagle' : 'albatross',
            timestamp: new Date(score.Date || score.roundDate),
            data: { 
              holeNumber: index + 1, 
              par, 
              strokes,
              courseName: score.CourseName || score.courseName || 'Ukendt bane'
            },
            isDismissed: false,
          });
        }
      }
    });
  }
  
  return activities;
}

/**
 * ==============================================================================
 * BIRDIE BONUS CACHE (NIGHTLY SCHEDULED FUNCTION)
 * ==============================================================================
 * Fetches ALL participants from paginated Birdie Bonus API and caches in Firestore.
 * Runs daily at 04:00 CET (after updateCourseCache and scanForMilestones).
 */

/**
 * Fetch Birdie Bonus token from GitHub Gist
 * Similar to fetchStatistikToken()
 */
async function fetchBirdieBonusToken() {
  const BIRDIE_TOKEN_URL = 'https://gist.githubusercontent.com/nhuttel/10131112fc9ec097d1a0752d3569038e/raw/915ba2bcc9f5eb5774979da745003e1bd73a019a/Birdie%2520bonus%2520deltagere';
  
  return new Promise((resolve, reject) => {
    https.get(BIRDIE_TOKEN_URL, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        // Token format: "basic [base64-credentials]"
        const tokenLine = data.trim();
        if (tokenLine.toLowerCase().startsWith('basic ')) {
          const credentials = tokenLine.substring(6);
          resolve(`Basic ${credentials}`);
        } else {
          resolve(tokenLine);
        }
      });
    }).on('error', reject);
  });
}

/**
 * Fetch single page from Birdie Bonus API
 * API returns: { "data": [...participants], "next_page": 2 } or { "next_page": null }
 */
async function fetchBirdieBonusPage(page, authToken) {
  const apiUrl = `https://birdie.bonus.sdmdev.dk/api/member/rating_list/${page}`;
  
  return new Promise((resolve, reject) => {
    https.get(apiUrl, {
      headers: {
        'Authorization': authToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      }
    }, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const response = JSON.parse(data);
            // API response structure: { "data": [...], "next_page": 2 }
            resolve({
              participants: response.data || [],
              nextPage: response.next_page
            });
          } catch (e) {
            console.error(`Parse error page ${page}:`, e.message);
            resolve({ participants: [], nextPage: null });
          }
        } else {
          console.error(`API error page ${page}: ${res.statusCode}`);
          resolve({ participants: [], nextPage: null });
        }
      });
    }).on('error', (err) => {
      console.error(`Network error page ${page}:`, err.message);
      resolve({ participants: [], nextPage: null });
    });
  });
}

/**
 * SCHEDULED FUNCTION: Cache Birdie Bonus Data
 * Runs daily at 04:00 CET
 * 
 * Fetches ALL participants from paginated Birdie Bonus API and caches in Firestore.
 * Pattern follows updateCourseCache (scheduled PubSub, token fetch, batch writes).
 */
exports.cacheBirdieBonusData = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 540, // 9 minutes
    memory: '512MB'
  })
  .pubsub.schedule('0 4 * * *') // 04:00 CET (after other cron jobs)
  .timeZone('Europe/Copenhagen')
  .onRun(async (context) => {
    console.log('🏌️ Starting Birdie Bonus cache update...');
    const startTime = Date.now();
    const db = admin.firestore();
    
    try {
      // STEP 1: Fetch auth token
      console.log('📡 Fetching Birdie Bonus token...');
      const authToken = await fetchBirdieBonusToken();
      
      // STEP 2: Paginate through ALL pages
      // API returns: { "data": [...], "next_page": 2 } or { "next_page": null }
      console.log('📡 Fetching paginated data...');
      const allParticipants = [];
      let page = 0;
      let nextPage = 0; // Start at page 0
      
      while (nextPage !== null) {
        console.log(`  Fetching page ${page}...`);
        const result = await fetchBirdieBonusPage(page, authToken);
        
        if (result.participants.length > 0) {
          allParticipants.push(...result.participants);
          console.log(`    → Got ${result.participants.length} participants`);
        }
        
        nextPage = result.nextPage;
        if (nextPage !== null) {
          page = nextPage;
        }
      }
      
      console.log(`✅ Fetched ${allParticipants.length} participants from ${page + 1} pages`);
      
      // DEBUG: Log first 3 participants to see actual field names
      if (allParticipants.length > 0) {
        console.log('🔍 DEBUG: First 3 participants structure:');
        for (let i = 0; i < Math.min(3, allParticipants.length); i++) {
          console.log(`Participant ${i}:`, JSON.stringify(allParticipants[i], null, 2));
        }
      }
      
      // STEP 3: Write to Firestore (batch writes)
      if (allParticipants.length > 0) {
        console.log('📝 Writing to Firestore...');
        
        // Firestore batch limit: 500 operations
        const BATCH_SIZE = 500;
        let written = 0;
        
        for (let i = 0; i < allParticipants.length; i += BATCH_SIZE) {
          const batch = db.batch();
          const chunk = allParticipants.slice(i, i + BATCH_SIZE);
          
          for (const participant of chunk) {
            const dguNumber = participant.dguNumber;
            if (!dguNumber) continue;
            
            // DEBUG: Log BB participant field for first few entries
            if (written < 3) {
              console.log(`🔍 DEBUG participant ${written}:`, {
                dguNumber,
                'BB participant': participant["BB participant"],
                'BB_participant': participant["BB_participant"],
                'BBparticipant': participant["BBparticipant"],
                'bbParticipant': participant["bbParticipant"],
                allKeys: Object.keys(participant)
              });
            }
            
            // Try multiple possible field names for BB participant
            const bbParticipantValue = 
              participant["BB participant"] || 
              participant["BB_participant"] || 
              participant["BBparticipant"] ||
              participant["bbParticipant"] ||
              0;
            
            // BB participant is a sequence number (2, 3, 4, etc.) - NOT a status code!
            // All participants in the API are Birdie Bonus participants.
            // Any value > 0 means they are participating.
            const isParticipantValue = Number(bbParticipantValue) > 0;
            
            // DEBUG: Log the computed value for first few
            if (written < 3) {
              console.log(`🔍 Computed isParticipant for ${dguNumber}: ${isParticipantValue} (from value: ${bbParticipantValue})`);
            }
            
            const docRef = db.collection('birdie_bonus_cache').doc(dguNumber);
            batch.set(docRef, {
              dguNumber,
              // Field names from API (case-sensitive, some with spaces):
              // "BB participant": 2 (with space!)
              // "Birdiebonuspoints": 78 (lowercase 'p')
              // "rankInRegionGroup": 159
              birdieCount: participant.Birdiebonuspoints || 0,
              rankingPosition: participant.rankInRegionGroup || 0,
              regionLabel: participant.regionLabel || 'Ukendt',
              hcpGroupLabel: participant.hcpGroupLabel || 'Ukendt',
              isParticipant: isParticipantValue,
              updatedAt: admin.firestore.FieldValue.serverTimestamp(),
            }, { merge: true });
            written++;
          }
          
          await batch.commit();
          console.log(`  ✅ Written ${written}/${allParticipants.length}`);
        }
      }
      
      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log('🎉 Birdie Bonus cache complete!');
      console.log(`  Pages fetched: ${page + 1}`);
      console.log(`  Participants: ${allParticipants.length}`);
      console.log(`  Duration: ${duration}s`);
      
      return { success: true, participants: allParticipants.length, duration };
    } catch (error) {
      console.error('❌ Cache update failed:', error);
      throw error;
    }
  });

/**
 * TEST FUNCTION: Debug Birdie Bonus API Response
 * Callable function to test API response structure
 */
exports.testBirdieBonusAPI = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    try {
      console.log('🧪 Testing Birdie Bonus API...');
      
      // Fetch token
      const authToken = await fetchBirdieBonusToken();
      console.log('✅ Token fetched');
      
      // Fetch first page
      const result = await fetchBirdieBonusPage(0, authToken);
      console.log(`✅ Got ${result.participants.length} participants`);
      
      if (result.participants.length > 0) {
        const firstParticipant = result.participants[0];
        console.log('🔍 First participant:', JSON.stringify(firstParticipant, null, 2));
        
        return {
          success: true,
          participantCount: result.participants.length,
          firstParticipant: firstParticipant,
          allKeys: Object.keys(firstParticipant),
          bbParticipantField: firstParticipant["BB participant"],
          bbParticipantField2: firstParticipant["BB_participant"],
        };
      }
      
      return { success: false, error: 'No participants found' };
    } catch (error) {
      console.error('❌ Test failed:', error);
      return { success: false, error: error.message };
    }
  });

/**
 * MANUAL TRIGGER: Run Birdie Bonus cache update manually
 * Callable function to trigger cache update without waiting for schedule
 */
exports.manualCacheBirdieBonusData = functions
  .region('europe-west1')
  .runWith({
    timeoutSeconds: 540,
    memory: '512MB'
  })
  .https.onCall(async (data, context) => {
    console.log('🔧 Manual trigger: Birdie Bonus cache update');
    const startTime = Date.now();
    const db = admin.firestore();
    
    try {
      // STEP 1: Fetch auth token
      console.log('📡 Fetching Birdie Bonus token...');
      const authToken = await fetchBirdieBonusToken();
      
      // STEP 2: Fetch ONLY first page for testing
      console.log('📡 Fetching first page only (test mode)...');
      const result = await fetchBirdieBonusPage(0, authToken);
      const allParticipants = result.participants;
      
      console.log(`✅ Fetched ${allParticipants.length} participants (test mode - page 0 only)`);
      
      // DEBUG: Log first 3 participants
      if (allParticipants.length > 0) {
        console.log('🔍 DEBUG: First 3 participants structure:');
        for (let i = 0; i < Math.min(3, allParticipants.length); i++) {
          console.log(`Participant ${i}:`, JSON.stringify(allParticipants[i], null, 2));
        }
      }
      
      // STEP 3: Write to Firestore
      if (allParticipants.length > 0) {
        console.log('📝 Writing to Firestore...');
        
        const batch = db.batch();
        let written = 0;
        
        for (const participant of allParticipants) {
          const dguNumber = participant.dguNumber;
          if (!dguNumber) continue;
          
          // DEBUG: Log BB participant field for first few entries
          if (written < 3) {
            console.log(`🔍 DEBUG participant ${written}:`, {
              dguNumber,
              'BB participant': participant["BB participant"],
              'BB_participant': participant["BB_participant"],
              'BBparticipant': participant["BBparticipant"],
              'bbParticipant': participant["bbParticipant"],
              allKeys: Object.keys(participant)
            });
          }
          
          // Try multiple possible field names for BB participant
          const bbParticipantValue = 
            participant["BB participant"] || 
            participant["BB_participant"] || 
            participant["BBparticipant"] ||
            participant["bbParticipant"] ||
            0;
          
          // BB participant is a sequence number (2, 3, 4, etc.) - NOT a status code!
          // All participants in the API are Birdie Bonus participants.
          // Any value > 0 means they are participating.
          const isParticipantValue = Number(bbParticipantValue) > 0;
          
          // DEBUG: Log the computed value for first few
          if (written < 3) {
            console.log(`🔍 Computed isParticipant for ${dguNumber}: ${isParticipantValue} (from value: ${bbParticipantValue})`);
          }
          
          const docRef = db.collection('birdie_bonus_cache').doc(dguNumber);
          batch.set(docRef, {
            dguNumber,
            birdieCount: participant.Birdiebonuspoints || 0,
            rankingPosition: participant.rankInRegionGroup || 0,
            regionLabel: participant.regionLabel || 'Ukendt',
            hcpGroupLabel: participant.hcpGroupLabel || 'Ukendt',
            isParticipant: isParticipantValue,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          }, { merge: true });
          written++;
        }
        
        await batch.commit();
        console.log(`  ✅ Written ${written} participants`);
      }
      
      const duration = ((Date.now() - startTime) / 1000).toFixed(2);
      console.log('🎉 Manual cache update complete!');
      console.log(`  Participants: ${allParticipants.length}`);
      console.log(`  Duration: ${duration}s`);
      
      return { 
        success: true, 
        participants: allParticipants.length, 
        duration,
        message: 'Updated first page only (50 participants)'
      };
    } catch (error) {
      console.error('❌ Manual cache update failed:', error);
      return { success: false, error: error.message };
    }
  });

