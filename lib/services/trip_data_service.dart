import 'package:trip_bud/models/trip.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as fr;

abstract class TripDataService {
  Future<List<Trip>> getUserTrips(String userId);
  Future<Trip?> getTrip(String tripId);
  Future<String> createTrip(Trip trip);
  Future<void> updateTrip(Trip trip);
  Future<void> deleteTrip(String tripId);
  Future<List<TripPhoto>> getTripPhotos(String tripId);
  Future<void> addPhotoToTrip(TripPhoto photo);
}

class MockTripDataService extends TripDataService {
  final Map<String, Trip> _trips = {};
  final Map<String, List<TripPhoto>> _photos = {};
  int _tripCounter = 0;

  @override
  Future<List<Trip>> getUserTrips(String userId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _trips.values.where((trip) => trip.userId == userId).toList();
  }

  @override
  Future<Trip?> getTrip(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _trips[tripId];
  }

  @override
  Future<String> createTrip(Trip trip) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final tripId =
        'trip_${++_tripCounter}_${DateTime.now().millisecondsSinceEpoch}';
    final newTrip = Trip(
      id: tripId,
      userId: trip.userId,
      name: trip.name,
      description: trip.description,
      startDate: trip.startDate,
      endDate: trip.endDate,
      places: trip.places,
      countries: trip.countries,
      schedule: trip.schedule,
      stats: trip.stats,
      isActive: trip.isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _trips[tripId] = newTrip;
    return tripId;
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _trips[trip.id] = trip;
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _trips.remove(tripId);
    _photos.remove(tripId);
  }

  @override
  Future<List<TripPhoto>> getTripPhotos(String tripId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _photos[tripId] ?? [];
  }

  @override
  Future<void> addPhotoToTrip(TripPhoto photo) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!_photos.containsKey(photo.tripId)) {
      _photos[photo.tripId] = [];
    }
    _photos[photo.tripId]!.add(photo);
  }
}

class FirestoreTripDataService extends TripDataService {
  final fr.CollectionReference _tripsRef;

  FirestoreTripDataService()
    : _tripsRef = fr.FirebaseFirestore.instance.collection('trips');

  Map<String, dynamic> _normalizeTimestamps(Map<String, dynamic> map) {
    Map<String, dynamic> out = {};
    map.forEach((key, value) {
      if (value is fr.Timestamp) {
        out[key] = value.toDate();
      } else if (value is Map<String, dynamic>) {
        out[key] = _normalizeTimestamps(value);
      } else if (value is List) {
        out[key] = value.map((e) {
          if (e is fr.Timestamp) return e.toDate();
          if (e is Map<String, dynamic>) return _normalizeTimestamps(e);
          return e;
        }).toList();
      } else {
        out[key] = value;
      }
    });
    return out;
  }

  @override
  Future<List<Trip>> getUserTrips(String userId) async {
    final q = await _tripsRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return q.docs.map((d) {
      final raw = d.data();
      final map = Map<String, dynamic>.from(raw as Map);
      return Trip.fromMap(_normalizeTimestamps(map), d.id);
    }).toList();
  }

  @override
  Future<Trip?> getTrip(String tripId) async {
    final doc = await _tripsRef.doc(tripId).get();
    if (!doc.exists) return null;
    final raw = doc.data();
    final map = Map<String, dynamic>.from(raw as Map);
    return Trip.fromMap(_normalizeTimestamps(map), doc.id);
  }

  @override
  Future<String> createTrip(Trip trip) async {
    final data = Map<String, dynamic>.from(trip.toMap());
    data['createdAt'] = fr.FieldValue.serverTimestamp();
    data['updatedAt'] = fr.FieldValue.serverTimestamp();
    final docRef = await _tripsRef.add(data);
    return docRef.id;
  }

  @override
  Future<void> updateTrip(Trip trip) async {
    final data = Map<String, dynamic>.from(trip.toMap());
    data['updatedAt'] = fr.FieldValue.serverTimestamp();
    await _tripsRef.doc(trip.id).set(data, fr.SetOptions(merge: true));
  }

  @override
  Future<void> deleteTrip(String tripId) async {
    await _tripsRef.doc(tripId).delete();
    // Optionally delete photo subcollection documents; omitted for simplicity.
  }

  @override
  Future<List<TripPhoto>> getTripPhotos(String tripId) async {
    final photosCol = _tripsRef.doc(tripId).collection('photos');
    final snap = await photosCol.get();
    return snap.docs.map((d) {
      final raw = d.data();
      final map = Map<String, dynamic>.from(raw as Map);
      return TripPhoto.fromMap(_normalizeTimestamps(map), d.id);
    }).toList();
  }

  @override
  Future<void> addPhotoToTrip(TripPhoto photo) async {
    final photosCol = _tripsRef.doc(photo.tripId).collection('photos');
    final data = Map<String, dynamic>.from(photo.toMap());
    data['takenAt'] = fr.Timestamp.fromDate(photo.takenAt);
    await photosCol.add(data);
    // Increment photosCount in the trip stats (best-effort, serverTimestamp used for updatedAt)
    await _tripsRef.doc(photo.tripId).set({
      'updatedAt': fr.FieldValue.serverTimestamp(),
    }, fr.SetOptions(merge: true));
  }
}
