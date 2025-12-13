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
  'https://dgu-scorekort.firebaseapp.com'
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
      // 1. Validate input
      const { markerUnionId, playerName, approvalUrl } = data;
      
      if (!markerUnionId || !playerName || !approvalUrl) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Missing required fields: markerUnionId, playerName, or approvalUrl'
        );
      }
      
      console.log(`  Marker: ${markerUnionId}`);
      console.log(`  Player: ${playerName}`);
      
      // 2. Fetch notification token
      console.log('  Fetching notification token...');
      const notificationToken = await fetchNotificationToken();
      
      // 3. Build notification payload
      const expiryDate = new Date();
      expiryDate.setDate(expiryDate.getDate() + 7);
      const expiryString = formatNotificationDate(expiryDate);
      
      const payload = {
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
      
      console.log('  Payload prepared');
      
      // 4. Send to DGU notification API
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
exports.golfboxCallback = functions
  .region('europe-west1')
  .https.onRequest((req, res) => {
    console.log('🔐 GolfBox OAuth callback received');
    console.log('  Method:', req.method);
    console.log('  Query params:', JSON.stringify(req.query));
    
    try {
      // 1. Extract query parameters
      const queryParams = req.query;
      const stateParam = queryParams.state;
      
      // 2. Validate that state parameter exists
      if (!stateParam) {
        console.error('❌ Missing state parameter');
        res.status(400).send('Bad Request: Missing state parameter');
        return;
      }
      
      // 3. Decode state parameter (base64 -> JSON)
      let decodedState;
      try {
        // State can be base64-encoded or URL-encoded JSON
        const stateJson = Buffer.from(stateParam, 'base64').toString('utf-8');
        console.log('  Decoded state (base64):', stateJson);
        decodedState = JSON.parse(stateJson);
      } catch (base64Error) {
        // If base64 decoding fails, try parsing as plain JSON (URL-decoded)
        try {
          console.log('  Base64 decode failed, trying plain JSON');
          decodedState = JSON.parse(decodeURIComponent(stateParam));
          console.log('  Decoded state (plain JSON):', JSON.stringify(decodedState));
        } catch (jsonError) {
          console.error('❌ Failed to decode state parameter:', jsonError.message);
          res.status(400).send('Bad Request: Invalid state parameter (not valid base64 or JSON)');
          return;
        }
      }
      
      // 4. Extract targetUrl from decoded state
      const targetUrl = decodedState.targetUrl;
      if (!targetUrl) {
        console.error('❌ Missing targetUrl in decoded state');
        res.status(400).send('Bad Request: Missing targetUrl in state parameter');
        return;
      }
      
      console.log('  Target URL:', targetUrl);
      
      // 5. Validate targetUrl against ALLOW_LIST
      const isAllowed = ALLOW_LIST.some(allowedPrefix => {
        // Check if targetUrl starts with any allowed prefix
        // For localhost, allow any port (e.g., http://localhost:3000, http://localhost:8080)
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
      
      // 6. Build redirect URL with all original query parameters
      // Parse targetUrl to check if it already has query params
      const url = new URL(targetUrl);
      
      // Append all query parameters from the original request
      Object.keys(queryParams).forEach(key => {
        url.searchParams.append(key, queryParams[key]);
      });
      
      const redirectUrl = url.toString();
      console.log('  Redirect URL:', redirectUrl);
      console.log('✅ Redirecting (302) to client');
      
      // 7. Perform 302 redirect
      res.redirect(302, redirectUrl);
      
    } catch (error) {
      console.error('❌ Unexpected error in golfboxCallback:', error);
      console.error('  Stack trace:', error.stack);
      res.status(500).send('Internal Server Error');
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
      
      // Token format: "basic c3RhdGlzdGlrOk5pY2swMDA3"
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

