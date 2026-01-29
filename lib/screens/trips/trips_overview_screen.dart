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
                onRefresh: () {
                  setState(() {
                    _loadTrips();
                  });
                },
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
  final VoidCallback onRefresh;

  const TripCard({
    super.key,
    required this.trip,
    required this.onTap,
    required this.onRefresh,
  });

  String _getTripStatus(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final loc = AppLocalizations.of(context);

    // Check for ended trips (manually ended with isActive=false and after being started)
    if (!trip.isActive && !trip.isPaused && now.isAfter(trip.startDate)) {
      return 'Ended';
    }

    if (trip.isActive && trip.isPaused) {
      return 'Paused';
    } else if (trip.isActive) {
      return loc.active;
    } else if (today.isAtSameMomentAs(startDay)) {
      return 'Today';
    } else if (today.isBefore(startDay)) {
      final daysUntil = startDay.difference(today).inDays;
      return 'Upcoming in $daysUntil ${daysUntil == 1 ? 'day' : 'days'}';
    }
    return loc.planned;
  }

  Color _getStatusColor() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );

    // Ended
    if (!trip.isActive && !trip.isPaused && now.isAfter(trip.startDate)) {
      return Colors.grey[300]!;
    }

    if (trip.isActive && trip.isPaused) {
      return Colors.orange[100]!;
    } else if (trip.isActive) {
      return Colors.green[100]!;
    } else if (today.isAtSameMomentAs(startDay)) {
      return Colors.purple[100]!;
    } else if (today.isBefore(startDay)) {
      return Colors.blue[100]!;
    }
    return Colors.grey[100]!;
  }

  Color _getStatusTextColor() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );

    // Ended
    if (!trip.isActive && !trip.isPaused && now.isAfter(trip.startDate)) {
      return Colors.grey[700]!;
    }

    if (trip.isActive && trip.isPaused) {
      return Colors.orange[700]!;
    } else if (trip.isActive) {
      return Colors.green[700]!;
    } else if (today.isAtSameMomentAs(startDay)) {
      return Colors.purple[700]!;
    } else if (today.isBefore(startDay)) {
      return Colors.blue[700]!;
    }
    return Colors.grey[700]!;
  }

  Future<void> _startTrip(BuildContext context) async {
    try {
      final tripDataService = context.read<TripDataService>();
      final updatedTrip = Trip(
        id: trip.id,
        userId: trip.userId,
        name: trip.name,
        description: trip.description,
        startDate: trip.startDate,
        endDate: trip.endDate,
        places: trip.places,
        countries: trip.countries,
        schedule: trip.schedule,
        stats: trip.stats,
        isActive: true,
        isPaused: false,
        createdAt: trip.createdAt,
        updatedAt: DateTime.now(),
      );
      await tripDataService.updateTrip(updatedTrip);
      if (context.mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (c) => ActiveTripScreen(trip: updatedTrip),
          ),
        );
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting trip: $e')));
      }
    }
  }

  Widget _buildActionButton(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDay = DateTime(
      trip.startDate.year,
      trip.startDate.month,
      trip.startDate.day,
    );
    final endDay = DateTime(
      trip.endDate.year,
      trip.endDate.month,
      trip.endDate.day,
    );

    // Ended state - can resume if before end date
    if (!trip.isActive && !trip.isPaused && now.isAfter(trip.startDate)) {
      if (today.isBefore(endDay) || today.isAtSameMomentAs(endDay)) {
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _startTrip(context),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(50, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: Colors.blue,
            ),
            child: const Text(
              'Resume',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
              style: TextStyle(fontSize: 11, color: Colors.white),
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    // Paused state
    if (trip.isPaused) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _startTrip(context),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(50, 28),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.orange,
          ),
          child: const Text(
            'Resume',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
      );
    }

    // Active state - View Active Trip button
    if (trip.isActive && !trip.isPaused) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(builder: (c) => ActiveTripScreen(trip: trip)),
            );
            onRefresh();
          },
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(50, 28),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.green,
          ),
          child: const Text(
            'View Trip',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
      );
    }

    // Today - Start Now button
    if (today.isAtSameMomentAs(startDay)) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _startTrip(context),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(50, 28),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: Colors.purple,
          ),
          child: const Text(
            'Start Now',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
      );
    }

    // Upcoming - Start Early button
    if (today.isBefore(startDay) &&
        (today.isBefore(endDay) || today.isAtSameMomentAs(endDay))) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () => _startTrip(context),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(50, 28),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: const Color.fromARGB(255, 0, 200, 120),
          ),
          child: const Text(
            'Start Early',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(fontSize: 11, color: Colors.white),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
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
          constraints: const BoxConstraints(maxWidth: 100),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _getStatusColor(),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  _getTripStatus(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    color: _getStatusTextColor(),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              _buildActionButton(context),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
