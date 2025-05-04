import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'diagnostico_page.dart';

class InicioPage extends StatelessWidget {
  const InicioPage({super.key});

  Future<void> _tomarFoto(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? foto = await picker.pickImage(source: ImageSource.camera);

    if (foto != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DiagnosticoPage(imagenFile: File(foto.path)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton.icon(
        onPressed: () => _tomarFoto(context),
        icon: const Icon(Icons.camera_alt),
        label: const Text('Analizar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }
}
