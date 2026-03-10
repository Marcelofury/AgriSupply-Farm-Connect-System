# Auto-Detect Region from District - Implementation Guide

## Overview
Instead of using GPS to detect a user's region, the system automatically determines the region based on the selected district. This is more reliable for delivery purposes.

---

## Why District-Based Auto-Detection?

### Problems with GPS-Based Region Detection
1. **Temporary Location** - User might be traveling or visiting another region
2. **Delivery Mismatch** - Orders would be routed to current GPS location, not permanent address
3. **Unreliable** - GPS might not work indoors or in certain areas
4. **Privacy** - Some users don't want to share precise location

### Benefits of District-Based Auto-Detection
1. **Intentional** - User explicitly selects their delivery district
2. **Permanent Address** - Orders go to the right location
3. **100% Accurate** - Every district belongs to exactly one region
4. **No Permissions** - No need for location permissions
5. **Offline** - Works without internet or GPS

---

## Implementation

### How It Works

1. **User selects district** from alphabetized dropdown (all 128 districts)
2. **System auto-detects region** from selected district
3. **Region displayed** as read-only with "Auto" badge
4. **Orders routed** to correct region for delivery fee calculation

### Code Example

```dart
// Get region from selected district
String _getRegionFromDistrict(final String district) {
  for (final entry in _districts.entries) {
    if (entry.value.contains(district)) {
      return entry.key;
    }
  }
  return 'Central'; // Default fallback
}

// Get all districts for dropdown
List<String> _getAllDistricts() {
  final allDistricts = <String>[];
  for (final districts in _districts.values) {
    allDistricts.addAll(districts);
  }
  allDistricts.sort(); // Alphabetical order
  return allDistricts;
}

// In dropdown onChange
onChanged: (final value) {
  setState(() {
    _selectedDistrict = value!;
    // Auto-detect and update region
    _selectedRegion = _getRegionFromDistrict(value);
  });
}
```

---

## User Experience

### Profile Editing Flow

1. User taps "Edit" icon in profile
2. District dropdown becomes enabled
3. User searches/scrolls to find their district
4. System immediately shows detected region below
5. Region field is read-only with green "Auto" badge
6. User saves profile

### Visual Design

```
┌─────────────────────────────────────┐
│ District                            │
│ ┌─────────────────────────────────┐ │
│ │ Kampala                      ▼  │ │ <- Searchable dropdown
│ └─────────────────────────────────┘ │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 📍 Region (Auto-detected)      Auto │ <- Read-only, auto-filled
│ Central                             │
└─────────────────────────────────────┘
```

---

## District-Region Mapping

### Central Region (24 districts)
Buikwe, Bukomansimbi, Butambala, Buvuma, Gomba, Kalangala, Kalungi, **Kampala**, Kayunga, Kiboga, Kyankwanzi, Luwero, Lwengo, Lyantonde, Masaka, Mityana, Mpigi, Mubende, Mukono, Nakaseke, Nakasongola, Rakai, Sembabule, Wakiso

### Eastern Region (36 districts)
Amuria, Budaka, Bududa, Bugiri, Bugweri, Bukwa, Bulambuli, Busia, Butaleja, Butebo, Buyende, Iganga, **Jinja**, Kaberamaido, Kalaki, Kaliro, Kamuli, Kapchorwa, Kapelebyong, Katakwi, Kibuku, Kumi, Kween, Luuka, Manafwa, Mayuge, **Mbale**, Namayingo, Namisindwa, Namutumba, Ngora, Pallisa, Serere, Sironko, Soroti, Tororo

### Northern Region (33 districts)
Abim, Adjumani, Agago, Alebtong, Amudat, Amuru, Apac, **Arua**, Dokolo, **Gulu**, Kaabong, Kitgum, Koboko, Kole, Kotido, Lamwo, **Lira**, Maracha, Moroto, Moyo, Nabilatuk, Napak, Nebbi, Ngora, Nwoya, Obongi, Omoro, Otuke, Oyam, Pader, Pakwach, Yumbe, Zombo

