import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentQrScannerScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentQrScannerScreen({super.key, required this.state});

  @override
  State<StudentQrScannerScreen> createState() => _StudentQrScannerScreenState();
}

class _StudentQrScannerScreenState extends State<StudentQrScannerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _pinInputController = TextEditingController();
  bool _isSuccess = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pinInputController.dispose();
    super.dispose();
  }

  void _verifyCheckIn(String pinOrCode, AttendanceCheckInMethod method) {
    final success = widget.state.checkInStudent(
      studentId: widget.state.currentUser.id,
      enteredPinOrCode: pinOrCode,
      method: method,
    );

    setState(() {
      _isSuccess = success;
      _statusMessage = success
          ? 'Attendance Verified! Marked Present for ${widget.state.activeSession.courseName}.'
          : 'Invalid or expired session PIN. Please verify with the class instructor.';
    });

    if (success) {
      HapticFeedback.mediumImpact();
      _showSuccessRippleDialog();
    }
  }

  void _showSuccessRippleDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Attendance Success',
      barrierColor: Colors.black.withOpacity(0.7),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return _QrSuccessRippleModal(
          student: widget.state.currentUser,
          session: widget.state.activeSession,
          onDismiss: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    final activeSession = widget.state.activeSession;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Live Attendance Check-In', style: TextStyle(color: textCol)),
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Active Course Info Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activeSession.courseCode,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryAccent,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.emeraldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.emerald.withOpacity(0.4)),
                        ),
                        child: const Text(
                          'SESSION ACTIVE',
                          style: TextStyle(fontSize: 10, color: AppTheme.emerald, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeSession.courseName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textCol),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeSession.faculty,
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Animated Scanner Viewport
            Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  color: isDark ? Colors.black : const Color(0xFF1A2230),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: primaryAccent.withOpacity(0.8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withOpacity(0.25),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Corner Borders
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                size: 100,
                                color: Colors.white.withOpacity(0.18),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Align with Session QR',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Laser Scan Line Animation
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Positioned(
                          top: 20 + (_animationController.value * 220),
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 2.5,
                            decoration: BoxDecoration(
                              color: primaryAccent,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryAccent.withOpacity(0.9),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    // Tap to simulate Instant QR scan
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            _verifyCheckIn(activeSession.code, AttendanceCheckInMethod.qr);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: Text(
                'Tap scanner viewport to scan dynamic QR code',
                style: TextStyle(color: textMuted.withOpacity(0.8), fontSize: 11),
              ),
            ),

            const SizedBox(height: 24),

            // OR: Enter Rolling 4-Digit PIN Code
            Row(
              children: [
                Expanded(child: Divider(color: borderCol)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR ENTER ROLLING PIN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: textMuted.withOpacity(0.7),
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: borderCol)),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _pinInputController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 4,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: primaryAccent,
                    ),
                    decoration: InputDecoration(
                      hintText: 'PIN',
                      counterText: '',
                      hintStyle: TextStyle(letterSpacing: 2, color: textMuted.withOpacity(0.5), fontSize: 16),
                      prefixIcon: Icon(Icons.pin, color: primaryAccent),
                      filled: true,
                      fillColor: cardBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderCol),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_pinInputController.text.trim().isNotEmpty) {
                        _verifyCheckIn(_pinInputController.text.trim(), AttendanceCheckInMethod.pin);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: Text(
                      'Verify',
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (_statusMessage != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isSuccess ? AppTheme.emeraldBg.withOpacity(0.4) : AppTheme.crimsonBg.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isSuccess ? AppTheme.emerald : AppTheme.crimson),
                ),
                child: Text(
                  _statusMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _isSuccess ? AppTheme.emerald : AppTheme.crimson,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _QrSuccessRippleModal extends StatefulWidget {
  final UserModel student;
  final AttendanceSessionModel session;
  final VoidCallback onDismiss;

  const _QrSuccessRippleModal({
    required this.student,
    required this.session,
    required this.onDismiss,
  });

  @override
  State<_QrSuccessRippleModal> createState() => _QrSuccessRippleModalState();
}

class _QrSuccessRippleModalState extends State<_QrSuccessRippleModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _scaleAnimation = Tween<double>(begin: 0.2, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _rippleController,
        curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: primaryAccent.withOpacity(0.5), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: primaryAccent.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ripple + Expanding Checkmark Container
                SizedBox(
                  height: 120,
                  width: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Expanding Golden Ring Ripples
                      AnimatedBuilder(
                        animation: _rippleAnimation,
                        builder: (context, child) {
                          final ringProgress = _rippleAnimation.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 70 + (ringProgress * 48),
                                height: 70 + (ringProgress * 48),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryAccent.withOpacity((1.0 - ringProgress).clamp(0.0, 1.0) * 0.8),
                                    width: 3 * (1.0 - ringProgress * 0.5),
                                  ),
                                ),
                              ),
                              Container(
                                width: 60 + (ringProgress * 28),
                                height: 60 + (ringProgress * 28),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: primaryAccent.withOpacity((1.0 - ringProgress).clamp(0.0, 1.0) * 0.5),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      // Central Checkmark Circle
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.emerald,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.emerald.withOpacity(0.4),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 42,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Success Title
                Text(
                  'Check-In Verified!',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryAccent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'የተማሪው የጥሪ ማረጋገጫ ተጠናቋል',
                  style: TextStyle(
                    fontSize: 13,
                    color: primaryAccent.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 18),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: elevatedBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Student', style: TextStyle(fontSize: 12, color: textMuted)),
                          Text(
                            widget.student.fullName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: textCol,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Baptismal Name', style: TextStyle(fontSize: 12, color: textMuted)),
                          Text(
                            widget.student.baptismalName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: primaryAccent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Course', style: TextStyle(fontSize: 12, color: textMuted)),
                          Flexible(
                            child: Text(
                              widget.session.courseName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textCol,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Done Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onDismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      'Done & Return',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isDark ? Colors.black : Colors.white,
                      ),
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
