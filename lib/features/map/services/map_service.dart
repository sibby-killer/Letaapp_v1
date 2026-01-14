import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/config/app_config.dart';

class MapService {
  // Get current location
  Future<LatLng> getCurrentLocation() async {
    // Check if location services are enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled');
    }

    // Check location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    // Get current position
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return LatLng(position.latitude, position.longitude);
  }

  // Calculate distance between two points (in kilometers)
  double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
      point1.latitude,
      point1.longitude,
      point2.latitude,
      point2.longitude,
    ) / 1000; // Convert to kilometers
  }

  // Get route using OSRM
  Future<Map<String, dynamic>> getRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    try {
      final url = '${AppConfig.osrmBaseUrl}/route/v1/driving/'
          '${origin.longitude},${origin.latitude};'
          '${destination.longitude},${destination.latitude}'
          '?overview=full&geometries=geojson&steps=true';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch route');
      }

      final data = json.decode(response.body);

      if (data['code'] != 'Ok') {
        throw Exception('Route not found');
      }

      final route = data['routes'][0];
      final geometry = route['geometry'];
      final coordinates = geometry['coordinates'] as List;

      // Convert coordinates to LatLng points
      final polylinePoints = coordinates
          .map((coord) => LatLng(
                coord[1] as double,
                coord[0] as double,
              ))
          .toList();

      return {
        'polyline': polylinePoints,
        'distance': route['distance'] / 1000, // Convert to km
        'duration': route['duration'] / 60, // Convert to minutes
      };
    } catch (e) {
      throw Exception('Failed to get route: ${e.toString()}');
    }
  }

  // Calculate delivery fee based on distance
  double calculateDeliveryFee(double distanceInKm) {
    // Base fee: $2.00
    // Per km: $0.50
    const baseFee = 2.0;
    const perKmFee = 0.5;

    return baseFee + (distanceInKm * perKmFee);
  }

  // Find nearest rider using geospatial query
  Future<String?> findNearestRider({
    required LatLng storeLocation,
    required double maxDistanceKm,
  }) async {
    // This would typically query Supabase with PostGIS extension
    // For now, returning a placeholder
    // In production, you would use:
    // SELECT id FROM users 
    // WHERE role = 'rider' 
    // AND ST_DWithin(location, ST_SetSRID(ST_MakePoint(lng, lat), 4326), maxDistance)
    // ORDER BY location <-> ST_SetSRID(ST_MakePoint(lng, lat), 4326)
    // LIMIT 1
    
    return null; // Implement with actual Supabase query
  }

  // Stream location updates
  Stream<LatLng> getLocationStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).map((position) => LatLng(position.latitude, position.longitude));
  }
}
