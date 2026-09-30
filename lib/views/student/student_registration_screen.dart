import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class StudentRegistrationScreen extends StatefulWidget {
  final FellowshipState state;
  final VoidCallback onRegistered;

  const StudentRegistrationScreen({
    super.key,
    required this.state,
    required this.onRegistered,
  });

  @override
  State<StudentRegistrationScreen> createState() => _StudentRegistrationScreenState();
}

class _StudentRegistrationScreenState extends State<StudentRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController(text: 'Teklehaimanot Girma');
  final _baptismalNameController = TextEditingController(text: 'Haile Meskel');
  final _phoneController = TextEditingController(text: '+251912345678');
  final _batchYearController = TextEditingController(text: '2024');

  int _selectedAcademicYear = 3;
  String _selectedDepartment = 'Computer Science';
  String _selectedGender = 'male';

  @override
  void dispose() {
    _fullNameController.dispose();
    _baptismalNameController.dispose();
    _phoneController.dispose();
    _batchYearController.dispose();
    super.dispose();
  }

  void _openDepartmentSearchDialog() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DepartmentSearchModal(
        selectedDepartment: _selectedDepartment,
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedDepartment = selected;
      });
    }
  }

  void _submitRegistration() {
    if (_formKey.currentState?.validate() ?? false) {
      widget.state.registerStudent(
        fullName: _fullNameController.text.trim(),
        baptismalName: _baptismalNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        batchYear: _batchYearController.text.trim(),
        department: _selectedDepartment,
        academicYear: _selectedAcademicYear,
        gender: _selectedGender,
      );

      _showWelcomeDialog();
    }
  }

  void _showWelcomeDialog() {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final elevatedBg = theme.colorScheme.surfaceContainerHighest;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: primaryAccent.withOpacity(0.5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Emblem
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [primaryAccent, theme.colorScheme.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryAccent.withOpacity(0.45),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(Icons.church, color: isDark ? Colors.black : Colors.white, size: 36),
            ),
            const SizedBox(height: 18),

            // Amharic & English Blessing
            Text(
              'እንኳን በደህና መጡ!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryAccent,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome to WCU Fellowship',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: textCol,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: elevatedBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderCol),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: primaryAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _fullNameController.text.trim(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: textCol, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.star_outline, color: primaryAccent, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Christian Name: ${_baptismalNameController.text.trim()}',
                          style: TextStyle(color: primaryAccent, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.school_outlined, color: textMuted, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_selectedDepartment • Year $_selectedAcademicYear',
                          style: TextStyle(color: textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Your registration is now active! Tap below to enter your fellowship portal.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: textMuted, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Action Button with Direct Redirection
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  widget.onRegistered();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ወደ ዋናው ገጽ ግባ / Go to Home',
                      style: TextStyle(
                        color: isDark ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: isDark ? Colors.black : Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final textCol = theme.colorScheme.onSurface;
    final textMuted = theme.textTheme.bodyMedium?.color ?? AppTheme.textSecondary;
    final cardBg = theme.cardTheme.color ?? theme.colorScheme.surface;
    final borderCol = theme.dividerColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Fellowship Registration', style: TextStyle(color: textCol)),
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryAccent),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryAccent.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.06),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: primaryAccent.withOpacity(0.15),
                          border: Border.all(color: primaryAccent.withOpacity(0.5)),
                        ),
                        child: Icon(Icons.church_outlined, color: primaryAccent, size: 28),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Welcome to WCU Fellowship',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textCol,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Join our spiritual and academic community. We blend the ancient reverence of Orthodox Christianity with university life at Wachamo University.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Section: Personal Details
                Text(
                  'Personal Details',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryAccent,
                  ),
                ),
                const SizedBox(height: 14),

                // Full Name Input
                Text('Full Name', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  style: TextStyle(color: textCol, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 13),
                    prefixIcon: Icon(Icons.person_outline, color: primaryAccent, size: 20),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderCol),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter full name' : null,
                ),

                const SizedBox(height: 14),

                // Baptismal Name Input (Christian Name)
                Text('Baptismal Name (የክርስትና ስም)', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _baptismalNameController,
                  style: TextStyle(color: textCol, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Christian Name (e.g. Haile Meskel, Walata Maryam)',
                    hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 13),
                    prefixIcon: Icon(Icons.star_border, color: primaryAccent, size: 20),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderCol),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter baptismal name' : null,
                ),

                const SizedBox(height: 14),

                // Phone Number Input
                Text('Phone Number', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: TextStyle(color: textCol, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '+251 900 000 000',
                    hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 13),
                    prefixIcon: Icon(Icons.phone_outlined, color: primaryAccent, size: 20),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderCol),
                    ),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter phone number' : null,
                ),

                const SizedBox(height: 24),

                // Section: Academic Information
                Text(
                  'Academic Information',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryAccent,
                  ),
                ),
                const SizedBox(height: 14),

                // Academic Year (Year 1 to 8 grid/pills)
                Text('Academic Year', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: List.generate(8, (index) {
                    final year = index + 1;
                    final isSelected = _selectedAcademicYear == year;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAcademicYear = year),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? primaryAccent : cardBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? primaryAccent : borderCol,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: primaryAccent.withOpacity(0.4),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : null,
                        ),
                        child: Text(
                          'Year $year',
                          style: TextStyle(
                            color: isSelected
                                ? (isDark ? Colors.black : Colors.white)
                                : textCol.withOpacity(0.8),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 16),

                // Batch Year
                Text('Batch Year', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _batchYearController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: textCol, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. 2024',
                    hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 13),
                    prefixIcon: Icon(Icons.calendar_today_outlined, color: primaryAccent, size: 20),
                    filled: true,
                    fillColor: cardBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: borderCol),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Searchable Department Selector
                Text('Department (Search & Select from 60 Departments)', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _openDepartmentSearchDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: primaryAccent.withOpacity(0.6), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.school, color: primaryAccent, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedDepartment,
                            style: TextStyle(
                              color: textCol,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: primaryAccent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: primaryAccent.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              Text('Search', style: TextStyle(color: primaryAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              Icon(Icons.search, color: primaryAccent, size: 14),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Gender Selection (ጾታ)
                Text('Gender (ጾታ)', style: TextStyle(color: textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGender = 'male'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'male' ? primaryAccent.withOpacity(0.18) : cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedGender == 'male' ? primaryAccent : borderCol,
                              width: _selectedGender == 'male' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.male, color: _selectedGender == 'male' ? primaryAccent : textMuted, size: 20),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Male (ወንድ)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _selectedGender == 'male' ? primaryAccent : textCol,
                                    fontWeight: _selectedGender == 'male' ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedGender = 'female'),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                          decoration: BoxDecoration(
                            color: _selectedGender == 'female' ? primaryAccent.withOpacity(0.18) : cardBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _selectedGender == 'female' ? primaryAccent : borderCol,
                              width: _selectedGender == 'female' ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.female, color: _selectedGender == 'female' ? primaryAccent : textMuted, size: 20),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Female (ሴት)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _selectedGender == 'female' ? primaryAccent : textCol,
                                    fontWeight: _selectedGender == 'female' ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Join Fellowship Action Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            'Join Fellowship (ይመዝገቡ)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.black : Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: isDark ? Colors.black : Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// DEDICATED ROBUST DEPARTMENT SEARCH MODAL
// ============================================================================
class _DepartmentSearchModal extends StatefulWidget {
  final String selectedDepartment;

  const _DepartmentSearchModal({
    required this.selectedDepartment,
  });

  @override
  State<_DepartmentSearchModal> createState() => _DepartmentSearchModalState();
}

class _DepartmentSearchModalState extends State<_DepartmentSearchModal> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Engineering',
    'Health & Medicine',
    'Business & Economics',
    'Natural Sciences',
    'Agriculture',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getFilteredDepartments() {
    final query = _searchController.text.trim().toLowerCase();

    return WcuDepartments.all.where((dept) {
      final matchesQuery = query.isEmpty || dept.toLowerCase().contains(query);
      if (!matchesQuery) return false;

      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Engineering') {
        return dept.toLowerCase().contains('engineering') ||
            dept.toLowerCase().contains('computer') ||
            dept.toLowerCase().contains('technology') ||
            dept.toLowerCase().contains('architecture');
      }
      if (_selectedCategory == 'Health & Medicine') {
        return dept.toLowerCase().contains('medicine') ||
            dept.toLowerCase().contains('nursing') ||
            dept.toLowerCase().contains('health') ||
            dept.toLowerCase().contains('pharmacy') ||
            dept.toLowerCase().contains('anesthesia') ||
            dept.toLowerCase().contains('midwifery') ||
            dept.toLowerCase().contains('laboratory') ||
            dept.toLowerCase().contains('veterinary');
      }
      if (_selectedCategory == 'Business & Economics') {
        return dept.toLowerCase().contains('accounting') ||
            dept.toLowerCase().contains('economics') ||
            dept.toLowerCase().contains('management') ||
            dept.toLowerCase().contains('marketing') ||
            dept.toLowerCase().contains('public administration') ||
            dept.toLowerCase().contains('tourism');
      }
      if (_selectedCategory == 'Natural Sciences') {
        return dept.toLowerCase().contains('biology') ||
            dept.toLowerCase().contains('chemistry') ||
            dept.toLowerCase().contains('physics') ||
            dept.toLowerCase().contains('mathematics') ||
            dept.toLowerCase().contains('geology') ||
            dept.toLowerCase().contains('statistics') ||
            dept.toLowerCase().contains('biotechnology') ||
            dept.toLowerCase().contains('sport');
      }
      if (_selectedCategory == 'Agriculture') {
        return dept.toLowerCase().contains('plant') ||
            dept.toLowerCase().contains('animal') ||
            dept.toLowerCase().contains('agriculture') ||
            dept.toLowerCase().contains('environment') ||
            dept.toLowerCase().contains('forestry') ||
            dept.toLowerCase().contains('horticulture') ||
            dept.toLowerCase().contains('soil') ||
            dept.toLowerCase().contains('natural resource');
      }

      return true;
    }).toList();
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

    final filtered = _getFilteredDepartments();
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: keyboardPadding),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: primaryAccent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.5) : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: borderCol,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.school, color: primaryAccent, size: 24),
                    const SizedBox(width: 10),
                    Text(
                      'WCU Departments',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textCol,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filtered.length} of ${WcuDepartments.all.length}',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryAccent),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              style: TextStyle(color: textCol, fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search department (e.g. Software, Medicine)...',
                hintStyle: TextStyle(color: textMuted.withOpacity(0.7), fontSize: 13),
                prefixIcon: Icon(Icons.search, color: primaryAccent, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 18, color: textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: elevatedBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderCol),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryAccent, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Category Filter Chips
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (ctx, idx) {
                final cat = _categories[idx];
                final isSelected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(cat),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? (isDark ? Colors.black : Colors.white)
                          : textCol.withOpacity(0.8),
                    ),
                    selected: isSelected,
                    selectedColor: primaryAccent,
                    backgroundColor: elevatedBg,
                    checkmarkColor: isDark ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? primaryAccent : borderCol,
                      ),
                    ),
                    onSelected: (val) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Departments List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 44, color: textMuted.withOpacity(0.6)),
                        const SizedBox(height: 10),
                        Text(
                          'No department matching "${_searchController.text}"',
                          style: TextStyle(color: textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final dept = filtered[index];
                      final isSelected = dept == widget.selectedDepartment;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primaryAccent.withOpacity(0.15)
                              : elevatedBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? primaryAccent
                                : borderCol,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          dense: true,
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? primaryAccent : textMuted.withOpacity(0.5),
                            size: 18,
                          ),
                          title: Text(
                            dept,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? primaryAccent : textCol,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop(dept);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
