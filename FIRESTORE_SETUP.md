# Firestore Setup Guide

## 1. Enable Firestore Database

1. Gå til [Firebase Console](https://console.firebase.google.com/)
2. Vælg dit projekt: **dgu-scorekort**
3. I venstre menu, klik på **Firestore Database**
4. Klik på **Create database**
5. Vælg **Start in test mode** (vi ændrer rules senere)
6. Vælg location: **europe-west1** (eller nærmeste til Danmark)
7. Klik på **Enable**

## 2. Configure Security Rules

Efter databasen er oprettet:

1. Gå til **Firestore Database → Rules** tab
2. Erstat det eksisterende indhold med nedenstående rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Scorecard collection rules
    match /scorecards/{scorecardId} {
      // Anyone can read scorecards (for marker approval via URL)
      allow read: if true;
      
      // Authenticated users can create scorecards
      allow create: if request.auth != null || true; // Allow for now during testing
      
      // Anyone can update (for marker approval)
      // In production, add authentication check
      allow update: if true;
      
      // Only allow deletion by authenticated users
      allow delete: if request.auth != null;
    }
  }
}
```

3. Klik på **Publish**

## 3. Test Security Rules (Optional)

I Firebase Console under **Rules** tab kan du teste dine rules:

**Test Read:**
```
match /scorecards/test123
allow read
```

**Test Write:**
```
match /scorecards/test123
allow write
data: { "playerId": "123-4567", "status": "pending" }
```

## 4. Production Security Rules (Implementer senere)

Når du er klar til production, stram security rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    match /scorecards/{scorecardId} {
      // Only players and assigned markers can read
      allow read: if request.auth != null && (
        request.auth.token.unionId == resource.data.playerId ||
        request.auth.token.unionId == resource.data.markerId
      );
      
      // Only authenticated players can create
      allow create: if request.auth != null &&
        request.auth.token.unionId == request.resource.data.playerId;
      
      // Only assigned marker can approve
      allow update: if request.auth != null &&
        request.auth.token.unionId == resource.data.markerId &&
        request.resource.data.status in ['approved', 'rejected'];
      
      // No deletion allowed
      allow delete: if false;
    }
  }
}
```

## 5. Indexes (Opret hvis nødvendigt)

Firestore vil automatisk foreslå indexes når du bruger queries med multiple where/orderBy clauses.

Eksempel queries der muligvis kræver indexes:
- `where('markerId', '==', ...).where('status', '==', 'pending').orderBy('createdAt')`
- `where('playerId', '==', ...).orderBy('playedDate')`

Firebase Console vil vise en fejl med et link til at oprette indexet automatisk.

## 6. Bekræft Setup

Kør test-funktionen i appen for at bekræfte at alt virker korrekt.

