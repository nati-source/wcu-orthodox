import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';


part 'approvals/approvals_emergency_aid_tab.dart';
part 'approvals/approvals_roles_tab.dart';
part 'approvals/approvals_priests_tab.dart';
part 'approvals/approvals_proposals_tab.dart';

class AdminApprovalsScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback? onBackPressed;

  const AdminApprovalsScreen({super.key, required this.state, this.onBackPressed});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  void _updateUi(VoidCallback fn) => setState(fn);
  String _proposalStatusFilter = 'All'; // 'All', 'Pending', 'Approved', 'Rejected'
  String _proposalSearch = '';
  String _roleSearchQuery = '';
  String _roleFilter = 'All'; // 'All' or UserRole.name

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final allStudents = state.allStudents;
    final aidRequests = state.emergencyAidRequests;
    final proposals = state.fundraisingProposals;
    final pendingProposals = proposals.where((p) => p.isPending).toList();

    final isCoordinator = state.activeRole == UserRole.volunteerCoordinator;
    final canSeePriests = state.canSchedulePriests;
    final canSeeRoles = state.canAssignRoles;
    final canSeeAid = state.canManageEmergencyAid;
    final canSeeProposals = state.isAdmin ||
        (isCoordinator &&
            (state.currentUser.coordinatorProfile?.departmentId == FellowshipDepartmentConstants.deptDevelopment ||
                state.currentUser.coordinatorProfile?.departmentId == FellowshipDepartmentConstants.deptAudit));

    // Dynamically build visible governance tabs
    final List<Widget> tabs = [];
    final List<Widget> views = [];

    if (canSeeProposals) {
      tabs.add(Tab(text: 'Proposals (${pendingProposals.length})'));
      views.add(_buildFundraisingProposalsTab(context, state));
    }

    if (canSeePriests) {
      tabs.add(Tab(text: 'Priests & Schedules (${state.confessorFathers.length})'));
      views.add(_buildPriestsAndSchedulesTab(context, state));
    }

    if (canSeeAid) {
      tabs.add(Tab(text: 'Emergency Aid (${aidRequests.length})'));
      views.add(_buildEmergencyAidTab(context, aidRequests));
    }

    if (canSeeRoles) {
      tabs.add(const Tab(text: 'Role Assignments'));
      views.add(_buildRoleAssignmentsTab(context, allStudents));
    }

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            isCoordinator ? 'Approvals & Governance • ማስተባበሪያ' : 'Admin Approvals & Oversight',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryAccent,
            ),
          ),
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
          bottom: TabBar(
            isScrollable: tabs.length > 2,
            indicatorColor: primaryAccent,
            labelColor: primaryAccent,
            unselectedLabelColor: theme.textTheme.bodyMedium?.color ?? AppTheme.textTertiary,
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: views,
        ),
      ),
    );
  }

  // ----------------------------------------------------
}
