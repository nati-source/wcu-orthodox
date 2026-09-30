part of '../coordinator_hub_screen.dart';

extension DeptDevelopmentModuleExt on _CoordinatorHubScreenState {
  Widget _buildDevelopmentModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final allProposals = state.fundraisingProposals;

    // Filter by Status
    var filtered = allProposals.where((p) {
      if (_developmentProposalStatusFilter == 'Pending') return p.isPending;
      if (_developmentProposalStatusFilter == 'Approved') return p.isApproved;
      if (_developmentProposalStatusFilter == 'Rejected') return p.isRejected;
      return true;
    }).toList();

    // Search Query Filter
    if (_developmentSearch.trim().isNotEmpty) {
      final q = _developmentSearch.trim().toLowerCase();
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.objective.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.targetAudience.toLowerCase().contains(q);
      }).toList();
    }

    // Financial Metrics
    final totalTargetCapital = allProposals.fold<double>(0.0, (s, p) => s + p.targetAmount);
    final approvedCapitalGoal = allProposals.where((p) => p.isApproved).fold<double>(0.0, (s, p) => s + p.targetAmount);
    final pendingCount = allProposals.where((p) => p.isPending).length;
    final approvedCount = allProposals.where((p) => p.isApproved).length;
    final rejectedCount = allProposals.where((p) => p.isRejected).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Overview & Financial Planning Metrics Card
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
                          child: Icon(Icons.savings_outlined, color: primaryAccent, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Development & Proposals • ልማትና ገቢ',
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
                      '${allProposals.length} Proposals',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Draft and submit fundraising campaign proposals, project budgets, and revenue strategies to the Admin Board for approval and university fellowship execution.',
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
                              const Icon(Icons.monetization_on_outlined, size: 14, color: AppTheme.gold),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Total Target Capital',
                                  style: TextStyle(fontSize: 10, color: textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${totalTargetCapital.toStringAsFixed(0)} ETB',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textCol),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                              const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.emerald),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Approved Target',
                                  style: TextStyle(fontSize: 10, color: textMuted),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${approvedCapitalGoal.toStringAsFixed(0)} ETB',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
            'CAMPAIGN PROPOSAL ACTIONS • የፕሮፖዛል ማዘጋጃ',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: primaryAccent,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showDraftFundraisingProposalDialog(context, state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.post_add, size: 16),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'አዲስ ፕሮፖዛል አዘጋጅ (Draft)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showProposalTemplatesDialog(context, state),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryAccent,
                    side: BorderSide(color: primaryAccent, width: 1.4),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.auto_awesome, size: 16, color: primaryAccent),
                      const SizedBox(width: 4),
                      const Flexible(
                        child: Text(
                          'ፈጣን አብነቶች (Templates)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // 3. Search Bar & Status Filter Choice Chips
        TextField(
          onChanged: (val) => _updateUi(() => _developmentSearch = val),
          decoration: InputDecoration(
            hintText: 'Search proposals by title, objective, or category...',
            prefixIcon: Icon(Icons.search, size: 18, color: primaryAccent),
            filled: true,
            fillColor: elevatedBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Status Filter ChoiceChips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDevelopmentStatusPill('All', 'All (${allProposals.length})'),
              _buildDevelopmentStatusPill('Pending', 'Pending Review ($pendingCount)'),
              _buildDevelopmentStatusPill('Approved', 'Approved ($approvedCount)'),
              _buildDevelopmentStatusPill('Rejected', 'Revision Needed ($rejectedCount)'),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Proposals Feed Header
        Text(
          'SUBMITTED FUNDRAISING PROPOSALS (${filtered.length})',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: primaryAccent,
          ),
        ),
        const SizedBox(height: 10),

        // 5. Proposals List Feed
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
                  Icon(Icons.inventory_2_outlined, size: 40, color: textMuted.withOpacity(0.5)),
                  const SizedBox(height: 10),
                  Text(
                    'No fundraising proposals found.',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Draft a new campaign proposal or pick a template from above to submit to the Admin Board.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          ...filtered.map((p) => _buildFundraisingProposalCard(context, state, p, isAudit)),
      ],
    );
  }

  Widget _buildDevelopmentStatusPill(String filterKey, String label) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isSelected = _developmentProposalStatusFilter == filterKey;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _updateUi(() => _developmentProposalStatusFilter = filterKey);
          }
        },
        selectedColor: primaryAccent.withOpacity(0.2),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? primaryAccent : theme.colorScheme.onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: isSelected ? primaryAccent : theme.dividerColor),
        ),
      ),
    );
  }

  Widget _buildFundraisingProposalCard(
    BuildContext context,
    FellowshipState state,
    FundraisingProposalModel proposal,
    bool isAudit,
  ) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (proposal.status) {
      case ProposalStatus.approved:
        statusColor = AppTheme.emerald;
        statusLabel = 'APPROVED • የፀደቀ';
        statusIcon = Icons.check_circle;
        break;
      case ProposalStatus.rejected:
        statusColor = AppTheme.crimson;
        statusLabel = 'REVISION NEEDED • የተመለሰ';
        statusIcon = Icons.cancel;
        break;
      case ProposalStatus.pending:
      default:
        statusColor = AppTheme.gold;
        statusLabel = 'PENDING REVIEW • በመጠባበቅ ላይ';
        statusIcon = Icons.hourglass_top;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withOpacity(proposal.isPending ? 0.4 : 0.6),
          width: proposal.isPending ? 1.2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status Badge & Category Pill & Duration
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: statusColor),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: elevatedBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  proposal.category,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Title
          Text(
            proposal.title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textCol,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),

          // Financial Breakdown Matrix
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: elevatedBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Target Goal', style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        '${proposal.targetAmount.toStringAsFixed(0)} ETB',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: theme.dividerColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Est. Expenses', style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        '${proposal.expectedExpenses.toStringAsFixed(0)} ETB',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Container(width: 1, height: 28, color: theme.dividerColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net Proceeds', style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        '${proposal.netExpectedProceeds.toStringAsFixed(0)} ETB',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.emerald),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Objective
          Text(
            proposal.objective,
            style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),

          // Chips: Target Audience & Duration
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.groups_outlined, size: 12, color: primaryAccent),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 200),
                      child: Text(
                        proposal.targetAudience,
                        style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: elevatedBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer_outlined, size: 12, color: textMuted),
                    const SizedBox(width: 4),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: Text(
                        proposal.timelineOrDuration,
                        style: TextStyle(fontSize: 10, color: textMuted, fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Admin Review Feedback Box (if present)
          if (proposal.adminReviewNotes != null && proposal.adminReviewNotes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: proposal.isApproved ? AppTheme.emerald.withOpacity(0.12) : AppTheme.crimson.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: proposal.isApproved ? AppTheme.emerald.withOpacity(0.3) : AppTheme.crimson.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    proposal.isApproved ? Icons.verified : Icons.feedback_outlined,
                    size: 16,
                    color: proposal.isApproved ? AppTheme.emerald : AppTheme.crimson,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          proposal.isApproved ? 'Admin Approval Note • የአድሚን ቦርድ ማረጋገጫ' : 'Admin Revision Feedback • የአድሚን ማሳሰቢያ',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: proposal.isApproved ? AppTheme.emerald : AppTheme.crimson,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          proposal.adminReviewNotes!,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: textCol,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),
          Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
          const SizedBox(height: 8),

          // Footer: Submitted By & Date & Actions
          Row(
            children: [
              Expanded(
                child: Text(
                  'By ${proposal.submittedByName} • ${proposal.submittedAt.day}/${proposal.submittedAt.month}/${proposal.submittedAt.year}',
                  style: TextStyle(fontSize: 10, color: textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: TextButton(
                  onPressed: () => _showProposalDetailsDialog(context, state, proposal),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryAccent,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('ዝርዝር (Details)', style: TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
              ),
              if (!isAudit && proposal.isPending) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: AppTheme.gold),
                  tooltip: 'Edit Proposal',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () => _showDraftFundraisingProposalDialog(context, state, editingProposal: proposal),
                ),
                const SizedBox(width: 2),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.crimson),
                  tooltip: 'Withdraw Proposal',
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    state.deleteFundraisingProposal(proposal.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fundraising proposal withdrawn.')),
                    );
                  },
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _showDraftFundraisingProposalDialog(
    BuildContext context,
    FellowshipState state, {
    FundraisingProposalModel? editingProposal,
    Map<String, dynamic>? templateData,
  }) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    final isEditing = editingProposal != null;

    final titleController = TextEditingController(
      text: editingProposal?.title ?? templateData?['title'] ?? '',
    );
    final objectiveController = TextEditingController(
      text: editingProposal?.objective ?? templateData?['objective'] ?? '',
    );
    final targetAmountController = TextEditingController(
      text: editingProposal != null
          ? editingProposal.targetAmount.toStringAsFixed(0)
          : (templateData != null ? (templateData['targetAmount'] as double).toStringAsFixed(0) : ''),
    );
    final expensesController = TextEditingController(
      text: editingProposal != null
          ? editingProposal.expectedExpenses.toStringAsFixed(0)
          : (templateData != null ? (templateData['expectedExpenses'] as double).toStringAsFixed(0) : '0'),
    );
    final strategyController = TextEditingController(
      text: editingProposal?.proposedStrategy ?? templateData?['proposedStrategy'] ?? '',
    );
    final audienceController = TextEditingController(
      text: editingProposal?.targetAudience ?? templateData?['targetAudience'] ?? '',
    );
    final timelineController = TextEditingController(
      text: editingProposal?.timelineOrDuration ?? templateData?['timelineOrDuration'] ?? '1 Month',
    );

    String selectedCategory = editingProposal?.category ?? templateData?['category'] ?? 'Bazaar & Exhibition (ባዛርና አውደ ርዕይ)';

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
                        Icon(Icons.savings_outlined, color: primaryAccent, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isEditing ? 'Edit Proposal • ፕሮፖዛል አስተካክል' : 'Draft Proposal • አዲስ የገቢ ፕሮፖዛል',
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(dialogCtx),
                          tooltip: 'Close',
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Title
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Campaign / Proposal Title • የፕሮጀክቱ ርዕስ',
                        hintText: 'e.g. የ2017 ዓመታዊ ታላቁ የበዓላት ባዛር',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Category Dropdown
                    Text('CAMPAIGN CATEGORY • የመደብ ዓይነት', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
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
                            DropdownMenuItem(value: 'Bazaar & Exhibition (ባዛርና አውደ ርዕይ)', child: Text('Bazaar & Exhibition (ባዛርና አውደ ርዕይ)')),
                            DropdownMenuItem(value: 'Alumni Pledge (የቀድሞ ተማሪዎች ድጋፍ)', child: Text('Alumni Pledge (የቀድሞ ተማሪዎች ድጋፍ)')),
                            DropdownMenuItem(value: 'Sacred Artifacts (የንዋያተ ቅድሳት ሽያጭ)', child: Text('Sacred Artifacts (የንዋያተ ቅድሳት ሽያጭ)')),
                            DropdownMenuItem(value: 'Student Emergency Fund (የተማሪዎች መረዳጃ)', child: Text('Student Emergency Fund (የተማሪዎች መረዳጃ)')),
                            DropdownMenuItem(value: 'Capital & Media Project (የግንባታና ሚዲያ)', child: Text('Capital & Media Project (የግንባታና ሚዲያ)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Financial Goal & Estimated Expenses
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: targetAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Target Goal (ETB)',
                              hintText: 'e.g. 75000',
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
                            controller: expensesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Est. Expenses (ETB)',
                              hintText: 'e.g. 8000',
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

                    // Objective
                    TextField(
                      controller: objectiveController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Primary Objective • ዋና ዓላማ',
                        hintText: 'ለተማሪዎች መንፈሳዊ ጉዞ እና ለተቸገሩ አባላት ድጋፍ የሚውል ገቢ ማሰባሰብ...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Execution Strategy
                    TextField(
                      controller: strategyController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Execution Strategy • የአፈፃፀም ስልት',
                        hintText: 'የበዓላት ዳቦና ሻማ ሽያጭ፣ የኦርቶዶክሳዊ መጻሕፍት አውደ ርዕይ...',
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Target Audience & Timeline
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: audienceController,
                            decoration: InputDecoration(
                              labelText: 'Target Audience • ተደራሽ',
                              hintText: 'የግቢው ተማሪዎችና ምዕመናን',
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
                            controller: timelineController,
                            decoration: InputDecoration(
                              labelText: 'Duration • የሚቆይበት',
                              hintText: '2 Weeks / 1 Month',
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainerHighest,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Submit Button
                    ElevatedButton.icon(
                      onPressed: () {
                        final title = titleController.text.trim();
                        final objective = objectiveController.text.trim();
                        final strategy = strategyController.text.trim();
                        final audience = audienceController.text.trim();
                        final timeline = timelineController.text.trim();
                        final targetAmt = double.tryParse(targetAmountController.text.trim()) ?? 0.0;
                        final expenses = double.tryParse(expensesController.text.trim()) ?? 0.0;

                        if (title.isEmpty || objective.isEmpty || strategy.isEmpty || targetAmt <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please fill title, objective, valid target amount, and strategy.')),
                          );
                          return;
                        }

                        if (isEditing) {
                          state.updateFundraisingProposal(
                            editingProposal.copyWith(
                              title: title,
                              objective: objective,
                              targetAmount: targetAmt,
                              expectedExpenses: expenses,
                              proposedStrategy: strategy,
                              targetAudience: audience.isNotEmpty ? audience : 'General Fellowship',
                              category: selectedCategory,
                              timelineOrDuration: timeline.isNotEmpty ? timeline : '1 Month',
                            ),
                          );
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Proposal updated successfully!')),
                          );
                        } else {
                          state.submitFundraisingProposal(
                            title: title,
                            objective: objective,
                            targetAmount: targetAmt,
                            expectedExpenses: expenses,
                            proposedStrategy: strategy,
                            targetAudience: audience.isNotEmpty ? audience : 'General Fellowship',
                            category: selectedCategory,
                            timelineOrDuration: timeline.isNotEmpty ? timeline : '1 Month',
                          );
                          Navigator.pop(dialogCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Fundraising proposal submitted to Admin Board for review!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: Text(
                        isEditing ? 'Save Changes • አስቀምጥ' : 'Submit to Admin Board • ለቦርዱ አቅርብ',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
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

  void _showProposalTemplatesDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;

    final templates = [
      {
        'title': 'የ2017 ዓመታዊ ታላቁ የበዓላት ባዛርና የንዋያተ ቅድሳት ሽያጭ',
        'category': 'Bazaar & Exhibition (ባዛርና አውደ ርዕይ)',
        'targetAmount': 75000.0,
        'expectedExpenses': 8000.0,
        'objective': 'ለተማሪዎች መንፈሳዊ ጉዞ እና ለተቸገሩ አባላት የዕለት ድጋፍ የሚውል ገቢ ማሰባሰብ።',
        'proposedStrategy': 'የበዓላት ዳቦና ሻማ ሽያጭ፣ የኦርቶዶክሳዊ መጻሕፍትና መዛሙርት አውደ ርዕይ፣ የፎቶ ማስታወሻዎች።',
        'targetAudience': 'የግቢው ተማሪዎች፣ መምህራንና የከተማው ኦርቶዶክሳውያን ምዕመናን',
        'timelineOrDuration': '2 Weeks (Meskerem 14 - 28)',
      },
      {
        'title': 'የቀድሞ ተማሪዎች (Alumni Fellowship) የቋሚ ድጋፍ ፈንድ',
        'category': 'Alumni Pledge (የቀድሞ ተማሪዎች ድጋፍ)',
        'targetAmount': 120000.0,
        'expectedExpenses': 3500.0,
        'objective': 'ከተመረቁ የቀድሞ የግቢ ጉባኤ አባላት ጋር ኔትወርክ በመፍጠር ወርሃዊ የድጋፍ ስምምነት መመስረት።',
        'proposedStrategy': 'የቴሌግራም ቦትና የባንክ ቋሚ ትእዛዝ (Standing Order) በማዘጋጀት ወርሃዊ የ100 ብር አባልነት ማስተባበር።',
        'targetAudience': 'በመላው ሀገሪቱ የሚገኙ የቀድሞ ዋቸሞ ግቢ ጉባኤ ተመራቂዎች',
        'timelineOrDuration': 'Ongoing Semester Campaign',
      },
      {
        'title': 'የቅዱሳት ሥዕላት፣ መጻሕፍትና የመዝሙር ሲዲዎች አውደ ርዕይ',
        'category': 'Sacred Artifacts (የንዋያተ ቅድሳት ሽያጭ)',
        'targetAmount': 50000.0,
        'expectedExpenses': 4500.0,
        'objective': 'ለግቢ ጉባኤው ቤተ መጻሕፍት ማስፋፊያ እና ድምፅ ማጉያ ዕቃዎች ግዢ የሚውል ፈንድ ማሰባሰብ።',
        'proposedStrategy': 'በግቢው ካምፓስ ዋና መተላለፊያ ላይ የሥነ ጥበብ አውደ ርዕይ በማዘጋጀት ሽያጭ ማካሄድ።',
        'targetAudience': 'የዩኒቨርሲቲው ተማሪዎችና የከተማ ምዕመናን',
        'timelineOrDuration': '3 Days (Weekend Expo)',
      },
      {
        'title': 'የተማሪዎች አስቸኳይ የጤናና የምግብ መረዳጃ ፈንድ',
        'category': 'Student Emergency Fund (የተማሪዎች መረዳጃ)',
        'targetAmount': 40000.0,
        'expectedExpenses': 1000.0,
        'objective': 'ለሕመምተኛ ተማሪዎች የመድኃኒት ማዘዣና የተቸገሩ ተማሪዎች የምግብ ኩፖን ወጪ መሸፈኛ።',
        'proposedStrategy': 'በየክፍሉ የድጋፍ ሳጥን ማዘዋወርና የኦንላይን የቴሌብር መዋጮ ማስተባበር።',
        'targetAudience': 'የግቢው ኦርቶዶክሳውያን ተማሪዎች',
        'timelineOrDuration': '1 Month Emergency Campaign',
      },
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
                  Icon(Icons.auto_awesome, color: primaryAccent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Fundraising Proposal Templates • ፈጣን አብነቶች',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Select a pre-structured fellowship initiative to scaffold your campaign proposal instantly.',
                style: TextStyle(fontSize: 12, color: textMuted),
              ),
              const SizedBox(height: 14),
              ...templates.map((tpl) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryAccent.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tpl['title'] as String,
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Target: ${(tpl['targetAmount'] as double).toStringAsFixed(0)} ETB • ${tpl['category']}',
                              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showDraftFundraisingProposalDialog(context, state, templateData: tpl);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Use Template', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _showProposalDetailsDialog(BuildContext context, FellowshipState state, FundraisingProposalModel proposal) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: ListView(
                controller: scrollController,
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
                  Text(
                    proposal.title,
                    style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: textCol, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          proposal.category,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: textMuted),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.timer_outlined, size: 12, color: primaryAccent),
                            const SizedBox(width: 4),
                            Text(
                              proposal.timelineOrDuration,
                              style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Financial Breakdown Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FINANCIAL BUDGETING SUMMARY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('Gross Target Amount:', style: TextStyle(fontSize: 12, color: textMuted))),
                            const SizedBox(width: 8),
                            Text('${proposal.targetAmount.toStringAsFixed(0)} ETB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('Estimated Operational Expenses:', style: TextStyle(fontSize: 12, color: textMuted))),
                            const SizedBox(width: 8),
                            Text('${proposal.expectedExpenses.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('Net Expected Yield for Fellowship:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol))),
                            const SizedBox(width: 8),
                            Text('${proposal.netExpectedProceeds.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Objective
                  Text('Primary Objective (ዓላማ):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 4),
                  Text(proposal.objective, style: TextStyle(fontSize: 12, color: textCol, height: 1.4)),
                  const SizedBox(height: 14),

                  // Proposed Strategy
                  Text('Proposed Strategy & Methodology (የአፈፃፀም ስልት):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 4),
                  Text(proposal.proposedStrategy, style: TextStyle(fontSize: 12, color: textCol, height: 1.4)),
                  const SizedBox(height: 14),

                  // Target Audience
                  Text('Target Audience & Donors (ተደራሽ ምዕመናን):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 4),
                  Text(proposal.targetAudience, style: TextStyle(fontSize: 12, color: textCol, height: 1.4)),
                  const SizedBox(height: 16),

                  // Admin Review Status Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: proposal.isApproved
                          ? AppTheme.emerald.withOpacity(0.12)
                          : (proposal.isRejected ? AppTheme.crimson.withOpacity(0.12) : AppTheme.gold.withOpacity(0.12)),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: proposal.isApproved
                            ? AppTheme.emerald.withOpacity(0.4)
                            : (proposal.isRejected ? AppTheme.crimson.withOpacity(0.4) : AppTheme.gold.withOpacity(0.4)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STATUS: ${proposal.status.name.toUpperCase()}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: proposal.isApproved
                                ? AppTheme.emerald
                                : (proposal.isRejected ? AppTheme.crimson : AppTheme.gold),
                          ),
                        ),
                        if (proposal.adminReviewNotes != null) ...[
                          const SizedBox(height: 6),
                          Text('Admin Notes: ${proposal.adminReviewNotes}', style: TextStyle(fontSize: 12, color: textCol, height: 1.3)),
                        ],
                        if (proposal.reviewedAt != null) ...[
                          const SizedBox(height: 4),
                          Text('Reviewed on: ${proposal.reviewedAt!.day}/${proposal.reviewedAt!.month}/${proposal.reviewedAt!.year}', style: TextStyle(fontSize: 10, color: textMuted)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 5: ሒሳብና ንብረት (ACCOUNTING & PROPERTY)
  // --------------------------------------------------------------------------
}
