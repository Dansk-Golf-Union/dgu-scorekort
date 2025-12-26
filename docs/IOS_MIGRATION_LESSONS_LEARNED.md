# iOS Migration - Lessons Learned fra DGU POC App

Dette dokument beskriver alle problemer og løsninger vi stødte på da vi migrerede DGU POC appen fra kun web til også at understøtte iOS som native app.

**Formål:** Reference guide til brug når Short Game appen skal migreres til iOS.

---

## Overordnet Kontekst

**Udgangspunkt:**
- Flutter web app (kun web platform)
- Firebase backend (Firestore, Cloud Functions)
- OAuth flow via Golfbox
- Deep links via `go_router`
- Deploy til Firebase Hosting

**Mål:**
- Tilføje iOS platform support
- Kunne bygge og køre på iOS simulator
- Kunne archive og distribuere via TestFlight
- Bevare 100% web funktionalitet

---

## Problem 1: Web-Specific Dependencies (`dart:html`, `dart:ui_web`)

### Hvad Skete:
Når vi forsøgte at bygge for iOS første gang, fik vi compile errors:
```
Error: Dart library 'dart:html' is not available on this platform.
Error: Dart library 'dart:ui_web' is not available on this platform.
```

**Årsag:** 
- `dart:html` og `dart:ui_web` er kun tilgængelige på web platform
- Vi brugte dem direkte i:
  - `lib/main.dart` - til browser URL manipulation
  - `lib/providers/auth_provider.dart` - til at rydde OAuth params fra URL
  - `lib/screens/marker_approval_from_url_screen.dart` - til at lukke browser window
  - `lib/screens/home_screen.dart` - til `HtmlElementView` for billeder

### Løsning:
Implementeret **conditional imports** og platform-specific utilities:

#### 1. Oprettet Web Utils med Conditional Imports

**Filer oprettet:**
- `lib/utils/web_utils.dart` (web implementation)
- `lib/utils/web_utils_stub.dart` (iOS/Android stub)

**`lib/utils/web_utils.dart`:**
```dart
import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class WebUtils {
  static String getBrowserUrl() {
    if (kIsWeb) {
      return html.window.location.href;
    }
    return '';
  }

  static void cleanOAuthParametersFromUrl() {
    if (kIsWeb) {
      try {
        final uri = Uri.parse(html.window.location.href);
        final cleanUri = uri.replace(
          queryParameters: {},
          fragment: '',
        );
        html.window.history.replaceState({}, '', cleanUri.toString());
        debugPrint('✅ Cleaned OAuth parameters from URL');
      } catch (e) {
        debugPrint('⚠️ Failed to clean URL: $e');
      }
    }
  }

  static void closeBrowserWindow() {
    if (kIsWeb) {
      html.window.close();
    }
  }
}
```

**`lib/utils/web_utils_stub.dart`:**
```dart
// Stub for non-web platforms
class WebUtils {
  static String getBrowserUrl() => '';
  static void cleanOAuthParametersFromUrl() {}
  static void closeBrowserWindow() {}
}
```

**Brug af conditional imports i kode:**
```dart
import 'utils/web_utils.dart'
    if (dart.library.html) 'utils/web_utils.dart'
    if (dart.library.io) 'utils/web_utils_stub.dart' as web_utils;

// Brug:
web_utils.cleanOAuthParametersFromUrl();
```

#### 2. Oprettet HTML Image Utils

**Filer oprettet:**
- `lib/utils/html_image_web.dart` (web implementation med `HtmlElementView`)
- `lib/utils/html_image_stub.dart` (iOS/Android stub med standard `Image.network`)

**`lib/utils/html_image_web.dart`:**
```dart
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget buildHtmlImage(String imageUrl, double width, double height) {
  final String viewType = 'img-${imageUrl.hashCode}';

  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final img = html.ImageElement()
        ..src = imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '4px';
      return img;
    },
  );

  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(4),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: HtmlElementView(viewType: viewType),
    ),
  );
}
```

**`lib/utils/html_image_stub.dart`:**
```dart
import 'package:flutter/material.dart';

Widget buildHtmlImage(String imageUrl, double width, double height) {
  return Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: Colors.grey.shade300),
      borderRadius: BorderRadius.circular(4),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        imageUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.error, color: Colors.red),
      ),
    ),
  );
}
```

