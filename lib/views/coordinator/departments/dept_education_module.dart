part of '../coordinator_hub_screen.dart';

extension DeptEducationModuleExt on _CoordinatorHubScreenState {
  Widget _buildEducationModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final allDeptBroadcasts = state.getBroadcastsForDepartment(FellowshipDepartmentConstants.deptEducation);

    // Filter by Category
    var filtered = allDeptBroadcasts.where((b) {
      if (_educationCategoryFilter == 'All') return true;
      if (_educationCategoryFilter == 'Course Info') return b.broadcastCategory == 'courseInfo';
      if (_educationCategoryFilter == 'Special Program') return b.broadcastCategory == 'specialProgram' || b.isSpecialTeacherNotice;
      if (_educationCategoryFilter == 'Urgent Alert') return b.urgency == 'urgent' || b.broadcastCategory == 'urgentAlert';
      return true;
    }).toList();

    // Filter by Target Batch
    if (_educationBatchFilter != 'All') {
      filtered = filtered.where((b) => b.targetBatch == _educationBatchFilter).toList();
    }

    final totalCount = allDeptBroadcasts.length;
    final courseUpdatesCount = allDeptBroadcasts.where((b) => b.broadcastCategory == 'courseInfo').length;
    final specialProgramsCount = allDeptBroadcasts.where((b) => b.broadcastCategory == 'specialProgram' || b.isSpecialTeacherNotice).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Education Hub Overview & Metrics Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryAccent.withOpacity(0.18),
                cardBg,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryAccent.withOpacity(0.4)),
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
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.school, color: primaryAccent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Apostolic Education • ትምህርትና ሐዋርያዊ',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: textCol,
                              fontFamily: 'serif',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryAccent.withOpacity(0.3)),
                    ),
                    child: Text(
                      '$totalCount Broadcasts',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Broadcast syllabus & exam announcements targeted to all students or specific academic batches (Year 1 to Year 5), and coordinate upcoming special guest clergy lectures.',
                style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: elevatedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.menu_book, size: 14, color: AppTheme.gold),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Course Updates',
                                  style: TextStyle(fontSize: 10, color: textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$courseUpdatesCount Active',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: elevatedBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.campaign, size: 14, color: AppTheme.emerald),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Special Programs',
                                  style: TextStyle(fontSize: 10, color: textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$specialProgramsCount Scheduled',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Action Toolbar (Only if not read-only audit)
        if (!isAudit) ...[
          Text(
            'COORDINATOR DISPATCH ACTIONS • ማስተላለፊያ እርምጃዎች',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: primaryAccent,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: () => _showCreateEducationBroadcastDialog(context, state),
                icon: const Icon(Icons.send_rounded, size: 15),
                label: const Text(
                  'አዲስ ማስታወቂያ (Broadcast)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showScheduleChurchProgramDialog(context, state),
                icon: const Icon(Icons.timer_outlined, size: 15),
                label: const Text(
                  'ልዩ መርሐ ግብር (Program) • Countdown',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryAccent,
                  side: BorderSide(color: primaryAccent, width: 1.3),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _showCreateFaithChallengeDialog(context, state),
                icon: const Icon(Icons.quiz_outlined, size: 15),
                label: const Text(
                  '+ የዕውቀት ውድድር (Challenge)',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981), width: 1.3),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (state.triviaQuizzes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.quiz_outlined, size: 18, color: Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Published Faith Challenges • የዕውቀት ውድድሮች (${state.triviaQuizzes.length})',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...state.triviaQuizzes.map((quiz) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: elevatedBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Wk ${quiz.weekNumber}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              quiz.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textCol),
                            ),
                          ),
                          Text(
                            '${quiz.questions.length} Qs',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                            visualDensity: VisualDensity.compact,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: const Text('Delete Faith Challenge?'),
                                  content: Text('Delete "${quiz.title}" from database?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await state.deleteTriviaQuiz(quiz.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faith Challenge deleted.')));
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],
        ],

        // 3. Interactive Category Filter Chips & Target Batch Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'DEPARTMENT BROADCASTS FEED (${filtered.length})',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: primaryAccent,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            // Batch Dropdown Filter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: elevatedBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: theme.dividerColor),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _educationBatchFilter,
                  isDense: true,
                  icon: Icon(Icons.filter_list, size: 16, color: primaryAccent),
                  style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w600),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Batches (ሁሉም)')),
                    DropdownMenuItem(value: '1', child: Text('Year 1 (1ኛ ዓመት)')),
                    DropdownMenuItem(value: '2', child: Text('Year 2 (2ኛ ዓመት)')),
                    DropdownMenuItem(value: '3', child: Text('Year 3 (3ኛ ዓመት)')),
                    DropdownMenuItem(value: '4', child: Text('Year 4 (4ኛ ዓመት)')),
                    DropdownMenuItem(value: '5', child: Text('Year 5 (5ኛ ዓመት)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      _updateUi(() => _educationBatchFilter = val);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Category Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildEducationCategoryPill('All', 'All (ሁሉም)'),
              _buildEducationCategoryPill('Course Info', 'Course Info (የትምህርት)'),
              _buildEducationCategoryPill('Special Program', 'Special Program (ልዩ መርሐ ግብር)'),
              _buildEducationCategoryPill('Urgent Alert', 'Urgent (አስቸኳይ)'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Broadcast Feed Items
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.campaign_outlined, size: 40, color: textMuted.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Text(
                    'No broadcasts match this filter.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Try changing category or batch filters, or create a new broadcast announcement.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          ...filtered.map((b) => _buildEducationBroadcastCard(context, state, b, isAudit)),
      ],
    );
  }

  Widget _buildEducationCategoryPill(String filterKey, String label) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isSelected = _educationCategoryFilter == filterKey;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _updateUi(() => _educationCategoryFilter = filterKey);
          }
        },
        selectedColor: primaryAccent.withOpacity(0.2),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? primaryAccent : (theme.colorScheme.onSurface),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? primaryAccent : theme.dividerColor),
        ),
      ),
    );
  }

  Widget _buildEducationBroadcastCard(
    BuildContext context,
    FellowshipState state,
    DepartmentBroadcastMessageModel broadcast,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final isSpecial = broadcast.broadcastCategory == 'specialProgram' || broadcast.isSpecialTeacherNotice;
    final isUrgent = broadcast.urgency == 'urgent';

    // Target Audience Badge styling
    final isAllStudents = broadcast.targetBatch == 'all' || broadcast.targetBatch.isEmpty;
    final targetBadgeColor = isAllStudents ? AppTheme.gold : primaryAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUrgent
              ? AppTheme.crimson.withOpacity(0.6)
              : (isSpecial ? primaryAccent.withOpacity(0.5) : theme.dividerColor),
          width: isUrgent || isSpecial ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Target Batch Badge & Category Pill & Urgency
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Target Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: targetBadgeColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: targetBadgeColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isAllStudents ? Icons.groups : Icons.school,
                      size: 12,
                      color: targetBadgeColor,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        broadcast.targetAudienceLabel.isNotEmpty
                            ? broadcast.targetAudienceLabel
                            : (isAllStudents ? 'All Students' : 'Year ${broadcast.targetBatch} Batch'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: targetBadgeColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Category Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSpecial
                      ? primaryAccent.withOpacity(0.15)
                      : elevatedBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isSpecial
                      ? '🌟 Special'
                      : (broadcast.broadcastCategory == 'courseInfo'
                          ? '📖 Course'
                          : '📢 Notice'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSpecial ? primaryAccent : textMuted,
                  ),
                ),
              ),
              if (isUrgent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.crimson.withOpacity(0.4)),
                  ),
                  child: const Text(
                    'URGENT',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            broadcast.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textCol,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),

          // Speaker / Guest Clergy (if present)
          if (broadcast.instructorOrSpeaker != null && broadcast.instructorOrSpeaker!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: elevatedBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.person_pin, size: 16, color: primaryAccent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'መምህር / ተጋባዥ: ${broadcast.instructorOrSpeaker}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textCol),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Venue & Meeting Time (if present)
          if (broadcast.meetingLocation != null || broadcast.meetingTime != null || (broadcast.courseCode != null && broadcast.courseCode!.isNotEmpty)) ...[
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (broadcast.meetingLocation != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.place, size: 12, color: primaryAccent),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            broadcast.meetingLocation!,
                            style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (broadcast.meetingTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: elevatedBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, size: 12, color: textMuted),
                        const SizedBox(width: 4),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(
                            '${broadcast.meetingTime!.day}/${broadcast.meetingTime!.month}/${broadcast.meetingTime!.year} at ${broadcast.meetingTime!.hour}:${broadcast.meetingTime!.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(fontSize: 11, color: textCol, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (broadcast.courseCode != null && broadcast.courseCode!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tag, size: 12, color: AppTheme.gold),
                        const SizedBox(width: 2),
                        Text(
                          broadcast.courseCode!,
                          style: const TextStyle(fontSize: 11, color: AppTheme.gold, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Body Text
          Text(
            broadcast.body,
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
          const SizedBox(height: 8),

          // Footer: Sender & Relative Date & Delete Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.account_circle, size: 14, color: textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${broadcast.senderName} (${broadcast.senderRole})',
                        style: TextStyle(fontSize: 10, color: textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${broadcast.sentAt.day}/${broadcast.sentAt.month} ${broadcast.sentAt.hour}:${broadcast.sentAt.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                  if (!isAudit) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.crimson),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Delete Broadcast',
                      onPressed: () {
                        state.deleteDepartmentBroadcast(broadcast.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Broadcast announcement removed.')),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateEducationBroadcastDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    String selectedBatch = 'all';
    String selectedCategory = 'courseInfo';
    String selectedUrgency = 'normal';
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final courseCodeController = TextEditingController();
    final instructorController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.campaign, color: primaryAccent, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'New Education Broadcast • አዲስ ማስታወቂያ',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Target Audience Dropdown
                    Text('TARGET AUDIENCE / BATCH • ተደራሽ ባች', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBatch,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Students (ሁሉንም ተማሪዎች)')),
                            DropdownMenuItem(value: '1', child: Text('Year 1 - Freshmen (1ኛ ዓመት)')),
                            DropdownMenuItem(value: '2', child: Text('Year 2 Batch (2ኛ ዓመት)')),
                            DropdownMenuItem(value: '3', child: Text('Year 3 Batch (3ኛ ዓመት)')),
                            DropdownMenuItem(value: '4', child: Text('Year 4 Batch (4ኛ ዓመት)')),
                            DropdownMenuItem(value: '5', child: Text('Year 5 - Graduating (5ኛ ዓመት)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedBatch = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Selector
                    Text('BROADCAST CATEGORY • የመልዕክት ዓይነት', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'courseInfo', child: Text('📖 Course Info & Syllabus (የትምህርት መረጃ)')),
                            DropdownMenuItem(value: 'generalNotice', child: Text('📢 General Notice (አጠቃላይ ማስታወቂያ)')),
                            DropdownMenuItem(value: 'urgentAlert', child: Text('🚨 Urgent Alert / Exam Update (አስቸኳይ ማሳሰቢያ)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional Course Code & Instructor
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: courseCodeController,
                            decoration: InputDecoration(
                              labelText: 'Course Code (Optional)',
                              hintText: 'e.g. PATR-201',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: instructorController,
                            decoration: InputDecoration(
                              labelText: 'Instructor / Teacher',
                              hintText: 'e.g. መምህር ዮሐንስ',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Broadcast Title • የርዕስ ስም',
                        hintText: 'e.g. የ2ኛ ዓመት የሃይማኖተ አበው ፈተና ማሳሰቢያ',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Body
                    TextField(
                      controller: bodyController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Detailed Message • ዝርዝር መረጃ',
                        hintText: 'የፈተናውን ሰዓት፣ ክፍል እና አስፈላጊ መመሪያዎችን እዚህ ይጻፉ...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Send Button
                    ElevatedButton.icon(
                      onPressed: () {
                        final title = titleController.text.trim();
                        final body = bodyController.text.trim();
                        if (title.isEmpty || body.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter both title and message content.')),
                          );
                          return;
                        }

                        final audienceLabel = selectedBatch == 'all'
                            ? 'All Students (ሁሉንም ተማሪዎች)'
                            : 'Year $selectedBatch Batch ($selectedBatchኛ ዓመት ባች)';

                        state.sendDepartmentBroadcast(
                          departmentId: FellowshipDepartmentConstants.deptEducation,
                          title: title,
                          body: body,
                          urgency: selectedCategory == 'urgentAlert' ? 'urgent' : selectedUrgency,
                          targetBatch: selectedBatch,
                          targetAudienceLabel: audienceLabel,
                          broadcastCategory: selectedCategory,
                          courseCode: courseCodeController.text.trim().isNotEmpty ? courseCodeController.text.trim() : null,
                          instructorOrSpeaker: instructorController.text.trim().isNotEmpty ? instructorController.text.trim() : null,
                        );

                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Broadcast sent successfully to $audienceLabel!')),
                        );
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Flexible(child: Text('Dispatch Broadcast • አስተላልፍ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showScheduleGuestTeacherDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    final teacherNameController = TextEditingController(text: 'ዶ/ር ሮዳስ ታደሰ');
    final teacherTitleController = TextEditingController(text: 'መጋቤ ሐዲስ');
    final topicController = TextEditingController(text: 'የስነ ፍጥረት ምስጢርና የነገረ መለኮት ጥናት');
    final venueController = TextEditingController(text: 'WCU Main Auditorium Hall A');
    final descController = TextEditingController();
    String selectedBatch = 'all';
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 3, hours: 4));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 18,
                bottom: MediaQuery.of(dialogCtx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.event_available, color: primaryAccent, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Schedule Special Program • ልዩ መርሐ ግብር',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Teacher Title & Name
                    Row(
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: teacherTitleController,
                            decoration: InputDecoration(
                              labelText: 'Title / ማዕረግ',
                              hintText: 'መጋቤ ሐዲስ',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: teacherNameController,
                            decoration: InputDecoration(
                              labelText: 'Speaker Name • ስም',
                              hintText: 'ዶ/ር ሮዳስ ታደሰ',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Topic
                    TextField(
                      controller: topicController,
                      decoration: InputDecoration(
                        labelText: 'Topic / Sermon Theme • የትምህርቱ ርዕስ',
                        hintText: 'የስነ ፍጥረት ምስጢር',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Venue
                    TextField(
                      controller: venueController,
                      decoration: InputDecoration(
                        labelText: 'Venue / Location • የመሰብሰቢያ አዳራሽ',
                        hintText: 'WCU Main Auditorium Hall A',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Target Batch
                    Text('TARGET AUDIENCE • ተጋባዥ ተማሪዎች', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedBatch,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'all', child: Text('All Campus Students (ሁሉንም ተማሪዎች)')),
                            DropdownMenuItem(value: '1', child: Text('Year 1 - Freshmen (1ኛ ዓመት)')),
                            DropdownMenuItem(value: '2', child: Text('Year 2 Batch (2ኛ ዓመት)')),
                            DropdownMenuItem(value: '3', child: Text('Year 3 Batch (3ኛ ዓመት)')),
                            DropdownMenuItem(value: '4', child: Text('Year 4 Batch (4ኛ ዓመት)')),
                            DropdownMenuItem(value: '5', child: Text('Year 5 - Graduating (5ኛ ዓመት)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedBatch = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Additional Notes
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Additional Instructions (Optional)',
                        hintText: 'ማስታወሻ ደብተር ይዛችሁ እንድትገኙ...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Schedule Button
                    ElevatedButton.icon(
                      onPressed: () {
                        final teacherName = teacherNameController.text.trim();
                        final teacherTitle = teacherTitleController.text.trim();
                        final topic = topicController.text.trim();
                        final venue = venueController.text.trim();

                        if (teacherName.isEmpty || topic.isEmpty || venue.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill all required speaker, topic and venue fields.')),
                          );
                          return;
                        }

                        final audienceLabel = selectedBatch == 'all'
                            ? 'All Students (ሁሉንም ተማሪዎች)'
                            : 'Year $selectedBatch Batch ($selectedBatchኛ ዓመት ባች)';

                        state.publishSpecialGuestTeacherNotice(
                          teacherName: teacherName,
                          teacherTitle: teacherTitle,
                          topic: topic,
                          venue: venue,
                          dateAndTime: selectedDateTime,
                          targetBatch: selectedBatch,
                          targetAudienceLabel: audienceLabel,
                          description: descController.text.trim().isNotEmpty ? descController.text.trim() : null,
                        );

                        Navigator.pop(dialogCtx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Special Program scheduled and broadcasted to $audienceLabel!')),
                        );
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Flexible(child: Text('Publish Special Program • ይፋ አድርግ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 4: ልማትና ገቢ አሰባሰብ (DEVELOPMENT & FUNDRAISING)
  // Dedicated to: Interactive Campaign Proposals Drafting, Admin Review Tracking, & Capital Goals
  // --------------------------------------------------------------------------

  void _showScheduleChurchProgramDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    final titleController = TextEditingController(text: 'Sunday Divine Liturgy • የሰንበት ቅዳሴ');
    final churchController = TextEditingController(text: "St. Mary's Orthodox Church • ደብረ ምሕረት ቅድስት ማርያም");
    final descController = TextEditingController(text: 'Canonical Divine Liturgy and Holy Eucharist service.');
    String selectedCategory = 'Liturgy';
    DateTime selectedDateTime = DateTime.now().add(const Duration(days: 1, hours: 2));

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final formattedDate =
                '${selectedDateTime.year}-${selectedDateTime.month.toString().padLeft(2, '0')}-${selectedDateTime.day.toString().padLeft(2, '0')}  ${selectedDateTime.hour.toString().padLeft(2, '0')}:${selectedDateTime.minute.toString().padLeft(2, '0')}';

            return Dialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.timer_outlined, color: primaryAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Schedule Program & Countdown',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'serif',
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'የቅዳሴና የመርሐ ግብር ቆጣሪ መመዝገቢያ',
                                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Program Title • የፕሮግራሙ ርዕስ',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: churchController,
                      decoration: InputDecoration(
                        labelText: 'Church Location • የቤተክርስቲያን ስም',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Program Category • የመርሐ ግብሩ ዓይነት',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Liturgy', child: Text('የቅዳሴ መርሐ ግብር (Divine Liturgy)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'Feast', child: Text('ንግሥ / ዓመታዊ በዓል (Feast Commemoration)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'Prayer Meeting', child: Text('የጸሎት ጉባኤ (Prayer Gathering)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'Bible Study', child: Text('የመጽሐፍ ቅዱስ ጥናት (Bible Study)', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),

                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final pickedDate = await showDatePicker(
                          context: ctx,
                          initialDate: selectedDateTime,
                          firstDate: DateTime.now().subtract(const Duration(days: 1)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (pickedDate != null && ctx.mounted) {
                          final pickedTime = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(selectedDateTime),
                          );
                          if (pickedTime != null) {
                            setDialogState(() {
                              selectedDateTime = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                pickedTime.hour,
                                pickedTime.minute,
                              );
                            });
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: primaryAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Target Date & Time • ቀን እና ሰዓት', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(formattedDate, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                                ],
                              ),
                            ),
                            Icon(Icons.edit_calendar, size: 16, color: primaryAccent),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Description & Reminders • ማብራሪያ',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 18),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final church = churchController.text.trim();
                        final desc = descController.text.trim();

                        if (title.isEmpty || church.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter program title and church location.')),
                          );
                          return;
                        }

                        await state.scheduleChurchProgram(
                          title: title,
                          churchName: church,
                          category: selectedCategory,
                          dateTime: selectedDateTime,
                          description: desc,
                        );

                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Liturgy countdown set to ${selectedDateTime.toString().substring(0, 16)}!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Flexible(child: Text('Publish Countdown • ሰዓቱን አስቀምጥና ጀምር', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateFaithChallengeDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = const Color(0xFF10B981);

    final weekNumController = TextEditingController(text: '1');
    final titleController = TextEditingController(text: 'Week 1: Orthodox Tradition & Sacraments • ምሥጢራተ ቤተክርስቲያን');
    final descController = TextEditingController(text: 'Test your understanding of church sacraments, sacred traditions, and holy scripture.');
    final questionAmController = TextEditingController();
    final questionEnController = TextEditingController();
    final optAController = TextEditingController();
    final optBController = TextEditingController();
    final optCController = TextEditingController();
    final optDController = TextEditingController();
    final explanationController = TextEditingController();
    final bibleRefController = TextEditingController();
    int correctIndex = 0;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.quiz_outlined, color: primaryAccent, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Create Weekly Faith Challenge',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'serif',
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'አዲስ የዕውቀት ውድድር ፈተና ማዘጋጃና ማሰራጫ',
                                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: TextField(
                            controller: weekNumController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Week # • ሳምንት',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: titleController,
                            decoration: InputDecoration(
                              labelText: 'Challenge Title • የውድድሩ ርዕስ',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Quiz Description • መግለጫ',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'QUESTION BUILDER • የጥያቄው ዝርዝር',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: questionAmController,
                      decoration: InputDecoration(
                        labelText: 'Question in Amharic (በአማርኛ) *',
                        hintText: 'ለምሳሌ፡ ሰባቱ ምሥጢራተ ቤተክርስቲያን እነማን ናቸው?',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: questionEnController,
                      decoration: InputDecoration(
                        labelText: 'Question in English (Optional • በእንግሊዝኛ)',
                        hintText: 'e.g. Which sacrament is the foundation of Christian life?',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Text(
                      'OPTIONS & CORRECT ANSWER • ምርጫዎች እና ትክክለኛ መልስ',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
                    ),
                    const SizedBox(height: 6),

                    _buildOptionField('A', optAController, correctIndex == 0, () => setDialogState(() => correctIndex = 0), theme),
                    const SizedBox(height: 6),
                    _buildOptionField('B', optBController, correctIndex == 1, () => setDialogState(() => correctIndex = 1), theme),
                    const SizedBox(height: 6),
                    _buildOptionField('C', optCController, correctIndex == 2, () => setDialogState(() => correctIndex = 2), theme),
                    const SizedBox(height: 6),
                    _buildOptionField('D', optDController, correctIndex == 3, () => setDialogState(() => correctIndex = 3), theme),
                    const SizedBox(height: 12),

                    TextField(
                      controller: explanationController,
                      decoration: InputDecoration(
                        labelText: 'Explanation / ማብራሪያ (Optional)',
                        hintText: 'የመልሱ ማብራሪያ ወይም የነገረ መለኮት ትምህርት...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextField(
                      controller: bibleRefController,
                      decoration: InputDecoration(
                        labelText: 'Scripture Reference / ጥቅስ (e.g. ዮሐ 10፥30)',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 18),

                    ElevatedButton.icon(
                      onPressed: () async {
                        final title = titleController.text.trim();
                        final qAm = questionAmController.text.trim();
                        final qEn = questionEnController.text.trim();
                        final optA = optAController.text.trim();
                        final optB = optBController.text.trim();
                        final optC = optCController.text.trim();
                        final optD = optDController.text.trim();

                        if (title.isEmpty || qAm.isEmpty || optA.isEmpty || optB.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill title, question and at least 2 choices.')),
                          );
                          return;
                        }

                        final options = [optA, optB];
                        if (optC.isNotEmpty) options.add(optC);
                        if (optD.isNotEmpty) options.add(optD);

                        final qId = 'tq-${DateTime.now().millisecondsSinceEpoch}';
                        final question = TriviaQuestionModel(
                          id: qId,
                          questionAmharic: qAm,
                          questionEnglish: qEn.isNotEmpty ? qEn : qAm,
                          options: options,
                          correctOptionIndex: correctIndex.clamp(0, options.length - 1),
                          explanation: explanationController.text.trim(),
                          bibleReference: bibleRefController.text.trim(),
                        );

                        final week = int.tryParse(weekNumController.text.trim()) ?? 1;
                        final quiz = TriviaQuizModel(
                          id: 'quiz-wk-$week-${DateTime.now().millisecondsSinceEpoch}',
                          weekNumber: week,
                          title: title,
                          description: descController.text.trim(),
                          questions: [question],
                          timeLimitMinutes: 5,
                        );

                        await state.addTriviaQuiz(quiz);

                        if (dialogCtx.mounted) {
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Faith challenge "$title" published to all students!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Flexible(child: Text('Publish Challenge • ውድድሩን ይፋ አድርግ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOptionField(String label, TextEditingController controller, bool isCorrect, VoidCallback onSelectCorrect, ThemeData theme) {
    final amharicLetter = label == 'A' ? 'ሀ' : label == 'B' ? 'ለ' : label == 'C' ? 'ሐ' : 'መ';
    return Row(
      children: [
        InkWell(
          onTap: onSelectCorrect,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCorrect ? const Color(0xFF10B981) : theme.colorScheme.surfaceContainerHighest,
              shape: BoxShape.circle,
              border: Border.all(color: isCorrect ? const Color(0xFF10B981) : theme.dividerColor),
            ),
            child: Icon(
              isCorrect ? Icons.check : Icons.circle_outlined,
              size: 14,
              color: isCorrect ? Colors.white : theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Choice $label (ምርጫ $amharicLetter)',
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            ),
          ),
        ),
      ],
    );
  }
}
