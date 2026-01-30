import 'package:hive/hive.dart';
import 'package:trip_bud/models/hive_models.dart';

class TripRepository {
  static const String _boxName = 'trips';
  late Box<HiveTrip> _box;

  TripRepository();

  Future<void> init() async {
    _box = await Hive.openBox<HiveTrip>(_boxName);
  }

  /// Save trip locally
  Future<void> saveTrip(HiveTrip trip) async {
    await _box.put(trip.id, trip);
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

  /// Clear all local data
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Get box reference for direct operations
  Box<HiveTrip> getBox() => _box;
}
