import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/theme.dart';
import '../../models/journalist.dart';
import '../../services/journalist_service.dart';
import '../../services/press_card_verification_service.dart';
import 'journalist_dashboard_screen.dart';

enum _Step { phone, smsCode, createAccount }

class JournalistLoginScreen extends StatefulWidget {
  const JournalistLoginScreen({super.key});

  @override
  State<JournalistLoginScreen> createState() => _JournalistLoginScreenState();
}

class _JournalistLoginScreenState extends State<JournalistLoginScreen> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _pseudoController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final JournalistService _service = JournalistService();
  final ImagePicker _picker = ImagePicker();

  _Step _step = _Step.phone;
  bool _isLoading = false;
  bool _autoVerified = false;
  bool _isVerifyingCard = false;
  bool _cardVerified = false;
  String? _cardVerificationMessage;
  String? _error;
  User? _currentUser;
  XFile? _pressCard;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    _pseudoController.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Entrez votre numéro');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await _service.sendSmsCode(
      phoneNumber: phone,
      onCodeSent: (verificationId) {
        if (!mounted || _autoVerified) return;
        setState(() {
          _step = _Step.smsCode;
          _isLoading = false;
        });
      },
      onError: (error) {
        if (!mounted) return;
        setState(() {
          _error = error;
          _isLoading = false;
        });
      },
      onAutoVerified: (user) {
        if (!mounted) return;
        _autoVerified = true;
        _currentUser = user;
        _handleSignedIn(user);
      },
    );
  }

  Future<void> _verifyCode() async {
    if (_codeController.text.trim().isEmpty) {
      setState(() => _error = 'Entrez le code SMS');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await _service.verifySmsCode(_codeController.text.trim());
      if (user == null) {
        setState(() {
          _error = 'Code invalide';
          _isLoading = false;
        });
        return;
      }
      _currentUser = user;
      await _handleSignedIn(user);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSignedIn(User user) async {
    try {
      final profile = await _service.getProfile(user.uid);
      if (!mounted) return;

      if (profile != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => JournalistDashboardScreen(journalist: profile)),
        );
      } else {
        setState(() {
          _step = _Step.createAccount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _Step.createAccount;
        _isLoading = false;
      });
    }
  }

  Future<void> _pickPressCard() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1080,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() => _pressCard = image);
    }
  }

  Future<void> _verifyPressCard() async {
    final cardNumber = _cardNumberController.text.trim();
    if (cardNumber.isEmpty) {
      setState(() => _error = 'Entrez votre numéro de carte de presse');
      return;
    }

    setState(() {
      _isVerifyingCard = true;
      _cardVerified = false;
      _cardVerificationMessage = null;
      _error = null;
    });

    final result =
        await PressCardVerificationService.verifyCard(cardNumber);

    if (!mounted) return;
    setState(() {
      _isVerifyingCard = false;
      _cardVerified = result.result == CardVerificationResult.valid;
      _cardVerificationMessage = result.message;
      if (result.result == CardVerificationResult.notFound ||
          result.result == CardVerificationResult.expired) {
        _error = result.message;
      }
    });
  }

  Future<void> _createAccount() async {
    if (_pseudoController.text.trim().isEmpty) {
      setState(() => _error = 'Le pseudo est obligatoire');
      return;
    }
    if (_pressCard == null) {
      setState(() => _error = 'La carte de presse est obligatoire');
      return;
    }
    if (_cardNumberController.text.trim().isEmpty) {
      setState(() => _error = 'Le numéro de carte de presse est obligatoire');
      return;
    }
    if (!_cardVerified) {
      setState(() => _error = 'La vérification de carte de presse est obligatoire');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Upload carte de presse
      String? pressCardUrl;
      final ref = FirebaseStorage.instance
          .ref('journalists/${_currentUser!.uid}/press_card.jpg');

      if (kIsWeb) {
        final bytes = await _pressCard!.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(_pressCard!.path));
      }
      pressCardUrl = await ref.getDownloadURL();

      final journalist = Journalist(
        uid: _currentUser!.uid,
        phoneNumber: _currentUser!.phoneNumber ?? '',
        pseudo: _pseudoController.text.trim(),
        pressCardUrl: pressCardUrl,
        pressCardNumber: _cardNumberController.text.trim().toUpperCase(),
        isCardVerified: _cardVerified,
        createdAt: DateTime.now(),
      );
      await _service.createProfile(journalist);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => JournalistDashboardScreen(journalist: journalist)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _goBack() {
    setState(() {
      _error = null;
      switch (_step) {
        case _Step.smsCode:
          _step = _Step.phone;
          _codeController.clear();
          break;
        case _Step.createAccount:
          _step = _Step.phone;
          _service.signOut();
          break;
        case _Step.phone:
          Navigator.pop(context);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VigileTheme.darkRed,
              const Color(0xFF1A0000),
              isDark ? Colors.black : const Color(0xFF0D0D0D),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: _goBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white54),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: VigileTheme.primaryRed.withValues(alpha: 0.2),
                    ),
                    child: Icon(
                      _step == _Step.createAccount
                          ? Icons.person_add
                          : Icons.badge,
                      size: 40,
                      color: VigileTheme.primaryRed,
                    ),
                  ).animate().scale(
                      begin: const Offset(0.8, 0.8),
                      duration: 500.ms,
                      curve: Curves.elasticOut),

                  const SizedBox(height: 24),

                  Text(
                    _step == _Step.createAccount
                        ? 'CRÉER VOTRE COMPTE'
                        : _step == _Step.smsCode
                            ? 'VÉRIFICATION'
                            : 'ESPACE JOURNALISTE',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 200.ms),

                  const SizedBox(height: 8),

                  Text(
                    _step == _Step.createAccount
                        ? 'Remplissez votre profil journaliste'
                        : _step == _Step.smsCode
                            ? 'Entrez le code reçu par SMS'
                            : 'Abonnement 200€/an • Carte de presse requise',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: isDark
                          ? VigileTheme.darkSurface
                          : Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        if (_step == _Step.createAccount) ...[
                          // Pseudo
                          TextField(
                            controller: _pseudoController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                                'Pseudo (signature)', Icons.badge),
                          ),

                          const SizedBox(height: 20),

                          // Pseudo Camerapixo (IVJA) pour vérification
                          TextField(
                            controller: _cardNumberController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Pseudo Camerapixo (IVJA)',
                              hintText: 'ex: john-doe',
                              hintStyle: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.2)),
                              labelStyle: TextStyle(
                                  color:
                                      Colors.white.withValues(alpha: 0.5)),
                              prefixIcon: Icon(Icons.badge,
                                  color: VigileTheme.primaryRed, size: 20),
                              suffixIcon: _isVerifyingCard
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white),
                                      ),
                                    )
                                  : _cardVerified
                                      ? const Icon(Icons.verified,
                                          color: VigileTheme.safeGreen)
                                      : IconButton(
                                          onPressed: _verifyPressCard,
                                          icon: const Icon(Icons.search,
                                              color:
                                                  VigileTheme.primaryRed),
                                          tooltip: 'Vérifier la carte',
                                        ),
                              filled: true,
                              fillColor:
                                  Colors.white.withValues(alpha: 0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _cardVerified
                                        ? VigileTheme.safeGreen
                                        : Colors.white
                                            .withValues(alpha: 0.1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _cardVerified
                                        ? VigileTheme.safeGreen
                                            .withValues(alpha: 0.5)
                                        : Colors.white
                                            .withValues(alpha: 0.1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: VigileTheme.primaryRed,
                                    width: 2),
                              ),
                            ),
                          ),

                          if (_cardVerificationMessage != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _cardVerified
                                      ? Icons.check_circle
                                      : Icons.info_outline,
                                  size: 16,
                                  color: _cardVerified
                                      ? VigileTheme.safeGreen
                                      : VigileTheme.accentOrange,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _cardVerificationMessage!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _cardVerified
                                          ? VigileTheme.safeGreen
                                          : VigileTheme.accentOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Carte de presse (photo)
                          GestureDetector(
                            onTap: _pickPressCard,
                            child: Container(
                              width: double.infinity,
                              height: _pressCard != null ? 180 : 100,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _pressCard != null
                                      ? VigileTheme.safeGreen.withValues(alpha: 0.5)
                                      : VigileTheme.primaryRed.withValues(alpha: 0.3),
                                ),
                              ),
                              child: _pressCard != null
                                  ? Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: kIsWeb
                                              ? FutureBuilder<List<int>>(
                                                  future: _pressCard!.readAsBytes().then((b) => b.toList()),
                                                  builder: (ctx, snap) {
                                                    if (snap.hasData) {
                                                      return Image.memory(
                                                        snap.data! as dynamic,
                                                        width: double.infinity,
                                                        height: 180,
                                                        fit: BoxFit.cover,
                                                      );
                                                    }
                                                    return const Center(
                                                        child: CircularProgressIndicator());
                                                  },
                                                )
                                              : Image.file(
                                                  File(_pressCard!.path),
                                                  width: double.infinity,
                                                  height: 180,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: GestureDetector(
                                            onTap: () => setState(
                                                () => _pressCard = null),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.close,
                                                  color: Colors.white,
                                                  size: 16),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo,
                                            color: VigileTheme.primaryRed,
                                            size: 32),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Carte de presse *',
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.5),
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Abonnement info
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: VigileTheme.accentOrange
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: VigileTheme.accentOrange
                                    .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: VigileTheme.accentOrange,
                                    size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Abonnement 200€/an\nCarte de presse obligatoire',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: VigileTheme.accentOrange,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          _buildButton('Créer mon compte', _createAccount),
                        ] else if (_step == _Step.phone) ...[
                          // Phone number
                          TextField(
                            controller: _phoneController,
                            style: const TextStyle(color: Colors.white),
                            decoration: _inputDecoration(
                                'Numéro de téléphone', Icons.phone),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Format: +33 6 12 34 56 78',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _buildButton('Recevoir le code SMS', _sendCode),
                        ] else ...[
                          // SMS code
                          TextField(
                            controller: _codeController,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                letterSpacing: 8),
                            decoration:
                                _inputDecoration('Code SMS', Icons.sms),
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 6,
                          ),
                          const SizedBox(height: 24),
                          _buildButton('Vérifier', _verifyCode),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _step = _Step.phone;
                                _codeController.clear();
                                _error = null;
                              });
                            },
                            child: Text(
                              'Changer de numéro',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],

                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: VigileTheme.primaryRed,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: VigileTheme.primaryRed, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: VigileTheme.primaryRed, width: 2),
      ),
      counterText: '',
    );
  }
}
