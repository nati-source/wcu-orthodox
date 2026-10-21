part of '../admin_approvals_screen.dart';

extension ApprovalsRolesTabExt on _AdminApprovalsScreenState {
  Widget _buildRoleAssignmentsTab(BuildContext context, List<UserModel> allStudents) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    // Filter by Role
    var filtered = allStudents.where((s) {
      if (_roleFilter == 'All') return true;
      return s.role.name == _roleFilter;
    }).toList();

    // Filter by Search query
    if (_roleSearchQuery.trim().isNotEmpty) {
      final q = _roleSearchQuery.trim().toLowerCase();
      filtered = filtered.where((s) {
        final matchesName = s.fullName.toLowerCase().contains(q);
        final matchesBaptismal = s.baptismalName.toLowerCase().contains(q);
        final matchesDept = s.department.toLowerCase().contains(q);
        final matchesPhone = s.phoneNumber.toLowerCase().contains(q);
        final matchesBatch = s.batchYear.toLowerCase().contains(q);
        final matchesRole = s.role.displayName.toLowerCase().contains(q);
        final matchesMinistry = s.ministryStatus.toLowerCase().contains(q);
        return matchesName || matchesBaptismal || matchesDept || matchesPhone || matchesBatch || matchesRole || matchesMinistry;
      }).toList();
    }

