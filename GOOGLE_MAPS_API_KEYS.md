# Google Maps API Key Management

This document explains how to manage Google Maps API keys for different build variants (debug vs release).

## Setup

### 1. Get SHA-1 Fingerprints

**For Debug Builds:**
```bash
cd android
./gradlew signingReport
```
Look for the SHA-1 under "Variant: debug" → "Config: debug"

**For Release Builds:**
If you have a release keystore:
```bash
keytool -list -v -keystore app/your-release-key.jks -alias your-key-alias
```
Or from signing report:
```bash
./gradlew signingReport
```
Look under "Variant: release" → "Config: release"

### 2. Create API Keys in Google Cloud Console

1. Go to [Google Cloud Console](https://console.cloud.google.com/google/maps-apis)
2. Select project: **ciclable**
3. Enable APIs:
   - Maps SDK for Android
   - Maps JavaScript API (for web version)
   - Maps SDK for iOS (if supporting iOS)

4. **Create Debug API Key:**
   - Credentials → Create → API Key
   - Edit key → Rename to "Ciclable Android Debug"
   - Application restrictions → Android apps
   - Add item:
     - Package name: `org.ciclable.app`
     - SHA-1: [paste debug SHA-1 from step 1]
   - API restrictions → Restrict key → Maps SDK for Android
   - Save

5. **Create Release API Key:**
   - Credentials → Create → API Key
   - Edit key → Rename to "Ciclable Android Release"
   - Application restrictions → Android apps
   - Add item:
     - Package name: `org.ciclable.app`
     - SHA-1: [paste release SHA-1 from step 1]
   - API restrictions → Restrict key → Maps SDK for Android
   - Set quotas to prevent unexpected billing
   - Save

### 3. Configure Local Properties

Copy the example file:
```bash
cp android/local.properties.example android/local.properties
```

Edit `android/local.properties` and add your keys:
```properties
google.maps.key.debug=AIzaSy_YOUR_DEBUG_KEY
google.maps.key.release=AIzaSy_YOUR_RELEASE_KEY
```

**Important:** `local.properties` is already in `.gitignore` - never commit it!

## How It Works

The build system:
1. Reads keys from `android/local.properties`
2. Injects the appropriate key into the manifest based on build type:
   - Debug builds → `google.maps.key.debug`
   - Release builds → `google.maps.key.release`
3. Falls back to the existing hardcoded key if properties are missing

## Build Commands

```bash
# Debug build (uses debug key)
flutter run

# Release build (uses release key)
flutter build apk --release
flutter build appbundle --release
```

## Security Best Practices

### ✅ Do:
- Use separate keys for debug and release
- Restrict keys by package name AND SHA-1 fingerprint
- Enable only required APIs
- Set daily quotas to prevent abuse
- Store keys in `local.properties` (gitignored)
- Rotate keys if compromised
- Monitor usage in Google Cloud Console

### ❌ Don't:
- Commit API keys to git
- Share keys between environments
- Use unrestricted keys
- Leave test keys in production
- Ignore usage alerts

## Team Collaboration

For team members to build the app:

1. Send them the API keys securely (not via git/email)
2. They create `android/local.properties` with the keys
3. They can build without modifying committed files

## CI/CD (GitHub Actions, etc.)

Store keys as secrets and inject them during build:

```yaml
- name: Create local.properties
  run: |
    echo "google.maps.key.debug=${{ secrets.GMAPS_DEBUG_KEY }}" >> android/local.properties
    echo "google.maps.key.release=${{ secrets.GMAPS_RELEASE_KEY }}" >> android/local.properties
```

## iOS Setup (Future)

For iOS, add to `ios/Runner/Info.plist`:
```xml
<key>GMSApiKey</key>
<string>${GOOGLE_MAPS_API_KEY}</string>
```

And configure build settings or use a script to inject the key.

## Troubleshooting

### Map not loading
1. Check `flutter run` output for API key being used
2. Verify SHA-1 fingerprint matches in Cloud Console
3. Verify package name is `org.ciclable.app`
4. Check API is enabled in Cloud Console
5. Wait 5-10 minutes after creating/updating keys

### "API key not found" error
1. Ensure `local.properties` file exists in `android/` directory
2. Check file has correct property names
3. Run `flutter clean` and rebuild

### Different key in debug vs release
This is expected and desired! Each build type should use its own restricted key.
