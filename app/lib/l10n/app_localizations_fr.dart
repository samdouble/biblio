// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get addBooks => 'Ajouter des livres';

  @override
  String get addBooksToLibrary => 'Ajouter des livres à la bibliothèque';

  @override
  String get addByScanning => 'Ajouter en scannant';

  @override
  String get addLibrary => 'Ajouter une bibliothèque';

  @override
  String get author => 'Auteur';

  @override
  String get clearSearch => 'Effacer la recherche';

  @override
  String get codeSent => 'Consultez votre courriel pour le code.';

  @override
  String get changesNotSynced =>
      'Modifications non synchronisées avec le cloud';

  @override
  String get couldNotLoadBookDetails =>
      'Impossible de charger les détails du livre';

  @override
  String get createLibrary => 'Créer une bibliothèque';

  @override
  String get email => 'Courriel';

  @override
  String get enterCode => 'Code';

  @override
  String enterCodeDescription(String email) {
    return 'Nous avons envoyé un code à 6 chiffres à $email. Saisissez-le ci-dessous.';
  }

  @override
  String get home => 'Accueil';

  @override
  String get language => 'Langue';

  @override
  String get languageEnglish => 'Anglais';

  @override
  String get languageFrench => 'Français';

  @override
  String get libraries => 'Bibliothèques';

  @override
  String get libraryName => 'Nom de la bibliothèque';

  @override
  String get myBooks => 'Mes livres';

  @override
  String noBooksFoundFor(String query) {
    return 'Aucun livre trouvé pour « $query ».';
  }

  @override
  String get noLibraries =>
      'Aucune bibliothèque. Appuyez sur + pour en créer une.';

  @override
  String get recentlyScanned => 'Récemment scannés';

  @override
  String get recentlyScannedEmpty =>
      'Scannez un livre avec le bouton + pour le voir ici.';

  @override
  String get searchByHint => 'Rechercher par titre, auteur, ISBN…';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get settings => 'Paramètres';

  @override
  String signedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get signUpDescription =>
      'Entrez votre courriel et nous vous enverrons un code à usage unique pour vous inscrire ou vous connecter.';

  @override
  String get signUpSuccess => 'Vous êtes connecté.';

  @override
  String get syncNow => 'Synchroniser';

  @override
  String get title => 'Titre';

  @override
  String get untitled => 'Sans titre';

  @override
  String get useDifferentEmail => 'Utiliser un autre courriel';

  @override
  String get verify => 'Vérifier';
}
