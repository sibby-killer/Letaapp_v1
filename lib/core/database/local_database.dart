import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/chat_message_model.dart';

class LocalDatabase {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<void> initialize() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'leta_app.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Products Cache Table
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        store_id TEXT NOT NULL,
        category_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        image_url TEXT,
        image_urls TEXT,
        is_available INTEGER NOT NULL DEFAULT 1,
        stock INTEGER NOT NULL DEFAULT 0,
        unit TEXT,
        variants TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        synced_at TEXT NOT NULL
      )
    ''');

    // Orders Cache Table
    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        store_id TEXT NOT NULL,
        rider_id TEXT,
        order_number TEXT NOT NULL,
        items TEXT NOT NULL,
        subtotal REAL NOT NULL,
        delivery_fee REAL NOT NULL,
        platform_fee REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        status TEXT NOT NULL,
        delivery_mode TEXT NOT NULL,
        payment_status TEXT NOT NULL,
        paystack_reference TEXT,
        delivery_address TEXT NOT NULL,
        estimated_delivery_time TEXT,
        completed_at TEXT,
        customer_confirmed INTEGER NOT NULL DEFAULT 0,
        rider_confirmed INTEGER NOT NULL DEFAULT 0,
        cancellation_reason TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        synced_at TEXT NOT NULL
      )
    ''');

    // Chat Messages Cache Table
    await db.execute('''
      CREATE TABLE chat_messages (
        id TEXT PRIMARY KEY,
        room_id TEXT NOT NULL,
        sender_id TEXT NOT NULL,
        sender_name TEXT NOT NULL,
        sender_image_url TEXT,
        message TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'text',
        metadata TEXT,
        is_read INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        synced_at TEXT NOT NULL
      )
    ''');

    // Create indexes for performance
    await db.execute('CREATE INDEX idx_products_store_id ON products(store_id)');
    await db.execute('CREATE INDEX idx_orders_customer_id ON orders(customer_id)');
    await db.execute('CREATE INDEX idx_orders_status ON orders(status)');
    await db.execute('CREATE INDEX idx_chat_messages_room_id ON chat_messages(room_id)');
  }

  // Product Cache Methods
  Future<void> cacheProducts(List<ProductModel> products) async {
    final db = await database;
    final batch = db.batch();

    for (final product in products) {
      batch.insert(
        'products',
        {
          ...product.toJson(),
          'synced_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
  }

  Future<List<ProductModel>> getCachedProducts(String storeId) async {
    final db = await database;
    final maps = await db.query(
      'products',
      where: 'store_id = ?',
      whereArgs: [storeId],
    );

    return maps.map((map) => ProductModel.fromJson(map)).toList();
  }

  // Order Cache Methods
  Future<void> cacheOrder(OrderModel order) async {
    final db = await database;
    await db.insert(
      'orders',
      {
        ...order.toJson(),
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OrderModel>> getCachedOrders(String customerId) async {
    final db = await database;
    final maps = await db.query(
      'orders',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => OrderModel.fromJson(map)).toList();
  }

  Future<OrderModel?> getCachedOrder(String orderId) async {
    final db = await database;
    final maps = await db.query(
      'orders',
      where: 'id = ?',
      whereArgs: [orderId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return OrderModel.fromJson(maps.first);
  }

  // Chat Messages Cache Methods
  Future<void> cacheMessage(ChatMessageModel message) async {
    final db = await database;
    await db.insert(
      'chat_messages',
      {
        ...message.toJson(),
        'synced_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatMessageModel>> getCachedMessages(String roomId) async {
    final db = await database;
    final maps = await db.query(
      'chat_messages',
      where: 'room_id = ?',
      whereArgs: [roomId],
      orderBy: 'created_at ASC',
    );

    return maps.map((map) => ChatMessageModel.fromJson(map)).toList();
  }

  // Clear all cache
  Future<void> clearCache() async {
    final db = await database;
    await db.delete('products');
    await db.delete('orders');
    await db.delete('chat_messages');
  }

  // Close database
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
