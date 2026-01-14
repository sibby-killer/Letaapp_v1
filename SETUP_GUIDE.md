# 🚀 Leta App - Complete Setup Guide

This guide will walk you through **everything** needed to run the Leta App on your Android phone.

---

## 📋 Prerequisites

Before starting, ensure you have:

- [ ] **Flutter SDK** (3.16+) - [Install Flutter](https://docs.flutter.dev/get-started/install)
- [ ] **Android Studio** (for Android SDK) - [Download](https://developer.android.com/studio)
- [ ] **Node.js** (18+) - [Download](https://nodejs.org/)
- [ ] **Git** - [Download](https://git-scm.com/)
- [ ] **VS Code** (recommended) - [Download](https://code.visualstudio.com/)

---

## 🔧 Step 1: Install Flutter

### Windows

```powershell
# Option 1: Using Chocolatey
choco install flutter

# Option 2: Manual installation
# 1. Download Flutter SDK from https://docs.flutter.dev/get-started/install/windows
# 2. Extract to C:\flutter
# 3. Add C:\flutter\bin to your PATH environment variable
```

### Verify Installation

```bash
flutter doctor
```

You should see:
```
[✓] Flutter (Channel stable, 3.x.x)
[✓] Android toolchain
[✓] Android Studio
[✓] VS Code
```

---

## 🔧 Step 2: Setup Supabase (Database)

### 2.1 Create Supabase Project

1. Go to [supabase.com](https://supabase.com) and sign up (free)
2. Click **"New Project"**
3. Fill in:
   - **Name**: `leta-app`
   - **Database Password**: (save this!)
   - **Region**: Choose closest to you
4. Wait 2-3 minutes for project to create

### 2.2 Get API Keys

1. Go to **Settings** → **API**
2. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: `eyJhbGc...`

### 2.3 Run Database Schema

1. In Supabase Dashboard, go to **SQL Editor**
2. Click **"New Query"**
3. Copy the entire contents of `supabase_schema.sql` file
4. Paste into the editor
5. Click **"Run"** (or press Ctrl+Enter)
6. Verify in **Table Editor** - you should see 8 tables:
   - users
   - categories
   - stores
   - products
   - orders
   - chat_rooms
   - chat_messages
   - rider_earnings

### 2.4 Enable PostGIS Extension

If not already enabled:
1. Go to **Database** → **Extensions**
2. Search for **"postgis"**
3. Click to enable it

---

## 🔧 Step 3: Setup Socket.io Server (Real-time Chat)

You have **3 options** for the chat server:

### Option A: Run Locally (For Testing)

```bash
# Navigate to socket-server folder
cd socket-server

# Install dependencies
npm install

# Start the server
npm start
```

Server runs at: `http://localhost:3000`

**For Android Emulator**, use: `http://10.0.2.2:3000`
**For Physical Device**, use your computer's IP: `http://192.168.x.x:3000`

To find your IP:
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

### Option B: Deploy to Render.com (FREE - Recommended)

1. Create account at [render.com](https://render.com)
2. Go to **Dashboard** → **New** → **Web Service**
3. Choose **"Build and deploy from Git"**
4. Connect your GitHub repo (or use public URL)
5. Configure:
   - **Name**: `leta-chat-server`
   - **Root Directory**: `socket-server`
   - **Runtime**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Instance Type**: `Free`
6. Click **"Create Web Service"**
7. Wait for deployment (2-5 minutes)
8. Copy the URL: `https://leta-chat-server.onrender.com`

### Option C: Deploy to Railway.app (FREE)

1. Go to [railway.app](https://railway.app)
2. Click **"Start a New Project"**
3. Choose **"Deploy from GitHub repo"**
4. Select your repository
5. Configure:
   - **Root Directory**: `socket-server`
6. Railway auto-deploys
7. Go to **Settings** → **Domains** → **Generate Domain**
8. Copy the URL

---

## 🔧 Step 4: Setup Paystack (Payments)

### 4.1 Create Paystack Account

1. Go to [paystack.com](https://paystack.com)
2. Click **"Create Free Account"**
3. Verify your email
4. Complete business verification (or use test mode)

### 4.2 Get API Keys

1. Login to Paystack Dashboard
2. Go to **Settings** → **API Keys & Webhooks**
3. Copy:
   - **Test Public Key**: `pk_test_xxxxx`
   - **Test Secret Key**: `sk_test_xxxxx`

⚠️ **Important**: Use **TEST keys** during development!

### 4.3 Paystack Split Payment Setup

For automatic vendor/rider payouts, you need to create **Subaccounts**:

#### Via Dashboard (Manual)
1. Go to **Subaccounts** in Paystack dashboard
2. Click **"Add Subaccount"**
3. Fill vendor's bank details
4. Copy the `subaccount_code`

#### Via API (Automatic - How Leta App Does It)
The app automatically creates subaccounts during vendor onboarding using the API.

**Required Bank Codes** (Nigeria):
| Bank | Code |
|------|------|
| Access Bank | 044 |
| GTBank | 058 |
| First Bank | 011 |
| UBA | 033 |
| Zenith Bank | 057 |

Full list: [Paystack Bank Codes](https://paystack.com/docs/transfers/bank-codes/)

### 4.4 Test Card Numbers

For testing payments:
```
Card Number: 4084084084084081
Expiry: Any future date
CVV: 408
PIN: 0000
OTP: 123456
```

---

## 🔧 Step 5: Setup Groq AI (Optional)

### 5.1 Get API Key

1. Go to [console.groq.com](https://console.groq.com)
2. Sign up (free)
3. Go to **API Keys** → **Create API Key**
4. Copy the key: `gsk_xxxxx`

The app uses Groq for smart search (e.g., "I need gas and chapo" → filters vendors). If you skip this, the app falls back to simple keyword matching.

---

## 🔧 Step 6: Configure the Flutter App

### 6.1 Update app_config.dart

Edit `lib/core/config/app_config.dart`:

```dart
class AppConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
  static const String supabaseAnonKey = 'YOUR_ANON_KEY';
  
  // Socket.io Configuration
  // Local: 'http://10.0.2.2:3000' (emulator) or 'http://YOUR_IP:3000' (physical)
  // Cloud: 'https://your-server.onrender.com'
  static const String socketUrl = 'YOUR_SOCKET_URL';
  
  // Paystack Configuration
  static const String paystackPublicKey = 'pk_test_YOUR_KEY';
  static const String paystackSecretKey = 'sk_test_YOUR_KEY';
  
  // Groq AI Configuration (optional)
  static const String groqApiKey = 'gsk_YOUR_KEY';
  
  // ... rest of config
}
```

### 6.2 Install Dependencies

```bash
cd Letaapp
flutter pub get
```

---

## 📱 Step 7: Run on Android Phone

### Option A: USB Debugging (Recommended)

#### 7.1 Enable Developer Mode on Phone

1. Go to **Settings** → **About Phone**
2. Tap **"Build Number"** 7 times
3. Go back to **Settings** → **Developer Options**
4. Enable **"USB Debugging"**

#### 7.2 Connect Phone

1. Connect phone via USB cable
2. When prompted, tap **"Allow USB Debugging"**
3. Check **"Always allow from this computer"**

#### 7.3 Verify Connection

```bash
flutter devices
```

You should see your phone listed.

#### 7.4 Run the App

```bash
flutter run
```

Select your device when prompted.

### Option B: Build APK and Install

```bash
# Build debug APK (faster, for testing)
flutter build apk --debug

# Or build release APK (optimized)
flutter build apk --release
```

APK location: `build/app/outputs/flutter-apk/app-debug.apk`

Transfer to phone and install:
1. Copy APK to phone (via USB, email, or cloud)
2. On phone, open file manager and tap the APK
3. Allow installation from unknown sources if prompted
4. Install and open the app

### Option C: Wireless Debugging (Android 11+)

```bash
# On phone: Developer Options → Wireless Debugging → Enable
# Note the IP:Port shown

# On computer:
adb pair IP:PORT
# Enter pairing code shown on phone

adb connect IP:PORT

flutter run
```

---

## 🧪 Step 8: Test the App

### 8.1 Create Test Accounts

Create accounts for each role:

| Role | Email | Password |
|------|-------|----------|
| Customer | customer@test.com | test123456 |
| Vendor | vendor@test.com | test123456 |
| Rider | rider@test.com | test123456 |
| Admin | admin@test.com | test123456 |

### 8.2 Test Flow

1. **Sign up as Customer** → See home screen with categories
2. **Sign up as Vendor** → Complete store setup → See Kanban dashboard
3. **Sign up as Rider** → See map view with Go Online toggle
4. **Sign up as Admin** → See platform overview

### 8.3 Verify Services

| Service | How to Test | Expected Result |
|---------|-------------|-----------------|
| Supabase Auth | Sign up/Login | Success, redirects to dashboard |
| Database | View categories on home | Categories load from database |
| Socket.io | Open app on 2 devices | Real-time updates work |
| Location | Tap location button | Current location detected |

---

## 🔍 Troubleshooting

### Error: "Supabase connection failed"
- ✅ Check internet connection
- ✅ Verify Supabase URL and anon key are correct
- ✅ Ensure project is not paused (free tier pauses after 7 days inactivity)

### Error: "Socket connection failed"
- ✅ Verify socket server is running
- ✅ For emulator, use `10.0.2.2` not `localhost`
- ✅ For physical device, ensure phone and computer are on same WiFi
- ✅ Check firewall isn't blocking port 3000

### Error: "Location permission denied"
- ✅ Go to phone Settings → Apps → Leta → Permissions → Location → Allow

### Error: "Gradle build failed"
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Error: "minSdkVersion" issues
The app requires Android 5.0 (API 21) or higher.

---

## 📁 Project Structure Summary

```
Letaapp/
├── lib/
│   ├── main.dart                    # App entry
│   ├── core/
│   │   ├── config/app_config.dart   # ⚙️ UPDATE THIS FILE
│   │   ├── theme/                   # UI theme
│   │   ├── routes/                  # Navigation
│   │   ├── models/                  # Data models
│   │   ├── database/                # SQLite cache
│   │   └── services/                # DI setup
│   └── features/
│       ├── auth/                    # Login/Signup
│       ├── customer/                # Customer dashboard
│       ├── vendor/                  # Vendor dashboard
│       ├── rider/                   # Rider dashboard
│       ├── admin/                   # Admin dashboard
│       ├── chat/                    # Socket.io service
│       ├── map/                     # OSM service
│       ├── payment/                 # Paystack service
│       └── ai/                      # Groq service
├── android/                         # Android config
├── socket-server/                   # Chat server
├── supabase_schema.sql             # Database schema
└── SETUP_GUIDE.md                  # This file
```

---

## ✅ Setup Checklist

Before running the app, confirm:

- [ ] Flutter installed and `flutter doctor` shows green
- [ ] Supabase project created
- [ ] Database schema executed
- [ ] Socket.io server running (local or cloud)
- [ ] API keys updated in `app_config.dart`
- [ ] Phone connected via USB with debugging enabled
- [ ] `flutter pub get` completed successfully

---

## 🎯 Next Steps After Setup

1. **Test all 4 roles** (Customer, Vendor, Rider, Admin)
2. **Add test products** via Supabase dashboard or Vendor app
3. **Test the order flow** (add to cart → checkout)
4. **Test chat** between Customer and Vendor
5. **Customize branding** (colors, logo in theme)

---

## 📚 Additional Resources

- [Flutter Documentation](https://docs.flutter.dev)
- [Supabase Documentation](https://supabase.com/docs)
- [Paystack API Reference](https://paystack.com/docs/api)
- [Socket.io Documentation](https://socket.io/docs/v4)
- [OpenStreetMap](https://www.openstreetmap.org)

---

## 💬 Common Questions

**Q: Do I need all services to test the app?**
A: No! The app works with just Supabase. Chat (Socket.io), AI (Groq), and Payments (Paystack) are optional for initial testing.

**Q: Can I use the app without a server?**
A: The app needs Supabase for data. Socket.io is only needed for real-time chat.

**Q: How do I add products for testing?**
A: Either:
1. Use Supabase Dashboard → Table Editor → products → Insert Row
2. Sign in as Vendor and use the Products tab (UI needs completion)

**Q: Is it safe to use test API keys?**
A: Yes! Test keys (starting with `pk_test_`, `sk_test_`) only work in test mode and don't process real payments.

---

**Happy Building! 🚀**
