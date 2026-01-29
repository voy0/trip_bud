import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:trip_bud/models/trip.dart';
import 'package:trip_bud/services/location_tracking_service.dart';
import 'package:trip_bud/services/media_sync_service.dart';
import 'package:trip_bud/services/trip_data_service.dart';
import 'package:trip_bud/services/pedometer_service.dart';
import 'package:trip_bud/services/user_preferences_service.dart';
import 'package:trip_bud/widgets/place_map.dart';
import 'package:trip_bud/l10n/app_localizations.dart';

class ActiveTripScreen extends StatefulWidget {
  final Trip trip;

  const ActiveTripScreen({super.key, required this.trip});

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  final LocationTrackingService _locationService = LocationTrackingService();
  final MediaSyncService _mediaSyncService = MediaSyncService();
  final PedometerService _pedometerService = PedometerService();
  final UserPreferencesService _userPreferences = UserPreferencesService();
  late Stream<Position> _positionStream;
  late Stream<int> _stepCountStream;
  int _newSteps = 0; // Steps in current session (since screen opened)
  int _baseStepCount = 0; // Steps already in the database
  double _distanceWalkedFromSteps = 0.0; // Distance from pedometer
  double _distanceWalkedFromGPS = 0.0; // Distance from GPS when speed < 20 km/h
  double _distanceDriven = 0.0;
  double _distanceBiked = 0.0;
  bool _isBikingMode = false;
  Position? _lastPosition;
  int _photoCount = 0;
  Duration _timeRemaining = Duration.zero;
  final Color _accentColor = const Color.fromARGB(255, 0, 200, 120);
  bool _hasSavedProgress = false;

  @override
  void initState() {
    super.initState();
    // Initialize with existing stats from database
    _baseStepCount = widget.trip.stats.totalSteps;
    _requestLocationPermission();
    _initializeLocationTracking();
    _calculateTimeRemaining();
    _loadPhotoCount();
    _initializePedometer();
    _initUserPreferences();
  }

  Future<void> _initUserPreferences() async {
    await _userPreferences.init();
  }

  Future<void> _initializePedometer() async {
    _stepCountStream = _pedometerService.getStepCountStream();
    _pedometerService.resetStepCounter();
  }

  @override
  void dispose() {
    _saveCurrentProgress();
    _pedometerService.stopListening();
    super.dispose();
  }

  Future<void> _loadPhotoCount() async {
    try {
      final count = await _mediaSyncService.countTripPhotos(widget.trip.id);
      if (mounted) {
        setState(() {
          _photoCount = count;
        });
      }
    } catch (e) {
      // Error loading photo count - continue silently
    }
  }

