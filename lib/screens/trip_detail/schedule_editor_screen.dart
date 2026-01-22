import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trip_bud/models/trip.dart';
import 'package:trip_bud/services/trip_data_service.dart';
import 'package:trip_bud/services/distance_time_service.dart';

class ScheduleEditorScreen extends StatefulWidget {
  final Trip trip;

  const ScheduleEditorScreen({super.key, required this.trip});

  @override
  State<ScheduleEditorScreen> createState() => _ScheduleEditorScreenState();
}

class _ScheduleEditorScreenState extends State<ScheduleEditorScreen> {
  late List<int> _daysPerPlace;
  late List<RouteInfo?> _routes;
  late DateTime _startDate;
  late DateTime _endDate;
  late List<String> _transportationModes; // 'walking', 'bicycling', 'driving'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _daysPerPlace = List.filled(widget.trip.places.length, 1);
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
    _transportationModes = _extractExistingModes();
    _loadRouteInfo();
  }

  List<String> _extractExistingModes() {
    final modes = List.filled(widget.trip.places.length - 1, 'driving');

    // Try to load existing modes from schedule
    if (widget.trip.schedule.isNotEmpty) {
      final modesMap = <int, String>{};

      for (final day in widget.trip.schedule) {
        for (final scheduled in day.schedule) {
          final placeIndex = widget.trip.places.indexWhere(
            (p) => p.id == scheduled.placeId,
          );
          if (placeIndex >= 0 && placeIndex < widget.trip.places.length - 1) {
            modesMap.putIfAbsent(
              placeIndex,
              () => scheduled.transportationMode,
            );
          }
        }
      }

      for (int i = 0; i < modes.length; i++) {
        modes[i] = modesMap[i] ?? 'driving';
      }
    }

    return modes;
  }

  int get _totalDaysInTrip {
    return _endDate.difference(_startDate).inDays + 1;
  }

  int get _totalDaysAssigned {
    return _daysPerPlace.fold<int>(0, (sum, days) => sum + days);
  }

  bool get _canAddMoreDays {
    return _totalDaysAssigned < _totalDaysInTrip;
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _loadRouteInfo() async {
    final service = DistanceTimeService();
    final routes = await service.getRouteInfo(
      widget.trip.places,
      modes: _transportationModes,
    );
    setState(() {
      _routes = routes;
      _isLoading = false;
    });
  }

  Future<void> _saveSchedule() async {
    setState(() => _isLoading = true);
    try {
      final tripDataService = context.read<TripDataService>();

      // Create schedule based on days per place and trip start date
      final schedule = <TripDay>[];
      var currentDate = _startDate;
      var dayNumber = 1;

      for (int i = 0; i < widget.trip.places.length; i++) {
        final daysCount = _daysPerPlace[i];
        for (int d = 0; d < daysCount; d++) {
          final mode = i < _transportationModes.length
              ? _transportationModes[i]
              : 'driving';
          schedule.add(
            TripDay(
              dayNumber: dayNumber,
              date: currentDate,
              schedule: [
                ScheduledPlace(
                  placeId: widget.trip.places[i].id,
                  scheduledTime: currentDate,
                  estimatedDuration: const Duration(hours: 2),
                  visited: false,
                  transportationMode: mode,
                ),
              ],
              distanceCovered: 0.0,
              stepsTaken: 0,
              photoIds: [],
            ),
          );
          currentDate = currentDate.add(const Duration(days: 1));
          dayNumber++;
        }
      }

      final updatedTrip = Trip(
        id: widget.trip.id,
        userId: widget.trip.userId,
        name: widget.trip.name,
        description: widget.trip.description,
        startDate: _startDate,
        endDate: _endDate,
        places: widget.trip.places,
        countries: widget.trip.countries,
        schedule: schedule,
        stats: widget.trip.stats,
        isActive: widget.trip.isActive,
        createdAt: widget.trip.createdAt,
        updatedAt: DateTime.now(),
      );

      await tripDataService.updateTrip(updatedTrip);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Schedule updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Editor'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(onPressed: _saveSchedule, child: const Text('Save')),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range selector
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trip Dates',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _selectStartDate(context),
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(
                                    '${_startDate.month}/${_startDate.day}/${_startDate.year}',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Text('-'),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => _selectEndDate(context),
                                  icon: const Icon(Icons.calendar_today),
                                  label: Text(
                                    '${_endDate.month}/${_endDate.day}/${_endDate.year}',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Total trip days: $_totalDaysInTrip',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Assign Days to Places',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set how many days you want to spend at each place',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: widget.trip.places.length,
                    itemBuilder: (context, index) {
                      final place = widget.trip.places[index];
                      final hasNextPlace =
                          index < widget.trip.places.length - 1;
                      final route = hasNextPlace ? _routes[index] : null;

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Place header
                              Row(
                                children: [
                                  CircleAvatar(child: Text('${index + 1}')),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          place.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          place.country,
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
                              const SizedBox(height: 16),

                              // Days selector
                              Row(
                                children: [
                                  const Text(
                                    'Days here:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  IconButton(
                                    icon: const Icon(Icons.remove),
                                    onPressed: _daysPerPlace[index] > 1
                                        ? () {
                                            setState(() {
                                              _daysPerPlace[index]--;
                                            });
                                          }
                                        : null,
                                  ),
                                  Container(
                                    width: 60,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '${_daysPerPlace[index]}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add),
                                    onPressed: _canAddMoreDays
                                        ? () {
                                            setState(() {
                                              _daysPerPlace[index]++;
                                            });
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                              if (_totalDaysAssigned >= _totalDaysInTrip)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Maximum days reached (${_totalDaysAssigned}/$_totalDaysInTrip)',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),

                              // Transportation mode selector (for leg to next place)
                              if (hasNextPlace) ...[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Travel to next place:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.directions_walk,
                                            ),
                                            label: const Text('Walk'),
                                            onPressed:
                                                _transportationModes[index] !=
                                                    'walking'
                                                ? () async {
                                                    setState(() {
                                                      _transportationModes[index] =
                                                          'walking';
                                                      _isLoading = true;
                                                    });
                                                    await _loadRouteInfo();
                                                  }
                                                : null,
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  _transportationModes[index] ==
                                                      'walking'
                                                  ? Colors.blue[50]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(Icons.pedal_bike),
                                            label: const Text('Bike'),
                                            onPressed:
                                                _transportationModes[index] !=
                                                    'bicycling'
                                                ? () async {
                                                    setState(() {
                                                      _transportationModes[index] =
                                                          'bicycling';
                                                      _isLoading = true;
                                                    });
                                                    await _loadRouteInfo();
                                                  }
                                                : null,
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  _transportationModes[index] ==
                                                      'bicycling'
                                                  ? Colors.blue[50]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            icon: const Icon(
                                              Icons.directions_car,
                                            ),
                                            label: const Text('Drive'),
                                            onPressed:
                                                _transportationModes[index] !=
                                                    'driving'
                                                ? () async {
                                                    setState(() {
                                                      _transportationModes[index] =
                                                          'driving';
                                                      _isLoading = true;
                                                    });
                                                    await _loadRouteInfo();
                                                  }
                                                : null,
                                            style: OutlinedButton.styleFrom(
                                              backgroundColor:
                                                  _transportationModes[index] ==
                                                      'driving'
                                                  ? Colors.blue[50]
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                ),
                              ],

                              // Route info to next place
                              if (hasNextPlace && route != null) ...[
                                Divider(color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.directions,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'To ${widget.trip.places[index + 1].name}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.location_on,
                                                size: 14,
                                                color: Colors.blue[300],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${route.distanceKm.toStringAsFixed(1)} km',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(width: 16),
                                              Icon(
                                                Icons.schedule,
                                                size: 14,
                                                color: Colors.blue[300],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                route.durationText,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ] else if (hasNextPlace && route == null) ...[
                                Divider(color: Colors.grey[300]),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.directions,
                                      size: 20,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'To ${widget.trip.places[index + 1].name}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Trip summary
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Trip Summary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Days:'),
                              Text(
                                '${_daysPerPlace.fold<int>(0, (sum, days) => sum + days)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total Distance:'),
                              Text(
                                '${DistanceTimeService.getTotalDistance(_routes).toStringAsFixed(1)} km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Travel Time:'),
                              Text(
                                DistanceTimeService.formatDuration(
                                  DistanceTimeService.getTotalTime(_routes),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}
