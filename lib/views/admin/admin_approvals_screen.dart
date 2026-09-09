import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminApprovalsScreen extends StatefulWidget {
  final FellowshipState state;

  const AdminApprovalsScreen({super.key, required this.state});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  String? _selectedCoordinatorDeptId; // null = All departments
  int _volunteerSubTab = 0; // 0: Applications Inbox, 1: Active Servants Roster
  ChoirWingType? _choirWingFilter; // null = All wings, or mezmur / fineArts

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final pendingStudents = state.pendingApprovals;
    final allStudents = state.allStudents;
    final pendingTrips = state.allTripRegistrations
        .where((r) => r.paymentStatus == TripPaymentStatus.pendingVerification)
        .toList();
    final aidRequests = state.emergencyAidRequests;
    final volunteerApps = state.getApplicationsForDepartment(_selectedCoordinatorDeptId);
    final pendingVolunteerCount = state.volunteerApplications
        .where((a) => a.status == ApplicationStatus.pending)
        .length;

    final isCoordinator = state.activeRole == UserRole.volunteerCoordinator;
    final canSeeStudents = state.canApproveGeneralStudents;
    final canSeePriests = state.canSchedulePriests;
    final canSeeRoles = state.canAssignRoles;
    final canSeeTrips = state.canManagePilgrimages;
    final canSeeAid = state.canManageEmergencyAid;

    // Dynamically build visible tabs
    final List<Widget> tabs = [];
    final List<Widget> views = [];

    if (canSeeStudents) {
      tabs.add(Tab(text: 'Students (${pendingStudents.length})'));
      views.add(_buildStudentRegistrationsTab(context, pendingStudents));
    }

    if (canSeePriests) {
      tabs.add(Tab(text: 'Priests & Schedules (${state.confessorFathers.length})'));
      views.add(_buildPriestsAndSchedulesTab(context, state));
    }

    // Always show Volunteer Applications tab
    tabs.add(Tab(text: isCoordinator ? 'My Dept Volunteers ($pendingVolunteerCount)' : '10 Dept Volunteers ($pendingVolunteerCount)'));
    views.add(_buildDepartmentCoordinatorRecruitmentTab(context, state, volunteerApps));

    if (canSeeTrips) {
      tabs.add(Tab(text: 'Trip Payments (${pendingTrips.length})'));
      views.add(_buildTripPaymentsTab(context, pendingTrips));
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
            isCoordinator ? 'Coordinator Approvals • ማስተባበሪያ' : 'Admin Approvals & Oversight',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryAccent,
            ),
          ),
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
  // TAB 1: STUDENT REGISTRATIONS
  // ----------------------------------------------------
  Widget _buildStudentRegistrationsTab(BuildContext context, List<UserModel> pending) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 48),
            const SizedBox(height: 12),
            Text(
              'No pending student verifications.',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: pending.length,
      itemBuilder: (ctx, index) {
        final student = pending[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.3 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    child: Text(
                      student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                      style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'B.N. ${student.baptismalName} • Year ${student.academicYear}',
                          style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Department: ${student.department} • Batch ${student.batchYear}',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
              Text(
                'Phone: ${student.phoneNumber}',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ?? AppTheme.textTertiary),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      state.rejectStudent(student.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Registration for ${student.fullName} rejected.')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.crimson,
                      side: const BorderSide(color: AppTheme.crimson),
                    ),
                    child: const Text('Reject', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      state.approveStudent(student.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${student.fullName} verified & added to fellowship!'),
                          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                    ),
                    child: const Text('Approve & Assign', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 2: 10 EOTC DEPARTMENT COORDINATOR RECRUITMENT & ROSTER
  // ----------------------------------------------------
  Widget _buildDepartmentCoordinatorRecruitmentTab(
    BuildContext context,
    FellowshipState state,
    List<VolunteerApplicationModel> apps,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final ministries = state.ministries;
    final isCoordinator = state.activeRole == UserRole.volunteerCoordinator;
    final isAuditCoordinator = isCoordinator && (state.currentUser.coordinatorProfile?.isReadOnlyAudit == true);
    final myDeptId = state.currentUser.coordinatorProfile?.departmentId;

    // For non-audit coordinators, enforce their scoped department ID
    final effectiveDeptId = (isCoordinator && !isAuditCoordinator)
        ? myDeptId
        : _selectedCoordinatorDeptId;

    final currentDept = effectiveDeptId != null
        ? ministries.firstWhere((m) => m.id == effectiveDeptId, orElse: () => ministries.first)
        : null;

    final scopedApps = state.getApplicationsForDepartment(effectiveDeptId);
    final members = state.getMembersForDepartment(effectiveDeptId);
    final canBroadcast = state.isAdmin || (isCoordinator && !isAuditCoordinator);
    final targetDeptForBroadcast = effectiveDeptId ?? (isCoordinator ? myDeptId : null) ?? FellowshipDepartmentConstants.deptEducation;

    final filteredApps = scopedApps.where((a) {
      if (effectiveDeptId == FellowshipDepartmentConstants.deptChoirArts && _choirWingFilter != null) {
        return a.choirWing == _choirWingFilter;
      }
      return true;
    }).toList();

    final filteredMembers = members.where((m) {
      if (effectiveDeptId == FellowshipDepartmentConstants.deptChoirArts && _choirWingFilter != null) {
        return m.choirWing == _choirWingFilter;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // 1. Department Perspective Selector Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(bottom: BorderSide(color: theme.dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isAuditCoordinator ? Icons.fact_check_outlined : Icons.shield_outlined,
                    color: isAuditCoordinator ? const Color(0xFFF5A65E) : primaryAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAuditCoordinator
                        ? 'AUDIT & INSPECTION ACCESS • READ ONLY'
                        : isCoordinator
                            ? 'SCOPED DEPARTMENT COORDINATOR ACCESS'
                            : 'COORDINATOR DELEGATION PERSPECTIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isAuditCoordinator ? const Color(0xFFF5A65E) : primaryAccent,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color ?? theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isAuditCoordinator ? const Color(0xFFF5A65E).withOpacity(0.5) : primaryAccent.withOpacity(0.4),
                  ),
                ),
                child: (isCoordinator && !isAuditCoordinator)
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.lock_outline, size: 16, color: AppTheme.amberGold),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🔒 Locked to: ${currentDept?.titleAmharic ?? 'My Department'} (${currentDept?.titleEn ?? ''})',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : DropdownButtonHideUnderline(
                        child: DropdownButton<String?>(
                          value: effectiveDeptId,
                          isExpanded: true,
                          dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                isAuditCoordinator
                                    ? '🔍 All 10 Departments (Cross-Department Audit Inspection)'
                                    : '🏛️ Executive View (All 10 Departments • ሁሉንም)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            ...ministries.map((m) {
                              return DropdownMenuItem<String?>(
                                value: m.id,
                                child: Text(
                                  '👤 ${m.titleAmharic} (${m.teamLead})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            }),
                          ],
                          onChanged: (val) => setState(() => _selectedCoordinatorDeptId = val),
                        ),
                      ),
              ),
            ],
          ),
        ),

        // 2. Audit Notice Banner or Department Coordinator Status Banner
        if (isAuditCoordinator)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFFF5A65E).withOpacity(0.12),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Color(0xFFF5A65E)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Audit Mode Active: Read-only inspection allowed across all 10 departments. Application status mutations are restricted.',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.brightness == Brightness.dark ? const Color(0xFFFFCC80) : const Color(0xFFD84315),
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (currentDept != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: theme.colorScheme.surfaceContainer,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: primaryAccent.withOpacity(0.2),
                  child: Icon(Icons.person, size: 16, color: primaryAccent),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Coordinator: ${currentDept.teamLead} (${currentDept.coordinatorBaptismalName}) • ${currentDept.coordinatorPhone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.85)),
                  ),
                ),
              ],
            ),
          ),

        // 2.5 Department Specialized Actions Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // 1. Broadcast Meeting / Notice
                if (canBroadcast)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.campaign, size: 16, color: Colors.white),
                      backgroundColor: primaryAccent,
                      label: const Text('📢 Broadcast Notice / መመሪያ', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _showBroadcastDialog(context, state, targetDeptForBroadcast),
                    ),
                  ),

                // 2. Guest Speaker Announcement (DEPT_EDUCATION)
                if (effectiveDeptId == FellowshipDepartmentConstants.deptEducation || state.canPublishSpecialTeacherNotice)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.record_voice_over, size: 16, color: Colors.white),
                      backgroundColor: const Color(0xFF8B5CF6),
                      label: const Text('🌟 Guest Preacher Alert', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _showSpecialTeacherNoticeDialog(context, state),
                    ),
                  ),

                // 3. Family Smart Matching (DEPT_MEMBER_CARE)
                if (effectiveDeptId == FellowshipDepartmentConstants.deptMemberCare || state.canManageFamilyMatching)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.family_restroom, size: 16, color: Colors.white),
                      backgroundColor: const Color(0xFF10B981),
                      label: const Text('👨‍👩‍👧‍👦 Family Smart Matching', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _showFamilyMatchingConfirmDialog(context, state),
                    ),
                  ),

                // 4. Fundraising Proposals (DEPT_DEVELOPMENT)
                if (effectiveDeptId == FellowshipDepartmentConstants.deptDevelopment || state.canSubmitFundraisingProposal || state.isAdmin) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.add_chart, size: 16, color: Colors.white),
                      backgroundColor: const Color(0xFFD97706),
                      label: const Text('💼 Submit Proposal', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _showFundraisingProposalDialog(context, state),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      avatar: const Icon(Icons.receipt_long, size: 16, color: Colors.white),
                      backgroundColor: const Color(0xFF4B5563),
                      label: Text('📋 Proposals (${state.fundraisingProposals.length})', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      onPressed: () => _showFundraisingProposalsListDialog(context, state),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // 2.6 Dual Leadership & Choir Wings Filter (DEPT_CHOIR_ARTS)
        if (effectiveDeptId == FellowshipDepartmentConstants.deptChoirArts)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryAccent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.theater_comedy, size: 16, color: primaryAccent),
                const SizedBox(width: 8),
                Text('Wings:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Wings', style: TextStyle(fontSize: 10)),
                          selected: _choirWingFilter == null,
                          onSelected: (selected) => setState(() => _choirWingFilter = null),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('🎼 መዝሙር (Lead: Dawit Fikadu)', style: TextStyle(fontSize: 10)),
                          selected: _choirWingFilter == ChoirWingType.mezmur,
                          onSelected: (selected) => setState(() => _choirWingFilter = selected ? ChoirWingType.mezmur : null),
                        ),
                        const SizedBox(width: 6),
                        ChoiceChip(
                          label: const Text('🎭 ስነ ጥበባት (Lead: Martha Tedla)', style: TextStyle(fontSize: 10)),
                          selected: _choirWingFilter == ChoirWingType.fineArts,
                          onSelected: (selected) => setState(() => _choirWingFilter = selected ? ChoirWingType.fineArts : null),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 3. Sub-Tab Toggle (Applicant Inbox vs Active Servants Roster)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _volunteerSubTab = 0);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _volunteerSubTab == 0
                          ? (theme.cardTheme.color ?? theme.colorScheme.surface)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: _volunteerSubTab == 0 ? Border.all(color: primaryAccent.withOpacity(0.5)) : null,
                    ),
                    child: Center(
                      child: Text(
                        'Applicant Queue (${filteredApps.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _volunteerSubTab == 0 ? FontWeight.bold : FontWeight.normal,
                          color: _volunteerSubTab == 0
                              ? primaryAccent
                              : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _volunteerSubTab = 1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _volunteerSubTab == 1
                          ? (theme.cardTheme.color ?? theme.colorScheme.surface)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: _volunteerSubTab == 1 ? Border.all(color: primaryAccent.withOpacity(0.5)) : null,
                    ),
                    child: Center(
                      child: Text(
                        'Active Servants Roster (${filteredMembers.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _volunteerSubTab == 1 ? FontWeight.bold : FontWeight.normal,
                          color: _volunteerSubTab == 1
                              ? primaryAccent
                              : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 4. Body Content
        Expanded(
          child: _volunteerSubTab == 0
              ? _buildApplicantQueueList(context, state, filteredApps)
              : _buildActiveServantsRosterList(context, state, filteredMembers),
        ),
      ],
    );
  }

  Widget _buildApplicantQueueList(
    BuildContext context,
    FellowshipState state,
    List<VolunteerApplicationModel> apps,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    if (apps.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? AppTheme.textTertiary, size: 44),
            const SizedBox(height: 10),
            Text(
              'No volunteer applications in this queue.',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: apps.length,
      itemBuilder: (ctx, index) {
        final app = apps[index];
        final isPending = app.status == ApplicationStatus.pending;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: app.status == ApplicationStatus.approved
                  ? AppTheme.emerald
                  : app.status == ApplicationStatus.rejected
                      ? AppTheme.crimson
                      : primaryAccent.withOpacity(0.6),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Candidate Name & Status Pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${app.studentName} (${app.studentBaptismalName})',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${app.studentDept} • Batch: ${app.studentYear}',
                          style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      app.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: app.status == ApplicationStatus.approved
                            ? AppTheme.emerald
                            : app.status == ApplicationStatus.rejected
                                ? AppTheme.crimson
                                : primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Department & Sub-wing
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.hub_outlined, color: primaryAccent, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${app.ministryAmharicTitle.isNotEmpty ? app.ministryAmharicTitle : app.ministryTitle} • ${app.preferredSubWing}',
                        style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              if (app.choirWing != null || app.languagesKnown.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (app.choirWing != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: primaryAccent.withOpacity(0.3)),
                        ),
                        child: Text(
                          '🎼 Wing: ${app.choirWing!.shortName}',
                          style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (app.languagesKnown.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Text(
                          '🗣️ Languages: ${app.languagesKnown.join(', ')}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],

              const SizedBox(height: 8),

              // Reason
              Text(
                'Calling: "${app.reason}"',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Experience: ${app.experience}',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ?? AppTheme.textTertiary),
              ),
              Text(
                'Availability: ${app.availability}',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ?? AppTheme.textTertiary),
              ),

              if (app.coordinatorNotes != null && app.coordinatorNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Note by ${app.reviewedByCoordinator}: ${app.coordinatorNotes}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.emerald, fontWeight: FontWeight.w600),
                ),
              ],

              const SizedBox(height: 12),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 6),

              // Actions: Quick Contact (Call / SMS) + Coordinator Decision
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.phone_outlined, color: primaryAccent, size: 18),
                    tooltip: 'Call Applicant',
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      state.launchCall(app.studentPhone);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.sms_outlined, color: primaryAccent, size: 18),
                    tooltip: 'SMS Applicant',
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      state.launchSms(
                        app.studentPhone,
                        body: 'Selam ${app.studentName}, this is regarding your application for ${app.ministryTitle}.',
                      );
                    },
                  ),
                  const Spacer(),
                  if (isPending) ...[
                    if (state.canAccessDepartmentWrite(app.ministryId)) ...[
                      OutlinedButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          state.rejectVolunteerApplication(app.id, notes: 'Declined by coordinator');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Application for ${app.studentName} declined.')),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.crimson,
                          side: const BorderSide(color: AppTheme.crimson),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        child: const Text('Decline', style: TextStyle(fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () => _openApprovalDialog(context, state, app),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text(
                          'Accept & Add to Roster',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ] else if (state.currentUser.coordinatorProfile?.isReadOnlyAudit == true) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5A65E).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF5A65E).withOpacity(0.4)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility_outlined, size: 12, color: Color(0xFFF5A65E)),
                            SizedBox(width: 4),
                            Text(
                              'Audit Inspection • Read Only',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E)),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Restricted to ${app.ministryTitle}',
                          style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveServantsRosterList(
    BuildContext context,
    FellowshipState state,
    List<DepartmentMemberModel> members,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? AppTheme.textTertiary, size: 44),
            const SizedBox(height: 10),
            Text('No active servants listed for this department.', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 13)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: members.length,
      itemBuilder: (ctx, index) {
        final mem = members[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Text(
                  mem.studentName.isNotEmpty ? mem.studentName[0] : 'S',
                  style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mem.studentName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      'B.N. ${mem.studentBaptismalName} • ${mem.studentDept} (${mem.studentYear})',
                      style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Role: ${mem.roleInDepartment} • Wing: ${mem.subWing}',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.phone_outlined, color: primaryAccent, size: 18),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  state.launchCall(mem.phoneNumber);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBroadcastDialog(BuildContext context, FellowshipState state, String deptId) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final deptName = FellowshipDepartmentConstants.getNameAmharic(deptId);
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final locationCtrl = TextEditingController(text: 'Campus Chapel / Main Hall');
    String urgency = 'normal';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('📢 Broadcast to $deptName', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Broadcast a direct meeting notice or announcement to all active servants and applicants in $deptName.',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Announcement Title / ርዕስ',
                        hintText: 'e.g. የቅዳሜ አስቸኳይ ስብሰባ',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bodyCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Message Body / መልእክት',
                        hintText: 'e.g. ነገ ከቀኑ 8:30 በዋናው አዳራሽ አጠቃላይ ግምገማ አለን።',
                      ),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: urgency,
                      decoration: const InputDecoration(labelText: 'Category / የአስቸኳይነት ደረጃ'),
                      dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                      items: const [
                        DropdownMenuItem(value: 'normal', child: Text('Normal Announcement (መደበኛ)')),
                        DropdownMenuItem(value: 'meeting', child: Text('Meeting Notice (የስብሰባ ጥሪ)')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent Alert (አስቸኳይ ማስታወቂያ)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => urgency = val);
                      },
                    ),
                    if (urgency == 'meeting') ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: locationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Meeting Location / የስብሰባ ቦታ',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) return;
                    HapticFeedback.mediumImpact();
                    state.sendDepartmentBroadcast(
                      departmentId: deptId,
                      title: titleCtrl.text.trim(),
                      body: bodyCtrl.text.trim(),
                      urgency: urgency,
                      meetingLocation: urgency == 'meeting' ? locationCtrl.text.trim() : null,
                      meetingTime: urgency == 'meeting' ? DateTime.now().add(const Duration(days: 1)) : null,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Notice broadcasted to $deptName!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                  ),
                  child: const Text('Send Broadcast', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSpecialTeacherNoticeDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final teacherCtrl = TextEditingController(text: 'መጋቤ ሐዲስ ዶ/ር ሮዳስ ታደሰ');
    final titleCtrl = TextEditingController(text: 'መምህር');
    final topicCtrl = TextEditingController(text: 'ኦርቶዶክሳዊ የአባቶች ታሪክና ስነ-ፍጥረት');
    final venueCtrl = TextEditingController(text: 'WCU Main Campus Great Hall');
    final notesCtrl = TextEditingController(text: 'ሁሉም ተማሪዎች ከመንፈሳዊ ወንድሞቻቸው ጋር እንዲገኙ ጥሪ ቀርቧል።');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('🌟 Guest Preacher Announcement', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Publish an official guest teacher alert to all students across the university.',
                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: teacherCtrl,
                  decoration: const InputDecoration(labelText: 'Teacher / Preacher Name (የመምህሩ ስም)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: topicCtrl,
                  decoration: const InputDecoration(labelText: 'Preaching Topic (የርዕሱ ዝርዝር)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: venueCtrl,
                  decoration: const InputDecoration(labelText: 'Venue / Auditorium (ቦታ)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Additional Notes (ተጨማሪ ማስታወሻ)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (teacherCtrl.text.trim().isEmpty || topicCtrl.text.trim().isEmpty) return;
                HapticFeedback.mediumImpact();
                state.publishSpecialGuestTeacherNotice(
                  teacherName: teacherCtrl.text.trim(),
                  teacherTitle: titleCtrl.text.trim(),
                  topic: topicCtrl.text.trim(),
                  venue: venueCtrl.text.trim(),
                  dateAndTime: DateTime.now().add(const Duration(days: 2, hours: 4)),
                  description: notesCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Guest Preacher notice published successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Publish Notice', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showFundraisingProposalDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final titleCtrl = TextEditingController();
    final objectiveCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '50000');
    final strategyCtrl = TextEditingController();
    final audienceCtrl = TextEditingController(text: 'Campus students, alumni and Sunday school faithful');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('💼 Submit Fundraising Proposal', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Submit a formal revenue collection initiative to the Fellowship Admin Board for approval.',
                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Proposal Title (የፕሮጀክቱ ርዕስ)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: objectiveCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Objective / Purpose (ዓላማ)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Target Amount (ETB / የገንዘብ ግብ)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: strategyCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Execution Strategy (የአፈፃፀም ስልት)'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: audienceCtrl,
                  decoration: const InputDecoration(labelText: 'Target Audience (ታሳቢ ደንበኞች)'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || objectiveCtrl.text.trim().isEmpty) return;
                final targetAmt = double.tryParse(amountCtrl.text.trim()) ?? 10000.0;
                HapticFeedback.mediumImpact();
                state.submitFundraisingProposal(
                  title: titleCtrl.text.trim(),
                  objective: objectiveCtrl.text.trim(),
                  targetAmount: targetAmt,
                  proposedStrategy: strategyCtrl.text.trim().isNotEmpty ? strategyCtrl.text.trim() : 'Holiday Bazaar & sales',
                  targetAudience: audienceCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fundraising proposal submitted to Admin Board!')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
              child: const Text('Submit Proposal', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showFundraisingProposalsListDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final proposals = state.fundraisingProposals;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('📋 Development Proposals (${proposals.length})', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: proposals.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No fundraising proposals submitted yet.'),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: proposals.length,
                        itemBuilder: (c, i) {
                          final prop = proposals[i];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: prop.status == ProposalStatus.approved
                                    ? AppTheme.emerald
                                    : prop.status == ProposalStatus.rejected
                                        ? AppTheme.crimson
                                        : const Color(0xFFD97706),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        prop.title,
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.cardTheme.color ?? theme.colorScheme.surface,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        prop.status.name.toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: prop.status == ProposalStatus.approved
                                              ? AppTheme.emerald
                                              : prop.status == ProposalStatus.rejected
                                                  ? AppTheme.crimson
                                                  : const Color(0xFFD97706),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Target: ${prop.targetAmount.toStringAsFixed(0)} ETB • By: ${prop.submittedByName}',
                                  style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Goal: ${prop.objective}',
                                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                                ),
                                if (prop.adminReviewNotes != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Admin Note: ${prop.adminReviewNotes}',
                                    style: const TextStyle(fontSize: 10, color: AppTheme.emerald, fontStyle: FontStyle.italic),
                                  ),
                                ],
                                if (state.isAdmin && prop.status == ProposalStatus.pending) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          state.reviewFundraisingProposal(
                                            proposalId: prop.id,
                                            status: ProposalStatus.rejected,
                                            adminNotes: 'Requires revision.',
                                          );
                                          setDialogState(() {});
                                        },
                                        child: const Text('Reject', style: TextStyle(color: AppTheme.crimson, fontSize: 11)),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: () {
                                          state.reviewFundraisingProposal(
                                            proposalId: prop.id,
                                            status: ProposalStatus.approved,
                                            adminNotes: 'Approved by Admin Board for execution.',
                                          );
                                          setDialogState(() {});
                                        },
                                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emerald, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                        child: const Text('Approve', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showFamilyMatchingConfirmDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('👨‍👩‍👧‍👦 Run Smart Family Matching', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Member Care & Counseling Coordinator Privilege:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Automatically balance and match newly approved students into spiritual families based on batch distribution, academic departments, and capacity constraints.',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(ctx);
                await state.runSmartMatching();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Smart Family Matching completed successfully!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('Execute Matching', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openApprovalDialog(
    BuildContext context,
    FellowshipState state,
    VolunteerApplicationModel app,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final noteController = TextEditingController(
      text: 'Welcome! You are approved for ${app.preferredSubWing}. Rehearsal briefing will follow.',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text(
            'Accept ${app.studentName}',
            style: TextStyle(color: primaryAccent, fontFamily: 'serif', fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assigning to ${app.ministryTitle} (${app.preferredSubWing}).',
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.8)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Welcome note / Instructions for recruit'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                state.approveVolunteerApplication(
                  app.id,
                  notes: noteController.text.trim(),
                  reviewedBy: 'Department Coordinator',
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${app.studentName} added to active department roster!'),
                    backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAccent,
                foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
              child: const Text('Confirm & Onboard', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 3: PILGRIMAGE PAYMENTS (TELEBIRR & CBE)
  // ----------------------------------------------------
  Widget _buildTripPaymentsTab(BuildContext context, List<TripRegistrationModel> pending) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    if (pending.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.done_all, color: AppTheme.emerald, size: 48),
            const SizedBox(height: 12),
            Text(
              'All pilgrimage payments verified.',
              style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: pending.length,
      itemBuilder: (ctx, index) {
        final reg = pending[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryAccent.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      reg.tripTitle,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ),
                  Text(
                    '${reg.feeAmount.toInt()} ETB',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: primaryAccent),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Pilgrim: ${reg.studentName} (${reg.studentBaptismalName}) • ${reg.department}',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Method: ${reg.paymentMethod.displayName}',
                style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Transaction Ref: ${reg.transactionReference}',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      state.verifyTripPayment(reg.id, false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment marked as rejected')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.crimson,
                      side: const BorderSide(color: AppTheme.crimson),
                    ),
                    child: const Text('Decline Payment', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      state.verifyTripPayment(reg.id, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Payment verified & Boarding pass issued to ${reg.studentName}'),
                          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    child: const Text('Verify & Issue Ticket', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 4: EMERGENCY STUDENT AID
  // ----------------------------------------------------
  Widget _buildEmergencyAidTab(BuildContext context, List<EmergencyAidRequestModel> requests) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    if (requests.isEmpty) {
      return Center(
        child: Text('No emergency aid applications on file.', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 14)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: requests.length,
      itemBuilder: (ctx, index) {
        final req = requests[index];
        final isUnderReview = req.status == EmergencyAidStatus.underReview;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: req.status.color.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(req.category.displayName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: req.status.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: req.status.color),
                    ),
                    child: Text(req.status.displayName, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: req.status.color)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Student: ${req.studentName} (${req.studentBaptismalName}) • ${req.department} Yr ${req.academicYear}',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount Requested: ${req.amountRequested.toInt()} ETB',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryAccent),
              ),
              const SizedBox(height: 6),
              Text(
                req.description,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.85), height: 1.3),
              ),
              if (isUnderReview) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        state.updateAidRequestStatus(req.id, EmergencyAidStatus.declined, adminNote: 'Declined by review committee.');
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.crimson,
                        side: const BorderSide(color: AppTheme.crimson),
                      ),
                      child: const Text('Decline', style: TextStyle(fontSize: 12)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        state.updateAidRequestStatus(req.id, EmergencyAidStatus.disbursed, adminNote: 'Approved & Disbursed via Telebirr');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Aid marked approved & disbursed to ${req.studentName}'),
                            backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      child: const Text('Approve & Disburse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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

  // ----------------------------------------------------
  // TAB 5: ROLE ASSIGNMENTS
  // ----------------------------------------------------
  Widget _buildRoleAssignmentsTab(BuildContext context, List<UserModel> allStudents) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: allStudents.length,
      itemBuilder: (ctx, index) {
        final student = allStudents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                child: Text(
                  student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                  style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface, fontSize: 14),
                    ),
                    Text(
                      student.department,
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<UserRole>(
                  value: student.role,
                  dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                  icon: Icon(Icons.arrow_drop_down, color: primaryAccent),
                  items: UserRole.values.map((r) {
                    return DropdownMenuItem(
                      value: r,
                      child: Text(
                        r.displayName.split(' ').first,
                        style: TextStyle(fontSize: 12, color: r.badgeColor, fontWeight: FontWeight.bold),
                      ),
                    );
                  }).toList(),
                  onChanged: (newRole) {
                    if (newRole != null) {
                      HapticFeedback.selectionClick();
                      state.assignUserRole(student.id, newRole);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Updated ${student.fullName} role to ${newRole.displayName}')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 6: PRIESTS, VENUES & SCHEDULE MANAGEMENT
  // ----------------------------------------------------
  Widget _buildPriestsAndSchedulesTab(BuildContext context, FellowshipState state) {
    final fathers = state.confessorFathers;
    final allAppts = state.confessionAppointments;
    final pendingAppts = allAppts.where((a) => a.status == ConfessionAppointmentStatus.pending).toList();
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Action Bar: Add Priest & Broadcast Schedule
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openAddEditPriestDialog(context, null),
                icon: Icon(Icons.person_add_alt_1, size: 16, color: theme.brightness == Brightness.dark ? Colors.black : Colors.white),
                label: Text('Add Priest / Confessor', style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openBroadcastPriestScheduleDialog(context),
                icon: Icon(Icons.campaign_outlined, size: 16, color: primaryAccent),
                label: Text('Broadcast Alert', style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section 1: Active Confessor Fathers Roster & Meeting Places
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE CONFESSOR FATHERS & VENUES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textTertiary, letterSpacing: 1.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${fathers.length} Active Clergy',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (fathers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No confessor fathers registered. Tap "Add Priest / Confessor" above.',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          )
        else
          ...fathers.map((father) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: primaryAccent.withOpacity(0.15),
                        child: Icon(Icons.person, color: primaryAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              father.fullName,
                              style: TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            ),
                            Text(
                              '${father.clericalTitle} • ${father.churchName}',
                              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: primaryAccent, size: 18),
                        onPressed: () => _openAddEditPriestDialog(context, father),
                        tooltip: 'Edit Schedule & Place',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Meeting Venue Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place, color: primaryAccent, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Venue: ${father.meetingVenue}',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Available Days & Time Slots
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...father.availableDays.map((d) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Text(d, style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                          )),
                      ...father.availableTimeSlots.map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(s, style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.w600)),
                          )),
                    ],
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 24),

        // Section 2: Student Confession Bookings Review
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STUDENT APPOINTMENTS & CONFIRMATIONS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textTertiary, letterSpacing: 1.5),
            ),
            if (pendingAppts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pendingAppts.length} Pending',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (allAppts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No student appointments booked yet.',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          )
        else
          ...allAppts.map((appt) {
            final isPending = appt.status == ConfessionAppointmentStatus.pending;
            final isConfirmed = appt.status == ConfessionAppointmentStatus.confirmed;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isConfirmed
                      ? AppTheme.emerald
                      : isPending
                          ? primaryAccent
                          : AppTheme.crimson,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appt.studentName,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isConfirmed ? AppTheme.emerald : isPending ? primaryAccent : AppTheme.crimson).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appt.status.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isConfirmed ? AppTheme.emerald : isPending ? primaryAccent : AppTheme.crimson,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'With: ${appt.fatherName}',
                    style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Slot: ${appt.scheduledDate.year}-${appt.scheduledDate.month}-${appt.scheduledDate.day} • ${appt.timeSlot}',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                  ),
                  Text(
                    'Topic: ${appt.topic}',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85) ?? AppTheme.textTertiary),
                  ),

                  if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Note: ${appt.notes}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.emerald, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],

                  if (isPending) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            state.cancelConfessionAppointment(appt.id);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.crimson,
                            side: const BorderSide(color: AppTheme.crimson),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: const Text('Decline', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _openAppointmentConfirmationDialog(context, appt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryAccent,
                            foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('Confirm & Set Venue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  void _openAddEditPriestDialog(BuildContext context, ConfessorFatherModel? existing) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final state = widget.state;
    final isEditing = existing != null;

    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final titleCtrl = TextEditingController(text: existing?.clericalTitle ?? 'መልአከ ሰላም ቀሲስ');
    final churchCtrl = TextEditingController(text: existing?.churchName ?? 'St. Mary\'s Cathedral');
    final venueCtrl = TextEditingController(text: existing?.meetingVenue ?? 'St. Mary\'s Sunday School Office (Room 2)');
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? '+251911002233');
    final bioCtrl = TextEditingController(text: existing?.bio ?? 'Confessor, Youth Counselor & Liturgical Scholar');

    final selectedDays = List<String>.from(existing?.availableDays ?? ['Saturday', 'Sunday']);
    final selectedSlots = List<String>.from(existing?.availableTimeSlots ?? ['3:00 PM - 5:30 PM']);

    final allDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final allSlots = ['9:00 AM - 11:30 AM', '2:00 PM - 4:30 PM', '3:00 PM - 5:30 PM', '5:00 PM - 7:00 PM'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEditing ? 'Edit Priest & Venue' : 'Add Confessor Father',
                style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Father Full Name (e.g. Kesis Yohannes)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Clerical Title (e.g. መልአከ ሰላም ቀሲስ)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: churchCtrl,
                      decoration: const InputDecoration(labelText: 'Church / Parish Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: venueCtrl,
                      decoration: const InputDecoration(labelText: 'Meeting Place / Campus Venue', hintText: 'e.g. Sunday School Room 2'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number (Call / SMS)'),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Available Days:',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allDays.map((d) {
                        final isSel = selectedDays.contains(d);
                        return FilterChip(
                          label: Text(
                            d,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSel
                                  ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: primaryAccent,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedDays.add(d);
                              } else {
                                selectedDays.remove(d);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Available Time Slots:',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allSlots.map((s) {
                        final isSel = selectedSlots.contains(s);
                        return FilterChip(
                          label: Text(
                            s,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSel
                                  ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: primaryAccent,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedSlots.add(s);
                              } else {
                                selectedSlots.remove(s);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Pastoral Bio / Counseling Focus'),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      state.deleteConfessorFather(existing.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Priest profile removed')));
                    },
                    child: const Text('Delete', style: TextStyle(color: AppTheme.crimson)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    HapticFeedback.mediumImpact();

                    final updated = ConfessorFatherModel(
                      id: existing?.id ?? 'fat-${DateTime.now().millisecondsSinceEpoch}',
                      fullName: nameCtrl.text.trim(),
                      clericalTitle: titleCtrl.text.trim(),
                      churchName: churchCtrl.text.trim(),
                      meetingVenue: venueCtrl.text.trim().isNotEmpty ? venueCtrl.text.trim() : 'St. Mary\'s Sunday School Office (Room 2)',
                      phoneNumber: phoneCtrl.text.trim(),
                      availableDays: selectedDays.isNotEmpty ? selectedDays : ['Saturday', 'Sunday'],
                      availableTimeSlots: selectedSlots.isNotEmpty ? selectedSlots : ['3:00 PM - 5:30 PM'],
                      bio: bioCtrl.text.trim(),
                    );

                    if (isEditing) {
                      state.updateConfessorFather(updated);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Priest schedule & venue updated')));
                    } else {
                      state.addConfessorFather(updated);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New Confessor Father added')));
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Add Priest', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAppointmentConfirmationDialog(BuildContext context, ConfessionAppointmentModel appt) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final state = widget.state;
    final noteCtrl = TextEditingController(text: 'Confirmed. Please meet at Sunday School Office Room 2 and prepare Psalm 50.');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Confirm ${appt.studentName}\'s Visit', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Father: ${appt.fatherName}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
              Text('Topic: ${appt.topic}', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
              Text('Requested Date: ${appt.scheduledDate.year}-${appt.scheduledDate.month}-${appt.scheduledDate.day} (${appt.timeSlot})', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Confirmation Note & Venue Instructions',
                  hintText: 'e.g. Meet at Room 2, fast from midnight',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                state.confirmConfessionAppointment(appt.id, notes: noteCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Confirmed appointment for ${appt.studentName}')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Confirm Appointment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openBroadcastPriestScheduleDialog(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final state = widget.state;
    final fatherCtrl = TextEditingController(text: 'Kesis Yohannes Teshome');
    final changeCtrl = TextEditingController(text: 'Counseling location moved to Campus Prayer Hall for Saturday.');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Broadcast Clergy Notice', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send an instant broadcast notification to all students regarding schedule or venue updates.',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fatherCtrl,
                decoration: const InputDecoration(labelText: 'Father / Clergy Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: changeCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Venue / Schedule Update Details'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (changeCtrl.text.trim().isEmpty) return;
                HapticFeedback.mediumImpact();
                state.broadcastPriestScheduleAlert(
                  fatherName: fatherCtrl.text.trim(),
                  newVenueOrTime: changeCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clergy schedule broadcast sent to all students!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAccent,
                foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
              child: const Text('Broadcast Alert', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
