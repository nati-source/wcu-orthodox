part of '../admin_approvals_screen.dart';

extension ApprovalsPriestsTabExt on _AdminApprovalsScreenState {
  Widget _buildPriestsAndSchedulesTab(BuildContext context, FellowshipState state) {
    final fathers = state.confessorFathers;
    final allAppts = state.confessionAppointments;
    final pendingAppts = allAppts.where((a) => a.status == ConfessionAppointmentStatus.pending).toList();
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Action Bar: Add Priest & Broadcast Schedule
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openAddEditPriestDialog(context, null),
                icon: Icon(Icons.person_add_alt_1, size: 16, color: theme.brightness == Brightness.dark ? Colors.black : Colors.white),
                label: Text('Add Priest / Confessor', style: TextStyle(color: theme.brightness == Brightness.dark ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _openBroadcastPriestScheduleDialog(context),
                icon: Icon(Icons.campaign_outlined, size: 16, color: primaryAccent),
                label: Text('Broadcast Alert', style: TextStyle(color: primaryAccent, fontWeight: FontWeight.bold, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: primaryAccent),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Section 1: Active Confessor Fathers Roster & Meeting Places
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'ACTIVE CONFESSOR FATHERS & VENUES',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textTertiary, letterSpacing: 1.5),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: primaryAccent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${fathers.length} Active Clergy',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        if (fathers.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No confessor fathers registered. Tap "Add Priest / Confessor" above.',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          )
        else
          ...fathers.map((father) {
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: primaryAccent.withOpacity(0.15),
                        child: Icon(Icons.person, color: primaryAccent, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              father.fullName,
                              style: TextStyle(fontFamily: 'serif', fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                            ),
                            Text(
                              '${father.clericalTitle} • ${father.churchName}',
                              style: TextStyle(fontSize: 11, color: primaryAccent, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: primaryAccent, size: 18),
                        onPressed: () => _openAddEditPriestDialog(context, father),
                        tooltip: 'Edit Schedule & Place',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Meeting Venue Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: primaryAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.place, color: primaryAccent, size: 14),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Venue: ${father.meetingVenue}',
                            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Available Days & Time Slots
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...father.availableDays.map((d) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Text(d, style: TextStyle(fontSize: 10, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                          )),
                      ...father.availableTimeSlots.map((s) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryAccent.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(s, style: TextStyle(fontSize: 10, color: primaryAccent, fontWeight: FontWeight.w600)),
                          )),
                    ],
                  ),
                ],
              ),
            );
          }),

        const SizedBox(height: 24),

        // Section 2: Student Confession Bookings Review
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STUDENT APPOINTMENTS & CONFIRMATIONS',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textTertiary, letterSpacing: 1.5),
            ),
            if (pendingAppts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${pendingAppts.length} Pending',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (allAppts.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.dividerColor),
            ),
            child: Center(
              child: Text(
                'No student appointments booked yet.',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontSize: 12),
              ),
            ),
          )
        else
          ...allAppts.map((appt) {
            final isPending = appt.status == ConfessionAppointmentStatus.pending;
            final isConfirmed = appt.status == ConfessionAppointmentStatus.confirmed;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isConfirmed
                      ? AppTheme.emerald
                      : isPending
                          ? primaryAccent
                          : AppTheme.crimson,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          appt.studentName,
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (isConfirmed ? AppTheme.emerald : isPending ? primaryAccent : AppTheme.crimson).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          appt.status.displayName,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isConfirmed ? AppTheme.emerald : isPending ? primaryAccent : AppTheme.crimson,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'With: ${appt.fatherName}',
                    style: TextStyle(fontSize: 12, color: primaryAccent, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Slot: ${appt.scheduledDate.year}-${appt.scheduledDate.month}-${appt.scheduledDate.day} • ${appt.timeSlot}',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
                  ),
                  Text(
                    'Topic: ${appt.topic}',
                    style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.85) ?? AppTheme.textTertiary),
                  ),

                  if (appt.notes != null && appt.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Note: ${appt.notes}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.emerald, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],

                  if (isPending) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            state.cancelConfessionAppointment(appt.id);
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.crimson,
                            side: const BorderSide(color: AppTheme.crimson),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          ),
                          child: const Text('Decline', style: TextStyle(fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _openAppointmentConfirmationDialog(context, appt),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryAccent,
                            foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                          child: const Text('Confirm & Set Venue', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  void _openAddEditPriestDialog(BuildContext context, ConfessorFatherModel? existing) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final state = widget.state;
    final isEditing = existing != null;

    final nameCtrl = TextEditingController(text: existing?.fullName ?? '');
    final titleCtrl = TextEditingController(text: existing?.clericalTitle ?? 'መልአከ ሰላም ቀሲስ');
    final churchCtrl = TextEditingController(text: existing?.churchName ?? 'St. Mary\'s Cathedral');
    final venueCtrl = TextEditingController(text: existing?.meetingVenue ?? 'St. Mary\'s Sunday School Office (Room 2)');
    final phoneCtrl = TextEditingController(text: existing?.phoneNumber ?? '+251911002233');
    final bioCtrl = TextEditingController(text: existing?.bio ?? 'Confessor, Youth Counselor & Liturgical Scholar');

    final selectedDays = List<String>.from(existing?.availableDays ?? ['Saturday', 'Sunday']);
    final selectedSlots = List<String>.from(existing?.availableTimeSlots ?? ['3:00 PM - 5:30 PM']);

    final allDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final allSlots = ['9:00 AM - 11:30 AM', '2:00 PM - 4:30 PM', '3:00 PM - 5:30 PM', '5:00 PM - 7:00 PM'];

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                isEditing ? 'Edit Priest & Venue' : 'Add Confessor Father',
                style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Father Full Name (e.g. Kesis Yohannes)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: 'Clerical Title (e.g. መልአከ ሰላም ቀሲስ)'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: churchCtrl,
                      decoration: const InputDecoration(labelText: 'Church / Parish Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: venueCtrl,
                      decoration: const InputDecoration(labelText: 'Meeting Place / Campus Venue', hintText: 'e.g. Sunday School Room 2'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone Number (Call / SMS)'),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Available Days:',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allDays.map((d) {
                        final isSel = selectedDays.contains(d);
                        return FilterChip(
                          label: Text(
                            d,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSel
                                  ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: primaryAccent,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedDays.add(d);
                              } else {
                                selectedDays.remove(d);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Available Time Slots:',
                      style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: allSlots.map((s) {
                        final isSel = selectedSlots.contains(s);
                        return FilterChip(
                          label: Text(
                            s,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSel
                                  ? (theme.brightness == Brightness.dark ? Colors.black : Colors.white)
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                          selected: isSel,
                          selectedColor: primaryAccent,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          onSelected: (val) {
                            setDialogState(() {
                              if (val) {
                                selectedSlots.add(s);
                              } else {
                                selectedSlots.remove(s);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: bioCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(labelText: 'Pastoral Bio / Counseling Focus'),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      state.deleteConfessorFather(existing.id);
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Priest profile removed')));
                    },
                    child: const Text('Delete', style: TextStyle(color: AppTheme.crimson)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    HapticFeedback.mediumImpact();

                    final updated = ConfessorFatherModel(
                      id: existing?.id ?? 'fat-${DateTime.now().millisecondsSinceEpoch}',
                      fullName: nameCtrl.text.trim(),
                      clericalTitle: titleCtrl.text.trim(),
                      churchName: churchCtrl.text.trim(),
                      meetingVenue: venueCtrl.text.trim().isNotEmpty ? venueCtrl.text.trim() : 'St. Mary\'s Sunday School Office (Room 2)',
                      phoneNumber: phoneCtrl.text.trim(),
                      availableDays: selectedDays.isNotEmpty ? selectedDays : ['Saturday', 'Sunday'],
                      availableTimeSlots: selectedSlots.isNotEmpty ? selectedSlots : ['3:00 PM - 5:30 PM'],
                      bio: bioCtrl.text.trim(),
                    );

                    if (isEditing) {
                      state.updateConfessorFather(updated);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Priest schedule & venue updated')));
                    } else {
                      state.addConfessorFather(updated);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('New Confessor Father added')));
                    }
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryAccent,
                    foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                  ),
                  child: Text(isEditing ? 'Save Changes' : 'Add Priest', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _openAppointmentConfirmationDialog(BuildContext context, ConfessionAppointmentModel appt) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final state = widget.state;
    final noteCtrl = TextEditingController(text: 'Confirmed. Please meet at Sunday School Office Room 2 and prepare Psalm 50.');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Confirm ${appt.studentName}\'s Visit', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Father: ${appt.fatherName}', style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface, fontWeight: FontWeight.bold)),
              Text('Topic: ${appt.topic}', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
              Text('Requested Date: ${appt.scheduledDate.year}-${appt.scheduledDate.month}-${appt.scheduledDate.day} (${appt.timeSlot})', style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Confirmation Note & Venue Instructions',
                  hintText: 'e.g. Meet at Room 2, fast from midnight',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                state.confirmConfessionAppointment(appt.id, notes: noteCtrl.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Confirmed appointment for ${appt.studentName}')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Confirm Appointment', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _openBroadcastPriestScheduleDialog(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final state = widget.state;
    final fatherCtrl = TextEditingController(text: 'Kesis Yohannes Teshome');
    final changeCtrl = TextEditingController(text: 'Counseling location moved to Campus Prayer Hall for Saturday.');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Broadcast Clergy Notice', style: TextStyle(fontFamily: 'serif', fontSize: 16, color: primaryAccent, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Send an instant broadcast notification to all students regarding schedule or venue updates.',
                style: TextStyle(fontSize: 11, color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fatherCtrl,
                decoration: const InputDecoration(labelText: 'Father / Clergy Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: changeCtrl,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Venue / Schedule Update Details'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () {
                if (changeCtrl.text.trim().isEmpty) return;
                HapticFeedback.mediumImpact();
                state.broadcastPriestScheduleAlert(
                  fatherName: fatherCtrl.text.trim(),
                  newVenueOrTime: changeCtrl.text.trim(),
                );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Clergy schedule broadcast sent to all students!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAccent,
                foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
              ),
              child: const Text('Broadcast Alert', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 2: FUNDRAISING & DEVELOPMENT PROPOSALS APPROVALS
  // ----------------------------------------------------
}
