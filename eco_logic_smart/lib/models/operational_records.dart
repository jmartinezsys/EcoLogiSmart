import 'dart:convert';
import 'dart:typed_data';

class InventoryItem {
  const InventoryItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.category = '',
    this.lowStockThreshold = 0,
  });

  final String id;
  final String name;
  final double quantity;
  final String unit;
  final String category;
  final double lowStockThreshold;

  factory InventoryItem.fromJson(Map<String, dynamic> json) => InventoryItem(
    id: json['id'] as String,
    name: json['name'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
    unit: json['unit'] as String? ?? 'unidades',
    category: json['category'] as String? ?? '',
    lowStockThreshold: (json['low_stock_threshold'] as num?)?.toDouble() ?? 0,
  );

  Map<String, Object?> toJson() => {
    'name': name,
    'quantity': quantity,
    'unit': unit,
    'category': category,
    'low_stock_threshold': lowStockThreshold,
  };
}

class MaterialListing {
  const MaterialListing({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.quantity,
    required this.unit,
    required this.status,
    required this.companyName,
    required this.city,
    this.category = '',
    this.exchangeFor,
    this.imageUrl,
    this.localImageBytes,
    this.isLegacyLocal = false,
  });

  final String id;
  final String companyId;
  final String title;
  final String description;
  final double quantity;
  final String unit;
  final String status;
  final String companyName;
  final String city;
  final String category;
  final String? exchangeFor;
  final String? imageUrl;
  final Uint8List? localImageBytes;
  final bool isLegacyLocal;

  factory MaterialListing.fromJson(Map<String, dynamic> json) =>
      MaterialListing(
        id: json['id'] as String,
        companyId: json['company_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        unit: json['unit'] as String? ?? 'unidades',
        status: json['status'] as String? ?? 'Disponible',
        companyName: json['company_name'] as String? ?? 'Empresa EcoLogiSmart',
        city: json['city'] as String? ?? '',
        category: json['category'] as String? ?? '',
        exchangeFor: json['exchange_for'] as String?,
        imageUrl: json['image_url'] as String?,
        localImageBytes: json['image_base64'] is String
            ? base64Decode(json['image_base64'] as String)
            : null,
        isLegacyLocal: json['is_legacy_local'] as bool? ?? false,
      );

  Map<String, Object?> toJson() => {
    'title': title,
    'description': description,
    'quantity': quantity,
    'unit': unit,
    'status': status,
    'category': category,
    'exchange_for': exchangeFor,
    'image_url': imageUrl,
  };
}

class MaterialExchangeRequest {
  const MaterialExchangeRequest({
    required this.id,
    required this.listingId,
    required this.requesterCompanyId,
    required this.requesterCompanyName,
    required this.offeredProduct,
    this.offeredQuantity = 0,
    this.offeredUnit = 'unidades',
    required this.status,
    required this.createdAt,
    this.message = '',
  });

  final String id;
  final String listingId;
  final String requesterCompanyId;
  final String requesterCompanyName;
  final String offeredProduct;
  final double offeredQuantity;
  final String offeredUnit;
  final String status;
  final DateTime createdAt;
  final String message;

  factory MaterialExchangeRequest.fromJson(Map<String, dynamic> json) =>
      MaterialExchangeRequest(
        id: json['id'] as String,
        listingId: json['listing_id'] as String? ?? '',
        requesterCompanyId: json['requester_company_id'] as String? ?? '',
        requesterCompanyName:
            json['requester_company_name'] as String? ?? 'Empresa',
        offeredProduct: json['offered_product'] as String? ?? '',
        offeredQuantity: (json['offered_quantity'] as num?)?.toDouble() ?? 0,
        offeredUnit: json['offered_unit'] as String? ?? 'unidades',
        status: json['status'] as String? ?? 'Pendiente',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        message: json['message'] as String? ?? '',
      );

  Map<String, Object?> toJson() => {
    'id': id,
    'listing_id': listingId,
    'requester_company_id': requesterCompanyId,
    'requester_company_name': requesterCompanyName,
    'offered_product': offeredProduct,
    'offered_quantity': offeredQuantity,
    'offered_unit': offeredUnit,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'message': message,
  };
}

class RouteJoinRequest {
  const RouteJoinRequest({
    required this.id,
    required this.routeId,
    required this.requesterCompanyId,
    required this.requesterCompanyName,
    required this.status,
    required this.createdAt,
    this.message = '',
  });

  final String id;
  final String routeId;
  final String requesterCompanyId;
  final String requesterCompanyName;
  final String status;
  final DateTime createdAt;
  final String message;

  factory RouteJoinRequest.fromJson(Map<String, dynamic> json) =>
      RouteJoinRequest(
        id: json['id'] as String,
        routeId: json['route_id'] as String? ?? '',
        requesterCompanyId: json['requester_company_id'] as String? ?? '',
        requesterCompanyName:
            json['requester_company_name'] as String? ?? 'Empresa',
        status: json['status'] as String? ?? 'Pendiente',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        message: json['message'] as String? ?? '',
      );
}

class LogisticsRequest {
  const LogisticsRequest({
    required this.id,
    required this.companyId,
    required this.companyName,
    required this.destination,
    required this.deliveryType,
    required this.createdAt,
    this.origin = '',
    this.cargoDescription = '',
    this.status = 'Abierta',
    this.travelDate,
  });

  final String id;
  final String companyId;
  final String companyName;
  final String destination;
  final String deliveryType;
  final DateTime createdAt;
  final String origin;
  final String cargoDescription;
  final String status;
  final DateTime? travelDate;

  factory LogisticsRequest.fromJson(Map<String, dynamic> json) =>
      LogisticsRequest(
        id: json['id'] as String,
        companyId: json['company_id'] as String? ?? '',
        companyName: json['company_name'] as String? ?? 'Empresa EcoLogiSmart',
        destination: json['destination'] as String? ?? '',
        deliveryType: json['delivery_type'] as String? ?? 'Materiales',
        createdAt:
            DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.now(),
        origin: json['origin'] as String? ?? '',
        cargoDescription: json['cargo_description'] as String? ?? '',
        status: json['status'] as String? ?? 'Abierta',
        travelDate: DateTime.tryParse(json['travel_date'] as String? ?? ''),
      );

  Map<String, Object?> toJson() => {
    'destination': destination,
    'delivery_type': deliveryType,
    'origin': origin,
    'cargo_description': cargoDescription,
    'travel_date': travelDate?.toIso8601String(),
    'status': status,
  };
}
