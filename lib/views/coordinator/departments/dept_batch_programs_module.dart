part of '../coordinator_hub_screen.dart';

extension DeptBatchProgramsModuleExt on _CoordinatorHubScreenState {
  Widget _buildBatchProgramsModule(BuildContext context, FellowshipState state, bool isAudit) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final trips = state.pilgrimageTrips;
    final allRegistrations = state.allTripRegistrations;

    // Filter registrations based on selected trip, status filter, and search query
    final filteredRegistrations = allRegistrations.where((r) {
      if (_selectedTripFilter != null && r.tripId != _selectedTripFilter) {
        return false;
      }
      if (_pilgrimFilter == 'Pending Approval' && r.paymentStatus != TripPaymentStatus.pendingVerification) {
        return false;
      }
      if (_pilgrimFilter == 'Verified' && r.paymentStatus != TripPaymentStatus.verified && r.paymentStatus != TripPaymentStatus.free) {
        return false;
      }
      if (_pilgrimFilter == 'Declined' && r.paymentStatus != TripPaymentStatus.rejected) {
        return false;
      }
      if (_pilgrimSearch.isNotEmpty) {
        final q = _pilgrimSearch.toLowerCase();
        final matchName = r.studentName.toLowerCase().contains(q);
        final matchBap = r.studentBaptismalName.toLowerCase().contains(q);
        final matchPhone = r.studentPhone.toLowerCase().contains(q);
        final matchRef = r.transactionReference.toLowerCase().contains(q);
        final matchTrip = r.tripTitle.toLowerCase().contains(q);
        if (!matchName && !matchBap && !matchPhone && !matchRef && !matchTrip) {
          return false;
        }
      }
      return true;
    }).toList();

