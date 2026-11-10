import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/constants/app_colors.dart';

class AuthPinSheet extends StatefulWidget {
  final VoidCallback onAuthenticated;

  const AuthPinSheet({super.key, required this.onAuthenticated});

  @override
  State<AuthPinSheet> createState() => _AuthPinSheetState();
}

class _AuthPinSheetState extends State<AuthPinSheet> {
  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuthentication();

  String _enteredPin = "";
  String? _savedPin;
  bool _isSettingPin = false;

  @override
  void initState() {
    super.initState();
    _checkSavedPin();
  }

  Future<void> _checkSavedPin() async {
    final pin = await _secureStorage.read(key: 'vault_pin');
    if (pin == null) {
      setState(() => _isSettingPin = true);
    } else {
      setState(() => _savedPin = pin);
      _authenticateBiometrics();
    }
  }

  Future<void> _authenticateBiometrics() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (canCheck) {
        final auth = await _localAuth.authenticate(
          localizedReason: 'প্রাইভেট ভল্ট আনলক করতে ফিঙ্গারপ্রিন্ট দিন',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (auth && mounted) {
          widget.onAuthenticated();
        }
      }
    } catch (_) {}
  }

  void _onKeyPress(String digit) {
    if (_enteredPin.length < 4) {
      setState(() => _enteredPin += digit);
      if (_enteredPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _handlePinComplete() async {
    if (_isSettingPin) {
      await _secureStorage.write(key: 'vault_pin', value: _enteredPin);
      widget.onAuthenticated();
    } else {
      if (_enteredPin == _savedPin) {
        widget.onAuthenticated();
      } else {
        setState(() => _enteredPin = "");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("ভুল পিন! পুনরায় চেষ্টা করুন।")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          Text(
            _isSettingPin ? "নতুন ৪-সংখ্যার ভল্ট পিন দিন" : "প্রাইভেট ভল্ট পিন লিখুন",
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // ৪-ডট পিন ইন্ডিকেটর
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isFilled = i < _enteredPin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isFilled ? AppColors.primary : AppColors.surfaceLight,
                ),
              );
            }),
          ),
          const SizedBox(height: 30),
          // ডায়াল প্যাড গ্রিড
          _buildKeypad(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _buildKeyRow(["1", "2", "3"]),
        const SizedBox(height: 12),
        _buildKeyRow(["4", "5", "6"]),
        const SizedBox(height: 12),
        _buildKeyRow(["7", "8", "9"]),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: const Icon(Icons.fingerprint_rounded, color: AppColors.primary, size: 32),
              onPressed: _authenticateBiometrics,
            ),
            _buildKey("0"),
            IconButton(
              icon: const Icon(Icons.backspace_rounded, color: AppColors.textSecondary, size: 26),
              onPressed: () {
                if (_enteredPin.isNotEmpty) {
                  setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
                }
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeyRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((k) => _buildKey(k)).toList(),
    );
  }

  Widget _buildKey(String label) {
    return InkWell(
      onTap: () => _onKeyPress(label),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
      ),
    );
  }
}