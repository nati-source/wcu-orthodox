import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_fellowship_card.dart';

/// Dedicated & Specialized Hub for Volunteer Coordinators of the 10 EOTC Fellowship Departments.
///
/// Scoped Permissions:
/// - Volunteer Coordinators cannot assign roles.
/// - Volunteer Coordinators cannot accept/reject general student registrations into fellowship.
/// - Volunteer Coordinators cannot schedule priests/confessors.
/// - Emergency Student Aid review is strictly restricted to 'አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ' (deptMemberCare).
/// - Pilgrimage Trip Payment verification is strictly restricted to 'ባችና መርሐ ግብራት' (deptBatchPrograms).
/// - Each coordinator gets an interactive, customized department control room tailored to their ministry.
class CoordinatorHubScreen extends StatefulWidget {
  final FellowshipState state;

  const CoordinatorHubScreen({super.key, required this.state});

  @override
  State<CoordinatorHubScreen> createState() => _CoordinatorHubScreenState();
}

class _CoordinatorHubScreenState extends State<CoordinatorHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  ChoirWingType? _choirWingFilter; // For Music Department: Mezmur vs Fine Arts

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final coordProfile = state.currentUser.coordinatorProfile;
    final deptId = coordProfile?.departmentId ?? FellowshipDepartmentConstants.deptMemberCare;
    final isAudit = coordProfile?.isReadOnlyAudit == true;

    final deptAmharic = FellowshipDepartmentConstants.getNameAmharic(deptId);
    final deptEn = FellowshipDepartmentConstants.getNameEn(deptId);

    final apps = state.getApplicationsForDepartment(deptId);
    final pendingApps = apps.where((a) => a.status == ApplicationStatus.pending).toList();
    final members = state.getMembersForDepartment(deptId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Coordinator Hub • ማስተባበሪያ',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '$deptAmharic ($deptEn)',
              style: TextStyle(
                fontSize: 11,
                color: primaryAccent,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Quick Department Switcher for Demo / Simulation
          PopupMenuButton<String>(
            tooltip: 'Switch Active Department',
            icon: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryAccent.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hub_outlined, size: 14, color: primaryAccent),
                  const SizedBox(width: 4),
                  Text('Switch Dept', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent)),
                  Icon(Icons.arrow_drop_down, size: 14, color: primaryAccent),
                ],
              ),
            ),
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (newDeptId) {
              HapticFeedback.mediumImpact();
              state.switchCoordinatorDepartment(newDeptId);
            },
            itemBuilder: (ctx) {
              return FellowshipDepartmentConstants.allDepartmentIds.map((id) {
                final isCurrent = id == deptId;
                final isAud = id == FellowshipDepartmentConstants.deptAudit;
                return PopupMenuItem<String>(
                  value: id,
                  child: Row(
                    children: [
                      Icon(
                        isAud ? Icons.fact_check_outlined : Icons.account_tree_outlined,
                        size: 16,
                        color: isCurrent ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${FellowshipDepartmentConstants.getNameAmharic(id)} ${isAud ? "(Audit)" : ""}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            color: isCurrent ? primaryAccent : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryAccent,
          labelColor: primaryAccent,
          unselectedLabelColor: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Department Tasks (${_getDeptSpecificBadgeCount(state, deptId)})'),
            Tab(text: 'Applications (${pendingApps.length})'),
            Tab(text: 'Volunteers Roster (${members.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Department-Specialized Interactive Workflows
          _buildDepartmentSpecializedView(context, state, deptId, isAudit),

          // Tab 2: Scoped Volunteer Applications for THIS Department
          _buildDepartmentApplicationsTab(context, state, deptId, pendingApps, isAudit),

          // Tab 3: Active Volunteers Roster
          _buildDepartmentRosterTab(context, state, deptId, members, isAudit),
        ],
      ),
    );
  }

  int _getDeptSpecificBadgeCount(FellowshipState state, String deptId) {
    if (deptId == FellowshipDepartmentConstants.deptMemberCare) {
      return state.emergencyAidRequests.where((r) => r.status == EmergencyAidStatus.underReview).length;
    } else if (deptId == FellowshipDepartmentConstants.deptBatchPrograms) {
      return state.allTripRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.pendingVerification).length;
    }
    return state.getApplicationsForDepartment(deptId).length;
  }

  // ============================================================================
  // TAB 1: DEPARTMENT SPECIALIZED INTERACTIVE WORKFLOWS
  // ============================================================================
  Widget _buildDepartmentSpecializedView(BuildContext context, FellowshipState state, String deptId, bool isAudit) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Department Identity Card
        _buildDepartmentBannerCard(context, state, deptId, isAudit),
        const SizedBox(height: 16),

        // 2. Department Quick Metrics Matrix
        _buildDepartmentKpis(context, state, deptId),
        const SizedBox(height: 20),

        // 3. Department Specific Dedicated Interactive Modules
        if (deptId == FellowshipDepartmentConstants.deptMemberCare)
          _buildMemberCareModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptChoirArts)
          _buildChoirAndArtsModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptBatchPrograms)
          _buildBatchProgramsModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptEducation)
          _buildEducationModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptDevelopment)
          _buildDevelopmentModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptFinanceProperty)
          _buildFinancePropertyModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptCharity)
          _buildCharityModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptSpecialNeeds)
          _buildSpecialNeedsModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptPlanning)
          _buildPlanningModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptAudit)
          _buildAuditModule(context, state)
        else
          _buildGenericDepartmentModule(context, state, deptId),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDepartmentBannerCard(BuildContext context, FellowshipState state, String deptId, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final deptAmharic = FellowshipDepartmentConstants.getNameAmharic(deptId);
    final deptEn = FellowshipDepartmentConstants.getNameEn(deptId);

    return InteractiveFellowshipCard(
      padding: const EdgeInsets.all(18),
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderColor: isAudit ? const Color(0xFFF5A65E).withOpacity(0.5) : primaryAccent.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isAudit ? const Color(0xFFF5A65E) : primaryAccent).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isAudit ? Icons.fact_check_outlined : Icons.shield_outlined,
                  color: isAudit ? const Color(0xFFF5A65E) : primaryAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deptAmharic,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deptEn,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  isAudit ? Icons.lock_outline : Icons.verified_user_outlined,
                  size: 14,
                  color: isAudit ? const Color(0xFFF5A65E) : AppTheme.emerald,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isAudit
                        ? 'Inspection Role: Read-only observation & audit logs across all units.'
                        : 'Coordinator Scope: Delegated department management & volunteer review.',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentKpis(BuildContext context, FellowshipState state, String deptId) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final apps = state.getApplicationsForDepartment(deptId);
    final pendingCount = apps.where((a) => a.status == ApplicationStatus.pending).length;
    final memberCount = state.getMembersForDepartment(deptId).length;

    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            context,
            title: 'Active Servants',
            value: '$memberCount',
            icon: Icons.groups_outlined,
            color: primaryAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            context,
            title: 'Pending Applicants',
            value: '$pendingCount',
            icon: Icons.assignment_ind_outlined,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            context,
            title: 'Duty Shifts',
            value: 'Active',
            icon: Icons.calendar_today_outlined,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 2: አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ (MEMBER CARE & COUNSELING)
  // --------------------------------------------------------------------------
  Widget _buildMemberCareModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final aidRequests = state.emergencyAidRequests;
    final pendingAid = aidRequests.where((r) => r.status == EmergencyAidStatus.underReview).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'የተማሪዎች አስቸኳይ ድጋፍና ምክክር (EMERGENCY AID REVIEW)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${pendingAid.length} Pending Review', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (pendingAid.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All member emergency aid and welfare applications are processed.',
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          ...pendingAid.map((req) {
            return InteractiveFellowshipCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: const Color(0xFFEF4444).withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        req.studentName,
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${req.amountRequested.toStringAsFixed(0)} ETB',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'B.N. ${req.studentBaptismalName} • Year ${req.academicYear} • Phone: ${req.studentPhone}',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Category: ${req.category.displayName}',
                    style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    req.description,
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, fontStyle: FontStyle.italic),
                  ),
                  if (!isAudit) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            state.verifyEmergencyAid(req.id, EmergencyAidStatus.declined, adminNote: 'Declined by Member Care Coordinator');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Emergency aid request for ${req.studentName} marked as declined.')),
                            );
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.crimson),
                          child: const Text('Decline', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            state.verifyEmergencyAid(req.id, EmergencyAidStatus.approved, adminNote: 'Approved by Member Care Coordinator');
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Emergency aid for ${req.studentName} approved for disbursement.')),
                            );
                          },
                          icon: const Icon(Icons.check, size: 14, color: Colors.white),
                          label: const Text('Approve & Disburse', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),

        const SizedBox(height: 16),

        // Capacity & Spiritual Welfare Tracker
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Welfare & Counseling Follow-up',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Monitor freshman adaptation, coordinate prayer families, and support students needing psychological or spiritual counseling.',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.3),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildActionChip(context, Icons.psychology_outlined, 'Counseling Cases'),
                  _buildActionChip(context, Icons.favorite_outline, 'Freshman Visits'),
                  _buildActionChip(context, Icons.event_available_outlined, 'Capacity Workshops'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 3: መዝሙርና ስነ ጥበባት (MUSIC, HYMNOGRAPHY & SACRED ARTS)
  // --------------------------------------------------------------------------
  Widget _buildChoirAndArtsModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'የዝማሬና ስነ-ጥበባት አስተዳደር (CHOIR & SACRED ARTS CONTROL)',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
        ),
        const SizedBox(height: 10),

        // Dual Wing Filter Selector
        Row(
          children: [
            Expanded(
              child: ChoiceChip(
                label: const Text('All Wings (ሁለቱም)'),
                selected: _choirWingFilter == null,
                onSelected: (val) => setState(() => _choirWingFilter = null),
                selectedColor: primaryAccent.withOpacity(0.2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('St. Yared Mezmur'),
                selected: _choirWingFilter == ChoirWingType.mezmur,
                onSelected: (val) => setState(() => _choirWingFilter = ChoirWingType.mezmur),
                selectedColor: primaryAccent.withOpacity(0.2),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ChoiceChip(
                label: const Text('Fine Arts & Drama'),
                selected: _choirWingFilter == ChoirWingType.fineArts,
                onSelected: (val) => setState(() => _choirWingFilter = ChoirWingType.fineArts),
                selectedColor: primaryAccent.withOpacity(0.2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Practice & Liturgy Rehearsal Schedule Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Weekly Liturgy Rehearsal Schedule', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  Icon(Icons.music_note, color: primaryAccent, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              _buildScheduleRow(context, 'Friday 11:30 LT', 'Saint Yared Digua & Mahlet Practice (Ge\'ez)'),
              const SizedBox(height: 6),
              _buildScheduleRow(context, 'Saturday 10:00 LT', 'Sunday Liturgy Choir Hymns & Drum (Kebero) Roster'),
              const SizedBox(height: 6),
              _buildScheduleRow(context, 'Sunday 2:00 LT', 'Sunday School Drama & Orthodox Poetry Rehearsal'),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 6: ባችና መርሐ ግብራት (BATCH & PROGRAMS COORDINATION)
  // --------------------------------------------------------------------------
  Widget _buildBatchProgramsModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final pendingTrips = state.allTripRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.pendingVerification).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'የመንፈሳዊ ጉዞ ክፍያ ማረጋገጫ (PILGRIMAGE PAYMENT VERIFIER)',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('${pendingTrips.length} Pending Payments', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (pendingTrips.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All pilgrimage trip payments & boarding tickets are verified.',
                    style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                  ),
                ),
              ],
            ),
          )
        else
          ...pendingTrips.map((reg) {
            return InteractiveFellowshipCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: primaryAccent.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(reg.studentName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(reg.paymentMethod.displayName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Trip: ${reg.tripTitle} • Fare: ${reg.feeAmount.toStringAsFixed(0)} ETB', style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600)),
                  Text('Transaction Ref: ${reg.transactionReference}', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                  if (!isAudit) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            state.verifyTripPayment(reg.id, false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Payment for ${reg.studentName} marked as invalid.')),
                            );
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.crimson),
                          child: const Text('Reject Ref', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            state.verifyTripPayment(reg.id, true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Payment verified & Boarding pass issued to ${reg.studentName}')),
                            );
                          },
                          icon: const Icon(Icons.check, size: 14, color: Colors.white),
                          label: const Text('Verify & Issue Ticket', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 1: ትምህርትና ሐዋርያዊ አገልግሎት (EDUCATION & APOSTOLIC MINISTRY)
  // --------------------------------------------------------------------------
  Widget _buildEducationModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Apostolic Curriculum & Guest Teachers', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.school, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Schedule Sunday catechism topics, dispatch special guest clergy lecture broadcasts, and coordinate study circles.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(context, Icons.campaign_outlined, 'Dispatch Guest Teacher Notice'),
              _buildActionChip(context, Icons.book_outlined, 'Review Syllabus Modules'),
              _buildActionChip(context, Icons.groups_outlined, 'Study Circle Rosters'),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 4: ልማትና ገቢ አሰባሰብ (DEVELOPMENT & FUNDRAISING)
  // --------------------------------------------------------------------------
  Widget _buildDevelopmentModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Fundraising & Development Proposals', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.savings_outlined, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Submit capital project budgets, track annual fellowship dues campaigns, and manage donor pledge registries.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildActionChip(context, Icons.post_add, 'Draft Project Proposal'),
              _buildActionChip(context, Icons.volunteer_activism, 'Dues Campaign Tracker'),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 5: ሒሳብና ንብረት (ACCOUNTING & PROPERTY)
  // --------------------------------------------------------------------------
  Widget _buildFinancePropertyModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Church Property & Assets Registry', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.account_balance_outlined, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Track sacred vestments, sound system equipment, and liturgical books inventory.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 7: ሙያና በጎ አድራጎት (CHARITY & VOCATIONAL)
  // --------------------------------------------------------------------------
  Widget _buildCharityModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Community Charity & Vocational Works', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.handshake_outlined, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Coordinate community food aid drives, hospital visits, and skill-training tutorials for fellows.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 8: ቋንቋና ልዩ ልዩ ፍላጎት (LANGUAGE & SPECIAL NEEDS)
  // --------------------------------------------------------------------------
  Widget _buildSpecialNeedsModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Multilingual & Sign-Language Services', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.translate_outlined, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Translation rosters for Afaan Oromoo, Tigrinya, English, and Geez liturgical texts, plus sign-language interpreter duty shifts.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 9: እቅድና ክትትል (PLANNING & MONITORING)
  // --------------------------------------------------------------------------
  Widget _buildPlanningModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Semester Strategy & Ministry OKRs', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Icon(Icons.pie_chart_outline, color: primaryAccent, size: 20),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Quarterly milestone progress tracking, committee performance benchmarks, and end-of-term evaluations.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 10: ኦዲትና ኢንስፔክሽን (AUDIT & INSPECTION)
  // --------------------------------------------------------------------------
  Widget _buildAuditModule(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5A65E).withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF5A65E).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.fact_check_outlined, color: Color(0xFFF5A65E), size: 22),
              SizedBox(width: 10),
              Text('Audit & Inspection Access Log', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E))),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You have read-only inspection access across all 10 fellowship sub-committees to verify transparency, constitution compliance, and asset management.',
            style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericDepartmentModule(BuildContext context, FellowshipState state, String deptId) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Text(
        'Department active and operational.',
        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
      ),
    );
  }

  // ============================================================================
  // TAB 2: SCOPED VOLUNTEER APPLICATIONS (THIS DEPT ONLY)
  // ============================================================================
  Widget _buildDepartmentApplicationsTab(
    BuildContext context,
    FellowshipState state,
    String deptId,
    List<VolunteerApplicationModel> pendingApps,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    if (pendingApps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 48),
            const SizedBox(height: 12),
            Text(
              'No pending volunteer applications for ${FellowshipDepartmentConstants.getNameAmharic(deptId)}.',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pendingApps.length,
      itemBuilder: (ctx, index) {
        final app = pendingApps[index];
        return InteractiveFellowshipCard(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderColor: theme.dividerColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: primaryAccent.withOpacity(0.12),
                    child: Text(
                      app.studentName.isNotEmpty ? app.studentName[0] : 'V',
                      style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(app.studentName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        Text('B.N. ${app.studentBaptismalName} • Year ${app.studentYear} • ${app.studentDept}', style: TextStyle(fontSize: 11, color: primaryAccent)),
                      ],
                    ),
                  ),
                  if (app.choirWing != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: primaryAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        app.choirWing == ChoirWingType.mezmur ? 'Mezmur' : 'Fine Arts',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Motivation / Ministry Reason:',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
              const SizedBox(height: 2),
              Text(
                app.reason,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, fontStyle: FontStyle.italic),
              ),
              if (!isAudit) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        state.rejectVolunteerApplication(app.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Application from ${app.studentName} rejected.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(foregroundColor: AppTheme.crimson),
                      child: const Text('Reject', style: TextStyle(fontSize: 11)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        state.approveVolunteerApplication(app.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${app.studentName} accepted into ${FellowshipDepartmentConstants.getNameAmharic(deptId)}!')),
                        );
                      },
                      icon: const Icon(Icons.check, size: 14, color: Colors.white),
                      label: const Text('Accept Volunteer', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  // ============================================================================
  // TAB 3: ACTIVE VOLUNTEERS ROSTER
  // ============================================================================
  Widget _buildDepartmentRosterTab(
    BuildContext context,
    FellowshipState state,
    String deptId,
    List<DepartmentMemberModel> members,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    if (members.isEmpty) {
      return Center(
        child: Text(
          'No active volunteers in this department roster.',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 13),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (ctx, index) {
        final member = members[index];
        return InteractiveFellowshipCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          color: theme.cardTheme.color ?? theme.colorScheme.surface,
          borderColor: theme.dividerColor,
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Text(
                  member.studentName.isNotEmpty ? member.studentName[0] : 'S',
                  style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(member.studentName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    Text('B.N. ${member.studentBaptismalName} • Year ${member.studentYear}', style: TextStyle(fontSize: 11, color: primaryAccent)),
                    Text('${member.studentDept} • Role: ${member.roleInDepartment}', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone_outlined, size: 18),
                color: primaryAccent,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  state.launchCall(member.phoneNumber);
                },
              ),
              IconButton(
                icon: const Icon(Icons.telegram, size: 20),
                color: const Color(0xFF38A3E5),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  state.launchTelegram(member.phoneNumber);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // HELPER WIDGETS
  // --------------------------------------------------------------------------
  Widget _buildActionChip(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: primaryAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: primaryAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: primaryAccent),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
        ],
      ),
    );
  }

  Widget _buildScheduleRow(BuildContext context, String time, String desc) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: primaryAccent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(time, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(desc, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface)),
        ),
      ],
    );
  }
}
