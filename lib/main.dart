import 'package:flutter/material.dart';
import 'app.dart';
import 'service_locator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ServiceLocator.setup();
  runApp(const MonexApp());
}