### Western Region (35 districts)
Buhweju, Buliisa, Bundibugyo, Bunyangabu, Bushenyi, Butobo, Hoima, Ibanda, Isingiro, **Kabale**, Kabarole, Kagadi, Kakumiro, Kamwenge, Kanungu, Kasese, Kibaale, Kikuube, Kiruhura, Kiryandongo, Kisoro, Kitagwenda, Kyegegwa, Kyenjojo, Masindi, **Mbarara**, Mitooma, Ntoroko, Ntungamo, Rubanda, Rubirizi, Rukiga, Rukungiri, Rwampara, Sheema

---

## Backend Validation

### Region Validation Removed
Since region is now auto-detected from district, backend only validates district:

```javascript
body('district')
  .notEmpty()
  .withMessage('District is required')
```

Region is calculated server-side as well for consistency:

```javascript
function getRegionFromDistrict(district) {
  for (const [region, districts] of Object.entries(constants.uganda.districts)) {
    if (districts.includes(district)) {
      return region;
    }
  }
  return null;
}

// In profile update
const region = getRegionFromDistrict(district);
```

---

## Testing

### Test Cases

```dart
// Test auto-detection
expect(_getRegionFromDistrict('Kampala'), 'Central');
expect(_getRegionFromDistrict('Jinja'), 'Eastern');
expect(_getRegionFromDistrict('Gulu'), 'Northern');
expect(_getRegionFromDistrict('Mbarara'), 'Western');

// Test district list
final allDistricts = _getAllDistricts();
expect(allDistricts.length, 128); // All districts
expect(allDistricts.contains('Kampala'), true);
expect(allDistricts.contains('Zombo'), true);

// Test sorting
expect(allDistricts.first, 'Abim'); // Alphabetically first
expect(allDistricts.last, 'Zombo'); // Alphabetically last
```

### Manual Testing

1. **Profile Creation**
   - Select district "Wakiso"
   - Verify region shows "Central" automatically
   
2. **Profile Update**
   - Change district from "Kampala" to "Jinja"
   - Verify region changes from "Central" to "Eastern"

3. **Delivery Fee Calculation**
   - Farmer in Kampala (Central)
   - Buyer in Mbale (Eastern)
   - Expected fee: UGX 10,000 (Central-Eastern)

---

## GPS Still Available For

While region detection no longer uses GPS, geolocation is still useful for:

### 1. Distance Calculations
```dart
final distance = locationService.calculateDistance(
  farmerLat, farmerLng,
  buyerLat, buyerLng,
);
// "This farmer is 12.5 km away from you"
```

### 2. "Products Near Me" Feature
- Show products sorted by proximity
- Filter by radius (5km, 10km, 20km)

### 3. Delivery Tracking
- Real-time driver location
- ETA updates
- Route optimization

### 4. Analytics
- Heatmaps of buyer locations
- Identify underserved areas
- Optimize distribution centers

---

## Migration Guide

### For Existing Users

If users already have region set but no district:

```dart
void _loadUserData() {
  if (user.district != null && user.district!.isNotEmpty) {
    // District exists - auto-detect region
    _selectedDistrict = user.district!;
    _selectedRegion = _getRegionFromDistrict(_selectedDistrict);
  } else if (user.region != null && user.region!.isNotEmpty) {
    // Only region exists - prompt to select district
    _selectedRegion = user.region!;
    _showDistrictPrompt();
  }
}
```

### Database Migration

No migration needed! Region field can be auto-calculated from district:

```sql
-- Update missing regions
UPDATE users 
SET region = (
  CASE 
    WHEN district IN ('Kampala', 'Wakiso', ...) THEN 'Central'
    WHEN district IN ('Jinja', 'Mbale', ...) THEN 'Eastern'
    -- etc
  END
)
WHERE region IS NULL AND district IS NOT NULL;
```

---

## Benefits Summary

✅ **More Reliable** - Based on permanent address, not temporary location  
✅ **No Permissions** - Works without GPS/location access  
✅ **Faster** - Instant auto-detection, no API calls  
✅ **Offline-First** - No internet needed for region detection  
✅ **User-Friendly** - Clear visual feedback with "Auto" badge  
✅ **Accurate Delivery** - Orders go to intended location  
✅ **Privacy-Friendly** - No precise GPS coordinates stored  

---

## Future Enhancements

1. **Sub-County Selection** - Even more precise locations
2. **Address Autocomplete** - Google Places-style search
3. **Delivery Zones** - Within-district zone pricing
4. **Multiple Addresses** - Save home, farm, office locations

---

**Last Updated**: March 2026  
**Version**: 2.0.0
