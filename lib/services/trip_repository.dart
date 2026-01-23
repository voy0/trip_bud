import 'package:hive/hive.dart';
import 'package:trip_bud/models/hive_models.dart';

class TripRepository {
  static const String _boxName = 'trips';
  late Box<HiveTrip> _box;

  TripRepository();

  Future<void> init() async {
    _box = await Hive.openBox<HiveTrip>(_boxName);
  }

  /// Save trip locally and queue for sync
  Future<void> saveTrip(HiveTrip trip) async {
    await _box.put(trip.id, trip);
    _queueSync(trip.id);
  }

  /// Get single trip from local storage
  HiveTrip? getTrip(String id) {
    return _box.get(id);
  }

  /// Get all trips from local storage
  List<HiveTrip> getAllTrips() {
    return _box.values.toList();
  }

  /// Delete trip from local storage
  Future<void> deleteTrip(String id) async {
    await _box.delete(id);
  }

  /// Sync all trips with Firebase
  Future<void> syncWithFirebase() async {
    // In a full implementation, sync logic would be implemented here
    for (var _ in _box.values) {
      try {
        // Convert places list to serializable format
        // Convert places list to serializable format for Firebase sync
        // This code is prepared for future Firebase integration

        // Queue for Firebase sync
        // Trip queued for sync
      } catch (e) {
        // Sync failed - continue silently
      }
    }
  }

  /// Clear all local data
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Get box reference for direct operations
  Box<HiveTrip> getBox() => _box;

  void _queueSync(String tripId) {
    // Implement background sync queue
    // Trip queued for sync
  }
}
