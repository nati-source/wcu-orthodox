import 'package:flutter/material.dart';
import '../../models/app_models.dart';
import '../../services/auth_service.dart';
import '../../state/fellowship_state.dart';
import '../../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  final FellowshipState? state;

  const RegisterScreen({
    super.key,
    required this.onRegisterSuccess,
    this.state,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _baptismalNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _batchController = TextEditingController(text: '2024');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  String _selectedDepartment = 'Computer Science';
  int _selectedAcademicYear = 1;
  String _selectedGender = 'male';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _baptismalNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _studentIdController.dispose();
    _batchController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Capitalizes the first character of each word in a name
  String _capitalizeWords(String input) {
    if (input.trim().isEmpty) return input.trim();
    return input.trim().split(RegExp(r'\s+')).map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + (word.length > 1 ? word.substring(1).toLowerCase() : '');
    }).join(' ');
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match. Please check and try again.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final formattedFullName = _capitalizeWords(_nameController.text);
    final formattedBaptismalName = _capitalizeWords(_baptismalNameController.text);
    final formattedBatch = _batchController.text.trim().isEmpty ? '2024' : _batchController.text.trim();

    try {
      final bool isAdmin = AppAdminConstants.isAdminEmail(_emailController.text);
      await _authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: formattedFullName,
        baptismalName: formattedBaptismalName,
        phoneNumber: _phoneController.text.trim(),
        studentId: _studentIdController.text.trim(),
        department: _selectedDepartment,
        academicYear: _selectedAcademicYear,
        batchYear: formattedBatch,
        campus: 'Main Campus (ዋናው ግቢ)',
        gender: _selectedGender,
        initialRole: isAdmin ? UserRole.admin : UserRole.student,
      );

      // Immediately sync state with the new registrant's data
      widget.state?.updateCurrentUserProfile(
        fullName: formattedFullName,
        baptismalName: formattedBaptismalName,
        phoneNumber: _phoneController.text.trim(),
        department: _selectedDepartment,
        academicYear: _selectedAcademicYear,
        batchYear: formattedBatch,
        role: isAdmin ? UserRole.admin : UserRole.student,
        isApproved: isAdmin ? true : false,
        gender: _selectedGender,
      );

      if (mounted) {
        _showSuccessDialog(formattedFullName, formattedBaptismalName);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          final errStr = e.toString();
          if (errStr.contains('email-already-in-use')) {
            _errorMessage = 'This email address is already registered. Please sign in instead.';
          } else if (errStr.contains('weak-password')) {
            _errorMessage = 'The password is too weak. Please use at least 6 characters.';
          } else if (errStr.contains('invalid-email')) {
            _errorMessage = 'Please enter a valid email address.';
          } else {
            _errorMessage = 'Registration error: ${errStr.replaceAll(RegExp(r'\[.*?\]'), '').trim()}';
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSuccessDialog(String fullName, String baptismalName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.gold.withOpacity(0.5), width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.goldGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.gold.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(Icons.church_rounded, color: Color(0xFF070F1E), size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'እንኳን በደህና መጡ!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.gold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Welcome to WCU Orthodox Fellowship',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.primaryBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderMuted),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person, color: AppTheme.gold, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (baptismalName.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_outline, color: AppTheme.gold, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Christian Name: $baptismalName',
                            style: const TextStyle(color: AppTheme.gold, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
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
            // Pending approval notice
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top_rounded, color: Color(0xFFF59E0B), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your account is pending admin approval. You\'ll gain full access once reviewed.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFF59E0B), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // Close dialog
                  Navigator.of(context).pop(); // Close register screen
                  widget.onRegisterSuccess();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  foregroundColor: const Color(0xFF070F1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'View Approval Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.hourglass_top_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.gold),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Fellowship Registration',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.gold.withOpacity(0.3)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppTheme.goldGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.gold.withOpacity(0.3),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.church_outlined, color: Color(0xFF070F1E), size: 30),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'WCU Orthodox Fellowship',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'የዋቸሞ ዩኒቨርሲቲ ግቢ ጉባኤ የተማሪዎች ምዝገባ',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: AppTheme.gold, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message banner
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.crimsonBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.crimson),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppTheme.crimson, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.white, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // Section 1: Personal Information
                    _buildSectionHeader('1. Personal Details / የግል መረጃ'),
                    const SizedBox(height: 12),

                    // Full Name (Auto-capitalized)
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: _inputDecoration('Full Name (የዓለም ስም)*', Icons.person_outline),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your full name' : null,
                    ),
                    const SizedBox(height: 14),

                    // Baptismal Name (Auto-capitalized)
                    TextFormField(
                      controller: _baptismalNameController,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: _inputDecoration('Baptismal Name (የክርስትና ስም)', Icons.star_border),
                    ),
                    const SizedBox(height: 14),

                    // Phone Number
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: _inputDecoration('Phone Number (+251...)*', Icons.phone_outlined),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your phone number' : null,
                    ),
                    const SizedBox(height: 14),

                    // Student ID
                    TextFormField(
                      controller: _studentIdController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: _inputDecoration('WCU Student ID (e.g. WCU/1234/15)*', Icons.badge_outlined),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter your student ID' : null,
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Academic Information
                    _buildSectionHeader('2. Academic Information / የትምህርት መረጃ'),
                    const SizedBox(height: 12),

                    // Department Search & Selector
                    const Text('Department / የትምህርት ክፍል*', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: _openDepartmentSearchDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.gold.withOpacity(0.6), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.school, color: AppTheme.gold, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedDepartment,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppTheme.gold.withOpacity(0.4)),
                              ),
                              child: const Row(
                                children: [
                                  Text('Change', style: TextStyle(color: AppTheme.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 3),
                                  Icon(Icons.search, color: AppTheme.gold, size: 13),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Academic Year Pills
                    const Text('Academic Year / የትምህርት ዓመት*', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(6, (index) {
                        final year = index + 1;
                        final isSelected = _selectedAcademicYear == year;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAcademicYear = year),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.gold : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isSelected ? AppTheme.gold : AppTheme.borderMuted,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              'Year $year',
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF070F1E) : AppTheme.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 14),

                    // Gender Selection (ጾታ)
                    const Text(
                      'Gender (ጾታ)',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedGender = 'male'),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedGender == 'male' ? AppTheme.gold : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedGender == 'male' ? AppTheme.gold : AppTheme.borderMuted,
                                  width: _selectedGender == 'male' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.male,
                                    size: 18,
                                    color: _selectedGender == 'male' ? const Color(0xFF070F1E) : AppTheme.textPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Male (ወንድ)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _selectedGender == 'male' ? const Color(0xFF070F1E) : AppTheme.textPrimary,
                                        fontWeight: _selectedGender == 'male' ? FontWeight.bold : FontWeight.w500,
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: _selectedGender == 'female' ? AppTheme.gold : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedGender == 'female' ? AppTheme.gold : AppTheme.borderMuted,
                                  width: _selectedGender == 'female' ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.female,
                                    size: 18,
                                    color: _selectedGender == 'female' ? const Color(0xFF070F1E) : AppTheme.textPrimary,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      'Female (ሴት)',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: _selectedGender == 'female' ? const Color(0xFF070F1E) : AppTheme.textPrimary,
                                        fontWeight: _selectedGender == 'female' ? FontWeight.bold : FontWeight.w500,
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
                    const SizedBox(height: 14),

                    // Batch Year
                    TextFormField(
                      controller: _batchController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: _inputDecoration('Batch Year (e.g. 2024 / 2016)', Icons.calendar_today_outlined),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Account Security Credentials
                    _buildSectionHeader('3. Account Credentials / የይለፍ ቃል'),
                    const SizedBox(height: 12),

                    // Email Address
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: _inputDecoration('Email Address*', Icons.email_outlined),
                      validator: (v) => v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                    ),
                    const SizedBox(height: 14),

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Password (min 6 characters)*',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.gold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderMuted),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.gold, width: 2),
                        ),
                      ),
                      validator: (v) => v != null && v.length >= 6 ? null : 'Password must be at least 6 characters',
                    ),
                    const SizedBox(height: 14),

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password*',
                        labelStyle: const TextStyle(color: AppTheme.textSecondary),
                        prefixIcon: const Icon(Icons.lock_reset, color: AppTheme.gold),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                            color: AppTheme.textSecondary,
                          ),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                        filled: true,
                        fillColor: AppTheme.surfaceElevated,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.borderMuted),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.gold, width: 2),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Please confirm your password';
                        if (v != _passwordController.text) return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.gold,
                        foregroundColor: const Color(0xFF070F1E),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF070F1E)),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Complete Registration / ምዝገባውን ጨርስ',
                                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                    ),
                    const SizedBox(height: 20),

                    // Already have an account back link
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      children: [
                        const Text(
                          'Already registered? ',
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Text(
                            'Sign In / ግባ',
                            style: TextStyle(
                              color: AppTheme.gold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: AppTheme.gold,
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: AppTheme.gold, size: 20),
      filled: true,
      fillColor: AppTheme.surfaceElevated,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderMuted),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.borderMuted),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.gold, width: 2),
      ),
    );
  }
}

