import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentLiturgicalCalendarScreen extends StatefulWidget {
  final FellowshipState state;

  const StudentLiturgicalCalendarScreen({super.key, required this.state});

  @override
  State<StudentLiturgicalCalendarScreen> createState() => _StudentLiturgicalCalendarScreenState();
}

class _StudentLiturgicalCalendarScreenState extends State<StudentLiturgicalCalendarScreen> {
  int _selectedTabIndex = 0; // 0: Daily Readings, 1: Fasting Rules, 2: Synaxarium (ስንክሳር)

  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChange);
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    final state = widget.state;
    final currentDay = state.currentCalendarDay;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Liturgical Calendar • ባሕረ ሐሳብ', style: TextStyle(color: textCol)),
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: primaryAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline, color: primaryAccent),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  backgroundColor: cardBg,
                  title: Text(
                    'Ethiopian Orthodox Calendar',
                    style: TextStyle(fontFamily: 'serif', color: primaryAccent),
                  ),
                  content: Text(
                    'The Ethiopian Orthodox Tewahedo Church follows the Ge\'ez calendar (ባሕረ ሐሳብ), having 12 months of 30 days plus Pagumēn (ጳጉሜን) of 5 or 6 days. Each day commemorates specific Saints, Angels, and liturgical scriptures.',
                    style: TextStyle(color: textCol, fontSize: 13, height: 1.4),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Close', style: TextStyle(color: primaryAccent)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Grand Ethiopian Date & Saint Banner Card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: primaryAccent.withOpacity(0.4), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withOpacity(0.35) : Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: primaryAccent.withOpacity(0.5)),
                          ),
                          child: Text(
                            currentDay.geezDateString,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryAccent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: currentDay.isFasting
                              ? const Color(0xFFEF4444).withOpacity(0.15)
                              : const Color(0xFF10B981).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: currentDay.isFasting
                                ? const Color(0xFFEF4444).withOpacity(0.5)
                                : const Color(0xFF10B981).withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              currentDay.isFasting ? Icons.restaurant_menu : Icons.sentiment_satisfied_alt,
                              size: 14,
                              color: currentDay.isFasting ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currentDay.isFasting ? 'Fasting Day' : 'Non-Fasting',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: currentDay.isFasting ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentDay.saintOfTodayGeEz,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textCol,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentDay.saintOfToday,
                    style: TextStyle(
                      fontSize: 13,
                      color: textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: elevatedBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wb_twilight, color: primaryAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            currentDay.fastName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: textCol,
                            ),
                          ),
                        ),
                        if (currentDay.isFasting)
                          Text(
                            'Until ${currentDay.fastingUntilHour}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryAccent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Day Selector Carousel
            Text(
              'SELECT DAY • ዕለታት',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: textMuted.withOpacity(0.7),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: state.calendarWeek.length,
                itemBuilder: (context, index) {
                  final day = state.calendarWeek[index];
                  final isSelected = day.geezDateString == currentDay.geezDateString;

                  return GestureDetector(
                    onTap: () => state.selectCalendarDay(day),
                    child: Container(
                      width: 118,
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? elevatedBg : cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? primaryAccent : borderCol,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.geezDateString,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? primaryAccent : textCol,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day.isFasting ? 'Fasting' : 'Free',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              color: day.isFasting ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 22),

            // 3. Segmented Navigation Tabs (Readings / Fasting Rules / Synaxarium)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabPill(
                      context: context,
                      title: 'Scriptures (ምንባባት)',
                      icon: Icons.auto_stories,
                      index: 0,
                    ),
                  ),
                  Expanded(
                    child: _buildTabPill(
                      context: context,
                      title: 'Rules (ሥርዓተ ጾም)',
                      icon: Icons.rule,
                      index: 1,
                    ),
                  ),
                  Expanded(
                    child: _buildTabPill(
                      context: context,
                      title: 'Synaxarium (ስንክሳር)',
                      icon: Icons.history_edu,
                      index: 2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. Tab Views
            if (_selectedTabIndex == 0) _buildScripturesTab(context, currentDay.scriptures),
            if (_selectedTabIndex == 1) _buildFastingRulesTab(context, currentDay),
            if (_selectedTabIndex == 2) _buildSynaxariumTab(context, currentDay),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill({
    required BuildContext context,
    required String title,
    required IconData icon,
    required int index,
  }) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final isSelected = _selectedTabIndex == index;
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? elevatedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: primaryAccent.withOpacity(0.4)) : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? primaryAccent : textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? (isDark ? primaryAccent : textCol) : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScripturesTab(BuildContext context, DailyScriptureModel sc) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = theme.dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily Reflection Quote Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryAccent.withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.format_quote, color: primaryAccent, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  sc.reflection,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: textCol,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        _buildScriptureTile(context, 'Epistle of St. Paul (መልእክተ ጳውሎስ)', sc.epistle, Icons.mail_outline),
        _buildScriptureTile(context, 'Catholic Epistle (መልእክተ ሐዋርያት)', sc.catholicEpistle, Icons.menu_book),
        _buildScriptureTile(context, 'Acts of the Apostles (ግብረ ሐዋርያት)', sc.acts, Icons.history),
        _buildScriptureTile(context, 'Daily Psalm (ምስባከ ዳዊት)', sc.psalm, Icons.music_note),
        _buildScriptureTile(context, 'Holy Gospel (ወንጌል ቅዱስ)', sc.gospel, Icons.local_fire_department, isHighlight: true),
      ],
    );
  }

  Widget _buildScriptureTile(BuildContext context, String label, String reading, IconData icon, {bool isHighlight = false}) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighlight ? elevatedBg : cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isHighlight ? primaryAccent.withOpacity(0.6) : borderCol),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlight ? primaryAccent.withOpacity(0.2) : elevatedBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: isHighlight ? primaryAccent : textMuted, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isHighlight ? primaryAccent : textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  reading,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: textCol,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFastingRulesTab(BuildContext context, EthiopianCalendarDay day) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = theme.dividerColor;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                day.isFasting ? Icons.hourglass_top : Icons.done_all,
                color: day.isFasting ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                day.fastName,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textCol,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            day.fastRules,
            style: TextStyle(
              fontSize: 13,
              color: textMuted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: borderCol),
          const SizedBox(height: 12),
          _buildRuleRow(context, 'Fasting Duration', day.isFasting ? 'Until 3:00 PM (9:00 LT)' : 'None'),
          _buildRuleRow(context, 'Dietary Observance', day.isFasting ? 'Vegan (No meat, dairy, eggs)' : 'Regular food permitted'),
          _buildRuleRow(context, 'Fish Permitted?', day.isFishAllowed ? 'Yes (በዓለ ሃምሳ / ገሃድ)' : 'No (የተከለከለ)'),
        ],
      ),
    );
  }

  Widget _buildRuleRow(BuildContext context, String key, String value) {
    final theme = Theme.of(context);
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(key, style: TextStyle(fontSize: 12, color: textMuted)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildSynaxariumTab(BuildContext context, EthiopianCalendarDay day) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = theme.dividerColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryAccent.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.history_edu, color: primaryAccent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Synaxarium • መጽሐፈ ስንክሳር',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                    Text(
                      'Commemoration of the Saints of Today',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            day.scriptures.synaxariumExcerpt,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 14,
              color: textCol,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
