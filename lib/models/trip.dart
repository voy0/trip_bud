class Trip {
  final String id;
  final String userId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime endDate;
  final List<Place> places;
  final List<String> countries;
  final List<TripDay> schedule;
  final TripStats stats;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Trip({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.places,
    required this.countries,
    required this.schedule,
    required this.stats,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Trip.fromMap(Map<String, dynamic> map, String id) {
    return Trip(
      id: id,
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      startDate: map['startDate'] is DateTime
          ? map['startDate']
          : DateTime.parse(map['startDate'].toString()),
      endDate: map['endDate'] is DateTime
          ? map['endDate']
          : DateTime.parse(map['endDate'].toString()),
      places:
          (map['places'] as List?)
              ?.map((p) => Place.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      countries: (map['countries'] as List?)?.cast<String>() ?? [],
      schedule:
          (map['schedule'] as List?)
              ?.map((s) => TripDay.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      stats: TripStats.fromMap(map['stats'] as Map<String, dynamic>? ?? {}),
      isActive: map['isActive'] ?? false,
      createdAt: map['createdAt'] is DateTime
          ? map['createdAt']
          : DateTime.parse(map['createdAt'].toString()),
      updatedAt: map['updatedAt'] is DateTime
          ? map['updatedAt']
          : DateTime.parse(map['updatedAt'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'places': places.map((p) => p.toMap()).toList(),
      'countries': countries,
      'schedule': schedule.map((s) => s.toMap()).toList(),
      'stats': stats.toMap(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Place {
  final String id;
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  final DateTime plannedDate;
  final Duration plannedDuration;

  Place({
    required this.id,
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.plannedDate,
    required this.plannedDuration,
  });

  factory Place.fromMap(Map<String, dynamic> map) {
    return Place(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      plannedDate: map['plannedDate'] is DateTime
          ? map['plannedDate']
          : DateTime.parse(map['plannedDate'].toString()),
      plannedDuration: Duration(minutes: map['plannedDurationMinutes'] ?? 60),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'plannedDate': plannedDate.toIso8601String(),
      'plannedDurationMinutes': plannedDuration.inMinutes,
    };
  }
}

class TripDay {
  final int dayNumber;
  final DateTime date;
  final List<ScheduledPlace> schedule;
  final double distanceCovered;
  final int stepsTaken;
  final List<String> photoIds;

  TripDay({
    required this.dayNumber,
    required this.date,
    required this.schedule,
    required this.distanceCovered,
    required this.stepsTaken,
    required this.photoIds,
  });

  factory TripDay.fromMap(Map<String, dynamic> map) {
    return TripDay(
      dayNumber: map['dayNumber'] ?? 0,
      date: map['date'] is DateTime
          ? map['date']
          : DateTime.parse(map['date'].toString()),
      schedule:
          (map['schedule'] as List?)
              ?.map((s) => ScheduledPlace.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      distanceCovered: (map['distanceCovered'] ?? 0.0).toDouble(),
      stepsTaken: map['stepsTaken'] ?? 0,
      photoIds: (map['photoIds'] as List?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayNumber': dayNumber,
      'date': date.toIso8601String(),
      'schedule': schedule.map((s) => s.toMap()).toList(),
      'distanceCovered': distanceCovered,
      'stepsTaken': stepsTaken,
      'photoIds': photoIds,
    };
  }
}

class ScheduledPlace {
  final String placeId;
  final DateTime scheduledTime;
  final Duration estimatedDuration;
  final bool visited;
  final DateTime? actualArrivalTime;

  ScheduledPlace({
    required this.placeId,
    required this.scheduledTime,
    required this.estimatedDuration,
    required this.visited,
    this.actualArrivalTime,
  });

  factory ScheduledPlace.fromMap(Map<String, dynamic> map) {
    return ScheduledPlace(
      placeId: map['placeId'] ?? '',
      scheduledTime: map['scheduledTime'] is DateTime
          ? map['scheduledTime']
          : DateTime.parse(map['scheduledTime'].toString()),
      estimatedDuration: Duration(
        minutes: map['estimatedDurationMinutes'] ?? 60,
      ),
      visited: map['visited'] ?? false,
      actualArrivalTime: map['actualArrivalTime'] != null
          ? (map['actualArrivalTime'] is DateTime
                ? map['actualArrivalTime']
                : DateTime.parse(map['actualArrivalTime'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'placeId': placeId,
      'scheduledTime': scheduledTime.toIso8601String(),
      'estimatedDurationMinutes': estimatedDuration.inMinutes,
      'visited': visited,
      'actualArrivalTime': actualArrivalTime?.toIso8601String(),
    };
  }
}

class TripStats {
  final double totalDistance;
  final int totalSteps;
  final Duration totalDuration;
  final int photosCount;
  final Duration timeAheadBehind;

  TripStats({
    required this.totalDistance,
    required this.totalSteps,
    required this.totalDuration,
    required this.photosCount,
    required this.timeAheadBehind,
  });

  factory TripStats.fromMap(Map<String, dynamic> map) {
    return TripStats(
      totalDistance: (map['totalDistance'] ?? 0.0).toDouble(),
      totalSteps: map['totalSteps'] ?? 0,
      totalDuration: Duration(minutes: map['totalDurationMinutes'] ?? 0),
      photosCount: map['photosCount'] ?? 0,
      timeAheadBehind: Duration(minutes: map['timeAheadBehindMinutes'] ?? 0),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalDistance': totalDistance,
      'totalSteps': totalSteps,
      'totalDurationMinutes': totalDuration.inMinutes,
      'photosCount': photosCount,
      'timeAheadBehindMinutes': timeAheadBehind.inMinutes,
    };
  }
}

class TripPhoto {
  final String id;
  final String tripId;
  final String filePath;
  final double? latitude;
  final double? longitude;
  final DateTime takenAt;

  TripPhoto({
    required this.id,
    required this.tripId,
    required this.filePath,
    this.latitude,
    this.longitude,
    required this.takenAt,
  });

  factory TripPhoto.fromMap(Map<String, dynamic> map, String id) {
    return TripPhoto(
      id: id,
      tripId: map['tripId'] ?? '',
      filePath: map['filePath'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      takenAt: map['takenAt'] is DateTime
          ? map['takenAt']
          : DateTime.parse(map['takenAt'].toString()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tripId': tripId,
      'filePath': filePath,
      'latitude': latitude,
      'longitude': longitude,
      'takenAt': takenAt.toIso8601String(),
    };
  }
}
