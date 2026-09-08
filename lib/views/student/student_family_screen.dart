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
                                  Text(
                                    '${state.currentFamilySiblings.length + 1} Members • ${family.formedDate}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textMuted,
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

                  // Telegram Group Button
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => state.launchTelegram(family.telegramGroupUrl),
                        icon: Icon(Icons.send_rounded, color: isDark ? Colors.black : Colors.white, size: 20),
                        label: Text(
                          'Join Telegram Group',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                Text(
                  'Fellowship Siblings',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'B.N. ${parent.baptismalName}',
            style: TextStyle(
              fontSize: 13,
              color: primaryAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            parent.department,
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
                    Row(
                      children: [
                        _buildTag(sibling.department, theme),
                        const SizedBox(width: 6),
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
