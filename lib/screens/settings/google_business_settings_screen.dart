import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/core.dart';
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
  String _statusMessage = 'Connect your account to link your Google Business Profile.';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
        if (account != null) {
          _fetchGmbLocations();
        }
      });
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      setState(() {
        _statusMessage = 'Sign in error: $error';
      });
    }
  }

  Future<void> _handleSignOut() async {
    await _googleSignIn.disconnect();
    setState(() {
      _locations = [];
      _selectedLocationId = null;
    });
  }

  Future<void> _fetchGmbLocations() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching your Google Business Locations...';
    });

    try {
      // For Web support
      await _googleSignIn.requestScopes(['https://www.googleapis.com/auth/business.manage']);
      
      final authHeaders = await _currentUser!.authHeaders;
      
      // 1. Fetch Accounts
      final accountsUrl = Uri.parse('https://mybusinessaccountmanagement.googleapis.com/v1/accounts');
      final accountsRes = await http.get(accountsUrl, headers: authHeaders);
      
      if (accountsRes.statusCode != 200) throw Exception('Failed to fetch accounts');
      
      final accountsData = jsonDecode(accountsRes.body);
      if (accountsData['accounts'] == null || accountsData['accounts'].isEmpty) {
        setState(() {
          _isLoading = false;
          _statusMessage = 'No Google Business accounts found for this email.';
        });
        return;
      }
      
      final accountName = accountsData['accounts'][0]['name'];
      
      // 2. Fetch Locations
      final locationsUrl = Uri.parse('https://mybusinessbusinessinformation.googleapis.com/v1/$accountName/locations?readMask=name,title,storeCode');
      final locationsRes = await http.get(locationsUrl, headers: authHeaders);
      
      if (locationsRes.statusCode != 200) throw Exception('Failed to fetch locations');
      
      final locationsData = jsonDecode(locationsRes.body);
      setState(() {
        _isLoading = false;
        _locations = locationsData['locations'] ?? [];
        _statusMessage = _locations.isEmpty 
            ? 'No locations found in this account.' 
            : 'Select the location that matches this shop.';
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
    }
  }

  Future<void> _saveSelection() async {
    if (_selectedLocationId == null) return;

    setState(() => _isLoading = true);
    try {
      // In a real app, you'd fetch the current business record from a provider/state
      // For now, we update it via API.
      // Note: We need the name/type/slug which usually come from the onboarding state.
      // We'll assume the backend handles partial updates or we fetch them first.
      
      // For simplicity in this demo, we'll just update the gmb_location_id.
      // In production, you'd use a dedicated 'updateSettings' API.
      
      await ApiService.updateOnboarding(
        name: 'My Business', // Should be dynamic
        businessType: 'retail', // Should be dynamic
        websiteSlug: 'my-shop', // Should be dynamic
        gmbLocationId: _selectedLocationId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Google Business Profile linked successfully! 🎉'), backgroundColor: BrandPalette.teal),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Google Business Settings', style: TextStyle(color: BrandPalette.navy)),
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
                const Text(
                  'Link your Shop to Google',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: BrandPalette.navy),
                ),
                const SizedBox(height: 8),
                Text(
                  'Display your Google reviews and business hours automatically on your online storefront.',
                  style: TextStyle(color: BrandPalette.navy.withOpacity(0.6)),
                ),
                const SizedBox(height: 30),
                
                if (_currentUser == null) ...[
                  Center(
                    child: Column(
                      children: [
                        Image.network(
                          'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_\"G\"_Logo.svg/1200px-Google_\"G\"_Logo.svg.png',
                          height: 60,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _handleSignIn,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF4285F4),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Sign in with Google'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: BrandPalette.navy.withOpacity(0.1)),
                    ),
                    child: ListTile(
                      leading: GoogleUserCircleAvatar(identity: _currentUser!),
                      title: Text(_currentUser!.displayName ?? 'Google User'),
                      subtitle: Text(_currentUser!.email),
                      trailing: TextButton(
                        onPressed: _handleSignOut,
                        child: const Text('Sign Out', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  const Text('Select Business Location', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  if (_isLoading && _locations.isEmpty)
                    const Center(child: CircularProgressIndicator())
                  else if (_locations.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_statusMessage, style: const TextStyle(color: Colors.orange)),
                    )
                  else
                    ..._locations.map((loc) {
                      final id = loc['name']; // accounts/X/locations/Y
                      final title = loc['title'] ?? 'Unknown Location';
                      return RadioListTile<String>(
                        title: Text(title),
                        subtitle: Text('ID: ${id.split('/').last}'),
                        value: id,
                        groupValue: _selectedLocationId,
                        onChanged: (val) => setState(() => _selectedLocationId = val),
                        activeColor: BrandPalette.teal,
                        contentPadding: EdgeInsets.zero,
                      );
                    }).toList(),
                ],
              ],
            ),
          ),
          
          if (_selectedLocationId != null)
            Padding(
              padding: const EdgeInsets.all(20),
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
