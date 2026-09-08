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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: camp.isEmergency ? const Color(0xFFEF4444).withOpacity(0.2) : const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        camp.category,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: camp.isEmergency ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                    ),
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
                    Text(
                      '${camp.raisedAmount.toInt()} ETB raised',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                    ),
                    Text(
                      'Goal: ${camp.targetAmount.toInt()} ETB',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => _openDonateModal(context, camp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('Donate via Telebirr / CBE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.purpose, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                    const SizedBox(height: 2),
                    Text('Ref: ${p.transactionReference}', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                  ],
                ),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.bold)),
              Text(number, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              Text(name, style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ],
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
                  Text(
                    'Confidential Student Emergency Aid',
                    style: TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
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
                label: Text('Apply for Emergency Assistance', style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
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

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Donate to ${camp.title}', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: primaryAccent)),
              const SizedBox(height: 14),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Donation Amount (ETB)', suffixText: 'ETB'),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () {
                  final amt = double.tryParse(amountController.text.trim()) ?? 100.0;
                  widget.state.donateToCharityCampaign(camp.id, amt);
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Donated $amt ETB! May God reward you abundantly.'), backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Confirm Donation via Telebirr', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
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
}
