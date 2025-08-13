import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  String _pickedAddress = "Tap on map to select location";
  Set<Marker> _markers = {};

  // 1. Add geocoding function
  Future<void> _updateAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _pickedAddress = [
            place.street,
            place.locality,
            place.administrativeArea
          ].where((part) => part != null && part!.isNotEmpty).join(", ");
        });
      }
    } catch (e) {
      setState(() {
        _pickedAddress = "Could not get address";
      });
    }
  }

  // 2. Proper tap handler
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
    _updateAddressFromLatLng(position); // Get address for the tapped location
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Location"),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(12.9716, 77.5946),
              zoom: 14,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped, // 3. Use proper tap handler
            markers: _markers, // 4. Show markers
            myLocationEnabled: true,
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
                            // Return the selected location
                            Navigator.pop(context, {
                              'location': _pickedLocation,
                              'address': _pickedAddress,
                            });
                          },
                    child: const Text("Confirm Location"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Current location logic here
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
