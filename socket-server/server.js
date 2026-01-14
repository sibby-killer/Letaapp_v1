/**
 * Leta App - Socket.io Chat Server
 * 
 * This server handles real-time chat functionality for the Leta App.
 * Features:
 * - Direct messaging (Customer <-> Vendor)
 * - Global rooms (All Vendors, All Riders)
 * - Typing indicators
 * - Admin oversight (can join any room)
 * 
 * Run: npm install && npm start
 * Default port: 3000
 */

require('dotenv').config();
const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
const server = http.createServer(app);

// Configure CORS for Socket.io
const io = new Server(server, {
  cors: {
    origin: "*", // In production, specify your app's domain
    methods: ["GET", "POST"],
    credentials: true
  },
  pingTimeout: 60000,
  pingInterval: 25000
});

app.use(cors());
app.use(express.json());

// Health check endpoint
app.get('/', (req, res) => {
  res.json({ 
    status: 'ok', 
    message: 'Leta Chat Server is running',
    timestamp: new Date().toISOString()
  });
});

// Store active users and their rooms
const activeUsers = new Map(); // { oderId: { socketId, rooms: [], userInfo } }
const roomTyping = new Map(); // { roomId: Set(userIds) }

// Socket.io connection handler
io.on('connection', (socket) => {
  console.log(`✅ User connected: ${socket.id}`);
  
  // User identification
  socket.on('identify', (data) => {
    const { userId, userName, userRole } = data;
    
    activeUsers.set(userId, {
      socketId: socket.id,
      rooms: [],
      userInfo: { userId, userName, userRole }
    });
    
    socket.userId = userId;
    socket.userName = userName;
    socket.userRole = userRole;
    
    console.log(`👤 User identified: ${userName} (${userRole})`);
    
    // Auto-join global rooms based on role
    if (userRole === 'vendor') {
      socket.join('vendors_global');
      console.log(`🏪 ${userName} joined vendors_global room`);
    } else if (userRole === 'rider') {
      socket.join('riders_global');
      console.log(`🚴 ${userName} joined riders_global room`);
    } else if (userRole === 'admin') {
      // Admin can see all rooms
      socket.join('admin_oversight');
      console.log(`👨‍💼 ${userName} joined admin_oversight room`);
    }
  });
  
  // Join a chat room
  socket.on('join_room', (data) => {
    const { roomId, userId, userName } = data;
    
    socket.join(roomId);
    
    // Track user's rooms
    const user = activeUsers.get(userId);
    if (user) {
      user.rooms.push(roomId);
    }
    
    console.log(`📥 ${userName || userId} joined room: ${roomId}`);
    
    // Notify others in the room
    socket.to(roomId).emit('user_joined', {
      roomId,
      userId,
      userName,
      timestamp: new Date().toISOString()
    });
  });
  
  // Leave a chat room
  socket.on('leave_room', (data) => {
    const { roomId, userId, userName } = data;
    
    socket.leave(roomId);
    
    // Remove from user's rooms
    const user = activeUsers.get(userId);
    if (user) {
      user.rooms = user.rooms.filter(r => r !== roomId);
    }
    
    console.log(`📤 ${userName || userId} left room: ${roomId}`);
    
    // Clear typing indicator
    const typingUsers = roomTyping.get(roomId);
    if (typingUsers) {
      typingUsers.delete(userId);
    }
    
    // Notify others
    socket.to(roomId).emit('user_left', {
      roomId,
      userId,
      userName,
      timestamp: new Date().toISOString()
    });
  });
  
  // Send a message
  socket.on('send_message', (data) => {
    const { 
      roomId, 
      senderId, 
      senderName, 
      senderImageUrl,
      message, 
      type = 'text',
      metadata 
    } = data;
    
    const messageData = {
      id: `msg_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      roomId,
      senderId,
      senderName,
      senderImageUrl,
      message,
      type,
      metadata,
      isRead: false,
      createdAt: new Date().toISOString()
    };
    
    console.log(`💬 Message in ${roomId}: ${message.substring(0, 50)}...`);
    
    // Send to all users in the room (including sender for confirmation)
    io.to(roomId).emit('new_message', messageData);
    
    // Also send to admin oversight room
    io.to('admin_oversight').emit('admin_message_monitor', {
      ...messageData,
      roomId
    });
    
    // Clear typing indicator for sender
    const typingUsers = roomTyping.get(roomId);
    if (typingUsers) {
      typingUsers.delete(senderId);
      socket.to(roomId).emit('user_typing', {
        roomId,
        userId: senderId,
        isTyping: false
      });
    }
  });
  
  // Typing indicator
  socket.on('typing', (data) => {
    const { roomId, userId, userName, isTyping } = data;
    
    // Track typing users per room
    if (!roomTyping.has(roomId)) {
      roomTyping.set(roomId, new Set());
    }
    
    const typingUsers = roomTyping.get(roomId);
    
    if (isTyping) {
      typingUsers.add(userId);
    } else {
      typingUsers.delete(userId);
    }
    
    // Broadcast to room (except sender)
    socket.to(roomId).emit('user_typing', {
      roomId,
      userId,
      userName,
      isTyping,
      typingUsers: Array.from(typingUsers)
    });
  });
  
  // Mark message as read
  socket.on('mark_read', (data) => {
    const { messageId, roomId, userId } = data;
    
    // Broadcast read receipt to room
    io.to(roomId).emit('message_read', {
      messageId,
      roomId,
      readBy: userId,
      readAt: new Date().toISOString()
    });
  });
  
  // Join global room (for vendors/riders)
  socket.on('join_global_room', (data) => {
    const { roomType, userId, userName } = data;
    const globalRoomId = `${roomType}_global`; // vendors_global or riders_global
    
    socket.join(globalRoomId);
    console.log(`🌐 ${userName || userId} joined global room: ${globalRoomId}`);
    
    // Notify others
    io.to(globalRoomId).emit('global_user_joined', {
      roomType,
      userId,
      userName,
      timestamp: new Date().toISOString()
    });
  });
  
  // Admin: Join any room for oversight
  socket.on('admin_join_room', (data) => {
    const { roomId, adminId, adminName } = data;
    
    if (socket.userRole !== 'admin') {
      socket.emit('error', { message: 'Unauthorized: Admin access required' });
      return;
    }
    
    socket.join(roomId);
    console.log(`👨‍💼 Admin ${adminName} joined room for oversight: ${roomId}`);
    
    // Optionally notify room (or keep silent for monitoring)
    // socket.to(roomId).emit('admin_joined', { adminName });
  });
  
  // Get online users in a room
  socket.on('get_room_users', async (data) => {
    const { roomId } = data;
    const sockets = await io.in(roomId).fetchSockets();
    
    const users = sockets.map(s => ({
      userId: s.userId,
      userName: s.userName,
      userRole: s.userRole
    })).filter(u => u.userId);
    
    socket.emit('room_users', { roomId, users });
  });
  
  // Handle disconnection
  socket.on('disconnect', (reason) => {
    console.log(`❌ User disconnected: ${socket.id} (${reason})`);
    
    // Clean up user from activeUsers
    for (const [userId, userData] of activeUsers.entries()) {
      if (userData.socketId === socket.id) {
        // Notify all rooms the user was in
        userData.rooms.forEach(roomId => {
          socket.to(roomId).emit('user_left', {
            roomId,
            userId,
            userName: userData.userInfo?.userName,
            timestamp: new Date().toISOString()
          });
          
          // Clear typing indicator
          const typingUsers = roomTyping.get(roomId);
          if (typingUsers) {
            typingUsers.delete(userId);
          }
        });
        
        activeUsers.delete(userId);
        break;
      }
    }
  });
  
  // Error handling
  socket.on('error', (error) => {
    console.error(`Socket error: ${error}`);
  });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════════════════════╗
  ║   🚀 Leta Chat Server is running!                  ║
  ║   📍 Local:    http://localhost:${PORT}              ║
  ║   📍 Network:  http://YOUR_IP:${PORT}                ║
  ╚═══════════════════════════════════════════════════╝
  `);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});
