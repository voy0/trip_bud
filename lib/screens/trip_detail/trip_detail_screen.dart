import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trip_bud/models/trip.dart';
import 'package:trip_bud/services/trip_data_service.dart';

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
          const Text(
            'Description',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(trip.description),
          const SizedBox(height: 24),
          const Text(
            'Places',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              'Map View',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Map integration coming soon!\n${trip.places.length} places to explore',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
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
