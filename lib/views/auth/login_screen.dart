import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/wcu_brand_logo.dart';
import '../onboarding/fellowship_onboarding_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onSkipDemo;
  final FellowshipState? state;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onSkipDemo,
    this.state,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  int _failedAttempts = 0;
  int _lockoutSecondsRemaining = 0;
  Timer? _lockoutTimer;

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startLockoutTimer() {
    setState(() {
      _lockoutSecondsRemaining = 30;
      _errorMessage = 'Too many failed login attempts. Please wait 30 seconds before trying again / በርካታ ያልተሳኩ ሙከራዎች ተደርገዋል: እባክዎ 30 ሰከንድ ይጠብቁ።';
    });
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_lockoutSecondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _lockoutSecondsRemaining = 0;
          _failedAttempts = 0;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _lockoutSecondsRemaining--;
        });
      }
    });
  }

  Future<void> _handleLogin() async {
    if (_lockoutSecondsRemaining > 0 || _isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      _failedAttempts = 0;
      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          _startLockoutTimer();
        } else {
          setState(() {
            final remainingTries = 5 - _failedAttempts;
            final baseError = e.toString().contains('user-not-found')
                ? 'No user found for that email.'
                : e.toString().contains('wrong-password')
                    ? 'Incorrect password.'
                    : 'Authentication error: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
            _errorMessage = '$baseError ($remainingTries attempts remaining / $remainingTries ሙከራዎች ቀርተዋል)';
          });
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openForgotPasswordDialog() {
    final emailResetController = TextEditingController(text: _emailController.text.trim());
    bool isSending = false;
    String? resetError;
    String? resetSuccessEmail;
    String? accountWarning;
    int resendCooldown = 0;
    Timer? cooldownTimer;

    showDialog(
      context: context,
      barrierDismissible: !isSending,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void startCooldown() {
              resendCooldown = 30;
              cooldownTimer?.cancel();
              cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
                if (resendCooldown <= 1) {
                  timer.cancel();
                  if (ctx.mounted) {
                    setDialogState(() {
                      resendCooldown = 0;
                    });
                  }
                } else {
                  if (ctx.mounted) {
                    setDialogState(() {
                      resendCooldown--;
                    });
                  }
                }
              });
            }

            Future<void> executeSendReset(String email) async {
              setDialogState(() {
                isSending = true;
                resetError = null;
                accountWarning = null;
              });

              try {
                await _authService.sendPasswordResetEmail(email);

                setDialogState(() {
                  isSending = false;
                  resetSuccessEmail = email;
                  resetError = null;
                });
                startCooldown();
              } catch (e) {
                setDialogState(() {
                  isSending = false;
                  final errStr = e.toString();
                  if (errStr.contains('user-not-found')) {
                    resetError = 'No registered account found with that email address. Please check your spelling or register.';
                  } else if (errStr.contains('invalid-email')) {
                    resetError = 'Please enter a valid email address.';
                  } else if (errStr.contains('too-many-requests')) {
                    resetError = 'Too many requests. Please wait a few moments before trying again.';
                  } else if (errStr.contains('network-request-failed')) {
                    resetError = 'Network error. Please check your internet connection and try again.';
                  } else {
                    resetError = 'Error: ${errStr.replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
                  }
                });
              }
            }

            final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
            return Dialog(
              backgroundColor: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: AppTheme.borderMuted),
              ),
              insetPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: keyboardHeight > 0 ? 12 : 24,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.lock_reset, color: AppTheme.gold, size: 24),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reset Password',
                                  style: TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'የይለፍ ቃል መልሶ ማግኛ',
                                  style: TextStyle(
                                    color: AppTheme.gold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: AppTheme.textSecondary, size: 20),
                            onPressed: () {
                              cooldownTimer?.cancel();
                              Navigator.pop(ctx);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (resetSuccessEmail == null) ...[
                        // Input State
                        const Text(
                          'Enter your registered email address to receive a secure password reset link from Firebase.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4),
                        ),
                        const SizedBox(height: 16),

                        if (resetError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.crimsonBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.crimson),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppTheme.crimson, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    resetError!,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        TextFormField(
                          controller: emailResetController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Email Address / ኢሜይል',
                            labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.gold, size: 20),
                            filled: true,
                            fillColor: AppTheme.primaryBg,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
                            ),
                          ),
                        ),
                        // Test accounts helper chip - ONLY shown in Debug mode, never in production!
                        if (kDebugMode) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceTile,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Test Accounts Credentials:',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.gold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        emailResetController.text = 'admin@wcuorthodox.org';
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.gold.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                                        ),
                                        child: const Text(
                                          'Autofill Admin',
                                          style: TextStyle(fontSize: 11, color: AppTheme.gold, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        emailResetController.text = 'student@wcuorthodox.org';
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.gold.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                                        ),
                                        child: const Text(
                                          'Autofill Student',
                                          style: TextStyle(fontSize: 11, color: AppTheme.gold, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],


                        // Action Buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                cooldownTimer?.cancel();
                                Navigator.pop(ctx);
                              },
                              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: isSending
                                  ? null
                                  : () async {
                                      final email = emailResetController.text.trim();
                                      if (email.isEmpty || !email.contains('@')) {
                                        setDialogState(() {
                                          resetError = 'Please enter a valid email address.';
                                        });
                                        return;
                                      }

                                      await executeSendReset(email);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.gold,
                                foregroundColor: const Color(0xFF070F1E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              child: isSending
                                  ? const SizedBox(
                                      height: 16,
                                      width: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF070F1E)),
                                    )
                                  : const Text(
                                      'Send Reset Link',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // Success & Resend State
                        if (resetError != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.crimsonBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.crimson),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppTheme.crimson, size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    resetError!,
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Reset Link Dispatched!',
                                      style: const TextStyle(
                                        color: Color(0xFF10B981),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              RichText(
                                text: TextSpan(
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary, height: 1.4),
                                  children: [
                                    const TextSpan(text: 'We sent a password reset email to:\n'),
                                    TextSpan(
                                      text: resetSuccessEmail!,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.gold),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Notice if email was test domain
                        if (resetSuccessEmail!.toLowerCase().endsWith('@wcu.test')) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.azure.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.azure),
                            ),
                            child: const Text(
                              '💡 Note: This is a local development account that does not receive external emails. Credentials have been autofilled on the sign-in form.',
                              style: TextStyle(fontSize: 11, color: AppTheme.azure, height: 1.3),
                            ),
                          ),
                          const SizedBox(height: 14),
                        ] else ...[
                          // Real email guidance
                          if (accountWarning != null) ...[
                            Container(
                              padding: const EdgeInsets.all(10),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.amber),
                              ),
                              child: Text(
                                accountWarning!,
                                style: const TextStyle(fontSize: 11, color: Colors.amber, height: 1.3),
                              ),
                            ),
                          ],

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBg,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderMuted),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.mark_email_unread_outlined, size: 16, color: AppTheme.gold),
                                    SizedBox(width: 8),
                                    Text(
                                      'Cannot find the reset email?',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '1. ⚠️ Check your Spam / Junk / Promotions folder.\n'
                                  '2. Google Firebase sends from: noreply@wcu-orthodox.firebaseapp.com\n'
                                  '3. Search your inbox for "wcu-orthodox" or "Firebase".',
                                  style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, height: 1.45),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Open Email App button
                          OutlinedButton.icon(
                            onPressed: () async {
                              final emailUri = Uri.parse('mailto:');
                              try {
                                if (await canLaunchUrl(emailUri)) {
                                  await launchUrl(emailUri);
                                }
                              } catch (_) {}
                            },
                            icon: const Icon(Icons.open_in_new, size: 16, color: AppTheme.azure),
                            label: const Text('Open Email App / ኢሜይል ክፈት', style: TextStyle(fontSize: 12, color: AppTheme.azure)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: AppTheme.azure.withOpacity(0.5)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        // Resend and Done Buttons
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Resend button with active cooldown
                            TextButton.icon(
                              onPressed: (isSending || resendCooldown > 0)
                                  ? null
                                  : () async {
                                      await executeSendReset(resetSuccessEmail!);
                                    },
                              icon: isSending
                                  ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                                  : const Icon(Icons.refresh, size: 16),
                              label: Text(
                                resendCooldown > 0
                                    ? 'Resend Link in ${resendCooldown}s'
                                    : 'Resend Reset Link / እንደገና ላክ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: resendCooldown > 0 ? AppTheme.textSecondary : AppTheme.gold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            ElevatedButton(
                              onPressed: () {
                                cooldownTimer?.cancel();
                                Navigator.pop(ctx);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.gold,
                                foregroundColor: const Color(0xFF070F1E),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Done / ተመለስ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      cooldownTimer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Interactive Orthodox cross-and-book brand mark.
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: WcuBrandLogo(
                          markSize: 86,
                          showName: false,
                          showAmharic: false,
                          onTap: () => showAboutDialog(
                            context: context,
                            applicationName: 'WCU Gibi Gubae',
                            applicationVersion: '1.3.6',
                            applicationLegalese:
                                'Wachemo University Orthodox Fellowship\nየዋቸሞ ዩኒቨርሲቲ ግቢ ጉባኤ',
                            children: const [
                              Text('Faith • Fellowship • Service'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Title & Subtitle
                    const Text(
                      'WCU Gibi Gubae',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'የዋቸሞ ዩኒቨርሲቲ ግቢ ጉባኤ መተግበሪያ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.gold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Error Message Banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.crimsonBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.crimson),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.crimson, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.gold),
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderMuted),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderMuted),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.gold, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Please enter your email';
                        if (!val.contains('@')) return 'Enter a valid email address';
                        return null;
                      },
                    ),
                    const SizedBox(height: 18),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.gold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderMuted),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderMuted),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.gold, width: 2),
                        ),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Please enter your password';
                        if (val.length < 6) return 'Password must be at least 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    // Forgot Password Link
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _openForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forgot Password? / የይለፍ ቃል ረሱ?',
                          style: TextStyle(
                            color: AppTheme.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Sign In Button
                    Semantics(
                      button: true,
                      label: _lockoutSecondsRemaining > 0
                          ? 'Sign In locked for $_lockoutSecondsRemaining seconds'
                          : 'Sign In button',
                      child: ElevatedButton(
                        onPressed: (_isLoading || _lockoutSecondsRemaining > 0) ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lockoutSecondsRemaining > 0 ? Colors.grey.shade700 : AppTheme.gold,
                          foregroundColor: const Color(0xFF070F1E),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF070F1E)),
                              )
                            : Text(
                                _lockoutSecondsRemaining > 0
                                    ? 'Locked (${_lockoutSecondsRemaining}s) / ተቆልፏል'
                                    : 'Sign In / ግባ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _lockoutSecondsRemaining > 0 ? Colors.white60 : const Color(0xFF070F1E),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Divider with 'OR / ወይም'
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.borderMuted)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'OR / ወይም',
                            style: TextStyle(
                              color: AppTheme.textTertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppTheme.borderMuted)),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Prominent Interactive Registration Card & Button
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.surfaceElevated,
                            AppTheme.gold.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.4),
                          width: 1.4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.gold.withValues(alpha: 0.16),
                                  border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
                                ),
                                child: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: AppTheme.gold,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Register First If You Don\'t Have An Account',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary,
                                        height: 1.25,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'አካውንት ከሌለዎት መጀመሪያ ይመዝገቡ • Join our community',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.gold,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 50,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RegisterScreen(
                                      state: widget.state,
                                      onRegisterSuccess: widget.onLoginSuccess,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.app_registration_rounded, size: 20),
                              label: const Text(
                                'Register Now • አሁኑኑ ይመዝገቡ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.gold,
                                foregroundColor: const Color(0xFF070F1E),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Interactive Sacred Tour & Feature Intro Card (Inspired by reference Bible app)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE5A93C).withOpacity(0.12),
                            const Color(0xFF10B981).withOpacity(0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.gold.withOpacity(0.3), width: 1.0),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.gold.withOpacity(0.15),
                            border: Border.all(color: AppTheme.gold.withOpacity(0.5), width: 1),
                          ),
                          child: const Icon(Icons.auto_awesome, color: AppTheme.gold, size: 18),
                        ),
                        title: const Text(
                          'Sacred App Tour & Feature Intro',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.gold),
                        ),
                        subtitle: const Text(
                          'የመተግበሪያውን አገልግሎቶች ይጎብኙ • Explore Church Ministries & Lectionary',
                          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 13, color: AppTheme.gold),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FellowshipOnboardingScreen(
                                state: widget.state ?? FellowshipState(),
                                onFinish: () {
                                  Navigator.pop(context);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => RegisterScreen(
                                        state: widget.state,
                                        onRegisterSuccess: widget.onLoginSuccess,
                                      ),
                                    ),
                                  );
                                },
                                onSignIn: () => Navigator.pop(context),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
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
