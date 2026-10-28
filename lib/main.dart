import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/onboarding_screen.dart';
import 'firebase_options.dart';

// Ubah ke false setelah selesai tes Firestore
const bool kTestFirestore = false;

// Notifier global untuk kontrol Dark Mode dan Light Mode di seluruh aplikasi
final ValueNotifier<ThemeMode> themeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const GasKampusApp());
}

class GasKampusApp extends StatelessWidget {
  const GasKampusApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'GasKampus',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.light,
            textTheme: GoogleFonts.interTextTheme(),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFC0F637),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF7F8F5),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFC0F637),
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF0F172A),
            useMaterial3: true,
          ),
          themeMode: currentMode,
          home: kTestFirestore
              ? const FirestoreTestPage()
              : const OnboardingWrapper(),
        );
      },
    );
  }
}

// Halaman sementara untuk tes koneksi Firestore (hapus setelah selesai tes)
class FirestoreTestPage extends StatefulWidget {
  const FirestoreTestPage({super.key});

  @override
  State<FirestoreTestPage> createState() => _FirestoreTestPageState();
}

class _FirestoreTestPageState extends State<FirestoreTestPage> {
  String _status = 'Belum ada tes';
  bool _loading = false;

  Future<void> _tesFirestore() async {
    setState(() {
      _loading = true;
      _status = 'Mengirim...';
    });
    try {
      await FirebaseFirestore.instance.collection('test').add({
        'pesan': 'halo firebase',
        'waktu': DateTime.now().toIso8601String(),
      });
      setState(() => _status = 'Berhasil! Cek di Firebase Console.');
    } catch (e) {
      setState(() => _status = 'Gagal: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tes Firestore')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: _loading ? null : _tesFirestore,
                child: const Text('Tes Firestore'),
              ),
              const SizedBox(height: 16),
              Text(_status, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}