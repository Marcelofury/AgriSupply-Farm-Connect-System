// Example: How to integrate LocationService into profile screens
// Add this after the address field in farmer/buyer profile screens

import '../../services/location_service.dart';

// In your State class, add:
final LocationService _locationService = LocationService();
bool _isDetectingLocation = false;

// Add this button widget after the Address TextField:
Widget _buildLocationDetectionButton() {
  return Padding(
    padding: const EdgeInsets.only(top: 8),
    child: OutlinedButton.icon(
      onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
      icon: _isDetectingLocation
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location, size: 18),
      label: Text(
        _isDetectingLocation ? 'Detecting...' : 'Detect My Location',
        style: const TextStyle(fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.primaryGreen),
        foregroundColor: AppColors.primaryGreen,
      ),
    ),
  );
}

// Add this method:
Future<void> _detectCurrentLocation() async {
  setState(() => _isDetectingLocation = true);

  try {
    // Get current position
    final position = await _locationService.getCurrentPosition();
    
    if (position == null) {
      _showError('Could not detect location');
      return;
    }

    // Get region from coordinates
    final detectedRegion = _locationService.getRegionFromCoordinates(
      position.latitude,
      position.longitude,
    );

    // Update UI
    setState(() {
      _selectedRegion = detectedRegion;
      // Set default district (first in the list)
      _selectedDistrict = _districts[_selectedRegion]!.first;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location detected: $_selectedRegion region'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  } catch (e) {
    if (!mounted) return;
    
    // Handle specific errors
    String errorMessage = 'Failed to detect location';
    
    if (e.toString().contains('denied')) {
      errorMessage = 'Location permission denied. Please enable in settings.';
      
      // Show dialog with option to open settings
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Location Permission'),
          content: const Text(
            'AgriSupply needs location access to automatically detect your region. '
            'Would you like to open settings?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _locationService.openLocationSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );
    } else if (e.toString().contains('disabled')) {
      errorMessage = 'Location services are disabled. Please enable them.';
    }
    
    _showError(errorMessage);
  } finally {
    if (mounted) {
      setState(() => _isDetectingLocation = false);
    }
  }
}

// ============================================
// HOW TO ADD TO YOUR PROFILE SCREEN
// ============================================

/*
1. Add the import at the top of your file:
   import '../../services/location_service.dart';

2. Add these variables to your State class:
   final LocationService _locationService = LocationService();
   bool _isDetectingLocation = false;

3. Add the _buildLocationDetectionButton() method above

4. Add the _detectCurrentLocation() method above

5. Insert the button in your ListView after the address field:
   
   CustomTextField(
     controller: _addressController,
     label: 'Address',
     prefixIcon: Icons.location_on,
     enabled: _isEditing,
   ),
   if (_isEditing) 
     _buildLocationDetectionButton(),  // <-- Add this
   const SizedBox(height: 16),
   // ... rest of your fields

6. Make sure geolocator package is in pubspec.yaml:
   geolocator: ^13.0.2

7. Add permissions to AndroidManifest.xml:
   <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
   <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />

8. Add permissions to iOS Info.plist:
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>AgriSupply needs your location to connect you with nearby farmers</string>
   <key>NSLocationAlwaysUsageDescription</key>
   <string>AgriSupply needs your location to connect you with nearby farmers</string>
*/

// ============================================
// ALTERNATIVE: Add GPS icon to region dropdown
// ============================================

Widget _buildRegionDropdownWithGPS() {
  return Row(
    children: [
      Expanded(
        child: _buildDropdown(
          label: 'Region',
          value: _selectedRegion.isEmpty ? null : _selectedRegion,
          items: _regions,
          enabled: _isEditing,
          onChanged: (value) {
            setState(() {
              _selectedRegion = value ?? '';
              _selectedDistrict = '';
            });
          },
        ),
      ),
      if (_isEditing) ...[
        const SizedBox(width: 8),
        IconButton(
          onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
          icon: _isDetectingLocation
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          tooltip: 'Detect location',
          color: AppColors.primaryGreen,
        ),
      ],
    ],
  );
}
