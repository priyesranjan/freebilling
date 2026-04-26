import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/core.dart';
import '../services/services.dart';
import 'screens.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _otpSent = false;
  String? _sessionId; // Stores the 2Factor session ID
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final String phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your phone number')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final sessionId = await ApiService.sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isLoading = false;
        _sessionId = sessionId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP sent to your phone!')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _sendVoiceOtp() async {
    final String phone = _phoneController.text.trim();
    if (phone.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final sessionId = await ApiService.sendVoiceOtp(phone);
      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _isLoading = false;
        _sessionId = sessionId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calling you with OTP...')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _verifyOtp() async {
    final String phone = _phoneController.text.trim();
    final String otp = _otpController.text.trim();
    final String name = _nameController.text.trim();

    if (otp.isEmpty || _sessionId == null) return;

    setState(() => _isLoading = true);

    try {
      final data = await ApiService.verifyOtp(phone, otp, _sessionId!, name.isEmpty ? null : name);
      final business = data['business'];
      
      if (!mounted) return;
      
      // If it's a new business or missing crucial info, go to onboarding
      if (business['business_type'] == null || business['website_slug'] == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PlatformShell()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid OTP or Verification Failed')));
    }
  }

  Future<void> _googleLogin() async {
    setState(() => _isLoading = true);
    try {
      // Mock Google Login Flow - in a real app you'd use google_sign_in package here
      await Future.delayed(const Duration(seconds: 1));
      final String mockEmail = 'demo${DateTime.now().millisecondsSinceEpoch}@google.com';
      final data = await ApiService.googleLogin(mockEmail, 'Google Demo User');
      final business = data['business'];

      if (!mounted) return;
      
      if (business['businessType'] == null || business['websiteSlug'] == null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const OnboardingScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const PlatformShell()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: BrandPalette.teal.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.storefront_outlined, size: 40, color: BrandPalette.teal),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to ERP Bill',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: BrandPalette.navy,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in or create a business account',
                  style: TextStyle(
                    fontSize: 16,
                    color: BrandPalette.ink.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 48),

                if (!_otpSent) ...[
                  // PHONE INPUT
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Continue'),
                    ),
                  ),
                ] else ...[
                  // OTP INPUT
                  Text(
                    'Enter the 4-digit code sent to ${_phoneController.text}',
                    style: TextStyle(color: BrandPalette.ink.withValues(alpha: 0.8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 16, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '----',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Optional Name Input for demo registration
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Business Name (Optional)',
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _verifyOtp,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Verify & Login'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _sendVoiceOtp,
                    child: const Text("Didn't receive SMS? Get OTP via Call"),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _otpSent = false),
                    child: const Text('Change Phone Number'),
                  ),
                ],

                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(child: Divider(color: BrandPalette.navy.withValues(alpha: 0.1))),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: BrandPalette.ink.withValues(alpha: 0.4))),
                    ),
                    Expanded(child: Divider(color: BrandPalette.navy.withValues(alpha: 0.1))),
                  ],
                ),
                const SizedBox(height: 32),

                // GOOGLE BUTTON
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _googleLogin,
                    icon: Image.network(
                      'https://cdn1.iconfinder.com/data/icons/google-s-logo/150/Google_Icons-09-512.png',
                      height: 24,
                    ),
                    label: const Text('Continue with Google'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: BrandPalette.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
