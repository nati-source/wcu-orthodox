import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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

  final List<String> _batches = ['All Batches', 'CS Dept', 'Business', 'Engineering', 'Health Sci'];
  final List<String> _timeFilterOptions = ['This Week', 'This Month', 'Semester', 'Annual'];

  _DashboardMetricsData _computeDashboardData(FellowshipState state) {
    // 1. Department/Batch filtering adjustment
    double batchMultiplier = 1.0;
    int baseRegistered = state.totalRegisteredStudents;
    if (_selectedBatchFilter == 'CS Dept') {
      batchMultiplier = 0.28;
      baseRegistered = 84;
    } else if (_selectedBatchFilter == 'Business') {
      batchMultiplier = 0.24;
      baseRegistered = 72;
    } else if (_selectedBatchFilter == 'Engineering') {
      batchMultiplier = 0.32;
      baseRegistered = 96;
    } else if (_selectedBatchFilter == 'Health Sci') {
      batchMultiplier = 0.18;
      baseRegistered = 56;
    }

    final isMonth = _selectedTimeFilter == 'This Month';
    final isSemester = _selectedTimeFilter.contains('Semester');
    final isAnnual = _selectedTimeFilter == 'Annual';

    if (isMonth) {
      final spots = [
        const FlSpot(0, 74),
        const FlSpot(1, 81),
        const FlSpot(2, 85),
        const FlSpot(3, 89),
      ];
      int peakIdx = 3;
      double avg = 82.3;
      if (_selectedBatchFilter == 'CS Dept') {
        avg = 88.5;
      } else if (_selectedBatchFilter == 'Business') {
        avg = 74.0;
      } else if (_selectedBatchFilter == 'Engineering') {
        avg = 84.1;
      } else if (_selectedBatchFilter == 'Health Sci') {
        avg = 75.8;
      }

      final totalPool = (baseRegistered * 4);
      final present = (totalPool * (avg / 100)).round();
      final late = (totalPool * 0.11).round();
      final absent = (totalPool - present - late).clamp(1, 100000);

      return _DashboardMetricsData(
        periodBadge: 'MONTHLY',
        periodLabel: 'This Month',
        registeredCount: baseRegistered,
        avgAttendance: avg,
        activeRoadmaps: (58 * batchMultiplier).round().clamp(5, 58),
        atRiskCount: (_selectedBatchFilter == 'All Batches' ? 12 : (12 * batchMultiplier).round().clamp(1, 12)),
        xLabels: const ['WK 1', 'WK 2', 'WK 3', 'WK 4'],
        spots: spots,
        peakIndex: peakIdx,
        presentCount: present.clamp(1, 100000),
        lateCount: late.clamp(1, 100000),
        absentCount: absent,
        activities: [
          const _DashboardActivityItem(
            icon: Icons.church_outlined,
            title: 'Monthly Fellowship Liturgy',
            subtitle: 'St. Mary monthly feast attendance hit 89% fellowship participation',
            timeAgo: '3d ago',
          ),
          const _DashboardActivityItem(
            icon: Icons.volunteer_activism_outlined,
            title: 'Charity Aid Disbursement',
            subtitle: 'Monthly student meal and emergency stipend transferred to 14 campus students',
            timeAgo: '6d ago',
          ),
          const _DashboardActivityItem(
            icon: Icons.trending_up_rounded,
            title: 'Attendance Recovery',
            subtitle: '6 at-risk students improved above 75% attendance threshold this month',
            timeAgo: '1w ago',
          ),
        ],
      );
    } else if (isSemester) {
      final spots = [
        const FlSpot(0, 71),
        const FlSpot(1, 76),
        const FlSpot(2, 84),
        const FlSpot(3, 79),
        const FlSpot(4, 91),
      ];
      int peakIdx = 4;
      double avg = 80.2;
      if (_selectedBatchFilter == 'CS Dept') {
        avg = 86.4;
      } else if (_selectedBatchFilter == 'Business') {
        avg = 73.1;
      } else if (_selectedBatchFilter == 'Engineering') {
        avg = 82.5;
      } else if (_selectedBatchFilter == 'Health Sci') {
        avg = 74.9;
      }

      final totalPool = (baseRegistered * 16);
      final present = (totalPool * (avg / 100)).round();
      final late = (totalPool * 0.12).round();
      final absent = (totalPool - present - late).clamp(1, 100000);

      return _DashboardMetricsData(
        periodBadge: 'SEMESTER',
        periodLabel: 'Semester',
        registeredCount: baseRegistered,
        avgAttendance: avg,
        activeRoadmaps: (142 * batchMultiplier).round().clamp(12, 142),
        atRiskCount: (_selectedBatchFilter == 'All Batches' ? 7 : (7 * batchMultiplier).round().clamp(1, 7)),
        xLabels: const ['SEP', 'OCT', 'NOV', 'DEC', 'JAN'],
        spots: spots,
        peakIndex: peakIdx,
        presentCount: present.clamp(1, 100000),
        lateCount: late.clamp(1, 100000),
        absentCount: absent,
        activities: [
          const _DashboardActivityItem(
            icon: Icons.school_outlined,
            title: 'Dogma Curriculum Milestone',
            subtitle: '142 students completed Semester 1 Patristics & Church History checkpoints',
            timeAgo: '2w ago',
          ),
          const _DashboardActivityItem(
            icon: Icons.people_outline,
            title: 'Campus Spiritual Families',
            subtitle: '8 new spiritual families successfully matched with elder mentor students',
            timeAgo: '3w ago',
          ),
          const _DashboardActivityItem(
            icon: Icons.verified_outlined,
            title: 'Midterm Retention Audit',
            subtitle: 'First-year student retention in campus fellowship remained at 93.4%',
            timeAgo: '1mo ago',
          ),
        ],
      );
    } else if (isAnnual) {
      final spots = [
        const FlSpot(0, 75),
        const FlSpot(1, 82),
        const FlSpot(2, 86),
        const FlSpot(3, 88),
      ];
      int peakIdx = 3;
      double avg = 82.8;
      if (_selectedBatchFilter == 'CS Dept') {
        avg = 89.2;
      } else if (_selectedBatchFilter == 'Business') {
        avg = 76.5;
      } else if (_selectedBatchFilter == 'Engineering') {
        avg = 85.0;
      } else if (_selectedBatchFilter == 'Health Sci') {
        avg = 77.2;
      }

      final totalPool = (baseRegistered * 36);
      final present = (totalPool * (avg / 100)).round();
      final late = (totalPool * 0.11).round();
      final absent = (totalPool - present - late).clamp(1, 100000);

      return _DashboardMetricsData(
        periodBadge: 'ANNUAL',
        periodLabel: 'Annual',
        registeredCount: (baseRegistered * 1.15).round(),
        avgAttendance: avg,
        activeRoadmaps: (310 * batchMultiplier).round().clamp(25, 310),
        atRiskCount: (_selectedBatchFilter == 'All Batches' ? 4 : (4 * batchMultiplier).round().clamp(1, 4)),
        xLabels: const ['TERM 1', 'TERM 2', 'TERM 3', 'TERM 4'],
        spots: spots,
        peakIndex: peakIdx,
        presentCount: present.clamp(1, 100000),
        lateCount: late.clamp(1, 100000),
        absentCount: absent,
        activities: [
          const _DashboardActivityItem(
            icon: Icons.emoji_events_outlined,
            title: 'Annual General Assembly',
            subtitle: 'Fellowship executive board approved 2025/2026 spiritual & administrative report',
            timeAgo: '1mo ago',
          ),
          const _DashboardActivityItem(
            icon: Icons.directions_bus_outlined,
            title: 'Graduating Batch Pilgrimage',
            subtitle: '58 graduating senior students completed annual pilgrimage to holy sites',
            timeAgo: '2mo ago',
          ),
          const _DashboardActivityItem(
            icon: Icons.savings_outlined,
            title: 'Annual Charity Campaign',
            subtitle: 'Over 250,000 ETB mobilized for student welfare & urgent hospital care',
            timeAgo: '3mo ago',
          ),
        ],
      );
    } else {
      // Default: 'This Week'
      final spots = [
        const FlSpot(0, 68),
        const FlSpot(1, 79),
        const FlSpot(2, 73),
        const FlSpot(3, 88),
        const FlSpot(4, 82),
      ];
      int peakIdx = 3;
      double avg = 78.0;
      if (_selectedBatchFilter == 'CS Dept') {
        avg = 85.6;
      } else if (_selectedBatchFilter == 'Business') {
        avg = 71.2;
      } else if (_selectedBatchFilter == 'Engineering') {
        avg = 81.3;
      } else if (_selectedBatchFilter == 'Health Sci') {
        avg = 72.5;
      }

      final totalPool = (baseRegistered);
      final present = (totalPool * (avg / 100)).round();
      final late = (totalPool * 0.15).round();
      final absent = (totalPool - present - late).clamp(1, 100000);

      return _DashboardMetricsData(
        periodBadge: 'WEEKLY',
        periodLabel: 'This Week',
        registeredCount: baseRegistered,
        avgAttendance: avg,
        activeRoadmaps: (state.activeRoadmapsCount * batchMultiplier).round().clamp(5, 50),
        atRiskCount: (_selectedBatchFilter == 'All Batches'
            ? state.atRiskStudentsCount
            : (state.atRiskStudentsCount * batchMultiplier).round().clamp(1, 20)),
        xLabels: const ['MON', 'TUE', 'WED', 'THU', 'FRI'],
        spots: spots,
        peakIndex: peakIdx,
        presentCount: present.clamp(1, 100000),
        lateCount: late.clamp(1, 100000),
        absentCount: absent,
        activities: [
          _DashboardActivityItem(
            icon: Icons.person_off_outlined,
            title: 'Sarah Jenkins',
            subtitle: 'Missed 3 consecutive classes (Attendance: 68%)',
            timeAgo: '2h ago',
            isRisk: true,
            onActionTap: () => state.launchCall('+251933445566'),
          ),
          const _DashboardActivityItem(
            icon: Icons.warning_amber_rounded,
            title: 'CS101 Batch',
            subtitle: 'Batch attendance dropped below 70% threshold',
            timeAgo: '4h ago',
            isRisk: true,
          ),
          const _DashboardActivityItem(
            icon: Icons.check_circle_outline,
            title: 'System Update',
            subtitle: 'Weekly attendance report auto-generated for fellowship board',
            timeAgo: '1d ago',
          ),
        ],
      );
    }
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

          // Horizontal Batch Filter Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _batches.map((batch) {
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

                // fl_chart Line/Area Curve
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
                      maxX: (metrics.spots.length - 1).toDouble(),
                      minY: 40,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: metrics.spots,
                          isCurved: true,
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

                // Horizontal Segmented Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        Expanded(
                          flex: metrics.presentCount,
                          child: Container(color: primaryAccent),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: metrics.lateCount,
                          child: Container(color: const Color(0xFF93B5E1)),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          flex: metrics.absentCount,
                          child: Container(color: const Color(0xFFF87171)),
                        ),
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
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                child: Text('VIEW ALL', style: TextStyle(color: primaryAccent, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Period-Specific Activity Cards
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
