class User {
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
  });

  final String id;
  final String email;
  final String fullName;
  final String role;

  bool get isDriver => role == 'DRIVER';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        role: json['role'] as String,
      );
}

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory TokenPair.fromJson(Map<String, dynamic> json) => TokenPair(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
      );
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    this.imageKey,
  });

  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? imageKey;

  double get total => price * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int,
        imageKey: json['image_key'] as String?,
      );
}

class StatusHistory {
  const StatusHistory({
    required this.id,
    required this.toStatus,
    this.fromStatus,
    required this.changedAt,
  });

  final String id;
  final String? fromStatus;
  final String toStatus;
  final DateTime changedAt;

  factory StatusHistory.fromJson(Map<String, dynamic> json) => StatusHistory(
        id: json['id'] as String,
        fromStatus: json['from_status'] as String?,
        toStatus: json['to_status'] as String,
        changedAt: DateTime.parse(json['changed_at'] as String).toLocal(),
      );
}

class Order {
  const Order({
    required this.id,
    required this.status,
    required this.customerId,
    this.driverId,
    required this.pickupAddress,
    required this.deliveryAddress,
    required this.totalAmount,
    this.notes,
    required this.createdAt,
    required this.items,
    required this.history,
  });

  final String id;
  final String status;
  final String customerId;
  final String? driverId;
  final String pickupAddress;
  final String deliveryAddress;
  final double totalAmount;
  final String? notes;
  final DateTime createdAt;
  final List<OrderItem> items;
  final List<StatusHistory> history;

  bool get isPending => status == 'PENDING';
  bool get isAvailable => status == 'PENDING';

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        status: json['status'] as String,
        customerId: json['customer_id'] as String,
        driverId: json['driver_id'] as String?,
        pickupAddress: json['pickup_address'] as String,
        deliveryAddress: json['delivery_address'] as String,
        totalAmount: (json['total_amount'] as num).toDouble(),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        items: (json['items'] as List<dynamic>)
            .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        history: (json['history'] as List<dynamic>? ?? [])
            .map((e) => StatusHistory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class RealtimeEvent {
  const RealtimeEvent(
      {required this.type, required this.orderId, required this.status});

  final String type;
  final String orderId;
  final String status;

  bool get isOrderUpdate => type == 'order.updated';
  bool get isOrderCreated => type == 'order.created';

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) => RealtimeEvent(
        type: json['type'] as String,
        orderId: json['order_id'] as String,
        status: json['status'] as String,
      );
}
