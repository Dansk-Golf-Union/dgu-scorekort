import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:typed_data';
import 'dart:convert';
import '../models/scorecard_model.dart';
import '../models/player_model.dart';
import '../services/player_service.dart';
import '../theme/app_theme.dart';

class MarkerApprovalScreen extends StatefulWidget {
  final Scorecard scorecard;
  final Function(String fullName, String unionId, String? lifetimeId, String? homeClubName, String signature)? onMarkerApproved;

  const MarkerApprovalScreen({
    super.key,
    required this.scorecard,
    this.onMarkerApproved,
  });

  @override
  State<MarkerApprovalScreen> createState() => _MarkerApprovalScreenState();
}

class _MarkerApprovalScreenState extends State<MarkerApprovalScreen> {
  final TextEditingController _unionIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _playerService = PlayerService();
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  
  Player? _markerInfo;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showConfirmation = false;

  @override
  void dispose() {
    _unionIdController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _fetchMarkerInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _showConfirmation = false;
    });

    try {
      final player = await _playerService.fetchPlayerByUnionId(_unionIdController.text.trim());

      setState(() {
        _markerInfo = player;
        _showConfirmation = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmMarker() async {
    if (_markerInfo == null) return;

    // Validate signature
    if (_signatureController.isEmpty) {
      setState(() {
        _errorMessage = 'Markør skal underskrive før godkendelse';
      });
      return;
    }

    // Export signature to PNG
    final Uint8List? signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes == null) {
      setState(() {
        _errorMessage = 'Kunne ikke gemme underskrift. Prøv igen.';
      });
      return;
    }

    // Convert to base64
    final String signatureBase64 = base64Encode(signatureBytes);

    // Call callback if provided
    if (widget.onMarkerApproved != null) {
      widget.onMarkerApproved!(
        _markerInfo!.name,
        _unionIdController.text.trim(),
        _markerInfo!.lifetimeId,
        _markerInfo!.homeClubName,
        signatureBase64,
      );
    }

    // Return true to indicate approval
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Markør Godkendelse'),
        centerTitle: true,
        backgroundColor: AppTheme.dguGreen,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Din markør skal godkende dit scorekort',
                            style: TextStyle(
                              color: Colors.blue.shade900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
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
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.dguGreen, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                    ),
                    keyboardType: TextInputType.phone,
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
                    label: Text(_isLoading ? 'Henter...' : 'Hent Markør Info'),
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

                  // Confirmation card
                  if (_showConfirmation && _markerInfo != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Markør Information',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _markerInfo!.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (_markerInfo!.homeClubName != null)
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
                        ),
                      ),
                    ),
                    
                    // Signature section
                    const SizedBox(height: 24),
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Markør Underskrift',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    _signatureController.clear();
                                    setState(() {
                                      _errorMessage = null;
                                    });
                                  },
                                  icon: const Icon(Icons.refresh, size: 18),
                                  label: const Text('Ryd'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Signature pad
                            Container(
                              height: 150,
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300, width: 2),
                                borderRadius: BorderRadius.circular(8),
                                color: Colors.white,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Signature(
                                  controller: _signatureController,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Underskriv med din finger',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Vend skærmen for større felt',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Confirm button
                            FilledButton.icon(
                              onPressed: _confirmMarker,
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Bekræft og Godkend'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.dguGreen,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

