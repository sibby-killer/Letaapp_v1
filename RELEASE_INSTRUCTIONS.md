# 🚀 Leta App - Release Instructions

**How to build and get the APK on your phone**

---

## ✅ **Quick Start (5 Minutes)**

### **Step 1: Build the APK**

Open PowerShell in the project folder and run:

```bash
flutter build apk --release
```

Wait 5-10 minutes for the build to complete.

### **Step 2: Find Your APK**

The APK will be at:
```
build\app\outputs\flutter-apk\app-release.apk
```

### **Step 3: Send to Your Phone**

**Option A: USB Transfer**
1. Connect phone via USB
2. Copy `app-release.apk` to your phone's Downloads folder
3. Open Files app on phone
4. Tap the APK file
5. Install (allow "Install from Unknown Sources")

**Option B: Cloud Transfer**
1. Upload APK to Google Drive / Dropbox / OneDrive
2. Download on phone
3. Install

**Option C: GitHub Release** (see below)

---

## 🔧 **Build Commands Explained**

### **Debug Build** (for testing)
```bash
flutter build apk --debug
```
- Larger file size
- Includes debugging info
- Faster build time
- Location: `build/app/outputs/flutter-apk/app-debug.apk`

### **Release Build** (for production)
```bash
flutter build apk --release
```
- Smaller file size
- Optimized performance
- No debugging info
- Location: `build/app/outputs/flutter-apk/app-release.apk`

### **Split APKs** (smaller downloads)
```bash
flutter build apk --split-per-abi --release
```
Creates 3 APKs:
- `app-armeabi-v7a-release.apk` (older phones)
- `app-arm64-v8a-release.apk` (modern phones)
- `app-x86_64-release.apk` (emulators)

Use the `arm64-v8a` version for most phones.

---

## 📦 **GitHub Release Method**

### **Step 1: Push to GitHub**

```bash
git add .
git commit -m "Release v1.0.0 - Production ready"
git push origin main
```

### **Step 2: Build APK Locally**

```bash
flutter build apk --release
```

### **Step 3: Create GitHub Release**

1. Go to: https://github.com/sibby-killer/Letaapp_v1/releases
2. Click "Create a new release"
3. Tag: `v1.0.0`
4. Title: "Leta App v1.0.0 - First Release"
5. Description:
   ```
   ## Features
   - 4 role-based dashboards (Customer, Vendor, Rider, Admin)
   - Real-time chat (Supabase Realtime)
   - Live location tracking
   - Split payments (Paystack)
   - AI-powered search (Groq)
   - Offline support
   
   ## Installation
   1. Download the APK below
   2. Enable "Install from Unknown Sources" on your phone
   3. Install the APK
   ```
6. Upload: `build/app/outputs/flutter-apk/app-release.apk`
7. Click "Publish release"

### **Step 4: Download on Phone**

1. Go to the release page on your phone
2. Download the APK
3. Install

---

## 🎯 **Automated GitHub Actions** (Optional)

Create `.github/workflows/release.yml`:

```yaml
name: Build and Release APK

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Setup Java
        uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.38.6'
      
      - name: Install dependencies
        run: flutter pub get
      
      - name: Build APK
        run: flutter build apk --release
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: build/app/outputs/flutter-apk/app-release.apk
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Then just push a tag:
```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub will automatically build and release the APK!

---

## 🔐 **Signing the APK** (Optional but Recommended)

For Play Store or official releases, sign your APK:

### **1. Create a keystore**

```bash
keytool -genkey -v -keystore leta-app-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias leta-app
```

Save this file securely! You'll need it for updates.

### **2. Create `key.properties`**

Create `android/key.properties`:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=leta-app
storeFile=../leta-app-key.jks
```

**⚠️ Important:** Add `key.properties` to `.gitignore`!

### **3. Update `android/app/build.gradle`**

Add before `android {`:
```gradle
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file('key.properties')
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
```

Add inside `android {`:
```gradle
signingConfigs {
    release {
        keyAlias keystoreProperties['keyAlias']
        keyPassword keystoreProperties['keyPassword']
        storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
        storePassword keystoreProperties['storePassword']
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
    }
}
```

Now builds will be signed automatically!

---

## 📱 **Testing Before Release**

### **1. Test on Real Device**

```bash
flutter run --release
```

### **2. Test APK Installation**

```bash
flutter build apk --release
adb install build/app/outputs/flutter-apk/app-release.apk
```

### **3. Check APK Size**

```bash
flutter build apk --release --analyze-size
```

Target: < 50 MB

---

## 🐛 **Troubleshooting**

### **Build Fails**

```bash
flutter clean
flutter pub get
flutter build apk --release
```

### **APK Too Large**

```bash
flutter build apk --split-per-abi --release
```

### **Can't Install on Phone**

1. Enable "Unknown Sources" in Settings
2. Check if you have enough storage
3. Try uninstalling old version first

### **Gradle Download Issues**

If Gradle fails to download:
```bash
cd android
./gradlew clean --offline
cd ..
flutter build apk --release
```

---

## ✅ **Checklist Before Release**

- [ ] Update version in `pubspec.yaml`
- [ ] Test on real device
- [ ] Configure all API keys in `app_config.dart`
- [ ] Run Supabase database schema
- [ ] Test all features work
- [ ] Build release APK
- [ ] Test APK installation
- [ ] Create GitHub release
- [ ] Update README with new features

---

## 🎉 **You're Ready!**

Run this now:

```bash
flutter build apk --release
```

Your APK will be at:
```
build\app\outputs\flutter-apk\app-release.apk
```

Transfer it to your phone and install! 🚀

---

**Need help?** Check `BUILD_FIX_REPORT.md` and `SUPABASE_REALTIME_MIGRATION.md`
