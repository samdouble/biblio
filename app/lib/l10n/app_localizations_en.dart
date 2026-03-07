// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get addBooks => 'Add books';

  @override
  String get addBooksToLibrary => 'Add books to library';

  @override
  String get addByScanning => 'Add by scanning';

  @override
  String get addLibrary => 'Add library';

  @override
  String get author => 'Author';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get codeSent => 'Check your email for the code.';

  @override
  String get couldNotLoadBookDetails => 'Could not load book details';

  @override
  String get createLibrary => 'Create library';

  @override
  String get email => 'Email';

  @override
  String get enterCode => 'Code';

  @override
  String enterCodeDescription(String email) {
    return 'We sent a 6-digit code to $email. Enter it below.';
  }

  @override
  String get home => 'Home';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'French';

  @override
  String get libraries => 'Libraries';

  @override
  String get libraryName => 'Library name';

  @override
  String get myBooks => 'My Books';

  @override
  String noBooksFoundFor(String query) {
    return 'No books found for \"$query\".';
  }

  @override
  String get noLibraries => 'No libraries yet. Tap + to create one.';

  @override
  String get recentlyScanned => 'Recently scanned';

  @override
  String get recentlyScannedEmpty =>
      'Scan a book with the + button to see it here.';

  @override
  String get searchByHint => 'Search by title, author, ISBN…';

  @override
  String get sendCode => 'Send code';

  @override
  String get settings => 'Settings';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get signUp => 'Sign up';

  @override
  String get signUpDescription =>
      'Enter your email and we\'ll send you a one-time code to sign up or sign in.';

  @override
  String get signUpSuccess => 'You\'re signed in.';

  @override
  String get title => 'Title';

  @override
  String get untitled => 'Untitled';

  @override
  String get useDifferentEmail => 'Use a different email';

  @override
  String get verify => 'Verify';
}
