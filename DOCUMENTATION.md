# 📚 Leta App - Complete Documentation

> **Production-Ready Multi-Vendor Delivery Platform**  
> Version 1.0.0 | Last Updated: January 2026

---

## Table of Contents

1. [Overview](#overview)
2. [Features](#features)
3. [Technology Stack](#technology-stack)
4. [Project Structure](#project-structure)
5. [Setup Guide](#setup-guide)
6. [API Configuration](#api-configuration)
7. [Database Schema](#database-schema)
8. [Architecture](#architecture)
9. [Services](#services)
10. [Building & Deployment](#building--deployment)
11. [Troubleshooting](#troubleshooting)

---

## Overview

**Leta App** is a hyper-local multi-vendor delivery ecosystem that connects customers, vendors, riders, and administrators in a seamless platform. It supports multiple product categories including food delivery, gas refills, and second-hand goods.

### Key Highlights

- 🔐 **4 User Roles**: Customer, Vendor, Rider, Admin
- 💬 **Real-time Chat**: Using Supabase Realtime (no Socket.io needed)
- 💳 **Split Payments**: Automatic distribution via Paystack
- 🤖 **AI Search**: Powered by Groq AI
- 🗺️ **Live Tracking**: Real-time rider location updates
- 📱 **Offline Support**: SQLite local caching

---

## Features

### Customer Features
- Browse nearby stores and products
- AI-powered natural language search
- Shopping cart with product variants
- Real-time order tracking
- Chat with vendors and riders
- Multiple payment options

### Vendor Features
- Kanban-style order management
- Product catalog management
- Real-time order notifications
- Chat with customers
- Earnings and analytics dashboard
- Bank account integration (Paystack subaccounts)

### Rider Features
- Live map with deliveries
- Go online/offline toggle
- Turn-by-turn navigation
- Earnings tracking
- Chat with customers and vendors

### Admin Features
- System-wide analytics
- User management
- Order oversight
- Chat monitoring
- Revenue reports

---

## Technology Stack

### Frontend
| Technology | Version | Purpose |
|------------|---------|---------|
| Flutter | 3.38.6+ | Cross-platform UI |
| Dart | 3.10.7+ | Programming language |
| Provider | Latest | State management |
| Material 3 | Latest | Design system |

### Backend Services
| Service | Purpose |
|---------|---------|
| **Supabase** | Auth, Database, Storage, Realtime |
| **Paystack** | Payment processing & split payments |
| **Groq AI** | Natural language search |
| **OpenStreetMap** | Maps display |
| **OSRM** | Routing & navigation |

### Database
| Technology | Purpose |
|------------|---------|
| PostgreSQL | Primary database (via Supabase) |
| PostGIS | Geographic queries |
| SQLite | Offline caching |

---

## Project Structure

```
leta_app/
├── android/                    # Android native code
├── assets/
│   ├── .env                   # Environment variables (API keys)
│   ├── images/                # Image assets
│   ├── icons/                 # Icon assets
│   └── animations/            # Lottie animations
├── lib/
│   ├── main.dart              # App entry point
│   ├── core/
│   │   ├── config/
│   │   │   └── app_config.dart    # API configuration
│   │   ├── theme/
│   │   │   └── app_theme.dart     # Material 3 theme
│   │   ├── routes/
│   │   │   └── app_router.dart    # Navigation routing
│   │   ├── database/
│   │   │   └── local_database.dart # SQLite offline cache
│   │   ├── services/
│   │   │   ├── service_locator.dart      # Dependency injection
│   │   │   └── supabase_realtime_service.dart # Real-time features
│   │   └── models/
│   │       ├── user_model.dart
│   │       ├── store_model.dart
│   │       ├── product_model.dart
│   │       ├── category_model.dart
│   │       ├── order_model.dart
│   │       └── chat_message_model.dart
│   └── features/
│       ├── auth/
│       │   ├── screens/           # Login, Signup screens
│       │   ├── services/          # Auth service
│       │   └── providers/         # Auth state
│       ├── customer/
│       │   └── screens/           # Customer home, browse
│       ├── vendor/
│       │   └── screens/           # Vendor dashboard
│       ├── rider/
│       │   └── screens/           # Rider dashboard
│       ├── admin/
│       │   └── screens/           # Admin dashboard
│       ├── cart/
│       │   └── providers/         # Cart state management
│       ├── order/
│       │   └── providers/         # Order management
│       ├── payment/
│       │   └── services/          # Paystack integration
│       ├── ai/
│       │   └── services/          # Groq AI service
│       ├── map/
│       │   └── services/          # Maps & routing
│       ├── chat/
│       │   └── services/          # Real-time chat (via Supabase)
│       ├── onboarding/
│       │   └── screens/           # Vendor onboarding
│       └── splash/
│           └── screens/           # Splash screen
├── .github/
│   └── workflows/
│       └── build-apk.yml          # GitHub Actions CI/CD
├── pubspec.yaml                   # Flutter dependencies
├── supabase_schema.sql            # Database schema
└── DOCUMENTATION.md               # This file
```

---

## Setup Guide

### Prerequisites

1. **Flutter SDK** 3.38.6 or higher
2. **Android Studio** or VS Code
3. **Supabase Account** (free tier available)
4. **Paystack Account** (for payments)
5. **Groq Account** (for AI search)

### Quick Start

#### 1. Clone the Repository

```bash
git clone https://github.com/sibby-killer/Letaapp_v1.git
cd Letaapp_v1
```

#### 2. Install Dependencies

```bash
flutter pub get
```

#### 3. Configure API Keys

Add your API keys to GitHub Secrets (for CI/CD builds):

1. Go to: `https://github.com/sibby-killer/Letaapp_v1/settings/secrets/actions`
2. Add these secrets:

| Secret Name | Value | Where to Get |
|-------------|-------|--------------|
| `SUPABASE_URL` | `https://xxx.supabase.co` | Supabase → Settings → API |
| `SUPABASE_ANON_KEY` | `eyJhbGci...` | Supabase → Settings → API |
| `PAYSTACK_PUBLIC_KEY` | `pk_test_xxx` | Paystack → Settings → API Keys |
| `PAYSTACK_SECRET_KEY` | `sk_test_xxx` | Paystack → Settings → API Keys |
| `GROQ_API_KEY` | `gsk_xxx` | Groq Console → API Keys |

#### 4. Setup Supabase Database

1. Go to Supabase Dashboard
2. Open SQL Editor
3. Run the contents of `supabase_schema.sql`
4. Enable Realtime for `messages` and `chat_rooms` tables:
   - Go to Database → Replication
   - Enable tables in `supabase_realtime` publication

#### 5. Build & Run

```bash
# Using GitHub Actions (Recommended)
git push origin main
# Then download APK from Actions tab

# Or locally
flutter build apk --release
```

---

## API Configuration

### Required API Keys

All API keys are **REQUIRED** for the app to function properly:

| Service | Keys Required | Purpose |
|---------|---------------|---------|
| **Supabase** | URL + Anon Key | Auth, Database, Realtime |
| **Paystack** | Public + Secret Key | Payments, Split transactions |
| **Groq** | API Key | AI-powered search |

### Getting API Keys

#### Supabase
1. Go to [supabase.com](https://supabase.com)
2. Create new project
3. Go to Settings → API
4. Copy **Project URL** and **anon public** key

#### Paystack
1. Go to [paystack.com](https://paystack.com)
2. Create account / Login
3. Go to Settings → API Keys
4. Copy **Test Public Key** and **Test Secret Key**
5. For production, use **Live Keys**

**Test Card for Paystack:**
- Number: `4084 0840 8408 4081`
- Expiry: Any future date
- CVV: `408`

#### Groq AI
1. Go to [console.groq.com](https://console.groq.com)
2. Create account / Login
3. Go to API Keys
4. Create new key and copy it

---

## Database Schema

### Tables

| Table | Purpose |
|-------|---------|
| `users` | User accounts (all roles) |
| `stores` | Vendor stores |
| `categories` | Product categories |
| `products` | Store products |
| `orders` | Customer orders |
| `order_items` | Items in each order |
| `chat_rooms` | Chat conversations |
| `messages` | Chat messages |

### Key Relationships

```
users (1) ──── (N) stores
users (1) ──── (N) orders (as customer)
stores (1) ──── (N) products
stores (1) ──── (N) orders (as vendor)
orders (1) ──── (N) order_items
chat_rooms (1) ──── (N) messages
```

### Row Level Security (RLS)

All tables have RLS enabled:
- Users can only read/write their own data
- Vendors can only manage their own stores
- Customers can only see their own orders
- Chat participants can only see their messages

---

## Architecture

### State Management

Uses **Provider** pattern:

```dart
// Providers
├── AuthProvider      // Authentication state
├── CartProvider      // Shopping cart
└── OrderProvider     // Order management
```

### Service Layer

```dart
// Services (via GetIt)
├── AuthService              // Supabase Auth
├── PaymentService           // Paystack API
├── MapService               // OpenStreetMap + OSRM
├── AIService                // Groq AI
└── SupabaseRealtimeService  // Real-time features
```

### Real-time Architecture

**Chat Messages** (Postgres Changes):
```dart
// Messages are stored in database
// UI listens via .stream()
supabase.from('messages').stream(primaryKey: ['id'])
```

**Typing Indicators** (Broadcast):
```dart
// Ephemeral - not stored
channel.sendBroadcastMessage(event: 'typing', payload: {...})
```

**Live Location** (Broadcast):
```dart
// Ephemeral - rider broadcasts location
channel.sendBroadcastMessage(event: 'location', payload: {...})
```

---

## Services

### Payment Service (Paystack)

**Features:**
- Initialize transactions
- Split payments (vendor/rider/platform)
- Create vendor subaccounts
- Verify transactions

**Payment Flow:**
1. Customer places order
2. App initializes Paystack transaction
3. Customer pays via Paystack checkout
4. Payment splits automatically:
   - Vendor receives product amount
   - Rider receives delivery fee
   - Platform receives commission

### AI Service (Groq)

**Features:**
- Natural language query analysis
- Category extraction
- Keyword extraction
- Smart suggestions

**Example:**
```
User: "I want chapo and beans near me"
AI Response: {
  categories: ["food"],
  keywords: ["chapo", "beans"]
}
```

### Map Service

**Features:**
- Current location tracking
- Distance calculation
- Route planning (OSRM)
- Delivery fee calculation

**Delivery Fee Formula:**
```
fee = baseFee + (distance * perKmRate)
// Default: 2.00 + (km * 0.50)
```

### Realtime Service (Supabase)

**Features:**
- Real-time chat messages
- Typing indicators
- Live rider location
- Order status updates

**No Socket.io server needed!**

---

## Building & Deployment

### GitHub Actions (Recommended)

The app automatically builds when you push to `main`:

1. Push code to GitHub
2. GitHub Actions builds APK
3. Download from Actions → Artifacts

**Workflow:** `.github/workflows/build-apk.yml`

### Manual Build

```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release

# APK location
build/app/outputs/flutter-apk/app-release.apk
```

### Play Store Deployment

1. Create keystore:
```bash
keytool -genkey -v -keystore leta-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias leta
```

2. Create `android/key.properties`:
```properties
storePassword=your_password
keyPassword=your_password
keyAlias=leta
storeFile=../leta-key.jks
```

3. Build App Bundle:
```bash
flutter build appbundle --release
```

4. Upload to Play Console

---

## Troubleshooting

### Common Issues

#### "Configuration Required" Screen
**Cause:** API keys not set  
**Solution:** Add all required secrets to GitHub Secrets and rebuild

#### Build Fails on GitHub
**Cause:** Various  
**Solution:** Check Actions logs for specific error

#### App Crashes on Launch
**Cause:** Usually missing resources  
**Solution:** Check Android logs with `adb logcat`

#### Gradle Download Fails
**Cause:** Network issues  
**Solution:** GitHub Actions builds avoid this - use CI/CD

#### Payments Not Working
**Cause:** Wrong Paystack keys  
**Solution:** Verify keys in GitHub Secrets, use test keys first

#### Chat Not Real-time
**Cause:** Realtime not enabled  
**Solution:** Enable tables in Supabase Replication settings

### Debug Commands

```bash
# Check Flutter setup
flutter doctor -v

# Clean build
flutter clean && flutter pub get

# View logs
adb logcat | grep -i "flutter\|leta"

# Analyze code
flutter analyze
```

---

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

---

## License

This project is proprietary software. All rights reserved.

---

## Support

- **GitHub Issues:** Report bugs and feature requests
- **Documentation:** This file
- **Email:** Contact the development team

---

## Changelog

### v1.0.0 (January 2026)
- Initial production release
- 4 role-based dashboards
- Real-time chat via Supabase
- Split payments via Paystack
- AI search via Groq
- Live rider tracking
- Offline support

---

**Built with ❤️ using Flutter**
