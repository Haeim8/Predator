// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appName => 'Predator';

  @override
  String get onboardingTitle1 => 'Proteggi la Tua Comunità';

  @override
  String get onboardingDesc1 =>
      'Predator ti avvisa sulle zone in cui sono stati segnalati crimini sessuali o violenti contro donne e bambini in Europa.';

  @override
  String get onboardingTitle2 => 'Tutti Possono Partecipare';

  @override
  String get onboardingDesc2 =>
      'Segnala incidenti in modo anonimo. Il nostro team verifica ogni segnalazione prima che appaia sulla mappa. Gratuito e sempre disponibile.';

  @override
  String get acceptTerms => 'Accetta i Termini';

  @override
  String get termsTitle => 'Termini di Utilizzo';

  @override
  String get termsContent =>
      'Utilizzando Predator, riconosci che:\n\n• Le informazioni visualizzate sono solo a scopo preventivo\n• Nessun dato personale (nome, indirizzo) viene divulgato\n• Gli eventi mostrati sono verificati dal nostro team di moderazione\n• L\'app e i suoi creatori non sono responsabili per azioni intraprese sulla base di queste informazioni\n• Le false segnalazioni possono avere conseguenze legali\n• Questa app rispetta le leggi europee sulla privacy (GDPR)';

  @override
  String get iAccept => 'Accetto';

  @override
  String get iDecline => 'Rifiuto';

  @override
  String get getStarted => 'Inizia';

  @override
  String get next => 'Avanti';

  @override
  String get skip => 'Salta';

  @override
  String get locationPermissionTitle => 'Posizione Richiesta';

  @override
  String get locationPermissionDesc =>
      'Predator ha bisogno della tua posizione per mostrare gli avvisi nelle vicinanze.';

  @override
  String get enableLocation => 'Attiva Posizione';

  @override
  String get locationDenied =>
      'L\'accesso alla posizione è necessario per usare Predator. Attivalo nelle impostazioni.';

  @override
  String get openSettings => 'Apri Impostazioni';

  @override
  String get searchPlaceholder => 'Cerca città o indirizzo...';

  @override
  String get reportIncident => 'Segnala un Incidente';

  @override
  String get incidentAddress => 'Indirizzo / Luogo';

  @override
  String get incidentDate => 'Data e Ora';

  @override
  String get incidentDescription => 'Descrivi cosa è successo';

  @override
  String get incidentSource => 'Fonte (opzionale)';

  @override
  String get sourcePlaceholder => 'Instagram, link giornalista, media...';

  @override
  String get anonymous => 'Resta Anonimo';

  @override
  String get submitReport => 'Invia Segnalazione';

  @override
  String get reportSubmitted => 'Segnalazione inviata per verifica';

  @override
  String get pendingVerification => 'In attesa di verifica';

  @override
  String get verified => 'Verificato';

  @override
  String get incidentDetails => 'Dettagli Incidente';

  @override
  String get reportedOn => 'Segnalato il';

  @override
  String get nearYou => 'Vicino a Te';

  @override
  String get freeApp => '100% Gratuito';

  @override
  String get communityDriven => 'Partecipativo';

  @override
  String get alwaysAvailable => 'Sempre Disponibile';

  @override
  String get cancel => 'Annulla';

  @override
  String get close => 'Chiudi';

  @override
  String get incidentType => 'Tipo di incidente';

  @override
  String get sexualAssault => 'Aggressione Sessuale';

  @override
  String get harassment => 'Molestie';

  @override
  String get violence => 'Violenza contro Donne/Bambini';

  @override
  String get other => 'Altro';

  @override
  String get alertNearby => 'Avviso: Incidente segnalato nelle vicinanze';
}
