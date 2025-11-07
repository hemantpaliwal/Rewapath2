import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class RewaPathLocationService {
  static StreamSubscription<Position>? _positionStream;

  static Future<void> startTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25, // Update every 25 meters
      ),
    ).listen((Position position) async {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('locations').upsert({
        'user_id': userId,
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
        'accuracy': position.accuracy,
      });
    });
  }

  static Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
  }

  static Future<void> sendSOS() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final position = await Geolocator.getCurrentPosition();
      await Supabase.instance.client.from('sos_alerts').insert({
        'user_id': userId,
        'lat': position.latitude,
        'lng': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print("SOS failed: $e");
    }
  }
}