    final studentCount = allStudents.where((s) => s.role == UserRole.student).length;
    final coordCount = allStudents.where((s) => s.role == UserRole.volunteerCoordinator).length;
    final parentCount = allStudents.where((s) => s.role == UserRole.spiritualParent).length;
    final adminCount = allStudents.where((s) => s.role == UserRole.admin).length;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Header Overview Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryAccent.withOpacity(0.16),
                cardBg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryAccent.withOpacity(0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.manage_accounts_outlined, color: primaryAccent, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Role & Privileges Assignment',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textCol,
                          ),
                        ),
                        Text(
                          'የአባላትና የአገልጋዮች የኃላፊነት ምደባ',
                          style: TextStyle(fontSize: 11, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${allStudents.length} Students',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Assign leadership privileges, volunteer coordinators, spiritual parents, or administrators to registered students.',
                style: TextStyle(fontSize: 12, color: textMuted, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Search Bar with Clear Button
        TextField(
          onChanged: (val) => _updateUi(() => _roleSearchQuery = val),
          decoration: InputDecoration(
            hintText: 'Search by student name, baptismal name, dept, year, phone...',
            hintStyle: TextStyle(fontSize: 12, color: textMuted),
            prefixIcon: Icon(Icons.search, size: 20, color: primaryAccent),
            suffixIcon: _roleSearchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => _updateUi(() => _roleSearchQuery = ''),
                    tooltip: 'Clear search',
                  )
                : null,
            filled: true,
            fillColor: elevatedBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: primaryAccent, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Role Filter ChoiceChips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildRoleFilterChip('All', 'All (${allStudents.length})'),
              _buildRoleFilterChip(UserRole.student.name, 'Students ($studentCount)', badgeColor: UserRole.student.badgeColor),
              _buildRoleFilterChip(UserRole.volunteerCoordinator.name, 'Coordinators ($coordCount)', badgeColor: UserRole.volunteerCoordinator.badgeColor),
              _buildRoleFilterChip(UserRole.spiritualParent.name, 'Spiritual Parents ($parentCount)', badgeColor: UserRole.spiritualParent.badgeColor),
              _buildRoleFilterChip(UserRole.admin.name, 'Admins ($adminCount)', badgeColor: UserRole.admin.badgeColor),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Section Title & Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STUDENT DIRECTORY (${filtered.length})',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: primaryAccent,
              ),
            ),
            if (filtered.length != allStudents.length)
              Text(
                'Showing ${filtered.length} of ${allStudents.length}',
                style: TextStyle(fontSize: 11, color: textMuted, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.person_search_outlined, size: 44, color: textMuted.withOpacity(0.5)),
                  const SizedBox(height: 12),
                  Text(
                    _roleSearchQuery.isNotEmpty
                        ? 'No students found matching "$_roleSearchQuery"'
                        : 'No students found in this role filter.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Try searching with another keyword or resetting active filters.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                  if (_roleSearchQuery.isNotEmpty || _roleFilter != 'All') ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () {
                        _updateUi(() {
                          _roleSearchQuery = '';
                          _roleFilter = 'All';
                        });
                      },
                      icon: const Icon(Icons.refresh, size: 15),
                      label: const Text('Reset Search & Filters', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryAccent,
                        side: BorderSide(color: primaryAccent.withOpacity(0.6)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          ...filtered.map((student) => _buildStudentRoleCard(context, state, student)),
      ],
    );
  }

  Widget _buildRoleFilterChip(String filterKey, String label, {Color? badgeColor}) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isSelected = _roleFilter == filterKey;
    final color = badgeColor ?? primaryAccent;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _updateUi(() => _roleFilter = filterKey);
          }
        },
        selectedColor: color.withOpacity(0.2),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? color : theme.colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? color : theme.dividerColor),
        ),
      ),
    );
  }

  Widget _buildStudentRoleCard(BuildContext context, FellowshipState state, UserModel student) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final roleColor = student.role.badgeColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.dark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: elevatedBg,
                child: Text(
                  student.fullName.isNotEmpty ? student.fullName[0] : 'S',
                  style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.fullName,
                            style: TextStyle(fontWeight: FontWeight.bold, color: textCol, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: roleColor.withOpacity(0.35)),
                          ),
                          child: Text(
                            student.role.displayName.split(' ').first,
                            style: TextStyle(fontSize: 10, color: roleColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    if (student.baptismalName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'የክርስትና ስም: ${student.baptismalName}',
                        style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      '${student.department} • Year ${student.academicYear} (${student.batchYear})',
                      style: TextStyle(fontSize: 11, color: textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (student.phoneNumber.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Phone: ${student.phoneNumber}',
                        style: TextStyle(fontSize: 10, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
          // Coordinator Scope Display & Legacy Migration Alert
          if (student.role == UserRole.volunteerCoordinator) ...[
            const SizedBox(height: 8),
            () {
              final deptId = student.coordinatorProfile?.departmentId;
              final isAudit = FellowshipDepartmentConstants.isAuditScope(deptId) || student.coordinatorProfile?.isReadOnlyAudit == true;
              final isLegacy = FellowshipDepartmentConstants.isLegacyCombinedMusicScope(deptId);
              final isUnassigned = deptId == null || deptId.trim().isEmpty;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isUnassigned
                          ? const Color(0xFFEF4444).withOpacity(0.12)
                          : isAudit
                              ? const Color(0xFFF5A65E).withOpacity(0.12)
                              : primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isUnassigned
                            ? const Color(0xFFEF4444).withOpacity(0.4)
                            : isAudit
                                ? const Color(0xFFF5A65E).withOpacity(0.35)
                                : primaryAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isUnassigned
                              ? Icons.assignment_late_outlined
                              : isAudit
                                  ? Icons.lock_outline
                                  : Icons.badge_outlined,
                          size: 14,
                          color: isUnassigned
                              ? const Color(0xFFEF4444)
                              : isAudit
                                  ? const Color(0xFFF5A65E)
                                  : primaryAccent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            FellowshipDepartmentConstants.formatCoordinatorScope(deptId),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isUnassigned
                                  ? const Color(0xFFEF4444)
                                  : isAudit
                                      ? const Color(0xFFF5A65E)
                                      : primaryAccent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isAudit)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5A65E).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Read-Only Audit', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E))),
                          ),
                        if (isUnassigned)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Action Required', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                          ),
                      ],
                    ),
                  ),

                  // Unassigned Scope Warning Banner
                  if (isUnassigned) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.assignment_late_outlined, size: 16, color: Color(0xFFDC2626)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Unassigned Coordinator Scope / ምድብ ያልተሰጠው አስተባባሪ',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Coordinator has no department scope assigned. Action required to assign department scope.',
                            style: TextStyle(fontSize: 10, color: textMuted),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _showCoordinatorScopeDialog(context, state, student),
                              icon: const Icon(Icons.add_task_outlined, size: 13, color: Colors.white),
                              label: const Text('Assign Scope / ምድብ መድብ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Ambiguous Legacy Warning Banner
                  if (isLegacy) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFF59E0B)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Ambiguous Legacy Assignment (Music & Sacred Arts)',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Mezmur/Choir and Sacred Arts are now distinct departments with separate tools. Action required to migrate.',
                            style: TextStyle(fontSize: 10, color: textMuted),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton.icon(
                              onPressed: () => _showCoordinatorScopeDialog(context, state, student, isMigration: true),
                              icon: const Icon(Icons.merge_type, size: 13, color: Colors.white),
                              label: const Text('Migrate Scope / ምድብ ቀይር', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD97706),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            }(),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
          const SizedBox(height: 8),

          // Role Selector Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_outlined, size: 14, color: textMuted),
                  const SizedBox(width: 4),
                  Text('Assign Role:', style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: elevatedBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<UserRole>(
                    value: student.role,
                    isDense: true,
                    dropdownColor: cardBg,
                    icon: Icon(Icons.arrow_drop_down, color: primaryAccent, size: 18),
                    items: UserRole.values.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: r.badgeColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              r.displayName,
                              style: TextStyle(fontSize: 11, color: r.badgeColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newRole) async {
                      if (newRole != null && newRole != student.role) {
                        HapticFeedback.selectionClick();
                        if (newRole == UserRole.volunteerCoordinator) {
                          _showCoordinatorScopeDialog(context, state, student);
                        } else {
                          final assigned = await state.assignUserRole(student.id, newRole);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(assigned
                                  ? 'Updated ${student.fullName} role to ${newRole.displayName}.'
                                  : 'Could not update ${student.fullName} role. Check the connection and try again.'),
                              backgroundColor: assigned ? newRole.badgeColor : AppTheme.crimson,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ),
            ],
          ),

          // Coordinator Action Controls (Change Scope / Revoke Access)
          if (student.role == UserRole.volunteerCoordinator) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _confirmRevokeCoordinatorDialog(context, state, student);
                  },
                  icon: const Icon(Icons.person_remove_outlined, size: 13),
                  label: const Text('Revoke Access', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.crimson,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    side: BorderSide(color: AppTheme.crimson.withOpacity(0.4)),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _showCoordinatorScopeDialog(context, state, student);
                  },
                  icon: Icon(
                    (student.coordinatorProfile?.departmentId == null || student.coordinatorProfile!.departmentId.isEmpty)
                        ? Icons.add_task_outlined
                        : Icons.edit_outlined,
                    size: 13,
                    color: Colors.white,
                  ),
                  label: Text(
                    (student.coordinatorProfile?.departmentId == null || student.coordinatorProfile!.departmentId.isEmpty)
                        ? 'Assign Scope'
                        : 'Change Scope',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (student.coordinatorProfile?.departmentId == null || student.coordinatorProfile!.departmentId.isEmpty)
                        ? const Color(0xFFDC2626)
                        : primaryAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // COORDINATOR SCOPE SELECTION & ASSIGNMENT DIALOG
  // ----------------------------------------------------
  void _showCoordinatorScopeDialog(
    BuildContext context,
    FellowshipState state,
    UserModel student, {
    bool isMigration = false,
  }) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final currentScope = student.coordinatorProfile?.departmentId;
    String selectedDeptId = (currentScope != null && !FellowshipDepartmentConstants.isLegacyCombinedMusicScope(currentScope))
        ? currentScope
        : FellowshipDepartmentConstants.deptEducation;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(isMigration ? Icons.merge_type_rounded : Icons.assignment_ind_outlined, color: primaryAccent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isMigration ? 'Migrate Coordinator Scope' : 'Assign Department Scope',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          student.fullName,
                          style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isMigration) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.35)),
                          ),
                          child: const Text(
                            'Legacy Assignment: This coordinator was assigned to the combined Music & Sacred Arts department. Please choose whether to assign them to Mezmur/Choir or Sacred Arts.',
                            style: TextStyle(fontSize: 11, color: Color(0xFFB45309), height: 1.3),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      Text(
                        'Select Department Scope / የክፍል ምድብ ይምረጡ:',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                      ),
                      const SizedBox(height: 10),

                      // Group 1: General Ministries
                      _buildScopeSectionHeader('General Fellowship Ministries / አጠቃላይ ክፍላት'),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptEducation, selectedDeptId, (v) => selectedDeptId = v),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptMemberCare, selectedDeptId, (v) => selectedDeptId = v),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptDevelopment, selectedDeptId, (v) => selectedDeptId = v),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptFinanceProperty, selectedDeptId, (v) => selectedDeptId = v),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptBatchPrograms, selectedDeptId, (v) => selectedDeptId = v),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptCharity, selectedDeptId, (v) => selectedDeptId = v),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptSpecialNeeds, selectedDeptId, (v) => selectedDeptId = v),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptPlanning, selectedDeptId, (v) => selectedDeptId = v),

                      const SizedBox(height: 12),
                      // Group 2: Music & Sacred Arts (Grouped together under one heading, but separate choices)
                      _buildScopeSectionHeader('Music & Sacred Arts / ዝማሬና ስነ ጥበባት', highlight: true),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptChoir, selectedDeptId, (v) => selectedDeptId = v),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptSacredArts, selectedDeptId, (v) => selectedDeptId = v),

                      const SizedBox(height: 12),
                      // Group 3: Inspection & Oversight
                      _buildScopeSectionHeader('Inspection & Oversight / ቁጥጥርና ኦዲት'),
                      _buildScopeRadioTile(dialogCtx, setDialogState, FellowshipDepartmentConstants.deptAudit, selectedDeptId, (v) => selectedDeptId = v, isAudit: true),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(ctx);
                    HapticFeedback.mediumImpact();
                    final assigned = await state.assignUserRole(
                      student.id,
                      UserRole.volunteerCoordinator,
                      departmentId: selectedDeptId,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(assigned
                            ? '${student.fullName} assigned to ${FellowshipDepartmentConstants.getNameAmharic(selectedDeptId)}.'
                            : 'Could not assign this coordinator. Check the connection and try again.'),
                        backgroundColor: assigned ? AppTheme.emerald : AppTheme.crimson,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
                  child: Text(
                    isMigration ? 'Complete Migration' : 'Save Scope',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildScopeSectionHeader(String title, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFF59E0B).withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: highlight ? const Color(0xFFD97706) : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildScopeRadioTile(
    BuildContext context,
    void Function(void Function()) setDialogState,
    String deptId,
    String selectedDeptId,
    void Function(String) onSelect, {
    bool isAudit = false,
  }) {
    final theme = Theme.of(context);
    final isSelected = selectedDeptId == deptId;
    final primaryAccent = theme.colorScheme.primary;

    return InkWell(
      onTap: () {
        setDialogState(() {
          onSelect(deptId);
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryAccent.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primaryAccent : theme.dividerColor.withOpacity(0.4),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 16,
              color: isSelected ? primaryAccent : theme.disabledColor,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    FellowshipDepartmentConstants.getNameAmharic(deptId),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? primaryAccent : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${FellowshipDepartmentConstants.getNameEn(deptId)} ${isAudit ? "[Read-Only]" : ""}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isAudit ? const Color(0xFFF5A65E) : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isAudit)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5A65E).withOpacity(0.14),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Read-Only', style: TextStyle(fontSize: 9, color: Color(0xFFF5A65E), fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  void _confirmRevokeCoordinatorDialog(
    BuildContext context,
    FellowshipState state,
    UserModel student,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Revoke Coordinator Access?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(
          'Are you sure you want to revoke volunteer coordinator privileges from ${student.fullName}? Their role will be reset to regular Student.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              HapticFeedback.mediumImpact();
              final revoked = await state.revokeCoordinatorAccess(student.id);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(revoked
                      ? 'Revoked coordinator access from ${student.fullName}. Role reset to Student.'
                      : 'Could not revoke coordinator access. Check the connection and try again.'),
                  backgroundColor: AppTheme.crimson,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
            child: const Text('Revoke Access', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 6: PRIESTS, VENUES & SCHEDULE MANAGEMENT
  // ----------------------------------------------------
}
