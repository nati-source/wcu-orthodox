import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';

class FellowshipOnboardingScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback onFinish;
  final VoidCallback onSignIn;

  const FellowshipOnboardingScreen({
    super.key,
    required this.state,
    required this.onFinish,
    required this.onSignIn,
  });

  @override
  State<FellowshipOnboardingScreen> createState() => _FellowshipOnboardingScreenState();
}

class _FellowshipOnboardingScreenState extends State<FellowshipOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isInSetupWizard = false;
  int _wizardStep = 0; // 0: Fellowship Alerts, 1: Sacred Look

  // Wizard preferences
  bool _dailyReminderEnabled = true;
  AppThemePalette _selectedPalette = AppThemePalette.midnightFellowship;

  @override
  void initState() {
    super.initState();
    _selectedPalette = widget.state.currentThemePalette;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      setState(() {
        _isInSetupWizard = true;
        _wizardStep = 0;
      });
    }
  }

  void _nextWizardStep() {
    HapticFeedback.lightImpact();
    if (_wizardStep < 1) {
      setState(() => _wizardStep++);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _skipToSignIn() async {
    HapticFeedback.lightImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_completed_onboarding_tour_v1', true);
    } catch (_) {}
    widget.onSignIn();
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('liturgy_reminder_enabled_v1', _dailyReminderEnabled);
      await prefs.setBool('has_completed_onboarding_tour_v1', true);
    } catch (_) {}
    widget.state.setThemePalette(_selectedPalette);
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    // Deep radial emerald-and-gold gradient background
    const bgGradient = RadialGradient(
      center: Alignment(0, -0.2),
      radius: 1.2,
      colors: [
        Color(0xFF0F3238), // Luminous emerald glow
        Color(0xFF081B1F), // Deep teal
        Color(0xFF030D10), // Midnight abyss
      ],
      stops: [0.0, 0.45, 1.0],
    );

    return Scaffold(
      backgroundColor: const Color(0xFF030D10),
      body: Container(
        decoration: const BoxDecoration(gradient: bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar with Cross Branding & Skip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFE5A93C), width: 1.2),
                              color: const Color(0xFFE5A93C).withValues(alpha: 0.12),
                            ),
                            child: const Center(
                              child: Icon(Icons.church_rounded, size: 16, color: Color(0xFFE5A93C)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'WCU Gibi Gubae • የዋቸሞ ዩኒቨርሲቲ ግቢ ጉባኤ',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE5A93C),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _skipToSignIn,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        _isInSetupWizard ? 'Sign In / ግባ' : 'Skip / እለፍ',
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ),

              // Main Body Content (Onboarding Tour OR Setup Wizard)
              Expanded(
                child: _isInSetupWizard
                    ? _buildSetupWizard()
                    : PageView(
                        controller: _pageController,
                        onPageChanged: (idx) => setState(() => _currentPage = idx),
                        children: [
                          _buildSlide1SpiritualFamily(),
                          _buildSlide2MinistriesAndFathers(),
                          _buildSlide3LiturgyAndPilgrimage(),
                          _buildSlide4MutualAidAndThemes(),
                        ],
                      ),
              ),

              // Bottom Control Strip (Pagination + Continue Button)
              _buildBottomControls(),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 1: SPIRITUAL FAMILY & MENTORSHIP (የመንፈስ ቤተሰብና አካዳሚክ ማማከር)
  // --------------------------------------------------------------------------
  Widget _buildSlide1SpiritualFamily() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),

                  // Central Illuminated Graphic Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2328).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE5A93C).withValues(alpha: 0.12),
                          blurRadius: 30,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Glowing Medallion Icon
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE5A93C), Color(0xFF8E6317)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE5A93C).withValues(alpha: 0.3),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.family_restroom_rounded, color: Color(0xFF030D10), size: 28),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Scripture citation
                        const Text(
                          '— መዝሙር ፻፴፪፥፩ • Psalm 133:1',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 13,
                            color: Color(0xFFE5A93C),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Clean Bilingual Scripture Quote (No Word-Highlight Chips)
                        const Text(
                          '“እነሆ፥ ወንድሞች በኅብረት ቢቀመጡ መልካም ነው፥ እንዴትም ያማረ ነው!”',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            height: 1.5,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '“Behold, how good and pleasant it is for brethren to dwell together in unity!”',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 11, color: Colors.white60, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 16),

                        // Real Spiritual Family Card Preview (#05171B)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF05171B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shield_outlined, color: Color(0xFFE5A93C), size: 16),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Family of St. George • የቅዱስ ጊዮርጊስ ቤተሰብ',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text('24 Members', style: TextStyle(fontSize: 9.5, color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildFeaturePill(Icons.favorite_border_rounded, 'Spiritual Parents (አባትና እናት)'),
                                  _buildFeaturePill(Icons.chat_bubble_outline_rounded, 'Telegram: @wcu_st_george'),
                                  _buildFeaturePill(Icons.school_outlined, 'Senior Academic Mentors'),
                                  _buildFeaturePill(Icons.star_border_rounded, 'St. George • ቅዱስ ጊዮርጊስ'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Text Heading Block
                  const Text(
                    'SPIRITUAL FAMILY & MENTORSHIP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Your spiritual home at\nWachemo University.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get matched into a Saint-named Spiritual Family with campus parents,\nconnect with siblings on Telegram, and find senior academic mentors.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 2: 10 EOTC MINISTRIES, PATRISTIC FATHERS & CONFESSOR (፲ የአገልግሎት ክፍሎችና የንስሐ አባት)
  // --------------------------------------------------------------------------
  Widget _buildSlide2MinistriesAndFathers() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),

                  // Patristics & Ministries Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2328).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F3238).withValues(alpha: 0.4),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Verse citation
                        const Text(
                          '— ፩ ጴጥሮስ ፬፥፲ • 1 Peter 4:10',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE5A93C),
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Clean Bilingual Scripture Quote (No Word-Highlight Chips)
                        const Text(
                          '“እያንዳንዱ እንደ ተቀበለው የጸጋ ስጦታ መጠን እርስ በርሳችሁ አገልግሉ።”',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 15,
                            color: Colors.white,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '“As each has received a gift, use it to serve one another.”',
                          style: TextStyle(fontSize: 11, color: Colors.white60, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 12),

                        // 10 EOTC Ministry Chips
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _buildDepartmentChip('ትምህርት (Education)'),
                            _buildDepartmentChip('መዝሙር (Choir)'),
                            _buildDepartmentChip('አባላት እንክብካቤ (Care)'),
                            _buildDepartmentChip('ስነ ጥበባት (Arts)'),
                            _buildDepartmentChip('በጎ አድራጎት (Charity)'),
                            _buildDepartmentChip('መንፈሳዊ ጉዞ (Pilgrimage)'),
                            _buildDepartmentChip('ሚዲያና ህትመት (Media)'),
                            _buildDepartmentChip('ግንኙነት (PR)'),
                            _buildDepartmentChip('ልማትና ገቢ (Dev)'),
                            _buildDepartmentChip('ስነ ስርዓት (Discipline)'),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Confessor Father & Anonymous Q&A Card (#05171B)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF05171B),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'CONFESSOR FATHERS & PATRISTICS • የንስሐ አባትና ነገረ አበው',
                                style: TextStyle(fontSize: 10, color: Color(0xFFE5A93C), fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Expanded(
                                    child: Text(
                                      '1-on-1 Confession & Spiritual Q&A',
                                      style: TextStyle(fontFamily: 'serif', fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildFatherBadge('ዮ', 'St. John Chrysostom • ቅዱስ ዮሐንስ አፈወርቅ'),
                                      const SizedBox(width: 4),
                                      _buildFatherBadge('ቄ', 'St. Cyril • ቅዱስ ቄርሎስ'),
                                      const SizedBox(width: 4),
                                      _buildFatherBadge('ተ', 'Abune Teklehaimanot • አቡነ ተክለ ሃይማኖት'),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _buildFeaturePill(Icons.calendar_month_outlined, 'Private Confession Booking'),
                                  _buildFeaturePill(Icons.lock_outline_rounded, 'Anonymous Spiritual Q&A'),
                                ],
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                '"No one heals a soul like a loving spiritual father." — Book private confession slots & ask questions anonymously.',
                                style: TextStyle(fontSize: 11, color: Colors.white60, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'SERVE & GROW',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Serve in 10 ministries &\nwalk with the Fathers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Apply to serve in 10 EOTC fellowship departments, study patristic roadmaps,\nand book confidential appointments with campus Confessor Fathers.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE5A93C).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: const Color(0xFFE5A93C)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFFF3C766), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildFatherBadge(String initial, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFE5A93C).withValues(alpha: 0.2),
          border: Border.all(color: const Color(0xFFE5A93C), width: 1),
        ),
        child: Center(
          child: Text(
            initial,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF3C766)),
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 3: HOLY LITURGY, LIVE QR ATTENDANCE, PILGRIMAGE & DIGITAL LIBRARY
  // --------------------------------------------------------------------------
  Widget _buildSlide3LiturgyAndPilgrimage() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),

                  // Liturgy, Attendance & Pilgrimage Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0A2328).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.35), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F3238).withValues(alpha: 0.4),
                          blurRadius: 25,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Strip
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Row(
                                children: [
                                  Icon(Icons.church_outlined, size: 14, color: Color(0xFFE5A93C)),
                                  SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'የዕለቱ ስንክሳር፣ ቅዳሴና የንግሥ ጉዞ',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE5A93C)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('ጥቅምት ፲፬ • አቡነ አረጋዊ', style: TextStyle(fontSize: 9.5, color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Psalm 122:1 Citation & Clean Plain-Text Scripture Quote
                        const Text(
                          '— መዝሙር ፻፳፩፥፩ • Psalm 122:1',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 11,
                            color: Color(0xFFE5A93C),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          '“ወደ እግዚአብሔር ቤት እንሂድ ባሉኝ ጊዜ ደስ አለኝ።”',
                          style: TextStyle(fontFamily: 'serif', fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600, height: 1.4),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '“I was glad when they said to me, ‘Let us go into the house of the Lord.’”',
                          style: TextStyle(fontSize: 11, color: Colors.white60, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 14),

                        // Preview Card 1: 30s Live QR/PIN Attendance
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF05171B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5A93C).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFFE5A93C), size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '30s Live Attendance Check-In',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'PIN: 4892 • 04:15 Remaining',
                                      style: TextStyle(fontSize: 10, color: Color(0xFF34D399), fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  'Present ✓',
                                  style: TextStyle(fontSize: 9.5, color: Color(0xFF34D399), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Preview Card 2: Monastery Pilgrimage Pass
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF05171B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5A93C).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.directions_bus_rounded, color: Color(0xFFE5A93C), size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Debre Damo Monastery Pilgrimage Pass',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Bus #02 • Seat #14 Reserved',
                                      style: TextStyle(fontSize: 10, color: Color(0xFFF3C766)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE5A93C).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.4)),
                                ),
                                child: const Text(
                                  'QR Pass',
                                  style: TextStyle(fontSize: 9.5, color: Color(0xFFF3C766), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Preview Card 3: Digital Liturgical Library & Prayer Book
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF05171B),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.menu_book_rounded, color: Color(0xFFE5A93C), size: 18),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Digital Liturgical Library & Prayer Book',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Wudase Maryam, Synaxarium & Patristic Books offline',
                                      style: TextStyle(fontSize: 9.5, color: Colors.white60),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'CAMPUS FELLOWSHIP LIFE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Liturgy, Live QR check-in\n& monastery pilgrimages.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Commemorate daily Saints in the Synaxarium, check in with 30-second QR codes,\nbook monastery pilgrimage bus seats, and access the digital prayer library.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // SLIDE 4: MUTUAL AID, FAITH TRIVIA & SACRED THEMES (መረዳጃ፣ የዕውቀት ውድድርና ገጽታ)
  // --------------------------------------------------------------------------
  Widget _buildSlide4MutualAidAndThemes() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const Spacer(),

                  // Fanned 3D Perspective Cards Named After Saints
                  SizedBox(
                    height: 145,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Card 1: St. Ephrem - Parchment & Incense (Left Tilted)
                        Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..translate(-55.0, 10.0, 0.0)
                            ..rotateZ(-0.14),
                          child: _buildStackCard(
                            title: 'ቅዱስ ኤፍሬም',
                            sub: 'Parchment & Incense',
                            bgColor: const Color(0xFFF9F5EC),
                            textColor: const Color(0xFF2C2419),
                            accentColor: const Color(0xFFB45309),
                          ),
                        ),

                        // Card 3: Abune Teklehaimanot - Axumite Emerald (Right Tilted)
                        Transform(
                          alignment: Alignment.bottomCenter,
                          transform: Matrix4.identity()
                            ..translate(55.0, 10.0, 0.0)
                            ..rotateZ(0.14),
                          child: _buildStackCard(
                            title: 'አቡነ ተክለ ሃይማኖት',
                            sub: 'Axumite Emerald',
                            bgColor: const Color(0xFF042018),
                            textColor: Colors.white,
                            accentColor: const Color(0xFF10B981),
                          ),
                        ),

                        // Card 2: St. Yared - Midnight Gold (Center Elevated)
                        Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.identity()..translate(0.0, -10.0, 0.0),
                          child: _buildStackCard(
                            title: 'ቅዱስ ያሬድ',
                            sub: 'Midnight Gold',
                            bgColor: const Color(0xFF0A1828),
                            textColor: Colors.white,
                            accentColor: const Color(0xFFE5A93C),
                            isCenter: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Galatians 6:2 Clean Plain-Text Mutual Aid Scripture
                  const Text(
                    '— ገላትያ ፮፥፪ • Galatians 6:2',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '“እርስ በርሳችሁ ሸክማችሁን ተሸካከሙ ሕጉንም ፈጽሙ።”',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '“Bear one another’s burdens, and so fulfill the law of Christ.”',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white60, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 12),

                  // Real Features Preview Box (#05171B)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF05171B),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite_rounded, color: Color(0xFFE5A93C), size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Confidential Emergency Aid • መረዳጃ',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Direct Relief', style: TextStyle(fontSize: 9, color: Color(0xFF34D399), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.emoji_events_rounded, color: Color(0xFFE5A93C), size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Weekly Faith Trivia • የዕውቀት ውድድር',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE5A93C).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('1st: St. George', style: TextStyle(fontSize: 9, color: Color(0xFFF3C766), fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  const Text(
                    'MADE FOR WCU FELLOWS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFE5A93C),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Mutual aid, faith trivia &\nyour sacred theme.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Support fellow students through confidential emergency aid, compete in\nweekly family faith trivia, and customize your fellowship experience.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStackCard({
    required String title,
    required String sub,
    required Color bgColor,
    required Color textColor,
    required Color accentColor,
    bool isCenter = false,
  }) {
    return Container(
      width: 130,
      height: 135,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: isCenter ? 0.8 : 0.4), width: isCenter ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: isCenter ? 20 : 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(Icons.auto_stories, color: accentColor, size: 16),
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(shape: BoxShape.circle, color: accentColor),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            style: TextStyle(fontSize: 9.5, color: textColor.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STREAMLINED 2-STEP SETUP WIZARD (ALERTS & SACRED LOOK)
  // --------------------------------------------------------------------------
  Widget _buildSetupWizard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2-Step Indicator Bar
          Row(
            children: [
              _buildStepIndicator(0, 'Alerts'),
              _buildStepDivider(),
              _buildStepIndicator(1, 'Look'),
            ],
          ),
          const SizedBox(height: 20),

          if (_wizardStep == 0) _buildWizardStepAlerts(),
          if (_wizardStep == 1) _buildWizardStepLook(),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String title) {
    final isActive = _wizardStep == stepIndex;
    final isDone = _wizardStep > stepIndex;

    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFE5A93C) : (isDone ? const Color(0xFF10B981) : Colors.white12),
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, size: 13, color: Colors.black)
                : Text(
                    '${stepIndex + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.black : Colors.white70,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? const Color(0xFFE5A93C) : Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: Colors.white12,
      ),
    );
  }

  // WIZARD STEP 0: FELLOWSHIP ALERTS (የቅዳሴና የመርሐ ግብር ማስታወሻ)
  Widget _buildWizardStepAlerts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FELLOWSHIP ALERTS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE5A93C), letterSpacing: 2.0),
        ),
        const SizedBox(height: 6),
        const Text(
          'Walk in the rhythm of the Church.',
          style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Receive reminders for Sunday Holy Liturgy, daily Saints commemoration (ስንክሳር), and live course attendance.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 18),

        // Lectionary Options
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2328).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5A93C), width: 1.5),
          ),
          child: const Row(
            children: [
              Icon(Icons.church, color: Color(0xFFE5A93C), size: 22),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ኦርቶዶክስ ተዋሕዶ (Orthodox Tewahedo Lectionary)',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFF3C766)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Daily Synaxarium (ስንክሳር), Wudase Maryam, Sunday Liturgy & Fasting rules',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded, color: Color(0xFFE5A93C), size: 18),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Liturgy & Fellowship Reminders Switch Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF0A2328).withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white12),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: Color(0xFFE5A93C), size: 22),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Liturgy & Fellowship Reminders',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Notify me before Sunday Holy Liturgy and scheduled fellowship programs.',
                      style: TextStyle(fontSize: 11, color: Colors.white60),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _dailyReminderEnabled,
                activeThumbColor: const Color(0xFFE5A93C),
                onChanged: (val) => setState(() => _dailyReminderEnabled = val),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // WIZARD STEP 1: SACRED LOOK (YOUR SACRED LOOK / የመተግበሪያው ገጽታ)
  Widget _buildWizardStepLook() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'YOUR SACRED LOOK',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFFE5A93C), letterSpacing: 2.0),
        ),
        const SizedBox(height: 6),
        const Text(
          'Personalize your fellowship app.',
          style: TextStyle(fontFamily: 'serif', fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pick a sacred color palette to customize your fellowship experience.',
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
        const SizedBox(height: 18),

        // LIVE FELLOWSHIP CARD PREVIEW BOX
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _selectedPalette == AppThemePalette.parchmentIncense
                ? const Color(0xFFF9F5EC)
                : (_selectedPalette == AppThemePalette.axumiteEmerald ? const Color(0xFF031E18) : const Color(0xFF071424)),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _selectedPalette == AppThemePalette.parchmentIncense
                  ? const Color(0xFFB45309)
                  : (_selectedPalette == AppThemePalette.axumiteEmerald ? const Color(0xFF10B981) : const Color(0xFFE5A93C)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'WCU GIBI GUBAE PREVIEW',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: _selectedPalette == AppThemePalette.parchmentIncense ? const Color(0xFFB45309) : const Color(0xFFE5A93C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _selectedPalette.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _selectedPalette == AppThemePalette.parchmentIncense ? Colors.black54 : Colors.white60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '“እነሆ፥ ወንድሞች በኅብረት ቢቀመጡ መልካም ነው፥ እንዴትም ያማረ ነው!” — መዝሙር ፻፴፪፥፩',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 14,
                  height: 1.5,
                  color: _selectedPalette == AppThemePalette.parchmentIncense ? const Color(0xFF2C2419) : Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (_selectedPalette == AppThemePalette.parchmentIncense
                          ? const Color(0xFFB45309)
                          : (_selectedPalette == AppThemePalette.axumiteEmerald ? const Color(0xFF10B981) : const Color(0xFFE5A93C)))
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Spiritual Family • 10 Ministries • Live QR Attendance • Pilgrimage',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: _selectedPalette == AppThemePalette.parchmentIncense
                        ? const Color(0xFFB45309)
                        : (_selectedPalette == AppThemePalette.axumiteEmerald ? const Color(0xFF34D399) : const Color(0xFFF3C766)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Palette Selector Swatches
        const Text('SACRED PALETTE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white70, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildPaletteTile(AppThemePalette.midnightFellowship, 'Midnight Gold', const Color(0xFF071424), const Color(0xFFE5A93C)),
            _buildPaletteTile(AppThemePalette.axumiteEmerald, 'Axumite Emerald', const Color(0xFF031E18), const Color(0xFF10B981)),
            _buildPaletteTile(AppThemePalette.parchmentIncense, 'Parchment & Incense', const Color(0xFFF9F5EC), const Color(0xFFB45309)),
          ],
        ),
      ],
    );
  }

  Widget _buildPaletteTile(AppThemePalette palette, String title, Color bg, Color accent) {
    final isSelected = _selectedPalette == palette;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedPalette = palette);
      },
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? accent : Colors.white24,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: accent.withValues(alpha: 0.4),
                    blurRadius: 10,
                  ),
              ],
            ),
            child: isSelected ? Center(child: Icon(Icons.check, size: 18, color: accent)) : null,
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? accent : Colors.white60,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // BOTTOM CONTROLS (PAGINATION DOTS + ACTION BUTTON)
  // --------------------------------------------------------------------------
  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: Column(
        children: [
          // Pagination Dots (Only shown on Onboarding Tour, not in Wizard)
          if (!_isInSetupWizard)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isSelected = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isSelected ? 22 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE5A93C) : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),

          const SizedBox(height: 14),

          // Primary Action Button
          ElevatedButton(
            onPressed: _isInSetupWizard ? _nextWizardStep : _nextPage,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE5A93C),
              foregroundColor: const Color(0xFF030D10),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
              elevation: 4,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isInSetupWizard
                      ? (_wizardStep == 1 ? 'Enter Fellowship • ወደ ግቢ ጉባኤ ግባ' : 'Continue')
                      : (_currentPage == 3 ? 'Set up my Fellowship' : 'Continue'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),

          // Sign In Link (for returning students)
          const SizedBox(height: 8),
          TextButton(
            onPressed: _skipToSignIn,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Already a member? Sign in / አባል ኖት? ግቡ',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFE5A93C),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
