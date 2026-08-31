import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class AdminApprovalsScreen extends StatelessWidget {
  final FellowshipState state;

  const AdminApprovalsScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final pending = state.pendingApprovals;
    final allStudents = state.allStudents;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.primaryBg,
        appBar: AppBar(
          title: const Text('Approvals & Roles'),
          bottom: const TabBar(
            indicatorColor: AppTheme.goldAccent,
            labelColor: AppTheme.goldLight,
            unselectedLabelColor: AppTheme.textTertiary,
            tabs: [
              Tab(text: 'Pending Verifications'),
              Tab(text: 'Role Assignments'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Pending Student Verifications
            pending.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline, color: AppTheme.emerald, size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No pending student verifications.',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
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
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
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
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  ),
                                  child: const Text('Reject', style: TextStyle(fontSize: 12)),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton(
                                  onPressed: () {
                                    state.approveStudent(student.id);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('${student.fullName} verified & added to fellowship!'),
                                        backgroundColor: AppTheme.surfaceColor,
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD4690B),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  child: const Text('Approve & Assign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),

            // Tab 2: Role Assignments
            ListView.builder(
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
            ),
          ],
        ),
      ),
    );
  }
}
