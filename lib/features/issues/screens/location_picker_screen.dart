import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/location_service.dart';

class MapLocationResult {
  const MapLocationResult({required this.location, required this.label});

  final LatLng location;
  final String label;
}

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, this.initialLocation, this.useCurrentLocation = false});

  final LatLng? initialLocation;
  final bool useCurrentLocation;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const _defaultLocation = LatLng(6.927079, 79.861244);

  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLocation;
  String? _selectedLabel;
  List<_SearchPlace> _searchResults = [];
  bool _isSearching = false;
  bool _isLoadingLocation = false;

  LatLng get _mapCenter => _selectedLocation ?? _defaultLocation;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (widget.useCurrentLocation) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _useCurrentLocation());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchResults = [];
    });

    try {
      final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
        'q': query,
        'format': 'jsonv2',
        'limit': '5',
      });
      final response = await http.get(uri, headers: {
        'User-Agent': 'GreenOffice360/1.0',
      });

      if (response.statusCode != 200) {
        throw Exception('Location search failed.');
      }

      final places = (jsonDecode(response.body) as List<dynamic>)
          .map((item) => _SearchPlace.fromJson(item as Map<String, dynamic>))
          .toList();
      if (!mounted) return;
      setState(() => _searchResults = places);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to search locations.')),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectPlace(_SearchPlace place) {
    final location = LatLng(place.latitude, place.longitude);
    setState(() {
      _selectedLocation = location;
      _selectedLabel = place.displayName;
      _searchResults = [];
      _searchController.text = place.displayName;
    });
    _mapController.move(location, 16);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _locationService.getCurrentLocation();
      final location = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _selectedLocation = location;
        _selectedLabel = 'Current location';
        _searchResults = [];
      });
      _mapController.move(location, 17);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _selectMapPoint(TapPosition _, LatLng location) {
    setState(() {
      _selectedLocation = location;
      _selectedLabel = 'Selected map location';
      _searchResults = [];
    });
  }

  void _confirmLocation() {
    final location = _selectedLocation;
    if (location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a location on the map first.')),
      );
      return;
    }

    Navigator.pop(
      context,
      MapLocationResult(
        location: location,
        label: _selectedLabel ?? 'Selected map location',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Location'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _mapCenter,
              initialZoom: _selectedLocation == null ? 13 : 16,
              onTap: _selectMapPoint,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.greenoffice360',
              ),
              if (_selectedLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedLocation!,
                      width: 48,
                      height: 48,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.error,
                        size: 48,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.surface,
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchPlaces(),
                    decoration: InputDecoration(
                      hintText: 'Search for an address or place',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              onPressed: _searchPlaces,
                              icon: const Icon(Icons.arrow_forward),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Material(
                    elevation: 4,
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final place = _searchResults[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined),
                          title: Text(place.displayName, maxLines: 2, overflow: TextOverflow.ellipsis),
                          onTap: () => _selectPlace(place),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 92,
            child: FloatingActionButton(
              heroTag: 'current-location',
              onPressed: _isLoadingLocation ? null : _useCurrentLocation,
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              child: _isLoadingLocation
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _confirmLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Use This Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchPlace {
  const _SearchPlace({required this.displayName, required this.latitude, required this.longitude});

  factory _SearchPlace.fromJson(Map<String, dynamic> json) {
    return _SearchPlace(
      displayName: json['display_name'] as String? ?? 'Selected place',
      latitude: double.parse(json['lat'] as String),
      longitude: double.parse(json['lon'] as String),
    );
  }

  final String displayName;
  final double latitude;
  final double longitude;
}