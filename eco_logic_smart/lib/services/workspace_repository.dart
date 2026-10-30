import 'dart:convert';

import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/company_account.dart';
import '../models/operational_records.dart';
import 'backend_config.dart';

class WorkspaceRepository {
  WorkspaceRepository._();

  static const _inventoryPrefix = 'ecologismart.inventory.v1.';
  static const _materialsKey = 'ecologismart.demo.materials.v1';
  static const _routesKey = 'ecologismart.demo.routes.v1';
  static const _exchangesKey = 'ecologismart.demo.exchanges.v1';
  static const _routeJoinsKey = 'ecologismart.demo.route_joins.v1';
  static const _bucket = 'material-images';
  static final _missingSchemaTables = <String>{};

  static bool get hasExchangeSchema =>
      !_missingSchemaTables.contains('material_exchange_requests');
  static bool get hasRouteSharingSchema =>
      !_missingSchemaTables.contains('route_join_requests');

  static bool get _cloud => BackendConfig.isRequested;
  static String _ownerId(CompanyAccount account) => _cloud
      ? BackendConfig.client.auth.currentUser!.id
      : (account.id.isNotEmpty ? account.id : account.email.toLowerCase());

  static Future<List<InventoryItem>> loadInventory(
    CompanyAccount account,
  ) async {
    if (_cloud) {
      final rows = await BackendConfig.client
          .from('inventory_items')
          .select()
          .eq('company_id', _ownerId(account))
          .order('name');
      return rows.map((row) => InventoryItem.fromJson(row)).toList();
    }
    final preferences = await SharedPreferences.getInstance();
    return _readList(
      preferences,
      '$_inventoryPrefix${_ownerId(account)}',
    ).map(InventoryItem.fromJson).toList();
  }

  static Future<List<InventoryItem>> loadRecoverableLocalInventory(
    CompanyAccount account,
  ) async {
    if (!_cloud) return const [];
    final preferences = await SharedPreferences.getInstance();
    final email = account.email.trim().toLowerCase();
    final legacyIds = {email, if (account.id.isNotEmpty) account.id};
    final importedKey =
        'ecologismart.inventory.imported.v1.${_ownerId(account)}';
    if (preferences.getBool(importedKey) == true) return const [];

    final matchingKeys = preferences.getKeys().where((key) {
      if (!key.startsWith(_inventoryPrefix)) return false;
      final owner = key.substring(_inventoryPrefix.length);
      return legacyIds.any((id) => id.toLowerCase() == owner.toLowerCase());
    });
    final rows = <Map<String, dynamic>>[];
    for (final key in matchingKeys) {
      rows.addAll(_readList(preferences, key));
    }
    return rows.map(InventoryItem.fromJson).toList();
  }

  static Future<int> importRecoverableInventory({
    required CompanyAccount account,
    required List<InventoryItem> localItems,
    required List<InventoryItem> currentItems,
  }) async {
    if (!_cloud) {
      throw StateError(
        'La importación requiere una cuenta conectada a Supabase.',
      );
    }
    final preferences = await SharedPreferences.getInstance();
    final importedKey =
        'ecologismart.inventory.imported.v1.${_ownerId(account)}';
    if (preferences.getBool(importedKey) == true) return 0;

    final knownItems = currentItems.map(_inventorySignature).toSet();
    final newItems = localItems
        .where((item) => knownItems.add(_inventorySignature(item)))
        .map((item) => {...item.toJson(), 'company_id': _ownerId(account)})
        .toList();
    if (newItems.isNotEmpty) {
      await BackendConfig.client.from('inventory_items').insert(newItems);
    }
    await preferences.setBool(importedKey, true);
    return newItems.length;
  }

  static String _inventorySignature(InventoryItem item) =>
      '${item.name.trim().toLowerCase()}|${item.category.trim().toLowerCase()}|'
      '${item.quantity}|${item.unit.trim().toLowerCase()}|${item.lowStockThreshold}';

