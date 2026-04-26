import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/core.dart';

class GoogleApiTestScreen extends StatefulWidget {
  const GoogleApiTestScreen({super.key});

  @override
  State<GoogleApiTestScreen> createState() => _GoogleApiTestScreenState();
}

class _GoogleApiTestScreenState extends State<GoogleApiTestScreen> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/business.manage',
    ],
  );

  GoogleSignInAccount? _currentUser;
  String _apiResponse = 'No data yet.';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        _currentUser = account;
      });
    });
    _googleSignIn.signInSilently();
  }

  Future<void> _handleSignIn() async {
    try {
      await _googleSignIn.signIn();
    } catch (error) {
      print('DEBUG GOOGLE SIGN IN ERROR: $error');
      setState(() {
        _apiResponse = 'Sign in error: $error';
      });
    }
  }

  Future<void> _handleSignOut() => _googleSignIn.disconnect();

  Future<void> _testGoogleBusinessApi() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoading = true;
      _apiResponse = 'Fetching Account Data...';
    });

    try {
      // On Web, we must explicitly request the API scopes before fetching auth headers
      final bool isAuthorized = await _googleSignIn.requestScopes([
        'https://www.googleapis.com/auth/business.manage'
      ]);
      
      if (!isAuthorized) {
        setState(() {
          _isLoading = false;
          _apiResponse = 'Permission Denied: You must allow the app to manage your business to continue.';
        });
        return;
      }

      final authHeaders = await _currentUser!.authHeaders;
      
      // 1. Fetch Accounts
      final accountsUrl = Uri.parse('https://mybusinessaccountmanagement.googleapis.com/v1/accounts');
      final accountsRes = await http.get(accountsUrl, headers: authHeaders);
      
      if (accountsRes.statusCode != 200) {
        setState(() {
          _isLoading = false;
          _apiResponse = 'Error fetching accounts (Code: ${accountsRes.statusCode}):\n${accountsRes.body}';
        });
        return;
      }
      
      final accountsData = jsonDecode(accountsRes.body);
      if (accountsData['accounts'] == null || accountsData['accounts'].isEmpty) {
        setState(() {
          _isLoading = false;
          _apiResponse = 'Success hitting API, but no Google Business Accounts found for this email.';
        });
        return;
      }
      
      final accountName = accountsData['accounts'][0]['name']; // e.g., 'accounts/12345'
      
      // 2. Fetch Locations (Businesses) for that Account
      setState(() {
        _apiResponse = 'Account Found: $accountName. Fetching Locations...';
      });
      
      final locationsUrl = Uri.parse('https://mybusinessbusinessinformation.googleapis.com/v1/$accountName/locations?readMask=name,title');
      final locationsRes = await http.get(locationsUrl, headers: authHeaders);
      
      if (locationsRes.statusCode != 200) {
         setState(() {
          _isLoading = false;
          _apiResponse = 'Error fetching locations (Code: ${locationsRes.statusCode}):\n${locationsRes.body}';
        });
        return;
      }
      
      setState(() {
        _isLoading = false;
        _apiResponse = 'API TEST SUCCESS! 🎉\n\nAccounts Response:\n${accountsRes.body}\n\nLocations Response:\n${locationsRes.body}';
      });
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _apiResponse = 'Exception during API call: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      appBar: AppBar(
        title: const Text('Google API Debugger'),
        backgroundColor: BrandPalette.pageBase,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BrandPalette.mint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BrandPalette.teal.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'This screen tests if your Google Cloud Project has the correct APIs enabled and quota granted. It tries to fetch your GMB Locations.',
              style: TextStyle(color: BrandPalette.teal, fontSize: 13),
            ),
          ),
          const SizedBox(height: 24),
          
          if (_currentUser != null) ...[
            ListTile(
              leading: GoogleUserCircleAvatar(identity: _currentUser!),
              title: Text(_currentUser!.displayName ?? ''),
              subtitle: Text(_currentUser!.email),
              trailing: IconButton(
                icon: const Icon(Icons.logout),
                onPressed: _handleSignOut,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _isLoading ? null : _testGoogleBusinessApi,
                icon: _isLoading ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)) : const Icon(Icons.sync),
                label: Text(_isLoading ? 'Running Test...' : 'Run API Connection Test'),
                style: FilledButton.styleFrom(backgroundColor: BrandPalette.navy, padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _handleSignIn,
                icon: const Icon(Icons.login),
                label: const Text('Sign in with Google'),
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF4285F4), padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
          
          const SizedBox(height: 30),
          const Text('API Response Logs', style: TextStyle(fontWeight: FontWeight.bold, color: BrandPalette.navy)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SelectableText(
              _apiResponse,
              style: const TextStyle(fontFamily: 'Courier', color: Colors.greenAccent, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
