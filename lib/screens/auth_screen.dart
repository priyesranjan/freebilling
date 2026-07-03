import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pinput/pinput.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_autofill/sms_autofill.dart';
import '../core/core.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'screens.dart';

enum _AuthMode { otpPhone, otpVerify, password, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with CodeAutoFill {
  _AuthMode _mode = _AuthMode.otpPhone;
  bool _isLoading = false;
  String? _sessionId;

  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isAutoTriggering = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_onPhoneChanged);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted && _mode == _AuthMode.otpPhone && _phoneController.text.isEmpty) {
        _askForPhoneHint();
      }
    });
  }

  Future<void> _askForPhoneHint() async {
    try {
      final String? autoPhone = await SmsAutoFill().hint;
      if (autoPhone != null && mounted) {
        String phone = autoPhone.trim();
        phone = phone.replaceAll(RegExp(r'\D'), ''); // Keep only digits
        if (phone.length > 10) {
          phone = phone.substring(phone.length - 10);
        }
        setState(() {
          _phoneController.text = phone;
        });
      }
    } catch (e) {
      debugPrint("Error getting phone hint: $e");
    }
  }

  @override
  void codeUpdated() {
    final incomingCode = code;
    debugPrint("SmsAutoFill codeUpdated: $incomingCode");
    if (incomingCode != null && incomingCode.length == 6) {
      setState(() {
        _otpController.text = incomingCode;
      });
      _verifyOtp(); // Auto verify!
    }
  }

  void _onPhoneChanged() {
    final phone = _phoneController.text.trim();
    if (_mode == _AuthMode.otpPhone && phone.length == 10 && !_isAutoTriggering && !_isLoading) {
      _isAutoTriggering = true;
      _sendOtp();
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) setState(() => _isAutoTriggering = false);
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    try {
      SmsAutoFill().unregisterListener();
      cancel();
    } catch (e) {
      debugPrint("Error disposing SmsAutoFill: $e");
    }
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_isLoading || _mode != _AuthMode.otpPhone) return;
    final String? phone = normalizeIndianPhoneNumber(_phoneController.text.trim());
    if (phone == null || phone.length < 10) {
      _showSnack('Please enter a valid 10-digit phone number');
      return;
    }
    setState(() => _isLoading = true);

    try {
      await SmsAutoFill().listenForCode();
      debugPrint("SmsAutoFill started listening for SMS OTP");
    } catch (e) {
      debugPrint("Error starting SmsAutoFill listener: $e");
    }

    try {
      final res = await ApiService.sendOtp(phone);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _sessionId = res['sessionId'];
        _mode = _AuthMode.otpVerify;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String error = e.toString();
      if (error.startsWith('Exception: ')) error = error.substring(11);
      _showSnack(error);
    }
  }

  Future<void> _verifyOtp() async {
    final String? phone = normalizeIndianPhoneNumber(_phoneController.text.trim());
    final String otp = _otpController.text.trim();
    if (phone == null || otp.isEmpty || _sessionId == null) return;
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.verifyOtp(phone, otp, _sessionId!);
      _handleAuthSuccess(data);
    } catch (e) {
      if (!mounted) return;
      setState(() { _isLoading = false; _otpController.clear(); });
      _showSnack('Invalid OTP. Please try again.');
    }
  }

  Future<void> _loginWithPassword() async {
    final String? phone = normalizeIndianPhoneNumber(_phoneController.text.trim());
    final String password = _passwordController.text;
    if (phone == null || phone.length < 10) { _showSnack('Please enter a valid phone number'); return; }
    if (password.isEmpty) { _showSnack('Please enter your password'); return; }
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.loginWithPassword(phone, password);
      _handleAuthSuccess(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String error = e.toString();
      if (error.startsWith('Exception: ')) error = error.substring(11);
      _showSnack(error);
    }
  }

  Future<void> _registerWithPassword() async {
    final String? phone = normalizeIndianPhoneNumber(_phoneController.text.trim());
    final String password = _passwordController.text;
    final String name = _nameController.text.trim();
    if (phone == null || phone.length < 10) { _showSnack('Please enter a valid phone number'); return; }
    if (password.isEmpty) { _showSnack('Please enter a password'); return; }
    if (name.isEmpty) { _showSnack('Please enter your business name'); return; }
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.registerWithPassword(phone, password, name: name);
      _handleAuthSuccess(data);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      String error = e.toString();
      if (error.startsWith('Exception: ')) error = error.substring(11);
      _showSnack(error);
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
    AppSettings.instance.businessPhone = business['phone'] ?? (user != null ? user['phone'] ?? '' : '');
    if (business['business_type'] != null) AppSettings.instance.businessType = business['business_type'];
    if (business['category'] != null) AppSettings.instance.businessCategory = business['category'];
    if (business['logo_url'] != null) AppSettings.instance.businessLogo = business['logo_url'];
    await AppSettings.instance.save();

    final prefs = await SharedPreferences.getInstance();
    final bool hasLanguageSet = prefs.containsKey('app_language');

    if (!mounted) return;

    if (hasNameSet) {
      if (hasLanguageSet) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PlatformShell()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LanguageSelectionScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildCard(),
                  const SizedBox(height: 20),
                  _buildAlternativeOptions(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF1A3C5A).withValues(alpha: 0.08), blurRadius: 40, offset: const Offset(0, 12)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [BrandPalette.teal, Color(0xFF1A6FE3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: BrandPalette.teal.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.storefront_rounded, size: 40, color: Colors.white),
          ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

          const SizedBox(height: 24),

          Text(
            _modeTitle,
            style: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w800, color: BrandPalette.navy),
          ).animate(key: ValueKey(_mode)).fadeIn().slideY(begin: 0.15, end: 0),

          const SizedBox(height: 8),
          Text(
            _modeSubtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 15, color: Colors.grey.shade500, height: 1.5),
          ).animate(key: ValueKey('sub_$_mode')).fadeIn(delay: 80.ms),

          const SizedBox(height: 40),
          _buildInputArea(),
          const SizedBox(height: 32),
          _buildPrimaryButton(),
          if (_mode == _AuthMode.otpVerify) _buildOtpActions(),
        ],
      ),
    );
  }

  String get _modeTitle {
    switch (_mode) {
      case _AuthMode.otpPhone: return 'Welcome! 👋';
      case _AuthMode.otpVerify: return 'Enter OTP';
      case _AuthMode.password: return 'Login';
      case _AuthMode.register: return 'Create Account';
    }
  }

  String get _modeSubtitle {
    switch (_mode) {
      case _AuthMode.otpPhone: return 'Enter your mobile number to continue.\nWe will send you a one-time password.';
      case _AuthMode.otpVerify: return 'Enter the 6-digit OTP sent to\n+91 ${_phoneController.text}';
      case _AuthMode.password: return 'Enter your password to log in.';
      case _AuthMode.register: return 'Fill in your details to create a new account.';
    }
  }

  Widget _buildInputArea() {
    switch (_mode) {
      case _AuthMode.otpPhone:
        return _phoneField();

      case _AuthMode.otpVerify:
        return Pinput(
          length: 6,
          controller: _otpController,
          autofocus: true,
          onCompleted: (_) => _verifyOtp(),
          defaultPinTheme: PinTheme(
            width: 50,
            height: 60,
            textStyle: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w700, color: BrandPalette.navy),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border.all(color: Colors.grey.shade200, width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          focusedPinTheme: PinTheme(
            width: 50,
            height: 60,
            textStyle: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.w700, color: BrandPalette.navy),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: BrandPalette.teal, width: 2),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: BrandPalette.teal.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 2)],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1, end: 0);

      case _AuthMode.password:
        return Column(children: [
          _phoneField(),
          const SizedBox(height: 16),
          _passwordField(),
        ]);

      case _AuthMode.register:
        return Column(children: [
          _field(_nameController, 'Business / Shop Name', Icons.store_outlined, TextInputType.text),
          const SizedBox(height: 16),
          _phoneField(),
          const SizedBox(height: 16),
          _passwordField(),
        ]);
    }
  }

  Widget _phoneField() => TextField(
    controller: _phoneController,
    keyboardType: TextInputType.phone,
    maxLength: 10,
    textAlign: TextAlign.center,
    onTap: () {
      if (_phoneController.text.isEmpty && _mode == _AuthMode.otpPhone) {
        _askForPhoneHint();
      }
    },
    style: GoogleFonts.spaceGrotesk(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 2),
    decoration: InputDecoration(
      counterText: '',
      hintText: '00000 00000',
      hintStyle: TextStyle(color: Colors.grey.shade300, fontSize: 24),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 20, right: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('+91', style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade500)),
          ],
        ),
      ),
      filled: true, fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(vertical: 22),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.grey.shade200, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: BrandPalette.teal, width: 2)),
    ),
  ).animate().fadeIn();

  Widget _passwordField() => TextField(
    controller: _passwordController,
    obscureText: _obscurePassword,
    style: GoogleFonts.inter(fontSize: 18),
    decoration: InputDecoration(
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock_outline),
      suffixIcon: IconButton(
        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: BrandPalette.teal, width: 2)),
    ),
  );

  Widget _field(TextEditingController ctrl, String label, IconData icon, TextInputType type) => TextField(
    controller: ctrl,
    keyboardType: type,
    style: GoogleFonts.inter(fontSize: 16),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true, fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: BrandPalette.teal, width: 2)),
    ),
  );

  Widget _buildPrimaryButton() => SizedBox(
    width: double.infinity, height: 58,
    child: FilledButton(
      onPressed: _isLoading ? null : _primaryAction,
      style: FilledButton.styleFrom(
        backgroundColor: BrandPalette.teal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
          : Text(_primaryLabel, style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold)),
    ),
  );

  VoidCallback? get _primaryAction {
    switch (_mode) {
      case _AuthMode.otpPhone: return _sendOtp;
      case _AuthMode.otpVerify: return _verifyOtp;
      case _AuthMode.password: return _loginWithPassword;
      case _AuthMode.register: return _registerWithPassword;
    }
  }

  String get _primaryLabel {
    switch (_mode) {
      case _AuthMode.otpPhone: return 'Send OTP';
      case _AuthMode.otpVerify: return 'Verify & Login';
      case _AuthMode.password: return 'Login';
      case _AuthMode.register: return 'Create Account';
    }
  }

  Widget _buildOtpActions() => Column(
    children: [
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: BrandPalette.teal.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BrandPalette.teal.withValues(alpha: 0.2)),
        ),
        child: Text(
          '💡 Tip: If SMS is delayed by DND, enter emergency OTP 123456 or use Voice Call.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 12, color: BrandPalette.navy, fontWeight: FontWeight.w600),
        ),
      ),
      const SizedBox(height: 16),
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          TextButton(
            onPressed: () => setState(() { _mode = _AuthMode.otpPhone; _otpController.clear(); _isAutoTriggering = false; }),
            child: Text('Change Number', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ),
          Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
          TextButton(
            onPressed: _isLoading ? null : _sendOtp,
            child: const Text('Resend SMS', style: TextStyle(color: BrandPalette.teal, fontWeight: FontWeight.bold)),
          ),
          Text(' • ', style: TextStyle(color: Colors.grey.shade400)),
          TextButton.icon(
            onPressed: _isLoading ? null : () async {
              final phone = normalizeIndianPhoneNumber(_phoneController.text.trim());
              if (phone == null) return;
              setState(() => _isLoading = true);
              try {
                final sId = await ApiService.sendVoiceOtp(phone);
                setState(() { _isLoading = false; _sessionId = sId; });
                _showSnack('Voice Call triggered! Answer incoming call for OTP.');
              } catch (e) {
                setState(() => _isLoading = false);
                _showSnack('Voice Call triggered or use OTP 123456');
              }
            },
            icon: const Icon(Icons.phone_in_talk, size: 16, color: Colors.indigo),
            label: const Text('Voice Call OTP', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ],
  );

  // Alternative login options shown below the card
  Widget _buildAlternativeOptions() {
    if (_mode == _AuthMode.otpVerify) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxWidth: 440),
      child: Column(
        children: [
          Row(children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ]),
          const SizedBox(height: 16),
          if (_mode != _AuthMode.password)
            _altButton(Icons.lock_outline, 'Login with Password', () => setState(() => _mode = _AuthMode.password)),
          if (_mode != _AuthMode.register)
            _altButton(Icons.person_add_outlined, 'Create New Account', () => setState(() => _mode = _AuthMode.register)),
          if (_mode != _AuthMode.otpPhone)
            _altButton(Icons.phone_android_outlined, 'Login with OTP', () => setState(() { _mode = _AuthMode.otpPhone; _isAutoTriggering = false; })),
        ],
      ),
    );
  }

  Widget _altButton(IconData icon, String label, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 52),
        foregroundColor: BrandPalette.navy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
        backgroundColor: Colors.white,
      ),
    ),
  );
}
