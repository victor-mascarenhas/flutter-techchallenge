import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/transaction_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/transactions_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TransactionProvider>(
          create: (context) => TransactionProvider(),
          update:
              (context, auth, previous) =>
                  previous!..update(auth.currentUser?.uid),
        ),
      ],
      child: MaterialApp(
        title: 'TechChallenge',
        theme: ThemeData(primarySwatch: Colors.blue),
        routes: {
          '/': (ctx) => AuthScreen(),
          '/transactions': (ctx) => TransactionsScreen(),
        },
      ),
    );
  }
}
