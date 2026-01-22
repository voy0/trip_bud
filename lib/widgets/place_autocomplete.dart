import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:trip_bud/constants/google_api_key.dart';

class PlaceSuggestion {
  final String description;
  final String placeId;
  PlaceSuggestion({required this.description, required this.placeId});
}

class PlaceSelection {
  final String name;
  final String country;
  final double latitude;
  final double longitude;
  PlaceSelection({
    required this.name,
    required this.country,
    required this.latitude,
    required this.longitude,
  });
}

class PlaceAutocomplete extends StatefulWidget {
  final void Function(PlaceSelection) onPlaceSelected;
  final String? hintText;
  final bool showAddButton;

  const PlaceAutocomplete({
    super.key,
    required this.onPlaceSelected,
    this.hintText,
    this.showAddButton = false,
  });

  @override
  State<PlaceAutocomplete> createState() => _PlaceAutocompleteState();
}

class _PlaceAutocompleteState extends State<PlaceAutocomplete> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _loading = false;
  PlaceSelection? _currentSelection;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _fetchSuggestions(value),
    );
  }

  Future<void> _fetchSuggestions(String input) async {
    if (kGoogleApiKey == 'REPLACE_WITH_YOUR_GOOGLE_API_KEY') return;
    setState(() => _loading = true);
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/place/autocomplete/json',
      {
        'input': input,
        'key': kGoogleApiKey,
        'types': 'geocode',
        'language': 'en',
      },
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final status = body['status'] as String?;

        // Check for API errors
        if (status == 'OK' && body['predictions'] is List) {
          final preds = (body['predictions'] as List)
              .map(
                (p) => PlaceSuggestion(
                  description: p['description'] ?? '',
                  placeId: p['place_id'] ?? '',
                ),
              )
              .toList();
          setState(() => _suggestions = preds);
        } else {
          print('Places API Status: $status');
          print('API Response: ${res.body}');
          setState(() => _suggestions = []);
        }
      } else {
        print('HTTP Error: ${res.statusCode} - ${res.body}');
        setState(() => _suggestions = []);
      }
    } catch (e) {
      print('Error fetching suggestions: $e');
      setState(() => _suggestions = []);
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _selectSuggestion(PlaceSuggestion s) async {
    if (kGoogleApiKey == 'REPLACE_WITH_YOUR_GOOGLE_API_KEY') return;
    // Fetch place details to get coordinates and address components
    final url = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': s.placeId,
      'key': kGoogleApiKey,
      'fields':
          'name,geometry,address_component,formatted_address,address_components',
      'language': 'en',
    });

    setState(() {
      _loading = true;
      _suggestions = [];
    });

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final body = json.decode(res.body) as Map<String, dynamic>;
        final result = body['result'] as Map<String, dynamic>?;
        if (result != null) {
          final name = result['name'] as String? ?? s.description;
          String country = '';
          if (result['address_components'] is List) {
            for (final comp in (result['address_components'] as List)) {
              final types = (comp['types'] as List).cast<String>();
              if (types.contains('country')) {
                country = comp['long_name'] as String? ?? '';
                break;
              }
            }
          }

          final geometry = result['geometry'] as Map<String, dynamic>?;
          final location = geometry?['location'] as Map<String, dynamic>?;
          if (location != null) {
            final lat = (location['lat'] as num).toDouble();
            final lng = (location['lng'] as num).toDouble();
            _controller.text = name;

            // Store the selection for later adding
            setState(() {
              _currentSelection = PlaceSelection(
                name: name,
                country: country,
                latitude: lat,
                longitude: lng,
              );
            });

            // Unfocus so keyboard hides and suggestions clear
            _focus.unfocus();
            return;
          }
        }
      }
    } catch (e) {
      print('Error selecting suggestion: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                decoration: InputDecoration(
                  labelText: widget.hintText ?? 'Search place',
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _controller.clear();
                            setState(() => _suggestions = []);
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hintText: widget.hintText ?? 'Type to search...',
                ),
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _loading || _controller.text.isEmpty
                  ? null
                  : () {
                      if (_currentSelection != null) {
                        // If we have a selection, add it directly
                        widget.onPlaceSelected(_currentSelection!);
                        _controller.clear();
                        setState(() => _suggestions = []);
                        _currentSelection = null;
                      } else if (_suggestions.isNotEmpty) {
                        // If suggestions are showing, select the first one
                        _selectSuggestion(_suggestions[0]);
                      } else {
                        // Otherwise fetch suggestions first
                        _fetchSuggestions(_controller.text);
                      }
                    },
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (kGoogleApiKey == 'REPLACE_WITH_YOUR_GOOGLE_API_KEY')
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: const Text(
              '⚠️ API key not configured. Set your Google Maps API key in lib/constants/google_api_key.dart',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          )
        else if (_controller.text.isNotEmpty &&
            _suggestions.isEmpty &&
            !_loading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text(
              'Click Search to find places',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        const SizedBox(height: 8),
        if (_suggestions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _suggestions.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: Colors.grey[200]),
              itemBuilder: (context, index) {
                final s = _suggestions[index];
                return ListTile(
                  leading: const Icon(
                    Icons.location_on,
                    size: 20,
                    color: Colors.grey,
                  ),
                  title: Text(
                    s.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => _selectSuggestion(s),
                );
              },
            ),
          )
        else if (_controller.text.isNotEmpty &&
            _suggestions.isEmpty &&
            !_loading)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: const Center(
              child: Text(
                'No places found. Try a different search.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
          ),
      ],
    );
  }
}
