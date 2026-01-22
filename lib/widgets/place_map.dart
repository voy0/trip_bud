import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:trip_bud/models/trip.dart';

class PlaceMap extends StatefulWidget {
  final List<Place>? places;
  final LatLng? singleLocation;
  final String? singleLabel;
  final double height;

  const PlaceMap({
    super.key,
    this.places,
    this.singleLocation,
    this.singleLabel,
    this.height = 200,
  });

  @override
  State<PlaceMap> createState() => _PlaceMapState();
}

class _PlaceMapState extends State<PlaceMap> {
  final Completer<GoogleMapController> _controller = Completer();

  static const CameraPosition _kDefault = CameraPosition(
    target: LatLng(20, 0),
    zoom: 2,
  );

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

  @override
  void didUpdateWidget(covariant PlaceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    _moveCameraIfNeeded();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          initialCameraPosition: _kDefault,
          markers: _buildMarkers(),
          onMapCreated: (controller) {
            if (!_controller.isCompleted) _controller.complete(controller);
            _moveCameraIfNeeded();
          },
          myLocationEnabled: false,
          zoomControlsEnabled: true,
        ),
      ),
    );
  }
}