  Future<void> _requestLocationPermission() async {
    final hasPermission = await _locationService.requestLocationPermission();
    if (!hasPermission && mounted) {
      final loc = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.locationPermissionRequired)));
    }
  }

  void _initializeLocationTracking() {
    _positionStream = _locationService.getPositionStream();
    _positionStream.listen((position) {
      if (_lastPosition != null) {
        final distance = Geolocator.distanceBetween(
          _lastPosition!.latitude,
          _lastPosition!.longitude,
          position.latitude,
          position.longitude,
        );
        final distanceKm = distance / 1000;
        final speedKmh = position.speed * 3.6; // m/s to km/h

        setState(() {
          if (_isBikingMode) {
            // When biking mode is on, count as biked regardless of speed
            _distanceBiked += distanceKm;
          } else if (speedKmh > 20) {
            // Only count as driven when moving faster than 20 km/h
            _distanceDriven += distanceKm;
          } else {
            // When speed < 20 km/h and not biking, count as walked (GPS-based)
            _distanceWalkedFromGPS += distanceKm;
          }
        });
      }
      _lastPosition = position;
    });
  }

  void _calculateTimeRemaining() {
    final now = DateTime.now();
    final tripEnd = widget.trip.endDate;
    final remaining = tripEnd.difference(now);

    setState(() {
      _timeRemaining = remaining.isNegative ? Duration.zero : remaining;
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  String _formatLocation(Position position) {
    return '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return PopScope(
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) {
          await _saveCurrentProgress();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.trip.name),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _saveCurrentProgress();
                if (mounted) navigator.pop();
              },
            ),
          ],
        ),
        body: Column(
          children: [
            // Map view (priority) - split evenly with stats
            Expanded(
              flex: 1,
              child: Stack(
                children: [
                  PlaceMap(places: widget.trip.places, allowInteraction: true),
                  // Current position indicator
                  StreamBuilder<Position>(
                    stream: _positionStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Positioned(
                          bottom: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: _accentColor,
                                  size: 20,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatLocation(snapshot.data!),
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return const Positioned(
                        bottom: 16,
                        right: 16,
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Stats panel
            Expanded(
              flex: 1,
              child: Container(
                color: Colors.grey[100],
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    // Time remaining
                    _buildStatRow(
                      icon: Icons.access_time,
                      label: loc.schedule,
                      value: _formatDuration(_timeRemaining),
                    ),
                    const Divider(),
                    // Steps from pedometer
                    StreamBuilder<int>(
                      stream: _stepCountStream,
                      builder: (context, snapshot) {
                        _newSteps = snapshot.data ?? 0;
                        if (snapshot.hasData) {
                          // Calculate distance walked from NEW steps only
                          final userHeight = _userPreferences.getUserHeight();
                          _distanceWalkedFromSteps = _userPreferences
                              .calculateDistanceFromSteps(
                                _newSteps,
                                userHeight,
                              );
                        }
                        // Display total steps (database + new session steps)
                        final totalSteps = _baseStepCount + _newSteps;
                        return _buildStatRow(
                          icon: Icons.directions_walk,
                          label: loc.steps,
                          value: totalSteps.toString(),
                        );
                      },
                    ),
                    const Divider(),
                    // Distance walked (combining pedometer and GPS-based)
                    _buildStatRow(
                      icon: Icons.directions_walk,
                      label: loc.distanceWalked,
                      value:
                          '${(widget.trip.stats.distanceWalked + _distanceWalkedFromSteps + _distanceWalkedFromGPS).toStringAsFixed(2)} km',
                    ),
                    const Divider(),
                    // Distance driven
                    _buildStatRow(
                      icon: Icons.directions_car,
                      label: loc.distanceDriven,
                      value:
                          '${(widget.trip.stats.distanceDriven + _distanceDriven).toStringAsFixed(2)} km',
                    ),
                    const Divider(),
                    // Distance biked with toggle button
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatRow(
                            icon: Icons.directions_bike,
                            label: loc.distanceBiked,
                            value:
                                '${(widget.trip.stats.distanceBiked + _distanceBiked).toStringAsFixed(2)} km',
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              _isBikingMode = !_isBikingMode;
                            });
                          },
                          icon: Icon(
                            _isBikingMode ? Icons.pause : Icons.play_arrow,
                            color: _isBikingMode ? Colors.red : _accentColor,
                          ),
                          tooltip: _isBikingMode
                              ? 'Stop biking'
                              : 'Start biking',
                        ),
                      ],
                    ),
                    const Divider(),
                    // Total distance
                    _buildStatRow(
                      icon: Icons.route,
                      label: loc.totalDistanceLabel,
                      value:
                          '${(widget.trip.stats.totalDistance + _distanceWalkedFromSteps + _distanceWalkedFromGPS + _distanceDriven + _distanceBiked).toStringAsFixed(2)} km',
                    ),
                    const Divider(),
                    // Photos
                    _buildStatRow(
                      icon: Icons.photo_camera,
                      label: loc.photos,
                      value: _photoCount.toString(),
                    ),
                    const Divider(),
                    // Next destination
                    if (widget.trip.places.isNotEmpty)
                      _buildStatRow(
                        icon: Icons.location_on,
                        label: loc.nextPlace,
                        value: widget.trip.places.first.name,
                      ),
                    const SizedBox(height: 16),
                    // Pause trip button
                    ElevatedButton.icon(
                      onPressed: _pauseTrip,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pause Trip'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // End trip button
                    ElevatedButton.icon(
                      onPressed: () => _showEndTripDialog(loc),
                      icon: const Icon(Icons.stop),
                      label: Text(loc.endTrip),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ), // body: Column
      ), // Scaffold
    ); // PopScope
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: _accentColor, size: 24),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _saveCurrentProgress() async {
    if (!mounted) return;
    if (_hasSavedProgress) return;
    try {
      final tripDataService = context.read<TripDataService>();

      // Update stats with NEW distances and steps from this session
      final totalWalkedDistance =
          _distanceWalkedFromSteps + _distanceWalkedFromGPS;
      final updatedStats = TripStats(
        totalDistance:
            widget.trip.stats.totalDistance +
            totalWalkedDistance +
            _distanceDriven +
            _distanceBiked,
        distanceWalked: widget.trip.stats.distanceWalked + totalWalkedDistance,
        distanceDriven: widget.trip.stats.distanceDriven + _distanceDriven,
        distanceBiked: widget.trip.stats.distanceBiked + _distanceBiked,
        totalSteps: widget.trip.stats.totalSteps + _newSteps,
        totalDuration: widget.trip.stats.totalDuration,
        photosCount: widget.trip.stats.photosCount,
        timeAheadBehind: widget.trip.stats.timeAheadBehind,
      );

      final updatedTrip = Trip(
        id: widget.trip.id,
        userId: widget.trip.userId,
        name: widget.trip.name,
        description: widget.trip.description,
        startDate: widget.trip.startDate,
        endDate: widget.trip.endDate,
        places: widget.trip.places,
        countries: widget.trip.countries,
        schedule: widget.trip.schedule,
        stats: updatedStats,
        isActive: widget.trip.isActive,
        isPaused: widget.trip.isPaused,
        createdAt: widget.trip.createdAt,
        updatedAt: DateTime.now(),
      );
      await tripDataService.updateTrip(updatedTrip);
      _hasSavedProgress = true;
    } catch (e) {
      // Silently fail to avoid blocking navigation
    }
  }

  Future<void> _pauseTrip() async {
    if (!mounted) return;
    try {
      final tripDataService = context.read<TripDataService>();

      // Update stats with NEW distances and steps from this session
      final totalWalkedDistance =
          _distanceWalkedFromSteps + _distanceWalkedFromGPS;
      final updatedStats = TripStats(
        totalDistance:
            widget.trip.stats.totalDistance +
            totalWalkedDistance +
            _distanceDriven +
            _distanceBiked,
        distanceWalked: widget.trip.stats.distanceWalked + totalWalkedDistance,
        distanceDriven: widget.trip.stats.distanceDriven + _distanceDriven,
        distanceBiked: widget.trip.stats.distanceBiked + _distanceBiked,
        totalSteps: widget.trip.stats.totalSteps + _newSteps,
        totalDuration: widget.trip.stats.totalDuration,
        photosCount: widget.trip.stats.photosCount,
        timeAheadBehind: widget.trip.stats.timeAheadBehind,
      );

      final updatedTrip = Trip(
        id: widget.trip.id,
        userId: widget.trip.userId,
        name: widget.trip.name,
        description: widget.trip.description,
        startDate: widget.trip.startDate,
        endDate: widget.trip.endDate,
        places: widget.trip.places,
        countries: widget.trip.countries,
        schedule: widget.trip.schedule,
        stats: updatedStats,
        isActive: true,
        isPaused: true,
        createdAt: widget.trip.createdAt,
        updatedAt: DateTime.now(),
      );
      await tripDataService.updateTrip(updatedTrip);
      _hasSavedProgress = true;
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error pausing trip: $e')));
    }
  }

  void _showEndTripDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(loc.endTrip),
        content: Text(loc.confirmEndTrip),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (!mounted) return;
              try {
                final tripDataService = context.read<TripDataService>();

                // Update stats with NEW steps and distance from this session
                final totalWalkedDistance =
                    _distanceWalkedFromSteps + _distanceWalkedFromGPS;
                final updatedStats = TripStats(
                  totalDistance:
                      widget.trip.stats.totalDistance +
                      totalWalkedDistance +
                      _distanceDriven +
                      _distanceBiked,
                  distanceWalked:
                      widget.trip.stats.distanceWalked + totalWalkedDistance,
                  distanceDriven:
                      widget.trip.stats.distanceDriven + _distanceDriven,
                  distanceBiked:
                      widget.trip.stats.distanceBiked + _distanceBiked,
                  totalSteps: widget.trip.stats.totalSteps + _newSteps,
                  totalDuration: widget.trip.stats.totalDuration,
                  photosCount: widget.trip.stats.photosCount,
                  timeAheadBehind: widget.trip.stats.timeAheadBehind,
                );

                final updatedTrip = Trip(
                  id: widget.trip.id,
                  userId: widget.trip.userId,
                  name: widget.trip.name,
                  description: widget.trip.description,
                  startDate: widget.trip.startDate,
                  endDate: widget.trip.endDate,
                  places: widget.trip.places,
                  countries: widget.trip.countries,
                  schedule: widget.trip.schedule,
                  stats: updatedStats,
                  isActive: false,
                  isPaused: false,
                  createdAt: widget.trip.createdAt,
                  updatedAt: DateTime.now(),
                );
                await tripDataService.updateTrip(updatedTrip);
                _hasSavedProgress = true;
                if (mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error ending trip: $e')),
                );
              }
            },
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
  }
}