#### 3. Opdateret Filer til at Bruge Conditional Imports

**Filer modificeret:**
- `lib/main.dart`
- `lib/providers/auth_provider.dart`
- `lib/screens/marker_approval_from_url_screen.dart`
- `lib/screens/home_screen.dart`

**Eksempel fra `lib/main.dart`:**
```dart
import 'utils/web_utils.dart'
    if (dart.library.html) 'utils/web_utils.dart'
    if (dart.library.io) 'utils/web_utils_stub.dart' as web_utils;

// I redirect logic:
final browserUrl = web_utils.getBrowserUrl();
if (browserUrl.contains('/friend-request/') || 
    browserUrl.contains('/marker-approval/')) {
  return null;
}
```

**Eksempel fra `lib/screens/marker_approval_from_url_screen.dart`:**
```dart
import 'package:flutter/foundation.dart'; // For kIsWeb
import '../utils/web_utils.dart'
    if (dart.library.html) '../utils/web_utils.dart'
    if (dart.library.io) '../utils/web_utils_stub.dart' as web_utils;

// I widget:
if (kIsWeb)
  OutlinedButton.icon(
    onPressed: () {
      web_utils.closeBrowserWindow();
    },
    icon: const Icon(Icons.close),
    label: const Text('Luk Scorekort'),
  ),
```

### Key Takeaways:
- ✅ **Aldrig import `dart:html` eller `dart:ui_web` direkte** i filer der skal kompilere til iOS
- ✅ **Brug conditional imports**: `if (dart.library.html)` for web, `if (dart.library.io)` for mobile
- ✅ **Wrap platform-specific kode i `kIsWeb` checks** for runtime checks
- ✅ **Opret stub implementations** for alle platform-specific utilities

---

## Problem 2: Manglende iOS Platform Files

### Hvad Skete:
Første `flutter build ios` fejlede med:
```
Application not configured for iOS
```

**Årsag:**
Flutter projektet var kun konfigureret med web platform. `ios/` mappen eksisterede men manglede kritiske filer.

### Løsning:

#### 1. Regenerer iOS Platform Files
```bash
flutter create --platforms=ios .
```

Dette kommando:
- Opdaterede `ios/` folder struktur
- Beholdt eksisterende filer (som `Info.plist`)
- Tilføjede manglende iOS platform metadata

#### 2. Opdater iOS Podfile
Opdateret `ios/Podfile` til at bruge iOS 13.0 minimum:
```ruby
platform :ios, '13.0'  # Var oprindeligt 9.0
```

**Hvorfor:** iOS 9.0 er ikke længere understøttet af moderne Firebase SDKs og resulterede i CocoaPods warnings.

#### 3. Installer CocoaPods Dependencies
```bash
cd ios
pod install
```

Dette installerer alle native iOS dependencies (Firebase, url_launcher, etc.)

### Key Takeaways:
- ✅ **Brug `flutter create --platforms=ios .`** til at scaffolde iOS support
- ✅ **Opdater `Podfile` platform version** til mindst iOS 12.0 (eller 13.0)
- ✅ **Kør `pod install`** efter enhver ændring i `pubspec.yaml` dependencies

---

## Problem 3: Firebase iOS Configuration

### Hvad Skete:
iOS build'et kompilerede men runtime fejlede med Firebase initialization errors.

**Årsag:**
Firebase kræver platform-specific configuration files:
- Web: `firebase_options.dart` (allerede havde vi)
- iOS: `GoogleService-Info.plist` (manglede)

### Løsning:

#### 1. Download GoogleService-Info.plist
Fra Firebase Console:
1. Gå til Project Settings → Your Apps
2. Klik på iOS app (hvis den ikke findes, tilføj den med Bundle ID)
3. Download `GoogleService-Info.plist`
4. Placer i `ios/Runner/` folder

