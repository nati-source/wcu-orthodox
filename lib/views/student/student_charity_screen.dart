import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentCharityScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentCharityScreen({super.key, required this.state});

  @override
  State<StudentCharityScreen> createState() => _StudentCharityScreenState();
}

class _StudentCharityScreenState extends State<StudentCharityScreen> {
  int _activeTab = 0; // 0: Mutual Aid & Campaigns, 1: Pay Dues, 2: Apply for Emergency Aid

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mutual Aid & Charity • መረዳጃና ምጽዋት'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (state.canManageCharityAndAid) ...[
            IconButton(
              icon: const Icon(Icons.volunteer_activism, color: Color(0xFF10B981)),
              tooltip: 'Emergency Aid Requests Review',
              onPressed: () => _showAidReviewModal(context, state),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: primaryAccent),
              tooltip: 'Add Charity Campaign',
              onPressed: () => _showAddCampaignDialog(context, state),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Segmented Navigation Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavButton(context, 'Aid Campaigns', Icons.volunteer_activism, 0)),
                Expanded(child: _buildNavButton(context, 'Pay Dues (መዋጮ)', Icons.payments_outlined, 1)),
                Expanded(child: _buildNavButton(context, 'Request Aid (እርዳታ)', Icons.emergency_outlined, 2)),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 0
                ? _buildCampaignsTab(context, state)
                : _activeTab == 1
                    ? _buildPayDuesTab(context, state)
                    : _buildRequestAidTab(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(BuildContext context, String title, IconData icon, int index) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isSelected = _activeTab == index;

    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryAccent.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: primaryAccent.withOpacity(0.5)) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 0: CAMPAIGNS & MUTUAL AID
  // ----------------------------------------------------
  Widget _buildCampaignsTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Grand Quote Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF10B981).withOpacity(0.15),
                theme.cardTheme.color ?? theme.colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.handshake_outlined, color: Color(0xFF10B981), size: 30),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  '“እርስ በርሳችሁ ሸክማችሁን ተሸካከሙ፤ እንዲሁ የክርስቶስን ሕግ ትፈጽማላችሁ።” — ገላትያ 6፥2',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'ACTIVE FELLOWSHIP DRIVES & AID CAMPAIGNS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),

        ...state.charityCampaigns.map((camp) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: camp.isEmergency ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          camp.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: camp.isEmergency ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${camp.donorsCount} Donors',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  camp.title,
                  style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  camp.description,
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 14),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: camp.progressPercentage,
                    minHeight: 8,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        '${camp.raisedAmount.toInt()} ETB raised',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Goal: ${camp.targetAmount.toInt()} ETB',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _openDonateModal(context, camp),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          minimumSize: const Size(double.infinity, 40),
                        ),
                        child: const Text('Donate via Telebirr / CBE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    if (state.canManageCharityAndAid) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 20),
                        tooltip: 'Delete Campaign',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                              title: const Text('Delete Charity Campaign'),
                              content: Text('Are you sure you want to delete "${camp.title}"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                ElevatedButton(
                                  onPressed: () {
                                    state.removeCharityCampaign(camp.id);
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Campaign "${camp.title}" removed.')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.crimson),
                                  child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ----------------------------------------------------
  // TAB 1: PAY MONTHLY DUES (የአባልነት መዋጮ)
  // ----------------------------------------------------
  Widget _buildPayDuesTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fellowship Membership Dues (የአባልነት መዋጮ)',
                style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              ),
              const SizedBox(height: 6),
              Text(
                'Active students contribute a suggested 50 ETB monthly to sustain Sunday school teaching materials, monastery visits, and mutual student aid.',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildAccountInfo(context, 'Telebirr', '+251911223344', 'WCU Orthodox Student Fellowship'),
              const SizedBox(height: 8),
              _buildAccountInfo(context, 'CBE Account', '1000234567890', 'WCU Orthodox Fellowship'),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _openPayDuesModal(context),
                icon: Icon(Icons.send_outlined, color: isDark ? Colors.black : Colors.white, size: 16),
                label: Text('Submit Dues Payment Receipt', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'PAYMENT HISTORY & RECEIPTS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        ...state.duesPayments.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.purpose, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text('Ref: ${p.transactionReference}', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${p.amount.toInt()} ETB', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryAccent)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(p.status, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildAccountInfo(BuildContext context, String title, String number, String name) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.bold)),
                Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                Text(name, style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 16, color: primaryAccent),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied $title ($number)'), backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface),
              );
            },
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 2: APPLY FOR EMERGENCY AID (እርዳታ መጠየቂያ)
  // ----------------------------------------------------
  Widget _buildRequestAidTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final myRequests = state.myEmergencyAidRequests;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lock_clock_outlined, color: primaryAccent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Confidential Student Emergency Aid',
                      style: TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Are you facing sudden illness, cafeteria meal crisis, or family emergency? The fellowship mutual aid committee is here for you in strict confidence.',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openAidApplicationDialog(context),
                icon: Icon(Icons.add_circle_outline, color: isDark ? Colors.black : Colors.white, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('Apply for Emergency Assistance', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'MY AID APPLICATIONS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        if (myRequests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No active emergency aid applications.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ),
          )
        else
          ...myRequests.map((req) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: req.status.color.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          req.category.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                  Text('Requested Amount: ${req.amountRequested.toInt()} ETB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 4),
                  Text(req.description, style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                  if (req.adminNote != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                      child: Text('Committee Note: ${req.adminNote}', style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface)),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  void _openDonateModal(BuildContext context, CharityCampaignModel camp) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final amountController = TextEditingController(text: '100');
    final refController = TextEditingController(text: 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    PaymentMethodType selectedMethod = PaymentMethodType.telebirr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
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
                        const Icon(Icons.volunteer_activism_outlined, color: Color(0xFF10B981), size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Donate to ${camp.title}',
                            style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick Amount Chips
                    Text('Select or Enter Amount', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [50, 100, 200, 500, 1000].map((amt) {
                        final isSel = amountController.text == amt.toString();
                        return ChoiceChip(
                          label: Text('$amt ETB'),
                          selected: isSel,
                          onSelected: (_) {
                            setMState(() => amountController.text = amt.toString());
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Custom Donation Amount (ETB)', suffixText: 'ETB', prefixIcon: Icon(Icons.payments_outlined, size: 18)),
                    ),
                    const SizedBox(height: 12),

                    // Payment Channel Selection
                    Text('Payment Channel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            avatar: const Icon(Icons.phone_android, size: 16),
                            label: const Text('Telebirr', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            selected: selectedMethod == PaymentMethodType.telebirr,
                            onSelected: (_) => setMState(() {
                              selectedMethod = PaymentMethodType.telebirr;
                              refController.text = 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                            }),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            avatar: const Icon(Icons.account_balance, size: 16),
                            label: const Text('CBE Birr / Bank', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            selected: selectedMethod == PaymentMethodType.cbeBirr,
                            onSelected: (_) => setMState(() {
                              selectedMethod = PaymentMethodType.cbeBirr;
                              refController.text = 'CBE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Official Fellowship Receiving Accounts Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Official Receiving Account (ይፋዊ የሂሳብ ቁጥር):', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedMethod == PaymentMethodType.telebirr
                                    ? 'Telebirr: 0911002233 (WCU Fellowship)'
                                    : 'CBE: 1000234567890 (WCU Fellowship)',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 16, color: Color(0xFF10B981)),
                                tooltip: 'Copy Account Number',
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account number copied to clipboard!')));
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: refController,
                      decoration: const InputDecoration(labelText: 'Transaction Ref / Receipt Code', prefixIcon: Icon(Icons.receipt_long_outlined, size: 18)),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final amt = double.tryParse(amountController.text.trim()) ?? 100.0;
                          final ref = refController.text.trim().isEmpty ? 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}' : refController.text.trim();
                          widget.state.submitCampaignDonation(
                            campaignId: camp.id,
                            amount: amt,
                            paymentMethod: selectedMethod,
                            transactionReference: ref,
                          );
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Donation of ${amt.toStringAsFixed(0)} ETB recorded! May God bless you abundantly.'),
                              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                            ),
                          );
                        },
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Complete Donation', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _openPayDuesModal(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final refController = TextEditingController();
    PaymentMethodType method = PaymentMethodType.telebirr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 24,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Submit Monthly Dues (50 ETB)', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: primaryAccent)),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PaymentMethodType>(
                    value: method,
                    dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                    items: [PaymentMethodType.telebirr, PaymentMethodType.cbeAccount]
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface))))
                        .toList(),
                    onChanged: (val) => setModalState(() => method = val!),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: refController,
                    decoration: const InputDecoration(labelText: 'Transaction Reference Code', hintText: 'e.g. TB-849102384'),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () {
                      if (refController.text.trim().isEmpty) return;
                      widget.state.submitDuesPayment(
                        amount: 50.0,
                        purpose: 'Monthly Fellowship Dues',
                        paymentMethod: method,
                        transactionReference: refController.text.trim(),
                      );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Payment receipt submitted for verification'), backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text('Submit Receipt', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openAidApplicationDialog(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    EmergencyAidCategory selectedCategory = EmergencyAidCategory.medical;
    final amountController = TextEditingController(text: '500');
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Confidential Aid Request', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<EmergencyAidCategory>(
                      value: selectedCategory,
                      dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                      items: EmergencyAidCategory.values
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface))))
                          .toList(),
                      onChanged: (val) => setDialogState(() => selectedCategory = val!),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount Needed (ETB)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Explain Situation (Strictly Confidential)'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary))),
                ElevatedButton(
                  onPressed: () {
                    final amt = double.tryParse(amountController.text.trim()) ?? 500.0;
                    if (descController.text.trim().isEmpty) return;
                    widget.state.submitEmergencyAidRequest(
                      category: selectedCategory,
                      description: descController.text.trim(),
                      amountRequested: amt,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Aid application received by committee'), backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryAccent),
                  child: Text('Submit Application', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddCampaignDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '10000');
    String category = 'Student Mutual Aid';
    bool isEmergency = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('🤝 Add Aid Campaign', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Campaign Title (የዘመቻው ርዕስ)')),
                    const SizedBox(height: 8),
                    TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description (ዝርዝር ዓላማ)')),
                    const SizedBox(height: 8),
                    TextField(controller: targetCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Amount ETB (የገንዘብ ግብ)')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: category,
                      dropdownColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'Student Mutual Aid', child: Text('Student Mutual Aid (የተማሪዎች ድጋፍ)')),
                        DropdownMenuItem(value: 'Orphanage Outreach', child: Text('Orphanage Outreach (የሕፃናት ማሳደጊያ)')),
                        DropdownMenuItem(value: 'Hospital Welfare', child: Text('Hospital Welfare (የሕሙማን ድጋፍ)')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => category = val);
                      },
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Emergency Campaign (አስቸኳይ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      value: isEmergency,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppTheme.crimson,
                      onChanged: (val) => setDialogState(() => isEmergency = val),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty || descCtrl.text.trim().isEmpty) return;
                    final targetAmt = double.tryParse(targetCtrl.text.trim()) ?? 10000.0;

                    final newCamp = CharityCampaignModel(
                      id: 'camp-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      description: descCtrl.text.trim(),
                      targetAmount: targetAmt,
                      raisedAmount: 0.0,
                      donorsCount: 0,
                      deadline: DateTime.now().add(const Duration(days: 30)),
                      isEmergency: isEmergency,
                      category: category,
                    );

                    state.addCharityCampaign(newCamp);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Campaign "${newCamp.title}" created successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, foregroundColor: Colors.white),
                  child: const Text('Create Campaign', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAidReviewModal(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final requests = state.emergencyAidRequests;

            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 18,
                right: 18,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.volunteer_activism, color: Color(0xFF10B981), size: 22),
                            const SizedBox(width: 8),
                            Text('Emergency Student Aid Reviews', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: primaryAccent)),
                          ],
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vocational & Charity Coordinator Aid Review Desk. Evaluate and disburse aid to verified applicants.',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: requests.isEmpty
                          ? const Center(child: Text('No emergency aid requests submitted.'))
                          : ListView.builder(
                              itemCount: requests.length,
                              itemBuilder: (c, idx) {
                                final req = requests[idx];
                                final isPending = req.status == EmergencyAidStatus.underReview;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: req.status == EmergencyAidStatus.approved
                                          ? AppTheme.emerald
                                          : req.status == EmergencyAidStatus.declined
                                              ? AppTheme.crimson
                                              : primaryAccent,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '${req.studentName} (${req.studentBaptismalName})',
                                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: theme.cardTheme.color ?? theme.colorScheme.surface,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              req.status.displayName,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: req.status == EmergencyAidStatus.approved
                                                    ? AppTheme.emerald
                                                    : req.status == EmergencyAidStatus.declined
                                                        ? AppTheme.crimson
                                                        : primaryAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Requested: ${req.amountRequested.toStringAsFixed(0)} ETB • Category: ${req.category.displayName}',
                                        style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Need: "${req.description}"',
                                        style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                                      ),
                                      if (req.adminNote != null) ...[
                                        const SizedBox(height: 4),
                                        Text('Coordinator Note: ${req.adminNote}', style: const TextStyle(fontSize: 10, color: AppTheme.emerald)),
                                      ],
                                      if (isPending) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                state.verifyEmergencyAid(req.id, EmergencyAidStatus.declined, adminNote: 'Referred to general dining hall.');
                                                setModalState(() {});
                                              },
                                              child: const Text('Decline', style: TextStyle(color: AppTheme.crimson, fontSize: 11)),
                                            ),
                                            const SizedBox(width: 8),
                                            ElevatedButton(
                                              onPressed: () {
                                                state.verifyEmergencyAid(req.id, EmergencyAidStatus.approved, adminNote: 'Approved & disbursed from Mutual Aid Fund.');
                                                setModalState(() {});
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                                              child: const Text('Approve & Disburse', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
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
