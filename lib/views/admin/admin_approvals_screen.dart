import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminApprovalsScreen extends StatelessWidget {
  final FellowshipState state;

  const AdminApprovalsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pendingStudents = state.pendingApprovals;
    final allStudents = state.allStudents;
    final pendingTrips = state.allTripRegistrations
        .where((r) => r.paymentStatus == TripPaymentStatus.pendingVerification)
        .toList();
    final aidRequests = state.emergencyAidRequests;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBg,
        appBar: AppBar(
          title: const Text('Approvals & Verifications'),
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppTheme.goldAccent,
            labelColor: AppTheme.goldLight,
            unselectedLabelColor: AppTheme.textTertiary,
            tabs: [
              Tab(text: 'Students (${pendingStudents.length})'),
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

            // Tab 2: Pilgrimage Telebirr & CBE Payment Verifications
            _buildTripPaymentsTab(context, pendingTrips),

            // Tab 3: Student Emergency Aid Requests Review
            _buildEmergencyAidTab(context, aidRequests),

            // Tab 4: Role Assignments
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
  // TAB 2: PILGRIMAGE PAYMENTS (TELEBIRR & CBE)
  // ----------------------------------------------------
  Widget _buildTripPaymentsTab(BuildContext context, List<TripRegistrationModel> pending) {
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
  // TAB 3: EMERGENCY STUDENT AID
  // ----------------------------------------------------
  Widget _buildEmergencyAidTab(BuildContext context, List<EmergencyAidRequestModel> requests) {
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
  // TAB 4: ROLE ASSIGNMENTS
  // ----------------------------------------------------
  Widget _buildRoleAssignmentsTab(BuildContext context, List<UserModel> allStudents) {
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