#### 2. Opdater firebase_options.dart
Tilføj iOS platform configuration baseret på `GoogleService-Info.plist`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'dart:io'; // For Platform.isIOS
import 'package:flutter/foundation.dart'; // For kIsWeb

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return ios;
    }
    // ... android, etc.
    throw UnsupportedError('Unsupported platform');
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBF5rKJ_ajZD49-znVAQgTtCG4uTvCa4x4',
    appId: '1:822805581464:web:bc8fb9a866bc6da5f64aed',
    messagingSenderId: '822805581464',
    projectId: 'dgu-scorekort',
    authDomain: 'dgu-scorekort.firebaseapp.com',
    storageBucket: 'dgu-scorekort.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBF5rKJ_ajZD49-znVAQgTtCG4uTvCa4x4',
    appId: '1:822805581464:ios:ac5af92e840566a6f64aed',
    messagingSenderId: '822805581464',
    projectId: 'dgu-scorekort',
    storageBucket: 'dgu-scorekort.firebasestorage.app',
    iosBundleId: 'org.nih.dgupoc',
  );
}
```

**Vigtigt:** `iosBundleId` skal matche Bundle ID i Xcode project.

### Key Takeaways:
- ✅ **Download `GoogleService-Info.plist` fra Firebase Console**
- ✅ **Placer den i `ios/Runner/` (samme niveau som `Info.plist`)**
- ✅ **Opdater `firebase_options.dart` med iOS configuration**
- ✅ **Bundle ID skal være identisk i Firebase Console og Xcode**

---

## Problem 4: iOS Deep Linking Configuration

### Hvad Skete:
OAuth callback fra Golfbox fungerede ikke på iOS.

**Årsag:**
iOS kræver URL schemes registreret i `Info.plist` for at modtage deep links.

### Løsning:

#### 1. Opdater Info.plist
Tilføj URL schemes til `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>org.nih.dgupoc</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>dgupoc</string>
        </array>
    </dict>
</array>
```

Dette tillader app'en at håndtere URLs som: `dgupoc://login?code=...`

#### 2. Opdater Cloud Function for iOS Detection
Modificeret `functions/index.js` `golfboxCallback` til at detektere iOS og redirecte til custom scheme:

```javascript
exports.golfboxCallback = functions.https.onRequest((req, res) => {
  const { code, state } = req.query;
  
  // Detect iOS user-agent
  const userAgent = req.headers['user-agent'] || '';
  const isIOS = /iPhone|iPad|iPod/.test(userAgent);

  if (isIOS) {
    res.redirect(`dgupoc://login?code=${code}&state=${state}`);
  } else {
    res.redirect(`https://dgu-app-poc.web.app/login?code=${code}&state=${state}`);
  }
});
```

### Key Takeaways:
- ✅ **Registrer custom URL scheme i `Info.plist`** (format: `appname://`)
- ✅ **URL scheme skal være unik** (check at den ikke konflikter med andre apps)
- ✅ **Opdater backend** til at detektere iOS og redirecte til custom scheme
- ✅ **`go_router` håndterer automatisk deep links** hvis de er korrekt registreret

---

## Problem 5: Xcode Environment Setup

### Hvad Skete:
Forskellige Xcode-relaterede fejl under setup:
- "Xcode installation is incomplete"
- "CocoaPods not installed"
- iOS simulators ikke tilgængelige

### Løsning:

#### 1. Configure Xcode Command Line Tools
```bash
sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license accept
```

#### 2. Install CocoaPods
```bash
sudo gem install cocoapods
```

#### 3. Download iOS Simulators
I Xcode:
- Xcode → Settings → Platforms → Download iOS Simulators

#### 4. Restart Flutter Daemon (hvis simulators ikke vises)
```bash
killall -9 dart
flutter devices  # Dette restarter daemon
```

### Key Takeaways:
- ✅ **Run `flutter doctor -v`** for at identificere setup problemer
- ✅ **Accept Xcode license** med `sudo xcodebuild -license accept`
- ✅ **Install CocoaPods** (kræves af Flutter for iOS dependencies)
- ✅ **Download mindst én iOS simulator** via Xcode Settings

---

## Problem 6: Build Number Management

### Hvad Skete:
TestFlight kræver unikke build numbers for hver upload.

**Årsag:**
Apple bruger build number til at skelne mellem forskellige builds af samme version.

### Løsning:

#### Increment Build Number i pubspec.yaml
Før hver ny archive/upload:

```yaml
version: 2.0.0+8  # +8 er build number (increment fra +7)
```

**Alternativt:** Opdater direkte i `ios/Runner/Info.plist`:
```xml
<key>CFBundleVersion</key>
<string>8</string>
```

