import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback onOpenFamilyMatching;
  final VoidCallback onOpenLiveAttendance;

  const AdminDashboardScreen({
    super.key,
    required this.state,
    required this.onOpenFamilyMatching,
    required this.onOpenLiveAttendance,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedTimeFilter = 'This Week';
  String _selectedBatchFilter = 'All Batches';

  final List<String> _batches = ['All Batches', 'CS Dept', 'Business', 'Engineering', 'Health Sci'];

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

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
                    value: _selectedTimeFilter,
                    dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                    icon: Icon(Icons.keyboard_arrow_down, color: primaryAccent, size: 18),
                    style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.bold),
                    items: ['This Week', 'This Month', 'Semester 1', 'Annual'].map((s) {
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

          // 2x2 KPI Metrics Grid
          Row(
            children: [
              // 1. Registered
              Expanded(
                child: _buildKpiCard(
                  context: context,
                  icon: Icons.people,
                  iconColor: primaryAccent,
                  value: '${state.totalRegisteredStudents}',
                  label: 'REGISTERED',
                ),
              ),
              const SizedBox(width: 12),
              // 2. Avg Attendance
              Expanded(
                child: _buildKpiCard(
                  context: context,
                  icon: Icons.check_circle_outline,
                  iconColor: AppTheme.azure,
                  value: '${state.averageAttendanceRate}%',
                  label: 'AVG ATTENDANCE',
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
                  value: '${state.activeRoadmapsCount}',
                  label: 'ACTIVE ROADMAPS',
                ),
              ),
              const SizedBox(width: 12),
              // 4. At-Risk Students
              Expanded(
                child: _buildKpiCard(
                  context: context,
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppTheme.crimson,
                  value: '${state.atRiskStudentsCount}',
                  label: 'AT-RISK STUDENTS',
                  isWarning: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Attendance Trend Chart Card
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
                        'Attendance Trend',
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
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'WEEKLY',
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
                              const titles = ['MON', 'TUE', 'WED', 'THU', 'FRI'];
                              final index = value.toInt();
                              if (index >= 0 && index < titles.length) {
                                final isPeak = index == 3; // Thu 88%
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
                      maxX: 4,
                      minY: 40,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 68),
                            FlSpot(1, 79),
                            FlSpot(2, 73),
                            FlSpot(3, 88),
                            FlSpot(4, 82),
                          ],
                          isCurved: true,
                          curveSmoothness: 0.4,
                          color: primaryAccent,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              return FlDotCirclePainter(
                                radius: index == 3 ? 6 : 4,
                                color: index == 3 ? primaryAccent : (isDark ? Colors.black : Colors.white),
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

          // Today's Status Bar
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
                  'Today\'s Status',
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
                        // Present (75%)
                        Expanded(
                          flex: 255,
                          child: Container(color: primaryAccent),
                        ),
                        const SizedBox(width: 2),
                        // Late (15%)
                        Expanded(
                          flex: 51,
                          child: Container(color: const Color(0xFF93B5E1)),
                        ),
                        const SizedBox(width: 2),
                        // Absent (10%)
                        Expanded(
                          flex: 34,
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
                    _buildStatusLegend(context: context, color: primaryAccent, label: 'PRESENT', count: '255'),
                    _buildStatusLegend(context: context, color: const Color(0xFF93B5E1), label: 'LATE', count: '51'),
                    _buildStatusLegend(context: context, color: const Color(0xFFF87171), label: 'ABSENT', count: '34'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Recent Activity & At-Risk Dynamic Alerts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Recent Activity',
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

          // Activity 1: Sarah Jenkins at-risk alert
          _buildActivityCard(
            context: context,
            icon: Icons.person_off_outlined,
            title: 'Sarah Jenkins',
            subtitle: 'Missed 3 consecutive classes (Attendance: 68%)',
            timeAgo: '2h ago',
            isRisk: true,
            onActionTap: () {
              state.launchCall('+251933445566');
            },
          ),
          const SizedBox(height: 10),

          // Activity 2: CS101 Batch warning
          _buildActivityCard(
            context: context,
            icon: Icons.warning_amber_rounded,
            title: 'CS101 Batch',
            subtitle: 'Batch attendance dropped below 70% threshold',
            timeAgo: '4h ago',
            isRisk: true,
          ),
          const SizedBox(height: 10),

          // Activity 3: System Update
          _buildActivityCard(
            context: context,
            icon: Icons.check_circle_outline,
            title: 'System Update',
            subtitle: 'Weekly attendance report auto-generated for fellowship board',
            timeAgo: '1d ago',
          ),
          const SizedBox(height: 24),

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
