import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/revenuecat_service.dart';
import 'dashdoor_app.dart';

Future<void> bootstrap() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };

      await RevenueCatService.instance.init();

      runApp(const ProviderScope(child: DashDoorApp()));
    },
    (error, stack) {
      debugPrint('Uncaught error: $error');
      debugPrint('$stack');
    },
  );
}
