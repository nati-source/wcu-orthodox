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
                    onChanged: (newRole) {
                      if (newRole != null && newRole != student.role) {
                        HapticFeedback.selectionClick();
                        state.assignUserRole(student.id, newRole);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Updated ${student.fullName} role to ${newRole.displayName}'),
                            backgroundColor: newRole.badgeColor,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 6: PRIESTS, VENUES & SCHEDULE MANAGEMENT
  // ----------------------------------------------------
}
