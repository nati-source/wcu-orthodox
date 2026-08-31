import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentFamilyScreen extends StatelessWidget {
  final FellowshipState state;

  const StudentFamilyScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
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
                color: AppTheme.secondaryBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.amberGlow.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.amberGlow.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.lock_clock, color: AppTheme.amberGlow, size: 28),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Family Roster In Preparation',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.goldLight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Fellowship coordinators are currently running the constrained matching engine to assign students by department and faculty cluster. Your Spiritual Parents and sibling contact cards will unlock as soon as the roster is published.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (family != null) ...[
            // Released Roster View (Matching screen2 - Copy.png)
            // 1. Family Banner Card
            Container(
              decoration: BoxDecoration(
                color: AppTheme.secondaryBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderMuted),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.35),
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
                          const Color(0xFF3E2723),
                          AppTheme.goldDeep.withOpacity(0.5),
                          const Color(0xFF1E2838),
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
                              color: Colors.white.withOpacity(0.12),
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
                                style: const TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFF7CA88),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.group, size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${state.currentFamilySiblings.length + 1} Members • ${family.formedDate}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
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
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                        label: const Text(
                          'Join Telegram Group',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4690B),
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
            const Text(
              'Spiritual Parents',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.goldLight,
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
                const Text(
                  'Fellowship Siblings',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldLight,
                  ),
                ),
                Text(
                  '${state.currentFamilySiblings.length} Members',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Sibling Roster List
            ...state.currentFamilySiblings.map((sibling) {
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
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.surfaceElevated,
                      child: Text(
                        sibling.fullName.isNotEmpty ? sibling.fullName[0] : 'S',
                        style: const TextStyle(color: AppTheme.goldLight, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sibling.fullName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildTag(sibling.department),
                              const SizedBox(width: 6),
                              _buildTag('Batch \'${sibling.batchYear.length > 2 ? sibling.batchYear.substring(2) : sibling.batchYear}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.goldLight, size: 20),
                      onPressed: () => state.launchSms(sibling.phoneNumber),
                      tooltip: 'SMS Sibling',
                    ),
                  ],
                ),
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.secondaryBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderMuted),
      ),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.surfaceElevated,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.goldAccent.withOpacity(0.6), width: 2),
              ),
              child: Center(
                child: Icon(
                  roleBadge.contains('Father') ? Icons.person : Icons.person_3,
                  size: 40,
                  color: AppTheme.goldLight,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Role Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.goldMuted.withOpacity(0.5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
            ),
            child: Text(
              roleBadge,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFF7CA88),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Name & Baptismal Name
          Text(
            parent.fullName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'B.N. ${parent.baptismalName}',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFFF5A65E),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            parent.department,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // Call and SMS Shortcut Buttons (Matching screen2 - Copy.png)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildRoundActionBtn(
                icon: Icons.phone,
                onTap: onCall,
                tooltip: 'Call Spiritual Parent',
              ),
              const SizedBox(width: 20),
              _buildRoundActionBtn(
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
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFF232D3F),
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.borderMuted),
        ),
        child: Icon(icon, color: AppTheme.goldLight, size: 20),
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
      ),
    );
  }
}