### Key Takeaways:
- ✅ **Increment build number** før hver TestFlight upload
- ✅ **Version format**: `major.minor.patch+build` (f.eks. `2.0.0+8`)
- ✅ **Build number skal være større** end den forrige upload
- ✅ **Kan automatiseres** i CI/CD pipeline

---

## Problem 7: CocoaPods Sync Issues

### Hvad Skete:
Archive fejlede med:
```
The sandbox is not in sync with the Podfile.lock
```

**Årsag:**
Efter ændringer i `pubspec.yaml` (f.eks. build number increment) skal CocoaPods dependencies resynces.

### Løsning:

#### Resync CocoaPods
```bash
cd ios
pod install
```

**Alternativt (ved større problemer):**
```bash
cd ios
rm -rf Pods Podfile.lock
pod install
```

### Key Takeaways:
- ✅ **Kør `pod install` efter ENHVER `pubspec.yaml` ændring**
- ✅ **Hvis pod install fejler**, prøv at slette `Pods/` og `Podfile.lock` først
- ✅ **CocoaPods cache kan korruptes** - `pod cache clean --all` kan hjælpe

---

## Problem 8: Code Signing (Første Gang)

### Hvad Skete:
Archive fejlede med:
- "Communication with Apple failed: Your team has no devices"
- "No profiles for 'org.nih.dgupoc' were found"

**Årsag:**
Apple Developer Portal kræver:
1. Registreret Bundle ID
2. Mindst ét registreret device for development profiles

### Løsning:

#### 1. Register Bundle ID i Apple Developer Portal
https://developer.apple.com/account/resources/identifiers/list
- Opret App ID med explicit Bundle ID (f.eks. `org.nih.dgupoc`)

#### 2. Register Test Device
https://developer.apple.com/account/resources/devices/list
- Find device UDID via Xcode → Window → Devices and Simulators
- Registrer device med navn og UDID

#### 3. Configure Automatic Signing i Xcode
I Xcode project settings → Signing & Capabilities:
- ✅ Check "Automatically manage signing"
- Vælg team fra dropdown
- Xcode opretter automatisk certificates og provisioning profiles

#### 4. Fix Keychain Access (hvis nødvendigt)
Hvis password prompts bliver ved med at komme:
- Åbn Keychain Access (Nøglering) app
- Find "Apple Development" certificate
- Dobbeltklik → Adgangskontrol tab
- Vælg "Tillad alle programmer at få adgang til denne post"

### Key Takeaways:
- ✅ **Register Bundle ID i Developer Portal FØRST**
- ✅ **Register mindst ét test device** for development testing
- ✅ **Brug Automatic Signing** (lettere end manual signing)
- ✅ **Keychain prompts kan fixes** ved at give Xcode permanent adgang til certificate

---

## Problem 9: iOS OAuth Deep Link Login Loop

### Hvad Skete:
iOS native app gik i en uendelig login loop efter OAuth callback. Første token exchange lykkedes (HTTP 200), men derefter forsøgte appen at exchange den samme authorization code hundredvis af gange, hvilket resulterede i `invalid_grant` fejl.

**Symptomer:**
- App viser login skærm i rapid loop ("blinker")
- Xcode console: `Status code: 200` første gang, derefter mange `Status code: 500`, `invalid_grant` fejl
- `_handleDeepLink` kaldes hundredvis af gange med samme OAuth code
- Guards logges (`⚠️ Ignoring duplicate`) men stopper ikke eksekveringen

**Årsag:**
Flutter `LoginScreen` widget rebuilder gentagne gange under OAuth flow, hvilket:
1. Nulstiller instance variables (`_lastProcessedCode`, `_isProcessingCallback`) 
2. Skaber nye deep link listeners UDEN at dispose de gamle (memory leak)
3. Resulterer i multiple aktive listeners der alle processor samme OAuth code

**Root cause:** Deep link listener og guards var placeret i `StatefulWidget` state, som ikke overlever widget rebuilds. Hver gang `notifyListeners()` kaldes fra `AuthProvider` (efter token exchange), rebuildes `LoginScreen`, og et NYT `_LoginScreenState` objekt oprettes med nulstillede guards.

### Løsning:

