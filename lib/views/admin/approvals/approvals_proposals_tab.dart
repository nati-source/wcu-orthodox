part of '../admin_approvals_screen.dart';

extension ApprovalsProposalsTabExt on _AdminApprovalsScreenState {
  Widget _buildFundraisingProposalsTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final allProposals = state.fundraisingProposals;

    // Filter by Status
    var filtered = allProposals.where((p) {
      if (_proposalStatusFilter == 'Pending') return p.isPending;
      if (_proposalStatusFilter == 'Approved') return p.isApproved;
      if (_proposalStatusFilter == 'Rejected') return p.isRejected;
      return true;
    }).toList();

    // Filter by Search Query
    if (_proposalSearch.trim().isNotEmpty) {
      final q = _proposalSearch.trim().toLowerCase();
      filtered = filtered.where((p) {
        return p.title.toLowerCase().contains(q) ||
            p.objective.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.submittedByName.toLowerCase().contains(q) ||
            p.targetAudience.toLowerCase().contains(q);
      }).toList();
    }

    final totalTargetCapital = allProposals.fold<double>(0.0, (s, p) => s + p.targetAmount);
    final approvedCapitalGoal = allProposals.where((p) => p.isApproved).fold<double>(0.0, (s, p) => s + p.targetAmount);
    final pendingCount = allProposals.where((p) => p.isPending).length;
    final approvedCount = allProposals.where((p) => p.isApproved).length;
    final rejectedCount = allProposals.where((p) => p.isRejected).length;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // 1. Overview & Financial Metrics Dashboard Card
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
                            'Fundraising Proposals • ልማትና ገቢ',
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
                      '${allProposals.length} Submitted',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Admin Board governance, budget validation, and formal approval queue for development and fundraising campaigns.',
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
                              const Icon(Icons.hourglass_top, size: 14, color: AppTheme.gold),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text('Pending Review', style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$pendingCount Awaiting',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: pendingCount > 0 ? AppTheme.gold : textCol),
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
                                child: Text('Approved Target', style: TextStyle(fontSize: 10, color: textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${approvedCapitalGoal.toStringAsFixed(0)} ETB',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.emerald),
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

        const SizedBox(height: 16),

        // 2. Search Field
        TextField(
          onChanged: (val) => _updateUi(() => _proposalSearch = val),
          decoration: InputDecoration(
            hintText: 'Search by title, objective, category, or submitter...',
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

        // 3. Status Filter ChoiceChips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildProposalStatusPill('All', 'All (${allProposals.length})'),
              _buildProposalStatusPill('Pending', 'Pending Review ($pendingCount)'),
              _buildProposalStatusPill('Approved', 'Approved ($approvedCount)'),
              _buildProposalStatusPill('Rejected', 'Revision Needed ($rejectedCount)'),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 4. Proposals List Section
        Text(
          'PROPOSALS REVIEW QUEUE (${filtered.length})',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: primaryAccent,
          ),
        ),
        const SizedBox(height: 10),

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
                    'When the Development & Fundraising coordinator drafts proposals or picks templates, they will appear here for Board approval.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                ],
              ),
            ),
          )
        else
          ...filtered.map((p) => _buildProposalAdminCard(context, state, p)),
      ],
    );
  }

  Widget _buildProposalStatusPill(String filterKey, String label) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isSelected = _proposalStatusFilter == filterKey;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            _updateUi(() => _proposalStatusFilter = filterKey);
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

  Widget _buildProposalAdminCard(
    BuildContext context,
    FellowshipState state,
    FundraisingProposalModel proposal,
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
        statusColor = AppTheme.gold;
        statusLabel = 'PENDING REVIEW • በመጠባበቅ ላይ';
        statusIcon = Icons.hourglass_top;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: statusColor.withOpacity(proposal.isPending ? 0.5 : 0.7),
          width: proposal.isPending ? 1.4 : 1.5,
        ),
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
          // Header: Status Badge & Category Pill
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
          const SizedBox(height: 10),

          // Footer: Submitted By & Date
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
              TextButton.icon(
                onPressed: () => _openProposalDossierDialog(context, proposal),
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text('ዝርዝር (Details)', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: primaryAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),

          // Interactive Admin Action Buttons Row (for Admin Role)
          if (state.isAdmin) ...[
            const SizedBox(height: 8),
            if (proposal.isPending) ...[
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openRejectProposalDialog(context, proposal),
                    icon: const Icon(Icons.reply_outlined, size: 14),
                    label: const Text('ማሻሻያ እዘዝ (Revision)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.crimson,
                      side: const BorderSide(color: AppTheme.crimson, width: 1.2),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _openApproveProposalDialog(context, proposal),
                    icon: const Icon(Icons.check_circle_outline, size: 14),
                    label: const Text('አጽድቅ (Approve)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openReevaluateProposalDialog(context, proposal),
                    icon: const Icon(Icons.edit_note, size: 14),
                    label: const Text('Re-evaluate / Edit Decision • ውሳኔ ቀይር', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primaryAccent,
                      side: BorderSide(color: primaryAccent.withOpacity(0.6)),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  void _openApproveProposalDialog(BuildContext context, FundraisingProposalModel proposal) {
    final theme = Theme.of(context);
    final state = widget.state;
    final noteCtrl = TextEditingController(text: 'Approved by Fellowship Admin Board for university-wide execution.');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actionsOverflowButtonSpacing: 8,
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Approve Proposal • ፕሮፖዛል አጽድቅ',
                  style: TextStyle(fontFamily: 'serif', fontSize: 16, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold),
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
                  proposal.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.monetization_on_outlined, size: 15, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          const Text('Target Capital: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          Expanded(
                            child: Text(
                              '${proposal.targetAmount.toStringAsFixed(0)} ETB',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.category_outlined, size: 15, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                          const SizedBox(width: 6),
                          Text('Category: ', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                          Expanded(
                            child: Text(
                              proposal.category,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Board Approval Note & Allocation Remarks',
                    hintText: 'e.g. Approved. Funds clearance granted with coordinator supervision.',
                  ),
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
                HapticFeedback.mediumImpact();
                state.reviewFundraisingProposal(
                  proposalId: proposal.id,
                  status: ProposalStatus.approved,
                  adminNotes: noteCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Proposal "${proposal.title}" approved successfully!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirm Approval • አጽድቅ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openRejectProposalDialog(BuildContext context, FundraisingProposalModel proposal) {
    final theme = Theme.of(context);
    final state = widget.state;
    final noteCtrl = TextEditingController(text: 'Please adjust the expected expenses and provide itemized quotation before re-submitting.');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          actionsOverflowButtonSpacing: 8,
          actionsAlignment: MainAxisAlignment.end,
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: const Row(
            children: [
              Icon(Icons.feedback_outlined, color: AppTheme.crimson, size: 24),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Request Revision • ማሻሻያ እዘዝ',
                  style: TextStyle(fontFamily: 'serif', fontSize: 16, color: AppTheme.crimson, fontWeight: FontWeight.bold),
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
                  proposal.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  'Provide feedback explaining what needs to be changed in the proposal before the Board can approve it.',
                  style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Revision Feedback Instructions',
                    hintText: 'e.g. Revise estimated budget, clarify venue agreement...',
                  ),
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
                if (noteCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter revision feedback note.')),
                  );
                  return;
                }
                HapticFeedback.mediumImpact();
                state.reviewFundraisingProposal(
                  proposalId: proposal.id,
                  status: ProposalStatus.rejected,
                  adminNotes: noteCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Revision feedback sent for "${proposal.title}".'),
                    backgroundColor: AppTheme.crimson,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.crimson,
                foregroundColor: Colors.white,
              ),
              child: const Text('Send Feedback • ማሻሻያውን ላክ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openReevaluateProposalDialog(BuildContext context, FundraisingProposalModel proposal) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final state = widget.state;
    ProposalStatus selectedStatus = proposal.status;
    final noteCtrl = TextEditingController(text: proposal.adminReviewNotes ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              actionsOverflowButtonSpacing: 8,
              actionsAlignment: MainAxisAlignment.end,
              actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                'Re-evaluate Proposal Decision',
                style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      proposal.title,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 12),
                    Text('Select Decision Status:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<ProposalStatus>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ProposalStatus.approved,
                          child: Text('APPROVED • የፀደቀ', style: TextStyle(color: AppTheme.emerald, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: ProposalStatus.rejected,
                          child: Text('REVISION NEEDED • ማሻሻያ የሚያስፈልገው', style: TextStyle(color: AppTheme.crimson, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        DropdownMenuItem(
                          value: ProposalStatus.pending,
                          child: Text('PENDING REVIEW • በመጠባበቅ ላይ', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => selectedStatus = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Admin Board Review Notes',
                        hintText: 'Enter updated notes or remarks...',
                      ),
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
                    HapticFeedback.mediumImpact();
                    state.reviewFundraisingProposal(
                      proposalId: proposal.id,
                      status: selectedStatus,
                      adminNotes: noteCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Proposal review status updated.')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                  ),
                  child: const Text('Save Decision', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openProposalDossierDialog(BuildContext context, FundraisingProposalModel proposal) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final state = widget.state;

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
        statusColor = AppTheme.gold;
        statusLabel = 'PENDING REVIEW • በመጠባበቅ ላይ';
        statusIcon = Icons.hourglass_top;
        break;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
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
                  Row(
                    children: [
                      Icon(Icons.savings_outlined, color: primaryAccent, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Proposal Dossier • ሙሉ የፕሮፖዛል ዝርዝር',
                          style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: textCol),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.pop(ctx),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Header Badges: Status & Category & Duration
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: statusColor.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 13, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              statusLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                            ),
                          ],
                        ),
                      ),
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
                  const SizedBox(height: 12),

                  Text(
                    proposal.title,
                    style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: textCol, height: 1.3),
                  ),
                  const SizedBox(height: 16),

                  // Financial Matrix
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FINANCIAL BUDGET MATRIX • የፋይናንስ በጀት', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('Target Gross Capital Goal:', style: TextStyle(fontSize: 12, color: textMuted)),
                            ),
                            const SizedBox(width: 8),
                            Text('${proposal.targetAmount.toStringAsFixed(0)} ETB', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text('Estimated Operational Expenses:', style: TextStyle(fontSize: 12, color: textMuted)),
                            ),
                            const SizedBox(width: 8),
                            Text('- ${proposal.expectedExpenses.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                          ],
                        ),
                        Divider(height: 16, color: theme.dividerColor),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text('Expected Net Proceeds:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                            ),
                            const SizedBox(width: 8),
                            Text('${proposal.netExpectedProceeds.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.emerald)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  Text('PRIMARY OBJECTIVE • ዋና ዓላማ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(proposal.objective, style: TextStyle(fontSize: 13, color: textCol, height: 1.4)),
                  ),
                  const SizedBox(height: 14),

                  Text('EXECUTION STRATEGY • የአፈፃፀም ስልት', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(proposal.proposedStrategy, style: TextStyle(fontSize: 13, color: textCol, height: 1.4)),
                  ),
                  const SizedBox(height: 14),

                  Text('SUBMITTER & AUDIENCE • ተደራሽና አቅራቢ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Target Audience:', style: TextStyle(fontSize: 12, color: textMuted)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                proposal.targetAudience,
                                textAlign: TextAlign.end,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Submitted By:', style: TextStyle(fontSize: 12, color: textMuted)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                proposal.submittedByName,
                                textAlign: TextAlign.end,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Department:', style: TextStyle(fontSize: 12, color: textMuted)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                FellowshipDepartmentConstants.getNameAmharic(proposal.submittedByDept),
                                textAlign: TextAlign.end,
                                style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Submission Date:', style: TextStyle(fontSize: 12, color: textMuted)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                '${proposal.submittedAt.day}/${proposal.submittedAt.month}/${proposal.submittedAt.year}',
                                textAlign: TextAlign.end,
                                style: TextStyle(fontSize: 12, color: textCol),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  if (proposal.adminReviewNotes != null && proposal.adminReviewNotes!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      proposal.isApproved ? 'ADMIN BOARD APPROVAL • የአድሚን ቦርድ ማረጋገጫ' : 'ADMIN REVISION FEEDBACK • የአድሚን ማሳሰቢያ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: proposal.isApproved ? AppTheme.emerald : AppTheme.crimson,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: proposal.isApproved ? AppTheme.emerald.withOpacity(0.12) : AppTheme.crimson.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: proposal.isApproved ? AppTheme.emerald.withOpacity(0.4) : AppTheme.crimson.withOpacity(0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                proposal.isApproved ? Icons.verified : Icons.feedback_outlined,
                                size: 16,
                                color: proposal.isApproved ? AppTheme.emerald : AppTheme.crimson,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  proposal.isApproved ? 'Status: Approved for University Execution' : 'Status: Revision Feedback from Board',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: proposal.isApproved ? AppTheme.emerald : AppTheme.crimson,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            proposal.adminReviewNotes!,
                            style: TextStyle(fontSize: 12, color: textCol, height: 1.4, fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (state.isAdmin && proposal.isPending) ...[
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openRejectProposalDialog(context, proposal);
                            },
                            icon: const Icon(Icons.reply_outlined, size: 16),
                            label: const Text('ማሻሻያ እዘዝ (Revision)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.crimson,
                              side: const BorderSide(color: AppTheme.crimson, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _openApproveProposalDialog(context, proposal);
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('አጽድቅ (Approve)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else if (state.isAdmin) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _openReevaluateProposalDialog(context, proposal);
                        },
                        icon: const Icon(Icons.edit_note, size: 16),
                        label: const Text('Re-evaluate Decision • ውሳኔ ቀይር', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryAccent,
                          side: BorderSide(color: primaryAccent.withOpacity(0.6)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
