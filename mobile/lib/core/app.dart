import 'package:flutter/material.dart';
import '../navigation/app_router.dart';
import 'theme.dart';
import 'constants.dart';

class AppWidget extends StatelessWidget {
  const AppWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      initialRoute: AppRouter.initial,
      routes: AppRouter.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}
