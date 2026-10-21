part of '../admin_approvals_screen.dart';

extension ApprovalsSpiritualQaTabExt on _AdminApprovalsScreenState {
  Widget _buildSpiritualQaTab(BuildContext context, FellowshipState state) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final allQuestions = state.spiritualQuestions;
    final pendingQuestions = allQuestions.where((q) => !q.isAnswered).toList();
    final answeredQuestions = allQuestions.where((q) => q.isAnswered).toList();

    List<AnonymousSpiritualQuestionModel> displayList;
    if (_spiritualQaFilter == 'Pending') {
      displayList = pendingQuestions;
    } else if (_spiritualQaFilter == 'Answered') {
      displayList = answeredQuestions;
    } else {
      displayList = allQuestions;
    }

    if (_spiritualQaSearch.trim().isNotEmpty) {
      final qLower = _spiritualQaSearch.trim().toLowerCase();
      displayList = displayList.where((q) =>
        q.questionText.toLowerCase().contains(qLower) ||
        q.category.toLowerCase().contains(qLower) ||
        (q.answerText?.toLowerCase().contains(qLower) ?? false) ||
        (q.answeredBy?.toLowerCase().contains(qLower) ?? false)
      ).toList();
    }

    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryAccent.withOpacity(0.16), cardBg],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryAccent.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.help_center_outlined, color: primaryAccent, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spiritual & Theological Inquiries • መንፈሳዊ ጥያቄዎች',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Review anonymous questions from students, provide pastoral Orthodox answers, and publish them to the fellowship community.',
                      style: TextStyle(fontSize: 11, color: textMuted, height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Filter Pills Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterPill(
                label: 'All Questions (${allQuestions.length})',
                filterValue: 'All',
                activeColor: primaryAccent,
                context: context,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                label: 'Pending Answer (${pendingQuestions.length})',
                filterValue: 'Pending',
                activeColor: const Color(0xFFF59E0B),
                context: context,
              ),
              const SizedBox(width: 8),
              _buildFilterPill(
                label: 'Answered (${answeredQuestions.length})',
                filterValue: 'Answered',
                activeColor: const Color(0xFF10B981),
                context: context,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Search Field
        TextField(
          onChanged: (val) => setState(() => _spiritualQaSearch = val),
          decoration: InputDecoration(
            hintText: 'Search questions, categories, answers...',
            prefixIcon: const Icon(Icons.search, size: 18),
            filled: true,
            fillColor: elevatedBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 16),

        if (displayList.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: textMuted.withOpacity(0.5)),
                const SizedBox(height: 12),
                Text(
                  _spiritualQaFilter == 'Pending'
                      ? 'No Unanswered Questions! • ሁሉም ጥያቄዎች ተመልሰዋል'
                      : 'No Questions Found',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textCol),
                ),
                const SizedBox(height: 4),
                Text(
                  'Anonymous questions submitted by students will appear here for review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: textMuted),
                ),
              ],
            ),
          )
        else
          ...displayList.map((q) => _buildQuestionAdminCard(context, state, q)),
      ],
    );
  }

  Widget _buildFilterPill({
    required String label,
    required String filterValue,
    required Color activeColor,
    required BuildContext context,
  }) {
    final isSelected = _spiritualQaFilter == filterValue;
    return InkWell(
      onTap: () => setState(() => _spiritualQaFilter = filterValue),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Theme.of(context).dividerColor,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? activeColor : Theme.of(context).textTheme.bodyMedium?.color,
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionAdminCard(BuildContext context, FellowshipState state, AnonymousSpiritualQuestionModel q) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;

    final formattedDate = '${q.askedAt.day}/${q.askedAt.month}/${q.askedAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: q.isAnswered ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFFF59E0B).withOpacity(0.4),
        ),
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
                  color: primaryAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  q.category,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: q.isAnswered
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      q.isAnswered ? 'Answered • የተመለሰ' : 'Pending • ያልተመለሰ',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: q.isAnswered ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(fontSize: 10, color: textMuted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          Text(
            'Q: ${q.questionText}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textCol, height: 1.3),
          ),
          const SizedBox(height: 10),

          if (q.isAnswered && q.answerText != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: elevatedBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF10B981), size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Answered by ${q.answeredBy ?? "Spiritual Committee / አገልጋይ"}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    q.answerText!,
                    style: TextStyle(fontSize: 12, color: textCol, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: () => _confirmDeleteQuestion(context, state, q.id),
                icon: const Icon(Icons.delete_outline, size: 15, color: AppTheme.crimson),
                label: const Text('Delete / ሰርዝ', style: TextStyle(fontSize: 11, color: AppTheme.crimson)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.crimson),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _showAnswerQuestionDialog(context, state, q),
                icon: const Icon(Icons.edit_note, size: 16),
                label: Text(
                  q.isAnswered ? 'Edit Answer / አሻሽል' : 'Answer Question / ምላሽ ስጥ',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAnswerQuestionDialog(BuildContext context, FellowshipState state, AnonymousSpiritualQuestionModel q) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final answerController = TextEditingController(text: q.answerText ?? '');
    final answeredByController = TextEditingController(
      text: q.answeredBy ??
          (state.currentUser.baptismalName.isNotEmpty
              ? '${state.currentUser.fullName} (${state.currentUser.baptismalName})'
              : state.currentUser.fullName),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.menu_book, color: primaryAccent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Spiritual Counsel & Answer',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category: ${q.category}',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primaryAccent),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Q: ${q.questionText}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  'Pastoral / Theological Answer • መንፈሳዊ ምላሽ:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: answerController,
                  maxLines: 5,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Write Orthodox canonical counsel, scripture citations, or doctrinal answer here...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Answered By • የመላሹ ስም ወይም ማዕረግ:',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: answeredByController,
                  decoration: InputDecoration(
                    hintText: 'e.g. ቀሲስ ... ወይም የትምህርትና ሐዋርያዊ አገልግሎት',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Cancel / ተመለስ'),
            ),
            ElevatedButton(
              onPressed: () async {
                final ans = answerController.text.trim();
                final by = answeredByController.text.trim();
                if (ans.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an answer to publish.')),
                  );
                  return;
                }

                await state.answerSpiritualQuestion(
                  questionId: q.id,
                  answerText: ans,
                  answeredBy: by.isNotEmpty ? by : 'Campus Fellowship Clergy',
                );

                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Spiritual question answered and published!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryAccent,
                foregroundColor: theme.brightness == Brightness.dark ? Colors.black : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Publish Answer • ምላሹን ለጥፍ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteQuestion(BuildContext context, FellowshipState state, String questionId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.delete_outline, color: AppTheme.crimson),
              SizedBox(width: 8),
              Text('Delete Question • ጥያቄውን ሰርዝ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'Are you sure you want to permanently delete this anonymous question from the database?',
            style: TextStyle(fontSize: 12),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await state.deleteSpiritualQuestion(questionId);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Question deleted from database.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.crimson,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete / ሰርዝ', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
