import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key});

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  GoogleMapController? _controller;
  LatLng? _pickedLocation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// Ask for location permission and move camera to current location
  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _pickedLocation = LatLng(position.latitude, position.longitude);
      _loading = false;
    });

    _controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        15,
      ),
    );
  }

  /// Convert LatLng to human-readable address
  Future<String> _getAddressFromLatLng(LatLng position) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      return "${p.name}, ${p.locality}, ${p.administrativeArea}, ${p.country}";
    }
    return "Unknown Location";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Location"),
        backgroundColor: Colors.deepPurple,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        onMapCreated: (controller) => _controller = controller,
        initialCameraPosition: CameraPosition(
          target: _pickedLocation ?? const LatLng(20.5937, 78.9629),
          zoom: _pickedLocation != null ? 15 : 4,
        ),
        onTap: (LatLng pos) {
          setState(() {
            _pickedLocation = pos;
          });
        },
        markers: _pickedLocation == null
            ? {}
            : {
          Marker(
            markerId: const MarkerId('picked'),
            position: _pickedLocation!,
          ),
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          if (_pickedLocation != null) {
            String address = await _getAddressFromLatLng(_pickedLocation!);
            Navigator.pop(context, address); // Send back to previous page
          }
        },
        label: const Text("Confirm Location"),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
