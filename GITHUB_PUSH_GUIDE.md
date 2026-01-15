# 📤 GitHub Push Guide - Leta App

**How to push everything to GitHub and create releases**

---

## 🚀 **Quick Push**

```bash
# Add all files
git add .

# Commit with message
git commit -m "Production ready - Supabase Realtime, all features complete"

# Push to GitHub
git push origin main
```

---

## 📋 **Step-by-Step Guide**

### **Step 1: Check Git Status**

```bash
git status
```

This shows what files have changed.

### **Step 2: Add Files**

**Add everything:**
```bash
git add .
```

**Or add specific files:**
```bash
git add lib/
git add android/
git add README.md
```

### **Step 3: Commit**

```bash
git commit -m "Your commit message here"
```

**Good commit messages:**
- ✅ "Production ready - all features complete"
- ✅ "Fixed build issues, added Supabase Realtime"
- ✅ "v1.0.0 - First production release"
- ❌ "updates" (too vague)
- ❌ "fix" (what was fixed?)

### **Step 4: Push**

```bash
git push origin main
```

If you get an error about upstream:
```bash
git push --set-upstream origin main
```

---

## 🏷️ **Creating a Release**

### **Method 1: GitHub Web Interface**

1. Go to: https://github.com/sibby-killer/Letaapp_v1
2. Click "Releases" (right sidebar)
3. Click "Create a new release"
4. Fill in:
   - **Tag:** `v1.0.0`
   - **Title:** `Leta App v1.0.0 - First Release`
   - **Description:** See template below
5. Upload your APK file: `build/app/outputs/flutter-apk/app-release.apk`
6. Click "Publish release"

**Description Template:**
```markdown
# 🚀 Leta App v1.0.0 - Production Release

## ✨ Features
- 🔐 Multi-role authentication (Customer, Vendor, Rider, Admin)
- 💬 Real-time chat using Supabase Realtime
- 📍 Live location tracking for deliveries
- 💳 Split payment system (Paystack integration)
- 🤖 AI-powered product search (Groq)
- 📦 Complete order management system
- 🗺️ Interactive maps with routing
- 💾 Offline support with SQLite caching

## 📱 Installation
1. Download the APK file below
2. Enable "Install from Unknown Sources" on your Android device
3. Open the APK file and install
4. Launch Leta App!

## 🔧 System Requirements
- Android 5.0 (Lollipop) or higher
- 100 MB free storage
- Internet connection for full features

## 📚 Documentation
- [Setup Guide](https://github.com/sibby-killer/Letaapp_v1/blob/main/SETUP_GUIDE.md)
- [Quick Build Guide](https://github.com/sibby-killer/Letaapp_v1/blob/main/QUICK_BUILD.md)
- [Architecture](https://github.com/sibby-killer/Letaapp_v1/blob/main/ARCHITECTURE.md)

## 🐛 Known Issues
None - production ready! 🎉

## 💡 What's Next
- Push notifications
- iOS version
- More payment methods
- Advanced analytics
```

### **Method 2: Git Tags (Command Line)**

```bash
# Create a tag
git tag -a v1.0.0 -m "First production release"

# Push tag to GitHub
git push origin v1.0.0
```

Then go to GitHub and create the release from the tag.

---

## 📊 **What to Include in the Repo**

### ✅ **Include:**
- All source code (`lib/`, `android/`, etc.)
- Configuration files (`pubspec.yaml`, etc.)
- Documentation (README.md, guides, etc.)
- Database schema (`supabase_schema.sql`)
- Build scripts

### ❌ **Don't Include:**
- `.env` files with API keys
- `key.properties` (signing keys)
- `.jks` or `.keystore` files
- `build/` folder
- `.gradle/` folder
- `node_modules/`
- Personal configuration

**Check `.gitignore` to make sure sensitive files are excluded!**

---

## 🔐 **Keeping Secrets Safe**

### **What are secrets?**
- API keys (Supabase, Paystack, Groq)
- Database passwords
- App signing keys
- OAuth tokens

### **How to protect them:**

1. **Use `.gitignore`:**
   ```
   .env
   *.env
   key.properties
   *.jks
   *.keystore
   ```

2. **Use GitHub Secrets** (for GitHub Actions):
   - Go to Settings → Secrets and variables → Actions
   - Add secrets like `SUPABASE_URL`, `PAYSTACK_KEY`
   - Reference in workflows: `${{ secrets.SUPABASE_URL }}`

3. **Create template files:**
   - Commit `.env.example` (with dummy values)
   - Users copy to `.env` and add real values

---

## 🔄 **Common Git Commands**

### **See what changed:**
```bash
git status
git diff
```

### **Undo changes:**
```bash
# Undo changes to a file
git checkout -- filename

# Undo last commit (keep changes)
git reset HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1
```

### **Update from GitHub:**
```bash
git pull origin main
```

### **Create a new branch:**
```bash
git checkout -b feature/new-feature
git push origin feature/new-feature
```

### **See commit history:**
```bash
git log --oneline
```

---

## 📦 **Complete Push Checklist**

Before pushing to GitHub:

- [ ] All API keys removed from code
- [ ] `.gitignore` properly configured
- [ ] Build succeeds locally
- [ ] README.md updated
- [ ] Documentation complete
- [ ] Commit message is clear
- [ ] No sensitive data in code

---

## 🎯 **Example: Complete Push Workflow**

```bash
# 1. Check what changed
git status

# 2. Add all changes
git add .

# 3. Commit with message
git commit -m "v1.0.0 - Production ready with Supabase Realtime"

# 4. Push to GitHub
git push origin main

# 5. Create tag for release
git tag -a v1.0.0 -m "First production release"
git push origin v1.0.0

# 6. Go to GitHub and create release
# Upload APK, add description, publish!
```

---

## ✅ **You're Ready!**

Run these commands now:

```bash
git add .
git commit -m "Production ready - Supabase Realtime, all features complete"
git push origin main
```

Then create a release on GitHub and upload your APK! 🚀

---

**Need the APK?** Run:
```bash
flutter build apk --release
```

Then upload `build\app\outputs\flutter-apk\app-release.apk` to GitHub Release!
