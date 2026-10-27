import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminLiveAttendanceScreen extends StatelessWidget {
  final FellowshipState state;
  final VoidCallback? onBackPressed;

  const AdminLiveAttendanceScreen({
    super.key,
    required this.state,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final theme = Theme.of(context);
        final primaryAccent = theme.colorScheme.primary;
        final textCol = theme.colorScheme.onSurface;
        final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
        final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
        final elevatedBg = theme.colorScheme.surfaceContainerHighest;
        final borderCol = theme.dividerColor;
        final isDark = theme.brightness == Brightness.dark;

        final session = state.activeSession;
        final isLive = session.isActive && !session.isExpired;
        final isExpired = session.isExpired;
        final isStandby = !session.isActive && !session.isExpired;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'Live Attendance / የቀጥታ መገኘት',
              style: TextStyle(
                color: textCol,
                fontFamily: 'serif',
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
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
            actions: [
              IconButton(
                tooltip: 'Reset Session / ወደ መጀመሪያ መልስ',
                icon: const Icon(Icons.replay, size: 20),
                onPressed: () {
                  state.resetAttendanceSession();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Attendance session reset to standby.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Screen Header Subtitle
                  Text(
                    '${session.courseCode} • ${session.courseName}',
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 14),

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
                                'SCANNED / PRESENT',
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
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      '${session.scans.length}',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: primaryAccent,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Students',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 44, color: borderCol),
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
                                '${state.totalRegisteredStudents}',
                                style: TextStyle(
                                  fontSize: 32,
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

                  const SizedBox(height: 16),

                  // MAIN ATTENDANCE CARD (Standby / Live / Expired)
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isLive
                            ? const Color(0xFF10B981).withOpacity(0.8)
                            : isExpired
                                ? const Color(0xFFF59E0B).withOpacity(0.6)
                                : borderCol,
                        width: isLive ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isLive
                              ? const Color(0xFF10B981).withOpacity(0.15)
                              : (isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.06)),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Status Badge
                        _buildStatusBadge(isStandby, isLive, isExpired, primaryAccent),

                        const SizedBox(height: 18),

                        // QR Display Box with Overlay for Standby & Expired States
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isLive ? primaryAccent : Colors.grey).withOpacity(0.25),
                                    blurRadius: 14,
                                  ),
                                ],
                              ),
                              child: isStandby
                                  ? Container(
                                      width: 170,
                                      height: 170,
                                      color: Colors.grey.shade100,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.qr_code_2, size: 70, color: Colors.grey.shade400),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Standby Mode',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                          Text(
                                            'Tap button to start 5-min',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey.shade500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : QrImageView(
                                      data: session.code,
                                      version: QrVersions.auto,
                                      size: 170,
                                      backgroundColor: Colors.white,
                                    ),
                            ),

                            // Expired Overlay
                            if (isExpired)
                              Container(
                                width: 194,
                                height: 194,
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.82),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.timer_off_outlined, color: Color(0xFFF59E0B), size: 44),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'WINDOW EXPIRED',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ጊዜው አልቋል',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // PIN Code Label
                        Text(
                          isExpired ? 'PIN Code (Expired)' : 'PIN Code / የመግቢያ ኮድ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isExpired ? Colors.redAccent : textMuted.withOpacity(0.8),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Large 4-Digit PIN
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            isStandby ? '----' : (isExpired ? 'EXPIRED' : session.rollingPin),
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: isExpired ? 32 : 44,
                              fontWeight: FontWeight.w900,
                              color: isLive
                                  ? primaryAccent
                                  : (isExpired ? const Color(0xFFEF4444) : textMuted.withOpacity(0.5)),
                              letterSpacing: isExpired ? 3.0 : 8.0,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Live 30s Countdown Indicator
                        if (isLive) ...[
                          ValueListenableBuilder<int>(
                            valueListenable: state.pinCountdownNotifier,
                            builder: (context, pinCount, _) {
                              final progress = (pinCount / 300.0).clamp(0.0, 1.0);
                              return Column(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      minHeight: 6,
                                      backgroundColor: elevatedBg,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        pinCount > 10 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.timer_outlined, size: 14, color: Color(0xFF10B981)),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Expires in $pinCount seconds / በ${pinCount}s ውስጥ ያልቃል',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: pinCount > 10 ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              state.expireAttendanceWindow();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              side: const BorderSide(color: Color(0xFFEF4444)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.stop_circle_outlined, size: 18),
                            label: const Text('Stop / Expire Window Now (አሁን አቁም)', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],

                        // Standby Action Button
                        if (isStandby) ...[
                          Text(
                            'Click the button below to generate a secure 5-minute QR code & PIN for students to scan. It will automatically expire after 5 minutes.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () {
                              state.startAttendanceWindow(durationSeconds: 300);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryAccent,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.play_arrow_rounded, size: 24),
                            label: const Text(
                              'Start 5-Min QR Attendance / የ5 ደቂቃ መገኘት ጀምር',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],

                        // Expired Action Button (For starting Round 2 / next round if needed)
                        if (isExpired) ...[
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                            ),
                            child: const Text(
                              'The 5-minute attendance window has closed. All students who scanned during this window have been recorded. Start a new window if needed.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11, color: Color(0xFFD97706), height: 1.3),
                            ),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () {
                              state.startAttendanceWindow(durationSeconds: 300);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              elevation: 4,
                            ),
                            icon: const Icon(Icons.refresh_rounded, size: 22),
                            label: const Text(
                              'Start New 5-Min Window / አዲስ 5 ደቂቃ ጀምር',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Scans Feed Header with Count & Clear Scans Option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Recent Scans / የተመዘገቡ ተማሪዎች',
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: textCol,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: primaryAccent.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: primaryAccent.withOpacity(0.3)),
                              ),
                              child: Text(
                                '${session.scans.length}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: primaryAccent,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (session.scans.isNotEmpty)
                        TextButton.icon(
                          onPressed: () => _confirmClearScans(context),
                          icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppTheme.crimson),
                          label: const Text('Clear', style: TextStyle(color: AppTheme.crimson, fontSize: 12)),
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Empty State or Scanned Students List
                  if (session.scans.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.how_to_reg_outlined, size: 48, color: textMuted.withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text(
                            'No Scans Yet / እስካሁን የተመዘገበ ተማሪ የለም',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: textCol,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Students who scan the live QR code or enter the PIN on their phones will appear here in real time.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...session.scans.map((scan) {
                      final timeFormatted = DateFormat('hh:mm:ss a').format(scan.timestamp);
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
                              backgroundColor: primaryAccent.withOpacity(0.18),
                              child: Text(
                                initials.isEmpty ? 'ST' : initials,
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
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 11, color: textMuted),
                                      const SizedBox(width: 4),
                                      Text(
                                        timeFormatted,
                                        style: TextStyle(fontSize: 11, color: textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // Check-In Method Badge (QR or PIN)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                                        ? Icons.qr_code_scanner
                                        : Icons.pin,
                                    color: primaryAccent,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    scan.method == AttendanceCheckInMethod.qr ? 'QR' : 'PIN',
                                    style: TextStyle(
                                      fontSize: 11,
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

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(bool isStandby, bool isLive, bool isExpired, Color primaryAccent) {
    if (isLive) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
              SizedBox(width: 6),
              Text(
                'LIVE 30s WINDOW ACTIVE / ክፍለ ጊዜው ክፍት ነው',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (isExpired) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.6)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_clock, color: Color(0xFFEF4444), size: 12),
              SizedBox(width: 6),
              Text(
                'WINDOW EXPIRED / የ30 ሰከንድ ጊዜ አልቋል',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF4444),
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Standby
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pause_circle_outline, color: Colors.grey.shade400, size: 12),
            const SizedBox(width: 6),
            Text(
              'STANDBY • WAITING TO START / ዝግጁ',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Colors.grey.shade400,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClearScans(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Attendance Scans?'),
        content: const Text(
          'This will remove all recorded scans for this session from both your screen and the server. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              state.clearAttendanceScans();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
