import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'diagnostico_page.dart';
import 'seguimiento_diagnostico_page.dart';
import '../models/deteccion_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class InicioPage extends StatefulWidget {
  const InicioPage({super.key});

  @override
  State<InicioPage> createState() => _InicioPageState();
}

class _InicioPageState extends State<InicioPage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _diagnosticos = [];
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  // Diagnósticos dinámicos
  List<Deteccion> _diagnosticosApi = [];
  bool _cargandoDiagnosticos = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _fetchDiagnosticosApi();
  }

  Future<void> _fetchDiagnosticosApi() async {
    setState(() { _cargandoDiagnosticos = true; });
    try {
      final response = await http.get(Uri.parse('http://192.168.1.2:3000/api/deteccion/agricultor/1'));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> lista = jsonData['data']['deteccions'];
        setState(() {
          _diagnosticosApi = lista.map((e) => Deteccion.fromJson(e)).where((d) => d.estado == 'pendiente').toList();
          _cargandoDiagnosticos = false;
        });
      } else {
        setState(() { _cargandoDiagnosticos = false; });
      }
    } catch (e) {
      setState(() { _cargandoDiagnosticos = false; });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _tomarFoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final file = File(image.path);
      if (await file.exists()) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiagnosticoPage(imagenFile: file),
          ),
        );

        if (result == 'enviado') {
          setState(() {
            _diagnosticos.add({
              'imagen': image.path,
              'estado': 'pendiente',
            });
          });
        }
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error de imagen'),
              content: const Text('No se pudo cargar la imagen.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  Future<void> _seleccionarFoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final file = File(image.path);
      if (await file.exists()) {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DiagnosticoPage(imagenFile: file),
          ),
        );
        if (result == 'enviado') {
          setState(() {
            _diagnosticos.add({
              'imagen': image.path,
              'estado': 'pendiente',
            });
          });
        }
      } else {
        if (context.mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error de imagen'),
              content: const Text('No se pudo cargar la imagen.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00863b), Color(0xFF24D083)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Lottie.asset(
                  'assets/plant_animation.json',
                  height: 200,
                  width: 200,
                ),
                Text(
                  'Yuravision',
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Text(
                    'Toma una foto para analizar la salud de tu planta.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserrat(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: InkWell(
                      onTap: () => _tomarFoto(context),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt, color: Color(0xFF00863b), size: 28),
                            const SizedBox(width: 12),
                            Text(
                              'Analizar Planta',
                              style: GoogleFonts.montserrat(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF00863b),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Botón para seleccionar foto de la galería
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: InkWell(
                    onTap: () => _seleccionarFoto(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18.0, horizontal: 24.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.photo_library, color: Color(0xFF00863b), size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Seleccionar foto',
                            style: GoogleFonts.montserrat(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF00863b),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                // Diagnósticos recientes
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'Tus diagnosticos recientes',
                      style: GoogleFonts.montserrat(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      if (_cargandoDiagnosticos)
                        const Center(child: CircularProgressIndicator()),
                      ..._diagnosticosApi.map((d) => DiagnosticoCard(
                        fecha: d.fechaSubida.substring(0, 10),
                        descripcion: d.descripcion,
                        estado: 'Pendiente',
                        imagen: d.imagenUrl.startsWith('http') ? d.imagenUrl : 'http://192.168.1.2:3000/' + d.imagenUrl,
                        isNetwork: true,
                        cultivo: d.cultivoNombre,
                      )),
                      // Cards estáticas para resueltos
                      DiagnosticoCard(
                        fecha: '05/05/2025',
                        descripcion: 'Las hojas tienen manchas...',
                        estado: 'Resuelto',
                        imagen: 'assets/imagenes/planta2.jpg',
                        isNetwork: false,
                        cultivo: 'Papa',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 32.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SeguimientoDiagnosticoPage()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF00863b),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Ver más'),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}