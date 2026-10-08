part of '../admin_approvals_screen.dart';

extension ApprovalsRegistrationsTabExt on _AdminApprovalsScreenState {
  Widget _buildRegistrationsTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final pendingStudents = state.pendingApprovals;

    // Filter by Department
    var filtered = pendingStudents.where((s) {
      if (_registrationDeptFilter == 'All') return true;
      return s.department.toLowerCase() == _registrationDeptFilter.toLowerCase();
    }).toList();

    // Filter by Search query
    if (_registrationSearchQuery.trim().isNotEmpty) {
      final q = _registrationSearchQuery.trim().toLowerCase();
      filtered = filtered.where((s) {
        final matchesName = s.fullName.toLowerCase().contains(q);
        final matchesBaptismal = s.baptismalName.toLowerCase().contains(q);
        final matchesDept = s.department.toLowerCase().contains(q);
        final matchesPhone = s.phoneNumber.toLowerCase().contains(q);
        final matchesBatch = s.batchYear.toLowerCase().contains(q);
        final matchesId = s.id.toLowerCase().contains(q);
        return matchesName || matchesBaptismal || matchesDept || matchesPhone || matchesBatch || matchesId;
      }).toList();
    }

    // Extract all unique departments from pending students
    final availableDepts = <String>{'All'};
    for (final s in pendingStudents) {
      if (s.department.trim().isNotEmpty) {
        availableDepts.add(s.department.trim());
      }
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // 1. Header Overview & Summary Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.gold.withOpacity(0.18),
                cardBg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.gold, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Student Registrations • የአዲስ ተማሪዎች ምዝገባ',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textCol,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Review and verify newly registered university students. Approving grants immediate access to fellowship portals, smart family matching, and attendance tracking.',
                          style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderMuted, height: 1),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Badge count
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: pendingStudents.isNotEmpty
                          ? AppTheme.gold.withOpacity(0.18)
                          : AppTheme.emerald.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: pendingStudents.isNotEmpty
                            ? AppTheme.gold.withOpacity(0.6)
                            : AppTheme.emerald.withOpacity(0.6),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          pendingStudents.isNotEmpty ? Icons.hourglass_top_rounded : Icons.check_circle_outline,
                          size: 15,
                          color: pendingStudents.isNotEmpty ? AppTheme.gold : AppTheme.emerald,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            pendingStudents.isNotEmpty
                                ? '${pendingStudents.length} Awaiting Approval'
                                : 'All Reviewed (0 Pending)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: pendingStudents.isNotEmpty ? AppTheme.gold : AppTheme.emerald,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Bulk Action: Approve All
                  if (pendingStudents.isNotEmpty && state.canApproveGeneralStudents)
                    ElevatedButton.icon(
                      onPressed: () => _confirmApproveAll(context, state),
                      icon: const Icon(Icons.done_all_rounded, size: 16),
                      label: const Text('Approve All / ሁሉንም ተቀበል', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.emerald,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Search & Filter Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: elevatedBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.dividerColor),
          ),
          child: TextField(
            onChanged: (val) => setState(() => _registrationSearchQuery = val),
            style: TextStyle(fontSize: 13, color: textCol),
            decoration: InputDecoration(
              icon: Icon(Icons.search, color: textMuted, size: 20),
              hintText: 'Search by student name, Christian name, ID, phone...',
              hintStyle: TextStyle(fontSize: 13, color: textMuted),
              border: InputBorder.none,
              suffixIcon: _registrationSearchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _registrationSearchQuery = ''),
                    )
                  : null,
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Department Filter Chips (Horizontal Scroll)
        if (availableDepts.length > 2)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: availableDepts.map((dept) {
                final isSelected = _registrationDeptFilter.toLowerCase() == dept.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(
                      dept == 'All' ? 'All Departments' : dept,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? primaryAccent : textMuted,
                      ),
                    ),
                    backgroundColor: cardBg,
                    selectedColor: primaryAccent.withOpacity(0.18),
                    checkmarkColor: primaryAccent,
                    side: BorderSide(
                      color: isSelected ? primaryAccent : theme.dividerColor,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    onSelected: (selected) {
                      setState(() {
                        _registrationDeptFilter = selected ? dept : 'All';
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

        const SizedBox(height: 16),

        // 3. Students List or Empty State
        if (filtered.isEmpty)
          _buildEmptyRegistrationsState(context, pendingStudents.isEmpty)
        else
          ...filtered.map((student) => _buildRegistrationCard(context, state, student)),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // REGISTRATION CARD
  // --------------------------------------------------------------------------
  Widget _buildRegistrationCard(BuildContext context, FellowshipState state, UserModel student) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;

    final initial = student.fullName.trim().isNotEmpty
        ? student.fullName.trim()[0].toUpperCase()
        : 'S';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.gold.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header: Avatar, Names, Status Badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar with gold ring
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: AppTheme.goldGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF070F1E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Baptismal Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (student.baptismalName.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: AppTheme.gold, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Christian Name: ${student.baptismalName}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.gold,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${student.id}',
                        style: TextStyle(fontSize: 10, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Pending Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Awaiting Review',
                        style: TextStyle(
                          color: Color(0xFFF59E0B),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(color: AppTheme.borderMuted, height: 1),

          // Details Grid: Dept, Year, Batch, Phone, Gender
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _buildRegistrationDetailItem(
                  icon: Icons.school_outlined,
                  label: 'Department',
                  value: student.department.isNotEmpty ? student.department : 'General',
                  textCol: textCol,
                  textMuted: textMuted,
                  accentColor: primaryAccent,
                ),
                _buildRegistrationDetailItem(
                  icon: Icons.timeline_outlined,
                  label: 'Academic Year',
                  value: 'Year ${student.academicYear}',
                  textCol: textCol,
                  textMuted: textMuted,
                  accentColor: primaryAccent,
                ),
                _buildRegistrationDetailItem(
                  icon: Icons.calendar_today_outlined,
                  label: 'Batch',
                  value: 'Class of ${student.batchYear}',
                  textCol: textCol,
                  textMuted: textMuted,
                  accentColor: primaryAccent,
                ),
                _buildRegistrationDetailItem(
                  icon: student.isFemale ? Icons.female : Icons.male,
                  label: 'Gender',
                  value: student.isFemale ? 'Female / እህት' : 'Male / ወንድም',
                  textCol: textCol,
                  textMuted: textMuted,
                  accentColor: student.isFemale ? const Color(0xFFEC4899) : const Color(0xFF3B82F6),
                ),
                if (student.phoneNumber.isNotEmpty)
                  GestureDetector(
                    onTap: () => state.launchCall(student.phoneNumber),
                    child: _buildRegistrationDetailItem(
                      icon: Icons.phone_outlined,
                      label: 'Phone (Tap to Call)',
                      value: student.phoneNumber,
                      textCol: primaryAccent,
                      textMuted: textMuted,
                      accentColor: AppTheme.emerald,
                      isActionable: true,
                    ),
                  ),
              ],
            ),
          ),

          const Divider(color: AppTheme.borderMuted, height: 1),

          // Actions: Approve & Decline Buttons
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Row(
              children: [
                // Decline Button
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmDeclineStudent(context, state, student),
                    icon: const Icon(Icons.close_rounded, size: 16, color: AppTheme.crimson),
                    label: const Text(
                      'Decline / ውድቅ አድርግ',
                      style: TextStyle(
                        color: AppTheme.crimson,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: AppTheme.crimson.withOpacity(0.6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Approve Button
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _openApprovalDialog(context, state, student),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text(
                      'Approve / ተቀበል',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.emerald,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Widget _buildRegistrationDetailItem({
    required IconData icon,
    required String label,
    required String value,
    required Color textCol,
    required Color textMuted,
    required Color accentColor,
    bool isActionable = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: accentColor),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: textMuted)),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textCol,
                decoration: isActionable ? TextDecoration.underline : TextDecoration.none,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // EMPTY STATE
  // --------------------------------------------------------------------------
  Widget _buildEmptyRegistrationsState(BuildContext context, bool isCompletelyEmpty) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: AppTheme.emerald.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.emerald.withOpacity(0.35), width: 1.5),
            ),
            child: const Icon(
              Icons.how_to_reg_rounded,
              color: AppTheme.emerald,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isCompletelyEmpty
                ? 'All Caught Up! • ሁሉም ተስተናግዷል'
                : 'No Matching Registrations',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textCol,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isCompletelyEmpty
                ? 'There are no pending student applications in the queue. All registered students have been reviewed and approved.'
                : 'No registration requests found matching your search or department filter.',
            style: TextStyle(fontSize: 13, color: textMuted, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // APPROVAL DIALOG (WITH ROLE SELECTION)
  // --------------------------------------------------------------------------
  void _openApprovalDialog(BuildContext context, FellowshipState state, UserModel student) {
    UserRole selectedRole = UserRole.student;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final theme = Theme.of(context);
          final textCol = theme.colorScheme.onSurface;

          return AlertDialog(
            backgroundColor: AppTheme.surfaceElevated,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: AppTheme.gold.withOpacity(0.5), width: 1.5),
            ),
            title: Row(
              children: [
                const Icon(Icons.verified_user_rounded, color: AppTheme.emerald, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Approve Registration',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                    ),
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
                    'Confirm approval for ${student.fullName}:',
                    style: TextStyle(fontSize: 13, color: textCol),
                  ),
                  if (student.baptismalName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Christian Name: ${student.baptismalName}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.gold, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Text(
                    'Assign Primary Role:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 8),

                  // Option 1: Student
                  _buildRoleRadioTile(
                    title: 'Student / አባል ተማሪ',
                    subtitle: 'Standard member with access to services, roadmaps & family',
                    role: UserRole.student,
                    selectedRole: selectedRole,
                    color: AppTheme.emerald,
                    onSelected: (r) => setDialogState(() => selectedRole = r),
                  ),

                  // Option 2: Spiritual Parent
                  _buildRoleRadioTile(
                    title: 'Spiritual Parent / የንስሐ ወላጅ',
                    subtitle: 'Mentors assigned students and guides family units',
                    role: UserRole.spiritualParent,
                    selectedRole: selectedRole,
                    color: const Color(0xFFF59E0B),
                    onSelected: (r) => setDialogState(() => selectedRole = r),
                  ),

                  // Option 3: Volunteer Coordinator
                  _buildRoleRadioTile(
                    title: 'Coordinator / አስተባባሪ',
                    subtitle: 'Coordinates fellowship departments and services',
                    role: UserRole.volunteerCoordinator,
                    selectedRole: selectedRole,
                    color: const Color(0xFF3B82F6),
                    onSelected: (r) => setDialogState(() => selectedRole = r),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: AppTheme.slateMuted)),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  state.approveStudent(student.id, role: selectedRole);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${student.fullName} approved as ${selectedRole.displayName}!',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppTheme.emerald,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Confirm & Allow Access'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.emerald,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRoleRadioTile({
    required String title,
    required String subtitle,
    required UserRole role,
    required UserRole selectedRole,
    required Color color,
    required ValueChanged<UserRole> onSelected,
  }) {
    final isSelected = role == selectedRole;
    return GestureDetector(
      onTap: () => onSelected(role),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.12) : AppTheme.primaryBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppTheme.borderMuted,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? color : AppTheme.slateMuted,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CONFIRM DECLINE
  // --------------------------------------------------------------------------
  void _confirmDeclineStudent(BuildContext context, FellowshipState state, UserModel student) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.crimson.withOpacity(0.5), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.crimson, size: 24),
            SizedBox(width: 10),
            Text(
              'Decline Registration?',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.crimson,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to decline the registration application for "${student.fullName}"? This will remove them from the approval queue.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.slateMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              state.rejectStudent(student.id);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Registration for ${student.fullName} has been declined.'),
                  backgroundColor: AppTheme.crimson,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.crimson,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Decline / ውድቅ አድርግ'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // CONFIRM APPROVE ALL
  // --------------------------------------------------------------------------
  void _confirmApproveAll(BuildContext context, FellowshipState state) {
    final count = state.pendingApprovals.length;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppTheme.emerald.withOpacity(0.5), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.done_all_rounded, color: AppTheme.emerald, size: 24),
            SizedBox(width: 10),
            Text(
              'Approve All Registrations?',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppTheme.emerald,
              ),
            ),
          ],
        ),
        content: Text(
          'This will approve all $count pending students and immediately grant them access to the fellowship app.',
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.slateMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              state.approveAllPendingStudents();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All $count pending students approved successfully!'),
                  backgroundColor: AppTheme.emerald,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            },
            icon: const Icon(Icons.done_all, size: 18),
            label: Text('Approve All ($count)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.emerald,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