  static Future<void> saveInventory(
    CompanyAccount account,
    InventoryItem item,
  ) async {
    if (_cloud) {
      await BackendConfig.client.from('inventory_items').insert({
        ...item.toJson(),
        'company_id': _ownerId(account),
      });
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final key = '$_inventoryPrefix${_ownerId(account)}';
    final rows = _readList(preferences, key);
    rows.insert(0, {
      ...item.toJson(),
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
    });
    await preferences.setString(key, jsonEncode(rows));
  }

  static Future<void> deleteInventory(
    CompanyAccount account,
    InventoryItem item,
  ) async {
    if (_cloud) {
      await BackendConfig.client
          .from('inventory_items')
          .delete()
          .eq('id', item.id)
          .eq('company_id', _ownerId(account));
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final key = '$_inventoryPrefix${_ownerId(account)}';
    final rows = _readList(preferences, key)
      ..removeWhere((row) => row['id'] == item.id);
    await preferences.setString(key, jsonEncode(rows));
  }

  static Future<List<MaterialListing>> loadMaterials() async {
    if (_cloud) {
      final rows = await BackendConfig.client
          .from('material_listings')
          .select()
          .order('created_at', ascending: false);
      final cloudListings = rows
          .map((row) => MaterialListing.fromJson(row))
          .toList();
      final preferences = await SharedPreferences.getInstance();
      final legacyListings = _readList(preferences, _materialsKey)
          .map(
            (row) =>
                MaterialListing.fromJson({...row, 'is_legacy_local': true}),
          )
          .toList();
      final knownListings = cloudListings.map(_materialSignature).toSet();
      return [
        ...cloudListings,
        ...legacyListings.where(
          (listing) => knownListings.add(_materialSignature(listing)),
        ),
      ];
    }
    final preferences = await SharedPreferences.getInstance();
    return _readList(
      preferences,
      _materialsKey,
    ).map(MaterialListing.fromJson).toList();
  }

  static String _materialSignature(MaterialListing listing) =>
      '${listing.title.trim().toLowerCase()}|'
      '${listing.companyName.trim().toLowerCase()}|'
      '${listing.quantity}|${listing.unit.trim().toLowerCase()}';

  static Future<void> publishMaterial({
    required CompanyAccount account,
    required MaterialListing listing,
    XFile? photo,
  }) async {
    if (_cloud) {
      String? imageUrl;
      if (photo != null) {
        final extension = photo.name.split('.').last.toLowerCase();
        final safeExtension = RegExp(r'^[a-z0-9]{1,5}$').hasMatch(extension)
            ? extension
            : 'jpg';
        final path =
            '${_ownerId(account)}/${DateTime.now().microsecondsSinceEpoch}.$safeExtension';
        final contentType = switch (safeExtension) {
          'png' => 'image/png',
          'webp' => 'image/webp',
          _ => 'image/jpeg',
        };
        await BackendConfig.client.storage
            .from(_bucket)
            .uploadBinary(
              path,
              await photo.readAsBytes(),
              fileOptions: FileOptions(contentType: contentType),
            );
        imageUrl = BackendConfig.client.storage
            .from(_bucket)
            .getPublicUrl(path);
      }
      await BackendConfig.client.from('material_listings').insert({
        ...listing.toJson(),
        'company_id': _ownerId(account),
        'image_url': imageUrl,
      });
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final rows = _readList(preferences, _materialsKey);
    final imageBase64 = photo == null
        ? null
        : base64Encode(await photo.readAsBytes());
    rows.insert(0, {
      ...listing.toJson(),
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'company_id': _ownerId(account),
      'company_name': account.businessName,
      'city': account.city,
      'image_url': null,
      'image_base64': imageBase64,
    });
    await preferences.setString(_materialsKey, jsonEncode(rows));
  }

  static Future<void> deleteMaterial({
    required CompanyAccount account,
    required MaterialListing listing,
  }) async {
    if (_cloud && !listing.isLegacyLocal) {
      await BackendConfig.client
          .from('material_listings')
          .delete()
          .eq('id', listing.id)
          .eq('company_id', _ownerId(account));
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final rows = _readList(preferences, _materialsKey)
      ..removeWhere((row) => row['id'] == listing.id);
    await preferences.setString(_materialsKey, jsonEncode(rows));
  }

  static Future<List<MaterialExchangeRequest>> loadExchangeRequests() async {
    if (_cloud) {
      try {
        final rows = await BackendConfig.client
            .from('material_exchange_requests')
            .select(
              'id,listing_id,requester_company_id,requester_company_name,'
              'offered_product,offered_quantity,offered_unit,message,status,'
              'created_at,updated_at',
            )
            .order('created_at', ascending: false);
        _missingSchemaTables.remove('material_exchange_requests');
        return rows
            .map((row) => MaterialExchangeRequest.fromJson(row))
            .toList();
      } on PostgrestException catch (error) {
        if (error.code == 'PGRST205' ||
            error.code == 'PGRST204' ||
            error.code == '42703' ||
            error.code == '42P01') {
          _missingSchemaTables.add('material_exchange_requests');
          return [];
        }
        rethrow;
      }
    }
    final preferences = await SharedPreferences.getInstance();
    return _readList(
      preferences,
      _exchangesKey,
    ).map(MaterialExchangeRequest.fromJson).toList();
  }

  static Future<void> requestMaterialExchange({
    required CompanyAccount account,
    required MaterialListing listing,
    required String offeredProduct,
    required double offeredQuantity,
    required String offeredUnit,
    String message = '',
  }) async {
    final row = {
      'listing_id': listing.id,
      'requester_company_id': _ownerId(account),
      'requester_company_name': account.businessName,
      'offered_product': offeredProduct,
      'offered_quantity': offeredQuantity,
      'offered_unit': offeredUnit,
      'message': message,
      'status': 'Pendiente',
      'created_at': DateTime.now().toIso8601String(),
    };
    if (_cloud) {
      await BackendConfig.client.from('material_exchange_requests').insert(row);
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final rows = _readList(preferences, _exchangesKey);
    rows.insert(0, {
      ...row,
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
    });
    await preferences.setString(_exchangesKey, jsonEncode(rows));
  }

  static Future<void> updateExchangeStatus(
    MaterialExchangeRequest request,
    String status,
  ) async {
    if (_cloud) {
      await BackendConfig.client
          .from('material_exchange_requests')
          .update({'status': status})
          .eq('id', request.id);
      if (status == 'Aceptada') {
        await BackendConfig.client
            .from('material_listings')
            .update({'status': 'Reservado'})
            .eq('id', request.listingId);
        await BackendConfig.client
            .from('material_exchange_requests')
            .update({'status': 'Rechazada'})
            .eq('listing_id', request.listingId)
            .eq('status', 'Pendiente')
            .neq('id', request.id);
      }
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final requests = _readList(preferences, _exchangesKey);
    for (final row in requests) {
      if (row['id'] == request.id ||
          (status == 'Aceptada' &&
              row['listing_id'] == request.listingId &&
              row['status'] == 'Pendiente')) {
        row['status'] = row['id'] == request.id ? status : 'Rechazada';
      }
    }
    await preferences.setString(_exchangesKey, jsonEncode(requests));
    if (status == 'Aceptada') {
      final listings = _readList(preferences, _materialsKey);
      for (final row in listings) {
        if (row['id'] == request.listingId) row['status'] = 'Reservado';
      }
      await preferences.setString(_materialsKey, jsonEncode(listings));
    }
  }

  static Future<List<LogisticsRequest>> loadRoutes() async {
    if (_cloud) {
      final rows = await BackendConfig.client
          .from('logistics_requests')
          .select()
          .order('created_at', ascending: false);
      return rows.map((row) => LogisticsRequest.fromJson(row)).toList();
    }
    final preferences = await SharedPreferences.getInstance();
    return _readList(
      preferences,
      _routesKey,
    ).map(LogisticsRequest.fromJson).toList();
  }

  static Future<void> requestRoute({
    required CompanyAccount account,
    String origin = '',
    required String destination,
    required String deliveryType,
    String cargoDescription = '',
    DateTime? travelDate,
  }) async {
    final row = {
      'company_id': _ownerId(account),
      'destination': destination,
      'delivery_type': deliveryType,
      'origin': origin,
      'cargo_description': cargoDescription,
      'travel_date': travelDate?.toIso8601String().split('T').first,
      'status': 'Abierta',
      'created_at': DateTime.now().toIso8601String(),
    };
    if (_cloud) {
      await BackendConfig.client.from('logistics_requests').insert(row);
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final rows = _readList(preferences, _routesKey);
    rows.insert(0, {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      ...row,
      'company_id': _ownerId(account),
      'company_name': account.businessName,
    });
    await preferences.setString(_routesKey, jsonEncode(rows));
  }

  static Future<List<RouteJoinRequest>> loadRouteJoinRequests() async {
    if (_cloud) {
      try {
        final rows = await BackendConfig.client
            .from('route_join_requests')
            .select()
            .order('created_at', ascending: false);
        _missingSchemaTables.remove('route_join_requests');
        return rows.map((row) => RouteJoinRequest.fromJson(row)).toList();
      } on PostgrestException catch (error) {
        if (error.code == 'PGRST205' || error.code == '42P01') {
          _missingSchemaTables.add('route_join_requests');
          return [];
        }
        rethrow;
      }
    }
    final preferences = await SharedPreferences.getInstance();
    return _readList(
      preferences,
      _routeJoinsKey,
    ).map(RouteJoinRequest.fromJson).toList();
  }

  static Future<void> requestToJoinRoute({
    required CompanyAccount account,
    required LogisticsRequest route,
    String message = '',
  }) async {
    final row = {
      'route_id': route.id,
      'requester_company_id': _ownerId(account),
      'requester_company_name': account.businessName,
      'message': message,
      'status': 'Pendiente',
      'created_at': DateTime.now().toIso8601String(),
    };
    if (_cloud) {
      await BackendConfig.client.from('route_join_requests').insert(row);
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final requests = _readList(preferences, _routeJoinsKey);
    requests.insert(0, {
      ...row,
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
    });
    await preferences.setString(_routeJoinsKey, jsonEncode(requests));
  }

  static Future<void> updateRouteJoinStatus(
    RouteJoinRequest request,
    String status,
  ) async {
    if (_cloud) {
      await BackendConfig.client
          .from('route_join_requests')
          .update({'status': status})
          .eq('id', request.id);
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final requests = _readList(preferences, _routeJoinsKey);
    for (final row in requests) {
      if (row['id'] == request.id) row['status'] = status;
    }
    await preferences.setString(_routeJoinsKey, jsonEncode(requests));
  }

  static Future<void> updateRouteStatus(
    LogisticsRequest route,
    String status,
  ) async {
    if (_cloud) {
      await BackendConfig.client
          .from('logistics_requests')
          .update({'status': status})
          .eq('id', route.id);
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final routes = _readList(preferences, _routesKey);
    for (final row in routes) {
      if (row['id'] == route.id) row['status'] = status;
    }
    await preferences.setString(_routesKey, jsonEncode(routes));
  }

  static List<Map<String, dynamic>> _readList(
    SharedPreferences preferences,
    String key,
  ) {
    final encoded = preferences.getString(key);
    if (encoded == null || encoded.isEmpty) return [];
    return (jsonDecode(encoded) as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
