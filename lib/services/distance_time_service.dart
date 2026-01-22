import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:trip_bud/constants/google_api_key.dart';
import 'package:trip_bud/models/trip.dart';

class RouteInfo {
  final double distanceKm;
  final Duration duration;
  final String durationText;

  RouteInfo({
    required this.distanceKm,
    required this.duration,
    required this.durationText,
  });
}

class DistanceTimeService {
  static const String _distanceMatrixUrl =
      'https://maps.googleapis.com/maps/api/distancematrix/json';

  /// Calculate haversine distance between two coordinates (in km)
  static double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Calculate distance and time between two places
  /// mode: 'driving', 'walking', 'bicycling', or 'transit'
  Future<RouteInfo?> getDistanceAndTime(
    Place from,
    Place to, {
    String mode = 'driving',
  }) async {
    if (kGoogleApiKey == 'REPLACE_WITH_YOUR_GOOGLE_API_KEY') {
      return _getFallbackRouteInfo(from, to, mode);
    }

    try {
      final url = Uri.parse(
        '$_distanceMatrixUrl'
        '?origins=${from.latitude},${from.longitude}'
        '&destinations=${to.latitude},${to.longitude}'
        '&mode=$mode'
        '&key=$kGoogleApiKey',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () => http.Response('', 0),
          );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final status = json['status'] as String?;

        if (status == 'OK') {
          final rows = json['rows'] as List?;
          if (rows != null && rows.isNotEmpty) {
            final elements = rows[0]['elements'] as List?;
            if (elements != null && elements.isNotEmpty) {
              final element = elements[0] as Map<String, dynamic>;
              final elementStatus = element['status'] as String?;

              if (elementStatus == 'OK') {
                final distance = element['distance'] as Map<String, dynamic>?;
                final duration = element['duration'] as Map<String, dynamic>?;

                if (distance != null && duration != null) {
                  final distanceMeters =
                      (distance['value'] as num?)?.toInt() ?? 0;
                  final distanceKm = distanceMeters / 1000.0;
                  final durationSeconds =
                      (duration['value'] as num?)?.toInt() ?? 0;
                  final durationText = duration['text'] as String? ?? '';

                  return RouteInfo(
                    distanceKm: distanceKm,
                    duration: Duration(seconds: durationSeconds),
                    durationText: durationText,
                  );
                }
              }
            }
          }
        }
      }
    } catch (e) {
      // Fall back to haversine calculation
    }

    return _getFallbackRouteInfo(from, to, mode);
  }

  /// Fallback distance calculation using haversine formula
  RouteInfo _getFallbackRouteInfo(Place from, Place to, String mode) {
    final distance = _calculateHaversineDistance(
      from.latitude,
      from.longitude,
      to.latitude,
      to.longitude,
    );

    // Estimate travel time based on mode
    final estimatedMinutes = _estimateTravelTime(distance, mode);
    final duration = Duration(minutes: estimatedMinutes);

    // Format duration text
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final durationText = hours > 0
        ? '$hours h $minutes m'
        : '${duration.inMinutes} m';

    return RouteInfo(
      distanceKm: distance,
      duration: duration,
      durationText: durationText,
    );
  }

  /// Estimate travel time based on distance and transportation mode
  int _estimateTravelTime(double distanceKm, String mode) {
    // Average speeds (km/h)
    final speedKmh = switch (mode) {
      'walking' => 5.0,
      'bicycling' => 20.0,
      'transit' => 40.0,
      _ => 80.0, // driving
    };

    final estimatedHours = distanceKm / speedKmh;
    return (estimatedHours * 60).toInt();
  }

  /// Calculate distances between all consecutive places with optional mode
  Future<List<RouteInfo?>> getRouteInfo(
    List<Place> places, {
    List<String>? modes,
  }) async {
    final routes = <RouteInfo?>[];

    for (int i = 0; i < places.length - 1; i++) {
      final mode = modes != null && i < modes.length ? modes[i] : 'driving';
      final routeInfo = await getDistanceAndTime(
        places[i],
        places[i + 1],
        mode: mode,
      );
      routes.add(routeInfo);
    }

    return routes;
  }

  /// Format duration as readable string
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return '$hours h $minutes m';
    }
    return '$minutes m';
  }

  /// Get total trip distance
  static double getTotalDistance(List<RouteInfo?> routes) {
    return routes.fold<double>(
      0.0,
      (total, route) => total + (route?.distanceKm ?? 0),
    );
  }

  /// Get total trip time
  static Duration getTotalTime(List<RouteInfo?> routes) {
    return routes.fold<Duration>(
      Duration.zero,
      (total, route) => total + (route?.duration ?? Duration.zero),
    );
  }
}
