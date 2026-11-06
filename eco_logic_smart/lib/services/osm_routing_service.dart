import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RouteEstimate {
  const RouteEstimate({
    required this.option,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final int option;
  final double distanceMeters;
  final int durationSeconds;

  String get distanceLabel => distanceMeters >= 1000
      ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
      : '${distanceMeters.round()} m';

  String get durationLabel {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;
    if (hours == 0) return '$minutes min';
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }
}

class _Coordinates {
  const _Coordinates(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

/// User-triggered, approximate road route lookup using OpenStreetMap services.
/// The public Nominatim service is throttled to one uncached query per second.
class OsmRoutingService {
  OsmRoutingService._();

  static final Map<String, _Coordinates> _geocodeCache = {};
  static DateTime? _lastGeocodeRequest;
  static final http.Client _client = http.Client();

  static Future<List<RouteEstimate>> findRoadRoutes({
    required String originCity,
    required String originAddress,
    required String destinationCity,
    required String destinationAddress,
  }) async {
    final origin = await _geocode('$originAddress, $originCity, Colombia');
    final destination = await _geocode(
      '$destinationAddress, $destinationCity, Colombia',
    );
    final coordinates =
        '${origin.longitude},${origin.latitude};'
        '${destination.longitude},${destination.latitude}';
    final uri = Uri.https(
      'router.project-osrm.org',
      '/route/v1/driving/$coordinates',
      {'alternatives': '3', 'overview': 'false', 'steps': 'false'},
    );
    final response = await _client
        .get(uri)
        .timeout(const Duration(seconds: 25));
    if (response.statusCode != 200) {
      throw StateError(
        'El servicio de rutas respondió ${response.statusCode}.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['code'] != 'Ok') {
      throw StateError('No se encontró una ruta vial entre esas direcciones.');
    }
    final routes = (data['routes'] as List<dynamic>? ?? const []);
    if (routes.isEmpty) throw StateError('No se encontraron rutas viales.');
    return [
      for (var index = 0; index < routes.length; index++)
        RouteEstimate(
          option: index + 1,
          distanceMeters: (routes[index]['distance'] as num).toDouble(),
          durationSeconds: (routes[index]['duration'] as num).round(),
        ),
    ];
  }

  static Future<_Coordinates> _geocode(String query) async {
    final normalized = query.trim().toLowerCase();
    final cached = _geocodeCache[normalized];
    if (cached != null) return cached;
    final preferences = await SharedPreferences.getInstance();
    final cacheKey =
        'ecologismart.osm.geocode.v1.${base64Url.encode(utf8.encode(normalized))}';
    final saved = preferences.getString(cacheKey);
    if (saved != null) {
      final values = (jsonDecode(saved) as List<dynamic>).cast<num>();
      final coordinates = _Coordinates(
        values[0].toDouble(),
        values[1].toDouble(),
      );
      _geocodeCache[normalized] = coordinates;
      return coordinates;
    }

    final lastRequest = _lastGeocodeRequest;
    if (lastRequest != null) {
      final wait =
          const Duration(seconds: 1) - DateTime.now().difference(lastRequest);
      if (wait > Duration.zero) await Future<void>.delayed(wait);
    }
    _lastGeocodeRequest = DateTime.now();
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'limit': '1',
      'countrycodes': 'co',
    });
    final headers = {'Accept-Language': 'es-CO,es;q=0.9'};
    if (!kIsWeb) headers['User-Agent'] = 'EcoLogiSmart/1.0';
    final response = await _client
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));
    if (response.statusCode != 200) {
      throw StateError(
        'El geocodificador respondió ${response.statusCode}. Intenta de nuevo más tarde.',
      );
    }
    final results = jsonDecode(response.body) as List<dynamic>;
    if (results.isEmpty) {
      throw StateError(
        'No se ubicó la dirección. Revisa ciudad, departamento y dirección.',
      );
    }
    final row = results.first as Map<String, dynamic>;
    final result = _Coordinates(
      double.parse(row['lat'] as String),
      double.parse(row['lon'] as String),
    );
    _geocodeCache[normalized] = result;
    await preferences.setString(
      cacheKey,
      jsonEncode([result.latitude, result.longitude]),
    );
    return result;
  }
}