**Midlertidig status:** Web app virker perfekt (bruger JSON state format uden iOS-specific kode). iOS OAuth implementation er midlertidigt deaktiveret indtil fix.

**Anbefalet fix (fremtidig):** Move deep link listener til `AuthProvider` eller singleton service:

```dart
// lib/providers/auth_provider.dart

class AuthProvider with ChangeNotifier {
  StreamSubscription<Uri>? _deepLinkSubscription;
  String? _lastProcessedOAuthCode;
  bool _isProcessingOAuthCallback = false;
  
  void initDeepLinkListener() {
    if (kIsWeb) return;
    
    final appLinks = AppLinks();
    _deepLinkSubscription = appLinks.uriLinkStream.listen(
      (uri) => _handleDeepLink(uri),
    );
  }
  
  @override
  void dispose() {
    _deepLinkSubscription?.cancel();
    super.dispose();
  }
}

// lib/main.dart
void main() async {
  final authProvider = AuthProvider();
  authProvider.initDeepLinkListener(); // Initialize ONCE at startup
  
  runApp(
    ChangeNotifierProvider.value(
      value: authProvider,
      child: const MyApp(),
    ),
  );
}
```

**Hvorfor dette virker:**
- `AuthProvider` er singleton (lever hele app lifecycle)
- State variables survives widget rebuilds
- Single listener per app session (no duplicates)

### Detaljeret Dokumentation:
For komplet technical analysis, timeline diagrams, Xcode console output, og multiple solution options, se:
**[IOS_OAUTH_LOGIN_LOOP_ISSUE.md](./IOS_OAUTH_LOGIN_LOOP_ISSUE.md)**

### Key Takeaways:
- ❌ **Placer ALDRIG deep link listeners i StatefulWidget state** - de resettes ved rebuilds
- ✅ **Placer listeners i Provider eller singleton** - de overlever rebuilds
- ✅ **Initialize listeners i `main()`** før widget tree oprettes
- ✅ **Guards skal være persistent** - ikke widget instance variables
- ✅ **Web app påvirkes IKKE** - platform checks isolerer iOS-specific kode

---

## Optimalt Workflow for Næste App (Short Game)

### 1. Før Du Starter:
```bash
# Verificer environment
flutter doctor -v
# Alle checks skal være grønne for iOS development
```

### 2. Setup iOS Platform:
```bash
# Tilføj iOS platform
flutter create --platforms=ios .

# Download Firebase iOS config
# Placer GoogleService-Info.plist i ios/Runner/

# Opdater Podfile
# Sæt platform til iOS 13.0

# Install dependencies
cd ios && pod install && cd ..
```

### 3. Code Changes (Før Første Build):
- [ ] Opret `lib/utils/web_utils.dart` og `lib/utils/web_utils_stub.dart`
- [ ] Opret `lib/utils/html_image_web.dart` og `lib/utils/html_image_stub.dart`
- [ ] Find alle steder der bruger `dart:html` eller `dart:ui_web`
- [ ] Erstat med conditional imports og platform checks
- [ ] Test at web stadig virker: `flutter run -d chrome`

### 4. iOS Configuration:
- [ ] Opdater `ios/Runner/Info.plist`:
  - Bundle ID
  - Display Name
  - URL Schemes (for deep linking)
- [ ] Opdater `lib/config/firebase_options.dart` med iOS config
- [ ] Opdater Cloud Functions med iOS detection (hvis relevant)

### 5. Første iOS Build:
```bash
# Clean build
flutter clean

# Build for simulator først
flutter build ios --simulator --debug

# Hvis success, prøv på device
flutter run -d "Your iPhone"
```

### 6. Fix Linter Errors:
```bash
# Check for iOS-specific issues
flutter analyze
```

### 7. Archive & TestFlight:
- [ ] Increment build number i `pubspec.yaml`
- [ ] Sync pods: `cd ios && pod install`
- [ ] Clean build folder i Xcode (⌘⇧K)
- [ ] Archive i Xcode: Product → Archive
- [ ] Upload til TestFlight (automatic signing)
- [ ] Configure Internal Testing i App Store Connect

---

## Checklist for Short Game App

