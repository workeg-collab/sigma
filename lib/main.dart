import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/database/database_helper.dart';
import 'core/services/audit_service.dart';
import 'core/services/auth_service.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/account_repository.dart';
import 'data/repositories/analytical_repository.dart';
import 'data/repositories/audit_repository.dart';
import 'data/repositories/contractor_repository.dart';
import 'data/repositories/fiscal_repository.dart';
import 'data/repositories/journal_repository.dart';
import 'data/repositories/party_repository.dart';
import 'data/repositories/project_repository.dart';
import 'data/repositories/user_repository.dart';
import 'domain/services/accounting_engine.dart';
import 'presentation/providers/accounting_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/journal_provider.dart';
import 'presentation/providers/report_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DatabaseHelper.initializeFfi();

  // Initialize singletons
  final dbHelper = DatabaseHelper();
  final userRepo = UserRepository(dbHelper: dbHelper);
  final authService = AuthService(userRepo: userRepo);
  final auditRepo = AuditRepository(dbHelper: dbHelper);
  final auditService = AuditService(auditRepo: auditRepo, authService: authService);
  final fiscalRepo = FiscalRepository(dbHelper: dbHelper);
  final accountRepo = AccountRepository(dbHelper: dbHelper);
  final projectRepo = ProjectRepository(dbHelper: dbHelper);
  final contractorRepo = ContractorRepository(dbHelper: dbHelper);
  final partyRepo = PartyRepository(dbHelper: dbHelper);
  final analyticalRepo = AnalyticalRepository(dbHelper: dbHelper);
  final journalRepo = JournalRepository(dbHelper: dbHelper, fiscalRepo: fiscalRepo);
  final engine = AccountingEngine(dbHelper: dbHelper);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>.value(value: authService),
        ChangeNotifierProvider<AccountingProvider>(
          create: (_) => AccountingProvider(
            accountRepo: accountRepo,
            projectRepo: projectRepo,
            contractorRepo: contractorRepo,
            partyRepo: partyRepo,
            analyticalRepo: analyticalRepo,
            fiscalRepo: fiscalRepo,
            engine: engine,
          ),
        ),
        ChangeNotifierProvider<JournalProvider>(
          create: (_) => JournalProvider(
            journalRepo: journalRepo,
            auditService: auditService,
          ),
        ),
        ChangeNotifierProvider<ReportProvider>(
          create: (_) => ReportProvider(engine: engine),
        ),
      ],
      child: const SigmaApp(),
    ),
  );
}

class SigmaApp extends StatelessWidget {
  const SigmaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'سيجما للمحاسبة والمقاولات',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeProvider.themeMode,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: auth.isAuthenticated ? const MainLayout() : const LoginScreen(),
    );
  }
}
