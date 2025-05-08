import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

import '../models/cultivo_model.dart';

// 🎨 Paleta de colores
const Color verdeClaro = Color(0xFF24D083);
const Color verdeOscuro = Color(0xFF046224);
const Color amarilloClaro = Color(0xFFFCEC9F);
const Color grisClaro = Color(0xFFE0E0E0);
const Color blanco = Colors.white;
const Color negro = Colors.black;

List<CameraDescription> cameras = [];

class DiagnosticoPage extends StatefulWidget {
  final File imagenFile;

  const DiagnosticoPage({super.key, required this.imagenFile});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage> {
  final TextEditingController _controller = TextEditingController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  bool _isRecording = false;
  bool _isPlaying = false;
  String? _audioPath;

  List<Cultivo> _cultivos = [];
  bool _isLoadingCultivos = true;
  String _selectedCultivo = 'Papa';

  // Nuevo: controlador y texto de búsqueda
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _player.openPlayer();
    _fetchCultivos();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<void> _fetchCultivos() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.2:3000/api/cultivo/'));
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = json['data'];
        final cultivosList = data['cultivos'] as List;
        setState(() {
          _cultivos = cultivosList.map((item) => Cultivo.fromJson(item)).toList();
          
          final papaExists = _cultivos.any((c) => c.nombre.toLowerCase() == 'papa');
          
          if (papaExists) {
            _selectedCultivo = 'Papa';
          } else if (_cultivos.isNotEmpty) {
            _selectedCultivo = _cultivos.first.nombre;
          }
          
          _isLoadingCultivos = false;
        });
      } else {
        throw Exception("Error al cargar cultivos: ${response.statusCode}");
      }
    } catch (e) {
      print("Error al obtener cultivos: $e");
      setState(() {
        _isLoadingCultivos = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los cultivos. Se mantendrá "Papa" como valor por defecto.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    _audioPath = '${dir.path}/audio_recording.m4a';
    await _recorder.startRecorder(toFile: _audioPath, codec: Codec.aacMP4);
    setState(() => _isRecording = true);
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() => _isRecording = false);
  }

  Future<void> _playAudio() async {
    if (_audioPath == null || !File(_audioPath!).existsSync()) return;
    await _player.startPlayer(
      fromURI: _audioPath,
      whenFinished: () => setState(() => _isPlaying = false),
    );
    setState(() => _isPlaying = true);
  }

  Future<void> _stopAudio() async {
    await _player.stopPlayer();
    setState(() => _isPlaying = false);
  }

  Future<void> _downloadAudio() async {
    if (_audioPath == null) return;
    final audioFile = File(_audioPath!);
    if (!audioFile.existsSync()) return;

    final dir = await getExternalStorageDirectory();
    final savedFile = await audioFile.copy('${dir!.path}/audio_guardado.m4a');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Audio guardado en: ${savedFile.path}')),
    );
  }

  int _getCultivoId(String cultivo) {
    final match = _cultivos.firstWhere(
      (c) => c.nombre.toLowerCase() == cultivo.toLowerCase(),
      orElse: () => Cultivo(id: 0, nombre: 'Desconocido'),
    );
    return match.id;
  }

  Future<void> _enviarDatos() async {
    final uri = Uri.parse("http://192.168.1.2:3000/api/deteccion/detectar-cultivo-ia");
    final request = http.MultipartRequest('POST', uri);

    request.fields['agricultorId'] = '1';
    request.fields['cultivoId'] = _getCultivoId(_selectedCultivo).toString();
    request.fields['descripcion'] = _controller.text;

    request.files.add(await http.MultipartFile.fromPath(
      'image',
      widget.imagenFile.path,
      contentType: MediaType.parse(lookupMimeType(widget.imagenFile.path) ?? 'image/jpeg'),
    ));

    if (_audioPath != null && File(_audioPath!).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        _audioPath!,
        contentType: MediaType.parse(lookupMimeType(_audioPath!) ?? 'audio/x-m4a'),
      ));
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        _mostrarDialogo("Éxito", "Datos enviados correctamente.", volver: true);
      } else {
        _mostrarDialogo("Error", "Error al enviar datos. Código: ${response.statusCode}");
      }
    } catch (e) {
      _mostrarDialogo("Error", "Error de red o servidor: $e");
    }
  }

  void _mostrarDialogo(String titulo, String mensaje, {bool volver = false}) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (volver) Navigator.of(context).pop('enviado');
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _player.closePlayer();
    _controller.dispose();
    _searchController.dispose(); // Liberar el controlador de búsqueda
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text('Diagnostico', style: GoogleFonts.montserrat(color: negro, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF7F7F7),
        iconTheme: const IconThemeData(color: negro),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
        child: ListView(
          children: [
            const SizedBox(height: 8),
            Text(
              'Diagnosticar problema',
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: negro,
              ),
            ),
            const SizedBox(height: 18),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  widget.imagenFile,
                  height: 170,
                  width: 170,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 22),
            // Buscador para cultivos
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.black45),
                hintText: 'Buscar cultivo...',
                hintStyle: GoogleFonts.montserrat(color: Colors.black38),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: grisClaro),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: grisClaro),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: verdeClaro, width: 2),
                ),
              ),
              style: GoogleFonts.montserrat(color: negro, fontSize: 15),
            ),
            const SizedBox(height: 12),
            // Selector de cultivos tipo pill horizontal con filtro
            SizedBox(
              height: 48,
              child: _isLoadingCultivos
                  ? const Center(child: CircularProgressIndicator())
                  : Builder(
                      builder: (context) {
                        final cultivosFiltrados = _searchText.isEmpty
                            ? _cultivos
                            : _cultivos.where((c) => c.nombre.toLowerCase().contains(_searchText)).toList();
                        if (cultivosFiltrados.isEmpty) {
                          return Center(
                            child: Text('No se encontraron cultivos', style: GoogleFonts.montserrat(color: Colors.black38)),
                          );
                        }
                        return ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: cultivosFiltrados.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final cultivo = cultivosFiltrados[index];
                            final isSelected = cultivo.nombre == _selectedCultivo;
                            return GestureDetector(
                              onTap: () {
                                setState(() => _selectedCultivo = cultivo.nombre);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? verdeClaro : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: isSelected ? verdeClaro : grisClaro, width: 2),
                                  boxShadow: isSelected
                                      ? [BoxShadow(color: verdeClaro.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
                                      : [],
                                ),
                                child: Text(
                                  cultivo.nombre,
                                  style: GoogleFonts.montserrat(
                                    color: isSelected ? Colors.white : negro,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
            const SizedBox(height: 28),
            Text(
              'Describe el problema',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 16, color: negro),
            ),
            const SizedBox(height: 8),
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                TextField(
                  controller: _controller,
                  maxLines: 4,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: 'Ej: las hojas tienen....',
                    hintStyle: GoogleFonts.montserrat(color: Colors.black45),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderSide: const BorderSide(color: grisClaro),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    counterText: '',
                  ),
                  style: GoogleFonts.montserrat(color: negro),
                  onChanged: (_) => setState(() {}),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12, bottom: 8),
                  child: Text(
                    '${_controller.text.length}/200 caracteres',
                    style: GoogleFonts.montserrat(fontSize: 12, color: Colors.black38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Grabar una explicacion (opcional)',
              style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 15, color: negro),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRecording ? _stopRecording : _startRecording,
                    icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: negro),
                    label: Text(_isRecording ? 'Detener' : 'Grabar audio', style: GoogleFonts.montserrat(color: negro)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: amarilloClaro,
                      foregroundColor: negro,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                if (_audioPath != null)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isPlaying ? _stopAudio : _playAudio,
                      icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, color: negro),
                      label: Text(_isPlaying ? 'Detener' : 'Reproducir', style: GoogleFonts.montserrat(color: negro)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: grisClaro,
                        foregroundColor: negro,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _enviarDatos,
                child: Text(
                  'Enviar para Analisis',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 17),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: verdeClaro,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class CustomCameraPage extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CustomCameraPage({super.key, required this.cameras});

  @override
  State<CustomCameraPage> createState() => _CustomCameraPageState();
}

class _CustomCameraPageState extends State<CustomCameraPage> {
  late CameraController _controller;
  bool _isCameraReady = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isNotEmpty) {
      _controller = CameraController(widget.cameras[0], ResolutionPreset.medium);
      await _controller!.initialize();
      setState(() {
        _isCameraReady = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isCameraReady ? CameraPreview(_controller) : const Center(child: CircularProgressIndicator()),
    );
  }
}
