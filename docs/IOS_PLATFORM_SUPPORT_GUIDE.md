# iOS Platform Support Guide

**Formål:** Guide til at tilføje iOS platform support til en Flutter web app uden at påvirke web funktionalitet.

**Baseret på:** DGU POC app migration (Dec 2025)  
**Anvendes til:** Short Game app og andre Flutter web → iOS migrationer

---

## Problemet

Flutter web apps bruger ofte web-only libraries som `dart:html` og `dart:ui_web`, der ikke er tilgængelige på iOS/Android. Dette forårsager build fejl når man prøver at compile til native platforme.

**Typiske fejl:**
```
Error: Dart library 'dart:html' is not available on this platform.
Error: Dart library 'dart:ui_web' is not available on this platform.
```

---

## Løsningen: Conditional Imports + Platform Guards

Vi bruger Dart's **conditional imports** kombineret med **platform checks** (`kIsWeb`) for at isolere web-specific kode.

### Pattern:

```dart
// Import med conditional fallback
import 'utils/feature_web.dart' if (dart.library.io) 'utils/feature_stub.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Runtime check
if (kIsWeb) {
  // Web-only kode
} else {
  // iOS/Android alternative eller no-op
}
```

---

## Step-by-Step Implementation

### 1. Identificer Web-Only Kode

Find alle steder hvor `dart:html` eller `dart:ui_web` bruges:

```bash
# I din Flutter projekt mappe:
grep -r "import 'dart:html'" lib/
grep -r "import 'dart:ui_web'" lib/
```

**Typiske use cases:**
- `html.window.location.href` (URL manipulation)
- `html.window.history.replaceState()` (History API)
- `html.window.close()` (Luk browser tab)
- `html.ImageElement()` (HTML img tags)
- `ui_web.platformViewRegistry` (Embed HTML elements)

### 2. Lav Platform-Specific Utilities

#### A. Browser/Window Operations

**`lib/utils/web_utils.dart`** (Web implementation):
```dart
// Web-specific utilities
import 'dart:html' as html;

/// Get current browser URL (web only)
String? getCurrentUrl() {
  try {
    return html.window.location.href;
  } catch (e) {
    return null;
  }
}

/// Clean OAuth parameters from browser URL (web only)
void cleanUrlParams() {
  try {
    final uri = Uri.parse(html.window.location.href);
    final cleanUri = uri.replace(
      queryParameters: {},
      fragment: '',
    );
    html.window.history.replaceState({}, '', cleanUri.toString());
  } catch (e) {
    // Silently fail
  }
}

/// Close browser window/tab (web only)
void closeWindow() {
  try {
    html.window.close();
  } catch (e) {
    // Silently fail
  }
}
```

**`lib/utils/web_utils_stub.dart`** (iOS/Android stub):
```dart
// Stub for non-web platforms

/// Get current browser URL (not available on native)
String? getCurrentUrl() {
  return null;
}

/// Clean OAuth parameters (no-op on native)
void cleanUrlParams() {
  // No-op
}

/// Close browser window (no-op on native)
void closeWindow() {
  // No-op
}
```

#### B. HTML Image Rendering (hvis relevant)

**`lib/utils/html_image_web.dart`**:
```dart
import 'package:flutter/material.dart';
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;

Widget buildHtmlImage(String imageUrl, double width, double height) {
  final String viewType = 'img-${imageUrl.hashCode}';
  
  ui_web.platformViewRegistry.registerViewFactory(
    viewType,
    (int viewId) {
      final img = html.ImageElement()
        ..src = imageUrl
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';
      return img;
    },
  );

  return Container(
    width: width,
    height: height,
    child: HtmlElementView(viewType: viewType),
  );
}
```

**`lib/utils/html_image_stub.dart`**:
```dart
import 'package:flutter/material.dart';

Widget buildHtmlImage(String imageUrl, double width, double height) {
  // Fallback: Standard network image (eller placeholder)
  return Container(
    width: width,
    height: height,
    child: Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(Icons.image, size: width / 2);
      },
    ),
  );
}
```

### 3. Opdater Filer Med Web-Only Kode

For hver fil identificeret i step 1:

#### A. Fjern direkte `dart:html` imports

**Før:**
```dart
import 'dart:html' as html;
```

**Efter:**
```dart
import 'package:flutter/foundation.dart' show kIsWeb;
import 'utils/web_utils.dart' if (dart.library.io) 'utils/web_utils_stub.dart';
```

#### B. Erstat direkte web API calls

**Før:**
```dart
final url = html.window.location.href;
html.window.history.replaceState({}, '', cleanUrl);
html.window.close();
```

**Efter:**
```dart
final url = getCurrentUrl() ?? '';
cleanUrlParams();
closeWindow();
```

#### C. Tilføj platform guards hvor nødvendigt

**Eksempel 1: Routing logic (main.dart)**

**Før:**
```dart
redirect: (context, state) {
  final browserUrl = html.window.location.href;
  
  if (browserUrl.contains('/public-route/')) {
    return null;
  }
  // ... auth logic
}
```

**Efter:**
```dart
redirect: (context, state) {
  // Only check browser URL on web
  if (kIsWeb) {
    final browserUrl = getCurrentUrl() ?? '';
    
    if (browserUrl.contains('/public-route/')) {
      return null;
    }
  }
  // ... auth logic
}
```

**Eksempel 2: UI Elements**

**Før:**
```dart
OutlinedButton(
  onPressed: () {
    html.window.close();
  },
  child: Text('Luk'),
)
```

