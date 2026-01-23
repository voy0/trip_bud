import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trip_bud/models/trip.dart';
import 'package:trip_bud/services/auth_service.dart';
import 'package:trip_bud/services/trip_data_service.dart';
import 'package:trip_bud/screens/trips/active_trip_screen.dart';
import 'package:trip_bud/l10n/app_localizations.dart';

class TripsOverviewScreen extends StatefulWidget {
  final Function(Locale) onLocaleChange;

  const TripsOverviewScreen({super.key, required this.onLocaleChange});

  @override
  State<TripsOverviewScreen> createState() => _TripsOverviewScreenState();
}

class _TripsOverviewScreenState extends State<TripsOverviewScreen> {
  late Future<List<Trip>> _tripsFuture;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    final authService = context.read<AuthService>();
    final tripDataService = context.read<TripDataService>();
    final currentUser = authService.getCurrentUser();

    if (currentUser != null) {
      _tripsFuture = tripDataService.getUserTrips(currentUser.id);
    } else {
      _tripsFuture = Future.value([]);
    }
  }

  void _navigateToCreateTrip() {
    Navigator.of(context).pushNamed('/create-trip').then((_) {
      setState(() {
        _loadTrips();
      });
    });
  }

  void _navigateToTripDetail(Trip trip) {
    Navigator.of(context).pushNamed('/trip-detail', arguments: trip.id).then((
      _,
    ) {
      setState(() {
        _loadTrips();
      });
    });
  }

  void _showSettingsDialog() {
    Navigator.of(context).pushNamed('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final loc = AppLocalizations.of(context);
    authService.getCurrentUser();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.trips),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
          ),
        ],
      ),
      body: FutureBuilder<List<Trip>>(
        future: _tripsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                '${AppLocalizations.of(context).error}${snapshot.error}',
              ),
            );
          }

          final trips = snapshot.data ?? [];

          if (trips.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No trips yet',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first trip to get started',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _navigateToCreateTrip,
                    icon: const Icon(Icons.add),
                    label: Text(loc.createTrip),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];
              return TripCard(
                trip: trip,
                onTap: () => _navigateToTripDetail(trip),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateTrip,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onTap;

  const TripCard({super.key, required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final daysDifference = trip.endDate.difference(trip.startDate).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Text(
          trip.name,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(trip.description),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${trip.startDate.month}/${trip.startDate.day} - ${trip.endDate.month}/${trip.endDate.day} ($daysDifference days)',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${trip.countries.length} countries, ${trip.places.length} places',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: trip.isActive ? Colors.green[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  trip.isActive ? loc.active : loc.planned,
                  style: TextStyle(
                    color: trip.isActive ? Colors.green[700] : Colors.grey[700],
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (!trip.isActive)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (c) => ActiveTripScreen(trip: trip),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(50, 20),
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: const Color.fromARGB(255, 0, 200, 120),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(fontSize: 10, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
