import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_fellowship_card.dart';

class StudentFamilyScreen extends StatelessWidget {
  final FellowshipState state;

  const StudentFamilyScreen({super.key, required this.state});

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

    final family = state.currentStudentFamily;
    final isPublished = state.isFamilyPublished;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // If Staged (Unpublished), show the Staged Family Card
          if (!isPublished) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryAccent.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.lock_clock, color: primaryAccent, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Family Roster In Preparation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Fellowship coordinators are currently running the constrained matching engine to assign students by department and faculty cluster. Your Spiritual Parents and sibling contact cards will unlock as soon as the roster is published.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (family != null) ...[
            // Released Roster View
            // 1. Family Banner Card
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderCol),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Banner Header Image / Graphic
                  Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      gradient: LinearGradient(
                        colors: [
                          primaryAccent.withOpacity(0.8),
                          primaryAccent.withOpacity(0.4),
                          cardBg,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Center(
                            child: Icon(
                              Icons.shield_outlined,
                              size: 80,
                              color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.06),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          bottom: 14,
                          right: 18,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                family.name,
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: textCol,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(Icons.group, size: 14, color: textMuted),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${state.currentFamilySiblings.length + 1} Members • ${family.formedDate}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textMuted,
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

                  // Telegram Group Actions
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () => state.launchTelegram(family.telegramGroupUrl),
                                  icon: Icon(Icons.send_rounded, color: isDark ? Colors.black : Colors.white, size: 20),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Join Telegram Group / ተቀላቀል',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.black : Colors.white,
                                      ),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ),
                            if (state.activeRole == UserRole.spiritualParent || state.isAdmin) ...[
                              const SizedBox(width: 10),
                              IconButton.filledTonal(
                                tooltip: 'Edit Telegram Group Link',
                                onPressed: () => _openEditTelegramDialog(context, state, family),
                                icon: const Icon(Icons.edit, size: 20),
                                style: IconButton.styleFrom(
                                  backgroundColor: primaryAccent.withOpacity(0.15),
                                  foregroundColor: primaryAccent,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  padding: const EdgeInsets.all(12),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (state.activeRole == UserRole.spiritualParent || state.isAdmin) ...[
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline, size: 13, color: textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Spiritual Parents: Tap the pencil icon to set the Telegram invite link for your children.',
                                  style: TextStyle(fontSize: 11, color: textMuted, height: 1.3),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            if (state.activeRole == UserRole.spiritualParent) ...[
              _buildSpiritualChildrenOverviewSection(context, state),
              const SizedBox(height: 24),
            ],

            // Section: Spiritual Parents
            Text(
              'Spiritual Parents',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textCol,
              ),
            ),
            const SizedBox(height: 14),

            // Spiritual Father Card
            _buildParentCard(
              context: context,
              parent: family.spiritualFather,
              roleBadge: 'Spiritual Father',
              onCall: () => state.launchCall(family.spiritualFather.phoneNumber),
              onSms: () => state.launchSms(family.spiritualFather.phoneNumber, body: 'Greetings Spiritual Father, this is ${state.currentUser.fullName} (${state.currentUser.baptismalName}).'),
            ),

            const SizedBox(height: 14),

            // Spiritual Mother Card
            _buildParentCard(
              context: context,
              parent: family.spiritualMother,
              roleBadge: 'Spiritual Mother',
              onCall: () => state.launchCall(family.spiritualMother.phoneNumber),
              onSms: () => state.launchSms(family.spiritualMother.phoneNumber, body: 'Greetings Spiritual Mother, this is ${state.currentUser.fullName} (${state.currentUser.baptismalName}).'),
            ),

            const SizedBox(height: 28),

            // Section: Fellowship Siblings
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Fellowship Siblings',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${state.currentFamilySiblings.length} Members',
                  style: TextStyle(fontSize: 13, color: textMuted),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Sibling Roster List with Contact Reveal Micro-Interaction
            ...state.currentFamilySiblings.map((sibling) {
              return _InteractiveSiblingTile(
                sibling: sibling,
                state: state,
              );
            }),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildParentCard({
    required BuildContext context,
    required SpiritualParentModel parent,
    required String roleBadge,
    required VoidCallback onCall,
    required VoidCallback onSms,
  }) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: elevatedBg,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: primaryAccent.withOpacity(0.6), width: 2),
              ),
              child: Center(
                child: Icon(
                  roleBadge.contains('Father') ? Icons.person : Icons.person_3,
                  size: 40,
                  color: primaryAccent,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Role Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: primaryAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryAccent.withOpacity(0.4)),
            ),
            child: Text(
              roleBadge,
              style: TextStyle(
                fontSize: 12,
                color: primaryAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Name & Baptismal Name
          Text(
            parent.fullName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'B.N. ${parent.baptismalName}',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: primaryAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            parent.department,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 16),

          // Call and SMS Shortcut Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoundActionBtn(
                context: context,
                icon: Icons.phone,
                onTap: onCall,
                tooltip: 'Call Spiritual Parent',
              ),
              const SizedBox(width: 20),
              _buildRoundActionBtn(
                context: context,
                icon: Icons.message_outlined,
                onTap: onSms,
                tooltip: 'SMS Spiritual Parent',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundActionBtn({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: elevatedBg,
          shape: BoxShape.circle,
          border: Border.all(color: borderCol),
        ),
        child: Icon(icon, color: primaryAccent, size: 20),
      ),
    );
  }

  Widget _buildSpiritualChildrenOverviewSection(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = theme.dividerColor;
    final children = state.spiritualChildren;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.family_restroom, color: primaryAccent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'My Spiritual Children • የመንፈስ ልጆቼ',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryAccent.withOpacity(0.4)),
              ),
              child: Text(
                '${children.length} Assigned',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Track their catechism roadmap progress, attendance records, and reach out directly.',
          style: TextStyle(fontSize: 12, color: textMuted, height: 1.3),
        ),
        const SizedBox(height: 12),
        if (children.isEmpty)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderCol),
            ),
            child: Center(
              child: Text(
                'No spiritual children currently assigned to this family.',
                style: TextStyle(fontSize: 13, color: textMuted),
              ),
            ),
          )
        else
          ...children.map((child) => _buildSpiritualChildCard(context, state, child)),
      ],
    );
  }

  Widget _buildSpiritualChildCard(BuildContext context, FellowshipState state, UserModel child) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final roadmaps = state.getRoadmapsForStudent(child.id);
    final completedCount = roadmaps.where((r) => r.status == RoadmapStatus.completed).length;
    final inProgressCount = roadmaps.where((r) => r.status == RoadmapStatus.inProgress).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: primaryAccent.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: primaryAccent.withOpacity(0.15),
                child: Text(
                  child.fullName.isNotEmpty ? child.fullName[0] : 'S',
                  style: TextStyle(
                    color: primaryAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      child.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'የክርስትና ስም: ${child.baptismalName} • Year ${child.academicYear} (Batch ${child.batchYear})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: primaryAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${child.department} • ${child.ministryStatus}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: child.attendancePercentage >= 75
                      ? AppTheme.emerald.withOpacity(0.15)
                      : AppTheme.crimson.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: child.attendancePercentage >= 75
                        ? AppTheme.emerald.withOpacity(0.4)
                        : AppTheme.crimson.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '${child.attendancePercentage.toInt()}%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: child.attendancePercentage >= 75 ? AppTheme.emerald : AppTheme.crimson,
                      ),
                    ),
                    Text(
                      'Attendance',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        color: child.attendancePercentage >= 75 ? AppTheme.emerald : AppTheme.crimson,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Roadmap Progress Summary Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: elevatedBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.emerald),
                        const SizedBox(width: 4),
                        Text(
                          '$completedCount Done',
                          style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.timelapse, size: 14, color: primaryAccent),
                        const SizedBox(width: 4),
                        Text(
                          '$inProgressCount In Progress',
                          style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book, size: 14, color: textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${roadmaps.length} Phases',
                          style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: child.phoneNumber.isNotEmpty && child.phoneNumber != '-'
                      ? () => state.launchCall(child.phoneNumber)
                      : null,
                  icon: const Icon(Icons.phone, size: 14),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('ደውል', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryAccent,
                    side: BorderSide(color: primaryAccent.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: child.phoneNumber.isNotEmpty && child.phoneNumber != '-'
                      ? () => state.launchSms(
                            child.phoneNumber,
                            body: 'ሰላም ${child.baptismalName}፣ የመንፈሳዊ ትምህርት ጉዞህን/ሽን በተመለከተ...',
                          )
                      : null,
                  icon: const Icon(Icons.sms_outlined, size: 14),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('SMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryAccent,
                    side: BorderSide(color: primaryAccent.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showChildRoadmapDialog(context, state, child, roadmaps),
                  icon: const Icon(Icons.auto_graph, size: 14),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Roadmap', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChildRoadmapDialog(BuildContext context, FellowshipState state, UserModel child, List<RoadmapPhaseModel> roadmaps) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${child.fullName} • Roadmap Progress',
                    style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: textCol),
                  ),
                  Text(
                    'የክርስትና ስም: ${child.baptismalName} • Attendance: ${child.attendancePercentage.toInt()}%',
                    style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  if (roadmaps.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(child: Text('No roadmaps available.', style: TextStyle(color: textMuted))),
                    )
                  else
                    ...roadmaps.map((phase) {
                      final isDone = phase.status == RoadmapStatus.completed;
                      final isInProgress = phase.status == RoadmapStatus.inProgress;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isDone
                                ? AppTheme.emerald.withOpacity(0.5)
                                : (isInProgress ? primaryAccent.withOpacity(0.5) : theme.dividerColor),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isDone
                                      ? Icons.check_circle
                                      : (isInProgress ? Icons.timelapse : Icons.lock_outline),
                                  color: isDone
                                      ? AppTheme.emerald
                                      : (isInProgress ? primaryAccent : textMuted),
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    phase.title,
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                                  ),
                                ),
                                Text(
                                  '${(phase.progress * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDone
                                        ? AppTheme.emerald
                                        : (isInProgress ? primaryAccent : textMuted),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: phase.progress,
                              backgroundColor: theme.dividerColor.withOpacity(0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isDone ? AppTheme.emerald : primaryAccent,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 5,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${phase.weeklyLessons.length} Weekly Lessons • Instructor: ${phase.instructor}',
                              style: TextStyle(fontSize: 10, color: textMuted),
                            ),
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

  void _openEditTelegramDialog(BuildContext context, FellowshipState state, FamilyModel family) {
    final theme = Theme.of(context);
    final linkController = TextEditingController(text: family.telegramGroupUrl);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.send_rounded, color: Color(0xFF229ED9), size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Telegram Group Link',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Set or update the Telegram group invite link for ${family.name}. Spiritual children will tap "Join Telegram Group" to enter your family chat.',
                style: TextStyle(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: linkController,
                style: TextStyle(color: theme.colorScheme.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Telegram Invite Link',
                  hintText: 'https://t.me/+...',
                  prefixIcon: const Icon(Icons.link, color: Color(0xFF229ED9)),
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a Telegram group link';
                  }
                  if (!val.trim().contains('t.me')) {
                    return 'Must be a valid Telegram link (contains t.me)';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final newUrl = linkController.text.trim();
                state.updateFamilyTelegramLink(family.id, newUrl);
                Navigator.pop(ctx);
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.emerald, size: 20),
                        SizedBox(width: 8),
                        Text('Telegram group link updated successfully!'),
                      ],
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Save Link / አስቀምጥ', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _InteractiveSiblingTile extends StatefulWidget {
  final UserModel sibling;
  final FellowshipState state;

  const _InteractiveSiblingTile({
    required this.sibling,
    required this.state,
  });

  @override
  State<_InteractiveSiblingTile> createState() => _InteractiveSiblingTileState();
}

class _InteractiveSiblingTileState extends State<_InteractiveSiblingTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final sibling = widget.sibling;

    return InteractiveFellowshipCard(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 10),
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderColor: _isExpanded ? primaryAccent.withOpacity(0.6) : theme.dividerColor,
      borderWidth: _isExpanded ? 1.5 : 1.0,
      showWatermark: true,
      watermarkSize: 70,
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: elevatedBg,
                child: Text(
                  sibling.fullName.isNotEmpty ? sibling.fullName[0] : 'S',
                  style: TextStyle(
                    color: primaryAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sibling.fullName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'B.N. ${sibling.baptismalName}',
                      style: TextStyle(
                        fontSize: 12,
                        color: primaryAccent,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _buildTag(sibling.department, theme),
                        _buildTag(
                          'Batch \'${sibling.batchYear.length > 2 ? sibling.batchYear.substring(2) : sibling.batchYear}',
                          theme,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expand / Quick Action Icon
              IconButton(
                icon: AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: primaryAccent,
                    size: 22,
                  ),
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  setState(() => _isExpanded = !_isExpanded);
                },
              ),
            ],
          ),

          // Expanded Contact Actions Bar
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 14),
              child: Column(
                children: [
                  Divider(color: theme.dividerColor, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Direct Call
                      _buildContactAction(
                        icon: Icons.phone,
                        label: 'Call',
                        color: const Color(0xFF10B981),
                        onTap: () => widget.state.launchCall(sibling.phoneNumber),
                      ),

                      // Direct SMS
                      _buildContactAction(
                        icon: Icons.chat_bubble_outline,
                        label: 'SMS',
                        color: primaryAccent,
                        onTap: () => widget.state.launchSms(
                          sibling.phoneNumber,
                          body: 'Selam ${sibling.baptismalName}, this is ${widget.state.currentUser.fullName} from our fellowship family.',
                        ),
                      ),

                      // Direct Telegram
                      _buildContactAction(
                        icon: Icons.send_rounded,
                        label: 'Telegram',
                        color: const Color(0xFF0284C7),
                        onTap: () => widget.state.launchTelegram('https://t.me/+251911223344'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }

  Widget _buildContactAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.4)),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color),
      ),
    );
  }
}
