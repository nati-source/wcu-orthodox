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
/// - Each coordinator gets an interactive, customized department control room tailored to their ministry.
class CoordinatorHubScreen extends StatefulWidget {
  final FellowshipState state;

  const CoordinatorHubScreen({super.key, required this.state});

  @override
  State<CoordinatorHubScreen> createState() => _CoordinatorHubScreenState();
}

class _CoordinatorHubScreenState extends State<CoordinatorHubScreen> with SingleTickerProviderStateMixin {
  void _updateUi(VoidCallback fn) => setState(fn);
  late TabController _tabController;
  ChoirWingType? _choirWingFilter; // For Music Department: Mezmur vs Fine Arts

  // Interactive Pilgrimage Controls (ባችና መርሐ ግብራት)
  String _pilgrimFilter = 'All'; // 'All', 'Pending Approval', 'Verified', 'Declined'
  String _pilgrimSearch = '';
  String? _selectedTripFilter; // null = all trips

  // Interactive Charity Controls (ሙያና በጎ አድራጎት)
  int _charityLedgerTab = 0; // 0: Campaigns, 1: Donations/Dues Inflow, 2: Aid Disbursements Outflow

  // Interactive Education Controls (ትምህርትና ሐዋርያዊ አገልግሎት)
  String _educationCategoryFilter = 'All'; // 'All', 'Course Info', 'Special Program', 'Urgent Alert'
  String _educationBatchFilter = 'All'; // 'All', '1', '2', '3', '4', '5'

  // Interactive Development & Fundraising Controls (ልማትና ገቢ አሰባሰብ)
  String _developmentProposalStatusFilter = 'All'; // 'All', 'Pending', 'Approved', 'Rejected'
  String _developmentSearch = '';

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
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
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
    } else if (deptId == FellowshipDepartmentConstants.deptCharity) {
      return state.duesPayments.where((d) => d.status == 'Pending Verification').length;
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
                        color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
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
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
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
                  final launched = await state.launchTelegram(member.phoneNumber);
                  if (!launched && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Could not open Telegram for ${member.studentName} (${member.phoneNumber})'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }



  void _confirmDeleteDialog(BuildContext context, {required String title, required String message, required VoidCallback onConfirm}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HELPER WIDGETS
  // --------------------------------------------------------------------------
  Widget _buildFinancialSubTile(BuildContext context, {required String label, required String amount, required Color color}) {
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
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
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
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
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
            child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
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
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
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
