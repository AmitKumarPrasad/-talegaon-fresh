import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// Detects the customer's current city/area using device GPS.
/// Returns null if permission is denied, location services are off, or lookup fails.
Future<String?> detectCurrentLocationLabel() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
    );

    final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    if (placemarks.isEmpty) return null;

    final place = placemarks.first;
    final area = place.subLocality?.isNotEmpty == true ? place.subLocality : place.locality;
    final city = place.locality?.isNotEmpty == true ? place.locality : place.administrativeArea;
    if (area != null && city != null && area != city) return '$area, $city';
    return city ?? area;
  } catch (_) {
    return null;
  }
}
