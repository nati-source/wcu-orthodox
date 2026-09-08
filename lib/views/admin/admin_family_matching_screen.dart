import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_fellowship_card.dart';

class AdminFamilyMatchingScreen extends StatefulWidget {
  final FellowshipState state;

  const AdminFamilyMatchingScreen({super.key, required this.state});

  @override
  State<AdminFamilyMatchingScreen> createState() => _AdminFamilyMatchingScreenState();
}

class _AdminFamilyMatchingScreenState extends State<AdminFamilyMatchingScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedStudentToSwap;
  String? _sourceFamilyId;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleStudentSwapTap(String studentId, String familyId) {
    HapticFeedback.selectionClick();

    if (_selectedStudentToSwap == null) {
      // First selection (Family A)
      setState(() {
        _selectedStudentToSwap = studentId;
        _sourceFamilyId = familyId;
      });
    } else {
      if (_selectedStudentToSwap == studentId) {
        // Deselect
        setState(() {
          _selectedStudentToSwap = null;
          _sourceFamilyId = null;
        });
      } else {
        // Second selection (Family B) - Show Interactive Comparison BottomSheet
        final studentA = widget.state.allStudents.firstWhere(
          (s) => s.id == _selectedStudentToSwap,
          orElse: () => widget.state.currentUser,
        );
        final studentB = widget.state.allStudents.firstWhere(
          (s) => s.id == studentId,
          orElse: () => widget.state.currentUser,
        );
        final familyA = widget.state.families.firstWhere(
          (f) => f.id == _sourceFamilyId,
          orElse: () => widget.state.families.first,
        );
        final familyB = widget.state.families.firstWhere(
          (f) => f.id == familyId,
          orElse: () => widget.state.families.last,
        );

        _showSwapConfirmationBottomSheet(
          studentA: studentA,
          familyA: familyA,
          studentB: studentB,
          familyB: familyB,
        );
      }
    }
  }

  void _showSwapConfirmationBottomSheet({
    required UserModel studentA,
    required FamilyModel familyA,
    required UserModel studentB,
    required FamilyModel familyB,
  }) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: primaryAccent.withOpacity(0.4), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.swap_horiz_rounded, color: primaryAccent, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'Confirm Student Swap',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'The following students will be atomically exchanged between their respective fellowship families:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: textMuted),
                ),
                const SizedBox(height: 20),

                // Side-by-Side Comparison Cards
                Row(
                  children: [
                    // Student A Card
                    Expanded(
                      child: _buildStudentSwapCard(
                        theme: theme,
                        student: studentA,
                        currentFamily: familyA.name,
                        targetFamily: familyB.name,
                        accentColor: primaryAccent,
                        isDark: isDark,
                      ),
                    ),

                    // Central Swap Arrow
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: primaryAccent.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryAccent.withOpacity(0.4)),
                      ),
                      child: Icon(Icons.swap_horiz, color: primaryAccent, size: 22),
                    ),

                    // Student B Card
                    Expanded(
                      child: _buildStudentSwapCard(
                        theme: theme,
                        student: studentB,
                        currentFamily: familyB.name,
                        targetFamily: familyA.name,
                        accentColor: const Color(0xFF60A5FA),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons (Confirm & Cancel)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, color: textCol)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          HapticFeedback.mediumImpact();

                          widget.state.swapStudentsBetweenFamilies(
                            studentAId: studentA.id,
                            familyAId: familyA.id,
                            studentBId: studentB.id,
                            familyBId: familyB.id,
                          );

                          setState(() {
                            _selectedStudentToSwap = null;
                            _sourceFamilyId = null;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle, color: AppTheme.emerald, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Swapped ${studentA.fullName.split(' ').first} ⇄ ${studentB.fullName.split(' ').first} between families!',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              duration: const Duration(seconds: 3),
                              backgroundColor: cardBg,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: Text(
                          'Confirm Swap',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentSwapCard({
    required ThemeData theme,
    required UserModel student,
    required String currentFamily,
    required String targetFamily,
    required Color accentColor,
    required bool isDark,
  }) {
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevatedBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: accentColor.withOpacity(0.2),
            child: Text(
              student.fullName.isNotEmpty ? student.fullName[0] : 'S',
              style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            student.fullName,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'B.N. ${student.baptismalName}',
            style: TextStyle(
              fontSize: 11,
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            student.department,
            style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '→ $targetFamily',
              style: const TextStyle(fontSize: 9, color: AppTheme.emerald, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showPublishConfirmation() {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.cell_tower, color: primaryAccent, size: 28),
            const SizedBox(width: 10),
            Text(
              'Publish & Broadcast Roster',
              style: TextStyle(
                fontFamily: 'serif',
                color: textCol,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Text(
          'This will atomically release the family assignments to all active student devices, notify members via push alert, and unlock Spiritual Father & Mother contact cards. Proceed?',
          style: TextStyle(color: textMuted, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              widget.state.publishAndBroadcastFamilies();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Atomic Broadcast Sent! Family rosters are now live for all students.'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Publish & Broadcast',
              style: TextStyle(
                color: isDark ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final families = state.families;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    final selectedStudent = _selectedStudentToSwap != null
        ? state.allStudents.firstWhere(
            (s) => s.id == _selectedStudentToSwap,
            orElse: () => state.currentUser,
          )
        : null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Spiritual Parent Matching', style: TextStyle(color: textCol)),
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Swap Banner when a student is selected
            if (_selectedStudentToSwap != null && selectedStudent != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.18),
                  border: Border(bottom: BorderSide(color: primaryAccent.withOpacity(0.5))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.swap_horiz, color: primaryAccent, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select another student to swap with',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: textCol,
                            ),
                          ),
                          Text(
                            'Selected: ${selectedStudent.fullName} (${selectedStudent.baptismalName})',
                            style: TextStyle(
                              fontSize: 11,
                              color: primaryAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      color: primaryAccent,
                      tooltip: 'Cancel Swap',
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedStudentToSwap = null;
                          _sourceFamilyId = null;
                        });
                      },
                    ),
                  ],
                ),
              ),

            // Scrollable Roster Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Screen Title
                    Text(
                      'Spiritual Parent\nSelection',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Status pill: Assigned • Pending
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
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.pendingRose,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${state.pendingApprovals.length} Pending',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                            fontWeight: FontWeight.w600,
                          ),
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
                                HapticFeedback.selectionClick();
                                await state.runSmartMatching();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Constrained matching complete: Students balanced by department & faculty.'),
                                      backgroundColor: cardBg,
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: state.isMatchingRunning
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(color: isDark ? Colors.black : Colors.white, strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Executing Constrained Solver...',
                                    style: TextStyle(
                                      color: isDark ? Colors.black : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Run Smart Matching',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.black : Colors.white,
                                  letterSpacing: 0.3,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Family Group Cards with Select-to-Swap
                    ...families.map((family) {
                      final members = state.allStudents.where((s) => family.memberIds.contains(s.id)).toList();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: borderCol),
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
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: textCol,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${family.spiritualFather.fullName.split(' ').first} & ${family.spiritualMother.fullName.split(' ').first}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: primaryAccent.withOpacity(0.4)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.people, size: 14, color: primaryAccent),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${members.length}/${family.maxCapacity}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: primaryAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // List of Students with Swap Trigger Buttons & Pulse Border
                            ...members.map((student) {
                              final isSelectedForSwap = _selectedStudentToSwap == student.id;

                              return AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  final pulseOpacity = isSelectedForSwap ? _pulseAnimation.value : 0.0;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => _handleStudentSwapTap(student.id, family.id),
                                        borderRadius: BorderRadius.circular(14),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 180),
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                          decoration: BoxDecoration(
                                            color: isSelectedForSwap
                                                ? primaryAccent.withOpacity(0.2)
                                                : elevatedBg,
                                            borderRadius: BorderRadius.circular(14),
                                            border: Border.all(
                                              color: isSelectedForSwap
                                                  ? primaryAccent.withOpacity(0.4 + (pulseOpacity * 0.6))
                                                  : borderCol,
                                              width: isSelectedForSwap ? 2.0 : 1.0,
                                            ),
                                            boxShadow: isSelectedForSwap
                                                ? [
                                                    BoxShadow(
                                                      color: primaryAccent.withOpacity(0.3 * pulseOpacity),
                                                      blurRadius: 10 * pulseOpacity,
                                                      spreadRadius: 1,
                                                    ),
                                                  ]
                                                : null,
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
                                                        color: isSelectedForSwap
                                                            ? primaryAccent
                                                            : textCol,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${student.department} • Batch \'${student.batchYear.length > 2 ? student.batchYear.substring(2) : student.batchYear}',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: textMuted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: isSelectedForSwap
                                                      ? primaryAccent.withOpacity(0.25)
                                                      : Colors.transparent,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.swap_horiz,
                                                  color: isSelectedForSwap ? primaryAccent : textMuted,
                                                  size: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
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

            // Bottom Publish & Broadcast Action Bar
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(top: BorderSide(color: borderCol)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.isFamilyPublished ? 'Roster is Live' : 'Roster is Staged',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: state.isFamilyPublished ? AppTheme.emerald : primaryAccent,
                          ),
                        ),
                        Text(
                          state.isFamilyPublished ? 'All students can view their family' : 'Ready to push to student devices',
                          style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showPublishConfirmation,
                    icon: Icon(Icons.send_rounded, size: 18, color: isDark ? Colors.black : Colors.white),
                    label: Text(
                      state.isFamilyPublished ? 'Re-Broadcast' : 'Publish & Broadcast',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
