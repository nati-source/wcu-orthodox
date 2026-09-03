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

    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        title: const Text('Pilgrimage & Trips • የንግሥ ጉዞ'),
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
                Expanded(
                  child: _buildNavTab(
                    title: 'Monastery Pilgrimages',
                    icon: Icons.directions_bus,
                    index: 0,
                  ),
                ),
                Expanded(
                  child: _buildNavTab(
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
                ? _buildTripsList(state)
                : _buildMyTicketsList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab({required String title, required IconData icon, required int index}) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppTheme.goldLight : AppTheme.textSecondary),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
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
  // TAB 0: UPCOMING PILGRIMAGES LIST
  // ----------------------------------------------------
  Widget _buildTripsList(FellowshipState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(18),
      itemCount: state.pilgrimageTrips.length,
      itemBuilder: (context, index) {
        final trip = state.pilgrimageTrips[index];
        final isRegistered = state.myTripRegistrations.any((r) => r.tripId == trip.id);

        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: AppTheme.secondaryBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppTheme.borderMuted),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
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
                      const Color(0xFF2B3648),
                      trip.isFree ? const Color(0xFF0F3B2E) : const Color(0xFF382312),
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
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        trip.isFree ? Icons.eco : Icons.explore,
                        color: trip.isFree ? const Color(0xFF10B981) : const Color(0xFFF5A65E),
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
                            style: const TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trip.destination,
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    // Fee / Free Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: trip.isFree ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFF5A65E).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: trip.isFree ? const Color(0xFF10B981) : const Color(0xFFF5A65E),
                        ),
                      ),
                      child: Text(
                        trip.isFree ? 'FREE TRIP' : '${trip.feeAmount.toInt()} ETB',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: trip.isFree ? const Color(0xFF10B981) : const Color(0xFFF5A65E),
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
                    _buildInfoRow(Icons.calendar_today, 'Departure', '${trip.departureDate.year}-${trip.departureDate.month}-${trip.departureDate.day}'),
                    _buildInfoRow(Icons.place, 'Boarding Gate', trip.departurePoint),
                    _buildInfoRow(Icons.event_seat, 'Seats Available', '${trip.availableSeats} of ${trip.totalSeats} seats remaining'),
                    _buildInfoRow(Icons.support_agent, 'Coordinator', '${trip.coordinatorName} (${trip.coordinatorPhone})'),

                    const SizedBox(height: 14),
                    const Text('Itinerary Highlights:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                    const SizedBox(height: 6),
                    ...trip.itinerary.take(2).map((it) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: Color(0xFFF5A65E))),
                              Expanded(child: Text(it, style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary))),
                            ],
                          ),
                        )),

                    const SizedBox(height: 18),
                    const Divider(color: AppTheme.borderMuted),
                    const SizedBox(height: 12),

                    // Payment Accepted Pills (Telebirr & CBE)
                    if (!trip.isFree) ...[
                      const Row(
                        children: [
                          Icon(Icons.payment, size: 14, color: Color(0xFF3B82F6)),
                          SizedBox(width: 6),
                          Text('Accepted Payment Methods: Telebirr & CBE', style: TextStyle(fontSize: 11, color: Color(0xFF93C5FD), fontWeight: FontWeight.w600)),
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
                                backgroundColor: const Color(0xFF1E2838),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () => _openRegistrationModal(context, trip),
                              icon: const Icon(Icons.confirmation_number_outlined, color: Colors.black, size: 18),
                              label: Text(
                                trip.isFree ? 'Register for Free Trip' : 'Register & Pay via Telebirr / CBE',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: trip.isFree ? const Color(0xFF10B981) : const Color(0xFFF5A65E),
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

  Widget _buildInfoRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.goldLight),
          const SizedBox(width: 8),
          Text('$title: ', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
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
  Widget _buildMyTicketsList(FellowshipState state) {
    final tickets = state.myTripRegistrations;

    if (tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.confirmation_number_outlined, size: 60, color: AppTheme.textTertiary),
              const SizedBox(height: 16),
              const Text('No Registered Pilgrimages', style: TextStyle(fontFamily: 'serif', fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 8),
              const Text('Browse upcoming trips and book your seat with Telebirr or CBE payment.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: () => setState(() => _activeTab = 0),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF5A65E)),
                child: const Text('Browse Trips', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
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
            gradient: const LinearGradient(
              colors: [Color(0xFF283446), Color(0xFF1B2332)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.goldAccent.withOpacity(0.5), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
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
                        const Text('WCU FELLOWSHIP PILGRIM PASS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFF5A65E), letterSpacing: 1.2)),
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
                      style: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Dashed divider line
              Container(
                height: 1,
                color: AppTheme.borderMuted,
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
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          Text(
                            'B.N. ${ticket.studentBaptismalName}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFF5A65E)),
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
                            style: const TextStyle(fontSize: 10, color: AppTheme.textTertiary),
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
    PaymentMethodType selectedMethod = trip.isFree ? PaymentMethodType.free : PaymentMethodType.telebirr;
    final refController = TextEditingController(text: trip.isFree ? 'FREE-PASS-WCU' : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceElevated,
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
                          style: const TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E)),
                        ),
                        IconButton(icon: const Icon(Icons.close, color: AppTheme.textSecondary), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      trip.title,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    if (!trip.isFree) ...[
                      // Fee Notice
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.borderMuted),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Pilgrimage Fee:', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                            Text(
                              '${trip.feeAmount.toInt()} ETB',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFF5A65E)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text('Select Payment Method:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),

                      // Telebirr Option
                      RadioListTile<PaymentMethodType>(
                        value: PaymentMethodType.telebirr,
                        groupValue: selectedMethod,
                        activeColor: const Color(0xFFF5A65E),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setModalState(() => selectedMethod = val!),
                        title: const Text('Telebirr (ቴሌብር)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('Send to: ${trip.telebirrNumber} (${trip.telebirrAccountName})', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ),

                      // CBE Option
                      RadioListTile<PaymentMethodType>(
                        value: PaymentMethodType.cbeAccount,
                        groupValue: selectedMethod,
                        activeColor: const Color(0xFFF5A65E),
                        contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setModalState(() => selectedMethod = val!),
                        title: const Text('CBE / Commercial Bank of Ethiopia (ሲቢኢ)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                        subtitle: Text('Acct: ${trip.cbeAccountNumber} (${trip.cbeAccountName})', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
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
                      const Text(
                        'This trip is organized free of charge by the WCU Orthodox Student Fellowship. Your seat will be confirmed immediately.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
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
                              backgroundColor: AppTheme.surfaceColor,
                            ),
                          );
                          setState(() => _activeTab = 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF5A65E),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Confirm Registration', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
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
