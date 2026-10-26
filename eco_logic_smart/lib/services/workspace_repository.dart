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
  static const _bucket = 'material-images';

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
      return rows.map((row) => MaterialListing.fromJson(row)).toList();
    }
    final preferences = await SharedPreferences.getInstance();
    return _readList(
      preferences,
      _materialsKey,
    ).map(MaterialListing.fromJson).toList();
  }

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
    required String destination,
    required String deliveryType,
  }) async {
    if (_cloud) {
      await BackendConfig.client.from('logistics_requests').insert({
        'company_id': _ownerId(account),
        'destination': destination,
        'delivery_type': deliveryType,
      });
      return;
    }
    final preferences = await SharedPreferences.getInstance();
    final rows = _readList(preferences, _routesKey);
    rows.insert(0, {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'company_id': _ownerId(account),
      'company_name': account.businessName,
      'destination': destination,
      'delivery_type': deliveryType,
      'created_at': DateTime.now().toIso8601String(),
    });
    await preferences.setString(_routesKey, jsonEncode(rows));
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
