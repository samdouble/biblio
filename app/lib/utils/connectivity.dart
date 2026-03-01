import 'package:connectivity_plus/connectivity_plus.dart';

bool isOnline(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
}
