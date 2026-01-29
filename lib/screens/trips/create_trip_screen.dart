import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trip_bud/l10n/app_localizations.dart';
import 'package:trip_bud/models/trip.dart';
import 'package:trip_bud/widgets/place_autocomplete.dart';
import 'package:trip_bud/widgets/place_map.dart';
import 'package:trip_bud/widgets/date_range_picker.dart';
import 'package:trip_bud/services/auth_service.dart';
import 'package:trip_bud/services/trip_data_service.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  int _currentStep = 0;
  late PageController _pageController;

  // Step 1: Trip Info
  final _tripNameController = TextEditingController();
  final _tripDescriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  // Step 2: Places
  final List<Place> _places = [];
  final _placeNameController = TextEditingController();
  final _placeCountryController = TextEditingController();
  final _placeLatController = TextEditingController();
  final _placeLonController = TextEditingController();
  PlaceSelection? _currentSelection;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tripNameController.dispose();
    _tripDescriptionController.dispose();
    _placeNameController.dispose();
    _placeCountryController.dispose();
    _placeLatController.dispose();
    _placeLonController.dispose();
    super.dispose();
  }

  void _selectDateRange() async {
    showDialog(
      context: context,
      builder: (context) => DateRangePicker(
        initialStart: _startDate,
        initialEnd: _endDate,
        onDateRangeSelected: (start, end) {
          setState(() {
            _startDate = start;
            _endDate = end;
          });
        },
      ),
    );
  }

  void _addPlace() {
    if (_placeNameController.text.isEmpty ||
        _placeCountryController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseFillAllFields),
        ),
      );
      return;
    }
    // prefer current selection coordinates if available
    final lat =
        _currentSelection?.latitude ??
        double.tryParse(_placeLatController.text) ??
        0.0;
    final lon =
        _currentSelection?.longitude ??
        double.tryParse(_placeLonController.text) ??
        0.0;

    setState(() {
      _places.add(
        Place(
          id: 'place_${_places.length}',
          name: _placeNameController.text,
          country: _placeCountryController.text,
          latitude: lat,
          longitude: lon,
          plannedDate: _startDate ?? DateTime.now(),
          plannedDuration: const Duration(hours: 2),
        ),
      );
      _placeNameController.clear();
      _placeCountryController.clear();
      _placeLatController.clear();
      _placeLonController.clear();
      _currentSelection = null;
    });
  }

  void _removePlace(int index) {
    setState(() => _places.removeAt(index));
  }

  bool _validateStep1() {
    if (_tripNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseEnterTripName),
        ),
      );
      return false;
    }
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).pleaseSelectDates)),
      );
      return false;
    }
    if (_startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).endDateMustBeAfterStart),
        ),
      );
      return false;
    }
    return true;
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep == 1 && _places.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).pleaseAddAtLeastOnePlace),
        ),
      );
      return;
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _createTrip() async {
    final authService = context.read<AuthService>();
    final tripDataService = context.read<TripDataService>();
    final currentUser = authService.getCurrentUser();

    if (currentUser == null) return;

    setState(() => _isLoading = true);

    try {
      // Generate schedule days
      final days = <TripDay>[];
      final dayCount = _endDate!.difference(_startDate!).inDays + 1;

      for (int i = 0; i < dayCount; i++) {
        days.add(
          TripDay(
            dayNumber: i + 1,
            date: _startDate!.add(Duration(days: i)),
            schedule: [],
            distanceCovered: 0,
            stepsTaken: 0,
            photoIds: [],
          ),
        );
      }

      final trip = Trip(
        id: '',
        userId: currentUser.id,
        name: _tripNameController.text,
        description: _tripDescriptionController.text,
        startDate: _startDate!,
        endDate: _endDate!,
        places: _places,
        countries: _places.map((p) => p.country).toSet().toList(),
        schedule: days,
        stats: TripStats(
          totalDistance: 0,
          totalSteps: 0,
          totalDuration: Duration.zero,
          photosCount: 0,
          timeAheadBehind: Duration.zero,
        ),
        isActive: false,
        isPaused: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tripDataService.createTrip(trip);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).tripCreatedSuccessfully),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context).error}${e.toString()}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).createTripTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                for (int i = 0; i < 3; i++)
                  Expanded(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _currentStep >= i
                              ? Theme.of(context).primaryColor
                              : Colors.grey[300],
                          child: Text(
                            '${i + 1}',
                            style: TextStyle(
                              color: _currentStep >= i
                                  ? Colors.white
                                  : Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (i < 2)
                          Container(height: 2, color: Colors.grey[300]),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [_buildStep1(), _buildStep2(), _buildStep3()],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      child: Text(AppLocalizations.of(context).backButton),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_currentStep < 2 ? _nextStep : _createTrip),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentStep < 2 ? 'Next' : 'Create Trip'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Information',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _tripNameController,
            decoration: InputDecoration(
              labelText: 'Trip Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _tripDescriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context).tripDates),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _startDate != null && _endDate != null
                  ? '${_startDate!.month}/${_startDate!.day}/${_startDate!.year} - ${_endDate!.month}/${_endDate!.day}/${_endDate!.year}'
                  : 'Select dates',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Add Places',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // Autocomplete search for places (Google Places)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: PlaceAutocomplete(
              hintText: 'Search place',
              onPlaceSelected: (sel) {
                _currentSelection = sel;
                _placeNameController.text = sel.name;
                _placeCountryController.text = sel.country;
                _placeLatController.text = sel.latitude.toString();
                _placeLonController.text = sel.longitude.toString();
                // Automatically add the place
                _addPlace();
              },
            ),
          ),
          const SizedBox(height: 12),
          // Map showing all added places
          if (_places.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${AppLocalizations.of(context).tripMapTitle} (${_places.length} place(s))',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  PlaceMap(places: _places, height: 280),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context).addedPlaces),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _places.length,
            itemBuilder: (context, index) {
              final place = _places[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  title: Text(place.name),
                  subtitle: Text(
                    '${place.country} (${place.latitude}, ${place.longitude})',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removePlace(index),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Trip Name',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(_tripNameController.text),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Duration',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _startDate != null && _endDate != null
                                  ? '${_startDate!.month}/${_startDate!.day} - ${_endDate!.month}/${_endDate!.day} (${_endDate!.difference(_startDate!).inDays + 1} days)'
                                  : 'Not set',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Places',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${_places.length} places in ${_places.map((p) => p.country).toSet().length} countries',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context).placesYouWillVisit),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _places.length,
            itemBuilder: (context, index) {
              final place = _places[index];
              return ListTile(
                leading: CircleAvatar(child: Text('${index + 1}')),
                title: Text(place.name),
                subtitle: Text(place.country),
              );
            },
          ),
        ],
      ),
    );
  }
}
