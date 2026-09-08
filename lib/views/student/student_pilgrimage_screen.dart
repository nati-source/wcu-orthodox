import 'package:flutter/material.dart';
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
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryAccent.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: primaryAccent.withOpacity(0.5)) : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? primaryAccent : (theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
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
                          Text('Accepted Payment Methods: Telebirr & CBE', style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      child: isRegistered
                          ? ElevatedButton.icon(
                              onPressed: () => setState(() => _activeTab = 1),
                              icon: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                              label: const Text('Registered • View Boarding Pass', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _openRegistrationModal(context, trip),
                              icon: Icon(Icons.confirmation_number_outlined, color: isDark ? Colors.black : Colors.white, size: 18),
                              label: Text(
                                trip.isFree ? 'Register for Free Trip' : 'Register & Pay via Telebirr / CBE',
                                style: TextStyle(color: isDark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: trip.isFree ? const Color(0xFF10B981) : primaryAccent,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
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
                        Text('WCU FELLOWSHIP PILGRIM PASS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.2)),
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
                          Row(
                            children: [
                              _buildPill('Bus #${ticket.busNumber}', const Color(0xFF3B82F6)),
                              const SizedBox(width: 6),
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
                        Text(
                          trip.isFree ? 'Free Pilgrimage Registration' : 'Pilgrimage Registration & Payment',
                          style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: primaryAccent),
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
                            Text('Total Pilgrimage Fee:', style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                            Text(
                              '${trip.feeAmount.toInt()} ETB',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryAccent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      Text('Select Payment Method:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                      const SizedBox(height: 8),

                      // Telebirr Option
                      RadioListTile<PaymentMethodType>(
                        value: PaymentMethodType.telebirr,
                        groupValue: selectedMethod,
                        activeColor: primaryAccent,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setModalState(() => selectedMethod = val!),
                        title: Text('Telebirr (ቴሌብር)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        subtitle: Text('Send to: ${trip.telebirrNumber} (${trip.telebirrAccountName})', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                      ),

                      // CBE Option
                      RadioListTile<PaymentMethodType>(
                        value: PaymentMethodType.cbeAccount,
                        groupValue: selectedMethod,
                        activeColor: primaryAccent,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setModalState(() => selectedMethod = val!),
                        title: Text('CBE / Commercial Bank of Ethiopia (ሲቢኢ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        subtitle: Text('Acct: ${trip.cbeAccountNumber} (${trip.cbeAccountName})', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
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
}
