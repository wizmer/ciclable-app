# Ciclable App Deployment Guide

This guide covers deploying the Ciclable app to:
- **Google Play Store** (official distribution)
- **F-Droid** (open-source distribution)

## Prerequisites

- Flutter SDK installed and configured
- Android SDK with build tools
- Java Development Kit (JDK) 17+
- Git for version control

---

## 1. Prepare the App for Release

### Update Application ID

Edit `android/app/build.gradle.kts` and change the application ID from the example:

```kotlin
defaultConfig {
    applicationId = "org.ciclable.app"  
    minSdk = 21  // Minimum Android version
    targetSdk = 34
    versionCode = 1
    versionName = "1.0.0"
}
```

### Set App Version

Version is managed in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

Format: `MAJOR.MINOR.PATCH+BUILD_NUMBER`
- `1.0.0` = version name (shown to users)
- `1` = version code (internal build number, must increment with each release)

---

## 2. Generate a Signing Key

### Create Keystore

```fish
keytool -genkey -v -keystore ~/ciclable-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ciclable-key
```

**Important:** 
- Store the keystore file securely (NOT in the repository)
- Remember the keystore password and key password
- Back up this file - losing it means you cannot update the app

### Configure Signing

Create `android/key.properties` (add to .gitignore):

```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=ciclable-key
storeFile=/home/yourusername/ciclable-release-key.jks
```

Update `android/app/build.gradle.kts`:

```kotlin
// Load signing configuration
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            minifyEnabled = true
            shrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

## 3. Build Release APK/App Bundle

### For Google Play Store (App Bundle - Recommended)

```fish
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### For F-Droid and Direct Distribution (APK)

```fish
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Build for Multiple ABIs (Smaller Downloads)

```fish
flutter build apk --split-per-abi --release
```

Generates separate APKs:
- `app-arm64-v8a-release.apk` (64-bit ARM - most modern devices)
- `app-armeabi-v7a-release.apk` (32-bit ARM - older devices)
- `app-x86_64-release.apk` (64-bit x86 - emulators/rare devices)

---

## 4. Deploy to Google Play Store

### Initial Setup

1. **Create Developer Account**
   - Go to [Google Play Console](https://play.google.com/console)
   - Pay $25 one-time registration fee
   - Complete account verification

2. **Create App**
   - Click "Create app"
   - Fill in app details:
     - App name: **Ciclable**
     - Default language: **English (or your primary language)**
     - App/Game: **App**
     - Free/Paid: **Free**
   - Accept policies and declarations

3. **Complete Store Listing**
   - App name and short description
   - Full description (4000 chars max)
   - Screenshots (at least 2):
     - Phone: 320-3840px wide, aspect ratio 16:9 to 2:1
     - Tablet (optional but recommended)
   - Feature graphic: 1024x500px
   - App icon: 512x512px (high-res)
   - Category: **Navigation** or **Maps & Navigation**
   - Content rating questionnaire
   - Privacy policy URL (required if app collects data)

4. **Set Up Release**
   - Go to "Production" → "Create new release"
   - Upload `app-release.aab`
   - Fill release notes
   - Review and rollout

### Privacy Policy

Since Ciclable collects location data and syncs with a backend, you need a privacy policy. Host it on your website or use [privacy-policy-template.com](https://www.privacypolicygenerator.info/).

Required disclosures:
- Location data collection (GPS coordinates for counting locations)
- Data storage (local SQLite + backend sync)
- Third-party services (Google Maps API)
- Data retention policy
- User rights (GDPR compliance if EU users)

### Update Releases

For subsequent releases:

1. Increment version in `pubspec.yaml`:
   ```yaml
   version: 1.0.1+2  # New version name + incremented build number
   ```

2. Rebuild app bundle:
   ```fish
   flutter build appbundle --release
   ```

3. Upload to Play Console → Production → Create new release

---

## 5. Deploy to F-Droid

F-Droid builds apps from source, so you need to prepare metadata and ensure reproducible builds.

### Create F-Droid Metadata

Create `metadata/org.ciclable.app.yml` in your repository:

```yaml
Categories:
  - Navigation
  - Internet

License: GPL-3.0-or-later  # or your chosen open-source license

AuthorName: Your Name/Organization
AuthorEmail: contact@ciclable.org
AuthorWebSite: https://ciclable.org

WebSite: https://ciclable.org
SourceCode: https://github.com/yourusername/ciclable_app
IssueTracker: https://github.com/yourusername/ciclable_app/issues

Summary: Cyclist traffic counting app
Description: |-
  Ciclable is a mobile application for counting cyclists and other road users
  at specific locations. It supports both online and offline modes with
  automatic data synchronization.
  
  Features:
  * Interactive map with counting locations
  * Offline-first architecture
  * Directed and non-directed counting modes
  * Google Maps integration
  * Real-time synchronization when online

