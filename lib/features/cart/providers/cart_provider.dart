import 'package:flutter/material.dart';
import '../../../core/models/product_model.dart';
import '../../../core/models/order_model.dart';
import '../../../core/config/app_config.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  Map<String, dynamic>? selectedVariants;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selectedVariants,
  });

  double get totalPrice => product.price * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;

  // Get total items quantity
  int get totalQuantity {
    return _items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  // Get subtotal
  double get subtotal {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Calculate delivery fee (will be set based on distance)
  double _deliveryFee = 0.0;
  double get deliveryFee => _deliveryFee;

  void setDeliveryFee(double fee) {
    _deliveryFee = fee;
    notifyListeners();
  }

  // Calculate tax
  double get tax {
    return subtotal * AppConfig.taxRate;
  }

  // Platform fee
  double get platformFee => AppConfig.platformFee;

  // Calculate total
  double get total {
    return subtotal + deliveryFee + platformFee + tax;
  }

  // Add item to cart
  void addItem(ProductModel product, {Map<String, dynamic>? selectedVariants}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id] = CartItem(
        product: product,
        quantity: 1,
        selectedVariants: selectedVariants,
      );
    }
    notifyListeners();
  }

  // Remove item from cart
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  // Update quantity
  void updateQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) return;
    
    if (quantity <= 0) {
      removeItem(productId);
    } else {
      _items[productId]!.quantity = quantity;
      notifyListeners();
    }
  }

  // Increase quantity
  void increaseQuantity(String productId) {
    if (_items.containsKey(productId)) {
      _items[productId]!.quantity++;
      notifyListeners();
    }
  }

  // Decrease quantity
  void decreaseQuantity(String productId) {
    if (!_items.containsKey(productId)) return;
    
    if (_items[productId]!.quantity > 1) {
      _items[productId]!.quantity--;
    } else {
      removeItem(productId);
    }
    notifyListeners();
  }

  // Clear cart
  void clear() {
    _items.clear();
    _deliveryFee = 0.0;
    notifyListeners();
  }

  // Convert cart to order items
  List<OrderItem> toOrderItems() {
    return _items.values.map((cartItem) {
      return OrderItem(
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        price: cartItem.product.price,
        quantity: cartItem.quantity,
        imageUrl: cartItem.product.imageUrl,
        selectedVariants: cartItem.selectedVariants,
      );
    }).toList();
  }

  // Get cart summary
  Map<String, dynamic> getCartSummary() {
    return {
      'subtotal': subtotal,
      'delivery_fee': deliveryFee,
      'platform_fee': platformFee,
      'tax': tax,
      'total': total,
      'item_count': totalQuantity,
    };
  }
}
