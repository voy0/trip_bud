import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:trip_bud/constants/google_api_key.dart';
import 'package:trip_bud/models/trip.dart';

class PlaceMap extends StatefulWidget {
  final List<Place>? places;
  final LatLng? singleLocation;
  final String? singleLabel;
  final double height;
  final List<String>? transportationModes; // Optional modes for each leg

  const PlaceMap({
    super.key,
    this.places,
    this.singleLocation,
    this.singleLabel,
    this.height = 200,
    this.transportationModes,
  });

  @override
  State<PlaceMap> createState() => _PlaceMapState();
}

class _PlaceMapState extends State<PlaceMap> {
  final Completer<GoogleMapController> _controller = Completer();
  late Future<Set<Polyline>> _polylinesFuture;

  static const CameraPosition _kDefault = CameraPosition(
    target: LatLng(20, 0),
    zoom: 2,
  );

  @override
  void initState() {
    super.initState();
    _polylinesFuture = _buildPolylines();
  }

  @override
  void didUpdateWidget(covariant PlaceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.places != widget.places) {
      _polylinesFuture = _buildPolylines();
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    if (widget.places != null) {
      for (var i = 0; i < widget.places!.length; i++) {
        final p = widget.places![i];
        markers.add(
          Marker(
            markerId: MarkerId(p.id),
            position: LatLng(p.latitude, p.longitude),
            infoWindow: InfoWindow(title: p.name, snippet: p.country),
          ),
        );
      }
    } else if (widget.singleLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('selected'),
          position: widget.singleLocation!,
          infoWindow: InfoWindow(title: widget.singleLabel ?? 'Selected'),
        ),
      );
    }
    return markers;
  }

  Future<void> _moveCameraIfNeeded() async {
    try {
      final controller = await _controller.future;
      if (widget.places != null && widget.places!.isNotEmpty) {
        final first = widget.places!.first;
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(first.latitude, first.longitude),
              zoom: 10,
            ),
          ),
        );
      } else if (widget.singleLocation != null) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: widget.singleLocation!, zoom: 12),
          ),
        );
      }
    } catch (_) {}
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      double latitude = (lat / 1e5).toDouble();
      double longitude = (lng / 1e5).toDouble();
      poly.add(LatLng(latitude, longitude));
    }

    return poly;
  }

  Future<Set<Polyline>> _buildPolylines() async {
    final polylines = <Polyline>{};
    if (widget.places == null || widget.places!.length <= 1) {
      return polylines;
    }

    for (int i = 0; i < widget.places!.length - 1; i++) {
      final from = widget.places![i];
      final to = widget.places![i + 1];
      final mode =
          widget.transportationModes != null &&
              i < widget.transportationModes!.length
          ? widget.transportationModes![i]
          : 'driving';

      try {
        final String url =
            'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${from.latitude},${from.longitude}'
            '&destination=${to.latitude},${to.longitude}'
            '&mode=$mode'
            '&key=$kGoogleApiKey';

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json['routes'].isNotEmpty) {
            final route = json['routes'][0];
            final polylinePoints = route['overview_polyline']['points'];
            final points = _decodePolyline(polylinePoints);

            polylines.add(
              Polyline(
                polylineId: PolylineId('route_$i'),
                points: points,
                color: Colors.blue,
                width: 3,
              ),
            );
            continue;
          }
        }
      } catch (_) {}

      // Fallback to straight line if API fails
      polylines.add(
        Polyline(
          polylineId: PolylineId('route_$i'),
          points: [
            LatLng(from.latitude, from.longitude),
            LatLng(to.latitude, to.longitude),
          ],
          color: Colors.blue,
          width: 3,
          geodesic: true,
        ),
      );
    }

    return polylines;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: FutureBuilder<Set<Polyline>>(
          future: _polylinesFuture,
          builder: (context, snapshot) {
            return GoogleMap(
              initialCameraPosition: _kDefault,
              markers: _buildMarkers(),
              polylines: snapshot.data ?? {},
              onMapCreated: (controller) {
                if (!_controller.isCompleted) _controller.complete(controller);
                _moveCameraIfNeeded();
              },
              myLocationEnabled: false,
              zoomControlsEnabled: true,
            );
          },
        ),
      ),
    );
  }
}
