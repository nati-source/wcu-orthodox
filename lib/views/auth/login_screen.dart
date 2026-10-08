import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.signInWithEmail(
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (mounted) {
        widget.onLoginSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().contains('user-not-found')
              ? 'No user found for that email.'
              : e.toString().contains('wrong-password')
                  ? 'Incorrect password.'
                  : 'Authentication error: ${e.toString().replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
        });
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
                        const SizedBox(height: 14),

                        // Test accounts helper chip - ONLY shown in Debug mode, never in production!
                        if (kDebugMode) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.azure.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.azure.withOpacity(0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.info_outline, size: 14, color: AppTheme.azure),
                                    SizedBox(width: 6),
                                    Text(
                                      'Test Accounts Credentials:',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.azure),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Admin: natisita928@gmail.com • admin12345',
                                  style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, height: 1.3),
                                ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    GestureDetector(
                                      onTap: () {
                                        _emailController.text = 'natisita928@gmail.com';
                                        _passwordController.text = 'admin12345';
                                        cooldownTimer?.cancel();
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text(
                                        '👉 Autofill Admin Sign-In',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.gold, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        _emailController.text = 'student@wcu.test';
                                        _passwordController.text = 'WcuStudent@2024';
                                        cooldownTimer?.cancel();
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text(
                                        '👉 Autofill Student Sign-In',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.gold, decoration: TextDecoration.underline),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
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

                                      // Development domain check
                                      if (email.toLowerCase().endsWith('@wcu.test')) {
                                        final defaultPass = email.toLowerCase().contains('admin')
                                            ? 'WcuAdmin@2024'
                                            : email.toLowerCase().contains('coord')
                                                ? 'WcuCoord@2024'
                                                : email.toLowerCase().contains('parent')
                                                    ? 'WcuParent@2024'
                                                    : 'WcuStudent@2024';
                                        _emailController.text = email;
                                        _passwordController.text = defaultPass;
                                        setDialogState(() {
                                          isSending = false;
                                          resetError = null;
                                          resetSuccessEmail = email;
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
                    // Orthodox Cross & Branding Icon
                    Container(
                      width: 80,
                      height: 80,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.goldGradient,
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.gold.withValues(alpha: 0.35),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.church_rounded,
                          size: 44,
                          color: Color(0xFF070F1E),
                        ),
                      ),
                    ),

                    // Title & Subtitle
                    const Text(
                      'WCU Orthodox Fellowship',
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
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
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
                          : const Text(
                              'Sign In / ግባ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                    const SizedBox(height: 18),

                    // Register Navigation Link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () {
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
                          child: const Text(
                            'Register / ተመዝገብ',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),

                    // Divider
                    const Row(
                      children: [
                        Expanded(child: Divider(color: AppTheme.borderMuted)),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('OR', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                        ),
                        Expanded(child: Divider(color: AppTheme.borderMuted)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Demo / Offline Mode Button
                    OutlinedButton.icon(
                      onPressed: widget.onSkipDemo,
                      icon: const Icon(Icons.offline_bolt_outlined, size: 18, color: AppTheme.slateMuted),
                      label: const Text(
                        'Continue in Local / Demo Mode',
                        style: TextStyle(color: AppTheme.slateMuted, fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: AppTheme.borderMuted),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
