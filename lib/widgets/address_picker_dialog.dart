import 'package:flutter/material.dart';
import '../services/places_service.dart';

class AddressPickerDialog extends StatefulWidget {
  final String? initialAddress;

  const AddressPickerDialog({super.key, this.initialAddress});

  @override
  State<AddressPickerDialog> createState() => _AddressPickerDialogState();
}

class _AddressPickerDialogState extends State<AddressPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _predictions = [];
  bool _isLoading = false;
  String? _selectedAddress;

  @override
  void initState() { 
    super.initState();
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _searchController.text = widget.initialAddress!;
      _selectedAddress = widget.initialAddress;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final predictions = await PlacesService.getPlacePredictions(query);
    
    setState(() {
      _predictions = predictions;
      _isLoading = false;
    });
  }

  Future<void> _selectPlace(Map<String, dynamic> prediction) async {
    setState(() {
      _isLoading = true;
    });

    final placeId = prediction['place_id'] as String;
    final details = await PlacesService.getPlaceDetails(placeId);

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    final address = _resolveSelectedAddress(prediction, details);
    if (address.isEmpty) return;

    setState(() {
      _selectedAddress = address;
      _searchController.text = address;
      _predictions = [];
    });
  }

  /// Prefer the label the user tapped (e.g. establishment name), not the street
  /// line from [formatted_address] (e.g. "Muchai Dr, Nairobi, Kenya").
  static String _resolveSelectedAddress(
    Map<String, dynamic> prediction,
    Map<String, dynamic>? details,
  ) {
    final mainText = prediction['structured_formatting']?['main_text'] as String?;
    if (mainText != null && mainText.trim().isNotEmpty) {
      return mainText.trim();
    }

    final name = details?['name'] as String?;
    if (name != null && name.trim().isNotEmpty) {
      return name.trim();
    }

    final description = prediction['description'] as String?;
    if (description != null && description.trim().isNotEmpty) {
      return description.trim();
    }

    final formatted = details?['formatted_address'] as String?;
    return formatted?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Select Address',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF014F5B),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(_selectedAddress),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for an address...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _predictions = [];
                            _selectedAddress = null;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF014F5B), width: 2),
                ),
              ),
              onChanged: (value) {
                _searchPlaces(value);
              },
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    color: Color(0xFF014F5B),
                  ),
                ),
              )
            else if (_predictions.isEmpty && _searchController.text.isEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'Start typing to search for an address',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else if (_predictions.isEmpty && _searchController.text.isNotEmpty)
              const Expanded(
                child: Center(
                  child: Text(
                    'No results found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    final description = prediction['description'] as String;
                    final mainText = prediction['structured_formatting']?['main_text'] as String? ?? description;
                    final secondaryText = prediction['structured_formatting']?['secondary_text'] as String? ?? '';

                    return ListTile(
                      leading: const Icon(Icons.location_on, color: Color(0xFF014F5B)),
                      title: Text(mainText),
                      subtitle: secondaryText.isNotEmpty ? Text(secondaryText) : null,
                      onTap: () => _selectPlace(prediction),
                    );
                  },
                ),
              ),
            if (_selectedAddress != null) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF014F5B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedAddress!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF014F5B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(_selectedAddress),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF014F5B),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Confirm Address',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

