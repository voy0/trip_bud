import 'package:hive/hive.dart';

part 'hive_models.g.dart';

@HiveType(typeId: 0)
class HiveTrip extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late DateTime startDate;

  @HiveField(4)
  late DateTime endDate;

  @HiveField(5)
  late List<HivePlace> places;

  @HiveField(6)
  late DateTime lastModified;

  @HiveField(7)
  late double totalDistance;

  HiveTrip({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    required this.endDate,
    required this.places,
    required this.lastModified,
    this.totalDistance = 0,
  });
}

@HiveType(typeId: 1)
class HivePlace extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double latitude;

  @HiveField(3)
  late double longitude;

  @HiveField(4)
  late String address;

  @HiveField(5)
  late int orderIndex;

  @HiveField(6)
  late DateTime? scheduledTime;

  @HiveField(7)
  late String transportMode;

  HivePlace({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.orderIndex,
    this.scheduledTime,
    this.transportMode = 'walk',
  });
}
