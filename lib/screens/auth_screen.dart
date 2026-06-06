import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/core.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'screens.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;
  bool _otpSent = false;
  String? _sessionId; 

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isAutoTriggering = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    if (phone.length == 10 && !_otpSent && !_isAutoTriggering) {
      _isAutoTriggering = true;
      _sendOtp();
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _isAutoTriggering = false);
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final String rawPhone = _phoneController.text.trim();
    final String? phone = normalizeIndianPhoneNumber(rawPhone);
    
    if (phone == null || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid 10-digit phone number')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpSent = true;
        _sessionId = res['sessionId'];
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String error = e.toString();
      if (error.startsWith('Exception: ')) error = error.substring(11);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> _verifyOtp() async {
    final String rawPhone = _phoneController.text.trim();
    final String? phone = normalizeIndianPhoneNumber(rawPhone);
    final String otp = _otpController.text.trim();

    if (phone == null || otp.isEmpty || _sessionId == null) return;

    setState(() => _isLoading = true);

    try {
      final data = await ApiService.verifyOtp(phone, otp, _sessionId!);
      _handleAuthSuccess(data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _otpController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid OTP. Please try again.')));
    }
  }

  void _handleAuthSuccess(Map<String, dynamic> data) async {
    final business = data['business'];
    final user = data['user'];
    if (!mounted) return;

    final String? bizName = business['name'];
    final bool hasNameSet = bizName != null && 
                           bizName.isNotEmpty && 
                           bizName != 'My Business' && 
                           bizName != 'Business';

    AppSettings.instance.businessName = bizName ?? '';
    if (user != null && user['phone'] != null) AppSettings.instance.businessPhone = user['phone'];
    if (business['business_type'] != null) AppSettings.instance.businessType = business['business_type'];
    if (business['category'] != null) AppSettings.instance.businessCategory = business['category'];
    if (business['logo_url'] != null) AppSettings.instance.businessLogo = business['logo_url'];
    await AppSettings.instance.save();

    if (!mounted) return;

    if (hasNameSet) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const PlatformShell()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 420),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: BrandPalette.navy.withValues(alpha: 0.05), blurRadius: 40, offset: const Offset(0, 10)),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo / Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: BrandPalette.teal.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_outlined, size: 40, color: BrandPalette.teal),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 32),
                    
                    // Welcome Text
                    Text(
                      _otpSent ? 'Verify Phone' : 'Welcome',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: BrandPalette.navy,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 12),
                    Text(
                      _otpSent 
                          ? 'Enter the 6-digit OTP sent to\n+91 ${_phoneController.text}' 
                          : 'Enter your phone number to continue.\nWe will send you an OTP.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 48),

                    // Input Area
                    if (!_otpSent)
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.spaceGrotesk(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '00000 00000',
                          hintStyle: TextStyle(color: Colors.grey.shade300),
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 20, right: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('+91', style: GoogleFonts.spaceGrotesk(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
                              ],
                            ),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: Colors.grey.shade200, width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: BrandPalette.teal, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(vertical: 24),
                        ),
                      ).animate().fadeIn(delay: 200.ms)
                    else
                      Pinput(
                        length: 6,
                        controller: _otpController,
                        onCompleted: (pin) => _verifyOtp(),
                        defaultPinTheme: PinTheme(
                          width: 50,
                          height: 60,
                          textStyle: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: BrandPalette.navy),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        focusedPinTheme: PinTheme(
                          width: 50,
                          height: 60,
                          textStyle: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w700, color: BrandPalette.navy),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: BrandPalette.teal, width: 2),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: BrandPalette.teal.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2),
                            ],
                          ),
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 40),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: FilledButton(
                        onPressed: _isLoading 
                            ? null 
                            : (_otpSent ? _verifyOtp : _sendOtp),
                        style: FilledButton.styleFrom(
                          backgroundColor: BrandPalette.teal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 0,
                        ),
                        child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                            : Text(
                                _otpSent ? 'Verify OTP' : 'Continue',
                                style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    if (_otpSent) ...[
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _otpSent = false;
                                _otpController.clear();
                                _isAutoTriggering = false;
                              });
                            },
                            child: Text('Change Number', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                          ),
                          Text('•', style: TextStyle(color: Colors.grey.shade400)),
                          TextButton(
                            onPressed: _isLoading ? null : _sendOtp,
                            child: const Text('Resend OTP', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ).animate().fadeIn(delay: 500.ms),
                    ]
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
