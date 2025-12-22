/**
 * ONE-TIME SCRIPT: Seed user_stats for existing users
 * 
 * Run once after deploying Cloud Functions to populate initial stats
 * After this, triggers will keep stats updated automatically
 * 
 * Usage:
 *   node seed_user_stats.js
 * 
 * Prerequisites:
 *   1. Deploy Cloud Functions first: firebase deploy --only functions
 *   2. Ensure serviceAccountKey.json is in project root
 *   3. Run: node seed_user_stats.js
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin (requires serviceAccountKey.json in project root)
// Download from: Firebase Console → Project Settings → Service Accounts
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('✅ Firebase Admin initialized');
} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin');
  console.error('   Make sure serviceAccountKey.json exists in project root');
  console.error('   Download from: Firebase Console → Project Settings → Service Accounts');
  process.exit(1);
}

const db = admin.firestore();

/**
 * Main seeding function
 */
async function seedUserStats() {
  console.log('🌱 Seeding user_stats for existing users...\n');
  const startTime = Date.now();
  
  try {
    // Get all unique user IDs from friendships collection
    console.log('📋 Fetching all friendships...');
    const friendshipsSnapshot = await db.collection('friendships').get();
    const userIds = new Set();
    
    friendshipsSnapshot.docs.forEach(doc => {
      const data = doc.data();
      userIds.add(data.userId1);
      userIds.add(data.userId2);
    });
    
    console.log(`✅ Found ${userIds.size} unique users with friendships\n`);
    
    if (userIds.size === 0) {
      console.log('⚠️  No users found. Nothing to seed.');
      process.exit(0);
    }
    
    // Update stats for each user
    let processed = 0;
    let succeeded = 0;
    let failed = 0;
    
    for (const unionId of userIds) {
      try {
        await updateUserStats(db, unionId);
        succeeded++;
        processed++;
        
        // Progress indicator every 10 users
        if (processed % 10 === 0 || processed === userIds.size) {
          console.log(`  Progress: ${processed}/${userIds.size} (${succeeded} ✅, ${failed} ❌)`);
        }
      } catch (error) {
        failed++;
        processed++;
        console.error(`  ❌ Failed for ${unionId}:`, error.message);
      }
    }
    
    const duration = ((Date.now() - startTime) / 1000).toFixed(1);
    
    console.log('\n🎉 Seeding complete!');
    console.log(`📊 Total: ${userIds.size} users`);
    console.log(`✅ Succeeded: ${succeeded}`);
    console.log(`❌ Failed: ${failed}`);
    console.log(`⏱️  Duration: ${duration}s\n`);
    
    process.exit(0);
  } catch (error) {
    console.error('\n❌ Seeding failed:', error);
    process.exit(1);
  }
}

/**
 * Calculate and update user_stats for a specific user
 * (Same logic as Cloud Function trigger)
 */
async function updateUserStats(db, unionId) {
  console.log(`  📊 ${unionId}...`);
  
  try {
    // 1. Count friendships
    const friendships1 = await db.collection('friendships')
      .where('userId1', '==', unionId)
      .where('status', '==', 'active')
      .get();
    
    const friendships2 = await db.collection('friendships')
      .where('userId2', '==', unionId)
      .where('status', '==', 'active')
      .get();
    
    const allFriendships = [...friendships1.docs, ...friendships2.docs];
    
    // Count by relationType
    let fullFriends = 0;
    let contacts = 0;
    
    allFriendships.forEach(doc => {
      const relationType = doc.data().relationType || 'friend';
      if (relationType === 'friend') {
        fullFriends++;
      } else {
        contacts++;
      }
    });
    
    const totalFriends = fullFriends + contacts;
    
    // 2. Count chat groups (exclude hidden)
    const groupsSnapshot = await db.collection('chat_groups')
      .where('members', 'array-contains', unionId)
      .get();
    
    const visibleGroups = groupsSnapshot.docs.filter(doc => {
      const hiddenFor = doc.data().hiddenFor || [];
      return !hiddenFor.includes(unionId);
    });
    
    const totalChatGroups = visibleGroups.length;
    
    // 3. Calculate unread count
    let unreadCount = 0;
    
    for (const groupDoc of visibleGroups) {
      const groupData = groupDoc.data();
      const unreadMap = groupData.unreadCount || {};
      const userUnread = unreadMap[unionId] || 0;
      unreadCount += userUnread;
    }
    
    // 4. Write to user_stats
    await db.collection('user_stats').doc(unionId).set({
      unionId,
      totalFriends,
      fullFriends,
      contacts,
      unreadChatCount: unreadCount,
      totalChatGroups,
      lastUpdated: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    
    console.log(`    ✅ ${totalFriends} friends, ${totalChatGroups} chats, ${unreadCount} unread`);
  } catch (error) {
    console.error(`    ❌ Failed for ${unionId}:`, error.message);
    throw error;
  }
}

// Run the seeding
seedUserStats();

