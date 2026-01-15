# ⚡ Quick Build Guide - Leta App

**Get your APK in 5 minutes!**

---

## 🚀 **Step 1: Clean Build (30 seconds)**

```bash
flutter clean
flutter pub get
```

---

## 🚀 **Step 2: Build APK (5 minutes)**

```bash
flutter build apk --release
```

**That's it!** ✅

---

## 📱 **Step 3: Get APK**

Your APK is ready at:
```
build\app\outputs\flutter-apk\app-release.apk
```

**Size:** ~30-50 MB

---

## 📲 **Step 4: Install on Phone**

### **Method 1: USB Transfer**
1. Connect phone via USB
2. Copy APK to Downloads folder
3. Open Files app → Downloads
4. Tap `app-release.apk`
5. Allow "Install from Unknown Sources"
6. Install!

### **Method 2: Cloud**
1. Upload APK to Google Drive/Dropbox
2. Download on phone
3. Install

### **Method 3: ADB**
```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## ✅ **That's All!**

You now have Leta App on your phone! 🎉

---

## 🐛 **If Build Fails**

### **Gradle Issues:**
```bash
cd android
.\gradlew clean --offline
cd ..
flutter clean
flutter build apk --release
```

### **Dependency Issues:**
```bash
flutter pub cache repair
flutter clean
flutter pub get
flutter build apk --release
```

### **Still Failing?**

See `RELEASE_INSTRUCTIONS.md` for detailed troubleshooting.

---

## 📊 **Build Statistics**

- **Build Time:** ~5 minutes (first build)
- **APK Size:** ~30-50 MB
- **Minimum Android:** 5.0 (API 21)
- **Target Android:** 14 (API 34)

---

**Happy building! 🚀**
