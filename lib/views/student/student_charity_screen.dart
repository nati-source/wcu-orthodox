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

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text('Mutual Aid & Charity • መረዳጃና ምጽዋት'),
        backgroundColor: AppTheme.primaryBg,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Segmented Navigation Header
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: Row(
              children: [
                Expanded(child: _buildNavButton('Aid Campaigns', Icons.volunteer_activism, 0)),
                Expanded(child: _buildNavButton('Pay Dues (መዋጮ)', Icons.payments_outlined, 1)),
                Expanded(child: _buildNavButton('Request Aid (እርዳታ)', Icons.emergency_outlined, 2)),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 0
                ? _buildCampaignsTab(state)
                : _activeTab == 1
                    ? _buildPayDuesTab(state)
                    : _buildRequestAidTab(state),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton(String title, IconData icon, int index) {
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.surfaceElevated : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: AppTheme.goldAccent.withOpacity(0.5)) : null,
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary),
            const SizedBox(height: 3),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
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
  Widget _buildCampaignsTab(FellowshipState state) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Grand Quote Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF243328), Color(0xFF16241B), AppTheme.secondaryBg],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
          ),
          child: const Row(
            children: [
              Icon(Icons.handshake_outlined, color: Color(0xFF34D399), size: 30),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  '“እርስ በርሳችሁ ሸክማችሁን ተሸካከሙ፤ እንዲሁ የክርስቶስን ሕግ ትፈጽማላችሁ።” — ገላትያ 6፥2',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'ACTIVE FELLOWSHIP DRIVES & AID CAMPAIGNS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 12),

        ...state.charityCampaigns.map((camp) {
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderMuted),
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
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  camp.title,
                  style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 6),
                Text(
                  camp.description,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 14),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: camp.progressPercentage,
                    minHeight: 8,
                    backgroundColor: AppTheme.surfaceColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF5A65E)),
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${camp.raisedAmount.toInt()} ETB raised',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E)),
                    ),
                    Text(
                      'Goal: ${camp.targetAmount.toInt()} ETB',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                ElevatedButton(
                  onPressed: () => _openDonateModal(context, camp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF5A65E),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('Donate via Telebirr / CBE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
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
  Widget _buildPayDuesTab(FellowshipState state) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fellowship Membership Dues (የአባልነት መዋጮ)',
                style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 6),
              const Text(
                'Active students contribute a suggested 50 ETB monthly to sustain Sunday school teaching materials, monastery visits, and mutual student aid.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              _buildAccountInfo('Telebirr', '+251911223344', 'WCU Orthodox Student Fellowship'),
              const SizedBox(height: 8),
              _buildAccountInfo('CBE Account', '1000234567890', 'WCU Orthodox Fellowship'),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: () => _openPayDuesModal(context),
                icon: const Icon(Icons.send_outlined, color: Colors.black, size: 16),
                label: const Text('Submit Dues Payment Receipt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A65E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'PAYMENT HISTORY & RECEIPTS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        ...state.duesPayments.map((p) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.secondaryBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderMuted),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.purpose, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 2),
                    Text('Ref: ${p.transactionReference}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${p.amount.toInt()} ETB', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E))),
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

  Widget _buildAccountInfo(String title, String number, String name) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFFF5A65E), fontWeight: FontWeight.bold)),
              Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(name, style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16, color: AppTheme.goldLight),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Copied $title ($number)'), backgroundColor: AppTheme.surfaceColor),
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
  Widget _buildRequestAidTab(FellowshipState state) {
    final myRequests = state.myEmergencyAidRequests;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderMuted),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lock_clock_outlined, color: Color(0xFFF5A65E), size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Confidential Student Emergency Aid',
                    style: TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Are you facing sudden illness, cafeteria meal crisis, or family emergency? The fellowship mutual aid committee is here for you in strict confidence.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _openAidApplicationDialog(context),
                icon: const Icon(Icons.add_circle_outline, color: Colors.black, size: 18),
                label: const Text('Apply for Emergency Assistance', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A65E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size(double.infinity, 44),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'MY AID APPLICATIONS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textTertiary, letterSpacing: 1.5),
        ),
        const SizedBox(height: 10),

        if (myRequests.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('No active emergency aid applications.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ),
          )
        else
          ...myRequests.map((req) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.secondaryBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: req.status.color.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(req.category.displayName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
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
                  Text('Requested Amount: ${req.amountRequested.toInt()} ETB', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E))),
                  const SizedBox(height: 4),
                  Text(req.description, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  if (req.adminNote != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppTheme.surfaceElevated, borderRadius: BorderRadius.circular(8)),
                      child: Text('Committee Note: ${req.adminNote}', style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
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
    final amountController = TextEditingController(text: '100');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Donate to ${camp.title}', style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E))),
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
                    SnackBar(content: Text('Donated $amt ETB! May God reward you abundantly.'), backgroundColor: AppTheme.surfaceColor),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5A65E),
                  minimumSize: const Size(double.infinity, 44),
                ),
                child: const Text('Confirm Donation via Telebirr', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openPayDuesModal(BuildContext context) {
    final refController = TextEditingController();
    PaymentMethodType method = PaymentMethodType.telebirr;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
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
                  const Text('Submit Monthly Dues (50 ETB)', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E))),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<PaymentMethodType>(
                    value: method,
                    dropdownColor: AppTheme.surfaceElevated,
                    items: [PaymentMethodType.telebirr, PaymentMethodType.cbeAccount]
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName, style: const TextStyle(fontSize: 12))))
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
                        const SnackBar(content: Text('Payment receipt submitted for verification'), backgroundColor: AppTheme.surfaceColor),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF5A65E),
                      minimumSize: const Size(double.infinity, 44),
                    ),
                    child: const Text('Submit Receipt', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
    EmergencyAidCategory selectedCategory = EmergencyAidCategory.medical;
    final amountController = TextEditingController(text: '500');
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text('Confidential Aid Request', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: Color(0xFFF5A65E))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<EmergencyAidCategory>(
                      value: selectedCategory,
                      dropdownColor: AppTheme.surfaceElevated,
                      items: EmergencyAidCategory.values
                          .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName, style: const TextStyle(fontSize: 11))))
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
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
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
                      const SnackBar(content: Text('Aid application received by committee'), backgroundColor: AppTheme.surfaceColor),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A65E)),
                  child: const Text('Submit Application', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
