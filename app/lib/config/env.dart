import 'package:flutter_dotenv/flutter_dotenv.dart';

String get apiBaseUrl =>
    dotenv.env['TSUNBOOKU_API_URL'] ?? '';
