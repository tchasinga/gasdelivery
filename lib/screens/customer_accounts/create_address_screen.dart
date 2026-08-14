import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../config/google_maps_keys.dart';

class CreateAddressScreen extends StatefulWidget {
  const CreateAddressScreen({super.key});

  @override
  State<CreateAddressScreen> createState() => _CreateAddressScreenState();
}

class _CreateAddressScreenState extends State<CreateAddressScreen> {
  static const _brand = Color(0xFF014F5B);
  static const _googleApiKey = GoogleMapsKeys.places;

  final _nameCtrl = TextEditingController();
  final _detailsCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  List<Map<String, dynamic>> _suggestions = [];
  String? _suggestionError;
  double? _lat;
  double? _lng;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _nameCtrl.dispose();
    _detailsCtrl.dispose();
    super.dispose();
  }

  void _onAddressChanged(String query) {
    _lat = null;
    _lng = null;
    _suggestionError = null;
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _searchPlaces(query);
    });
  }

  Future<void> _searchPlaces(String query) async {
    if (query.trim().length < 3) {
      setState(() {
        _suggestions = [];
        _suggestionError = null;
      });
      return;
    }
    try {
      final autoUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=${Uri.encodeComponent(query)}&types=address&components=country:ke&key=$_googleApiKey',
      );
      final autoRes = await http.get(autoUrl);
      final autoData = jsonDecode(autoRes.body);
      var preds = (autoData['predictions'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

      if (preds.isEmpty) {
        final queryUrl = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/queryautocomplete/json?input=${Uri.encodeComponent(query)}&key=$_googleApiKey',
        );
        final queryRes = await http.get(queryUrl);
        final queryData = jsonDecode(queryRes.body);
        preds = (queryData['predictions'] as List? ?? [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }

      if (!mounted) return;
      setState(() {
        _suggestions = preds;
        _suggestionError = preds.isEmpty ? null : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _suggestionError = 'Could not load suggestions right now.';
      });
    }
  }

  Future<void> _pickSuggestion(Map<String, dynamic> s) async {
    final placeId = s['place_id']?.toString();
    if (placeId == null) return;
    _nameCtrl.text = s['description']?.toString() ?? _nameCtrl.text;
    setState(() => _suggestions = []);

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$_googleApiKey',
    );
    final res = await http.get(url);
    final data = jsonDecode(res.body);
    final loc = data['result']?['geometry']?['location'];
    if (loc is Map) {
      _lat = (loc['lat'] as num?)?.toDouble();
      _lng = (loc['lng'] as num?)?.toDouble();
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    if (_lat == null || _lng == null) {
      final resolved = await _resolveCoordinatesFromText(_nameCtrl.text.trim());
      if (resolved != null) {
        _lat = resolved.$1;
        _lng = resolved.$2;
      }
    }

    if (_lat == null || _lng == null) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not detect coordinates. Try selecting a suggestion.',
            ),
          ),
        );
      }
      return;
    }

    Navigator.pop(context, {
      'name': _nameCtrl.text.trim(),
      'details': _detailsCtrl.text.trim(),
      'lat': _lat,
      'lng': _lng,
    });
  }

  Future<(double, double)?> _resolveCoordinatesFromText(String address) async {
    if (address.isEmpty) return null;
    try {
      final geoUrl = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$_googleApiKey',
      );
      final geoRes = await http.get(geoUrl);
      final geoData = jsonDecode(geoRes.body);
      final results = geoData['results'] as List?;
      if (results != null && results.isNotEmpty) {
        final loc = results.first['geometry']?['location'];
        final lat = (loc?['lat'] as num?)?.toDouble();
        final lng = (loc?['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          return (lat, lng);
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _brand,
        foregroundColor: Colors.white,
        title: const Text('Create Address'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              onChanged: _onAddressChanged,
              decoration: const InputDecoration(
                labelText: 'Address name',
                hintText: 'Start typing location...',
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Address is required'
                  : null,
            ),
            const SizedBox(height: 10),
            if (_suggestions.isNotEmpty)
              Card(
                child: Column(
                  children: _suggestions
                      .take(5)
                      .map(
                        (s) => ListTile(
                          title: Text(s['description']?.toString() ?? ''),
                          onTap: () => _pickSuggestion(s),
                        ),
                      )
                      .toList(),
                ),
              ),
            if (_suggestionError != null) ...[
              const SizedBox(height: 8),
              Text(
                _suggestionError!,
                style: const TextStyle(color: Colors.orange),
              ),
            ],
            const SizedBox(height: 8),
            TextFormField(
              controller: _detailsCtrl,
              decoration: const InputDecoration(
                labelText: 'Address details',
                hintText: 'House, floor, nearby landmark...',
              ),
            ),
            if (_lat != null && _lng != null) ...[
              const SizedBox(height: 10),
              Text('Coordinates: $_lat, $_lng'),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _brand),
              onPressed: _loading ? null : _save,
              child: const Text('Add address'),
            ),
          ],
        ),
      ),
    );
  }
}