RepoType: git
Repo: https://github.com/yourusername/ciclable_app

Builds:
  - versionName: '1.0.0'
    versionCode: 1
    commit: v1.0.0
    output: build/app/outputs/flutter-apk/app-release.apk
    srclibs:
      - flutter@stable
    build:
      - $$flutter$$/bin/flutter build apk --release

AutoUpdateMode: Version v%v
UpdateCheckMode: Tags
CurrentVersion: '1.0.0'
CurrentVersionCode: 1
```

### Submit to F-Droid

1. **Fork F-Droid Data Repository**
   ```fish
   git clone https://gitlab.com/fdroid/fdroiddata.git
   cd fdroiddata
   ```

2. **Add Your Metadata**
   ```fish
   cp /path/to/your/metadata/org.ciclable.app.yml metadata/
   ```

3. **Test Build Locally**
   ```fish
   fdroid build org.ciclable.app
   ```

4. **Submit Merge Request**
   - Push to your fork
   - Create merge request to F-Droid's repository
   - F-Droid reviewers will verify and merge

### F-Droid Alternative: Self-Hosted Repository

If you want faster updates without F-Droid review process:

1. **Create Your Own F-Droid Repository**
   ```fish
   fdroid init
   fdroid update --create-metadata
   ```

2. **Host Repository**
   - Upload generated files to your web server
   - Users add your repository URL in F-Droid app settings

---

## 6. Alternative: GitHub Releases

For open-source distribution without F-Droid infrastructure:

### Create Release

```fish
# Tag the release
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0

# Build APK
flutter build apk --release --split-per-abi

# Create GitHub release and attach APKs
gh release create v1.0.0 \
  build/app/outputs/flutter-apk/app-arm64-v8a-release.apk \
  build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk \
  build/app/outputs/flutter-apk/app-x86_64-release.apk \
  --title "Ciclable v1.0.0" \
  --notes "Initial release"
```

Users can install APKs directly from GitHub releases.

---

## 7. Continuous Deployment (Optional)

### GitHub Actions Workflow

Create `.github/workflows/release.yml`:

```yaml
name: Release Build

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Java
        uses: actions/setup-java@v3
        with:
          distribution: 'temurin'
          java-version: '17'
      
      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.24.x'
          channel: 'stable'
      
      - name: Get dependencies
        run: flutter pub get
      
      - name: Decode keystore
        run: echo "${{ secrets.KEYSTORE_BASE64 }}" | base64 -d > android/app/keystore.jks
      
      - name: Create key.properties
        run: |
          echo "storePassword=${{ secrets.KEYSTORE_PASSWORD }}" > android/key.properties
          echo "keyPassword=${{ secrets.KEY_PASSWORD }}" >> android/key.properties
          echo "keyAlias=ciclable-key" >> android/key.properties
          echo "storeFile=keystore.jks" >> android/key.properties
      
      - name: Build APK
        run: flutter build apk --release --split-per-abi
      
      - name: Build App Bundle
        run: flutter build appbundle --release
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            build/app/outputs/flutter-apk/*.apk
            build/app/outputs/bundle/release/app-release.aab
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Set GitHub Secrets:**
- `KEYSTORE_BASE64`: Base64-encoded keystore file
- `KEYSTORE_PASSWORD`: Keystore password
- `KEY_PASSWORD`: Key password

---

## 8. Post-Release Checklist

- [ ] Tag release in Git
- [ ] Update changelog/release notes
- [ ] Test installation on clean device
- [ ] Monitor crash reports
- [ ] Respond to user feedback
- [ ] Plan next version features

---

## Troubleshooting

### Build Fails with "Signing Config Not Found"

Ensure `android/key.properties` exists and paths are correct.

### APK Size Too Large

Enable code shrinking and resource optimization:
```kotlin
buildTypes {
    release {
        minifyEnabled = true
        shrinkResources = true
    }
}
```

### F-Droid Build Fails

- Ensure no proprietary dependencies (Firebase, Google Play Services billing, etc.)
- Use only open-source libraries
- Check Flutter version compatibility

### Google Play Rejects Upload

- Verify target SDK is at least 33 (Android 13)
- Complete all required store listing fields
- Add privacy policy if collecting data
- Set correct app permissions in AndroidManifest.xml

---

## Resources

- [Flutter Deployment Docs](https://docs.flutter.dev/deployment/android)
- [Google Play Console](https://play.google.com/console)
- [F-Droid Docs](https://f-droid.org/docs/)
- [App Signing Best Practices](https://developer.android.com/studio/publish/app-signing)