**Efter:**
```dart
if (kIsWeb)
  OutlinedButton(
    onPressed: closeWindow,
    child: Text('Luk'),
  )
// Knappen vises kun på web, ikke iOS
```

**Eksempel 3: HTML Images**

**Før:**
```dart
if (imageUrl != null) {
  return _buildHtmlImage(imageUrl, 48, 48);
}
```

**Efter:**
```dart
if (imageUrl != null && kIsWeb) {
  return buildHtmlImage(imageUrl, 48, 48);
} else {
  // Fallback for iOS
  return Container(
    width: 48, height: 48,
    child: Icon(Icons.image),
  );
}
```

### 4. iOS Projekt Setup

#### A. Tilføj iOS Platform Support

```bash
# Hvis iOS folder ikke eksisterer:
flutter create --platforms=ios .
```

#### B. Opdater Bundle Identifier

**`ios/Runner.xcodeproj/project.pbxproj`**:
```
PRODUCT_BUNDLE_IDENTIFIER = com.yourcompany.yourapp;
```

#### C. Opdater Display Name

**`ios/Runner/Info.plist`**:
```xml
<key>CFBundleDisplayName</key>
<string>Your App Name</string>
<key>CFBundleName</key>
<string>your_app_name</string>
```

#### D. Tilføj Firebase iOS Config (hvis relevant)

1. Download `GoogleService-Info.plist` fra Firebase Console
2. Placer i `ios/Runner/` mappen
3. Opdater `lib/config/firebase_options.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return ios;
    }
    throw UnsupportedError('Unsupported platform');
  }

  static const FirebaseOptions web = FirebaseOptions(
    // ... existing web config
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-IOS-API-KEY',
    appId: 'YOUR-IOS-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'your-project-id',
    storageBucket: 'your-bucket.appspot.com',
    iosBundleId: 'com.yourcompany.yourapp',
  );
}
```

#### E. Tilføj URL Schemes (hvis deep links bruges)

**`ios/Runner/Info.plist`**:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourappscheme</string>
        </array>
    </dict>
</array>
```

### 5. Test

#### A. Clean Build

```bash
flutter clean
flutter pub get
```

#### B. Byg til iOS Simulator

```bash
# Kopier xcconfig fil (workaround for CocoaPods issue)
cp ios/Flutter/Generated.xcconfig ios/Flutter/ephemeral/Flutter-Generated.xcconfig

# Byg
flutter build ios --simulator --debug
```

#### C. Kør på Simulator

```bash
open -a Simulator
flutter run
```

#### D. Test Web (KRITISK!)

```bash
flutter run -d chrome
```

**Test checklist:**
- [ ] Login/OAuth flow virker
- [ ] Deep links virker
- [ ] Ingen console errors
- [ ] Alle features virker som før

---

## Troubleshooting

### Problem: "dart:html is not available on this platform"

**Løsning:** Du har glemt at lave conditional import et sted.

1. Find filen med fejlen
2. Erstat direkte `dart:html` import med conditional import
3. Wrap web-specific kode i `if (kIsWeb)` check

### Problem: "CocoaPods: Flutter-Generated.xcconfig must exist"

**Løsning:**
```bash
cp ios/Flutter/Generated.xcconfig ios/Flutter/ephemeral/Flutter-Generated.xcconfig
flutter build ios --simulator --debug
```

### Problem: Web app virker ikke efter ændringer

**Løsning:**
1. Tjek at conditional imports loader korrekt fil på web
2. Verificer at `kIsWeb` checks er korrekte
3. Test i Chrome DevTools console for fejl

---

## Best Practices

### ✅ DO:
- Test web app grundigt efter HVER ændring
- Brug conditional imports for platform-specific kode
- Lav graceful fallbacks for iOS (ikke crash)
- Commit ofte til git

### ❌ DON'T:
- Refactor working web kode unødvendigt
- Brug `Platform.isIOS` til UI logic (brug `kIsWeb` i stedet)
- Antag at web og iOS har samme capabilities
- Deploy til production uden at teste web

---

## Cheat Sheet

### Common Replacements

| Web (Før) | Cross-Platform (Efter) |
|-----------|------------------------|
| `import 'dart:html' as html;` | `import 'utils/web_utils.dart' if (dart.library.io) 'utils/web_utils_stub.dart';` |
| `html.window.location.href` | `getCurrentUrl()` |
| `html.window.history.replaceState()` | `cleanUrlParams()` |
| `html.window.close()` | `closeWindow()` |
| `if (kIsWeb) { web_code; }` | Platform guard bevares |
| `HtmlElementView(...)` | Wrap i `kIsWeb` check med fallback |

### Quick Commands

```bash
# Find web-only imports
grep -r "dart:html" lib/
grep -r "dart:ui_web" lib/

# Build iOS
flutter clean
cp ios/Flutter/Generated.xcconfig ios/Flutter/ephemeral/Flutter-Generated.xcconfig
flutter build ios --simulator --debug

# Test platforms
flutter run -d chrome          # Web
flutter run                     # iOS simulator
flutter run -d macos           # macOS (hvis relevant)

# Deploy web only
flutter build web --release
firebase deploy --only hosting
```

---

## Summary

iOS platform support handler primært om:
1. **Isolering**: Web-specific kode i separate filer
2. **Fallbacks**: Graceful degradation på iOS
3. **Testing**: Verificer at web ikke påvirkes

Med denne tilgang kan din app køre både som web app OG native iOS app uden konflikter.

---

**Sidst opdateret:** Dec 26, 2025  
**Baseret på:** DGU POC app (dgu-scorekort projekt)  
**Commit reference:** eb7ff66

