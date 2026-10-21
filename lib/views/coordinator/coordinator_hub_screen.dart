import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/interactive_fellowship_card.dart';
import '../student/student_qr_scanner_screen.dart';

part 'departments/dept_member_care_module.dart';
part 'departments/dept_choir_arts_module.dart';
part 'departments/dept_choir_module.dart';
part 'departments/dept_sacred_arts_module.dart';
part 'departments/dept_batch_programs_module.dart';
part 'departments/dept_charity_module.dart';
part 'departments/dept_education_module.dart';
part 'departments/dept_development_module.dart';
part 'departments/dept_accounting_module.dart';
part 'departments/dept_language_module.dart';
part 'departments/dept_planning_module.dart';
part 'departments/dept_audit_module.dart';

/// Dedicated & Specialized Hub for Volunteer Coordinators of the 10 EOTC Fellowship Departments.
///
/// Scoped Permissions:
/// - Volunteer Coordinators cannot assign roles.
/// - Volunteer Coordinators cannot accept/reject general student registrations into fellowship.
/// - Volunteer Coordinators cannot schedule priests/confessors.
/// - Emergency Student Aid review is strictly restricted to 'አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ' (deptMemberCare).
/// - Pilgrimage Trip Payment verification & trip management is strictly restricted to 'ባችና መርሐ ግብራት' (deptBatchPrograms).
/// - Charity & Vocational management & treasury is strictly restricted to 'ሙያና በጎ አድራጎት' (deptCharity).
/// - Regular coordinators open directly into their assigned department scope without department-switch controls.
/// - Department preview/switching is strictly reserved for Admins.
class CoordinatorHubScreen extends StatefulWidget {
  final FellowshipState state;

  const CoordinatorHubScreen({super.key, required this.state});

  @override
  State<CoordinatorHubScreen> createState() => _CoordinatorHubScreenState();
}

