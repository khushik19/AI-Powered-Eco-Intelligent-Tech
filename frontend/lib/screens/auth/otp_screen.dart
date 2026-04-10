import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../config/app_colors.dart';
import '../../widgets/cosmic_background.dart';
import '../../widgets/glass_card.dart';
import 'set_password_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  final Map<String, dynamic> userData;

  const OtpScreen({super.key, required this.email, required this.userData});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  // ── state ──────────────────────────────────────────────────────────────────
  String _otp = '';
  bool _isSending = true;   // waiting for SMS to be dispatched
  bool _isVerifying = false; // user tapped Verify
  String? _sendError;        // error while sending OTP
  String? _verifyError;      // error while verifying OTP

  // Web-specific: firebase returns ConfirmationResult
  ConfirmationResult? _confirmationResult;

  // Mobile-specific: verifyPhoneNumber gives us an ID
  String? _verificationId;

  // Resend cooldown
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  // ── helpers ────────────────────────────────────────────────────────────────

  /// Format phone to E.164 (+91XXXXXXXXXX).
  String get _formattedPhone {
    final raw = (widget.userData['phone'] as String? ?? '')
        .replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (raw.startsWith('+')) return raw;          // already has +
    if (raw.length == 10) return '+91$raw';       // Indian 10-digit
    if (raw.length > 10) return '+$raw';          // has country code, missing +
    return raw;
  }

  String get _maskedPhone {
    final p = _formattedPhone;
    if (p.length >= 4) {
      return '${p.substring(0, p.length - 4)}****';
    }
    return p;
  }

  @override
  void initState() {
    super.initState();
    _sendOtp();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ── OTP send ───────────────────────────────────────────────────────────────

  Future<void> _sendOtp() async {
    if (!mounted) return;
    setState(() {
      _isSending = true;
      _sendError = null;
    });

    try {
      if (kIsWeb) {
        // ── Web path ─────────────────────────────────────────────────────────
        // Firebase handles invisible reCAPTCHA automatically on web.
        _confirmationResult = await FirebaseAuth.instance
            .signInWithPhoneNumber(_formattedPhone);
        if (mounted) setState(() => _isSending = false);
      } else {
        // ── Mobile path ───────────────────────────────────────────────────────
        await FirebaseAuth.instance.verifyPhoneNumber(
          phoneNumber: _formattedPhone,
          // Android auto-verification
          verificationCompleted: (PhoneAuthCredential credential) async {
            await FirebaseAuth.instance.signInWithCredential(credential);
            if (mounted) _navigateNext();
          },
          verificationFailed: (FirebaseAuthException e) {
            if (mounted) {
              setState(() {
                _isSending = false;
                _sendError = e.message ?? 'Verification failed';
              });
            }
          },
          codeSent: (String verificationId, int? resendToken) {
            if (mounted) {
              setState(() {
                _verificationId = verificationId;
                _isSending = false;
              });
            }
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            _verificationId = verificationId;
          },
          timeout: const Duration(seconds: 60),
        );
      }

      // Start 60s resend cooldown
      _startCooldown();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendError = _friendlyError(e.code, e.message);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendError = e.toString();
        });
      }
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = 60);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _resendCooldown--;
        if (_resendCooldown <= 0) t.cancel();
      });
    });
  }

  // ── OTP verify ─────────────────────────────────────────────────────────────

  void _verify() async {
    if (_otp.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter the 6-digit OTP')),
      );
      return;
    }
    setState(() {
      _isVerifying = true;
      _verifyError = null;
    });

    try {
      if (kIsWeb) {
        // Web: confirm via ConfirmationResult
        if (_confirmationResult == null) {
          throw Exception('OTP not sent yet. Please wait or resend.');
        }
        await _confirmationResult!.confirm(_otp);
      } else {
        // Mobile: build credential and sign in
        if (_verificationId == null) {
          throw Exception('Verification ID missing. Please resend OTP.');
        }
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId!,
          smsCode: _otp,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (mounted) _navigateNext();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _verifyError = _friendlyError(e.code, e.message);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _verifyError = e.toString();
        });
      }
    }
  }

  void _navigateNext() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetPasswordScreen(userData: widget.userData),
      ),
    );
  }

  String _friendlyError(String code, String? message) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Use format: +91XXXXXXXXXX';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a few minutes.';
      case 'invalid-verification-code':
        return 'Wrong OTP code. Please check and try again.';
      case 'session-expired':
        return 'OTP expired. Please resend.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later.';
      case 'network-request-failed':
        return 'No internet connection.';
      default:
        return message ?? 'Something went wrong. Please try again.';
    }
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CosmicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios,
                      color: AppColors.textPrimary, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),

                // Title
                const Text(
                  'Verify\nYour Phone',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.2,
                  ),
                ).animate().fadeIn(),
                const SizedBox(height: 12),

                // Subtitle — shows sending state
                _isSending
                    ? Row(
                        children: [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.tealBlue,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Sending OTP to $_maskedPhone…',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(delay: 200.ms)
                    : _sendError != null
                        ? _ErrorBanner(
                            message: _sendError!,
                            onRetry: _sendOtp,
                          ).animate().fadeIn()
                        : Text(
                            'We sent a 6-digit code to\n$_maskedPhone',
                            style: const TextStyle(
                              fontFamily: 'Outfit',
                              fontSize: 15,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 48),

                // PIN input
                AbsorbPointer(
                  absorbing: _isSending || _sendError != null,
                  child: Opacity(
                    opacity: (_isSending || _sendError != null) ? 0.4 : 1.0,
                    child: PinCodeTextField(
                      appContext: context,
                      length: 6,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setState(() => _otp = v),
                      onCompleted: (v) {
                        setState(() => _otp = v);
                        _verify();
                      },
                      animationType: AnimationType.scale,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(12),
                        fieldHeight: 56,
                        fieldWidth: 48,
                        activeFillColor: AppColors.glassWhiteStrong,
                        selectedFillColor: AppColors.glassWhite,
                        inactiveFillColor: AppColors.glassWhite,
                        activeColor: AppColors.nebulaBlue,
                        selectedColor: AppColors.cosmicPurple,
                        inactiveColor: AppColors.glassBorder,
                      ),
                      enableActiveFill: true,
                      cursorColor: AppColors.nebulaBlue,
                      textStyle: const TextStyle(
                        fontFamily: 'Montserrat',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 8),

                // Verify error
                if (_verifyError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _verifyError!,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 12,
                        color: AppColors.dustyRose,
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Verify button
                _isVerifying
                    ? const Center(child: CircularProgressIndicator())
                    : GlassButton(
                        text: 'Verify & Continue',
                        icon: Icons.check_circle_outline,
                        onTap: (_isSending || _sendError != null)
                            ? () {} // disabled state — do nothing
                            : _verify,
                      ).animate().fadeIn(delay: 600.ms),

                const SizedBox(height: 12),

                // Resend button with cooldown
                Center(
                  child: TextButton(
                    onPressed: _resendCooldown > 0 || _isSending
                        ? null
                        : _sendOtp,
                    child: Text(
                      _resendCooldown > 0
                          ? 'Resend OTP in ${_resendCooldown}s'
                          : _isSending
                              ? 'Sending…'
                              : 'Resend OTP',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        color: _resendCooldown > 0 || _isSending
                            ? AppColors.textMuted
                            : AppColors.nebulaBlue,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Error Banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.dustyRose.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dustyRose.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.dustyRose, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Outfit',
                fontSize: 13,
                color: AppColors.dustyRose,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: AppColors.dustyRose,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}