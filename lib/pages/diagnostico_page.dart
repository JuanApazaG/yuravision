import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

class DiagnosticoPage extends StatefulWidget {
  final File imagenFile;

  const DiagnosticoPage({super.key, required this.imagenFile});

  @override
  State<DiagnosticoPage> createState() => _DiagnosticoPageState();
}

class _DiagnosticoPageState extends State<DiagnosticoPage> {
  final TextEditingController _controller = TextEditingController();
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  bool _isRecording = false;
  String? _audioPath;

  // Selector de cultivo
  String _selectedCultivo = 'Papa';

  @override
  void initState() {
    super.initState();
    _initRecorder();
  }

  Future<void> _initRecorder() async {
    await Permission.microphone.request();
    await _recorder.openRecorder();
  }

  Future<void> _startRecording() async {
    final dir = await getTemporaryDirectory();
    _audioPath = '${dir.path}/audio_recording.aac';
    await _recorder.startRecorder(toFile: _audioPath);
    setState(() {
      _isRecording = true;
    });
  }

  Future<void> _stopRecording() async {
    await _recorder.stopRecorder();
    setState(() {
      _isRecording = false;
    });
  }

  // 🔽 Mapea cultivo a ID (ajustable según tu backend)
  int _getCultivoId(String cultivo) {
    switch (cultivo.toLowerCase()) {
      case 'papa':
        return 1;
      case 'tomate':
        return 2;
      default:
        return 0;
    }
  }

  Future<void> _enviarDatos() async {
    final uri = Uri.parse("http://192.168.1.2:3000/api/deteccion/detectar-cultivo-ia");
    final request = http.MultipartRequest('POST', uri);

    // 🔧 DATOS: agricultorId, cultivoId, descripcion
    final agricultorId = '123'; // ⚠️ Reemplazar luego con ID dinámico
    request.fields['agricultorId'] = agricultorId;
    request.fields['cultivoId'] = _getCultivoId(_selectedCultivo).toString();
    request.fields['descripcion'] = _controller.text;

    // 🖼️ IMAGEN
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      widget.imagenFile.path,
      contentType: MediaType.parse(lookupMimeType(widget.imagenFile.path) ?? 'image/jpeg'),
    ));

    // 🎙️ AUDIO (si existe)
    if (_audioPath != null && File(_audioPath!).existsSync()) {
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        _audioPath!,
        contentType: MediaType.parse(lookupMimeType(_audioPath!) ?? 'audio/aac'),
      ));
    }

    // 🛠️ DEBUG: mostrar datos que se enviarán
    print("⏳ Enviando datos...");
    print("Campos:");
    request.fields.forEach((key, value) => print("  $key: $value"));
    print("Archivos:");
    for (var file in request.files) {
      print("  ${file.field}: ${file.filename} (${file.contentType})");
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        print(" Respuesta del servidor:\n$responseBody");
        _mostrarDialogo("Éxito", "Datos enviados correctamente.");
      } else {
        print(" Código ${response.statusCode}");
        print(" Respuesta del servidor:\n$responseBody");
        _mostrarDialogo("Error", "Error al enviar los datos. Código: ${response.statusCode}");
      }
    } catch (e, stack) {
      print("🔥 Error al enviar: $e");
      print(stack);
      _mostrarDialogo("Error", "Error de red o servidor: $e");
    }
  }

  void _mostrarDialogo(String titulo, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(titulo),
        content: Text(mensaje),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diagnóstico')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Image.file(widget.imagenFile, height: 200),
            const SizedBox(height: 16),

            const Text('Selecciona tu cultivo:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCultivo,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Papa', 'Tomate'].map((cultivo) {
                return DropdownMenuItem(value: cultivo, child: Text(cultivo));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCultivo = value;
                  });
                }
              },
            ),

            const SizedBox(height: 16),
            Text(
              'Diagnóstico para $_selectedCultivo:',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Resultado preliminar: virus del rizado amarillo',
                style: TextStyle(fontSize: 16),
              ),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe mejor tu problema...',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              icon: Icon(_isRecording ? Icons.stop : Icons.mic),
              label: Text(_isRecording ? 'Detener grabación' : 'Grabar audio (1 min máx)'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            if (_audioPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text('Audio guardado en: $_audioPath'),
              ),

            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _enviarDatos,
              icon: const Icon(Icons.send),
              label: const Text("Enviar diagnóstico"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[800],
                padding: const EdgeInsets.symmetric(vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
