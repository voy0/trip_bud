import 'package:hive_flutter/hive_flutter.dart';

class UserPreferencesService {
  static const String _boxName = 'user_preferences';
  static const String _heightKey = 'user_height_cm';

  late Box<dynamic> _box;

  Future<void> init() async {
    _box = await Hive.openBox(_boxName);
  }

  /// Get user height in centimeters (default: 175cm)
  int getUserHeight() {
    return _box.get(_heightKey, defaultValue: 175) as int;
  }

  /// Set user height in centimeters
  Future<void> setUserHeight(int heightCm) async {
    await _box.put(_heightKey, heightCm);
  }

  /// Calculate stride length based on height
  /// Formula: stride_length (m) = height (cm) * 0.43 / 100
  double calculateStrideLength(int heightCm) {
    return (heightCm * 0.43) / 100;
  }

  /// Calculate distance walked based on steps and user height
  /// Formula: distance (km) = steps * stride_length (m) / 1000
  double calculateDistanceFromSteps(int steps, int heightCm) {
    final strideLengthMeters = calculateStrideLength(heightCm);
    final distanceMeters = steps * strideLengthMeters;
    return distanceMeters / 1000; // Convert to km
  }
}
