import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng tirunelveliCoords = LatLng(8.7139, 77.7567);
  static const double defaultZoom = 12.0;

  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  String _pickedAddress = "Tirunelveli, Tamil Nadu";
  Set<Marker> _markers = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _pickedLocation = tirunelveliCoords;
    _determinePosition();
  }

  void _setToDefaultLocation() {
    setState(() {
      _pickedLocation = tirunelveliCoords;
      _pickedAddress = "Tirunelveli, Tamil Nadu";
      _loading = false;
      _markers = {
        Marker(
          markerId: const MarkerId('default_location'),
          position: tirunelveliCoords,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        )
      };
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(tirunelveliCoords, defaultZoom),
      );
    });
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setToDefaultLocation();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _setToDefaultLocation();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _setToDefaultLocation();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _pickedLocation = LatLng(position.latitude, position.longitude);
        _loading = false;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_pickedLocation!, defaultZoom),
      );
      _updateAddressFromLatLng(_pickedLocation!);
    } catch (e) {
      _setToDefaultLocation();
    }
  }

  Future<void> _updateAddressFromLatLng(LatLng position) async {
    try {
      if (position == tirunelveliCoords) {
        setState(() => _pickedAddress = "Tirunelveli, Tamil Nadu");
        return;
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _pickedAddress = [
            place.street,
            place.locality ?? 'Tirunelveli',
            place.administrativeArea ?? 'Tamil Nadu'
          ].where((part) => part != null && part.isNotEmpty).join(", ");
        });
      }
    } catch (e) {
      setState(() => _pickedAddress = "Tirunelveli, Tamil Nadu");
    }
  }

  void _onMapTapped(LatLng position) {
    setState(() {
      _pickedLocation = position;
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        )
      };
    });
    _updateAddressFromLatLng(position);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
        backgroundColor: const Color(0xFF1994DD),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation ?? tirunelveliCoords,
              zoom: defaultZoom,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    _pickedAddress,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _pickedLocation == null
                        ? null
                        : () {
                      Navigator.pop(context, {
                        'location': _pickedLocation,
                        'address': _pickedAddress,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1994DD),
                    ),
                    child: const Text("Confirm Location"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}