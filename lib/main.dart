import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'pages/inicio_page.dart';
import 'pages/enfermedades_page.dart';
import 'pages/perfil_page.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'pages/custom_camera_page.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  cameras = await availableCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yuravision',
      theme: ThemeData(
        primaryColor: const Color(0xFF00863b),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00863b)),
        useMaterial3: true,
        textTheme: GoogleFonts.montserratTextTheme(),
      ),

      home: const HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  

  final List<Widget> _pages = [
    const InicioPage(),
    const EnfermedadesPage(),
    const PerfilPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<String> _titles = ['Inicio', 'Enfermedades', 'Usted'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            SvgPicture.asset(
              'assets/logo.svg',
              height: 40,
            ),
            const SizedBox(width: 10),
            const Text('Yuravision'),
          ],
        ),
        
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.group), label: 'Enfermedades'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Usted'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.green,
      ),
    );
  }
}
