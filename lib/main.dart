import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'data/app_state.dart';
import 'data/database.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  Intl.defaultLocale = 'id_ID';

  final notifications = NotificationService();
  await notifications.init();

  final state = AppState(AppDatabase(), notifications);
  await state.load();

  runApp(
    ChangeNotifierProvider<AppState>.value(
      value: state,
      child: const DanaNikahApp(),
    ),
  );
}
