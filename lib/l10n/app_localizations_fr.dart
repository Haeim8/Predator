// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Predator';

  @override
  String get onboardingTitle1 => 'Protégez Votre Communauté';

  @override
  String get onboardingDesc1 =>
      'Predator vous alerte sur les zones où des crimes sexuels ou violents contre les femmes et les enfants ont été signalés en Europe.';

  @override
  String get onboardingTitle2 => 'Tout le Monde Peut Participer';

  @override
  String get onboardingDesc2 =>
      'Signalez des incidents de manière anonyme. Notre équipe vérifie chaque signalement avant qu\'il n\'apparaisse sur la carte. Gratuit et toujours disponible.';

  @override
  String get acceptTerms => 'Accepter les Conditions';

  @override
  String get termsTitle => 'Conditions d\'Utilisation';

  @override
  String get termsContent =>
      'En utilisant Predator, vous reconnaissez que :\n\n• Les informations affichées sont à des fins de prévention uniquement\n• Aucune donnée personnelle (nom, adresse) d\'un individu n\'est divulguée\n• Les événements affichés sont vérifiés par notre équipe de modération\n• L\'application et ses créateurs ne sont pas responsables des actions entreprises sur la base de ces informations\n• Les faux signalements peuvent entraîner des conséquences juridiques\n• Cette application respecte les lois européennes sur la vie privée (RGPD)';

  @override
  String get iAccept => 'J\'accepte';

  @override
  String get iDecline => 'Je refuse';

  @override
  String get getStarted => 'Commencer';

  @override
  String get next => 'Suivant';

  @override
  String get skip => 'Passer';

  @override
  String get locationPermissionTitle => 'Localisation Requise';

  @override
  String get locationPermissionDesc =>
      'Predator a besoin de votre localisation pour afficher les alertes à proximité et vous informer sur votre environnement.';

  @override
  String get enableLocation => 'Activer la Localisation';

  @override
  String get locationDenied =>
      'L\'accès à la localisation est nécessaire pour utiliser Predator. Veuillez l\'activer dans les paramètres.';

  @override
  String get openSettings => 'Ouvrir les Paramètres';

  @override
  String get searchPlaceholder => 'Rechercher une ville ou adresse...';

  @override
  String get reportIncident => 'Signaler un Incident';

  @override
  String get incidentAddress => 'Adresse / Lieu';

  @override
  String get incidentDate => 'Date et Heure';

  @override
  String get incidentDescription => 'Décrivez ce qui s\'est passé';

  @override
  String get incidentSource => 'Source (optionnel)';

  @override
  String get sourcePlaceholder => 'Instagram, lien journaliste, média...';

  @override
  String get anonymous => 'Rester Anonyme';

  @override
  String get submitReport => 'Envoyer le Signalement';

  @override
  String get reportSubmitted => 'Signalement envoyé pour vérification';

  @override
  String get pendingVerification => 'En attente de vérification';

  @override
  String get verified => 'Vérifié';

  @override
  String get incidentDetails => 'Détails de l\'Incident';

  @override
  String get reportedOn => 'Signalé le';

  @override
  String get nearYou => 'Près de Vous';

  @override
  String get freeApp => '100% Gratuit';

  @override
  String get communityDriven => 'Participatif';

  @override
  String get alwaysAvailable => 'Toujours Disponible';

  @override
  String get cancel => 'Annuler';

  @override
  String get close => 'Fermer';

  @override
  String get incidentType => 'Type d\'incident';

  @override
  String get sexualAssault => 'Agression Sexuelle';

  @override
  String get harassment => 'Harcèlement';

  @override
  String get violence => 'Violence contre Femmes/Enfants';

  @override
  String get other => 'Autre';

  @override
  String get alertNearby => 'Alerte : Incident signalé à proximité';
}
