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

import '../models/cultivo_model.dart';

// 🎨 Paleta de colores
const Color verdeClaro = Color(0xFF24D083);
const Color verdeOscuro = Color(0xFF046224);
const Color amarilloClaro = Color(0xFFFCEC9F);
const Color grisClaro = Color(0xFFE0E0E0);
const Color blanco = Colors.white;
const Color negro = Colors.black;

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

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _player.openPlayer();
    _fetchCultivos();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: blanco,
      appBar: AppBar(
        title: Text('Diagnóstico', style: GoogleFonts.lato(color: negro, fontWeight: FontWeight.bold)),
        backgroundColor: blanco,
        iconTheme: const IconThemeData(color: negro),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.file(widget.imagenFile, height: 200),
            const SizedBox(height: 16),

            Text('Selecciona tu cultivo:', style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: negro)),
            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              value: _selectedCultivo,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: grisClaro),
                ),
              ),
              iconEnabledColor: negro,
              dropdownColor: blanco,
              items: _cultivos.map((cultivo) {
                return DropdownMenuItem(
                  value: cultivo.nombre,
                  child: Text(cultivo.nombre, style: GoogleFonts.lato(color: negro)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) setState(() => _selectedCultivo = value);
              },
            ),

            const SizedBox(height: 16),
            Text('Diagnóstico para $_selectedCultivo:', style: GoogleFonts.lato(fontSize: 18, fontWeight: FontWeight.bold, color: negro)),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: blanco,
                border: Border.all(color: grisClaro),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
              ),
              child: Text('Resultado preliminar: virus del rizado amarillo', style: GoogleFonts.lato(fontSize: 16, color: negro)),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Describe mejor tu problema...',
                hintStyle: GoogleFonts.lato(color: Colors.black54),
                filled: true,
                fillColor: blanco,
                border: OutlineInputBorder(
                  borderSide: const BorderSide(color: grisClaro),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              style: GoogleFonts.lato(color: negro),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic, color: negro),
                  label: Text(_isRecording ? 'Detener' : 'Grabar audio', style: GoogleFonts.lato(color: negro)),
                  style: ElevatedButton.styleFrom(backgroundColor: amarilloClaro),
                ),
                const SizedBox(width: 12),
                if (_audioPath != null)
                  ElevatedButton.icon(
                    onPressed: _isPlaying ? _stopAudio : _playAudio,
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, color: negro),
                    label: Text(_isPlaying ? 'Detener' : 'Reproducir', style: GoogleFonts.lato(color: negro)),
                    style: ElevatedButton.styleFrom(backgroundColor: grisClaro),
                  ),
              ],
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _enviarDatos,
              child: Text("Enviar diagnóstico", style: GoogleFonts.lato(fontWeight: FontWeight.bold, color: blanco)),
              style: ElevatedButton.styleFrom(backgroundColor: verdeOscuro),
            ),
          ],
        ),
      ),
    );
  }
}
