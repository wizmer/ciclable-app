# Quick Deployment Reference

## Before First Release

1. **Generate signing key:**
   ```fish
   keytool -genkey -v -keystore ~/ciclable-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias ciclable-key
   ```

2. **Create key.properties:**
   ```fish
   cp android/key.properties.example android/key.properties
   # Edit with your actual passwords and keystore path
   ```

3. **Update version in pubspec.yaml:**
   ```yaml
   version: 1.0.0+1
   ```

## Build Commands

### For Google Play Store
```fish
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

### For F-Droid / Direct Distribution
```fish
flutter build apk --release --split-per-abi
```
Output: `build/app/outputs/flutter-apk/app-*-release.apk`

## Release Checklist

- [ ] Update version in `pubspec.yaml`
- [ ] Update `CHANGELOG.md`
- [ ] Create git tag: `git tag -a v1.0.0 -m "Release 1.0.0"`
- [ ] Push tag: `git push origin v1.0.0`
- [ ] Build release artifacts
- [ ] Test on clean device
- [ ] Upload to Play Store / GitHub
- [ ] Update F-Droid metadata if needed

## GitHub Actions (Automated)

Once set up, just push a tag:
```fish
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically:
- Build APKs and App Bundle
- Create GitHub release
- Attach artifacts

## Required Secrets (GitHub)

Set in repository Settings → Secrets:
- `KEYSTORE_BASE64` - Base64 of keystore file
- `KEYSTORE_PASSWORD` - Keystore password
- `KEY_PASSWORD` - Key password

Generate base64:
```fish
base64 -w 0 ~/ciclable-release-key.jks
```

## Version Management

Format: `MAJOR.MINOR.PATCH+BUILD`
- `1.0.0+1` → initial release
- `1.0.1+2` → bug fix
- `1.1.0+3` → new features
- `2.0.0+4` → breaking changes

**Important:** BUILD number must always increment!

## Quick Links

- [Full Deployment Guide](DEPLOYMENT.md)
- [Google Play Console](https://play.google.com/console)
- [F-Droid Wiki](https://f-droid.org/docs/)
- [Changelog](CHANGELOG.md)
