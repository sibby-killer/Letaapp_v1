# Leta Chat Server - Socket.io

Real-time chat server for the Leta App.

## Quick Start

### Option 1: Run Locally

```bash
# Navigate to socket-server folder
cd socket-server

# Install dependencies
npm install

# Start the server
npm start

# Server runs at: http://localhost:3000
```

### Option 2: Deploy to Free Cloud Services

#### A) Deploy to Render.com (Recommended - Free)

1. Go to [render.com](https://render.com) and sign up
2. Click **New** → **Web Service**
3. Connect your GitHub repository
4. Configure:
   - **Name**: leta-chat-server
   - **Root Directory**: socket-server
   - **Runtime**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
5. Click **Create Web Service**
6. Copy the URL (e.g., `https://leta-chat-server.onrender.com`)

#### B) Deploy to Railway.app (Free tier)

1. Go to [railway.app](https://railway.app) and sign up
2. Click **New Project** → **Deploy from GitHub**
3. Select your repository
4. Set root directory to `socket-server`
5. Railway auto-detects Node.js and deploys
6. Copy the generated URL

#### C) Deploy to Fly.io (Free tier)

```bash
# Install Fly CLI
curl -L https://fly.io/install.sh | sh

# Login
fly auth login

# Navigate to socket-server
cd socket-server

# Create fly.toml
cat > fly.toml << EOF
app = "leta-chat-server"
primary_region = "iad"

[http_service]
  internal_port = 3000
  force_https = true
  auto_stop_machines = true
  auto_start_machines = true
EOF

# Deploy
fly launch
fly deploy

# Get URL
fly status
```

## Update Flutter App

After deploying, update your Flutter app config:

```dart
// lib/core/config/app_config.dart
static const String socketUrl = 'https://your-server-url.onrender.com';
```

For local testing with Android Emulator:
```dart
static const String socketUrl = 'http://10.0.2.2:3000';
```

For local testing with physical device:
```dart
// Use your computer's local IP (find with ipconfig/ifconfig)
static const String socketUrl = 'http://192.168.1.100:3000';
```

## Test the Server

```bash
# Check if server is running
curl http://localhost:3000

# Expected response:
# {"status":"ok","message":"Leta Chat Server is running","timestamp":"..."}
```

## Features

- ✅ Direct messaging (1-to-1)
- ✅ Room-based chat
- ✅ Typing indicators
- ✅ Read receipts
- ✅ Global vendor/rider rooms
- ✅ Admin oversight capability
- ✅ User presence tracking

## Events Reference

### Client → Server

| Event | Data | Description |
|-------|------|-------------|
| `identify` | `{userId, userName, userRole}` | Identify user on connection |
| `join_room` | `{roomId, userId, userName}` | Join a chat room |
| `leave_room` | `{roomId, userId, userName}` | Leave a chat room |
| `send_message` | `{roomId, senderId, senderName, message, type}` | Send message |
| `typing` | `{roomId, userId, userName, isTyping}` | Typing indicator |
| `mark_read` | `{messageId, roomId, userId}` | Mark message read |

### Server → Client

| Event | Data | Description |
|-------|------|-------------|
| `new_message` | Message object | New message received |
| `user_typing` | `{roomId, userId, isTyping}` | User typing status |
| `message_read` | `{messageId, readBy, readAt}` | Message read receipt |
| `user_joined` | `{roomId, userId, userName}` | User joined room |
| `user_left` | `{roomId, userId, userName}` | User left room |
