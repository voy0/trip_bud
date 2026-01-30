import 'dart:math';
import 'package:trip_bud/models/trip.dart';

class TripStatistics {
  final double plannedDistance;
  final double actualDistance;
  final Duration plannedDuration;
  final Duration actualDuration;
  final int stepsCount;
  final double elevation;
  final double averagePace;
  final int placesVisited;
  final int totalPlaces;

  TripStatistics({
    required this.plannedDistance,
    required this.actualDistance,
    required this.plannedDuration,
    required this.actualDuration,
    required this.stepsCount,
    required this.elevation,
    required this.averagePace,
    this.placesVisited = 0,
    this.totalPlaces = 0,
  });

  /// Get completion percentage of planned distance
  double get distanceCompletionPercentage => plannedDistance > 0
      ? (actualDistance / plannedDistance * 100).clamp(0, 200)
      : 0;

  /// Get speed comparison (actual vs planned)
  double get speedComparison =>
      plannedDistance > 0 ? actualDistance / plannedDistance : 0;

  /// Check if trip is on schedule
  bool get isOnSchedule {
    if (plannedDuration.inSeconds == 0) return true;
    return actualDuration.inSeconds <= plannedDuration.inSeconds;
  }

  /// Get remaining distance
  double get remainingDistance => max(0, plannedDistance - actualDistance);

  /// Get time remaining
  Duration get timeRemaining {
    final remaining = plannedDuration.inSeconds - actualDuration.inSeconds;
    return Duration(seconds: max(0, remaining));
  }

  /// Places completion percentage
  double get placesCompletionPercentage =>
      totalPlaces > 0 ? (placesVisited / totalPlaces * 100).clamp(0, 100) : 0;
}

class TripStatisticsService {
  /// Calculate trip statistics from location history
  static TripStatistics calculateStats(
    Trip trip,
    List<Map<String, dynamic>> locations,
    int placesVisited,
  ) {
    double actualDistance = 0;

    // Calculate actual distance from location history
    if (locations.length > 1) {
      for (int i = 0; i < locations.length - 1; i++) {
        actualDistance += _haversineDistance(
          locations[i]['latitude'] as double,
          locations[i]['longitude'] as double,
          locations[i + 1]['latitude'] as double,
          locations[i + 1]['longitude'] as double,
        );
      }
    }

    // Calculate actual duration from first and last location
    Duration actualDuration = Duration.zero;
    if (locations.isNotEmpty) {
      final firstTime = locations.first['timestamp'] as DateTime?;
      final lastTime = locations.last['timestamp'] as DateTime?;

      if (firstTime != null && lastTime != null) {
        actualDuration = lastTime.difference(firstTime);
      }
    }

    return TripStatistics(
      plannedDistance: trip.stats.totalDistance,
      actualDistance: actualDistance,
      plannedDuration: trip.endDate.difference(trip.startDate),
      actualDuration: actualDuration,
      stepsCount: _estimateSteps(actualDistance),
      elevation: 0,
      averagePace: actualDuration.inSeconds > 0
          ? actualDistance / (actualDuration.inSeconds / 3600)
          : 0,
      placesVisited: placesVisited,
      totalPlaces: trip.places.length,
    );
  }

  /// Haversine formula for distance calculation
  static double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const R = 6371; // Earth's radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  /// Convert degrees to radians
  static double _toRad(double degree) {
    return degree * pi / 180;
  }

  /// Estimate steps from distance (average step ~0.75m)
  static int _estimateSteps(double distanceKm) {
    const double metersPerStep = 0.75;
    return (distanceKm * 1000 / metersPerStep).toInt();
  }

  /// Format distance for display
  static String formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toStringAsFixed(0)}m';
    }
    return '${km.toStringAsFixed(2)}km';
  }

  /// Format duration for display
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  /// Format pace (km/h)
  static String formatPace(double kmPerHour) {
    return '${kmPerHour.toStringAsFixed(1)}km/h';
  }
}
