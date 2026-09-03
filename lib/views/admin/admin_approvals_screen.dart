import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
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

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBg,
        appBar: AppBar(
          title: const Text('Approvals & Coordinator Hub'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.goldAccent,
            labelColor: AppTheme.goldLight,
            unselectedLabelColor: AppTheme.textTertiary,
            tabs: [
              Tab(text: 'Students (${pendingStudents.length})'),
              Tab(text: '10 Dept Volunteers ($pendingVolunteerCount)'),
              Tab(text: 'Trip Payments (${pendingTrips.length})'),
              Tab(text: 'Emergency Aid (${aidRequests.length})'),
              const Tab(text: 'Role Assignments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Pending Student Registrations
            _buildStudentRegistrationsTab(context, pendingStudents),

            // Tab 2: 10 EOTC Department Coordinator Recruitment & Roster
            _buildDepartmentCoordinatorRecruitmentTab(context, state, volunteerApps),

            // Tab 3: Pilgrimage Telebirr & CBE Payment Verifications
            _buildTripPaymentsTab(context, pendingTrips),

            // Tab 4: Student Emergency Aid Requests Review
            _buildEmergencyAidTab(context, aidRequests),

            // Tab 5: Role Assignments
            _buildRoleAssignmentsTab(context, allStudents),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: STUDENT REGISTRATIONS
  // ----------------------------------------------------
  Widget _buildStudentRegistrationsTab(BuildContext context, List<UserModel> pending) {
    final state = widget.state;
    if (pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 48),
            SizedBox(height: 12),
            Text('No pending student verifications.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.borderMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppTheme.surfaceElevated,
                    child: Text(
                      student.fullName[0],
                      style: const TextStyle(color: AppTheme.goldLight, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.fullName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        Text(
                          'B.N. ${student.baptismalName} • Year ${student.academicYear}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFFF5A65E)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Department: ${student.department} • Batch ${student.batchYear}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              Text(
                'Phone: ${student.phoneNumber}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
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
                      state.approveStudent(student.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${student.fullName} verified & added to fellowship!'), backgroundColor: AppTheme.surfaceColor),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD4690B)),
                    child: const Text('Approve & Assign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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
    final ministries = state.ministries;
    final currentDept = _selectedCoordinatorDeptId != null
        ? ministries.firstWhere((m) => m.id == _selectedCoordinatorDeptId, orElse: () => ministries.first)
        : null;

    final members = state.getMembersForDepartment(_selectedCoordinatorDeptId);

    return Column(
      children: [
        // 1. Department Perspective Selector Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFF141C2A),
            border: Border(bottom: BorderSide(color: AppTheme.borderMuted)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFFF5A65E), size: 16),
                  SizedBox(width: 6),
                  Text(
                    'COORDINATOR DELEGATION PERSPECTIVE',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFF5A65E), letterSpacing: 1.2),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.goldAccent.withOpacity(0.4)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    value: _selectedCoordinatorDeptId,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceElevated,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          '🏛️ Executive View (All 10 Departments • ሁሉንም)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      ...ministries.map((m) {
                        return DropdownMenuItem<String?>(
                          value: m.id,
                          child: Text(
                            '👤 ${m.titleAmharic} (${m.teamLead})',
                            style: const TextStyle(fontSize: 12, color: Colors.white),
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

        // 2. Department Coordinator Status Banner
        if (currentDept != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF1B2433),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFF5A65E).withOpacity(0.2),
                  child: const Icon(Icons.person, size: 16, color: Color(0xFFF5A65E)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Coordinator: ${currentDept.teamLead} (${currentDept.coordinatorBaptismalName}) • ${currentDept.coordinatorPhone}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
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
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _volunteerSubTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _volunteerSubTab == 0 ? AppTheme.surfaceElevated : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: _volunteerSubTab == 0 ? Border.all(color: AppTheme.goldAccent.withOpacity(0.5)) : null,
                    ),
                    child: Center(
                      child: Text(
                        'Applicant Queue (${apps.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _volunteerSubTab == 0 ? FontWeight.bold : FontWeight.normal,
                          color: _volunteerSubTab == 0 ? AppTheme.goldLight : AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _volunteerSubTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: _volunteerSubTab == 1 ? AppTheme.surfaceElevated : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: _volunteerSubTab == 1 ? Border.all(color: AppTheme.goldAccent.withOpacity(0.5)) : null,
                    ),
                    child: Center(
                      child: Text(
                        'Active Servants Roster (${members.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: _volunteerSubTab == 1 ? FontWeight.bold : FontWeight.normal,
                          color: _volunteerSubTab == 1 ? AppTheme.goldLight : AppTheme.textSecondary,
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
              ? _buildApplicantQueueList(context, state, apps)
              : _buildActiveServantsRosterList(context, state, members),
        ),
      ],
    );
  }

  Widget _buildApplicantQueueList(
    BuildContext context,
    FellowshipState state,
    List<VolunteerApplicationModel> apps,
  ) {
    if (apps.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, color: AppTheme.textTertiary, size: 44),
            SizedBox(height: 10),
            Text('No volunteer applications in this queue.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: app.status == ApplicationStatus.approved
                  ? AppTheme.emerald
                  : app.status == ApplicationStatus.rejected
                      ? AppTheme.crimson
                      : const Color(0xFFF5A65E).withOpacity(0.6),
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
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${app.studentDept} • Batch: ${app.studentYear}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFF5A65E)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
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
                                : const Color(0xFFF5A65E),
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
                  color: const Color(0xFF121A26),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.hub_outlined, color: AppTheme.goldLight, size: 14),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${app.ministryAmharicTitle.isNotEmpty ? app.ministryAmharicTitle : app.ministryTitle} • ${app.preferredSubWing}',
                        style: const TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Reason
              Text(
                'Calling: "${app.reason}"',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 4),
              Text(
                'Experience: ${app.experience}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
              ),
              Text(
                'Availability: ${app.availability}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
              ),

              if (app.coordinatorNotes != null && app.coordinatorNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Note by ${app.reviewedByCoordinator}: ${app.coordinatorNotes}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.emerald, fontWeight: FontWeight.w600),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(color: AppTheme.borderMuted),
              const SizedBox(height: 6),

              // Actions: Quick Contact (Call / SMS) + Coordinator Decision
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone_outlined, color: AppTheme.goldLight, size: 18),
                    tooltip: 'Call Applicant',
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    padding: EdgeInsets.zero,
                    onPressed: () => state.launchCall(app.studentPhone),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sms_outlined, color: AppTheme.goldLight, size: 18),
                    tooltip: 'SMS Applicant',
                    constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
                    padding: EdgeInsets.zero,
                    onPressed: () => state.launchSms(
                      app.studentPhone,
                      body: 'Selam ${app.studentName}, this is regarding your application for ${app.ministryTitle}.',
                    ),
                  ),
                  const Spacer(),
                  if (isPending) ...[
                    OutlinedButton(
                      onPressed: () {
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
                        backgroundColor: const Color(0xFFF5A65E),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: const Text(
                        'Accept & Add to Roster',
                        style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
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
    if (members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, color: AppTheme.textTertiary, size: 44),
            SizedBox(height: 10),
            Text('No active servants listed for this department.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
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
                  mem.studentName[0],
                  style: const TextStyle(color: AppTheme.goldLight, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mem.studentName,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'B.N. ${mem.studentBaptismalName} • ${mem.studentDept} (${mem.studentYear})',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFF5A65E)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Role: ${mem.roleInDepartment} • Wing: ${mem.subWing}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.phone_outlined, color: AppTheme.goldLight, size: 18),
                onPressed: () => state.launchCall(mem.phoneNumber),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openApprovalDialog(
    BuildContext context,
    FellowshipState state,
    VolunteerApplicationModel app,
  ) {
    final noteController = TextEditingController(
      text: 'Welcome! You are approved for ${app.preferredSubWing}. Rehearsal briefing will follow.',
    );

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceElevated,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Accept ${app.studentName}', style: const TextStyle(color: Color(0xFFF5A65E), fontFamily: 'serif')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Assigning to ${app.ministryTitle} (${app.preferredSubWing}).', style: const TextStyle(fontSize: 12, color: Colors.white70)),
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
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                state.approveVolunteerApplication(
                  app.id,
                  notes: noteController.text.trim(),
                  reviewedBy: 'Department Coordinator',
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${app.studentName} added to active department roster!'),
                    backgroundColor: AppTheme.surfaceColor,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A65E)),
              child: const Text('Confirm & Onboard', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
    if (pending.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.done_all, color: AppTheme.emerald, size: 48),
            SizedBox(height: 12),
            Text('All pilgrimage payments verified.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF5A65E).withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    reg.tripTitle,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Text(
                    '${reg.feeAmount.toInt()} ETB',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Pilgrim: ${reg.studentName} (${reg.studentBaptismalName}) • ${reg.department}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Method: ${reg.paymentMethod.displayName}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF93C5FD), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Transaction Ref: ${reg.transactionReference}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
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
                      state.verifyTripPayment(reg.id, true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Payment verified & Boarding pass issued to ${reg.studentName}'), backgroundColor: AppTheme.surfaceColor),
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
    if (requests.isEmpty) {
      return const Center(
        child: Text('No emergency aid applications on file.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
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
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: req.status.color.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(req.category.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
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
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount Requested: ${req.amountRequested.toInt()} ETB',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E)),
              ),
              const SizedBox(height: 6),
              Text(
                req.description,
                style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.3),
              ),
              if (isUnderReview) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
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
                        state.updateAidRequestStatus(req.id, EmergencyAidStatus.disbursed, adminNote: 'Approved & Disbursed via Telebirr');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Aid marked approved & disbursed to ${req.studentName}'), backgroundColor: AppTheme.surfaceColor),
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
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: allStudents.length,
      itemBuilder: (ctx, index) {
        final student = allStudents[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
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
                  student.fullName[0],
                  style: const TextStyle(color: AppTheme.goldLight, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      student.department,
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<UserRole>(
                  value: student.role,
                  dropdownColor: AppTheme.surfaceColor,
                  icon: const Icon(Icons.arrow_drop_down, color: AppTheme.goldLight),
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
}
