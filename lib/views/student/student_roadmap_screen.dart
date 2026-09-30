import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentRoadmapScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback onOpenScanner;

  const StudentRoadmapScreen({
    super.key,
    required this.state,
    required this.onOpenScanner,
  });

  @override
  State<StudentRoadmapScreen> createState() => _StudentRoadmapScreenState();
}

class _StudentRoadmapScreenState extends State<StudentRoadmapScreen> {
  String? _selectedSpiritualChildId;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final isSpiritualParent = state.activeRole == UserRole.spiritualParent;

    if (isSpiritualParent) {
      return _buildSpiritualParentRoadmapView(context, state);
    }

    return _buildStandardStudentRoadmapView(context, state);
  }

  // ----------------------------------------------------
  // SPIRITUAL PARENT: SCOPED ROADMAP VIEW
  // ----------------------------------------------------
  Widget _buildSpiritualParentRoadmapView(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final currentFamily = state.currentStudentFamily;
    final children = state.spiritualChildren;

    // Default to the first spiritual child if none explicitly selected
    if (_selectedSpiritualChildId == null && children.isNotEmpty) {
      _selectedSpiritualChildId = children.first.id;
    }

    final selectedChild = children.firstWhere(
      (c) => c.id == _selectedSpiritualChildId,
      orElse: () => children.isNotEmpty
          ? children.first
          : UserModel(
              id: 'none',
              fullName: 'No assigned child',
              baptismalName: '-',
              phoneNumber: '-',
              batchYear: '-',
              department: '-',
              academicYear: 1,
            ),
    );

    final roadmaps = state.getRoadmapsForStudent(selectedChild.id);
    final isAuthorized = state.canAccessStudentRoadmap(selectedChild.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Spiritual Parent Oversight Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryAccent.withOpacity(0.18),
                  theme.cardTheme.color ?? theme.colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryAccent.withOpacity(0.5)),
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
                      child: Icon(Icons.family_restroom, color: primaryAccent, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentFamily?.name ?? 'Orthodox Family Network',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textCol,
                            ),
                          ),
                          Text(
                            'Spiritual Parent Curriculum Oversight',
                            style: TextStyle(
                              fontSize: 11,
                              color: primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Access is scoped strictly to spiritual children assigned to your family. Monitor weekly patristics study, attendance progress, and course phases.',
                  style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 2. Spiritual Children Scroller / Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'ASSIGNED SPIRITUAL CHILDREN • የመንፈስ ልጆች (${children.length})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: primaryAccent,
                  ),
                ),
              ),
              if (children.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  'Tap to switch child',
                  style: TextStyle(fontSize: 10, color: textMuted, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),

          if (children.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Center(
                child: Text('No spiritual children assigned yet in this family.', style: TextStyle(color: textMuted, fontSize: 13)),
              ),
            )
          else
            SizedBox(
              height: 78,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: children.length,
                itemBuilder: (ctx, index) {
                  final child = children[index];
                  final isSelected = child.id == _selectedSpiritualChildId;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSpiritualChildId = child.id);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 220,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryAccent.withOpacity(0.15)
                            : (theme.cardTheme.color ?? theme.colorScheme.surface),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? primaryAccent : theme.dividerColor,
                          width: isSelected ? 1.8 : 1.0,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryAccent.withOpacity(0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 20,
                            backgroundColor: isSelected
                                ? primaryAccent
                                : theme.colorScheme.surfaceContainerHighest,
                            child: Text(
                              child.fullName.isNotEmpty ? child.fullName[0] : 'S',
                              style: TextStyle(
                                color: isSelected
                                    ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
                                    : primaryAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  child.fullName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? primaryAccent : textCol,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        child.baptismalName.isNotEmpty ? child.baptismalName : 'Yr ${child.academicYear}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: textMuted,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: child.attendancePercentage >= 75
                                            ? AppTheme.emerald.withOpacity(0.2)
                                            : AppTheme.crimson.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${child.attendancePercentage.toInt()}%',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: child.attendancePercentage >= 75 ? AppTheme.emerald : AppTheme.crimson,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 18),

          // 3. Child Profile & Attendance Card with Direct Communication
          if (children.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: primaryAccent.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: primaryAccent.withOpacity(0.15),
                        child: Icon(Icons.person, color: primaryAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedChild.fullName,
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textCol),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'የክርስትና ስም: ${selectedChild.baptismalName} • Year ${selectedChild.academicYear} (${selectedChild.batchYear})',
                              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${selectedChild.department} • ${selectedChild.ministryStatus}',
                              style: TextStyle(fontSize: 10, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selectedChild.attendancePercentage >= 75
                              ? AppTheme.emerald.withOpacity(0.15)
                              : AppTheme.crimson.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedChild.attendancePercentage >= 75
                                ? AppTheme.emerald.withOpacity(0.4)
                                : AppTheme.crimson.withOpacity(0.4),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${selectedChild.attendancePercentage.toInt()}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: selectedChild.attendancePercentage >= 75 ? AppTheme.emerald : AppTheme.crimson,
                              ),
                            ),
                            Text(
                              'Attendance',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                color: selectedChild.attendancePercentage >= 75 ? AppTheme.emerald : AppTheme.crimson,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  // Quick Contact & Milestone Actions
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedChild.phoneNumber.isNotEmpty && selectedChild.phoneNumber != '-'
                              ? () => state.launchCall(selectedChild.phoneNumber)
                              : null,
                          icon: const Icon(Icons.phone, size: 15),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('ደውል (Call)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryAccent,
                            side: BorderSide(color: primaryAccent.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: selectedChild.phoneNumber.isNotEmpty && selectedChild.phoneNumber != '-'
                              ? () => state.launchSms(
                                    selectedChild.phoneNumber,
                                    body: 'ሰላም ${selectedChild.baptismalName}፣ የመንፈሳዊ ትምህርት ጉዞህን/ሽን በተመለከተ...',
                                  )
                              : null,
                          icon: const Icon(Icons.sms_outlined, size: 15),
                          label: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('መልዕክት (SMS)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryAccent,
                            side: BorderSide(color: primaryAccent.withOpacity(0.5)),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // 4. Scoped Roadmap Timeline
          if (!isAuthorized)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.crimson.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.crimson.withOpacity(0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, color: AppTheme.crimson, size: 22),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Access Denied: You can only view roadmaps of spiritual children assigned to your family.',
                      style: TextStyle(color: AppTheme.crimson, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            Text(
              'CURRICULUM ROADMAP PROGRESS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: primaryAccent,
              ),
            ),
            const SizedBox(height: 14),

            ...List.generate(roadmaps.length, (index) {
              final phase = roadmaps[index];
              final isLast = index == roadmaps.length - 1;
              return _buildTimelineItem(
                context: context,
                phase: phase,
                isLast: isLast,
              );
            }),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // STANDARD STUDENT ROADMAP VIEW
  // ----------------------------------------------------
  Widget _buildStandardStudentRoadmapView(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final roadmaps = state.roadmaps;
    final isDark = theme.brightness == Brightness.dark;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Intro Header Card
              Text(
                'Spiritual Journey',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Track your progress through the fellowship\'s core curriculum. Attend sessions and participate in study to unlock deeper mysteries of the faith.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),

              // Interactive Timeline
              ...List.generate(roadmaps.length, (index) {
                final phase = roadmaps[index];
                final isLast = index == roadmaps.length - 1;
                return _buildTimelineItem(
                  context: context,
                  phase: phase,
                  isLast: isLast,
                );
              }),
            ],
          ),
        ),

        // Floating "Check In [QR]" Button
        Positioned(
          right: 20,
          bottom: 20,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: primaryAccent,
              boxShadow: [
                BoxShadow(
                  color: primaryAccent.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: widget.onOpenScanner,
              icon: Icon(
                Icons.qr_code_scanner,
                color: isDark ? Colors.black : Colors.white,
                size: 22,
              ),
              label: Text(
                'Check In',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.black : Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineItem({
    required BuildContext context,
    required RoadmapPhaseModel phase,
    required bool isLast,
  }) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    Color indicatorColor;
    IconData indicatorIcon;

    switch (phase.status) {
      case RoadmapStatus.completed:
        indicatorColor = primaryAccent;
        indicatorIcon = Icons.check;
        break;
      case RoadmapStatus.inProgress:
        indicatorColor = primaryAccent;
        indicatorIcon = Icons.menu_book_outlined;
        break;
      case RoadmapStatus.locked:
        indicatorColor = borderCol;
        indicatorIcon = Icons.lock_outline;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Column
          SizedBox(
            width: 48,
            child: Column(
              children: [
                // Node Circle
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: cardBg,
                    border: Border.all(
                      color: indicatorColor,
                      width: phase.status == RoadmapStatus.inProgress ? 2.5 : 2,
                    ),
                    boxShadow: phase.status == RoadmapStatus.inProgress
                        ? [
                            BoxShadow(
                              color: indicatorColor.withOpacity(0.35),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Icon(indicatorIcon, color: indicatorColor, size: 18),
                ),
                // Connector Line
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: phase.status == RoadmapStatus.completed
                          ? primaryAccent
                          : borderCol,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // Phase Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: InkWell(
                onTap: () => _openPhaseLessonsSheet(context, phase),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: phase.status == RoadmapStatus.inProgress
                          ? primaryAccent.withOpacity(0.6)
                          : borderCol,
                      width: phase.status == RoadmapStatus.inProgress ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.25) : Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Header
                      Row(
                        children: [
                          if (phase.status == RoadmapStatus.completed) ...[
                            Icon(Icons.check_circle, color: primaryAccent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'COMPLETED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: primaryAccent,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ] else if (phase.status == RoadmapStatus.inProgress) ...[
                            Icon(Icons.autorenew, color: primaryAccent, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'IN PROGRESS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: primaryAccent,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ] else ...[
                            Icon(Icons.lock, color: textMuted.withOpacity(0.7), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'LOCKED',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: textMuted.withOpacity(0.7),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Title
                      Text(
                        phase.title,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Description
                      Text(
                        phase.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                          height: 1.4,
                        ),
                      ),

                      // Progress Bar if in progress
                      if (phase.status == RoadmapStatus.inProgress) ...[
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Progress',
                              style: TextStyle(fontSize: 12, color: textMuted),
                            ),
                            Text(
                              '${(phase.progress * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: phase.progress,
                            minHeight: 6,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                            valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                          ),
                        ),
                      ],

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person_pin, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              phase.instructor,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: textMuted),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'View Lessons',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(Icons.chevron_right, size: 16, color: primaryAccent),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openPhaseLessonsSheet(BuildContext context, RoadmapPhaseModel phase) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;

    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: borderCol,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    phase.title,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Instructor: ${phase.instructor} • ${phase.semester}',
                    style: TextStyle(fontSize: 13, color: textMuted),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: borderCol),
                  const SizedBox(height: 10),
                  Text(
                    'Weekly Curriculum & Reading List',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (phase.weeklyLessons.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Weekly curriculum for this phase will unlock once prerequisites are met.',
                        style: TextStyle(color: textMuted, fontSize: 13),
                      ),
                    )
                  else
                    ...phase.weeklyLessons.map((lesson) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: elevatedBg,
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
                                    lesson.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: textCol,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    lesson.isDownloaded ? Icons.download_done : Icons.download_outlined,
                                    color: lesson.isDownloaded ? AppTheme.emerald : primaryAccent,
                                  ),
                                  onPressed: () {
                                    widget.state.toggleLessonDownload(phase.id, lesson.id);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(lesson.isDownloaded
                                            ? 'Lesson removed from offline cache'
                                            : 'Downloaded for offline study'),
                                        backgroundColor: cardBg,
                                      ),
                                    );
                                  },
                                  tooltip: 'Download for Offline Reading',
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              lesson.summary,
                              style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Required Readings:',
                              style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            ...lesson.readingList.map((reading) => Padding(
                                  padding: const EdgeInsets.only(left: 4, bottom: 2),
                                  child: Row(
                                    children: [
                                      Icon(Icons.circle, size: 6, color: textMuted.withOpacity(0.5)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          reading,
                                          style: TextStyle(fontSize: 12, color: textMuted),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
