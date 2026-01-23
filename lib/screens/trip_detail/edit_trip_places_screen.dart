import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:trip_bud/models/trip.dart';
import 'package:trip_bud/widgets/place_autocomplete.dart';
import 'package:trip_bud/widgets/place_map.dart';
import 'package:trip_bud/l10n/app_localizations.dart';
import 'package:trip_bud/services/trip_data_service.dart';

class EditTripPlacesScreen extends StatefulWidget {
  final Trip trip;

  const EditTripPlacesScreen({super.key, required this.trip});

  @override
  State<EditTripPlacesScreen> createState() => _EditTripPlacesScreenState();
}

class _EditTripPlacesScreenState extends State<EditTripPlacesScreen> {
  late List<Place> _places;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _places = List.from(widget.trip.places);
  }

  void _addPlace(PlaceSelection sel) {
    setState(() {
      _places.add(
        Place(
          id: 'place_${_places.length}',
          name: sel.name,
          country: sel.country,
          latitude: sel.latitude,
          longitude: sel.longitude,
          plannedDate: widget.trip.startDate,
          plannedDuration: const Duration(hours: 2),
        ),
      );
    });
  }

  void _removePlace(int index) {
    setState(() {
      _places.removeAt(index);
    });
  }

  void _movePlace(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final place = _places.removeAt(oldIndex);
      _places.insert(newIndex, place);
    });
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);
    try {
      final tripDataService = context.read<TripDataService>();

      final updatedTrip = Trip(
        id: widget.trip.id,
        userId: widget.trip.userId,
        name: widget.trip.name,
        description: widget.trip.description,
        startDate: widget.trip.startDate,
        endDate: widget.trip.endDate,
        places: _places,
        countries: widget.trip.countries,
        schedule: widget.trip.schedule,
        stats: widget.trip.stats,
        isActive: widget.trip.isActive,
        createdAt: widget.trip.createdAt,
        updatedAt: DateTime.now(),
      );

      await tripDataService.updateTrip(updatedTrip);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).placesUpdatedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${AppLocalizations.of(context).error}$e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).editPlaces),
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
            TextButton(
              onPressed: _places.isEmpty ? null : _saveChanges,
              child: Text(AppLocalizations.of(context).save),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context).addPlaces,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            PlaceAutocomplete(
              hintText: AppLocalizations.of(context).searchPlaceText,
              onPlaceSelected: _addPlace,
            ),
            const SizedBox(height: 24),
            if (_places.isNotEmpty)
              Column(
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
                  const SizedBox(height: 24),
                ],
              ),
            const Text(
              'Places (Tap move icons to reorder)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              onReorder: _movePlace,
              itemCount: _places.length,
              itemBuilder: (context, index) {
                final place = _places[index];
                return Card(
                  key: ValueKey(place.id),
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: const Icon(Icons.drag_handle),
                    ),
                    title: Text(place.name),
                    subtitle: Text(place.country),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removePlace(index),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
