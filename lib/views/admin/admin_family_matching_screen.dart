import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminFamilyMatchingScreen extends StatefulWidget {
  final FellowshipState state;

  const AdminFamilyMatchingScreen({super.key, required this.state});

  @override
  State<AdminFamilyMatchingScreen> createState() => _AdminFamilyMatchingScreenState();
}

class _AdminFamilyMatchingScreenState extends State<AdminFamilyMatchingScreen> {
  String? _selectedStudentToSwap;
  String? _sourceFamilyId;

  void _handleStudentSwapTap(String studentId, String familyId) {
    if (_selectedStudentToSwap == null) {
      setState(() {
        _selectedStudentToSwap = studentId;
        _sourceFamilyId = familyId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected student for swap. Now tap another student in a different family to swap them.'),
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      if (_selectedStudentToSwap == studentId) {
        setState(() {
          _selectedStudentToSwap = null;
          _sourceFamilyId = null;
        });
      } else {
        // Perform Swap
        widget.state.swapStudentsBetweenFamilies(
          studentAId: _selectedStudentToSwap!,
          familyAId: _sourceFamilyId!,
          studentBId: studentId,
          familyBId: familyId,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Students successfully swapped between families!'),
            backgroundColor: AppTheme.surfaceColor,
          ),
        );

        setState(() {
          _selectedStudentToSwap = null;
          _sourceFamilyId = null;
        });
      }
    }
  }

  void _showPublishConfirmation() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.cell_tower, color: AppTheme.goldAccent, size: 28),
            SizedBox(width: 10),
            Text(
              'Publish & Broadcast Roster',
              style: TextStyle(fontFamily: 'serif', color: AppTheme.goldLight, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text(
          'This will atomically release the family assignments to all active student devices, notify members via push alert, and unlock Spiritual Father & Mother contact cards. Proceed?',
          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textTertiary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.state.publishAndBroadcastFamilies();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Atomic Broadcast Sent! Family rosters are now live for all students.'),
                  backgroundColor: AppTheme.surfaceColor,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE57E12)),
            child: const Text('Publish & Broadcast', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final families = state.families;

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Screen Title matching manag1 - Copy.png
                    const Text(
                      'Spiritual Parent\nSelection',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFF7CA88),
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status pill: 12 Assigned • 4 Pending
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.emerald,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${state.allStudents.length} Assigned',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF87171),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${state.pendingApprovals.length} Pending',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Run Smart Matching Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.isMatchingRunning
                            ? null
                            : () async {
                                await state.runSmartMatching();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Constrained matching complete: Students balanced by department & faculty.'),
                                      backgroundColor: AppTheme.surfaceColor,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD4690B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: state.isMatchingRunning
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Executing Constrained Solver...',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : const Text(
                                'Run Smart Matching',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Family Group Cards with Select-to-Swap matching manag1 - Copy.png
                    ...families.map((family) {
                      final members = state.allStudents.where((s) => family.memberIds.contains(s.id)).toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppTheme.borderMuted),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Family Header: Name, Parents & Capacity Pill
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        family.name,
                                        style: const TextStyle(
                                          fontFamily: 'serif',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${family.spiritualFather.fullName.split(' ').first} & ${family.spiritualMother.fullName.split(' ').first}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C2417),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.people, size: 14, color: AppTheme.goldLight),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${members.length}/${family.maxCapacity}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.goldLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // List of Students with Swap Trigger Buttons
                            ...members.map((student) {
                              final isSelectedForSwap = _selectedStudentToSwap == student.id;

                              return InkWell(
                                onTap: () => _handleStudentSwapTap(student.id, family.id),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelectedForSwap
                                        ? AppTheme.goldAccent.withOpacity(0.25)
                                        : const Color(0xFF26201B),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelectedForSwap
                                          ? AppTheme.goldLight
                                          : AppTheme.borderMuted.withOpacity(0.5),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              student.fullName,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: isSelectedForSwap ? AppTheme.goldLight : Colors.white,
                                              ),
                                            ),
                                            Text(
                                              '${student.department} • Batch \'${student.batchYear.length > 2 ? student.batchYear.substring(2) : student.batchYear}',
                                              style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.swap_horiz,
                                        color: isSelectedForSwap ? AppTheme.goldLight : AppTheme.textSecondary,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Bottom Bar: Draft Mode Toggle & Publish & Broadcast Action
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0E131B),
                border: const Border(top: BorderSide(color: AppTheme.borderMuted)),
              ),
              child: Row(
                children: [
                  // Draft Mode Indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'STATUS',
                        style: TextStyle(fontSize: 9, color: AppTheme.textTertiary, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        state.isFamilyPublished ? 'Published' : 'Draft Mode',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: state.isFamilyPublished ? AppTheme.emerald : AppTheme.goldLight,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),

                  // Publish & Broadcast Button matching manag1 - Copy.png
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _showPublishConfirmation,
                        icon: const Icon(Icons.cell_tower, color: Colors.black, size: 18),
                        label: const Text(
                          'Publish & Broadcast',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF7CA88),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
