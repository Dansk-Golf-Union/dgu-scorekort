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
const DGU_API_BASE = 'https://dgubasen.api.union.golfbox.io/info@ingeniumgolf.dk';
const TOKEN_GIST_URL = 'https://gist.githubusercontent.com/nhuttel/a907dd7d60bf417b584333dfd5fff74a/raw/9b743740c4a7476c79d6a03c726e0d32b4034ec6/dgu_token.txt';
const BATCH_SIZE = 20;
const API_DELAY_MS = 300;

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
    
    try {
      // 1. Fetch Basic Auth token from Gist
      console.log('📡 Fetching auth token...');
      const authToken = await fetchAuthToken();
      
      // 2. Fetch all clubs from DGU API
      console.log('📡 Fetching all clubs from DGU API...');
      const clubsRaw = await fetchClubsFromAPI(authToken);
      console.log(`✅ Found ${clubsRaw.length} clubs`);
      
      // 3. Fetch courses for each club and filter
      console.log('📡 Fetching courses for each club...');
      const clubsWithCourses = [];
      let totalCourses = 0;
      let skippedClubs = 0;
      
      for (let i = 0; i < clubsRaw.length; i++) {
        const club = clubsRaw[i];
        const clubId = club.ID;
        const clubName = club.Name || 'Unknown';
        
        try {
          console.log(`  [${i + 1}/${clubsRaw.length}] ${clubName}...`);
          
          // Fetch raw courses
          const coursesRaw = await fetchCoursesFromAPI(clubId, authToken);
          
          // Filter courses (active, current versions only)
          const filteredCourses = filterCourses(coursesRaw);
          
          console.log(`    → Filtered ${coursesRaw.length} → ${filteredCourses.length} courses`);
          
          // Add filtered courses to club data
          club.courses = filteredCourses;
          totalCourses += filteredCourses.length;
          
          // Check size (warn if >900KB)
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
          
          clubsWithCourses.push(club);
          
          // Rate limiting delay
          if (i < clubsRaw.length - 1) {
            await sleep(API_DELAY_MS);
          }
        } catch (error) {
          console.error(`    ❌ Error fetching courses for ${clubName}:`, error.message);
          // Continue with other clubs even if one fails
        }
      }
      
      console.log(`✅ Fetched ${totalCourses} courses across ${clubsWithCourses.length} clubs`);
      if (skippedClubs > 0) {
        console.log(`⚠️  Skipped ${skippedClubs} clubs (too large)`);
      }
      
      // 4. Save to Firestore
      console.log('💾 Saving cache to Firestore...');
      await saveCacheToFirestore(clubsWithCourses, totalCourses);
      
      const duration = ((Date.now() - startTime) / 1000).toFixed(0);
      console.log(`✅ Cache update completed successfully in ${duration}s`);
      
      return {
        success: true,
        clubCount: clubsWithCourses.length,
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
      path: '/info@ingeniumgolf.dk/clubs',
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
 * Fetch courses for a specific club from DGU API
 */
async function fetchCoursesFromAPI(clubId, authToken) {
  return new Promise((resolve, reject) => {
    const path = `/info@ingeniumgolf.dk/clubs/${clubId}/courses?active=1&sort=ActivationDate:1&sortTee=TotalLength:1&changedsince=20250301T000000`;
    
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
 * Filter courses: Only active, activation date <= now, latest version per template
 * Same logic as Flutter app's CacheSeedService
 */
function filterCourses(coursesRaw) {
  const currentDate = new Date();
  
  // 1. Filter: Only active courses
  let courses = coursesRaw.filter(course => course.IsActive === true);
  
  // 2. Filter: Only courses with ActivationDate <= now
  courses = courses.filter(course => {
    if (!course.ActivationDate) return true;
    
    try {
      const activationDate = parseCompactDate(course.ActivationDate);
      if (!activationDate) return true;
      return activationDate <= currentDate;
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
    clubCount: clubsWithCourses.length,
    courseCount: totalCourses,
    clubs: clubList, // Lightweight club list for instant loading
    version: 2
  });
  
  console.log('  ✅ Metadata updated');
}

/**
 * Sleep helper function
 */
function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