    final pendingCount = allRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.pendingVerification).length;
    final verifiedCount = allRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.verified || r.paymentStatus == TripPaymentStatus.free).length;
    final rejectedCount = allRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.rejected).length;

    // Financial Calculation for Pilgrimages
    final totalExpectedRevenue = trips.fold<double>(0.0, (sum, t) => sum + (t.totalSeats * t.feeAmount));
    final totalVerifiedRevenue = allRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.verified).fold<double>(0.0, (sum, r) => sum + r.feeAmount);
    final totalPendingRevenue = allRegistrations.where((r) => r.paymentStatus == TripPaymentStatus.pendingVerification).fold<double>(0.0, (sum, r) => sum + r.feeAmount);
    final collectionProgress = totalExpectedRevenue > 0 ? (totalVerifiedRevenue / totalExpectedRevenue).clamp(0.0, 1.0) : 0.0;

    // Payment channel breakdown
    final telebirrAmount = allRegistrations.where((r) => r.paymentMethod == PaymentMethodType.telebirr && r.paymentStatus == TripPaymentStatus.verified).fold<double>(0.0, (s, r) => s + r.feeAmount);
    final cbeAmount = allRegistrations.where((r) => r.paymentMethod == PaymentMethodType.cbeBirr && r.paymentStatus == TripPaymentStatus.verified).fold<double>(0.0, (s, r) => s + r.feeAmount);
    final cashAmount = allRegistrations.where((r) => r.paymentMethod == PaymentMethodType.cash && r.paymentStatus == TripPaymentStatus.verified).fold<double>(0.0, (s, r) => s + r.feeAmount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Pilgrimage Financial / Money Controlling Dashboard Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryAccent.withOpacity(0.16),
                theme.cardTheme.color ?? theme.colorScheme.surface,
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
                        Icon(Icons.account_balance_wallet_outlined, color: primaryAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Pilgrimage Treasury & Money Control • የጉዞ በጀትና ካዝና',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
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
                      color: const Color(0xFF10B981).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Live Treasury', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Verified Collected',
                      amount: '${totalVerifiedRevenue.toStringAsFixed(0)} ETB',
                      color: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Pending Verification',
                      amount: '${totalPendingRevenue.toStringAsFixed(0)} ETB',
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinancialSubTile(
                      context,
                      label: 'Target Budget',
                      amount: '${totalExpectedRevenue.toStringAsFixed(0)} ETB',
                      color: primaryAccent,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Collection Progress Indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: collectionProgress,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryAccent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text('Progress: ${(collectionProgress * 100).toStringAsFixed(1)}% Collected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text('${allRegistrations.length} Total Registered', style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Payment Channels Breakdown
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMiniBadge(context, 'Telebirr: ${telebirrAmount.toStringAsFixed(0)} ETB', const Color(0xFF3B82F6)),
                    const SizedBox(width: 6),
                    _buildMiniBadge(context, 'CBE Birr: ${cbeAmount.toStringAsFixed(0)} ETB', const Color(0xFF8B5CF6)),
                    const SizedBox(width: 6),
                    _buildMiniBadge(context, 'Cash: ${cashAmount.toStringAsFixed(0)} ETB', const Color(0xFF10B981)),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 2. Action Toolbar: Scan Passes, Add New Trip & Add Pilgrim Student
        if (!isAudit) ...[
          // Prominent Pilgrim QR Scanner Button for Batch & Programs Coordinator
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentQrScannerScreen(state: state, initialMode: 1),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_scanner, size: 20, color: Colors.white),
              label: const Text(
                'Scan Pilgrim Passes & Bus Boarding • ትኬት ቃኝ',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
                shadowColor: const Color(0xFF10B981).withOpacity(0.4),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openAddPilgrimageTripModal(context, state),
                  icon: const Icon(Icons.add_location_alt, size: 16, color: Colors.white),
                  label: const Text('Add Pilgrimage Trip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openAddPilgrimStudentModal(context, state),
                  icon: Icon(Icons.person_add_alt_1, size: 16, color: primaryAccent),
                  label: Text('Register Pilgrim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: primaryAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ],

        // 3. Active Pilgrimage Trips List (with Edit & Delete)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'ACTIVE PILGRIMAGE TRIPS (${trips.length})',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (trips.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Text('No active trips created. Tap "Add Pilgrimage Trip" above.', style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
          )
        else
          ...trips.map((trip) {
            final tripRegs = allRegistrations.where((r) => r.tripId == trip.id).toList();
            final tripVerified = tripRegs.where((r) => r.paymentStatus == TripPaymentStatus.verified).fold<double>(0.0, (s, r) => s + r.feeAmount);
            final isFilterActive = _selectedTripFilter == trip.id;

            return InteractiveFellowshipCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: isFilterActive ? primaryAccent : primaryAccent.withOpacity(0.3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          trip.title,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primaryAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          trip.isFree ? 'Free Trip' : '${trip.feeAmount.toStringAsFixed(0)} ETB',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primaryAccent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Monastery: ${trip.destination} • Date: ${trip.departureDate.year}-${trip.departureDate.month}-${trip.departureDate.day}',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          'Booked: ${trip.bookedSeats} / ${trip.totalSeats} Seats • ${tripRegs.length} Registered',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: primaryAccent),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Collected: ${tripVerified.toStringAsFixed(0)} ETB',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Filter shortcut button
                      Flexible(
                        child: TextButton.icon(
                          onPressed: () {
                            _updateUi(() {
                              if (_selectedTripFilter == trip.id) {
                                _selectedTripFilter = null;
                              } else {
                                _selectedTripFilter = trip.id;
                              }
                            });
                          },
                          icon: Icon(isFilterActive ? Icons.filter_alt_off : Icons.filter_alt, size: 14),
                          label: Text(
                            isFilterActive ? 'Show All Trips' : 'View Passengers (${tripRegs.length})',
                            style: const TextStyle(fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (!isAudit)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                              tooltip: 'Delete Trip',
                              onPressed: () {
                                _confirmDeleteDialog(
                                  context,
                                  title: 'Delete Pilgrimage Trip',
                                  message: 'Are you sure you want to delete "${trip.title}" and cancel all its registered tickets?',
                                  onConfirm: () {
                                    state.removePilgrimageTrip(trip.id);
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trip "${trip.title}" removed.')));
                                  },
                                );
                              },
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _openEditTripModal(context, state, trip),
                              icon: const Icon(Icons.edit, size: 12),
                              label: const Text('Edit Trip', style: TextStyle(fontSize: 11)),
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6)),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 18),

        // 4. Interactive Approvals & Passenger Roster with Filters & Search
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'PILGRIMS APPROVALS & PASSENGER ROSTER',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: primaryAccent, letterSpacing: 1.1),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Search Bar for Pilgrims
        TextField(
          decoration: InputDecoration(
            hintText: 'Search by passenger, baptismal name, phone or ref...',
            hintStyle: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _pilgrimSearch.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 16),
                    onPressed: () => _updateUi(() => _pilgrimSearch = ''),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            filled: true,
            fillColor: theme.cardTheme.color ?? theme.colorScheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor)),
          ),
          onChanged: (val) => _updateUi(() => _pilgrimSearch = val.trim()),
        ),
        const SizedBox(height: 10),

        // Filter Tabs with Crisp, High-Definition Segmented Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildPilgrimStatusFilterPill(
                context: context,
                label: 'All',
                count: allRegistrations.length,
                filterKey: 'All',
                activeColor: primaryAccent,
                icon: Icons.people_alt_outlined,
              ),
              const SizedBox(width: 8),
              _buildPilgrimStatusFilterPill(
                context: context,
                label: 'Pending Approval',
                count: pendingCount,
                filterKey: 'Pending Approval',
                activeColor: const Color(0xFFF59E0B), // Sharp Amber
                icon: Icons.hourglass_top_rounded,
              ),
              const SizedBox(width: 8),
              _buildPilgrimStatusFilterPill(
                context: context,
                label: 'Verified',
                count: verifiedCount,
                filterKey: 'Verified',
                activeColor: const Color(0xFF10B981), // Sharp Emerald Green
                icon: Icons.check_circle_rounded,
              ),
              const SizedBox(width: 8),
              _buildPilgrimStatusFilterPill(
                context: context,
                label: 'Declined',
                count: rejectedCount,
                filterKey: 'Declined',
                activeColor: const Color(0xFFEF4444), // Sharp Crimson Red
                icon: Icons.cancel_rounded,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        if (filteredRegistrations.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No pilgrim registrations found for the selected filter.',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
            ),
          )
        else
          ...filteredRegistrations.map((reg) {
            final isPending = reg.paymentStatus == TripPaymentStatus.pendingVerification;
            final isVerified = reg.paymentStatus == TripPaymentStatus.verified || reg.paymentStatus == TripPaymentStatus.free;
            final isRejected = reg.paymentStatus == TripPaymentStatus.rejected;
            final isDark = theme.brightness == Brightness.dark;

            final Color statusColor = isVerified
                ? const Color(0xFF10B981)
                : isPending
                    ? const Color(0xFFF59E0B)
                    : const Color(0xFFEF4444);
            final IconData statusIcon = isVerified
                ? Icons.check_circle_rounded
                : isPending
                    ? Icons.hourglass_top_rounded
                    : Icons.cancel_rounded;
            final String statusLabel = isVerified
                ? 'Verified'
                : isPending
                    ? 'Pending'
                    : 'Declined';

            return InteractiveFellowshipCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderColor: isPending ? const Color(0xFFF59E0B).withOpacity(0.6) : theme.dividerColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: statusColor.withOpacity(isDark ? 0.22 : 0.12),
                          border: Border.all(color: statusColor, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          reg.studentName.isNotEmpty ? reg.studentName[0] : 'P',
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reg.studentName,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'B.N. ${reg.studentBaptismalName} • Bus #${reg.busNumber} Seat #${reg.seatNumber}',
                              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Trip: ${reg.tripTitle}',
                              style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: statusColor, width: 1.3),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(statusIcon, size: 12, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reg.feeAmount.toStringAsFixed(0)} ETB',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.tag, size: 12, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Ref: ${reg.transactionReference} (${reg.paymentMethod.displayName})',
                            style: TextStyle(fontSize: 10, fontFamily: 'monospace', color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: reg.transactionReference));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction Ref copied!')));
                          },
                          child: Icon(Icons.copy, size: 12, color: primaryAccent),
                        ),
                      ],
                    ),
                  ),

                  // Actions row (Verify, Reject, View Ticket, Edit, Delete)
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.end,
                    children: [
                      // View E-Ticket button
                      OutlinedButton.icon(
                        onPressed: () => _openPilgrimTicketModal(context, state, reg),
                        icon: const Icon(Icons.qr_code, size: 12),
                        label: const Text('E-Ticket', style: TextStyle(fontSize: 11)),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                      ),
                      if (!isAudit) ...[
                        // Edit Passenger Details
                        OutlinedButton.icon(
                          onPressed: () => _openEditPilgrimStudentModal(context, state, reg),
                          icon: const Icon(Icons.edit, size: 12),
                          label: const Text('Edit / Seat', style: TextStyle(fontSize: 11)),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                        ),
                        // Delete / Cancel Ticket
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.crimson, size: 18),
                          tooltip: 'Cancel Pilgrim Ticket',
                          onPressed: () {
                            _confirmDeleteDialog(
                              context,
                              title: 'Cancel Pilgrim Ticket',
                              message: 'Are you sure you want to cancel ticket for ${reg.studentName}?',
                              onConfirm: () {
                                state.deletePilgrimRegistration(reg.id);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pilgrim ${reg.studentName} removed.')));
                              },
                            );
                          },
                        ),
                        if (isPending) ...[
                          OutlinedButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              state.verifyTripPayment(reg.id, false);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment for ${reg.studentName} marked as invalid.')));
                            },
                            style: OutlinedButton.styleFrom(foregroundColor: AppTheme.crimson, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4)),
                            child: const Text('Reject', style: TextStyle(fontSize: 11)),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              state.verifyTripPayment(reg.id, true);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment verified & Boarding pass issued to ${reg.studentName}')));
                            },
                            icon: const Icon(Icons.check, size: 12, color: Colors.white),
                            label: const Text('Verify & Issue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                          ),
                        ],
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

  // --------------------------------------------------------------------------
  // DEPARTMENT 7: ሙያና በጎ አድራጎት (CHARITY & VOCATIONAL ACTIVITIES)
  // Dedicated to: Interactive Charity Campaigns, Donations Inflow, Aid Disbursements Outflow & Treasury Control
  // --------------------------------------------------------------------------

  Widget _buildPilgrimStatusFilterPill({
    required BuildContext context,
    required String label,
    required int count,
    required String filterKey,
    required Color activeColor,
    required IconData icon,
  }) {
    final isSelected = _pilgrimFilter == filterKey;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        _updateUi(() => _pilgrimFilter = filterKey);
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
                color: isSelected
                    ? (isDark ? activeColor : activeColor)
                    : (theme.colorScheme.onSurface),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : activeColor.withOpacity(0.18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: isSelected
                      ? Colors.white
                      : activeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _openAddPilgrimageTripModal(BuildContext context, FellowshipState state) {
    final titleCtrl = TextEditingController();
    final monasteryCtrl = TextEditingController();
    final dateCtrl = TextEditingController(text: 'Ginbot 21 (May 29)');
    final feeCtrl = TextEditingController(text: '350');
    final seatsCtrl = TextEditingController(text: '90');
    final telebirrNumCtrl = TextEditingController(text: '+251911223344');
    final telebirrNameCtrl = TextEditingController(text: 'WCU Orthodox Fellowship');
    final cbeAcctCtrl = TextEditingController(text: '1000293848123');
    final cbeNameCtrl = TextEditingController(text: 'WCU Orthodox Student Fellowship');
    final descCtrl = TextEditingController();

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
                Text('Add New Pilgrimage Trip • አዲስ መንፈሳዊ ጉዞ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 14),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Trip Title (e.g. ወልዲባ ገዳም መንፈሳዊ ጉዞ)')),
                const SizedBox(height: 10),
                TextField(controller: monasteryCtrl, decoration: const InputDecoration(labelText: 'Destination Monastery / Church')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fee per Seat (ETB)'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: seatsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Seat Capacity'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Departure Date & Schedule')),
                const SizedBox(height: 12),
                
                // Telebirr & CBE Payment Receiving Accounts (For Coordinator Setup)
                const Text('Payment Receiving Accounts (የክፍያ መቀበያ ሂሳቦች):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: telebirrNumCtrl, decoration: const InputDecoration(labelText: 'Telebirr Phone No.'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: telebirrNameCtrl, decoration: const InputDecoration(labelText: 'Telebirr Name'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: cbeAcctCtrl, decoration: const InputDecoration(labelText: 'CBE Account No.'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: cbeNameCtrl, decoration: const InputDecoration(labelText: 'CBE Holder Name'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Itinerary & Guidelines')),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (titleCtrl.text.trim().isEmpty) return;
                      final fee = double.tryParse(feeCtrl.text.trim()) ?? 350.0;
                      final newTrip = PilgrimageTripModel(
                        id: 'trip-${DateTime.now().millisecondsSinceEpoch}',
                        title: titleCtrl.text.trim(),
                        destination: monasteryCtrl.text.trim().isEmpty ? 'Holy Monastery' : monasteryCtrl.text.trim(),
                        departureDate: DateTime.now().add(const Duration(days: 14)),
                        returnDate: DateTime.now().add(const Duration(days: 15)),
                        departurePoint: 'WCU Campus Main Gate',
                        feeAmount: fee,
                        isFree: fee <= 0,
                        telebirrNumber: telebirrNumCtrl.text.trim().isNotEmpty ? telebirrNumCtrl.text.trim() : '+251911223344',
                        telebirrAccountName: telebirrNameCtrl.text.trim().isNotEmpty ? telebirrNameCtrl.text.trim() : 'WCU Orthodox Fellowship',
                        cbeAccountNumber: cbeAcctCtrl.text.trim().isNotEmpty ? cbeAcctCtrl.text.trim() : '1000293848123',
                        cbeAccountName: cbeNameCtrl.text.trim().isNotEmpty ? cbeNameCtrl.text.trim() : 'WCU Orthodox Student Fellowship',
                        totalSeats: int.tryParse(seatsCtrl.text.trim()) ?? 90,
                        bookedSeats: 0,
                        itinerary: [descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Liturgy & spiritual blessing'],
                        packingList: ['Netela (ነጠላ)', 'Prayer Book', 'Student Fellowship ID'],
                        coordinatorName: state.currentUser.fullName,
                        coordinatorPhone: state.currentUser.phoneNumber,
                      );
                      state.addPilgrimageTrip(newTrip);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pilgrimage Trip "${newTrip.title}" created successfully!')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
                    child: const Text('Publish Pilgrimage Trip', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. Edit Pilgrimage Trip Modal
  void _openEditTripModal(BuildContext context, FellowshipState state, PilgrimageTripModel trip) {
    final titleCtrl = TextEditingController(text: trip.title);
    final monasteryCtrl = TextEditingController(text: trip.destination);
    final feeCtrl = TextEditingController(text: trip.feeAmount.toStringAsFixed(0));
    final seatsCtrl = TextEditingController(text: trip.totalSeats.toString());
    final dateCtrl = TextEditingController(text: '${trip.departureDate.year}-${trip.departureDate.month}-${trip.departureDate.day}');
    final telebirrNumCtrl = TextEditingController(text: trip.telebirrNumber);
    final telebirrNameCtrl = TextEditingController(text: trip.telebirrAccountName);
    final cbeAcctCtrl = TextEditingController(text: trip.cbeAccountNumber);
    final cbeNameCtrl = TextEditingController(text: trip.cbeAccountName);

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
                Text('Edit Pilgrimage Details • የጉዞ መረጃ ማስተካከያ', style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                const SizedBox(height: 14),
                TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Trip Title')),
                const SizedBox(height: 10),
                TextField(controller: monasteryCtrl, decoration: const InputDecoration(labelText: 'Destination Monastery')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: feeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fee (ETB)'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: seatsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total Seats'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(controller: dateCtrl, decoration: const InputDecoration(labelText: 'Departure Date')),
                const SizedBox(height: 12),
                
                // Telebirr & CBE Payment Receiving Accounts
                const Text('Payment Receiving Accounts (የክፍያ መቀበያ ሂሳቦች):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: TextField(controller: telebirrNumCtrl, decoration: const InputDecoration(labelText: 'Telebirr Phone No.'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: telebirrNameCtrl, decoration: const InputDecoration(labelText: 'Telebirr Name'))),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(child: TextField(controller: cbeAcctCtrl, decoration: const InputDecoration(labelText: 'CBE Account No.'))),
                    const SizedBox(width: 10),
                    Expanded(child: TextField(controller: cbeNameCtrl, decoration: const InputDecoration(labelText: 'CBE Holder Name'))),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final updated = trip.copyWith(
                        title: titleCtrl.text.trim(),
                        destination: monasteryCtrl.text.trim(),
                        feeAmount: double.tryParse(feeCtrl.text.trim()) ?? trip.feeAmount,
                        totalSeats: int.tryParse(seatsCtrl.text.trim()) ?? trip.totalSeats,
                        telebirrNumber: telebirrNumCtrl.text.trim().isNotEmpty ? telebirrNumCtrl.text.trim() : trip.telebirrNumber,
                        telebirrAccountName: telebirrNameCtrl.text.trim().isNotEmpty ? telebirrNameCtrl.text.trim() : trip.telebirrAccountName,
                        cbeAccountNumber: cbeAcctCtrl.text.trim().isNotEmpty ? cbeAcctCtrl.text.trim() : trip.cbeAccountNumber,
                        cbeAccountName: cbeNameCtrl.text.trim().isNotEmpty ? cbeNameCtrl.text.trim() : trip.cbeAccountName,
                      );
                      state.updatePilgrimageTrip(updated);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Trip "${updated.title}" updated.')));
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
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

  // 3. Register Pilgrim Student Modal (Add User Pilgrimage Details)
  void _openAddPilgrimStudentModal(BuildContext context, FellowshipState state) {
    if (state.pilgrimageTrips.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add a pilgrimage trip first!')));
      return;
    }

    String selectedTripId = (_selectedTripFilter != null && state.pilgrimageTrips.any((t) => t.id == _selectedTripFilter))
        ? _selectedTripFilter!
        : state.pilgrimageTrips.first.id;
    final nameCtrl = TextEditingController();
    final baptismalCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final deptCtrl = TextEditingController(text: 'Engineering');
    final refCtrl = TextEditingController(text: 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    PaymentMethodType selectedMethod = PaymentMethodType.telebirr;
    int busNo = 1;
    int seatNo = 12;
    UserModel? selectedStudent;

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
                        Icon(Icons.person_add_alt_1_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Register Pilgrim Student • ተጓዥ መመዝገቢያ',
                            style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Quick Fill from existing registered students dropdown
                    if (state.allStudents.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: selectedStudent?.id,
                        isExpanded: true,
                        hint: const Text('Quick-fill from Fellowship Students (ተማሪ ይምረጡ)', style: TextStyle(fontSize: 12)),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Manual Entry (በእጅ አስገባ)', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                          ),
                          ...state.allStudents.map((s) => DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(
                              '${s.fullName} (${s.baptismalName}) - ${s.phoneNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          )),
                        ],
                        onChanged: (sId) {
                          if (sId == null) {
                            setMState(() => selectedStudent = null);
                          } else {
                            final found = state.allStudents.firstWhere((s) => s.id == sId);
                            setMState(() {
                              selectedStudent = found;
                              nameCtrl.text = found.fullName;
                              baptismalCtrl.text = found.baptismalName;
                              phoneCtrl.text = found.phoneNumber;
                              deptCtrl.text = found.department;
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Select Registered Student (Optional)',
                          prefixIcon: Icon(Icons.people_outline, size: 18),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Select Pilgrimage Trip Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedTripId,
                      isExpanded: true,
                      items: state.pilgrimageTrips.map((t) => DropdownMenuItem(
                        value: t.id,
                        child: Text(
                          t.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      )).toList(),
                      onChanged: (val) {
                        if (val != null) setMState(() => selectedTripId = val);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select Pilgrimage Trip',
                        prefixIcon: Icon(Icons.place_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Student Full Name *', prefixIcon: Icon(Icons.person_outline, size: 18))),
                    const SizedBox(height: 10),
                    TextField(controller: baptismalCtrl, decoration: const InputDecoration(labelText: 'Baptismal Name (የክርስትና ስም)', prefixIcon: Icon(Icons.church_outlined, size: 18))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined, size: 18)))),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: deptCtrl, decoration: const InputDecoration(labelText: 'Academic Dept', prefixIcon: Icon(Icons.school_outlined, size: 18)))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: busNo,
                            isExpanded: true,
                            items: [1, 2, 3, 4, 5].map((b) => DropdownMenuItem(value: b, child: Text('Bus #$b'))).toList(),
                            onChanged: (val) {
                              if (val != null) setMState(() => busNo = val);
                            },
                            decoration: const InputDecoration(labelText: 'Assigned Bus', prefixIcon: Icon(Icons.directions_bus_outlined, size: 18)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: seatNo,
                            isExpanded: true,
                            items: List.generate(50, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text('Seat #$s'))).toList(),
                            onChanged: (val) {
                              if (val != null) setMState(() => seatNo = val);
                            },
                            decoration: const InputDecoration(labelText: 'Seat Number', prefixIcon: Icon(Icons.event_seat_outlined, size: 18)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<PaymentMethodType>(
                      value: selectedMethod,
                      isExpanded: true,
                      items: [PaymentMethodType.telebirr, PaymentMethodType.cbeBirr, PaymentMethodType.cash, PaymentMethodType.free]
                          .map((m) => DropdownMenuItem(value: m, child: Text(m.displayName, maxLines: 1, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setMState(() => selectedMethod = val);
                      },
                      decoration: const InputDecoration(labelText: 'Payment Method', prefixIcon: Icon(Icons.payment_outlined, size: 18)),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Transaction Ref / Receipt Code', prefixIcon: Icon(Icons.receipt_long_outlined, size: 18))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter or select student full name!')));
                            return;
                          }
                          final trip = state.pilgrimageTrips.firstWhere(
                            (t) => t.id == selectedTripId,
                            orElse: () => state.pilgrimageTrips.first,
                          );
                          final tripPrefix = trip.id.length >= 4 ? trip.id.substring(0, 4).toUpperCase() : trip.id.toUpperCase();
                          final newReg = TripRegistrationModel(
                            id: 'reg-${DateTime.now().millisecondsSinceEpoch}',
                            tripId: trip.id,
                            tripTitle: trip.title,
                            studentId: selectedStudent?.id ?? () {
                              final inPhone = phoneCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');
                              final inName = name.toLowerCase();
                              for (final s in state.allStudents) {
                                final sP = s.phoneNumber.trim().replaceAll(RegExp(r'[^0-9]'), '');
                                if ((inPhone.isNotEmpty && sP.isNotEmpty && (inPhone == sP || (inPhone.length >= 9 && sP.length >= 9 && inPhone.substring(inPhone.length - 9) == sP.substring(sP.length - 9)))) || (s.fullName.trim().toLowerCase() == inName)) {
                                  return s.id;
                                }
                              }
                              return 'stud-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
                            }(),
                            studentName: name,
                            studentBaptismalName: baptismalCtrl.text.trim().isEmpty ? 'Walda Maryam' : baptismalCtrl.text.trim(),
                            studentPhone: phoneCtrl.text.trim().isEmpty ? '0911002233' : phoneCtrl.text.trim(),
                            department: deptCtrl.text.trim().isEmpty ? 'Engineering' : deptCtrl.text.trim(),
                            academicYear: selectedStudent?.academicYear ?? 3,
                            busNumber: busNo,
                            seatNumber: seatNo,
                            feeAmount: trip.feeAmount,
                            isFree: trip.isFree,
                            paymentMethod: selectedMethod,
                            transactionReference: refCtrl.text.trim().isEmpty ? 'TB-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}' : refCtrl.text.trim(),
                            paymentStatus: TripPaymentStatus.verified,
                            qrTicketCode: 'PILGRIM-$tripPrefix-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                            registeredAt: DateTime.now(),
                          );
                          state.addPilgrimRegistration(newReg);
                          _updateUi(() {
                            _selectedTripFilter = trip.id;
                            _pilgrimFilter = 'All';
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Pilgrim ${newReg.studentName} registered for Bus #$busNo Seat #$seatNo!')));
                        },
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        label: const Text('Confirm Pilgrim Registration', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
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

  // 4. Edit Pilgrim Student Modal (Change Seat, Bus, Payment Status)
  void _openEditPilgrimStudentModal(BuildContext context, FellowshipState state, TripRegistrationModel reg) {
    final nameCtrl = TextEditingController(text: reg.studentName);
    final baptismalCtrl = TextEditingController(text: reg.studentBaptismalName);
    final phoneCtrl = TextEditingController(text: reg.studentPhone);
    final refCtrl = TextEditingController(text: reg.transactionReference);
    int busNo = reg.busNumber;
    int seatNo = reg.seatNumber;
    TripPaymentStatus status = reg.paymentStatus;

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
                        Icon(Icons.edit_note_rounded, color: Theme.of(context).colorScheme.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Edit Pilgrim Passenger & Seat • ተጓዥ ማስተካከያ',
                            style: TextStyle(fontFamily: 'serif', fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Student Name', prefixIcon: Icon(Icons.person_outline, size: 18))),
                    const SizedBox(height: 10),
                    TextField(controller: baptismalCtrl, decoration: const InputDecoration(labelText: 'Baptismal Name', prefixIcon: Icon(Icons.church_outlined, size: 18))),
                    const SizedBox(height: 10),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined, size: 18))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: busNo,
                            isExpanded: true,
                            items: [1, 2, 3, 4, 5].map((b) => DropdownMenuItem(value: b, child: Text('Bus #$b'))).toList(),
                            onChanged: (val) {
                              if (val != null) setMState(() => busNo = val);
                            },
                            decoration: const InputDecoration(labelText: 'Bus #', prefixIcon: Icon(Icons.directions_bus_outlined, size: 18)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: seatNo,
                            isExpanded: true,
                            items: List.generate(50, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text('Seat #$s'))).toList(),
                            onChanged: (val) {
                              if (val != null) setMState(() => seatNo = val);
                            },
                            decoration: const InputDecoration(labelText: 'Seat #', prefixIcon: Icon(Icons.event_seat_outlined, size: 18)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<TripPaymentStatus>(
                      value: status,
                      isExpanded: true,
                      items: [TripPaymentStatus.verified, TripPaymentStatus.pendingVerification, TripPaymentStatus.rejected, TripPaymentStatus.free]
                          .map((s) => DropdownMenuItem(value: s, child: Text(s.displayName, maxLines: 1, overflow: TextOverflow.ellipsis)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setMState(() => status = val);
                      },
                      decoration: const InputDecoration(labelText: 'Payment Status', prefixIcon: Icon(Icons.verified_outlined, size: 18)),
                    ),
                    const SizedBox(height: 10),
                    TextField(controller: refCtrl, decoration: const InputDecoration(labelText: 'Transaction Ref', prefixIcon: Icon(Icons.receipt_long_outlined, size: 18))),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final updated = reg.copyWith(
                            studentName: nameCtrl.text.trim(),
                            studentBaptismalName: baptismalCtrl.text.trim(),
                            studentPhone: phoneCtrl.text.trim(),
                            busNumber: busNo,
                            seatNumber: seatNo,
                            paymentStatus: status,
                            transactionReference: refCtrl.text.trim(),
                          );
                          state.updatePilgrimRegistration(updated);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Passenger record for ${updated.studentName} updated.')));
                        },
                        icon: const Icon(Icons.save_outlined, size: 16, color: Colors.white),
                        label: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
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

  // 5. Pilgrim Digital E-Ticket & Receipt Modal
  void _openPilgrimTicketModal(BuildContext context, FellowshipState state, TripRegistrationModel reg) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.confirmation_number_outlined, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Pilgrim E-Ticket Pass', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: reg.qrTicketCode,
                        version: QrVersions.auto,
                        size: 110,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reg.qrTicketCode,
                        style: const TextStyle(
                          fontSize: 10,
                          fontFamily: 'monospace',
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildTicketDetailRow('Passenger:', reg.studentName),
              _buildTicketDetailRow('Baptismal Name:', reg.studentBaptismalName),
              _buildTicketDetailRow('Trip Title:', reg.tripTitle),
              _buildTicketDetailRow('Bus & Seat:', 'Bus #${reg.busNumber} • Seat #${reg.seatNumber}'),
              _buildTicketDetailRow('Fare Paid:', '${reg.feeAmount.toStringAsFixed(0)} ETB'),
              _buildTicketDetailRow('Payment Channel:', reg.paymentMethod.displayName),
              _buildTicketDetailRow('Transaction Ref:', reg.transactionReference),
              _buildTicketDetailRow('Status:', reg.paymentStatus.displayName),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
