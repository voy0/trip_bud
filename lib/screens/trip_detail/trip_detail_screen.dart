import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trip_bud/l10n/app_localizations.dart';
import 'package:trip_bud/models/trip.dart';
import 'package:trip_bud/services/trip_data_service.dart';
import 'package:trip_bud/services/distance_time_service.dart';
import 'package:trip_bud/widgets/place_map.dart';
import 'package:trip_bud/widgets/gallery_grid_view.dart';
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
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadTrip() {
    final tripDataService = context.read<TripDataService>();
    setState(() {
      _tripFuture = tripDataService.getTrip(widget.tripId);
    });
  }

  Future<void> _editDescription(Trip trip) async {
    _descriptionController.text = trip.description;
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext).descriptionTitle),
        content: TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: AppLocalizations.of(dialogContext).descriptionTitle,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(dialogContext).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.of(dialogContext).save),
          ),
        ],
      ),
    );

    if (saved != true) return;

    if (!mounted) return;

    try {
      final tripDataService = context.read<TripDataService>();
      final updatedTrip = Trip(
        id: trip.id,
        userId: trip.userId,
        name: trip.name,
        description: _descriptionController.text.trim(),
        startDate: trip.startDate,
        endDate: trip.endDate,
        places: trip.places,
        countries: trip.countries,
        schedule: trip.schedule,
        stats: trip.stats,
        isActive: trip.isActive,
        isPaused: trip.isPaused,
        createdAt: trip.createdAt,
        updatedAt: DateTime.now(),
      );

      await tripDataService.updateTrip(updatedTrip);
      if (mounted) {
        _loadTrip();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context).error}$e')),
      );
    }
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).scheduleTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
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
                label: Text(AppLocalizations.of(context).edit),
              ),
            ],
          ),
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
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).tripDetailsTitle),
            ),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final trip = snapshot.data!;

        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(trip.name),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final tripService = context.read<TripDataService>();
                      final cancelLabel = AppLocalizations.of(context).cancel;
                      final deleteLabel = AppLocalizations.of(context).delete;
                      final navigator = Navigator.of(context);
                      final scaffoldMessenger = ScaffoldMessenger.of(context);
                      final confirmed = await showDialog<bool?>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(deleteLabel),
                            content: const Text(
                              'Are you sure you want to delete this trip?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(cancelLabel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          );
                        },
                      );
                      if (confirmed == true) {
                        try {
                          await tripService.deleteTrip(trip.id);
                          if (mounted) {
                            navigator.pop();
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Trip deleted successfully',
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            scaffoldMessenger.showSnackBar(
                              SnackBar(
                                content: const Text('Error deleting trip'),
                              ),
                            );
                          }
                        }
                      }
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Text(AppLocalizations.of(context).delete),
                    ),
                  ],
                ),
              ],
              bottom: TabBar(
                tabs: [
                  Tab(
                    icon: const Icon(Icons.info),
                    text: AppLocalizations.of(context).overview,
                  ),
                  Tab(
                    icon: const Icon(Icons.map),
                    text: AppLocalizations.of(context).map,
                  ),
                  Tab(
                    icon: const Icon(Icons.image),
                    text: AppLocalizations.of(context).gallery,
                  ),
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
                  Text(
                    AppLocalizations.of(context).tripStats,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    AppLocalizations.of(context).totalDistanceLabel,
                    '${trip.stats.totalDistance.toStringAsFixed(1)} km',
                  ),
                  _buildStatRow(
                    AppLocalizations.of(context).distanceWalked,
                    '${trip.stats.distanceWalked.toStringAsFixed(1)} km',
                  ),
                  _buildStatRow(
                    AppLocalizations.of(context).distanceDriven,
                    '${trip.stats.distanceDriven.toStringAsFixed(1)} km',
                  ),
                  _buildStatRow(
                    AppLocalizations.of(context).distanceBiked,
                    '${trip.stats.distanceBiked.toStringAsFixed(1)} km',
                  ),
                  _buildStatRow(
                    AppLocalizations.of(context).steps,
                    '${trip.stats.totalSteps}',
                  ),
                  _buildStatRow(
                    AppLocalizations.of(context).photos,
                    '${trip.stats.photosCount}',
                  ),
                  _buildStatRow(
                    AppLocalizations.of(context).duration,
                    '${trip.schedule.length} ${AppLocalizations.of(context).days}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildScheduleSummary(trip),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).descriptionTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _editDescription(trip),
                icon: const Icon(Icons.edit, size: 18),
                label: Text(AppLocalizations.of(context).edit),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(trip.description),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).placesTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                label: Text(AppLocalizations.of(context).edit),
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
    return GalleryGridView(
      tripId: trip.id,
      accentColor: const Color.fromARGB(255, 0, 200, 120),
    );
  }
}
