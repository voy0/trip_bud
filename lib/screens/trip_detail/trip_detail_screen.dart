import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trip_bud/models/trip.dart';
import 'package:trip_bud/services/trip_data_service.dart';
import 'package:trip_bud/services/distance_time_service.dart';
import 'package:trip_bud/widgets/place_map.dart';
import 'package:trip_bud/screens/trip_detail/edit_trip_places_screen.dart';
import 'package:trip_bud/screens/trip_detail/schedule_editor_screen.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;

  const TripDetailScreen({super.key, required this.tripId});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late Future<Trip?> _tripFuture;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  void _loadTrip() {
    final tripDataService = context.read<TripDataService>();
    _tripFuture = tripDataService.getTrip(widget.tripId);
  }

  Widget _buildScheduleSummary(Trip trip) {
    // Group schedule by place
    final Map<String, int> daysPerPlace = {};
    for (final day in trip.schedule) {
      if (day.schedule.isNotEmpty) {
        final placeId = day.schedule[0].placeId;
        daysPerPlace[placeId] = (daysPerPlace[placeId] ?? 0) + 1;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Schedule Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ScheduleEditorScreen(trip: trip),
                  ),
                );
                if (result == true) {
                  _loadTrip();
                }
              },
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: trip.places.length,
                  separatorBuilder: (_, __) => Divider(color: Colors.grey[300]),
                  itemBuilder: (context, index) {
                    final place = trip.places[index];
                    final daysHere = daysPerPlace[place.id] ?? 0;
                    final hasNextPlace = index < trip.places.length - 1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 18,
                                child: Text('${index + 1}'),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      place.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '$daysHere day${daysHere != 1 ? 's' : ''}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (hasNextPlace)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 30),
                              child: FutureBuilder<RouteInfo?>(
                                future: DistanceTimeService()
                                    .getDistanceAndTime(
                                      place,
                                      trip.places[index + 1],
                                    ),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData &&
                                      snapshot.data != null) {
                                    final route = snapshot.data!;
                                    return Row(
                                      children: [
                                        Icon(
                                          Icons.arrow_downward,
                                          size: 16,
                                          color: Colors.blue[300],
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${route.distanceKm.toStringAsFixed(1)} km • ${route.durationText}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[300],
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Trip?>(
      future: _tripFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Trip Details')),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final trip = snapshot.data!;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(trip.name),
              bottom: const TabBar(
                tabs: [
                  Tab(icon: Icon(Icons.info), text: 'Overview'),
                  Tab(icon: Icon(Icons.map), text: 'Map'),
                  Tab(icon: Icon(Icons.image), text: 'Gallery'),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildOverviewTab(trip),
                _buildMapTab(trip),
                _buildGalleryTab(trip),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab(Trip trip) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Stats',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    'Distance',
                    '${trip.stats.totalDistance.toStringAsFixed(1)} km',
                  ),
                  _buildStatRow('Steps', '${trip.stats.totalSteps}'),
                  _buildStatRow('Photos', '${trip.stats.photosCount}'),
                  _buildStatRow('Duration', '${trip.schedule.length} days'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildScheduleSummary(trip),
          const SizedBox(height: 24),
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(trip.description),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Places',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditTripPlacesScreen(trip: trip),
                    ),
                  );
                  if (result == true) {
                    _loadTrip();
                  }
                },
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Edit'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trip.places.length,
            itemBuilder: (context, index) {
              final place = trip.places[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(place.name),
                  subtitle: Text(place.country),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Daily Schedule',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: trip.schedule.length,
            itemBuilder: (context, index) {
              final day = trip.schedule[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(child: Text('Day ${day.dayNumber}')),
                  title: Text('${day.date.month}/${day.date.day}'),
                  subtitle: Text('${day.photoIds.length} photos'),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMapTab(Trip trip) {
    // Extract transportation modes from schedule if available
    final modes = _extractTransportationModes(trip);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Map View',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          PlaceMap(
            places: trip.places,
            height: 360,
            transportationModes: modes,
          ),
          const SizedBox(height: 12),
          Text('${trip.places.length} places on the map'),
        ],
      ),
    );
  }

  List<String> _extractTransportationModes(Trip trip) {
    final modes = <String>[];

    // If no schedule yet, use defaults
    if (trip.places.length <= 1) return modes;

    // Collect the first occurrence of each transportation mode from schedule
    final modesSet = <int, String>{};

    for (final day in trip.schedule) {
      for (final scheduled in day.schedule) {
        // Find which place this is
        final placeIndex = trip.places.indexWhere(
          (p) => p.id == scheduled.placeId,
        );
        if (placeIndex >= 0 && placeIndex < trip.places.length - 1) {
          modesSet.putIfAbsent(placeIndex, () => scheduled.transportationMode);
        }
      }
    }

    // Build the modes list in order
    for (int i = 0; i < trip.places.length - 1; i++) {
      modes.add(modesSet[i] ?? 'driving');
    }

    return modes;
  }

  Widget _buildGalleryTab(Trip trip) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Trip Gallery',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Photos from your trip will appear here',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
