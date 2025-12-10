import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';

/// Dialog for assigning a marker to a scorecard
/// Returns the marker Player object if confirmed, null if cancelled
class MarkerAssignmentDialog extends StatefulWidget {
  const MarkerAssignmentDialog({super.key});

  @override
  State<MarkerAssignmentDialog> createState() => _MarkerAssignmentDialogState();
}

class _MarkerAssignmentDialogState extends State<MarkerAssignmentDialog> {
  final TextEditingController _unionIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _playerService = PlayerService();
  
  Player? _markerInfo;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _unionIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchMarkerInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final player = await _playerService.fetchPlayerByUnionId(
        _unionIdController.text.trim(),
      );

      setState(() {
        _markerInfo = player;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _confirmMarker() {
    if (_markerInfo == null) return;
    Navigator.pop(context, _markerInfo);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Icon(
                      Icons.person_add,
                      color: AppTheme.dguGreen,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Vælg Markør',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Indtast DGU nummeret på den person der skal godkende dit scorekort',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),

                // Union ID input
                TextFormField(
                  controller: _unionIdController,
                  decoration: InputDecoration(
                    labelText: 'Markørens DGU Nummer',
                    hintText: 'F.eks. 123-4567',
                    helperText: 'Format: XXX-XXXXXX',
                    prefixIcon: const Icon(Icons.badge),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.dguGreen,
                        width: 2,
                      ),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  autofocus: false,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Indtast markørens DGU nummer';
                    }
                    
                    // Validate format: 1-3 digits, dash, 1-6 digits
                    final regex = RegExp(r'^\d{1,3}-\d{1,6}$');
                    if (!regex.hasMatch(value.trim())) {
                      return 'Ugyldigt format. Brug: XXX-XXXXXX';
                    }
                    
                    return null;
                  },
                  onFieldSubmitted: (_) => _fetchMarkerInfo(),
                ),
                const SizedBox(height: 16),

                // Fetch button
                FilledButton.icon(
                  onPressed: _isLoading ? null : _fetchMarkerInfo,
                  icon: _isLoading 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isLoading ? 'Henter...' : 'Hent Markør'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.dguGreen,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Marker info card
                if (_markerInfo != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            const Text(
                              'Markør Fundet',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _markerInfo!.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'DGU: ${_unionIdController.text.trim()}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        if (_markerInfo!.homeClubName != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.golf_course, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                _markerInfo!.homeClubName!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Confirm button
                  FilledButton.icon(
                    onPressed: _confirmMarker,
                    icon: const Icon(Icons.send),
                    label: const Text('Gem og Send til Markør'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.dguGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
