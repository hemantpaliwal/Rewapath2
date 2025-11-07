import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';

class RewaPathProgressService {
  static double dailyTarget = 20.0; // km/day
  static const double totalRouteKm = 2600.0;

  static Future<void> init() async {
    // Preload route for distance calc
  }

  static Future<double> getDailyProgress() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return 0.0;

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final response = await Supabase.instance.client
        .from('locations')
        .select('lat, lng, timestamp')
        .eq('user_id', userId)
        .gte('timestamp', startOfDay.toIso8601String())
        .order('timestamp');

    if (response.isEmpty) return 0.0;

    double distance = 0.0;
    Position? prev;
    for (var loc in response) {
      final pos = Position(
        latitude: loc['lat'],
        longitude: loc['lng'],
        timestamp: DateTime.parse(loc['timestamp']),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      if (prev != null) {
        distance += Geolocator.distanceBetween(
          prev.latitude,
          prev.longitude,
          pos.latitude,
          pos.longitude,
        );
      }
      prev = pos;
    }
    return distance / 1000; // meters → km
  }

  static Future<double> getTotalProgress() async {
    final pos = await Geolocator.getCurrentPosition();
    final start = LatLng(22.6686, 81.7757); // Amarkantak
    final current = LatLng(pos.latitude, pos.longitude);

    const earthRadius = 6371.0;
    final dLat = _toRadians(current.latitude - start.latitude);
    final dLon = _toRadians(current.longitude - start.longitude);
    final a = (dLat / 2).sin() * (dLat / 2).sin() +
        start.latitude.cos() *
            current.latitude.cos() *
            (dLon / 2).sin() *
            (dLon / 2).sin();
    final c = 2 * a.sqrt().atan2((1 - a).sqrt());
    final distanceKm = earthRadius * c;

    return (distanceKm / totalRouteKm).clamp(0.0, 1.0) * 100;
  }

  static double _toRadians(double degree) => degree * (3.14159265359 / 180);

  static Future<void> shareJourney(
      double dailyKm, double totalPct, Position pos) async {
    final day = DateTime.now().day;
    final text = '''
🌊 *RewaPath Yatra Update* 🌊
Day $day | ${dailyKm.toStringAsFixed(1)} km walked today
Total Progress: ${totalPct.toStringAsFixed(1)}% of 2600 km
📍 Location: https://maps.google.com/?q=${pos.latitude},${pos.longitude}
हर हर नर्मदे! 🙏
#RewaPath #NarmadaParikrama
    ''';

    await Share.share(text);
  }
}
