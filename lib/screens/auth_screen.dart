import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pinput/pinput.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/core.dart';
import '../services/services.dart';
import 'screens.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with CodeAutoFill {
  bool _isLogin = true;
  bool _isLoading = false;
  bool _otpSent = false;
  String? _sessionId; 

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  
  String _businessType = 'retail';
  
  Uint8List? _logoBytes;
  String? _logoName;
  bool _isAutoTriggering = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    listenForCode(); // Start listening for SMS
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    if (phone.length == 10 && !_otpSent && !_isAutoTriggering && _isLogin) {
      _isAutoTriggering = true;
      _sendOtp();
      // Reset trigger after a delay to allow manual re-send if needed
      Future.delayed(const Duration(seconds: 2), () {
        _isAutoTriggering = false;
      });
    }
  }

  @override
  void codeUpdated() {
    setState(() {
      _otpController.text = code ?? '';
    });
    if (_otpController.text.length == 6) {
      _verifyOtp();
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _nameController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _logoBytes = bytes;
        _logoName = image.name;
      });
    }
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

    if (otp.isEmpty || _sessionId == null) return;

    setState(() => _isLoading = true);

    try {
      String? uploadedLogoUrl;
      if (!_isLogin && _logoBytes != null && _logoName != null) {
        uploadedLogoUrl = await ApiService.uploadLogo(_logoBytes!, _logoName!);
      }

      final data = await ApiService.verifyOtp(
        phone, otp, _sessionId!,
        name: _isLogin ? null : _nameController.text.trim(),
        businessType: _isLogin ? null : _businessType,
        category: _isLogin ? null : _categoryController.text.trim(),
        logoUrl: uploadedLogoUrl,
      );
      
      final business = data['business'];
      
      if (!mounted) return;
      
      // If we somehow logged in but the backend lacks crucial info
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
      await Future.delayed(const Duration(seconds: 1));
      final String mockEmail = 'demo${DateTime.now().millisecondsSinceEpoch}@google.com';
      final data = await ApiService.googleLogin(mockEmail, 'Google Demo User');
      final business = data['business'];

      if (!mounted) return;
      
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Login Failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandPalette.pageBase,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
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
                ).animate().scale(duration: 400.ms, curve: Curves.backOut).fadeIn(),
                const SizedBox(height: 24),
                Text(
                  'Welcome to ERP Bill',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: BrandPalette.navy,
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 400.ms).fadeIn(),
                const SizedBox(height: 32),

                // Tab Switcher
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Login'),
                      selected: _isLogin,
                      onSelected: (val) {
                        if (val) setState(() { _isLogin = true; _otpSent = false; });
                      },
                      selectedColor: BrandPalette.teal.withValues(alpha: 0.2),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('Signup'),
                      selected: !_isLogin,
                      onSelected: (val) {
                        if (val) setState(() { _isLogin = false; _otpSent = false; });
                      },
                      selectedColor: BrandPalette.teal.withValues(alpha: 0.2),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                if (!_otpSent) ...[
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone),
                      hintText: '10-digit mobile number',
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                  
                  if (!_isLogin) ...[
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _businessType,
                      decoration: const InputDecoration(
                        labelText: 'Business Type',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'retail', child: Text('Retail Store')),
                        DropdownMenuItem(value: 'wholesale', child: Text('Wholesale')),
                        DropdownMenuItem(value: 'service', child: Text('Service/Agency')),
                        DropdownMenuItem(value: 'restaurant', child: Text('Restaurant/Cafe')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _businessType = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _categoryController,
                      decoration: const InputDecoration(
                        labelText: 'Category (e.g. Electronics, Clothing)',
                        prefixIcon: Icon(Icons.local_offer),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: _logoBytes != null 
                        ? CircleAvatar(backgroundImage: MemoryImage(_logoBytes!))
                        : const CircleAvatar(child: Icon(Icons.image)),
                      title: Text(_logoBytes != null ? 'Logo Selected' : 'Upload Business Logo'),
                      trailing: IconButton(
                        icon: const Icon(Icons.upload_file),
                        onPressed: _pickLogo,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isLogin ? 'Login' : 'Signup'),
                    ),
                  ),
                ] else ...[
                  Text(
                    'Enter the 6-digit code sent to ${_phoneController.text}',
                    style: TextStyle(color: BrandPalette.ink.withValues(alpha: 0.8)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Pinput(
                    length: 6,
                    controller: _otpController,
                    onCompleted: (val) => _verifyOtp(),
                    defaultPinTheme: PinTheme(
                      width: 50,
                      height: 60,
                      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: BrandPalette.navy),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                    ),
                    focusedPinTheme: PinTheme(
                      width: 50,
                      height: 60,
                      textStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: BrandPalette.teal),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: BrandPalette.teal, width: 2),
                      ),
                    ),
                  ).animate().shake(duration: 500.ms),
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
                        : const Text('Verify & Continue'),
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
