part of '../admin_approvals_screen.dart';

extension ApprovalsEmergencyAidTabExt on _AdminApprovalsScreenState {
  Widget _buildEmergencyAidTab(BuildContext context, List<EmergencyAidRequestModel> requests) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    if (requests.isEmpty) {
      return Center(
        child: Text('No emergency aid applications on file.', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 14)),
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
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: req.status.color.withOpacity(0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(req.category.displayName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
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
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                'Amount Requested: ${req.amountRequested.toInt()} ETB',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryAccent),
              ),
              const SizedBox(height: 6),
              Text(
                req.description,
                style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withOpacity(0.85), height: 1.3),
              ),
              if (isUnderReview) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
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
                        HapticFeedback.mediumImpact();
                        _showAdminDisburseDialog(context, state, req);
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

  void _showAdminDisburseDialog(BuildContext context, FellowshipState state, EmergencyAidRequestModel req) {
    final theme = Theme.of(context);
    final amountCtrl = TextEditingController(text: req.amountRequested.toInt().toString());
    final voucherCtrl = TextEditingController(text: 'VCH-ADMIN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final noteCtrl = TextEditingController(text: 'Approved & Disbursed to ${req.studentPhone}');
    PaymentMethodType method = PaymentMethodType.telebirr;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          title: Row(
            children: [
              const Icon(Icons.handshake_outlined, color: Color(0xFF10B981)),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Disburse Emergency Aid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Student: ${req.studentName} (${req.studentBaptismalName})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Category: ${req.category.displayName} • Phone: ${req.studentPhone}', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                const SizedBox(height: 12),
                TextField(controller: amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Approved Amount (ETB)', prefixIcon: Icon(Icons.payments_outlined, size: 18))),
                const SizedBox(height: 10),
                DropdownButtonFormField<PaymentMethodType>(
                  value: method,
                  isExpanded: true,
                  items: [PaymentMethodType.telebirr, PaymentMethodType.cbeBirr, PaymentMethodType.cash]
                      .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName))).toList(),
                  onChanged: (val) { if (val != null) setDState(() => method = val); },
                  decoration: const InputDecoration(labelText: 'Payment Channel', prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 18)),
                ),
                const SizedBox(height: 10),
                TextField(controller: voucherCtrl, decoration: const InputDecoration(labelText: 'Voucher Reference ID', prefixIcon: Icon(Icons.tag, size: 18))),
                const SizedBox(height: 10),
                TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Admin Notes / Receipt Ref', prefixIcon: Icon(Icons.notes, size: 18))),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amt = double.tryParse(amountCtrl.text.trim()) ?? req.amountRequested;
                final voucher = voucherCtrl.text.trim().isEmpty ? 'VCH-ADMIN-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}' : voucherCtrl.text.trim();
                state.disburseEmergencyAid(
                  requestId: req.id,
                  amount: amt,
                  paymentMethod: method.displayName,
                  voucherReference: voucher,
                  note: noteCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Disbursement of ${amt.toStringAsFixed(0)} ETB recorded for ${req.studentName}.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Confirm Disbursement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 5: ROLE ASSIGNMENTS
  // ----------------------------------------------------
}
