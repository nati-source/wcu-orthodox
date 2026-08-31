import 'package:flutter/material.dart';
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
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppTheme.emerald, size: 28),
              SizedBox(width: 10),
              Text(
                'Check-In Successful',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student: ${widget.state.currentUser.fullName} (${widget.state.currentUser.baptismalName})',
                style: const TextStyle(color: AppTheme.goldLight, fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Text(
                'Course: ${widget.state.activeSession.courseName}',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              const Text(
                'Method: Dynamic QR & Rolling PIN Validation',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 12),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.goldAccent),
              child: const Text('Done', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSession = widget.state.activeSession;

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text('Live Attendance Check-In'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppTheme.goldLight),
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
                color: AppTheme.secondaryBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderMuted),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        activeSession.courseCode,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.goldLight,
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
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    activeSession.faculty,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
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
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.goldAccent.withOpacity(0.8), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.goldAccent.withOpacity(0.25),
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
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
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
                              color: const Color(0xFFF5A65E),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF5A65E).withOpacity(0.9),
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
            const Center(
              child: Text(
                'Tap scanner viewport to scan dynamic QR code',
                style: TextStyle(color: AppTheme.textTertiary, fontSize: 11),
              ),
            ),

            const SizedBox(height: 24),

            // OR: Enter Rolling 4-Digit PIN Code
            Row(
              children: [
                Expanded(child: Divider(color: AppTheme.borderMuted)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'OR ENTER ROLLING PIN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textTertiary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: AppTheme.borderMuted)),
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
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Color(0xFFF5A65E),
                    ),
                    decoration: InputDecoration(
                      hintText: 'PIN',
                      counterText: '',
                      hintStyle: const TextStyle(letterSpacing: 2, color: AppTheme.textTertiary, fontSize: 16),
                      prefixIcon: const Icon(Icons.pin, color: AppTheme.goldAccent),
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
                      backgroundColor: AppTheme.goldAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    child: const Text(
                      'Verify',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 15),
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
