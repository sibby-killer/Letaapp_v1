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

  // Search for places using Nominatim (OpenStreetMap) - FREE
  Future<List<PlaceSearchResult>> searchPlaces(String query, {LatLng? nearLocation}) async {
    try {
      // Focus search on Kakamega, Kenya area
      final viewbox = nearLocation != null
          ? '${nearLocation.longitude - 0.5},${nearLocation.latitude - 0.5},${nearLocation.longitude + 0.5},${nearLocation.latitude + 0.5}'
          : '34.2,0.0,35.2,0.6'; // Kakamega region bounding box
      
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)},Kenya'
        '&format=json'
        '&addressdetails=1'
        '&limit=10'
        '&viewbox=$viewbox'
        '&bounded=0'
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'LetaApp/1.0 (delivery app for Kakamega)',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Place search failed');
      }

      final List<dynamic> data = json.decode(response.body);
      
      return data.map((place) => PlaceSearchResult.fromNominatim(place)).toList();
    } catch (e) {
      throw Exception('Place search failed: ${e.toString()}');
    }
  }

  // Reverse geocode - get address from coordinates
  Future<PlaceSearchResult> reverseGeocode(LatLng location) async {
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${location.latitude}'
        '&lon=${location.longitude}'
        '&format=json'
        '&addressdetails=1'
      );

      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'LetaApp/1.0 (delivery app for Kakamega)',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Reverse geocoding failed');
      }

      final data = json.decode(response.body);
      return PlaceSearchResult.fromNominatim(data);
    } catch (e) {
      throw Exception('Reverse geocoding failed: ${e.toString()}');
    }
  }

  // Get current location with address
  Future<PlaceSearchResult> getCurrentLocationWithAddress() async {
    final location = await getCurrentLocation();
    return await reverseGeocode(location);
  }
}

// Place search result model
class PlaceSearchResult {
  final String displayName;
  final String? street;
  final String? suburb;
  final String? city;
  final String? county;
  final String? country;
  final double latitude;
  final double longitude;
  final String placeId;

  PlaceSearchResult({
    required this.displayName,
    this.street,
    this.suburb,
    this.city,
    this.county,
    this.country,
    required this.latitude,
    required this.longitude,
    required this.placeId,
  });

  factory PlaceSearchResult.fromNominatim(Map<String, dynamic> json) {
    final address = json['address'] as Map<String, dynamic>? ?? {};
    
    return PlaceSearchResult(
      displayName: json['display_name'] as String? ?? '',
      street: address['road'] as String? ?? address['street'] as String?,
      suburb: address['suburb'] as String? ?? address['neighbourhood'] as String?,
      city: address['city'] as String? ?? address['town'] as String? ?? address['village'] as String?,
      county: address['county'] as String? ?? address['state'] as String?,
      country: address['country'] as String?,
      latitude: double.tryParse(json['lat']?.toString() ?? '0') ?? 0.0,
      longitude: double.tryParse(json['lon']?.toString() ?? '0') ?? 0.0,
      placeId: json['place_id']?.toString() ?? '',
    );
  }

  // Get a short, readable address
  String get shortAddress {
    final parts = <String>[];
    if (street != null) parts.add(street!);
    if (suburb != null) parts.add(suburb!);
    if (city != null) parts.add(city!);
    return parts.isEmpty ? displayName : parts.join(', ');
  }

  // Get full address for display
  String get fullAddress {
    final parts = <String>[];
    if (street != null) parts.add(street!);
    if (suburb != null) parts.add(suburb!);
    if (city != null) parts.add(city!);
    if (county != null) parts.add(county!);
    if (country != null) parts.add(country!);
    return parts.isEmpty ? displayName : parts.join(', ');
  }

  LatLng get latLng => LatLng(latitude, longitude);
}
