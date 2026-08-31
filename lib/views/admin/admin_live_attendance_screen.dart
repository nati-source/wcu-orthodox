import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminLiveAttendanceScreen extends StatelessWidget {
  final FellowshipState state;

  const AdminLiveAttendanceScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final session = state.activeSession;
    final countdown = state.pinCountdownSeconds;

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Screen Header matching mangment2 - Copy.png
              const Text(
                'Live Attendance',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF7CA88),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                session.courseCode,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // Present vs Total Enrolled Top Stats Bar matching mangment2 - Copy.png
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderMuted),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRESENT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session.scans.length}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF5A65E),
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 40, color: AppTheme.borderMuted),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'TOTAL ENROLLED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textTertiary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${session.totalEnrolled}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SCAN TO CHECK IN Card with Dynamic QR & Rolling PIN matching mangment2 - Copy.png
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppTheme.borderMuted),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'SCAN TO CHECK IN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF5A65E),
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Dynamic QR Code Container
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.goldAccent.withOpacity(0.3),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: session.code,
                        version: QrVersions.auto,
                        size: 160,
                        backgroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text(
                      'PIN Code',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textTertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Large 4-Digit Rolling PIN (e.g. 8421)
                    Text(
                      session.rollingPin,
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 44,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFFF5A65E),
                        letterSpacing: 8.0,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Countdown Refresh Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: countdown / 30.0,
                        minHeight: 4,
                        backgroundColor: AppTheme.surfaceElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE57E12)),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Refreshes in ${countdown}s',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Scans Feed matching mangment2 - Copy.png
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Scans',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: const Text('View All', style: TextStyle(color: AppTheme.goldLight, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              ...session.scans.map((scan) {
                final timeFormatted = DateFormat('hh:mm a').format(scan.timestamp);
                final initials = scan.studentName
                    .split(' ')
                    .take(2)
                    .map((s) => s.isNotEmpty ? s[0] : '')
                    .join();

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderMuted),
                  ),
                  child: Row(
                    children: [
                      // Avatar with initials
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF2E261E),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFF7CA88),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Name & Time
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scan.studentName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeFormatted,
                              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                            ),
                          ],
                        ),
                      ),

                      // Check-In Method Badge (QR or PIN)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF222B3A),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderMuted),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              scan.method == AttendanceCheckInMethod.qr
                                  ? Icons.qr_code
                                  : Icons.pin,
                              color: AppTheme.goldLight,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              scan.method == AttendanceCheckInMethod.qr ? 'QR' : 'PIN',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.goldLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
