import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:trip_bud/models/trip.dart';
import 'package:trip_bud/services/location_tracking_service.dart';
import 'package:trip_bud/services/media_sync_service.dart';
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
  late Stream<Position> _positionStream;
  int _stepCount = 0;
  int _photoCount = 0;
  Duration _timeRemaining = Duration.zero;
  final Color _accentColor = const Color.fromARGB(255, 0, 200, 120);

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _initializeLocationTracking();
    _calculateTimeRemaining();
    _loadPhotoCount();
    // In real app, you would fetch actual step count from pedometer
    _stepCount = 0;
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
    final loc = AppLocalizations.of(context);
    final hasPermission = await _locationService.requestLocationPermission();
    if (!hasPermission && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.locationPermissionRequired)));
    }
  }

  void _initializeLocationTracking() {
    _positionStream = _locationService.getPositionStream();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.trip.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
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
                  // Steps
                  _buildStatRow(
                    icon: Icons.directions_walk,
                    label: loc.steps,
                    value: _stepCount.toString(),
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
      ),
    );
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

  void _showEndTripDialog(AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.endTrip),
        content: Text(loc.confirmEndTrip),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text(loc.confirm),
          ),
        ],
      ),
    );
  }
}