// ============================================================================
// DEDICATED WCU ACADEMIC DEPARTMENT SEARCH MODAL
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
    return WcuDepartments.all.where((dept) {
      final matchesSearch = dept.toLowerCase().contains(_searchController.text.trim().toLowerCase());
      if (!matchesSearch) return false;

      if (_selectedCategory == 'All') return true;
      if (_selectedCategory == 'Engineering') {
        return dept.toLowerCase().contains('engineering') ||
            dept.toLowerCase().contains('architecture') ||
            dept.toLowerCase().contains('cotm') ||
            dept.toLowerCase().contains('surveying');
      }
      if (_selectedCategory == 'Health & Medicine') {
        return dept.toLowerCase().contains('medicine') ||
            dept.toLowerCase().contains('nursing') ||
            dept.toLowerCase().contains('pharmacy') ||
            dept.toLowerCase().contains('health') ||
            dept.toLowerCase().contains('anesthesia') ||
            dept.toLowerCase().contains('midwifery') ||
            dept.toLowerCase().contains('medical');
      }
      if (_selectedCategory == 'Business & Economics') {
        return dept.toLowerCase().contains('accounting') ||
            dept.toLowerCase().contains('economics') ||
            dept.toLowerCase().contains('management') ||
            dept.toLowerCase().contains('marketing') ||
            dept.toLowerCase().contains('administration');
      }
      if (_selectedCategory == 'Natural Sciences') {
        return dept.toLowerCase().contains('biology') ||
            dept.toLowerCase().contains('chemistry') ||
            dept.toLowerCase().contains('physics') ||
            dept.toLowerCase().contains('mathematics') ||
            dept.toLowerCase().contains('geology') ||
            dept.toLowerCase().contains('computer');
      }
      if (_selectedCategory == 'Agriculture') {
        return dept.toLowerCase().contains('animal') ||
            dept.toLowerCase().contains('plant') ||
            dept.toLowerCase().contains('horticulture') ||
            dept.toLowerCase().contains('agricultural') ||
            dept.toLowerCase().contains('natural resource');
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredDepartments();

    return Container(
      height: MediaQuery.of(context).size.height * 0.78,
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
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
                const Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.school, color: AppTheme.gold, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'WCU Academic Departments',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filtered.length} of ${WcuDepartments.all.length}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.gold),
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
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search department (e.g. Software, Medicine)...',
                hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.7), fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: AppTheme.gold, size: 20),
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
                fillColor: AppTheme.primaryBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.borderMuted),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppTheme.gold, width: 1.5),
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
                      color: isSelected ? const Color(0xFF070F1E) : AppTheme.textPrimary,
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.gold,
                    backgroundColor: AppTheme.primaryBg,
                    checkmarkColor: const Color(0xFF070F1E),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isSelected ? AppTheme.gold : AppTheme.borderMuted,
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
                        Icon(Icons.search_off, size: 44, color: AppTheme.textSecondary.withOpacity(0.6)),
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
                          color: isSelected ? AppTheme.gold.withOpacity(0.15) : AppTheme.primaryBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppTheme.gold : AppTheme.borderMuted,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          dense: true,
                          leading: Icon(
                            isSelected ? Icons.check_circle : Icons.circle_outlined,
                            color: isSelected ? AppTheme.gold : AppTheme.textSecondary.withOpacity(0.5),
                            size: 18,
                          ),
                          title: Text(
                            dept,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppTheme.gold : AppTheme.textPrimary,
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
