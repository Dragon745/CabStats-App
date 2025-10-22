import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // Check if location services are enabled
  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services in your device settings.');
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please grant location permission to use this feature.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable location permissions in app settings.');
      }

      // Get current position with increased timeout and better error handling
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 30),
        forceAndroidLocationManager: false,
      );
      
      return position;
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('timeout')) {
        throw Exception('Location request timed out. Please check your GPS signal and try again.');
      } else if (e.toString().contains('permission')) {
        throw Exception('Location permission is required. Please grant permission and try again.');
      } else if (e.toString().contains('disabled')) {
        throw Exception('Location services are disabled. Please enable location services.');
      } else {
        throw Exception('Failed to get location: ${e.toString()}');
      }
    }
  }

  // Get locality name from coordinates
  Future<String?> getLocalityFromPosition(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Geocoding request timed out');
        },
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        // Priority: street > subLocality > locality > subAdministrativeArea > administrativeArea
        // Go from most specific (street) to most general (administrative area)
        String locality = place.thoroughfare ?? 
                         place.subLocality ?? 
                         place.locality ?? 
                         place.subAdministrativeArea ??
                         place.administrativeArea ?? 
                         'Unknown Location';
        
        // If locality is still empty or null, use coordinates as fallback
        if (locality.isEmpty || locality == 'Unknown Location') {
          locality = 'Location ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
        }
        
        return locality;
      } else {
        return 'Unknown Location';
      }
    } catch (e) {
      // Return a fallback location instead of null
      return 'Location ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}';
    }
  }

  // Get current locality name
  Future<String?> getCurrentLocality() async {
    try {
      Position? position = await getCurrentPosition();
      if (position != null) {
        final locality = await getLocalityFromPosition(position);
        return locality;
      } else {
        return null;
      }
    } catch (e) {
      // Re-throw the exception to let the calling code handle it
      rethrow;
    }
  }

  // Get detailed location info for debugging
  Future<Map<String, String?>> getDetailedLocationInfo() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) {
        return {
          'locality': null,
          'latitude': null,
          'longitude': null,
          'error': 'Unable to get location'
        };
      }

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        
        return {
          'locality': place.locality,
          'subLocality': place.subLocality,
          'subAdministrativeArea': place.subAdministrativeArea,
          'administrativeArea': place.administrativeArea,
          'thoroughfare': place.thoroughfare,
          'name': place.name,
          'latitude': position.latitude.toStringAsFixed(6),
          'longitude': position.longitude.toStringAsFixed(6),
          'error': null,
        };
      }
    } catch (e) {
      return {
        'locality': null,
        'subLocality': null,
        'subAdministrativeArea': null,
        'administrativeArea': null,
        'thoroughfare': null,
        'name': null,
        'latitude': null,
        'longitude': null,
        'error': e.toString(),
      };
    }
    return {
      'locality': null,
      'subLocality': null,
      'subAdministrativeArea': null,
      'administrativeArea': null,
      'thoroughfare': null,
      'name': null,
      'latitude': null,
      'longitude': null,
      'error': 'No location data available',
    };
  }

  // Get formatted location info
  Future<Map<String, String?>> getLocationInfo() async {
    try {
      Position? position = await getCurrentPosition();
      if (position == null) {
        return {
          'locality': null,
          'latitude': null,
          'longitude': null,
          'error': 'Unable to get location'
        };
      }

      String? locality = await getLocalityFromPosition(position);
      
      return {
        'locality': locality,
        'latitude': position.latitude.toStringAsFixed(6),
        'longitude': position.longitude.toStringAsFixed(6),
        'error': null,
      };
    } catch (e) {
      return {
        'locality': null,
        'latitude': null,
        'longitude': null,
        'error': e.toString(),
      };
    }
  }

  // Check if we have location permission
  Future<bool> hasLocationPermission() async {
    LocationPermission permission = await checkPermission();
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Request location permission with user-friendly messages
  Future<bool> requestLocationPermissionWithMessage() async {
    LocationPermission permission = await checkPermission();
    
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
    }
    
    return permission == LocationPermission.always || 
           permission == LocationPermission.whileInUse;
  }

  // Check if location is ready for use (permissions + services)
  Future<Map<String, dynamic>> checkLocationReadiness() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await isLocationEnabled();
      if (!serviceEnabled) {
        return {
          'ready': false,
          'error': 'Location services are disabled',
          'message': 'Please enable location services in your device settings to use this feature.',
          'action': 'enable_location_services'
        };
      }

      // Check permissions
      LocationPermission permission = await checkPermission();
      if (permission == LocationPermission.denied) {
        return {
          'ready': false,
          'error': 'Location permission denied',
          'message': 'Location permission is required to start rides. Please grant permission when prompted.',
          'action': 'request_permission'
        };
      }

      if (permission == LocationPermission.deniedForever) {
        return {
          'ready': false,
          'error': 'Location permission permanently denied',
          'message': 'Location permission has been permanently denied. Please enable it in app settings.',
          'action': 'open_app_settings'
        };
      }

      return {
        'ready': true,
        'error': null,
        'message': 'Location is ready',
        'action': null
      };
    } catch (e) {
      return {
        'ready': false,
        'error': e.toString(),
        'message': 'Unable to check location status. Please try again.',
        'action': 'retry'
      };
    }
  }
}
