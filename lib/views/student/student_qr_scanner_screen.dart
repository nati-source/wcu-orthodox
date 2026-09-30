import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentQrScannerScreen extends StatefulWidget {
  final FellowshipState state;
  final int initialMode; // 0: Attendance, 1: Pilgrimage Pass

  const StudentQrScannerScreen({
    super.key,
    required this.state,
    this.initialMode = 0,
  });

  @override
  State<StudentQrScannerScreen> createState() => _StudentQrScannerScreenState();
}

class _StudentQrScannerScreenState extends State<StudentQrScannerScreen>
    with SingleTickerProviderStateMixin {
  late int _activeScannerTab;
  late AnimationController _animationController;
  final TextEditingController _pinInputController = TextEditingController();
  final TextEditingController _ticketInputController = TextEditingController();
  
  MobileScannerController? _cameraController;
  DateTime? _lastScanTime;

  bool _isSuccess = false;
  String? _statusMessage;
  bool _isTorchOn = false;

  bool get _canScanPilgrims => widget.state.canManagePilgrimages || widget.state.isAdmin;

  @override
  void initState() {
    super.initState();
    _activeScannerTab = _canScanPilgrims ? widget.initialMode : 0;
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    if (_activeScannerTab == 1 && _canScanPilgrims) {
      _startCamera();
    }
  }

  @override
  void didUpdateWidget(StudentQrScannerScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialMode != widget.initialMode) {
      if (_canScanPilgrims) {
        _switchTab(widget.initialMode);
      } else {
        _switchTab(0);
      }
    }
  }

  void _startCamera() {
    _cameraController ??= MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  void _stopCamera() {
    _cameraController?.dispose();
    _cameraController = null;
    _isTorchOn = false;
  }

  void _switchTab(int newIndex) {
    if (_activeScannerTab == newIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _activeScannerTab = newIndex;
      _statusMessage = null;
      if (newIndex == 1 && _canScanPilgrims) {
        _startCamera();
      } else {
        _stopCamera();
      }
    });
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    if (_activeScannerTab == 1 && _cameraController != null) {
      _cameraController!.toggleTorch();
    }
    HapticFeedback.selectionClick();
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (_activeScannerTab != 1) return;
    final now = DateTime.now();
    if (_lastScanTime != null && now.difference(_lastScanTime!).inMilliseconds < 1500) {
      return;
    }

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue ?? barcode.displayValue;
      if (code != null && code.trim().isNotEmpty) {
        _lastScanTime = now;
        _verifyPilgrimPassScan(code.trim());
        break;
      }
    }
  }

  @override
  void dispose() {
    _stopCamera();
    _animationController.dispose();
    _pinInputController.dispose();
    _ticketInputController.dispose();
    super.dispose();
  }

  void _verifyAttendanceCheckIn(String pinOrCode, AttendanceCheckInMethod method) {
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
      _showAttendanceSuccessDialog();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _verifyPilgrimPassScan(String qrTicketCode) {
    final cleanCode = qrTicketCode.trim().toUpperCase();
    final allTrips = widget.state.allTripRegistrations;
    final match = allTrips.where(
      (r) => r.qrTicketCode.trim().toUpperCase() == cleanCode || r.transactionReference.trim().toUpperCase() == cleanCode,
    ).toList();

    if (match.isNotEmpty) {
      final reg = match.first;
      widget.state.scanBusBoardingTicket(reg.qrTicketCode);

      setState(() {
        _isSuccess = true;
        _statusMessage = 'Boarding Verified: ${reg.studentName} (Bus #${reg.busNumber}, Seat #${reg.seatNumber})';
      });

      HapticFeedback.mediumImpact();
      _showPilgrimBoardingSuccessDialog(reg);
    } else {
      setState(() {
        _isSuccess = false;
        _statusMessage = 'Ticket code "$cleanCode" not found in active bus passenger manifest.';
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _simulatePilgrimScan() {
    final allTrips = widget.state.allTripRegistrations;
    if (allTrips.isNotEmpty) {
      _verifyPilgrimPassScan(allTrips.first.qrTicketCode);
    } else {
      _verifyPilgrimPassScan('WCU-PILGRIM-001');
    }
  }

  void _showAttendanceSuccessDialog() {
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

  void _showPilgrimBoardingSuccessDialog(TripRegistrationModel reg) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(color: theme.dividerColor, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.emerald.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.emerald.withOpacity(0.4)),
                ),
                child: const Icon(Icons.verified, color: AppTheme.emerald, size: 36),
              ),
              const SizedBox(height: 12),
              Text(
                'Pilgrim Boarding Pass Verified!',
                style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: textCol),
              ),
              Text(
                'የጉዞና አውቶቡስ ትኬት በተሳካ ሁኔታ ተረጋግጧል',
                style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    _buildModalRow('Passenger:', reg.studentName, textCol),
                    const SizedBox(height: 6),
                    _buildModalRow('Baptismal Name:', reg.studentBaptismalName, primaryAccent),
                    const SizedBox(height: 6),
                    _buildModalRow('Trip Destination:', reg.tripTitle, textCol),
                    const SizedBox(height: 6),
                    _buildModalRow('Bus & Seat Assignment:', 'Bus #${reg.busNumber} • Seat #${reg.seatNumber}', AppTheme.emerald),
                    const SizedBox(height: 6),
                    _buildModalRow('Payment Status:', reg.paymentStatus.displayName, AppTheme.emerald),
                    const SizedBox(height: 6),
                    _buildModalRow('Ticket Code:', reg.qrTicketCode, primaryAccent),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Confirm Boarding / እሺ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalRow(String label, String value, Color valColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    final activeSession = widget.state.activeSession;
    final trips = widget.state.pilgrimageTrips;
    final allRegistrations = widget.state.allTripRegistrations;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _activeScannerTab == 0 ? 'Live Attendance Scanner' : 'Pilgrim Pass Boarding Scanner',
          style: TextStyle(color: textCol, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            tooltip: _isTorchOn ? 'Turn Flash Off' : 'Turn Flash On',
            icon: Icon(
              _isTorchOn ? Icons.flash_on : Icons.flash_off,
              color: _isTorchOn ? Colors.amber : textMuted,
            ),
            onPressed: _toggleTorch,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode Selector Segmented Control (Visible strictly to Batch Coordinators & Admins)
            if (_canScanPilgrims) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderCol),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildScannerModeTab(
                        index: 0,
                        label: 'Course Attendance',
                        amharicLabel: 'የትምህርት መገኘት',
                        icon: Icons.school_outlined,
                        isActive: _activeScannerTab == 0,
                        primaryAccent: primaryAccent,
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: _buildScannerModeTab(
                        index: 1,
                        label: 'Pilgrim Pass',
                        amharicLabel: 'የጉዞ ትኬት (ባች)',
                        icon: Icons.directions_bus_outlined,
                        isActive: _activeScannerTab == 1,
                        primaryAccent: primaryAccent,
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Active Context Badge
            if (_activeScannerTab == 0) ...[
              // Attendance Session Details
              Container(
                padding: const EdgeInsets.all(14),
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
                        Expanded(
                          child: Text(
                            activeSession.courseCode,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: primaryAccent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textCol),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      activeSession.faculty,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Pilgrim Pass Scanner Header
              Container(
                padding: const EdgeInsets.all(14),
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
                        Expanded(
                          child: Text(
                            'ባችና መርሐ ግብራት ማስተባበሪያ',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryAccent,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryAccent.withOpacity(0.4)),
                          ),
                          child: Text(
                            '${allRegistrations.length} Registrations',
                            style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      trips.isNotEmpty ? trips.first.title : 'St. Gabriel Kulubi Pilgrimage',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textCol),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scan passenger QR codes with camera to verify seat & bus boarding.',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // High-Tech Scanner Viewport
            Center(
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF0A0E1A)]
                        : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: _isTorchOn ? Colors.amber.withOpacity(0.8) : primaryAccent.withOpacity(0.7),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_isTorchOn ? Colors.amber : primaryAccent).withOpacity(0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Stack(
                    children: [
                      // Mode 1: Real Camera Feed for Pilgrim Pass
                      if (_activeScannerTab == 1 && _cameraController != null)
                        Positioned.fill(
                          child: MobileScanner(
                            controller: _cameraController!,
                            onDetect: _handleBarcodeDetection,
                            errorBuilder: (context, error, child) {
                              final isDenied = error.errorCode == MobileScannerErrorCode.permissionDenied;
                              final isUnsupported = error.errorCode == MobileScannerErrorCode.unsupported;
                              final message = isDenied
                                  ? 'Camera permission denied.\nPlease enable Camera permission in device settings or tap Retry.'
                                  : isUnsupported
                                      ? 'Camera feed unavailable on this platform/device (Windows/Emulator).\nPlease use manual ticket code below or tap Simulate.'
                                      : 'Camera feed unavailable: ${error.errorDetails?.message ?? error.errorCode.name}\nPlease retry or enter ticket code below.';

                              return Container(
                                color: const Color(0xFF0F172A),
                                padding: const EdgeInsets.all(16),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.videocam_off_outlined, color: Colors.white54, size: 36),
                                      const SizedBox(height: 8),
                                      Text(
                                        message,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        alignment: WrapAlignment.center,
                                        spacing: 8,
                                        runSpacing: 6,
                                        children: [
                                          TextButton.icon(
                                            onPressed: () {
                                              _stopCamera();
                                              _startCamera();
                                              setState(() {});
                                            },
                                            icon: const Icon(Icons.refresh, size: 16, color: Colors.amber),
                                            label: const Text('Retry Camera', style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                          TextButton.icon(
                                            onPressed: _simulatePilgrimScan,
                                            icon: const Icon(Icons.flash_on, size: 16, color: Color(0xFF10B981)),
                                            label: const Text('Simulate Scan', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      else
                        // Mode 0: Fast Simulated Viewfinder for Course Attendance
                        Positioned.fill(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    size: 84,
                                    color: Colors.white.withOpacity(0.25),
                                  ),
                                  const SizedBox(height: 10),
                                  const Text(
                                    'Align Session Attendance QR',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Tap viewfinder to trigger instant scan',
                                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // Corner HUD Brackets
                      Positioned(
                        top: 14,
                        left: 14,
                        child: _buildCornerReticle(primaryAccent, 0),
                      ),
                      Positioned(
                        top: 14,
                        right: 14,
                        child: _buildCornerReticle(primaryAccent, 1),
                      ),
                      Positioned(
                        bottom: 14,
                        left: 14,
                        child: _buildCornerReticle(primaryAccent, 2),
                      ),
                      Positioned(
                        bottom: 14,
                        right: 14,
                        child: _buildCornerReticle(primaryAccent, 3),
                      ),

                      // Animated Laser Sweep Line
                      AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Positioned(
                            top: 24 + (_animationController.value * 220),
                            left: 20,
                            right: 20,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: _isTorchOn ? Colors.amber : primaryAccent,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isTorchOn ? Colors.amber : primaryAccent).withOpacity(0.9),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Tap trigger for Attendance (or test simulation)
                      if (_activeScannerTab == 0)
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(28),
                              onTap: () {
                                _verifyAttendanceCheckIn(activeSession.code, AttendanceCheckInMethod.qr);
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),
            Center(
              child: Text(
                _activeScannerTab == 0
                    ? 'Scan live session screen or enter rolling PIN below'
                    : 'Aim camera at passenger ticket QR or enter ticket code below',
                style: TextStyle(color: textMuted.withOpacity(0.8), fontSize: 11),
              ),
            ),

            const SizedBox(height: 20),

            // Manual Code Input Section
            if (_activeScannerTab == 0) ...[
              // Attendance: Enter 4-Digit Rolling PIN
              Row(
                children: [
                  Expanded(child: Divider(color: borderCol)),
                  Flexible(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR ENTER ROLLING 4-DIGIT PIN',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textMuted.withOpacity(0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: borderCol)),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _pinInputController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 4,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 6,
                        color: primaryAccent,
                      ),
                      decoration: InputDecoration(
                        hintText: 'PIN',
                        counterText: '',
                        hintStyle: TextStyle(letterSpacing: 2, color: textMuted.withOpacity(0.5), fontSize: 15),
                        prefixIcon: Icon(Icons.pin, color: primaryAccent, size: 20),
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderCol),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_pinInputController.text.trim().isNotEmpty) {
                          _verifyAttendanceCheckIn(_pinInputController.text.trim(), AttendanceCheckInMethod.pin);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      child: Text(
                        'Check In',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Pilgrim Pass: Enter Ticket / Ref Code
              Row(
                children: [
                  Expanded(child: Divider(color: borderCol)),
                  Flexible(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR ENTER TICKET / REF CODE',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: textMuted.withOpacity(0.7),
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: borderCol)),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ticketInputController,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textCol,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g. PILGRIM-TRIP-8421',
                        hintStyle: TextStyle(color: textMuted.withOpacity(0.5), fontSize: 13),
                        prefixIcon: Icon(Icons.confirmation_number_outlined, color: primaryAccent, size: 20),
                        filled: true,
                        fillColor: cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: borderCol),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_ticketInputController.text.trim().isNotEmpty) {
                          _verifyPilgrimPassScan(_ticketInputController.text.trim());
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: Text(
                        'Verify Pass',
                        style: TextStyle(
                          color: isDark ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],

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

  Widget _buildScannerModeTab({
    required int index,
    required String label,
    required String amharicLabel,
    required IconData icon,
    required bool isActive,
    required Color primaryAccent,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => _switchTab(index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isActive ? (isDark ? Colors.black : Colors.white) : primaryAccent,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? (isDark ? Colors.black : Colors.white) : AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              amharicLabel,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? (isDark ? Colors.black87 : Colors.white70)
                    : AppTheme.textSecondary.withOpacity(0.7),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCornerReticle(Color color, int corner) {
    // 0: Top-Left, 1: Top-Right, 2: Bottom-Left, 3: Bottom-Right
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        border: Border(
          top: (corner == 0 || corner == 1) ? BorderSide(color: color, width: 3) : BorderSide.none,
          bottom: (corner == 2 || corner == 3) ? BorderSide(color: color, width: 3) : BorderSide.none,
          left: (corner == 0 || corner == 2) ? BorderSide(color: color, width: 3) : BorderSide.none,
          right: (corner == 1 || corner == 3) ? BorderSide(color: color, width: 3) : BorderSide.none,
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
