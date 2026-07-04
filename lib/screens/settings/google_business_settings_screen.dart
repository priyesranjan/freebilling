import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/core.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';

class GoogleBusinessSettingsScreen extends StatefulWidget {
  const GoogleBusinessSettingsScreen({super.key});

  @override
  State<GoogleBusinessSettingsScreen> createState() => _GoogleBusinessSettingsScreenState();
}

class _GoogleBusinessSettingsScreenState extends State<GoogleBusinessSettingsScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/business.manage',
    ],
  );

  GoogleSignInAccount? _currentUser;
  List<dynamic> _locations = [];
  String? _selectedLocationId;
  String _statusMessage = '';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (mounted) {
        setState(() {
          _currentUser = account;
          if (account != null) {
            _fetchGmbLocations();
          }
        });
      }
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Connecting to Google...';
    });
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        // User cancelled sign-in
        setState(() {
          _isLoading = false;
          _statusMessage = '';
        });
        return;
      }
      setState(() {
        _currentUser = account;
      });
      await _fetchGmbLocations();
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = _parseSignInError(error.toString());
        _statusMessage = '';
      });
    }
  }

  String _parseSignInError(String error) {
    if (error.contains('10') || error.contains('DEVELOPER_ERROR')) {
      return 'Google OAuth Setup Required!\n\n'
          'Your APK\'s SHA-1 fingerprint needs to be registered in Google Cloud Console.\n\n'
          'SHA-1: 73:3A:0D:59:A3:B8:54:23:68:F5:A1:F6:82:C0:F0:C6:63:72:F8:02\n\n'
          'Steps:\n'
          '1. Open console.cloud.google.com\n'
          '2. Go to APIs & Services → Credentials\n'
          '3. Create Android OAuth Client ID\n'
          '4. Package: com.appdost.freebilling\n'
          '5. Paste SHA-1 fingerprint above\n'
          '6. Save and try again!';
    }
    if (error.contains('12500')) {
      return 'Google Play Services needs to be updated on this device. Please update Google Play Services from the Play Store and try again.';
    }
    if (error.contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    return 'Sign-in failed: $error\n\nPlease try again or check your Google Cloud Console configuration.';
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.disconnect();
    setState(() {
      _currentUser = null;
      _locations = [];
      _selectedLocationId = null;
      _statusMessage = '';
      _errorMessage = null;
    });
  }

  Future<void> _fetchGmbLocations() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _statusMessage = 'Fetching your Google Business locations...';
    });

    try {
      final scopeGranted = await _googleSignIn.requestScopes([
        'https://www.googleapis.com/auth/business.manage',
      ]);
      
      if (!scopeGranted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Business management permission was denied. Please grant access to manage your Google Business Profile.';
          _statusMessage = '';
        });
        return;
      }

      final authHeaders = await _currentUser!.authHeaders;

      // 1. Fetch Accounts
      final accountsUrl = Uri.parse('https://mybusinessaccountmanagement.googleapis.com/v1/accounts');
      final accountsRes = await http.get(accountsUrl, headers: authHeaders);

      if (accountsRes.statusCode != 200) {
        throw Exception('Failed to fetch accounts (HTTP ${accountsRes.statusCode}): ${accountsRes.body}');
      }

      final accountsData = jsonDecode(accountsRes.body);
      if (accountsData['accounts'] == null || (accountsData['accounts'] as List).isEmpty) {
        setState(() {
          _isLoading = false;
          _locations = [];
          _errorMessage = 'No Google Business accounts found for ${_currentUser!.email}.\n\n'
              'Make sure this Google account owns or manages a Google Business Profile at business.google.com';
          _statusMessage = '';
        });
        return;
      }

      // Fetch locations from all accounts
      List<dynamic> allLocations = [];
      for (final account in accountsData['accounts']) {
        final accountName = account['name'];
        final locationsUrl = Uri.parse(
          'https://mybusinessbusinessinformation.googleapis.com/v1/$accountName/locations?readMask=name,title,storeCode,storefrontAddress',
        );
        final locationsRes = await http.get(locationsUrl, headers: authHeaders);

        if (locationsRes.statusCode == 200) {
          final locationsData = jsonDecode(locationsRes.body);
          final locs = locationsData['locations'] ?? [];
          allLocations.addAll(locs);
        }
      }

      setState(() {
        _isLoading = false;
        _locations = allLocations;
        if (_locations.isEmpty) {
          _errorMessage = 'No business locations found in your Google Business account.\n\n'
              'Please add a location at business.google.com first, then come back here to link it.';
          _statusMessage = '';
        } else {
          _statusMessage = '${_locations.length} location(s) found. Select the one for this shop:';
          _selectedLocationId = _locations.first['name'];
          _errorMessage = null;
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to fetch locations: $e\n\nPlease check your internet connection and try again.';
        _statusMessage = '';
      });
    }
  }

  Future<void> _saveSelection() async {
    if (_selectedLocationId == null) return;

    setState(() => _isLoading = true);
    try {
      final s = AppSettings.instance;
      await ApiService.updateOnboarding(
        name: s.businessName.isEmpty ? 'My Shop' : s.businessName,
        businessType: s.businessType.isEmpty ? 'retail' : s.businessType,
        websiteSlug: s.websiteSlug.isEmpty ? 'my-shop' : s.websiteSlug,
        gmbLocationId: _selectedLocationId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Google Business Profile linked successfully!'),
            backgroundColor: BrandPalette.teal,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Google Business Profile', style: TextStyle(color: BrandPalette.navy)),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
        iconTheme: const IconThemeData(color: BrandPalette.navy),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header
                const Text(
                  'Link your Real Google Business',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: BrandPalette.navy),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in with your Google account that owns your business profile on Google Maps.',
                  style: TextStyle(color: BrandPalette.navy.withOpacity(0.6), fontSize: 14),
                ),
                const SizedBox(height: 30),

                // Sign-In / Signed-In State
                if (_currentUser == null) ...[
                  // Not signed in
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F4),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: const Icon(Icons.business, size: 40, color: Color(0xFF4285F4)),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Connect Your Google Account',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: BrandPalette.navy),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in with the same Gmail account you use to manage your business on Google Maps & Google Search.',
                          style: TextStyle(color: BrandPalette.navy.withOpacity(0.5), fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            icon: _isLoading
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.login, size: 20),
                            label: Text(
                              _isLoading ? 'Connecting...' : 'Sign in with Google',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Signed in - show account card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                      boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        GoogleUserCircleAvatar(identity: _currentUser!),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    _currentUser!.displayName ?? 'Google User',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: BrandPalette.navy),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(_currentUser!.email, style: TextStyle(color: BrandPalette.navy.withOpacity(0.5), fontSize: 12)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _handleSignOut,
                          child: const Text('Disconnect', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Status message
                  if (_statusMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: BrandPalette.navy)),
                    ),

                  // Loading indicator
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 30),
                      child: Center(child: CircularProgressIndicator()),
                    ),

                  // Location list (REAL locations only)
                  if (!_isLoading && _locations.isNotEmpty)
                    ..._locations.map((loc) {
                      final id = loc['name'] ?? '';
                      final title = loc['title'] ?? 'Unnamed Location';
                      final address = loc['storefrontAddress'];
                      String addressText = '';
                      if (address != null) {
                        final lines = address['addressLines'];
                        final locality = address['locality'] ?? '';
                        if (lines != null && lines is List && lines.isNotEmpty) {
                          addressText = '${lines.join(', ')}, $locality';
                        } else if (locality.isNotEmpty) {
                          addressText = locality;
                        }
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedLocationId == id ? BrandPalette.teal : Colors.grey.shade200,
                            width: _selectedLocationId == id ? 2 : 1,
                          ),
                        ),
                        child: RadioListTile<String>(
                          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (addressText.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(addressText, style: TextStyle(fontSize: 12, color: BrandPalette.navy.withOpacity(0.5))),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text('ID: ${id.split('/').last}', style: TextStyle(fontSize: 11, color: BrandPalette.navy.withOpacity(0.35))),
                              ),
                            ],
                          ),
                          value: id,
                          groupValue: _selectedLocationId,
                          onChanged: (val) => setState(() => _selectedLocationId = val),
                          activeColor: BrandPalette.teal,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        ),
                      );
                    }).toList(),

                  // No locations found (after successful sign-in)
                  if (!_isLoading && _locations.isEmpty && _errorMessage == null && _currentUser != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withOpacity(0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.store, size: 40, color: Colors.orange),
                          SizedBox(height: 12),
                          Text(
                            'No business locations found',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange, fontSize: 15),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'This Google account doesn\'t have any business locations. Please visit business.google.com to set up your business profile first.',
                            style: TextStyle(color: Colors.orange, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],

                // Error message (shown for both signed-in and not-signed-in states)
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.2)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SelectableText(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 13, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: _currentUser == null ? _handleSignIn : _fetchGmbLocations,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Try Again'),
                  ),
                ],
              ],
            ),
          ),

          // Save button (only when a REAL location is selected)
          if (_selectedLocationId != null && _locations.isNotEmpty && _currentUser != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))],
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isLoading ? null : _saveSelection,
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandPalette.navy,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save & Link Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
