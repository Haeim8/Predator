import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/journalist.dart';
import '../models/incident.dart';
import '../models/convicted_person.dart';

class JournalistService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db =
      FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'predatoris');

  User? get currentUser => _auth.currentUser;

  // ── Phone Auth ──

  String? _verificationId;
  ConfirmationResult? _confirmationResult;

  Future<void> sendSmsCode({
    required String phoneNumber,
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    required Function(User user) onAutoVerified,
  }) async {
    if (kIsWeb) {
      // Web: utiliser signInWithPhoneNumber qui retourne ConfirmationResult
      try {
        _confirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
        onCodeSent('web');
      } catch (e) {
        onError(e.toString());
      }
    } else {
      // Mobile: utiliser verifyPhoneNumber classique
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          final result = await _auth.signInWithCredential(credential);
          if (result.user != null) {
            onAutoVerified(result.user!);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(_parsePhoneError(e.code));
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    }
  }

  Future<User?> verifySmsCode(String smsCode) async {
    if (kIsWeb) {
      // Web: utiliser confirmationResult.confirm()
      if (_confirmationResult == null) return null;
      final result = await _confirmationResult!.confirm(smsCode);
      return result.user;
    } else {
      // Mobile: utiliser PhoneAuthProvider.credential
      if (_verificationId == null) return null;
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final result = await _auth.signInWithCredential(credential);
      return result.user;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _parsePhoneError(String code) {
    switch (code) {
      case 'invalid-phone-number':
        return 'Numéro de téléphone invalide';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessayez plus tard';
      case 'quota-exceeded':
        return 'Quota SMS dépassé. Réessayez plus tard';
      default:
        return 'Erreur: $code';
    }
  }

  // ── Journalist Profile ──

  Future<Journalist?> getProfile(String uid) async {
    final doc = await _db.collection('journalists').doc(uid).get();
    if (!doc.exists) return null;
    return Journalist.fromFirestore(doc);
  }

  Future<void> createProfile(Journalist journalist) async {
    await _db.collection('journalists').doc(journalist.uid).set(journalist.toFirestore());
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('journalists').doc(uid).update(data);
  }

  // ── Incidents Management ──

  Future<List<Incident>> getPendingIncidents() async {
    final snapshot = await _db
        .collection('incidents')
        .where('status', isEqualTo: IncidentStatus.pending.index)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList();
  }

  Future<List<Incident>> getVerifiedIncidents() async {
    final snapshot = await _db
        .collection('incidents')
        .where('status', isEqualTo: IncidentStatus.verified.index)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList();
  }

  Future<List<Incident>> getRejectedIncidents() async {
    final snapshot = await _db
        .collection('incidents')
        .where('status', isEqualTo: IncidentStatus.rejected.index)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList();
  }

  Future<void> verifyIncident(String incidentId, String pseudo) async {
    await _db.collection('incidents').doc(incidentId).update({
      'status': IncidentStatus.verified.index,
      'verifiedBy': pseudo,
      'verifiedAt': Timestamp.now(),
    });
  }

  Future<List<Incident>> getMyVerifications(String pseudo) async {
    final snapshot = await _db
        .collection('incidents')
        .where('verifiedBy', isEqualTo: pseudo)
        .orderBy('verifiedAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Incident.fromFirestore(doc)).toList();
  }

  Future<void> deleteProfile(String uid) async {
    await _db.collection('journalists').doc(uid).delete();
    await _auth.currentUser?.delete();
  }

  Future<void> rejectIncident(String incidentId, String pseudo, String reason) async {
    await _db.collection('incidents').doc(incidentId).update({
      'status': IncidentStatus.rejected.index,
      'rejectionReason': reason,
      'verifiedBy': pseudo,
      'verifiedAt': Timestamp.now(),
    });
  }

  // ── Convicted Persons Management ──

  Future<List<ConvictedPerson>> getPendingPersons() async {
    final snapshot = await _db
        .collection('convicted_persons')
        .where('status', isEqualTo: PersonStatus.pending.index)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ConvictedPerson.fromFirestore(doc))
        .toList();
  }

  Future<List<ConvictedPerson>> getMyPersonVerifications(String pseudo) async {
    final snapshot = await _db
        .collection('convicted_persons')
        .where('verifiedBy', isEqualTo: pseudo)
        .orderBy('verifiedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => ConvictedPerson.fromFirestore(doc))
        .toList();
  }

  Future<void> updatePersonInfo(String personId, Map<String, dynamic> data) async {
    await _db.collection('convicted_persons').doc(personId).update(data);
  }

  Future<void> verifyPerson({
    required String personId,
    required String pseudo,
    required bool showAddress,
    required bool showSocialMedia,
  }) async {
    await _db.collection('convicted_persons').doc(personId).update({
      'status': PersonStatus.verified.index,
      'verifiedBy': pseudo,
      'verifiedAt': Timestamp.now(),
      'showAddress': showAddress,
      'showSocialMedia': showSocialMedia,
    });
  }

  Future<void> rejectPerson(
      String personId, String pseudo, String reason) async {
    await _db.collection('convicted_persons').doc(personId).update({
      'status': PersonStatus.rejected.index,
      'rejectionReason': reason,
      'verifiedBy': pseudo,
      'verifiedAt': Timestamp.now(),
    });
  }
}
