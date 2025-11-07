import 'package:flutter/services.dart';
import 'package:xml/xml.dart';
import 'package:latlong2/latlong.dart';

class GPXParser {
  static Future<List<LatLng>> parseRoute() async {
    try {
      // Load uploaded GPX file
      final gpxString =
          await rootBundle.loadString('assets/routes/narmada_parikrama.gpx');
      final document = XmlDocument.parse(gpxString);
      final points = <LatLng>[];

      for (final trkpt in document.findAllElements('trkpt')) {
        final lat = double.tryParse(trkpt.getAttribute('lat') ?? '');
        final lon = double.tryParse(trkpt.getAttribute('lon') ?? '');
        if (lat != null && lon != null) {
          points.add(LatLng(lat, lon));
        }
      }

      if (points.isNotEmpty) return points;
    } catch (e) {
      print("GPX load failed: $e");
    }

    // Fallback hardcoded route
    return _fallbackRoute();
  }

  static List<LatLng> _fallbackRoute() {
    return [
      LatLng(22.6686, 81.7757), // Amarkantak
      LatLng(22.5167, 80.3667), // Mandla
      LatLng(23.1815, 79.9864), // Jabalpur
      LatLng(22.3313, 77.0963), // Harda
      LatLng(22.0536, 76.7453), // Barwaha
      LatLng(22.2497, 76.2738), // Omkareshwar
      LatLng(21.8833, 75.1833), // Khargone
      LatLng(21.6667, 74.5000), // Nandurbar
      LatLng(21.3333, 73.6667), // Bharuch
      LatLng(20.9667, 72.7667), // Mithi Talai
      LatLng(21.5000, 73.3333), // Kevadia
      LatLng(21.8667, 73.5167), // Rajpipla
      LatLng(22.6686, 81.7757), // Back to Amarkantak
    ];
  }
}
