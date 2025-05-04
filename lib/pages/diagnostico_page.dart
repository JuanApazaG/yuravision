import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

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

  // Cultivo seleccionado
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

            // Selector de cultivo
            const Text(
              'Selecciona tu cultivo:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedCultivo,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: ['Papa', 'Tomate'].map((cultivo) {
                return DropdownMenuItem(
                  value: cultivo,
                  child: Text(cultivo),
                );
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

            // Diagnóstico
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

            // Texto adicional
            TextField(
              controller: _controller,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Describe mejor tu problema...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Grabación
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
          ],
        ),
      ),
    );
  }
}
