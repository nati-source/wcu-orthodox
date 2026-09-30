import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentPilgrimageScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentPilgrimageScreen({super.key, required this.state});

  @override
  State<StudentPilgrimageScreen> createState() => _StudentPilgrimageScreenState();
}

class _StudentPilgrimageScreenState extends State<StudentPilgrimageScreen> {
  int _activeTab = 0; // 0: Upcoming Trips, 1: My Pilgrimage Tickets

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pilgrimage & Trips • የንግሥ ጉዞ'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          if (state.canManagePilgrimages) ...[
            IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: Color(0xFF10B981)),
              tooltip: 'Bus Manifest & QR Boarding Scanner',
              onPressed: () => _showBusManifestAndScannerModal(context, state),
            ),
            IconButton(
              icon: Icon(Icons.add_circle_outline, color: primaryAccent),
              tooltip: 'Add New Pilgrimage Trip',
              onPressed: () => _showAddTripDialog(context, state),
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
                Expanded(
                  child: _buildNavTab(
                    context: context,
                    title: 'Monastery Pilgrimages',
                    icon: Icons.directions_bus,
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildNavTab(
                    context: context,
                    title: 'My Digital Passes (${state.myTripRegistrations.length})',
                    icon: Icons.qr_code,
                    index: 1,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _activeTab == 0
                ? _buildTripsList(context, state)
                : _buildMyTicketsList(context, state),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab({required BuildContext context, required String title, required IconData icon, required int index}) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isSelected = _activeTab == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryAccent.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: primaryAccent.withOpacity(0.5)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: isSelected ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 0: UPCOMING PILGRIMAGES LIST
  // ----------------------------------------------------
  Widget _buildTripsList(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: state.pilgrimageTrips.length,
      itemBuilder: (context, index) {
        final trip = state.pilgrimageTrips[index];
        final isRegistered = state.myTripRegistrations.any((r) => r.tripId == trip.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Header Banner
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.surfaceContainerHighest,
                      trip.isFree ? const Color(0xFF0F3B2E) : primaryAccent.withOpacity(0.18),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        trip.isFree ? Icons.eco : Icons.explore,
                        color: trip.isFree ? const Color(0xFF10B981) : primaryAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            trip.title,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trip.destination,
                            style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Fee / Free Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: trip.isFree ? const Color(0xFF10B981).withOpacity(0.2) : primaryAccent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: trip.isFree ? const Color(0xFF10B981) : primaryAccent,
                        ),
                      ),
                      child: Text(
                        trip.isFree ? 'FREE TRIP' : '${trip.feeAmount.toInt()} ETB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: trip.isFree ? const Color(0xFF10B981) : primaryAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Trip Details Body
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(context, Icons.calendar_today, 'Departure', '${trip.departureDate.year}-${trip.departureDate.month}-${trip.departureDate.day}'),
                    _buildInfoRow(context, Icons.place, 'Boarding Gate', trip.departurePoint),
                    _buildInfoRow(context, Icons.event_seat, 'Seats Available', '${trip.availableSeats} of ${trip.totalSeats} seats remaining'),
                    _buildInfoRow(context, Icons.support_agent, 'Coordinator', '${trip.coordinatorName} (${trip.coordinatorPhone})'),

                    const SizedBox(height: 14),
                    Text('Itinerary Highlights:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    ...trip.itinerary.take(2).map((it) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('• ', style: TextStyle(color: primaryAccent)),
                              Expanded(child: Text(it, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface))),
                            ],
                          ),
                        )),

                    const SizedBox(height: 18),
                    Divider(color: theme.dividerColor),
                    const SizedBox(height: 12),

                    // Payment Accepted Pills (Telebirr & CBE)
                    if (!trip.isFree) ...[
                      Row(
                        children: [
                          Icon(Icons.payment, size: 14, color: primaryAccent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Accepted Payment Methods: Telebirr & CBE',
                              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    Row(
                      children: [
                        Expanded(
                          child: isRegistered
                              ? ElevatedButton.icon(
                                  onPressed: () => setState(() => _activeTab = 1),
                                  icon: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                                  label: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text('Registered • View Boarding Pass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                )
                              : ElevatedButton.icon(
                                  onPressed: () => _openRegistrationModal(context, trip),
                                  icon: Icon(Icons.confirmation_number_outlined, color: isDark ? Colors.black : Colors.white, size: 18),
                                  label: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      trip.isFree ? 'Register for Free Trip' : 'Register & Pay via Telebirr / CBE',
                                      style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: trip.isFree ? const Color(0xFF10B981) : primaryAccent,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                ),
                        ),
                        if (state.canManagePilgrimages) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 20),
                            tooltip: 'Delete / Archive Trip',
                            onPressed: () {
                              state.removePilgrimageTrip(trip.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Trip "${trip.title}" deleted.')),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String title, String value) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: primaryAccent),
          const SizedBox(width: 8),
          Text('$title: ', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: MY DIGITAL PASSES & QR CODES
  // ----------------------------------------------------
  Widget _buildMyTicketsList(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final tickets = state.myTripRegistrations;

    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.confirmation_number_outlined, size: 60, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6) ?? AppTheme.textTertiary),
              const SizedBox(height: 16),
              Text('No Registered Pilgrimages', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text('Browse upcoming trips and book your seat with Telebirr or CBE payment.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => setState(() => _activeTab = 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                ),
                child: const Text('Browse Trips', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: primaryAccent.withOpacity(0.5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              // Ticket Header
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'WCU FELLOWSHIP PILGRIM PASS',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.2),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: ticket.paymentStatus.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: ticket.paymentStatus.color),
                          ),
                          child: Text(
                            ticket.paymentStatus.displayName,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: ticket.paymentStatus.color),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      ticket.tripTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),

              // Dashed divider line
              Container(
                height: 1,
                color: theme.dividerColor,
              ),

              // QR Code and Bus/Seat Matrix
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    // Digital Boarding QR
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: ticket.qrTicketCode,
                        version: QrVersions.auto,
                        size: 90.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Pilgrim Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.studentName,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                          Text(
                            'B.N. ${ticket.studentBaptismalName}',
                            style: TextStyle(fontSize: 12, color: primaryAccent),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildPill('Bus #${ticket.busNumber}', const Color(0xFF3B82F6)),
                              _buildPill('Seat #${ticket.seatNumber}', const Color(0xFF10B981)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ref: ${ticket.transactionReference}',
                            style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? AppTheme.textTertiary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  // ----------------------------------------------------
  // REGISTRATION & PAYMENT MODAL (TELEBIRR / CBE)
  // ----------------------------------------------------
  void _openRegistrationModal(BuildContext context, PilgrimageTripModel trip) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;

    PaymentMethodType selectedMethod = trip.isFree ? PaymentMethodType.free : PaymentMethodType.telebirr;
    final refController = TextEditingController(text: trip.isFree ? 'FREE-PASS-WCU' : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            trip.isFree ? 'Free Pilgrimage Registration' : 'Pilgrimage Registration & Payment',
                            style: TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold, color: primaryAccent),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(icon: Icon(Icons.close, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trip.title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                    const SizedBox(height: 16),

                    if (!trip.isFree) ...[
                      // Fee Notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                'Total Pilgrimage Fee:',
                                style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${trip.feeAmount.toInt()} ETB',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryAccent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('Select Payment Method & Send Fee:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                      const SizedBox(height: 8),

                      // Telebirr Option Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: selectedMethod == PaymentMethodType.telebirr ? primaryAccent.withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selectedMethod == PaymentMethodType.telebirr ? primaryAccent : theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<PaymentMethodType>(
                              value: PaymentMethodType.telebirr,
                              groupValue: selectedMethod,
                              activeColor: primaryAccent,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              onChanged: (val) => setModalState(() => selectedMethod = val!),
                              title: Row(
                                children: [
                                  Icon(Icons.phone_android, size: 16, color: primaryAccent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Telebirr (ቴሌብር)',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text('${trip.telebirrNumber} (${trip.telebirrAccountName})', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                            ),
                            if (selectedMethod == PaymentMethodType.telebirr)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                                child: InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: trip.telebirrNumber));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Telebirr number "${trip.telebirrNumber}" copied to clipboard!')),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryAccent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.copy, size: 13, color: primaryAccent),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Copy Telebirr Number (${trip.telebirrNumber})',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      // CBE Option Card
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: selectedMethod == PaymentMethodType.cbeAccount ? primaryAccent.withOpacity(0.08) : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selectedMethod == PaymentMethodType.cbeAccount ? primaryAccent : theme.dividerColor),
                        ),
                        child: Column(
                          children: [
                            RadioListTile<PaymentMethodType>(
                              value: PaymentMethodType.cbeAccount,
                              groupValue: selectedMethod,
                              activeColor: primaryAccent,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                              onChanged: (val) => setModalState(() => selectedMethod = val!),
                              title: Row(
                                children: [
                                  Icon(Icons.account_balance, size: 16, color: primaryAccent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'CBE / Commercial Bank of Ethiopia (ሲቢኢ)',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text('Acct: ${trip.cbeAccountNumber} (${trip.cbeAccountName})', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                            ),
                            if (selectedMethod == PaymentMethodType.cbeAccount)
                              Padding(
                                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                                child: InkWell(
                                  onTap: () {
                                    Clipboard.setData(ClipboardData(text: trip.cbeAccountNumber));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('CBE Account "${trip.cbeAccountNumber}" copied to clipboard!')),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: primaryAccent.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.copy, size: 13, color: primaryAccent),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'Copy CBE Account (${trip.cbeAccountNumber})',
                                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      TextField(
                        controller: refController,
                        decoration: const InputDecoration(
                          labelText: 'Transaction Reference / SMS Code',
                          hintText: 'e.g. TB-982347109 or CBE-829103',
                        ),
                      ),
                    ] else ...[
                      Text(
                        'This trip is organized free of charge by the WCU Orthodox Student Fellowship. Your seat will be confirmed immediately.',
                        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, height: 1.4),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (!trip.isFree && refController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter your transaction reference number')),
                            );
                            return;
                          }

                          widget.state.registerForTrip(
                            tripId: trip.id,
                            paymentMethod: selectedMethod,
                            transactionReference: refController.text.trim().isNotEmpty ? refController.text.trim() : 'FREE-ENTRY',
                          );

                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(trip.isFree ? 'Free seat confirmed! Digital pass generated.' : 'Registration submitted! Awaiting payment verification.'),
                              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
                            ),
                          );
                          setState(() => _activeTab = 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryAccent,
                          foregroundColor: isDark ? Colors.black : Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Confirm Registration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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

  void _showAddTripDialog(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final titleCtrl = TextEditingController();
    final destCtrl = TextEditingController();
    final feeCtrl = TextEditingController(text: '350');
    final departPointCtrl = TextEditingController(text: 'WCU Main Campus Gate');
    final seatsCtrl = TextEditingController(text: '90');
    final telebirrNumCtrl = TextEditingController(text: '+251911223344');
    final telebirrNameCtrl = TextEditingController(text: 'WCU Orthodox Fellowship');
    final cbeAcctCtrl = TextEditingController(text: '1000293848123');
    final cbeNameCtrl = TextEditingController(text: 'WCU Orthodox Student Fellowship');
    bool isFree = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('🚌 Add Pilgrimage Trip', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Trip Title (e.g. ጉዞ ወደ ደብረ ሊባኖስ)')),
                    const SizedBox(height: 8),
                    TextField(controller: destCtrl, decoration: const InputDecoration(labelText: 'Monastery Destination (መዳረሻ ገዳም)')),
                    const SizedBox(height: 8),
                    TextField(controller: departPointCtrl, decoration: const InputDecoration(labelText: 'Departure Location (መነሻ ቦታ)')),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      title: const Text('Free Trip (ነፃ ጉዞ)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      value: isFree,
                      contentPadding: EdgeInsets.zero,
                      activeColor: const Color(0xFF10B981),
                      onChanged: (val) => setDialogState(() => isFree = val),
                    ),
                    if (!isFree) ...[
                      TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Trip Fee in ETB (የጉዞ ዋጋ)')),
                      const SizedBox(height: 8),
                      TextField(controller: telebirrNumCtrl, decoration: const InputDecoration(labelText: 'Telebirr Receiving Number')),
                      const SizedBox(height: 8),
                      TextField(controller: telebirrNameCtrl, decoration: const InputDecoration(labelText: 'Telebirr Receiver Name')),
                      const SizedBox(height: 8),
                      TextField(controller: cbeAcctCtrl, decoration: const InputDecoration(labelText: 'CBE Account Number')),
                      const SizedBox(height: 8),
                      TextField(controller: cbeNameCtrl, decoration: const InputDecoration(labelText: 'CBE Account Holder Name')),
                      const SizedBox(height: 8),
                    ],
                    TextField(controller: seatsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Available Seats (ጠቅላላ ወንበር)')),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty || destCtrl.text.trim().isEmpty) return;
                    final totalSeats = int.tryParse(seatsCtrl.text.trim()) ?? 90;
                    final feeAmt = isFree ? 0.0 : (double.tryParse(feeCtrl.text.trim()) ?? 350.0);

                    final newTrip = PilgrimageTripModel(
                      id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
                      title: titleCtrl.text.trim(),
                      destination: destCtrl.text.trim(),
                      departureDate: DateTime.now().add(const Duration(days: 14)),
                      returnDate: DateTime.now().add(const Duration(days: 15)),
                      departurePoint: departPointCtrl.text.trim(),
                      isFree: isFree,
                      feeAmount: feeAmt,
                      telebirrNumber: telebirrNumCtrl.text.trim().isNotEmpty ? telebirrNumCtrl.text.trim() : '+251911223344',
                      telebirrAccountName: telebirrNameCtrl.text.trim().isNotEmpty ? telebirrNameCtrl.text.trim() : 'WCU Orthodox Fellowship',
                      cbeAccountNumber: cbeAcctCtrl.text.trim().isNotEmpty ? cbeAcctCtrl.text.trim() : '1000293848123',
                      cbeAccountName: cbeNameCtrl.text.trim().isNotEmpty ? cbeNameCtrl.text.trim() : 'WCU Orthodox Student Fellowship',
                      totalSeats: totalSeats,
                      bookedSeats: 0,
                      itinerary: ['5:30 AM - Departure from WCU Gate', '10:00 AM - Arrival & Liturgy', '3:00 PM - Spiritual Teaching & Return'],
                      packingList: ['White Netsela/Gabi', 'Mezmur Book', 'Fasting Food & Water'],
                      coordinatorName: state.currentUser.fullName,
                      coordinatorPhone: state.currentUser.phoneNumber,
                    );

                    state.addPilgrimageTrip(newTrip);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Trip "${newTrip.title}" created successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: primaryAccent, foregroundColor: Colors.white),
                  child: const Text('Create Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBusManifestAndScannerModal(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final scanCodeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allRegs = state.allTripRegistrations;
            final boardedCount = allRegs.where((r) => r.isBoarded).length;

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
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.directions_bus, color: Color(0xFF10B981), size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Bus Boarding & QR Ticket Control',
                                  style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: primaryAccent),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Batch & Programs Coordinator Bus Passenger Letter Control. Scan or enter QR ticket code.',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Quick Boarding Code Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: scanCodeCtrl,
                            decoration: InputDecoration(
                              labelText: 'Scan or Enter QR Ticket Code',
                              hintText: 'e.g. PILGRIM-TRIP-USR01',
                              prefixIcon: const Icon(Icons.qr_code),
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (scanCodeCtrl.text.trim().isEmpty) return;
                            final code = scanCodeCtrl.text.trim();
                            final success = state.scanBusBoardingTicket(code);
                            if (success) {
                              scanCodeCtrl.clear();
                              setModalState(() {});
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ Ticket verified! Passenger boarded.'), backgroundColor: Color(0xFF10B981)),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('❌ Ticket code not found.'), backgroundColor: AppTheme.crimson),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                          child: const Text('Board', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Passenger Stats Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Passenger Manifest (${allRegs.length} total)',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('Boarded: $boardedCount / ${allRegs.length}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Passenger List
                    Expanded(
                      child: allRegs.isEmpty
                          ? const Center(child: Text('No registered passengers found.'))
                          : ListView.builder(
                              itemCount: allRegs.length,
                              itemBuilder: (c, idx) {
                                final reg = allRegs[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: reg.isBoarded ? const Color(0xFF10B981) : theme.dividerColor),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 18,
                                        backgroundColor: reg.isBoarded ? const Color(0xFF10B981).withOpacity(0.2) : theme.colorScheme.surfaceContainerHighest,
                                        child: Icon(
                                          reg.isBoarded ? Icons.check_circle : Icons.person_outline,
                                          size: 18,
                                          color: reg.isBoarded ? const Color(0xFF10B981) : primaryAccent,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${reg.studentName} (${reg.studentBaptismalName})',
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                                            ),
                                            Text(
                                              'Bus #${reg.busNumber} • Seat #${reg.seatNumber} • ${reg.department}',
                                              style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                                            ),
                                            Text(
                                              'Ticket: ${reg.qrTicketCode}',
                                              style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          reg.isBoarded ? Icons.check_box : Icons.check_box_outline_blank,
                                          color: reg.isBoarded ? const Color(0xFF10B981) : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                                        ),
                                        tooltip: 'Toggle Boarded Status',
                                        onPressed: () {
                                          state.togglePassengerBoarded(reg.id);
                                          setModalState(() {});
                                        },
                                      ),
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
