import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/otp_service.dart';
import 'reset_password_screen.dart';

class VerifyOtpScreen extends StatefulWidget {
  final String email;

  const VerifyOtpScreen({super.key, required this.email});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  // Countdown timer for Resend button (60s)
  int _secondsRemaining = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsRemaining = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleResendOtp() async {
    if (_secondsRemaining > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final res = await OtpService.sendOtp(recipientEmail: widget.email);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (res['success'] == true) {
      _startTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mã OTP mới đã được gửi lại vào email của bạn!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _errorMessage = res['message'] ?? 'Gửi lại OTP thất bại.';
      });
    }
  }

  void _handleVerifyOtp() {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Vui lòng nhập đủ 6 chữ số mã OTP.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final isValid = OtpService.verifyOtp(widget.email, otp);
    setState(() => _isLoading = false);

    if (isValid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(
            email: widget.email,
            otp: otp,
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Mã OTP không chính xác hoặc đã hết hiệu lực. Vui lòng kiểm tra lại hộp thư.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Xác Thực OTP', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_outlined, size: 50, color: Colors.deepOrange),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Xác Nhận Mã OTP',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                children: [
                  const TextSpan(text: 'Vui lòng nhập mã OTP gồm 6 chữ số đã được gửi tới email:\n'),
                  TextSpan(
                    text: widget.email,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // 6-digit OTP Input field
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF1565C0), width: 1.5),
              ),
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 16,
                  color: Color(0xFF1565C0),
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  hintText: '••••••',
                  hintStyle: TextStyle(letterSpacing: 16, color: Colors.grey),
                  counterText: '',
                  border: InputBorder.none,
                ),
                onChanged: (val) {
                  if (val.trim().length == 6) {
                    _handleVerifyOtp();
                  }
                },
              ),
            ),
            const SizedBox(height: 16),

            // Resend Countdown
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_secondsRemaining > 0)
                  Text(
                    'Gửi lại mã sau $_secondsRemaining giây',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  )
                else
                  TextButton.icon(
                    onPressed: _isLoading ? null : _handleResendOtp,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text(
                      'Gửi lại mã OTP qua Gmail',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1565C0)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 28),

            // Verify Button
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleVerifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'XÁC THỰC MÃ OTP',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
