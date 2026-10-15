import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

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
  final int activeRoadmaps;
  final int atRiskCount;
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
    required this.activeRoadmaps,
    required this.atRiskCount,
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
  String _selectedTimeFilter = 'This Week';
  String _selectedBatchFilter = 'All Batches';

  List<String> _getAvailableBatches(FellowshipState state) {
    final depts = state.allStudents
        .map((s) => s.department.trim())
        .where((d) => d.isNotEmpty && d != 'General')
        .toSet()
        .toList();
    depts.sort();
    return ['All Batches', ...depts];
  }

  final List<String> _timeFilterOptions = ['This Week', 'This Month', 'Semester', 'Annual'];

  _DashboardMetricsData _computeDashboardData(FellowshipState state) {
    // 1. Filter students according to selected department/batch
    final allStudents = state.allStudents;
    final List<UserModel> students;
    if (_selectedBatchFilter == 'All Batches') {
      students = allStudents;
    } else {
      students = allStudents
          .where((s) => s.department.trim().toLowerCase() == _selectedBatchFilter.trim().toLowerCase())
          .toList();
    }

    final int registeredCount = students.length;

    // 2. Compute true average attendance mathematically from actual student records
    final double avgAttendance = registeredCount == 0
        ? 0.0
        : double.parse((students.fold<double>(0.0, (sum, s) => sum + s.attendancePercentage) / registeredCount).toStringAsFixed(1));

    // 3. Compute at-risk students & counts
    final atRiskList = students.where((s) => s.attendancePercentage < 75.0).toList();
    final int atRiskCount = atRiskList.length;

    // 4. Active roadmaps from state
    final int activeRoadmaps = state.roadmaps.length;

    // 5. Attendance status counts (Present, Late, Absent)
    final int presentCount = students.where((s) => s.attendancePercentage >= 75.0).length;
    final int lateCount = students.where((s) => s.attendancePercentage >= 50.0 && s.attendancePercentage < 75.0).length;
    final int absentCount = students.where((s) => s.attendancePercentage < 50.0).length;

    // 6. Time period labels
    final isMonth = _selectedTimeFilter == 'This Month';
    final isSemester = _selectedTimeFilter.contains('Semester');
    final isAnnual = _selectedTimeFilter == 'Annual';

    final String periodBadge = isMonth ? 'MONTHLY' : (isSemester ? 'SEMESTER' : (isAnnual ? 'ANNUAL' : 'WEEKLY'));
    final String periodLabel = isMonth ? 'This Month' : (isSemester ? 'Semester' : (isAnnual ? 'Annual' : 'This Week'));

    // 7. Dynamic Trend Chart Spots
    List<FlSpot> spots = [];
    List<String> xLabels = [];
    int peakIndex = 0;

    if (registeredCount == 0) {
      spots = [];
      xLabels = [];
      peakIndex = 0;
    } else {
      if (students.length >= 2) {
        double maxRate = -1;
        for (int i = 0; i < students.length && i < 6; i++) {
          final s = students[i];
          final namePart = s.fullName.trim().split(' ').first;
          final label = namePart.length > 5 ? namePart.substring(0, 5) : namePart;
          xLabels.add(label);
          final rate = s.attendancePercentage.clamp(0.0, 100.0);
          spots.add(FlSpot(i.toDouble(), rate));
          if (rate > maxRate) {
            maxRate = rate;
            peakIndex = i;
          }
        }
      } else {
        xLabels = isMonth
            ? ['WK 1', 'WK 2', 'WK 3', 'WK 4']
            : (isSemester
                ? ['SEP', 'OCT', 'NOV', 'DEC', 'JAN']
                : (isAnnual ? ['Q1', 'Q2', 'Q3', 'Q4'] : ['MON', 'TUE', 'WED', 'THU', 'FRI']));
        for (int i = 0; i < xLabels.length; i++) {
          spots.add(FlSpot(i.toDouble(), avgAttendance));
        }
        peakIndex = (xLabels.length / 2).floor();
      }
    }

    // 8. Real System Activity Items (No fake mock entries)
    final List<_DashboardActivityItem> activities = [];

    // Pending registrations
    if (state.pendingApprovals.isNotEmpty) {
      activities.add(
        _DashboardActivityItem(
          icon: Icons.person_add_alt_1_rounded,
          title: '${state.pendingApprovals.length} Pending Registration(s)',
          subtitle: 'Awaiting admin verification: ${state.pendingApprovals.take(3).map((u) => u.fullName).join(", ")}',
          timeAgo: 'Pending',
          isRisk: true,
          onActionTap: widget.onOpenApprovals,
        ),
      );
    }

    // Real At-Risk Students requiring pastoral follow-up
    for (final atRisk in atRiskList.take(3)) {
      activities.add(
        _DashboardActivityItem(
          icon: Icons.warning_amber_rounded,
          title: '${atRisk.fullName} (${atRisk.department.isNotEmpty ? atRisk.department : "Fellowship"})',
          subtitle: 'Attendance at ${atRisk.attendancePercentage.toStringAsFixed(1)}% (Below 75% threshold)',
          timeAgo: 'Current',
          isRisk: true,
          onActionTap: atRisk.phoneNumber.isNotEmpty ? () => state.launchCall(atRisk.phoneNumber) : null,
        ),
      );
    }

    // Active Live Attendance Session
    if (state.activeSession.scans.isNotEmpty) {
      activities.add(
        _DashboardActivityItem(
          icon: Icons.qr_code_scanner,
          title: 'Live Attendance Session',
          subtitle: '${state.activeSession.scans.length} of $registeredCount student(s) checked in',
          timeAgo: 'Active',
          onActionTap: widget.onOpenLiveAttendance,
        ),
      );
    }

    // Pending Emergency Aid Requests
    final pendingAid = state.emergencyAidRequests.where((a) => a.status == 'pending').toList();
    if (pendingAid.isNotEmpty) {
      activities.add(
        _DashboardActivityItem(
          icon: Icons.emergency_outlined,
          title: '${pendingAid.length} Emergency Aid Request(s)',
          subtitle: 'Student assistance applications pending review',
          timeAgo: 'Review',
          isRisk: true,
          onActionTap: widget.onOpenApprovals,
        ),
      );
    }

    // Pending Volunteer Applications
    final pendingVolunteers = state.volunteerApplications.where((a) => a.status == ApplicationStatus.pending).toList();
    if (pendingVolunteers.isNotEmpty) {
      activities.add(
        _DashboardActivityItem(
          icon: Icons.volunteer_activism_outlined,
          title: '${pendingVolunteers.length} Department Application(s)',
          subtitle: 'Students applied to join fellowship service departments',
          timeAgo: 'Review',
          onActionTap: widget.onOpenApprovals,
        ),
      );
    }

    // Broadcasts
    if (state.latestEmergencyBroadcast != null) {
      activities.add(
        _DashboardActivityItem(
          icon: Icons.campaign_rounded,
          title: state.latestEmergencyBroadcast!.title,
          subtitle: state.latestEmergencyBroadcast!.description,
          timeAgo: 'Broadcast',
        ),
      );
    }

    return _DashboardMetricsData(
      periodBadge: periodBadge,
      periodLabel: periodLabel,
      registeredCount: registeredCount,
      avgAttendance: avgAttendance,
      activeRoadmaps: activeRoadmaps,
      atRiskCount: atRiskCount,
      xLabels: xLabels,
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

    final metrics = _computeDashboardData(state);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                        color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
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
              // Time Filter Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _timeFilterOptions.contains(_selectedTimeFilter)
                        ? _selectedTimeFilter
                        : (_selectedTimeFilter.contains('Semester') ? 'Semester' : 'This Week'),
                    dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                    icon: Icon(Icons.keyboard_arrow_down, color: primaryAccent, size: 18),
                    style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.bold),
                    items: _timeFilterOptions.map((s) {
                      return DropdownMenuItem(
                        value: s,
                        child: Text(s, style: TextStyle(color: theme.colorScheme.onSurface)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTimeFilter = val);
                    },
                  ),
                ),
              ),
            ],
          ),

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
                      Icon(Icons.swap_horiz_rounded, color: primaryAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Switch Perspective / Toggle Roles',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.gold.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'Live Sandbox',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.gold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Experience the app from any role perspective. You can return to Admin anytime via the top banner or Profile tab.',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
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
                          label: const Text('Student', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UserRole.student.badgeColor,
                            side: BorderSide(color: UserRole.student.badgeColor.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          label: const Text('Coordinator', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UserRole.volunteerCoordinator.badgeColor,
                            side: BorderSide(color: UserRole.volunteerCoordinator.badgeColor.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                          label: const Text('Parent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: UserRole.spiritualParent.badgeColor,
                            side: BorderSide(color: UserRole.spiritualParent.badgeColor.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          if (state.pendingApprovals.isNotEmpty) ...[
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
                border: Border.all(color: AppTheme.gold.withOpacity(0.55), width: 1.5),
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
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.gold, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${state.pendingApprovals.length} New Student Registrations',
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
                            color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ),
          ],

          // Horizontal Batch Filter Pills (Only shown if multiple departments are registered)
          Builder(
            builder: (context) {
              final batches = _getAvailableBatches(state);
              if (batches.length <= 1) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: batches.map((batch) {
                      final isSelected = _selectedBatchFilter == batch;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedBatchFilter = batch),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryAccent.withOpacity(0.18) : (theme.cardTheme.color ?? theme.colorScheme.surface),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? primaryAccent : theme.dividerColor,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            batch.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isSelected ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
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
                  value: '${metrics.registeredCount}',
                  label: '${metrics.periodBadge} REGISTERED',
                ),
              ),
              const SizedBox(width: 12),
              // 2. Avg Attendance Rate
              Expanded(
                child: _buildKpiCard(
                  context: context,
                  icon: Icons.check_circle_outline,
                  iconColor: AppTheme.azure,
                  value: '${metrics.avgAttendance.toStringAsFixed(1)}%',
                  label: '${metrics.periodBadge} RATE',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // 3. Active Roadmaps
              Expanded(
                child: _buildKpiCard(
                  context: context,
                  icon: Icons.map_outlined,
                  iconColor: AppTheme.emerald,
                  value: '${metrics.activeRoadmaps}',
                  label: '${metrics.periodBadge} ROADMAPS',
                ),
              ),
              const SizedBox(width: 12),
              // 4. At-Risk Students
              Expanded(
                child: _buildKpiCard(
                  context: context,
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppTheme.crimson,
                  value: '${metrics.atRiskCount}',
                  label: '${metrics.periodBadge} AT-RISK',
                  isWarning: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Attendance Trend Chart Card (Reactive to _selectedTimeFilter)
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
                        'Attendance Trend • ${metrics.periodLabel}',
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryAccent.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        metrics.periodBadge,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Attendance Trend Visualization (Clean real data or intuitive empty placeholder)
                if (metrics.spots.isEmpty || metrics.registeredCount == 0)
                  Container(
                    height: 160,
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.query_stats_rounded, size: 36, color: primaryAccent.withOpacity(0.4)),
                        const SizedBox(height: 10),
                        Text(
                          'No Attendance Sessions Recorded Yet',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.colorScheme.onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Live attendance curves will appear here as students check in via QR code or PIN.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                        ),
                      ],
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
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              getTitlesWidget: (value, meta) {
                                final titles = metrics.xLabels;
                                final index = value.toInt();
                                if (index >= 0 && index < titles.length && (value - index).abs() < 0.1) {
                                  final isPeak = index == metrics.peakIndex;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      titles[index],
                                      style: TextStyle(
                                        color: isPeak ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textTertiary),
                                        fontWeight: isPeak ? FontWeight.bold : FontWeight.normal,
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
                        maxX: (metrics.spots.length > 1 ? (metrics.spots.length - 1).toDouble() : 1.0),
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
                                  color: isPeak ? primaryAccent : (isDark ? Colors.black : Colors.white),
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

          // Period Attendance Breakdown (Segmented Bar & Counts)
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
                  '${metrics.periodLabel} Attendance Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 14),

                // Horizontal Segmented Bar (Guarded against zero flex)
                if (metrics.registeredCount == 0 || (metrics.presentCount + metrics.lateCount + metrics.absentCount == 0))
                  Container(
                    height: 12,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
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
                            if (metrics.presentCount > 0) const SizedBox(width: 2),
                            Expanded(
                              flex: metrics.lateCount,
                              child: Container(color: const Color(0xFF93B5E1)),
                            ),
                          ],
                          if (metrics.absentCount > 0) ...[
                            if (metrics.presentCount > 0 || metrics.lateCount > 0) const SizedBox(width: 2),
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
                    _buildStatusLegend(context: context, color: primaryAccent, label: 'PRESENT', count: '${metrics.presentCount}'),
                    _buildStatusLegend(context: context, color: const Color(0xFF93B5E1), label: 'LATE', count: '${metrics.lateCount}'),
                    _buildStatusLegend(context: context, color: const Color(0xFFF87171), label: 'ABSENT', count: '${metrics.absentCount}'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recent Activity & Period Dynamic Highlights
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Activity • ${metrics.periodLabel}',
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
              if (metrics.activities.isNotEmpty)
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  child: Text('VIEW ALL', style: TextStyle(color: primaryAccent, fontSize: 11, fontWeight: FontWeight.bold)),
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
                    Icon(Icons.inbox_outlined, size: 36, color: primaryAccent.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text(
                      'No Urgent Activities or Alerts',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'All ${metrics.registeredCount} enrolled student(s) are in good standing. New registrations, aid requests, and attendance alerts will appear here as they occur.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else
            ...metrics.activities.map((act) => Padding(
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
                )),

          const SizedBox(height: 14),

          // Test Data & Database Seeder Action Card
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
                      child: Icon(Icons.storage_rounded, color: primaryAccent, size: 20),
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
                            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
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
                            final count = await state.seedEntireDatabaseToFirestore();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Successfully pushed $count records across all 20 collections to Firebase!'),
                                  backgroundColor: const Color(0xFF10B981),
                                ),
                              );
                            }
                          },
                    icon: state.isSeedingData
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Icon(Icons.cloud_sync_rounded, size: 20, color: isDark ? Colors.black : Colors.white),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                                final count = await state.seedTestStudentsToFirestore(count: 15);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Seeded $count test students to Firebase!'),
                                      backgroundColor: const Color(0xFF10B981),
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.person_add_outlined, size: 16),
                        label: const Text(
                          'Seed Students',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: state.isSeedingData
                            ? null
                            : () async {
                                final count = await state.clearTestStudentsFromFirestore();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Cleared $count test students from Firebase database!'),
                                      backgroundColor: AppTheme.crimson,
                                    ),
                                  );
                                }
                              },
                        icon: const Icon(Icons.delete_sweep_outlined, size: 16, color: AppTheme.crimson),
                        label: const Text(
                          'Free Database',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.crimson),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                      child: const Icon(Icons.developer_mode, color: AppTheme.azure, size: 20),
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
                              color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
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
          color: isWarning ? AppTheme.crimson.withOpacity(0.5) : theme.dividerColor,
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
              color: isWarning ? AppTheme.crimson : (theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary),
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
              style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary, fontWeight: FontWeight.bold),
            ),
            Text(
              count,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
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
          color: isRisk ? AppTheme.crimson.withOpacity(0.4) : theme.dividerColor,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isRisk ? AppTheme.crimson.withOpacity(0.15) : primaryAccent.withOpacity(0.15),
            child: Icon(icon, color: isRisk ? AppTheme.crimson : primaryAccent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeAgo,
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary),
              ),
              if (onActionTap != null) ...[
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onActionTap,
                  child: Text(
                    'Contact',
                    style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.bold),
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
