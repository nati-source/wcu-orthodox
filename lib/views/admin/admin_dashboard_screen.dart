import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/app_models.dart';
import '../../services/admin_dashboard_analytics_service.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/edit_profile_modal.dart';

class AdminDashboardScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback onOpenFamilyMatching;
  final VoidCallback onOpenLiveAttendance;
  final VoidCallback? onOpenApprovals;

  const AdminDashboardScreen({
    super.key,
    required this.state,
    required this.onOpenFamilyMatching,
    required this.onOpenLiveAttendance,
    this.onOpenApprovals,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _DashboardMetricsData {
  final String periodBadge;
  final String periodLabel;
  final int registeredCount;
  final double avgAttendance;
  final bool hasAttendanceData;
  final int recordedSessions;
  final int atRiskCount;
  final int pendingApprovalsCount;
  final bool hasSessionBreakdown;
  final String breakdownCourseName;
  final bool isLoading;
  final String? loadError;
  final List<String> xLabels;
  final List<FlSpot> spots;
  final int peakIndex;
  final int presentCount;
  final int lateCount;
  final int absentCount;
  final List<_DashboardActivityItem> activities;

  const _DashboardMetricsData({
    required this.periodBadge,
    required this.periodLabel,
    required this.registeredCount,
    required this.avgAttendance,
    required this.hasAttendanceData,
    required this.recordedSessions,
    required this.atRiskCount,
    required this.pendingApprovalsCount,
    required this.hasSessionBreakdown,
    required this.breakdownCourseName,
    required this.isLoading,
    required this.loadError,
    required this.xLabels,
    required this.spots,
    required this.peakIndex,
    required this.presentCount,
    required this.lateCount,
    required this.absentCount,
    required this.activities,
  });
}

class _DashboardActivityItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String timeAgo;
  final bool isRisk;
  final VoidCallback? onActionTap;

  const _DashboardActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.timeAgo,
    this.isRisk = false,
    this.onActionTap,
  });
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminDashboardAnalyticsService _analyticsService =
      AdminDashboardAnalyticsService();
  AdminDashboardAnalyticsSnapshot? _databaseSnapshot;
  bool _isLoading = true;
  String? _loadError;
  String _selectedBatchFilter = 'All Batches';

  @override
  void initState() {
    super.initState();
    unawaited(_loadDashboardData());
  }

  Future<void> _loadDashboardData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final snapshot = await _analyticsService.load();
      if (!mounted) return;
      setState(() {
        _databaseSnapshot = snapshot;
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _databaseSnapshot = null;
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  List<String> _getAvailableBatches(List<UserModel> students) {
    final depts = students
        .map((s) => s.department.trim())
        .where((d) => d.isNotEmpty && d != 'General')
        .toSet()
        .toList();
    return ['All Batches', ...depts];
  }

  _DashboardMetricsData _computeDashboardData(FellowshipState state) {
    final database = _databaseSnapshot;
    final students = (database?.students ?? const <UserModel>[])
        .where(
          (student) =>
              student.role == UserRole.student &&
              (_selectedBatchFilter == 'All Batches' ||
                  student.department.trim() == _selectedBatchFilter),
        )
        .toList();
    final registeredCount = students.length;
    final selectedDepartment = _selectedBatchFilter == 'All Batches'
        ? null
        : _selectedBatchFilter;
    final completedSessions = (database?.sessions ?? const [])
        .where(
          (record) =>
              !record.session.isActive ||
              record.session.isExpired ||
              (record.session.expiresAt != null &&
                  !record.session.expiresAt!.isAfter(DateTime.now())),
        )
        .where((record) => record.enrolledStudents.isNotEmpty)
        .where(
          (record) =>
              selectedDepartment == null ||
              record.enrolledStudents.any(
                (student) => student.department == selectedDepartment,
              ),
        )
        .toList();
    final scopedStudentIds = students.map((student) => student.id).toSet();
    final opportunitiesByStudent = <String, int>{};
    final attendedByStudent = <String, int>{};
    var totalOpportunities = 0;
    var totalAttended = 0;

    for (final record in completedSessions) {
      final enrolled = record.enrolledStudents.where((student) {
        return selectedDepartment == null ||
            student.department == selectedDepartment;
      });
      final enrolledIds = enrolled.map((student) => student.studentId).toSet();
      totalOpportunities += enrolledIds.length;
      final scansByStudent = {
        for (final scan in record.scans) scan.studentId: scan,
      };
      for (final studentId in enrolledIds) {
        final scan = scansByStudent[studentId];
        final attended =
            scan != null &&
            (scan.status == AttendanceStatus.present ||
                scan.status == AttendanceStatus.late);
        if (attended) totalAttended++;
        if (scopedStudentIds.contains(studentId)) {
          opportunitiesByStudent.update(
            studentId,
            (value) => value + 1,
            ifAbsent: () => 1,
          );
          if (attended) {
            attendedByStudent.update(
              studentId,
              (value) => value + 1,
              ifAbsent: () => 1,
            );
          }
        }
      }
    }

    final attendanceRates = <String, double>{
      for (final entry in opportunitiesByStudent.entries)
        entry.key: (attendedByStudent[entry.key] ?? 0) * 100 / entry.value,
    };
    final attendanceDataStudents = students
        .where((student) => attendanceRates.containsKey(student.id))
        .toList();
    final hasAttendanceData = totalOpportunities > 0;
    final avgAttendance = hasAttendanceData
        ? totalAttended * 100 / totalOpportunities
        : 0.0;
    final atRiskStudents =
        attendanceDataStudents
            .where((student) => (attendanceRates[student.id] ?? 100) < 75)
            .toList()
          ..sort(
            (a, b) => (attendanceRates[a.id] ?? 0).compareTo(
              attendanceRates[b.id] ?? 0,
            ),
          );

    final allSessions = database?.sessions ?? const [];
    final latestSession = allSessions.isEmpty ? null : allSessions.first;
    final hasLiveSession =
        latestSession != null &&
        latestSession.session.isActive &&
        !latestSession.session.isExpired &&
        (latestSession.session.expiresAt == null ||
            latestSession.session.expiresAt!.isAfter(DateTime.now()));
    final latestEnrollment = latestSession?.enrolledStudents ?? const [];
    final legacyLiveRoster = hasLiveSession && latestEnrollment.isEmpty
        ? students.map(
            (student) => AttendanceEnrollmentSnapshot(
              studentId: student.id,
              department: student.department,
            ),
          )
        : const <AttendanceEnrollmentSnapshot>[];
    final breakdownRoster =
        (latestEnrollment.isNotEmpty ? latestEnrollment : legacyLiveRoster)
            .where(
              (student) =>
                  selectedDepartment == null ||
                  student.department == selectedDepartment,
            )
            .toList();
    final breakdownIds = breakdownRoster
        .map((student) => student.studentId)
        .toSet();
    final latestScans =
        latestSession?.scans
            .where((scan) => breakdownIds.contains(scan.studentId))
            .toList() ??
        const <AttendanceRecordModel>[];
    final presentCount = latestScans
        .where((scan) => scan.status == AttendanceStatus.present)
        .length;
    final lateCount = latestScans
        .where((scan) => scan.status == AttendanceStatus.late)
        .length;
    final absentCount = (breakdownRoster.length - presentCount - lateCount)
        .clamp(0, breakdownRoster.length);
    final hasSessionBreakdown = breakdownRoster.isNotEmpty;

    const labels = ['0–49%', '50–74%', '75–89%', '90–100%'];
    final buckets = <int>[0, 0, 0, 0];
    for (final student in attendanceDataStudents) {
      final rate = attendanceRates[student.id] ?? 0;
      final bucket = rate < 50
          ? 0
          : rate < 75
          ? 1
          : rate < 90
          ? 2
          : 3;
      buckets[bucket]++;
    }
    final spots = [
      if (attendanceDataStudents.isNotEmpty)
        for (var index = 0; index < buckets.length; index++)
          FlSpot(
            index.toDouble(),
            buckets[index] * 100 / attendanceDataStudents.length,
          ),
    ];
    var peakIndex = 0;
    for (var index = 1; index < spots.length; index++) {
      if (spots[index].y > spots[peakIndex].y) peakIndex = index;
    }

    final activities = <_DashboardActivityItem>[
      for (final student in atRiskStudents.take(3))
        _DashboardActivityItem(
          icon: Icons.person_off_outlined,
          title: student.fullName.trim().isEmpty
              ? 'Student follow-up needed'
              : student.fullName,
          subtitle:
              '${(attendanceRates[student.id] ?? 0).toStringAsFixed(0)}% attendance across ${opportunitiesByStudent[student.id]} recorded sessions',
          timeAgo: 'Follow-up',
          isRisk: true,
          onActionTap: student.phoneNumber.trim().isEmpty
              ? null
              : () => state.launchCall(student.phoneNumber),
        ),
      if (hasLiveSession)
        _DashboardActivityItem(
          icon: Icons.qr_code_scanner,
          title: 'Live Attendance Session',
          subtitle:
              '${latestScans.length} check-ins recorded for ${latestSession.session.courseName}.',
          timeAgo: 'Live',
          onActionTap: widget.onOpenLiveAttendance,
        ),
      if ((database?.pendingStudents.length ?? 0) > 0)
        _DashboardActivityItem(
          icon: Icons.verified_user_outlined,
          title: 'Membership Registrations',
          subtitle:
              '${database!.pendingStudents.length} student registrations pending approval.',
          timeAgo: 'Pending',
          onActionTap: widget.onOpenApprovals,
        ),
    ];

    return _DashboardMetricsData(
      periodBadge: 'DATABASE',
      periodLabel: hasAttendanceData
          ? '${completedSessions.length} Recorded Sessions'
          : 'Attendance History',
      registeredCount: registeredCount,
      avgAttendance: avgAttendance,
      hasAttendanceData: hasAttendanceData,
      recordedSessions: completedSessions.length,
      atRiskCount: atRiskStudents.length,
      pendingApprovalsCount: database?.pendingStudents.length ?? 0,
      hasSessionBreakdown: hasSessionBreakdown,
      breakdownCourseName: hasSessionBreakdown
          ? latestSession?.session.courseName ?? ''
          : '',
      isLoading: _isLoading,
      loadError: _loadError,
      xLabels: labels,
      spots: spots,
      peakIndex: peakIndex,
      presentCount: presentCount,
      lateCount: lateCount,
      absentCount: absentCount,
      activities: activities,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    final availableBatches = _getAvailableBatches(
      _databaseSnapshot?.students ?? const <UserModel>[],
    );
    if (!availableBatches.contains(_selectedBatchFilter)) {
      _selectedBatchFilter = 'All Batches';
    }
    final metrics = _computeDashboardData(state);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Executive Administrator Profile & Contact Card
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryAccent.withOpacity(0.16),
                  theme.cardTheme.color ?? theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: primaryAccent.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: primaryAccent.withOpacity(0.2),
                  child: Icon(
                    Icons.admin_panel_settings,
                    color: primaryAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              state.currentUser.fullName.isNotEmpty
                                  ? state.currentUser.fullName
                                  : 'Administrator',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.gold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Admin',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.gold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.currentUser.department} • ${state.currentUser.phoneNumber.isNotEmpty ? state.currentUser.phoneNumber : "No phone set"}',
                        style: TextStyle(
                          fontSize: 11,
                          color:
                              theme.textTheme.bodyMedium?.color ??
                              AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => EditProfileModal.show(context, state),
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.14),
                      shape: BoxShape.circle,
                      border: Border.all(color: primaryAccent.withOpacity(0.4)),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: primaryAccent,
                      size: 16,
                    ),
                  ),
                  tooltip: 'Edit Profile • መገለጫ አርትዕ',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),

          // Header Row: Executive Analytics + Time Filter Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Executive Analytics',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            theme.textTheme.bodyMedium?.color ??
                            AppTheme.textSecondary,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Overview',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      metrics.loadError == null
                          ? Icons.storage_outlined
                          : Icons.cloud_off_outlined,
                      color: metrics.loadError == null
                          ? primaryAccent
                          : AppTheme.crimson,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      metrics.isLoading
                          ? 'LOADING'
                          : metrics.loadError == null
                          ? 'DATABASE'
                          : 'ERROR',
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: metrics.isLoading ? null : _loadDashboardData,
                tooltip: 'Refresh database analytics',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),

          if (metrics.loadError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.crimson.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.crimson.withOpacity(0.35)),
              ),
              child: Text(
                'Database analytics could not be loaded. Check your connection and refresh.',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 12,
                ),
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Role Switcher Card for instant 1-tap toggling
          if (state.canSwitchRoles) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryAccent.withOpacity(0.12),
                    theme.cardTheme.color ?? theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: primaryAccent.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: primaryAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Switch Perspective / Toggle Roles',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.gold.withOpacity(0.5),
                          ),
                        ),
                        child: const Text(
                          'Live Sandbox',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.gold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Experience the app from any role perspective. You can return to Admin anytime via the top banner or Profile tab.',
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          theme.textTheme.bodyMedium?.color ??
                          AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            state.switchRole(UserRole.student);
                          },
                          icon: const Icon(Icons.school, size: 16),
                          label: const Text(
                            'Student',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UserRole.student.badgeColor,
                            side: BorderSide(
                              color: UserRole.student.badgeColor.withOpacity(
                                0.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            state.switchRole(UserRole.volunteerCoordinator);
                          },
                          icon: const Icon(Icons.verified_user, size: 16),
                          label: const Text(
                            'Coordinator',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                UserRole.volunteerCoordinator.badgeColor,
                            side: BorderSide(
                              color: UserRole.volunteerCoordinator.badgeColor
                                  .withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            state.switchRole(UserRole.spiritualParent);
                          },
                          icon: const Icon(Icons.family_restroom, size: 16),
                          label: const Text(
                            'Parent',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                UserRole.spiritualParent.badgeColor,
                            side: BorderSide(
                              color: UserRole.spiritualParent.badgeColor
                                  .withOpacity(0.5),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Urgent Alert Card: Pending Student Registrations
          if (metrics.pendingApprovalsCount > 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.gold.withOpacity(0.2),
                    theme.cardTheme.color ?? theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.gold.withOpacity(0.55),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1_rounded,
                      color: AppTheme.gold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${metrics.pendingApprovalsCount} New Student Registrations',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Awaiting admin verification & approval to access the app.',
                          style: TextStyle(
                            fontSize: 11,
                            color:
                                theme.textTheme.bodyMedium?.color ??
                                AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (widget.onOpenApprovals != null)
                    ElevatedButton(
                      onPressed: widget.onOpenApprovals,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: const Color(0xFF070F1E),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Review',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Horizontal Batch Filter Pills (Only shown if multiple departments are registered)
          Builder(
            builder: (context) {
              final batches = availableBatches;
              if (batches.length <= 1) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: batches.map((batch) {
                      final isSelected = _selectedBatchFilter == batch;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedBatchFilter = batch),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? primaryAccent.withOpacity(0.18)
                                : (theme.cardTheme.color ??
                                      theme.colorScheme.surface),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? primaryAccent
                                  : theme.dividerColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            batch.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isSelected
                                  ? primaryAccent
                                  : (theme.textTheme.bodyMedium?.color ??
                                        AppTheme.textSecondary),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          // 2x2 KPI Metrics Grid (Dynamically reflects _selectedTimeFilter & _selectedBatchFilter)
          Row(
            children: [
              // 1. Registered Count
              Expanded(
                child: _buildKpiCard(
                  context: context,
                  icon: Icons.people,
                  iconColor: primaryAccent,
                  value: metrics.isLoading
                      ? '…'
                      : metrics.loadError != null
                      ? '—'
                      : '${metrics.registeredCount}',
                  label: 'APPROVED STUDENTS',
                ),
              ),
              const SizedBox(width: 12),
              // 2. Avg Attendance Rate
              Expanded(
                child: _buildKpiCard(
                  context: context,
                  icon: Icons.check_circle_outline,
                  iconColor: AppTheme.azure,
                  value: metrics.isLoading
                      ? '…'
                      : metrics.hasAttendanceData
                      ? '${metrics.avgAttendance.toStringAsFixed(1)}%'
                      : '—',
                  label: metrics.hasAttendanceData
                      ? 'RECORDED ATTENDANCE'
                      : metrics.loadError != null
                      ? 'UNAVAILABLE'
                      : 'NO SESSION HISTORY',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 3. Attendance sessions with saved enrollment snapshots
              Expanded(
                child: _buildKpiCard(
                  context: context,
                  icon: Icons.event_available_outlined,
                  iconColor: AppTheme.emerald,
                  value: metrics.isLoading
                      ? '…'
                      : metrics.loadError != null
                      ? '—'
                      : '${metrics.recordedSessions}',
                  label: 'RECORDED SESSIONS',
                ),
              ),
              const SizedBox(width: 12),
              // 4. At-Risk Students
              Expanded(
                child: _buildKpiCard(
                  context: context,
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppTheme.crimson,
                  value: metrics.hasAttendanceData
                      ? '${metrics.atRiskCount}'
                      : '—',
                  label: 'BELOW 75%',
                  isWarning: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Attendance distribution calculated from saved session check-ins.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Attendance Distribution • ${metrics.periodLabel}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: primaryAccent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        metrics.periodBadge,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                if (metrics.isLoading ||
                    metrics.loadError != null ||
                    metrics.spots.isEmpty)
                  Container(
                    height: 160,
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            metrics.isLoading
                                ? Icons.hourglass_empty_rounded
                                : metrics.loadError != null
                                ? Icons.cloud_off_outlined
                                : Icons.query_stats_rounded,
                            size: 32,
                            color: primaryAccent.withOpacity(0.4),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            metrics.isLoading
                                ? 'Loading database aggregates…'
                                : metrics.loadError != null
                                ? 'Attendance data is unavailable'
                                : 'No Complete Attendance Sessions Yet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: theme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            metrics.isLoading
                                ? 'Reading approved students and attendance records from Firestore.'
                                : metrics.loadError != null
                                ? 'Refresh the dashboard after checking the connection.'
                                : 'Attendance aggregates appear after a session with a saved enrollment roster is closed.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  theme.textTheme.bodyMedium?.color ??
                                  AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 170,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(
                            color: theme.dividerColor.withOpacity(0.5),
                            strokeWidth: 1,
                            dashArray: [4, 4],
                          ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                final titles = metrics.xLabels;
                                final index = value.toInt();
                                if (index >= 0 &&
                                    index < titles.length &&
                                    (value - index).abs() < 0.1) {
                                  final isPeak = index == metrics.peakIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      titles[index],
                                      style: TextStyle(
                                        color: isPeak
                                            ? primaryAccent
                                            : (theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.color ??
                                                  AppTheme.textTertiary),
                                        fontWeight: isPeak
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                }
                                return const Text('');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: (metrics.spots.length > 1
                            ? (metrics.spots.length - 1).toDouble()
                            : 1.0),
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: metrics.spots,
                            isCurved: metrics.spots.length > 2,
                            curveSmoothness: 0.35,
                            color: primaryAccent,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                final isPeak = index == metrics.peakIndex;
                                return FlDotCirclePainter(
                                  radius: isPeak ? 6 : 4,
                                  color: isPeak
                                      ? primaryAccent
                                      : (isDark ? Colors.black : Colors.white),
                                  strokeWidth: 2,
                                  strokeColor: primaryAccent,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  primaryAccent.withOpacity(0.35),
                                  primaryAccent.withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Latest session breakdown from the saved enrollment and scan records.
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest Session Attendance Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (metrics.breakdownCourseName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    metrics.breakdownCourseName,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.textTheme.bodyMedium?.color ??
                          AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 14),

                // Horizontal Segmented Bar (Guarded against zero flex)
                if (!metrics.hasSessionBreakdown ||
                    (metrics.presentCount +
                            metrics.lateCount +
                            metrics.absentCount ==
                        0))
                  Text(
                    metrics.hasSessionBreakdown
                        ? 'No check-ins are recorded for the latest session.'
                        : 'No session roster is available for a breakdown yet.',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          theme.textTheme.bodyMedium?.color ??
                          AppTheme.textSecondary,
                    ),
                  )
                else
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 12,
                      child: Row(
                        children: [
                          if (metrics.presentCount > 0)
                            Expanded(
                              flex: metrics.presentCount,
                              child: Container(color: primaryAccent),
                            ),
                          if (metrics.lateCount > 0) ...[
                            if (metrics.presentCount > 0)
                              const SizedBox(width: 2),
                            Expanded(
                              flex: metrics.lateCount,
                              child: Container(color: const Color(0xFF93B5E1)),
                            ),
                          ],
                          if (metrics.absentCount > 0) ...[
                            if (metrics.presentCount > 0 ||
                                metrics.lateCount > 0)
                              const SizedBox(width: 2),
                            Expanded(
                              flex: metrics.absentCount,
                              child: Container(color: const Color(0xFFF87171)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Status Legends
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusLegend(
                      context: context,
                      color: primaryAccent,
                      label: 'PRESENT',
                      count: '${metrics.presentCount}',
                    ),
                    _buildStatusLegend(
                      context: context,
                      color: const Color(0xFF93B5E1),
                      label: 'LATE',
                      count: '${metrics.lateCount}',
                    ),
                    _buildStatusLegend(
                      context: context,
                      color: const Color(0xFFF87171),
                      label: 'ABSENT',
                      count: '${metrics.absentCount}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Current follow-up items derived from live records.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Needs Attention • ${metrics.periodLabel}',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Real Activity Cards or Friendly Empty State
          if (metrics.activities.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 36,
                      color: primaryAccent.withOpacity(0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No Current Follow-ups',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      metrics.loadError != null
                          ? 'Dashboard records could not be loaded from the database.'
                          : !metrics.hasAttendanceData
                          ? 'No completed sessions with saved enrollment rosters are available for attendance follow-up yet.'
                          : metrics.registeredCount == 0
                          ? 'No approved student profiles are available for this department.'
                          : 'No approved students are below the attendance threshold in the recorded sessions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.textTheme.bodyMedium?.color ??
                            AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...metrics.activities.map(
              (act) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildActivityCard(
                  context: context,
                  icon: act.icon,
                  title: act.title,
                  subtitle: act.subtitle,
                  timeAgo: act.timeAgo,
                  isRisk: act.isRisk,
                  onActionTap: act.onActionTap,
                ),
              ),
            ),

          const SizedBox(height: 14),

          if (state.isDemoMode && kDebugMode) ...[
            // Test Data & Database Seeder Action Card (demo mode only)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryAccent.withOpacity(0.12),
                    theme.cardTheme.color ?? theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryAccent.withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.storage_rounded,
                          color: primaryAccent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Database Test Fixtures • የዳታቤዝ መሞከሪያ',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              'Bulk seed 15+ campus students to test Smart Matching, Attendance & Roles, or free the database.',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    theme.textTheme.bodyMedium?.color ??
                                    AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.isSeedingData
                          ? null
                          : () async {
                              final count = await state
                                  .seedEntireDatabaseToFirestore();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Successfully pushed $count records across all 20 collections to Firebase!',
                                    ),
                                    backgroundColor: const Color(0xFF10B981),
                                  ),
                                );
                              }
                            },
                      icon: state.isSeedingData
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Icon(
                              Icons.cloud_sync_rounded,
                              size: 20,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                      label: Text(
                        'Push Entire Database to Firebase (20 Collections)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.isSeedingData
                              ? null
                              : () async {
                                  final count = await state
                                      .seedTestStudentsToFirestore(count: 15);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Seeded $count test students to Firebase!',
                                        ),
                                        backgroundColor: const Color(
                                          0xFF10B981,
                                        ),
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(Icons.person_add_outlined, size: 16),
                          label: const Text(
                            'Seed Students',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.isSeedingData
                              ? null
                              : () async {
                                  final count = await state
                                      .clearTestStudentsFromFirestore();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Cleared $count test students from Firebase database!',
                                        ),
                                        backgroundColor: AppTheme.crimson,
                                      ),
                                    );
                                  }
                                },
                          icon: const Icon(
                            Icons.delete_sweep_outlined,
                            size: 16,
                            color: AppTheme.crimson,
                          ),
                          label: const Text(
                            'Free Database',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.crimson,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.crimson),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.azure.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.developer_mode,
                          color: AppTheme.azure,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Developer Testing Role Switcher',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Unlock simulator toolbar across all 4 role access points',
                              style: TextStyle(
                                fontSize: 11,
                                color:
                                    theme.textTheme.bodyMedium?.color ??
                                    AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: state.showDevRoleSwitcher,
                        activeColor: primaryAccent,
                        onChanged: (val) {
                          state.toggleDevRoleSwitcher(val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    bool isWarning = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isWarning
            ? AppTheme.crimson.withOpacity(0.12)
            : (theme.cardTheme.color ?? theme.colorScheme.surface),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWarning
              ? AppTheme.crimson.withOpacity(0.5)
              : theme.dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isWarning ? AppTheme.crimson : theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isWarning
                  ? AppTheme.crimson
                  : (theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                        AppTheme.textTertiary),
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusLegend({
    required BuildContext context,
    required Color color,
    required String label,
    required String count,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color:
                    theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                    AppTheme.textTertiary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              count,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActivityCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String timeAgo,
    bool isRisk = false,
    VoidCallback? onActionTap,
  }) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRisk
              ? AppTheme.crimson.withOpacity(0.4)
              : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isRisk
                ? AppTheme.crimson.withOpacity(0.15)
                : primaryAccent.withOpacity(0.15),
            child: Icon(
              icon,
              color: isRisk ? AppTheme.crimson : primaryAccent,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        theme.textTheme.bodyMedium?.color ??
                        AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo,
                style: TextStyle(
                  fontSize: 11,
                  color:
                      theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ??
                      AppTheme.textTertiary,
                ),
              ),
              if (onActionTap != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onActionTap,
                  child: Text(
                    'Contact',
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
