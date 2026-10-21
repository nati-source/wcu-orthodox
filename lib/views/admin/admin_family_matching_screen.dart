import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminFamilyMatchingScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback? onBackPressed;

  const AdminFamilyMatchingScreen({
    super.key,
    required this.state,
    this.onBackPressed,
  });

  @override
  State<AdminFamilyMatchingScreen> createState() =>
      _AdminFamilyMatchingScreenState();
}

class _AdminFamilyMatchingScreenState extends State<AdminFamilyMatchingScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedStudentToSwap;
  String? _sourceFamilyId;
  bool _isApplyingDraft = false;
  bool _isPublishing = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChanged);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(covariant AdminFamilyMatchingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      oldWidget.state.removeListener(_onStateChanged);
      widget.state.addListener(_onStateChanged);
    }
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChanged);
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
      if (!widget.state.canManageFamilyMatching) return;
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
        if (widget.state.families.isEmpty) return;
        final familyA = widget.state.families.firstWhere(
          (f) => f.id == _sourceFamilyId,
          orElse: () => widget.state.families.first,
        );
        final familyB = widget.state.families.firstWhere(
          (f) => f.id == familyId,
          orElse: () => widget.state.families.last,
        );

        if (familyA.id == familyB.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Choose the second student from a different family.',
              ),
            ),
          );
          return;
        }

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
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
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
            border: Border.all(
              color: primaryAccent.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: SingleChildScrollView(
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
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: primaryAccent,
                        size: 28,
                      ),
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
                          border: Border.all(
                            color: primaryAccent.withOpacity(0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.swap_horiz,
                          color: primaryAccent,
                          size: 22,
                        ),
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: textCol,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            HapticFeedback.mediumImpact();
                            try {
                              await widget.state.swapStudentsBetweenFamilies(
                                studentAId: studentA.id,
                                familyAId: familyA.id,
                                studentBId: studentB.id,
                                familyBId: familyB.id,
                              );
                              if (!mounted) return;
                              setState(() {
                                _selectedStudentToSwap = null;
                                _sourceFamilyId = null;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Swap saved as an unpublished draft. Review and publish the roster when ready.',
                                  ),
                                  duration: const Duration(seconds: 3),
                                  backgroundColor: cardBg,
                                ),
                              );
                            } catch (error) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Could not save the swap: $error',
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryAccent,
                            foregroundColor: isDark
                                ? Colors.black
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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
              style: TextStyle(
                color: accentColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
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
            style: TextStyle(
              fontSize: 10,
              color:
                  theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
            ),
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
              style: const TextStyle(
                fontSize: 9,
                color: AppTheme.emerald,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showMatchingPreview(FamilyMatchingPreview preview) async {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final muted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;
    final studentsById = {
      for (final student in widget.state.allStudents) student.id: student,
    };
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text('Review family matching plan'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${preview.assignedStudentCount} of ${preview.eligibleStudentCount} approved students can be assigned.',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'The plan keeps department groups together where capacity allows and prefers an exact department match with a parent. Saving creates an unpublished draft.',
                  style: TextStyle(color: muted, height: 1.4),
                ),
                const SizedBox(height: 16),
                ...preview.families.map((family) {
                  final assignedNames = preview.studentAssignments.entries
                      .where((entry) => entry.value == family.id)
                      .map(
                        (entry) =>
                            studentsById[entry.key]?.fullName ?? entry.key,
                      )
                      .toList();
                  final visibleNames = assignedNames.take(4).join(', ');
                  final remainingCount =
                      assignedNames.length -
                      (assignedNames.length < 4 ? assignedNames.length : 4);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.groups_2_outlined, color: primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                family.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${family.spiritualFather.fullName} & ${family.spiritualMother.fullName}',
                                style: TextStyle(fontSize: 12, color: muted),
                              ),
                              if (assignedNames.isNotEmpty)
                                Text(
                                  'Students: $visibleNames${remainingCount > 0 ? ' + $remainingCount more' : ''}',
                                  style: TextStyle(fontSize: 12, color: muted),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Text('${family.memberCount}/${family.maxCapacity}'),
                      ],
                    ),
                  );
                }),
                if (preview.unassignedStudents.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Unassigned students',
                    style: TextStyle(
                      color: AppTheme.pendingRose,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...preview.unassignedStudents.map(
                    (student) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        '• ${student.fullName} (${student.department})',
                        style: TextStyle(color: muted),
                      ),
                    ),
                  ),
                ],
                if (preview.warnings.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  ...preview.warnings.map(
                    (warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(
                        warning,
                        style: TextStyle(
                          color: AppTheme.pendingRose,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: preview.canApply && !_isApplyingDraft
                ? () async {
                    Navigator.of(dialogContext).pop();
                    setState(() => _isApplyingDraft = true);
                    try {
                      await widget.state.applySmartMatchingPreview(preview);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Draft saved. The roster remains unpublished until you publish it.',
                            ),
                          ),
                        );
                      }
                    } catch (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not save the matching draft: $error',
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isApplyingDraft = false);
                    }
                  }
                : null,
            icon: const Icon(Icons.save_outlined),
            label: const Text('Save unpublished draft'),
          ),
        ],
      ),
    );
  }

  void _showPublishConfirmation() {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
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
            Expanded(
              child: Text(
                'Publish Family Roster',
                style: TextStyle(
                  fontFamily: 'serif',
                  color: textCol,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: Text(
          'This publishes the validated family assignments and creates a regular Family Roster announcement in the same commit. Students can then view their roster. Continue?',
          style: TextStyle(color: textMuted, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            onPressed: _isPublishing || !widget.state.canPublishFamilyRoster
                ? null
                : () async {
                    Navigator.pop(ctx);
                    HapticFeedback.mediumImpact();
                    setState(() => _isPublishing = true);
                    try {
                      await widget.state.publishFamilyRoster();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Family roster and announcement published.',
                            ),
                          ),
                        );
                      }
                    } catch (error) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not publish the family roster: $error',
                            ),
                          ),
                        );
                      }
                    } finally {
                      if (mounted) setState(() => _isPublishing = false);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Publish roster',
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
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
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
        title: Text(
          'Spiritual Parent Matching',
          style: TextStyle(color: textCol),
        ),
        backgroundColor: cardBg,
        elevation: 0,
        leading: (Navigator.canPop(context) || widget.onBackPressed != null)
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
                onPressed: () {
                  if (widget.onBackPressed != null) {
                    widget.onBackPressed!();
                  } else if (Navigator.canPop(context)) {
                    Navigator.of(context).pop();
                  }
                },
              )
            : null,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Swap Banner when a student is selected
            if (_selectedStudentToSwap != null && selectedStudent != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.18),
                  border: Border(
                    bottom: BorderSide(color: primaryAccent.withOpacity(0.5)),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.swap_horiz,
                        color: primaryAccent,
                        size: 18,
                      ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
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
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
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
                              '${state.assignedFamilyStudentCount}/${state.eligibleFamilyStudents.length} Students Assigned',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
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
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Run Smart Matching Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                            state.isMatchingRunning ||
                                _isApplyingDraft ||
                                !state.canManageFamilyMatching
                            ? null
                            : () async {
                                HapticFeedback.selectionClick();
                                try {
                                  final preview = await state
                                      .previewSmartMatching();
                                  if (preview != null && context.mounted) {
                                    await _showMatchingPreview(preview);
                                  }
                                } catch (error) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not build a matching preview: $error',
                                        ),
                                      ),
                                    );
                                  }
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: state.isMatchingRunning
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Preparing matching preview...',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.black
                                          : Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                'Preview Smart Matching',
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
                      final members = state.eligibleFamilyStudents
                          .where((student) => family.memberIds.contains(student.id))
                          .toList();

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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.male,
                                                color: Color(0xFF38A3E5),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 3),
                                              Flexible(
                                                child: Text(
                                                  'Father: ${family.spiritualFather.fullName.split(' ').first}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textMuted,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.female,
                                                color: Color(0xFFE056FD),
                                                size: 14,
                                              ),
                                              const SizedBox(width: 3),
                                              Flexible(
                                                child: Text(
                                                  'Mother: ${family.spiritualMother.fullName.split(' ').first}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: textMuted,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: primaryAccent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: primaryAccent.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.people,
                                        size: 14,
                                        color: primaryAccent,
                                      ),
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

                            const SizedBox(height: 10),

                            // Telegram Group Invite Link Row
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: elevatedBg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: borderCol.withOpacity(0.6),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.send_rounded,
                                    color: Color(0xFF229ED9),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      family.telegramGroupUrl.isNotEmpty
                                          ? family.telegramGroupUrl
                                          : 'No Telegram link set',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color:
                                            family.telegramGroupUrl.isNotEmpty
                                            ? primaryAccent
                                            : textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: state.canManageFamilies
                                        ? () => _openEditTelegramDialog(
                                            context,
                                            state,
                                            family,
                                          )
                                        : null,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: primaryAccent.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.edit,
                                            size: 12,
                                            color: primaryAccent,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Edit Link',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: primaryAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 14),

                            // List of Students with Swap Trigger Buttons & Pulse Border
                            ...members.map((student) {
                              final isSelectedForSwap =
                                  _selectedStudentToSwap == student.id;

                              return AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  final pulseOpacity = isSelectedForSwap
                                      ? _pulseAnimation.value
                                      : 0.0;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: state.canManageFamilyMatching
                                            ? () => _handleStudentSwapTap(
                                                student.id,
                                                family.id,
                                              )
                                            : null,
                                        borderRadius: BorderRadius.circular(14),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 180,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 11,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelectedForSwap
                                                ? primaryAccent.withOpacity(0.2)
                                                : elevatedBg,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: isSelectedForSwap
                                                  ? primaryAccent.withOpacity(
                                                      0.4 +
                                                          (pulseOpacity * 0.6),
                                                    )
                                                  : borderCol,
                                              width: isSelectedForSwap
                                                  ? 2.0
                                                  : 1.0,
                                            ),
                                            boxShadow: isSelectedForSwap
                                                ? [
                                                    BoxShadow(
                                                      color: primaryAccent
                                                          .withOpacity(
                                                            0.3 * pulseOpacity,
                                                          ),
                                                      blurRadius:
                                                          10 * pulseOpacity,
                                                      spreadRadius: 1,
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      student.fullName,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                                padding: const EdgeInsets.all(
                                                  6,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: isSelectedForSwap
                                                      ? primaryAccent
                                                            .withOpacity(0.25)
                                                      : Colors.transparent,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.swap_horiz,
                                                  color: isSelectedForSwap
                                                      ? primaryAccent
                                                      : textMuted,
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
                          state.isFamilyPublished
                              ? 'Roster is Live'
                              : (state.canPublishFamilyRoster
                                    ? 'Draft is Ready'
                                    : 'Roster Needs Fixes'),
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: state.isFamilyPublished
                                ? AppTheme.emerald
                                : (state.canPublishFamilyRoster
                                      ? primaryAccent
                                      : AppTheme.pendingRose),
                          ),
                        ),
                        Text(
                          state.isFamilyPublished
                              ? 'All students can view their family'
                              : '${state.assignedFamilyStudentCount}/${state.eligibleFamilyStudents.length} students assigned',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed:
                        state.canManageFamilyMatching &&
                            state.canPublishFamilyRoster &&
                            !_isPublishing &&
                            !_isApplyingDraft
                        ? _showPublishConfirmation
                        : null,
                    icon: Icon(
                      Icons.send_rounded,
                      size: 16,
                      color: isDark ? Colors.black : Colors.white,
                    ),
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        state.isFamilyPublished
                            ? 'Re-announce'
                            : 'Publish roster',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.black : Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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

  void _openEditTelegramDialog(
    BuildContext context,
    FellowshipState state,
    FamilyModel family,
  ) {
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
        actionsOverflowButtonSpacing: 8,
        actionsOverflowDirection: VerticalDirection.down,
        actionsAlignment: MainAxisAlignment.end,
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set or update the Telegram group invite link for ${family.name}. Spiritual children will tap "Join Telegram Group" to enter your family chat.',
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        theme.textTheme.bodyMedium?.color ??
                        AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: linkController,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Telegram Invite Link',
                    hintText: 'https://t.me/+...',
                    prefixIcon: const Icon(
                      Icons.link,
                      color: Color(0xFF229ED9),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter a Telegram group link';
                    }
                    final uri = Uri.tryParse(val.trim());
                    if (uri == null ||
                        uri.scheme != 'https' ||
                        uri.host != 't.me') {
                      return 'Use a secure Telegram link starting with https://t.me/';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
            ),
          ),
          ElevatedButton(
            onPressed: state.canManageFamilies
                ? () async {
                    if (formKey.currentState?.validate() ?? false) {
                      final newLink = linkController.text.trim();
                      try {
                        await state.updateFamilyTelegramLink(
                          family.id,
                          newLink,
                        );
                        if (!ctx.mounted || !mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Updated Telegram link for ${family.name}',
                            ),
                            backgroundColor: const Color(0xFF229ED9),
                          ),
                        );
                      } catch (error) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Could not update the Telegram link: $error',
                              ),
                            ),
                          );
                        }
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save Link',
              style: TextStyle(
                color: theme.brightness == Brightness.dark
                    ? Colors.black
                    : Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
