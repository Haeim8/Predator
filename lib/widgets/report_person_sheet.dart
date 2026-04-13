import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../core/theme.dart';
import '../models/convicted_person.dart';
import '../services/firestore_service.dart';

class ReportPersonSheet extends StatefulWidget {
  const ReportPersonSheet({super.key});

  @override
  State<ReportPersonSheet> createState() => _ReportPersonSheetState();
}

class _ReportPersonSheetState extends State<ReportPersonSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _factsController = TextEditingController();
  final _addressController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();
  final _linkedinController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  DateTime? _convictionDate;
  bool _isAnonymous = true;
  bool _isSubmitting = false;
  final List<XFile> _mediaFiles = [];
  static const int _maxMedia = 3;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _factsController.dispose();
    _addressController.dispose();
    _instagramController.dispose();
    _twitterController.dispose();
    _linkedinController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    if (_mediaFiles.length >= _maxMedia) return;
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Caméra'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1280,
      maxHeight: 720,
      imageQuality: 70,
    );
    if (file != null) setState(() => _mediaFiles.add(file));
  }

  Future<List<String>> _uploadMedia(String personId) async {
    final urls = <String>[];
    for (int i = 0; i < _mediaFiles.length; i++) {
      final file = _mediaFiles[i];
      final ref = FirebaseStorage.instance
          .ref('convicted_persons/$personId/media_$i.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      );
      if (kIsWeb) {
        await ref.putData(await file.readAsBytes(), metadata);
      } else {
        await ref.putFile(File(file.path), metadata);
      }
      urls.add(await ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final personId = const Uuid().v4();
      List<String> mediaUrls = [];
      if (_mediaFiles.isNotEmpty) {
        mediaUrls = await _uploadMedia(personId);
      }

      final person = ConvictedPerson(
        id: personId,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        facts: _factsController.text.trim(),
        convictionDate: _convictionDate,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        mediaUrls: mediaUrls,
        instagram: _instagramController.text.trim().isEmpty
            ? null
            : _instagramController.text.trim(),
        twitter: _twitterController.text.trim().isEmpty
            ? null
            : _twitterController.text.trim(),
        linkedin: _linkedinController.text.trim().isEmpty
            ? null
            : _linkedinController.text.trim(),
        isAnonymous: _isAnonymous,
        createdAt: DateTime.now(),
      );

      final service = FirestoreService();
      await service.submitPerson(person);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                    'Signalement envoyé. Il sera examiné par un journaliste.'),
              ),
            ],
          ),
          backgroundColor: VigileTheme.safeGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? VigileTheme.darkSurface : Colors.white;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade400,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: VigileTheme.primaryRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_search,
                      color: VigileTheme.primaryRed, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Signaler un individu',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text('Personne condamnée ou recherchée',
                          style:
                              TextStyle(fontSize: 13, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Form
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom / Prénom
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameController,
                            maxLength: 100,
                            decoration: _inputDecoration('Nom *', Icons.person),
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Requis' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameController,
                            maxLength: 100,
                            decoration:
                                _inputDecoration('Prénom *', Icons.person_outline),
                            validator: (v) =>
                                v!.trim().isEmpty ? 'Requis' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Faits
                    TextFormField(
                      controller: _factsController,
                      maxLength: 1000,
                      decoration: _inputDecoration(
                          'Faits reprochés / condamnation *', Icons.gavel),
                      maxLines: 4,
                      validator: (v) => v!.trim().isEmpty ? 'Requis' : null,
                    ),

                    const SizedBox(height: 16),

                    // Date de condamnation
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(1990),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _convictionDate = date);
                        }
                      },
                      child: InputDecorator(
                        decoration: _inputDecoration(
                            'Date de condamnation', Icons.calendar_today),
                        child: Text(
                          _convictionDate != null
                              ? '${_convictionDate!.day}/${_convictionDate!.month}/${_convictionDate!.year}'
                              : 'Sélectionner une date',
                          style: TextStyle(
                            color: _convictionDate != null
                                ? null
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Adresse
                    TextFormField(
                      controller: _addressController,
                      maxLength: 200,
                      decoration: _inputDecoration(
                          'Adresse connue (optionnel)', Icons.location_on),
                    ),

                    const SizedBox(height: 20),

                    // Preuves (photos/documents)
                    Text('Preuves (photos, documents)',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ..._mediaFiles.asMap().entries.map((entry) {
                            return Container(
                              width: 100,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: VigileTheme.safeGreen
                                        .withValues(alpha: 0.5)),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(11),
                                    child: kIsWeb
                                        ? FutureBuilder<List<int>>(
                                            future: entry.value
                                                .readAsBytes()
                                                .then((b) => b.toList()),
                                            builder: (_, snap) =>
                                                snap.hasData
                                                    ? Image.memory(
                                                        snap.data! as dynamic,
                                                        fit: BoxFit.cover)
                                                    : const Center(
                                                        child:
                                                            CircularProgressIndicator()),
                                          )
                                        : Image.file(
                                            File(entry.value.path),
                                            fit: BoxFit.cover),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setState(() =>
                                          _mediaFiles.removeAt(entry.key)),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 14),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (_mediaFiles.length < _maxMedia)
                            GestureDetector(
                              onTap: _pickMedia,
                              child: Container(
                                width: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: VigileTheme.primaryRed
                                          .withValues(alpha: 0.3)),
                                  color: VigileTheme.primaryRed
                                      .withValues(alpha: 0.05),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate,
                                        color: VigileTheme.primaryRed,
                                        size: 28),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_mediaFiles.length}/$_maxMedia',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Réseaux sociaux
                    Text('Réseaux sociaux de l\'individu',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _instagramController,
                      maxLength: 100,
                      decoration: _inputDecoration('Instagram', Icons.camera_alt),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _twitterController,
                      maxLength: 100,
                      decoration: _inputDecoration('X (Twitter)', Icons.alternate_email),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _linkedinController,
                      maxLength: 100,
                      decoration: _inputDecoration('LinkedIn', Icons.work),
                    ),

                    const SizedBox(height: 20),

                    // Anonymat
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text('Rester anonyme',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: const Text(
                            'Votre identité ne sera pas révélée',
                            style: TextStyle(fontSize: 12)),
                        value: _isAnonymous,
                        activeTrackColor: VigileTheme.primaryRed,
                        onChanged: (v) => setState(() => _isAnonymous = v),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Submit
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send),
                        label: Text(
                            _isSubmitting ? 'Envoi...' : 'Envoyer le signalement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VigileTheme.primaryRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: VigileTheme.primaryRed),
      counterText: '',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: VigileTheme.primaryRed, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
