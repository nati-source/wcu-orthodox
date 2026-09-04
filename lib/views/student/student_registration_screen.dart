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
      );

      _showWelcomeDialog();
    }
  }

  void _showWelcomeDialog() {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
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
              child: const Icon(Icons.church, color: Colors.black, size: 36),
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
            const Text(
              'Welcome to WCU Fellowship',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Summary Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderMuted),
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
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13),
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
                      const Icon(Icons.school_outlined, color: AppTheme.textSecondary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$_selectedDepartment • Year $_selectedAcademicYear',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const Text(
              'Your registration is now active! Tap below to enter your fellowship portal.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),

            // Action Button with Direct Redirection
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // 1. Close dialog
                  Navigator.of(ctx).pop();
                  // 2. Pop registration screen to return to home scaffold
                  if (mounted && Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  }
                  // 3. Trigger Home tab selection
                  widget.onRegistered();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ወደ ዋናው ገጽ ግባ / Go to Home',
                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, color: Colors.black, size: 18),
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Fellowship Registration'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primaryAccent.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
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
                      const Text(
                        'Welcome to WCU Fellowship',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Join our spiritual and academic community. We blend the ancient reverence of Orthodox Christianity with university life at Wachamo University.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
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
                const Text('Full Name', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _fullNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person_outline, color: primaryAccent, size: 20),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter full name' : null,
                ),

                const SizedBox(height: 14),

                // Baptismal Name Input (Christian Name)
                const Text('Baptismal Name (የክርስትና ስም)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _baptismalNameController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Christian Name (e.g. Haile Meskel, Walata Maryam)',
                    prefixIcon: Icon(Icons.star_border, color: primaryAccent, size: 20),
                  ),
                  validator: (val) => val == null || val.isEmpty ? 'Please enter baptismal name' : null,
                ),

                const SizedBox(height: 14),

                // Phone Number Input
                const Text('Phone Number', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: '+251 900 000 000',
                    prefixIcon: Icon(Icons.phone_outlined, color: primaryAccent, size: 20),
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
                const Text('Academic Year', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
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
                          color: isSelected ? primaryAccent : theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? primaryAccent : AppTheme.borderMuted,
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
                            color: isSelected ? Colors.black : Colors.white,
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
                const Text('Batch Year', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _batchYearController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'e.g. 2024',
                    prefixIcon: Icon(Icons.calendar_today_outlined, color: primaryAccent, size: 20),
                  ),
                ),

                const SizedBox(height: 16),

                // Searchable Department Selector
                const Text('Department (Search & Select from 60 Departments)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: _openDepartmentSearchDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
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
                            style: const TextStyle(
                              color: Colors.white,
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

                const SizedBox(height: 32),

                // Join Fellowship Action Button
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Join Fellowship (ይመዝገቡ)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.black, size: 20),
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
    final filtered = _getFilteredDepartments();
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: keyboardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: primaryAccent.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
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
              color: AppTheme.borderMuted,
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
                    const Text(
                      'WCU Departments',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
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
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search department (e.g. Software, Medicine)...',
                prefixIcon: Icon(Icons.search, color: primaryAccent, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: AppTheme.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.scaffoldBackgroundColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryAccent.withOpacity(0.4)),
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
                      color: isSelected ? Colors.black : Colors.white70,
                    ),
                    selected: isSelected,
                    selectedColor: primaryAccent,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    checkmarkColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? primaryAccent : AppTheme.borderMuted,
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
                        const Icon(Icons.search_off, size: 44, color: AppTheme.textTertiary),
                        const SizedBox(height: 10),
                        Text(
                          'No department matching "${_searchController.text}"',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
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
                              : theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? primaryAccent
                                : AppTheme.borderMuted.withOpacity(0.5),
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          dense: true,
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? primaryAccent : AppTheme.textTertiary,
                            size: 18,
                          ),
                          title: Text(
                            dept,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? primaryAccent : Colors.white,
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