class _CoordinatorHubScreenState extends State<CoordinatorHubScreen>
    with SingleTickerProviderStateMixin {
  void _updateUi(VoidCallback fn) => setState(fn);
  late TabController _tabController;
  ChoirWingType? _choirWingFilter; // For Music Department: Mezmur vs Fine Arts

  // Search & Filter state across tabs
  String _teamSearch = '';
  String _tasksSearch = '';

  // Interactive Pilgrimage Controls (ባችና መርሐ ግብራት)
  String _pilgrimFilter =
      'All'; // 'All', 'Pending Approval', 'Verified', 'Declined'
  String _pilgrimSearch = '';
  String? _selectedTripFilter; // null = all trips

  // Interactive Charity Controls (ሙያና በጎ አድራጎት)
  int _charityLedgerTab =
      0; // 0: Campaigns, 1: Donations/Dues Inflow, 2: Aid Disbursements Outflow

  // Interactive Education Controls (ትምህርትና ሐዋርያዊ አገልግሎት)
  String _educationCategoryFilter =
      'All'; // 'All', 'Course Info', 'Special Program', 'Urgent Alert'
  String _educationBatchFilter = 'All'; // 'All', '1', '2', '3', '4', '5'

  // Interactive Development & Fundraising Controls (ልማትና ገቢ አሰባሰብ)
  String _developmentProposalStatusFilter =
      'All'; // 'All', 'Pending', 'Approved', 'Rejected'
  String _developmentSearch = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final state = widget.state;
        final theme = AppTheme.getTheme(state.currentThemePalette);
        final primaryAccent = theme.colorScheme.primary;
        final coordProfile = state.currentUser.coordinatorProfile;

        // Admin can switch preview departments; regular coordinator opens directly into assigned scope
        final deptId = state.isAdmin
            ? (state.selectedCoordinatorDepartmentId ??
                  coordProfile?.departmentId ??
                  FellowshipDepartmentConstants.deptEducation)
            : (coordProfile?.departmentId ??
                  FellowshipDepartmentConstants.deptEducation);
        final isAudit =
            FellowshipDepartmentConstants.isAuditScope(deptId) ||
            coordProfile?.isReadOnlyAudit == true;

        final deptAmharic = FellowshipDepartmentConstants.getNameAmharic(
          deptId,
        );
        final deptEn = FellowshipDepartmentConstants.getNameEn(deptId);

        final apps = state.getApplicationsForDepartment(deptId);
        final pendingApps = apps
            .where((a) => a.status == ApplicationStatus.pending)
            .toList();
        final members = state.getMembersForDepartment(deptId);
        final totalTasks = _getTotalTasksBadgeCount(
          state,
          deptId,
          pendingApps.length,
        );

        return Theme(
          data: theme,
          child: Scaffold(
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
                // Dedicated Sacred Theme Switcher
                IconButton(
                  tooltip:
                      'Theme: ${state.currentThemePalette.displayName} — Tap to switch',
                  icon: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: primaryAccent.withOpacity(0.35),
                      ),
                    ),
                    child: Icon(
                      state.currentThemePalette.isDark
                          ? Icons.wb_sunny_rounded
                          : Icons.nightlight_round,
                      size: 16,
                      color: primaryAccent,
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    final nextIndex =
                        (state.currentThemePalette.index + 1) %
                        AppThemePalette.values.length;
                    final nextPal = AppThemePalette.values[nextIndex];
                    state.setThemePalette(nextPal);
                    ScaffoldMessenger.of(context).removeCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Theme: ${nextPal.displayName} (${nextPal.amharicName})',
                        ),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),

                // Department Scope Control:
                // Admin sees interactive preview switcher; regular coordinator sees fixed scope lock badge
                if (state.isAdmin) ...[
                  PopupMenuButton<String>(
                    tooltip: 'Admin Department Preview',
                    icon: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryAccent.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.admin_panel_settings_outlined,
                            size: 14,
                            color: primaryAccent,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Admin Switch',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryAccent,
                            ),
                          ),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 14,
                            color: primaryAccent,
                          ),
                        ],
                      ),
                    ),
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (newDeptId) {
                      HapticFeedback.mediumImpact();
                      state.switchCoordinatorDepartment(newDeptId);
                    },
                    itemBuilder: (ctx) {
                      return FellowshipDepartmentConstants.coordinatorScopeIds.map((
                        id,
                      ) {
                        final isCurrent = id == deptId;
                        final isAud =
                            FellowshipDepartmentConstants.isAuditScope(id);
                        return PopupMenuItem<String>(
                          value: id,
                          child: Row(
                            children: [
                              Icon(
                                isAud
                                    ? Icons.fact_check_outlined
                                    : Icons.account_tree_outlined,
                                size: 16,
                                color: isCurrent
                                    ? primaryAccent
                                    : (theme.textTheme.bodyMedium?.color ??
                                          AppTheme.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${FellowshipDepartmentConstants.getNameAmharic(id)} ${isAud ? "(Audit)" : ""}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isCurrent
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isCurrent
                                        ? primaryAccent
                                        : theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    },
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (isAudit ? const Color(0xFFF5A65E) : primaryAccent)
                          .withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            (isAudit ? const Color(0xFFF5A65E) : primaryAccent)
                                .withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isAudit
                              ? Icons.lock_outline
                              : Icons.verified_user_outlined,
                          size: 12,
                          color: isAudit
                              ? const Color(0xFFF5A65E)
                              : primaryAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAudit ? 'Audit Scope' : 'Assigned Scope',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isAudit
                                ? const Color(0xFFF5A65E)
                                : primaryAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 8),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: primaryAccent,
                labelColor: primaryAccent,
                unselectedLabelColor:
                    theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
                tabs: [
                  const Tab(
                    icon: Icon(Icons.dashboard_outlined, size: 15),
                    text: 'Overview',
                  ),
                  Tab(
                    icon: const Icon(Icons.task_alt_outlined, size: 15),
                    text: totalTasks > 0 ? 'Tasks ($totalTasks)' : 'Tasks',
                  ),
                  Tab(
                    icon: const Icon(Icons.groups_outlined, size: 15),
                    text: members.isNotEmpty
                        ? 'Team (${members.length})'
                        : 'Team',
                  ),
                  const Tab(
                    icon: Icon(Icons.construction_outlined, size: 15),
                    text: 'Tools',
                  ),
                ],
              ),
            ),
            body: TabBarView(
              controller: _tabController,
              children: [
                // Tab 1: Overview & Relevant Next Actions
                _buildDepartmentOverviewTab(
                  context,
                  state,
                  deptId,
                  isAudit,
                  pendingApps,
                  members,
                ),

                // Tab 2: Pending Applications & Action Tasks
                _buildDepartmentTasksTab(
                  context,
                  state,
                  deptId,
                  pendingApps,
                  isAudit,
                ),

                // Tab 3: Active Volunteers Roster & Team Directory
                _buildDepartmentRosterTab(
                  context,
                  state,
                  deptId,
                  members,
                  isAudit,
                ),

                // Tab 4: Specialized Interactive Tools & Workflows
                _buildDepartmentToolsTab(context, state, deptId, isAudit),
              ],
            ),
          ),
        );
      },
    );
  }

  int _getTotalTasksBadgeCount(
    FellowshipState state,
    String deptId,
    int pendingAppsCount,
  ) {
    return pendingAppsCount + _getDeptSpecificBadgeCount(state, deptId);
  }

  int _getDeptSpecificBadgeCount(FellowshipState state, String deptId) {
    if (deptId == FellowshipDepartmentConstants.deptMemberCare) {
      return state.emergencyAidRequests
          .where((r) => r.status == EmergencyAidStatus.underReview)
          .length;
    } else if (deptId == FellowshipDepartmentConstants.deptBatchPrograms) {
      return state.allTripRegistrations
          .where(
            (r) => r.paymentStatus == TripPaymentStatus.pendingVerification,
          )
          .length;
    } else if (deptId == FellowshipDepartmentConstants.deptCharity) {
      return state.duesPayments
          .where(
            (d) =>
                d.status == 'Pending Verification' ||
                d.status == 'pendingVerification',
          )
          .length;
    } else if (deptId == FellowshipDepartmentConstants.deptDevelopment) {
      return state.fundraisingProposals.where((p) => p.isPending).length;
    }
    return 0;
  }

  // ============================================================================
  // TAB 1: DEPARTMENT OVERVIEW & RELEVANT WORK NEXT ACTIONS
  // ============================================================================
  Widget _buildDepartmentOverviewTab(
    BuildContext context,
    FellowshipState state,
    String deptId,
    bool isAudit,
    List<VolunteerApplicationModel> pendingApps,
    List<DepartmentMemberModel> members,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final isLegacy = FellowshipDepartmentConstants.isLegacyCombinedMusicScope(
      deptId,
    );
    final broadcasts = state.getBroadcastsForDepartment(deptId);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Department Identity Header Card
        _buildDepartmentBannerCard(context, state, deptId, isAudit),
        const SizedBox(height: 14),

        // 2. Ambiguous Legacy Scope Warning Banner
        if (isLegacy) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFF59E0B).withOpacity(0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ambiguous Legacy Scope (Music & Sacred Arts Combined)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'You are currently assigned under the legacy combined scope. Mezmur/Choir and Sacred Arts are now distinct departments with separate tools and authorization. Please contact an Administrator to review and migrate your scope.',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 3. Department KPIs / Metrics Row
        _buildDepartmentKpis(context, state, deptId),
        const SizedBox(height: 16),

        // 4. Relevant Work & Next Actions Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.bolt, color: primaryAccent, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Next Actions & Department Priorities',
                            style: TextStyle(
                              fontSize: 13,
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
                  if (!isAudit) ...[
                    const SizedBox(width: 4),
                    TextButton.icon(
                      onPressed: () =>
                          _showBroadcastComposer(context, state, deptId),
                      icon: const Icon(Icons.campaign_outlined, size: 14),
                      label: const Text(
                        'Post Notice',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Pending Applications Action
              if (pendingApps.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withOpacity(0.25),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.assignment_ind_outlined,
                          size: 16,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${pendingApps.length} Pending Volunteer Applications',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Applicants waiting for review and team placement.',
                              style: TextStyle(fontSize: 10, color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _tabController.animateTo(1);
                        },
                        child: const Text(
                          'Review ->',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Department Specific Workflows Next Action
              _buildDeptNextActionTile(context, state, deptId, isAudit),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 5. Recent Department Announcements & Broadcasts
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
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
                      'Department Broadcasts & Notices (${broadcasts.length})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.notifications_none,
                    size: 18,
                    color: primaryAccent,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (broadcasts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'No broadcasts posted yet for ${FellowshipDepartmentConstants.getNameEn(deptId)}.',
                    style: TextStyle(
                      fontSize: 11,
                      color: textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else
                ...broadcasts
                    .take(3)
                    .map((b) => _buildBroadcastSummaryCard(context, state, b)),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDeptNextActionTile(
    BuildContext context,
    FellowshipState state,
    String deptId,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;

    String actionTitle = 'Department Interactive Tools';
    String actionDesc = 'Access specialized tools and workflows.';
    String buttonText = 'Tools ->';
    VoidCallback onAction = () {
      HapticFeedback.selectionClick();
      _tabController.animateTo(3);
    };

    if (deptId == FellowshipDepartmentConstants.deptMemberCare) {
      final pendingAid = state.emergencyAidRequests
          .where((r) => r.status == EmergencyAidStatus.underReview)
          .length;
      actionTitle = 'Student Aid & Counseling Review';
      actionDesc = '$pendingAid confidential emergency aid cases under review.';
      buttonText = 'Aid ->';
    } else if (deptId == FellowshipDepartmentConstants.deptBatchPrograms) {
      final pendingPilgrims = state.allTripRegistrations
          .where(
            (r) => r.paymentStatus == TripPaymentStatus.pendingVerification,
          )
          .length;
      actionTitle = 'Pilgrimage Trip & Transport Rosters';
      actionDesc = '$pendingPilgrims pilgrim payments pending verification.';
      buttonText = 'Trips ->';
    } else if (deptId == FellowshipDepartmentConstants.deptCharity) {
      final pendingDues = state.duesPayments
          .where(
            (d) =>
                d.status == 'Pending Verification' ||
                d.status == 'pendingVerification',
          )
          .length;
      actionTitle = 'Mutual Aid & Charity Treasury';
      actionDesc = '$pendingDues dues contributions awaiting verification.';
      buttonText = 'Ledger ->';
    } else if (deptId == FellowshipDepartmentConstants.deptChoir) {
      actionTitle = 'Liturgy Hymns & Digua Practice';
      actionDesc = 'Friday 11:30 LT Digua Practice & Saturday Kebero Rosters.';
      buttonText = 'Choir ->';
    } else if (deptId == FellowshipDepartmentConstants.deptSacredArts) {
      actionTitle = 'Iconography & Christian Drama';
      actionDesc = 'Orthodox drama rehearsal, script reading & icon catalog.';
      buttonText = 'Arts ->';
    } else if (deptId == FellowshipDepartmentConstants.deptEducation) {
      actionTitle = 'Apostolic Curriculum & Preaching';
      actionDesc = 'Manage course materials and faith defense study circles.';
      buttonText = 'Courses ->';
    } else if (deptId == FellowshipDepartmentConstants.deptDevelopment) {
      final pendingProps = state.fundraisingProposals
          .where((p) => p.isPending)
          .length;
      actionTitle = 'Fundraising Proposals & Projects';
      actionDesc = '$pendingProps donor campaign proposals pending approval.';
      buttonText = 'Proposals ->';
    } else if (deptId == FellowshipDepartmentConstants.deptFinanceProperty) {
      actionTitle = 'Property & Asset Inventory';
      actionDesc =
          'Liturgical vestments, vessels and sound equipment registry.';
      buttonText = 'Assets ->';
    } else if (deptId == FellowshipDepartmentConstants.deptAudit) {
      actionTitle = 'Compliance & Oversight Inspection';
      actionDesc =
          'Read-only audit checklists across all fellowship operations.';
      buttonText = 'Inspect ->';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: primaryAccent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: primaryAccent.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: primaryAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.handyman_outlined,
              size: 16,
              color: primaryAccent,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  actionTitle,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  actionDesc,
                  style: TextStyle(fontSize: 10, color: textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBroadcastSummaryCard(
    BuildContext context,
    FellowshipState state,
    DepartmentBroadcastMessageModel b,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: elevatedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.campaign, size: 16, color: primaryAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  b.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  b.body,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${b.senderName} • ${b.targetAudienceLabel}',
                  style: TextStyle(
                    fontSize: 9,
                    color:
                        theme.textTheme.bodyMedium?.color ??
                        AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showBroadcastComposer(
    BuildContext context,
    FellowshipState state,
    String deptId,
  ) {
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    String urgency = 'normal';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final primaryAccent = theme.colorScheme.primary;

          return AlertDialog(
            backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                Icon(Icons.campaign_outlined, color: primaryAccent, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Post Department Announcement',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To: ${FellowshipDepartmentConstants.getNameAmharic(deptId)} Members',
                    style: TextStyle(
                      fontSize: 11,
                      color: primaryAccent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      labelText: 'Announcement Title / አርእስት',
                      labelStyle: const TextStyle(fontSize: 12),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: bodyController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Message Body / መልእክት',
                      labelStyle: const TextStyle(fontSize: 12),
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Urgency:', style: TextStyle(fontSize: 11)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: urgency,
                        isDense: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'normal',
                            child: Text(
                              'Normal Notice',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'urgent',
                            child: Text(
                              'Urgent Alert',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                          DropdownMenuItem(
                            value: 'meeting',
                            child: Text(
                              'Meeting Call',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => urgency = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final title = titleController.text.trim();
                  final body = bodyController.text.trim();
                  if (title.isEmpty || body.isEmpty) return;
                  Navigator.pop(ctx);
                  HapticFeedback.mediumImpact();
                  state.sendDepartmentBroadcast(
                    departmentId: deptId,
                    title: title,
                    body: body,
                    urgency: urgency,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Department broadcast published successfully!',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.send, size: 14, color: Colors.white),
                label: const Text(
                  'Send Broadcast',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============================================================================
  // TAB 4: DEPARTMENT-SPECIFIC TOOLS & INTERACTIVE WORKFLOWS
  // ============================================================================
  Widget _buildDepartmentToolsTab(
    BuildContext context,
    FellowshipState state,
    String deptId,
    bool isAudit,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (deptId == FellowshipDepartmentConstants.deptChoir)
          _buildChoirModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptSacredArts)
          _buildSacredArtsModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptChoirArts)
          _buildChoirAndArtsModule(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptMemberCare)
          _buildMemberCareModule(context, state, isAudit)
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

  Widget _buildDepartmentBannerCard(
    BuildContext context,
    FellowshipState state,
    String deptId,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final deptAmharic = FellowshipDepartmentConstants.getNameAmharic(deptId);
    final deptEn = FellowshipDepartmentConstants.getNameEn(deptId);

    return InteractiveFellowshipCard(
      padding: const EdgeInsets.all(18),
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderColor: isAudit
          ? const Color(0xFFF5A65E).withOpacity(0.5)
          : primaryAccent.withOpacity(0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isAudit ? const Color(0xFFF5A65E) : primaryAccent)
                      .withOpacity(0.12),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deptEn,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            theme.textTheme.bodyMedium?.color ??
                            AppTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                      color:
                          theme.textTheme.bodyMedium?.color ??
                          AppTheme.textSecondary,
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

  Widget _buildDepartmentKpis(
    BuildContext context,
    FellowshipState state,
    String deptId,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final apps = state.getApplicationsForDepartment(deptId);
    final pendingCount = apps
        .where((a) => a.status == ApplicationStatus.pending)
        .length;
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
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricTile(
            context,
            title: 'Pending Apps',
            value: '$pendingCount',
            icon: Icons.assignment_ind_outlined,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 8),
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color:
                  theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 2: አባላት እንክብካቤ፤ ምክክርና አቅም ማጎልበቻ (MEMBER CARE & COUNSELING)
  // --------------------------------------------------------------------------

  // ============================================================================
  // TAB 2: DEPARTMENT ACTION TASKS & PENDING VOLUNTEER APPLICATIONS
  // ============================================================================
  Widget _buildDepartmentTasksTab(
    BuildContext context,
    FellowshipState state,
    String deptId,
    List<VolunteerApplicationModel> pendingApps,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final q = _tasksSearch.trim().toLowerCase();

    // Filter pending applications
    final filteredApps = pendingApps.where((app) {
      if (q.isEmpty) return true;
      return app.studentName.toLowerCase().contains(q) ||
          app.studentBaptismalName.toLowerCase().contains(q) ||
          app.studentDept.toLowerCase().contains(q) ||
          app.reason.toLowerCase().contains(q);
    }).toList();

    final deptSpecificCount = _getDeptSpecificBadgeCount(state, deptId);
    final totalCount = filteredApps.length + deptSpecificCount;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Search Bar for Tasks
        TextField(
          onChanged: (val) => _updateUi(() => _tasksSearch = val),
          decoration: InputDecoration(
            hintText: 'Search tasks & volunteer applications...',
            hintStyle: TextStyle(fontSize: 12, color: textMuted),
            prefixIcon: Icon(Icons.search, size: 20, color: primaryAccent),
            suffixIcon: _tasksSearch.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _updateUi(() => _tasksSearch = ''),
                  )
                : null,
            filled: true,
            fillColor: elevatedBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryAccent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Pending Volunteer Applications Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'VOLUNTEER APPLICATIONS (${filteredApps.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: primaryAccent,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isAudit)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A65E).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFF5A65E).withOpacity(0.3),
                  ),
                ),
                child: const Text(
                  'Read-Only Audit',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFFF5A65E),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        if (filteredApps.isEmpty && pendingApps.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No volunteer applications match "$_tasksSearch"',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
          )
        else if (filteredApps.isEmpty && pendingApps.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.emerald,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No pending volunteer applications for ${FellowshipDepartmentConstants.getNameAmharic(deptId)}.',
                    style: TextStyle(fontSize: 12, color: textMuted),
                  ),
                ),
              ],
            ),
          )
        else
          ...filteredApps.map((app) {
            return InteractiveFellowshipCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              color: cardBg,
              borderColor: theme.dividerColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: primaryAccent.withOpacity(0.12),
                        child: Text(
                          app.studentName.isNotEmpty ? app.studentName[0] : 'V',
                          style: TextStyle(
                            color: primaryAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.studentName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: textCol,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'B.N. ${app.studentBaptismalName} • Year ${app.studentYear} • ${app.studentDept}',
                              style: TextStyle(
                                fontSize: 11,
                                color: primaryAccent,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (app.choirWing != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            app.choirWing == ChoirWingType.mezmur
                                ? 'Mezmur'
                                : 'Fine Arts',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Motivation / Ministry Reason:',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    app.reason,
                    style: TextStyle(
                      fontSize: 11,
                      color: textCol,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  if (!isAudit) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            state.rejectVolunteerApplication(app.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Application from ${app.studentName} rejected.',
                                ),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.crimson,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            state.approveVolunteerApplication(app.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${app.studentName} accepted into ${FellowshipDepartmentConstants.getNameAmharic(deptId)}!',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.check,
                            size: 14,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Accept Volunteer',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),

        const SizedBox(height: 18),

        // 3. Department-Specific Pending Tasks Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'DEPARTMENT ACTION QUEUE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: primaryAccent,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$deptSpecificCount Pending',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primaryAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (deptId == FellowshipDepartmentConstants.deptMemberCare)
          _buildMemberCareTasksList(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptBatchPrograms)
          _buildBatchProgramsTasksList(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptCharity)
          _buildCharityTasksList(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptDevelopment)
          _buildDevelopmentTasksList(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptChoir)
          _buildChoirTasksList(context, state, isAudit)
        else if (deptId == FellowshipDepartmentConstants.deptSacredArts)
          _buildSacredArtsTasksList(context, state, isAudit)
        else
          _buildGenericDepartmentTasksList(context, state, deptId, isAudit),

        if (totalCount == 0) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.emerald.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.task_alt, color: AppTheme.emerald, size: 36),
                const SizedBox(height: 8),
                Text(
                  'All Department Tasks Complete! / ሁሉም ስራዎች ተጠናቀዋል',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'No pending volunteer applications or action items requiring coordinator review at this moment.',
                  style: TextStyle(fontSize: 11, color: textMuted),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  // --- Department Task Queue Sub-Builders ---

  Widget _buildMemberCareTasksList(
    BuildContext context,
    FellowshipState state,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;

    final underReview = state.emergencyAidRequests
        .where((r) => r.status == EmergencyAidStatus.underReview)
        .toList();
    if (underReview.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.emerald,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No emergency student aid requests under review.',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: underReview.map((req) {
        return InteractiveFellowshipCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          color: cardBg,
          borderColor: const Color(0xFFF59E0B).withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.medical_services_outlined,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${req.studentName} (${req.category.displayName})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'ETB ${req.amountRequested.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                req.description,
                style: TextStyle(fontSize: 11, color: textMuted),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isAudit) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        _tabController.animateTo(3); // Navigate to Tools tab
                      },
                      child: const Text(
                        'Review in Tools / ወደ መሣሪያዎች ሂድ',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBatchProgramsTasksList(
    BuildContext context,
    FellowshipState state,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;

    final pendingPayments = state.allTripRegistrations
        .where((r) => r.paymentStatus == TripPaymentStatus.pendingVerification)
        .toList();
    if (pendingPayments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.emerald,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'All pilgrimage payments verified and confirmed.',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: pendingPayments.map((reg) {
        return InteractiveFellowshipCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          color: cardBg,
          borderColor: const Color(0xFFF59E0B).withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.directions_bus_outlined,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${reg.studentName} • Bus ${reg.busNumber} Seat ${reg.seatNumber}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'ETB ${reg.feeAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${reg.tripTitle} • Ref: ${reg.transactionReference}',
                style: TextStyle(fontSize: 11, color: textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isAudit) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        final rejected = await state.verifyTripPayment(
                          reg.id,
                          false,
                          rejectionReason: 'Declined by coordinator',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              rejected
                                  ? 'Payment declined for ${reg.studentName}.'
                                  : 'Payment decision could not be saved. Refresh and try again.',
                            ),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.crimson,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        final verified = await state.verifyTripPayment(
                          reg.id,
                          true,
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              verified
                                  ? 'Payment verified for ${reg.studentName}.'
                                  : 'Payment verification could not be saved. Refresh and try again.',
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        'Verify & Issue Ticket',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCharityTasksList(
    BuildContext context,
    FellowshipState state,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;

    final pendingDues = state.duesPayments
        .where(
          (d) =>
              d.status == 'Pending Verification' ||
              d.status == 'pendingVerification',
        )
        .toList();
    if (pendingDues.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.emerald,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'All monthly charity dues and pledges verified.',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: pendingDues.map((due) {
        return InteractiveFellowshipCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          color: cardBg,
          borderColor: const Color(0xFFF59E0B).withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.volunteer_activism_outlined,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${due.studentName} (${due.purpose})',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'ETB ${due.amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Ref: ${due.transactionReference} • Via: ${due.paymentMethod}',
                style: TextStyle(fontSize: 11, color: textMuted),
              ),
              if (!isAudit) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        try {
                          await state.verifyDuesPayment(due.id, false);
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not decline payment: $error')),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.crimson,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        try {
                          await state.verifyDuesPayment(due.id, true);
                        } catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Could not verify payment: $error')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                      child: const Text(
                        'Verify Dues',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDevelopmentTasksList(
    BuildContext context,
    FellowshipState state,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;

    final pendingProposals = state.fundraisingProposals
        .where((p) => p.isPending)
        .toList();
    if (pendingProposals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: AppTheme.emerald,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'No fundraising proposals awaiting review.',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: pendingProposals.map((prop) {
        return InteractiveFellowshipCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          color: cardBg,
          borderColor: const Color(0xFFF59E0B).withOpacity(0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: Color(0xFFF59E0B),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      prop.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'ETB ${prop.targetAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${prop.category} • Submitted by: ${prop.submittedByName}',
                style: TextStyle(fontSize: 11, color: textMuted),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                prop.objective,
                style: TextStyle(fontSize: 11, color: textCol),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => _tabController.animateTo(3),
                    child: const Text(
                      'Manage in Tools / በመሣሪያዎች ይገምግሙ',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChoirTasksList(
    BuildContext context,
    FellowshipState state,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: primaryAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Mezmur/Choir Repertoire & Section Checks',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Keep liturgy hymns and Sunday service chants synchronized. Manage Digua, Mahlet, and Kebero duty shifts in the Tools tab.',
            style: TextStyle(fontSize: 11, color: textMuted, height: 1.3),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(3),
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text(
                'Open Choir Tools',
                style: TextStyle(fontSize: 11),
              ),
              style: OutlinedButton.styleFrom(foregroundColor: primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSacredArtsTasksList(
    BuildContext context,
    FellowshipState state,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primaryAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.palette_outlined, color: primaryAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sacred Arts Projects & Artifact Custody',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Review iconography conservation, sacred poetry submissions, and liturgical drama rehearsal schedules in the Tools tab.',
            style: TextStyle(fontSize: 11, color: textMuted, height: 1.3),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(3),
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text(
                'Open Sacred Arts Tools',
                style: TextStyle(fontSize: 11),
              ),
              style: OutlinedButton.styleFrom(foregroundColor: primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenericDepartmentTasksList(
    BuildContext context,
    FellowshipState state,
    String deptId,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.checklist_rtl_outlined,
                color: primaryAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${FellowshipDepartmentConstants.getNameAmharic(deptId)} Operations',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Access department management workflows, broadcasts, and operational registries through the Tools tab.',
            style: TextStyle(fontSize: 11, color: textMuted, height: 1.3),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _tabController.animateTo(3),
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text(
                'Open Tools Tab',
                style: TextStyle(fontSize: 11),
              ),
              style: OutlinedButton.styleFrom(foregroundColor: primaryAccent),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // TAB 3: ACTIVE VOLUNTEERS ROSTER & TEAM DIRECTORY
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
    final textCol = theme.colorScheme.onSurface;
    final textMuted =
        theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final q = _teamSearch.trim().toLowerCase();
    final filteredMembers = members.where((m) {
      if (q.isEmpty) return true;
      return m.studentName.toLowerCase().contains(q) ||
          m.studentBaptismalName.toLowerCase().contains(q) ||
          m.studentDept.toLowerCase().contains(q) ||
          m.roleInDepartment.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Search Bar for Team
        TextField(
          onChanged: (val) => _updateUi(() => _teamSearch = val),
          decoration: InputDecoration(
            hintText: 'Search servants by name, baptismal name, dept...',
            hintStyle: TextStyle(fontSize: 12, color: textMuted),
            prefixIcon: Icon(Icons.search, size: 20, color: primaryAccent),
            suffixIcon: _teamSearch.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _updateUi(() => _teamSearch = ''),
                  )
                : null,
            filled: true,
            fillColor: elevatedBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryAccent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // 2. Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'ACTIVE SERVANTS (${filteredMembers.length})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: primaryAccent,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${members.length} Total',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: primaryAccent,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (filteredMembers.isEmpty && members.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.person_search_outlined,
                    size: 36,
                    color: textMuted.withOpacity(0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No servants match "$_teamSearch"',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () => _updateUi(() => _teamSearch = ''),
                    child: const Text(
                      'Reset Search',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (filteredMembers.isEmpty && members.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.groups_outlined,
                    size: 40,
                    color: textMuted.withOpacity(0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No active servants in this department roster yet.',
                    style: TextStyle(fontSize: 13, color: textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...filteredMembers.map((member) {
            return InteractiveFellowshipCard(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              color: cardBg,
              borderColor: theme.dividerColor,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 19,
                    backgroundColor: elevatedBg,
                    child: Text(
                      member.studentName.isNotEmpty
                          ? member.studentName[0]
                          : 'S',
                      style: TextStyle(
                        color: primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.studentName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textCol,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'B.N. ${member.studentBaptismalName} • Year ${member.studentYear}',
                          style: TextStyle(fontSize: 10, color: primaryAccent),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${member.studentDept} • Role: ${member.roleInDepartment}',
                          style: TextStyle(fontSize: 9, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Call Volunteer / ደውል',
                    icon: const Icon(Icons.phone_outlined, size: 18),
                    color: primaryAccent,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      state.launchCall(member.phoneNumber);
                    },
                  ),
                  IconButton(
                    tooltip: 'Chat on Telegram / በቴሌግራም አውራ',
                    icon: const Icon(Icons.telegram, size: 20),
                    color: const Color(0xFF38A3E5),
                    onPressed: () async {
                      HapticFeedback.selectionClick();
                      final launched = await state.launchTelegram(
                        member.phoneNumber,
                      );
                      if (!launched && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Could not open Telegram for ${member.studentName} (${member.phoneNumber})',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  void _confirmDeleteDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HELPER WIDGETS
  // --------------------------------------------------------------------------
  Widget _buildFinancialSubTile(
    BuildContext context, {
    required String label,
    required String amount,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color:
                  theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMiniBadge(BuildContext context, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildTicketDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

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
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: primaryAccent,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
          child: Text(
            time,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: primaryAccent,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            desc,
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface),
          ),
        ),
      ],
    );
  }
}
