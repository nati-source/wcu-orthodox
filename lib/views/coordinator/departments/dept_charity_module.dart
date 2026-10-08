part of '../coordinator_hub_screen.dart';

extension DeptCharityModuleExt on _CoordinatorHubScreenState {
  Widget _buildCharityModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final campaigns = state.charityCampaigns;
    final duesPayments = state.duesPayments;
    final disbursements = state.charityDisbursements;

    // Financial Calculation for Charity
    final totalCampaignsRaised = campaigns.fold<double>(0.0, (sum, c) => sum + c.raisedAmount);
    final totalTargetBudget = campaigns.fold<double>(0.0, (sum, c) => sum + c.targetAmount);
    final totalDuesCollected = duesPayments.where((d) => d.status == 'Verified').fold<double>(0.0, (sum, d) => sum + d.amount);
    final totalAidDisbursed = disbursements.fold<double>(0.0, (sum, d) => sum + d.amount);
    final totalGrossInflow = totalCampaignsRaised + totalDuesCollected;
    final netTreasuryBalance = totalGrossInflow - totalAidDisbursed;
    final totalDonors = campaigns.fold<int>(0, (sum, c) => sum + c.donorsCount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Charity Treasury / Money Controlling Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.16),
                theme.cardTheme.color ?? theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
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
                        const Icon(Icons.volunteer_activism_outlined, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Charity Treasury & Vault Control • የበጎ አድራጎት ካዝና',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$totalDonors Donors', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Gross Inflow',
                      amount: '${totalGrossInflow.toStringAsFixed(0)} ETB',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Aid Disbursed',
                      amount: '${totalAidDisbursed.toStringAsFixed(0)} ETB',
                      color: AppTheme.crimson,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Net Balance',
                      amount: '${netTreasuryBalance.toStringAsFixed(0)} ETB',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Campaigns Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: totalTargetBudget > 0 ? (totalCampaignsRaised / totalTargetBudget).clamp(0.0, 1.0) : 0.0,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text('Campaigns Raised: ${totalCampaignsRaised.toStringAsFixed(0)} ETB', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('Goal: ${totalTargetBudget.toStringAsFixed(0)} ETB', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Action Toolbar: Add Campaign & Record Donation & Disburse Aid
        if (!isAudit) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openAddCharityCampaignModal(context, state),
                  icon: const Icon(Icons.add_task, size: 14, color: Colors.white),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Add Campaign', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openRecordDonationModal(context, state),
                  icon: const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF10B981)),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Record Donation', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openDisburseAidModal(context, state),
                  icon: const Icon(Icons.handshake_outlined, size: 14, color: AppTheme.crimson),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('Disburse Aid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimson)),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                    side: const BorderSide(color: AppTheme.crimson),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],

        // 3. Sub-Section Navigation Tabs (Campaigns, Donations Inflow, Aid Disbursements Outflow, Aid Requests)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCharityTabPill(
                context: context,
                label: 'Campaigns',
                count: campaigns.length,
                tabIndex: 0,
                activeColor: const Color(0xFF10B981),
                icon: Icons.campaign_outlined,
              ),
              const SizedBox(width: 8),
              _buildCharityTabPill(
                context: context,
                label: 'Donations & Dues',
                count: duesPayments.length,
                tabIndex: 1,
                activeColor: const Color(0xFF10B981),
                icon: Icons.receipt_long_outlined,
              ),
              const SizedBox(width: 8),
              _buildCharityTabPill(
                context: context,
                label: 'Aid Disbursements',
                count: disbursements.length,
                tabIndex: 2,
                activeColor: AppTheme.crimson,
                icon: Icons.outbox_rounded,
              ),
              const SizedBox(width: 8),
              _buildCharityTabPill(
                context: context,
                label: 'Aid Requests',
                count: state.emergencyAidRequests.length,
                tabIndex: 3,
                activeColor: const Color(0xFFF59E0B),
                icon: Icons.emergency_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // SUB-TAB 0: CAMPAIGNS LIST
        if (_charityLedgerTab == 0) ...[
          if (campaigns.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text('No active charity campaigns. Tap "Add Campaign" above.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            )
          else
            ...campaigns.map((camp) {
              return InteractiveFellowshipCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderColor: const Color(0xFF10B981).withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            camp.title,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(camp.progressPercentage * 100).toStringAsFixed(0)}% Funded',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Category: ${camp.category}', style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(camp.description, style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                    const SizedBox(height: 8),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: camp.progressPercentage,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text('Raised: ${camp.raisedAmount.toStringAsFixed(0)} ETB (${camp.donorsCount} Donors)', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text('Goal: ${camp.targetAmount.toStringAsFixed(0)} ETB', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),

                    if (!isAudit) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                            tooltip: 'Delete Campaign',
                            onPressed: () {
                              _confirmDeleteDialog(
                                context,
                                title: 'Delete Charity Campaign',
                                message: 'Are you sure you want to delete "${camp.title}"?',
                                onConfirm: () {
                                  state.removeCharityCampaign(camp.id);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Campaign "${camp.title}" deleted.')));
                                },
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          OutlinedButton.icon(
                            onPressed: () => _openEditCharityCampaignModal(context, state, camp),
                            icon: const Icon(Icons.edit, size: 12),
                            label: const Text('Edit Goal', style: TextStyle(fontSize: 11)),
                            style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],

        // SUB-TAB 1: DONATIONS & DUES INFLOW LEDGER
        if (_charityLedgerTab == 1) ...[
          if (duesPayments.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text('No donations or dues recorded yet.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            )
          else
            ...duesPayments.map((due) {
              final isVerified = due.status == 'Verified';
              return InteractiveFellowshipCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderColor: isVerified ? theme.dividerColor : const Color(0xFFF59E0B).withOpacity(0.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFF10B981).withOpacity(0.15),
                          child: const Icon(Icons.receipt_long, color: Color(0xFF10B981), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                due.studentName,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${due.amount.toStringAsFixed(0)} ETB • ${due.purpose}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Ref: ${due.transactionReference} (${due.paymentMethod.displayName})',
                                style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            due.status,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isVerified ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isAudit) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (!isVerified) ...[
                            OutlinedButton(
                              onPressed: () {
                                HapticFeedback.selectionClick();
                                state.verifyDuesPayment(due.id, false);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution declined.')));
                              },
                              style: OutlinedButton.styleFrom(foregroundColor: AppTheme.crimson, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                              child: const Text('Decline', style: TextStyle(fontSize: 11)),
                            ),
                            const SizedBox(width: 6),
                            ElevatedButton(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                state.verifyDuesPayment(due.id, true);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution verified & added to Charity vault!')));
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                              child: const Text('Verify', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                            const SizedBox(width: 6),
                          ],
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                            tooltip: 'Void / Delete Contribution',
                            onPressed: () {
                              _confirmDeleteDialog(
                                context,
                                title: 'Void Contribution',
                                message: 'Delete contribution record of ${due.amount.toStringAsFixed(0)} ETB from ${due.studentName}?',
                                onConfirm: () {
                                  state.deleteDuesPayment(due.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contribution record deleted.')));
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],

        // SUB-TAB 2: AID DISBURSEMENTS OUTFLOW LEDGER
        if (_charityLedgerTab == 2) ...[
          if (disbursements.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text('No aid disbursements recorded yet. Tap "Disburse Aid" above.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            )
          else
            ...disbursements.map((disb) {
              return InteractiveFellowshipCard(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderColor: AppTheme.crimson.withOpacity(0.3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppTheme.crimson.withOpacity(0.12),
                          child: const Icon(Icons.outbox, color: AppTheme.crimson, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                disb.beneficiaryName,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${disb.amount.toStringAsFixed(0)} ETB • ${disb.assistanceType}',
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Voucher: ${disb.voucherReference} • By: ${disb.approvedBy}',
                                style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (!isAudit)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                            tooltip: 'Void Disbursement Record',
                            onPressed: () {
                              _confirmDeleteDialog(
                                context,
                                title: 'Void Disbursement',
                                message: 'Are you sure you want to void disbursement of ${disb.amount.toStringAsFixed(0)} ETB for ${disb.beneficiaryName}?',
                                onConfirm: () {
                                  state.deleteCharityDisbursement(disb.id);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disbursement record voided.')));
                                },
                              );
                            },
                          ),
                      ],
                    ),
                    if (disb.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text('Note: ${disb.notes}', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                    ],
                  ],
                ),
              );
            }),
        ],

        // SUB-TAB 3: EMERGENCY AID REQUESTS & DIRECT DISBURSEMENTS
        if (_charityLedgerTab == 3) ...[
          if (state.emergencyAidRequests.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Text('No emergency aid requests currently on file.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            )
          else
            ...state.emergencyAidRequests.map((req) {
              final isUnderReview = req.status == EmergencyAidStatus.underReview;
              final isDisbursed = req.status == EmergencyAidStatus.disbursed;
              return InteractiveFellowshipCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderColor: isUnderReview ? const Color(0xFFF59E0B) : theme.dividerColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: req.status.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: req.status.color),
                          ),
                          child: Text(req.status.displayName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: req.status.color)),
                        ),
                        Text(
                          '${req.amountRequested.toInt()} ETB',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${req.studentName} (${req.studentBaptismalName})',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    Text(
                      'Dept: ${req.department} Yr ${req.academicYear} • Phone: ${req.studentPhone}',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: ${req.category.displayName}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryAccent),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      req.description,
                      style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                    if (req.adminNote != null && req.adminNote!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Note: ${req.adminNote}',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                    if (isUnderReview && !isAudit) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              state.updateAidRequestStatus(req.id, EmergencyAidStatus.declined, adminNote: 'Declined by Charity Coordinator.');
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aid request for ${req.studentName} declined.')));
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.crimson),
                            child: const Text('Decline', style: TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            onPressed: () => _openDisburseAidModal(context, state, linkedRequest: req),
                            icon: const Icon(Icons.payments_outlined, size: 14, color: Colors.white),
                            label: const Text('Disburse Payment', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ],
    );
  }

  // --------------------------------------------------------------------------
  // DEPARTMENT 1: ትምህርትና ሐዋርያዊ አገልግሎት (EDUCATION & APOSTOLIC MINISTRY)
  // Dedicated to: Batch-Targeted Course Broadcasts & Special Programs Scheduling
  // --------------------------------------------------------------------------

  Widget _buildCharityTabPill({
    required BuildContext context,
    required String label,
    required int count,
    required int tabIndex,
    required Color activeColor,
    required IconData icon,
  }) {
    final isSelected = _charityLedgerTab == tabIndex;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _updateUi(() => _charityLedgerTab = tabIndex);
      },
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(isDark ? 0.28 : 0.16)
              : (theme.cardTheme.color ?? theme.colorScheme.surface),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? activeColor : activeColor.withOpacity(0.35),
            width: isSelected ? 1.8 : 1.1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.28),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? activeColor : (isDark ? activeColor.withOpacity(0.9) : activeColor),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : activeColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : activeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 6. Add Charity Campaign Modal
  void _openAddCharityCampaignModal(BuildContext context, FellowshipState state) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '25000');
    String category = 'Student Mutual Aid';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add Charity Campaign • አዲስ የበጎ አድራጎት ፕሮጀክት', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    const SizedBox(height: 14),
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Campaign Title (e.g. የተማሪዎች ደብተርና እስክሪብቶ ድጋፍ)')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: category,
                      isExpanded: true,
                      items: ['Student Mutual Aid', 'Orphanage Outreach', 'Hospital Visits', 'Church Construction', 'Emergency Food Aid']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setMState(() => category = val);
                      },
                      decoration: const InputDecoration(labelText: 'Category'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Budget (ETB)')),
                    const SizedBox(height: 10),
                    TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description & Beneficiary Plan')),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (titleCtrl.text.trim().isEmpty) return;
                          final newCamp = CharityCampaignModel(
                            id: 'camp-${DateTime.now().millisecondsSinceEpoch}',
                            title: titleCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            targetAmount: double.tryParse(targetCtrl.text.trim()) ?? 25000.0,
                            raisedAmount: 0.0,
                            donorsCount: 0,
                            deadline: DateTime.now().add(const Duration(days: 30)),
                            category: category,
                          );
                          state.addCharityCampaign(newCamp);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Charity Campaign "${newCamp.title}" published!')));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        child: const Text('Launch Campaign', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  // 7. Edit Charity Campaign Modal
  void _openEditCharityCampaignModal(BuildContext context, FellowshipState state, CharityCampaignModel camp) {
    final titleCtrl = TextEditingController(text: camp.title);
    final targetCtrl = TextEditingController(text: camp.targetAmount.toStringAsFixed(0));
    final descCtrl = TextEditingController(text: camp.description);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Charity Goal • የበጎ አድራጎት ማስተካከያ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                const SizedBox(height: 14),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Campaign Title')),
                const SizedBox(height: 10),
                TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Goal (ETB)')),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final updated = CharityCampaignModel(
                        id: camp.id,
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        targetAmount: double.tryParse(targetCtrl.text.trim()) ?? camp.targetAmount,
                        raisedAmount: camp.raisedAmount,
                        donorsCount: camp.donorsCount,
                        deadline: camp.deadline,
                        category: camp.category,
                      );
                      state.updateCharityCampaign(updated);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Campaign "${updated.title}" updated.')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 8. Record Donation / Dues Modal (Add Inflow)
  void _openRecordDonationModal(BuildContext context, FellowshipState state) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController(text: '500');
    final purposeCtrl = TextEditingController(text: 'Monthly Fellowship Dues');
    final refCtrl = TextEditingController(text: 'DON-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    PaymentMethodType method = PaymentMethodType.telebirr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Record Donation / Dues • የልገሳ መመዝገቢያ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Donor / Fellow Name')),
                    const SizedBox(height: 10),
                    TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount (ETB)')),
                    const SizedBox(height: 10),
                    TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Purpose / Fund Designation')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<PaymentMethodType>(
                      value: method,
                      isExpanded: true,
                      items: [PaymentMethodType.telebirr, PaymentMethodType.cbeBirr, PaymentMethodType.cash]
                          .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setMState(() => method = val);
                      },
                      decoration: const InputDecoration(labelText: 'Payment Method'),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Receipt / Bank Reference')),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (nameCtrl.text.trim().isEmpty) return;
                          state.submitDuesPayment(
                            amount: double.tryParse(amountCtrl.text.trim()) ?? 500.0,
                            purpose: purposeCtrl.text.trim(),
                            paymentMethod: method,
                            transactionReference: refCtrl.text.trim(),
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contribution of ${amountCtrl.text} ETB recorded for ${nameCtrl.text.trim()}!')));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                        child: const Text('Save Contribution', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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

  // 9. Disburse Aid Grant Modal (Add Outflow)
  void _openDisburseAidModal(BuildContext context, FellowshipState state, {EmergencyAidRequestModel? linkedRequest}) {
    final beneficiaryCtrl = TextEditingController(
      text: linkedRequest != null ? '${linkedRequest.studentName} (${linkedRequest.studentBaptismalName})' : '',
    );
    final amountCtrl = TextEditingController(
      text: linkedRequest != null ? linkedRequest.amountRequested.toInt().toString() : '800',
    );
    final purposeCtrl = TextEditingController(
      text: linkedRequest != null ? linkedRequest.category.displayName : 'Cafeteria & Meal Subsidy',
    );
    final voucherCtrl = TextEditingController(
      text: 'VCH-AID-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    final notesCtrl = TextEditingController(
      text: linkedRequest != null ? 'Recipient Phone: ${linkedRequest.studentPhone} • Disbursed for ${linkedRequest.category.displayName}' : '',
    );
    PaymentMethodType selectedDisbMethod = PaymentMethodType.telebirr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setMState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.handshake_outlined, color: AppTheme.crimson, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            linkedRequest != null ? 'Disburse Aid to ${linkedRequest.studentName}' : 'Disburse Charity Aid • ድጋፍ መስጫ ቫውቸር',
                            style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.crimson),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: beneficiaryCtrl,
                      decoration: const InputDecoration(labelText: 'Beneficiary Student Name', prefixIcon: Icon(Icons.person_outline, size: 18)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: amountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Disbursed Amount (ETB)', prefixIcon: Icon(Icons.payments_outlined, size: 18)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<PaymentMethodType>(
                            value: selectedDisbMethod,
                            isExpanded: true,
                            items: [PaymentMethodType.telebirr, PaymentMethodType.cbeBirr, PaymentMethodType.cash]
                                .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName, maxLines: 1, overflow: TextOverflow.ellipsis)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setMState(() => selectedDisbMethod = val);
                            },
                            decoration: const InputDecoration(labelText: 'Disburse Channel', prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 18)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: purposeCtrl, decoration: const InputDecoration(labelText: 'Assistance Category / Need Reason', prefixIcon: Icon(Icons.category_outlined, size: 18))),
                    const SizedBox(height: 10),
                    TextField(controller: voucherCtrl, decoration: const InputDecoration(labelText: 'Voucher Reference ID', prefixIcon: Icon(Icons.tag, size: 18))),
                    const SizedBox(height: 10),
                    TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes & Transfer Details', prefixIcon: Icon(Icons.notes, size: 18))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (beneficiaryCtrl.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter beneficiary name!')));
                            return;
                          }
                          final amt = double.tryParse(amountCtrl.text.trim()) ?? 800.0;
                          final voucher = voucherCtrl.text.trim().isEmpty ? 'VCH-AID-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}' : voucherCtrl.text.trim();

                          if (linkedRequest != null) {
                            state.disburseEmergencyAid(
                              requestId: linkedRequest.id,
                              amount: amt,
                              paymentMethod: selectedDisbMethod.displayName,
                              voucherReference: voucher,
                              note: notesCtrl.text.trim(),
                            );
                          } else {
                            final disb = CharityDisbursementModel(
                              id: 'disb-${DateTime.now().millisecondsSinceEpoch}',
                              beneficiaryName: beneficiaryCtrl.text.trim(),
                              assistanceType: purposeCtrl.text.trim().isEmpty ? 'Direct Student Aid' : purposeCtrl.text.trim(),
                              amount: amt,
                              voucherReference: voucher,
                              approvedBy: state.currentUser.fullName.isNotEmpty ? state.currentUser.fullName : 'Charity Treasury Office',
                              disbursedAt: DateTime.now(),
                              notes: notesCtrl.text.trim(),
                            );
                            state.addCharityDisbursement(disb);
                          }
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Aid of ${amt.toStringAsFixed(0)} ETB disbursed via ${selectedDisbMethod.displayName} for ${beneficiaryCtrl.text.trim()}!')));
                        },
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Confirm Disbursement & Issue Voucher', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.crimson,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
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
}
