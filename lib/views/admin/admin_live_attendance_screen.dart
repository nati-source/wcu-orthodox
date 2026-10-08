import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminLiveAttendanceScreen extends StatelessWidget {
  final FellowshipState state;
  final VoidCallback? onBackPressed;

  const AdminLiveAttendanceScreen({super.key, required this.state, this.onBackPressed});

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

    final session = state.activeSession;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Live Attendance', style: TextStyle(color: textCol, fontFamily: 'serif', fontWeight: FontWeight.bold)),
        backgroundColor: cardBg,
        elevation: 0,
        leading: (Navigator.canPop(context) || onBackPressed != null)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
                onPressed: () {
                  if (onBackPressed != null) {
                    onBackPressed!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Screen Header Subtitle
              Text(
                'Course Code: ${session.courseCode} • ${session.courseName}',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),

              // Present vs Total Enrolled Top Stats Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRESENT',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: textMuted.withOpacity(0.7),
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${session.scans.length}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: primaryAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: borderCol),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'TOTAL ENROLLED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: textMuted.withOpacity(0.7),
                              letterSpacing: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${session.totalEnrolled}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textCol,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // SCAN TO CHECK IN Card with Dynamic QR & Rolling PIN
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'SCAN TO CHECK IN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: primaryAccent,
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
                            color: primaryAccent.withOpacity(0.3),
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
                    Text(
                      'PIN Code',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: textMuted.withOpacity(0.7),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Large 4-Digit Rolling PIN (e.g. 8421)
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        session.rollingPin,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 44,
                          fontWeight: FontWeight.w900,
                          color: primaryAccent,
                          letterSpacing: 8.0,
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Countdown Refresh Progress Bar
                    ValueListenableBuilder<int>(
                      valueListenable: state.pinCountdownNotifier,
                      builder: (context, pinCount, _) {
                        return Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pinCount / 30.0,
                                minHeight: 4,
                                backgroundColor: elevatedBg,
                                valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Refreshes in ${pinCount}s',
                              style: TextStyle(
                                fontSize: 11,
                                color: textMuted,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Recent Scans Feed
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Recent Scans',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    child: Text('View All', style: TextStyle(color: primaryAccent, fontSize: 12)),
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
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderCol),
                  ),
                  child: Row(
                    children: [
                      // Avatar with initials
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: elevatedBg,
                        child: Text(
                          initials,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryAccent,
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
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textCol,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeFormatted,
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ],
                        ),
                      ),

                      // Check-In Method Badge (QR or PIN)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: elevatedBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: borderCol),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              scan.method == AttendanceCheckInMethod.qr
                                  ? Icons.qr_code
                                  : Icons.pin,
                              color: primaryAccent,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              scan.method == AttendanceCheckInMethod.qr ? 'QR' : 'PIN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: primaryAccent,
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