### Platform-Specific Code Review:
```bash
# Find alle imports af dart:html
grep -r "import 'dart:html'" lib/

# Find alle imports af dart:ui_web
grep -r "import 'dart:ui_web'" lib/

# Find alle imports af package:flutter_web_plugins
grep -r "import 'package:flutter_web_plugins'" lib/

# Find alle HtmlElementView brugs
grep -r "HtmlElementView" lib/
```

### File Checklist:
- [ ] `ios/Runner/GoogleService-Info.plist` - Downloaded fra Firebase
- [ ] `ios/Runner/Info.plist` - Bundle ID, Display Name, URL Schemes
- [ ] `ios/Podfile` - Platform version 13.0
- [ ] `lib/config/firebase_options.dart` - iOS FirebaseOptions tilføjet
- [ ] `lib/utils/web_utils.dart` + stub - Web utilities isolated
- [ ] `lib/utils/html_image_web.dart` + stub - HTML image utilities isolated
- [ ] `lib/main.dart` - Conditional imports for web_utils
- [ ] `pubspec.yaml` - Build number ready for increment

### Common Pitfalls at Undgå:
1. ❌ **Aldrig hardcode platform-specific imports** i shared code
2. ❌ **Glem ikke at run `pod install`** efter `pubspec.yaml` changes
3. ❌ **Test BÅDE web og iOS** efter hver større ændring
4. ❌ **Increment ikke build number** før du er klar til upload
5. ❌ **Brug ikke samme Bundle ID** som eksisterende apps
6. ❌ **Placer IKKE deep link listeners i StatefulWidget** - de resettes ved rebuilds
   - **Se:** [IOS_OAUTH_LOGIN_LOOP_ISSUE.md](./IOS_OAUTH_LOGIN_LOOP_ISSUE.md) for detaljeret analyse af OAuth loop problem
   - **Løsning:** Placer listeners i Provider eller singleton service

---

## Nyttige Commands Reference

```bash
# Flutter commands
flutter doctor -v
flutter clean
flutter pub get
flutter build ios --simulator --debug
flutter build ios --release
flutter run -d chrome  # Test web
flutter run -d "iPhone 16 Plus"  # Test iOS simulator
flutter devices  # List available devices

# CocoaPods commands
cd ios && pod install
cd ios && pod update
cd ios && pod cache clean --all

# Xcode commands
xcodebuild clean
xcodebuild -list  # List schemes and targets

# Git branch management
git checkout -b feature/ios-support
git add .
git commit -m "feat: add iOS platform support"
```

---

## Estimeret Tidsforbrug

**For Short Game app migration (baseret på POC erfaring):**

1. **Platform Setup** (1-2 timer)
   - iOS folder setup
   - CocoaPods installation
   - Firebase iOS config

2. **Code Refactoring** (3-5 timer)
   - Identificer web-specific code
   - Implementer conditional imports
   - Test på både web og iOS

3. **iOS Configuration** (1 timer)
   - Info.plist updates
   - Deep linking setup
   - Bundle ID configuration

4. **Testing & Debugging** (2-4 timer)
   - Fix runtime errors
   - Test alle features på iOS
   - Verify web stadig virker

5. **Archive & TestFlight** (1 time)
   - Archive i Xcode
   - Upload til TestFlight
   - Configure test groups

**Total: 8-13 timer** (afhængig af kompleksitet og antal web-specific dependencies)

---

## Kontakt Points med Golfbox/Backend Team

**Hvis Short Game app også har OAuth integration:**

1. **Cloud Function Updates**
   - Tilføj iOS detection i OAuth callback
   - Redirect til custom URL scheme for iOS

2. **URL Whitelist**
   - Tilføj app URL scheme til tilladt liste
   - Test OAuth flow på både web og iOS

3. **API Endpoints**
   - Verificer at alle API calls virker fra iOS
   - Check CORS settings hvis relevant

---

## Dokumentation Links

- [Flutter Platform Integration Docs](https://docs.flutter.dev/platform-integration)
- [Firebase iOS Setup](https://firebase.google.com/docs/ios/setup)
- [Apple Deep Linking](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)
- [CocoaPods Guides](https://guides.cocoapods.org/)
- [TestFlight Distribution](https://developer.apple.com/testflight/)

---

**Document Created:** December 26, 2025  
**App:** DGU POC (dgu_scorekort)  
**Flutter Version:** 3.10.3  
**iOS Deployment Target:** 13.0

