import 'package:flutter/material.dart';
import 'dart:math';

class Diagnostico {
  final int id;
  final String cultivo;
  final DateTime fecha;
  final String estado; // 'Pendiente' o 'Solucionado'
  final String resultado;
  final String imagen;
  final String? audio;

  Diagnostico({
    required this.id,
    required this.cultivo,
    required this.fecha,
    required this.estado,
    required this.resultado,
    required this.imagen,
    this.audio,
  });
}

class EnfermedadesPage extends StatefulWidget {
  const EnfermedadesPage({super.key});

  @override
  State<EnfermedadesPage> createState() => _EnfermedadesPageState();
}

class _EnfermedadesPageState extends State<EnfermedadesPage> {
  List<Diagnostico> diagnosticos = [
    Diagnostico(
      id: 1,
      cultivo: 'Papa',
      fecha: DateTime.now().subtract(const Duration(days: 1)),
      estado: 'Pendiente',
      resultado: 'El análisis está en curso...',
      imagen: 'assets/ejemplo_papa.jpg',
      audio: null,
    ),
    Diagnostico(
      id: 2,
      cultivo: 'Maíz',
      fecha: DateTime.now().subtract(const Duration(days: 2)),
      estado: 'Solucionado',
      resultado: 'Detectado: Roya común. Recomendación: aplicar fungicida.',
      imagen: 'assets/ejemplo_maiz.jpg',
      audio: null,
    ),
    Diagnostico(
      id: 3,
      cultivo: 'Arroz',
      fecha: DateTime.now(),
      estado: 'Pendiente',
      resultado: 'El análisis está en curso...',
      imagen: 'assets/ejemplo_arroz.jpg',
      audio: null,
    ),
  ];

  void _actualizarLista() {
    setState(() {
      // Simula actualización cambiando aleatoriamente el estado de uno
      final random = Random();
      int idx = random.nextInt(diagnosticos.length);
      diagnosticos[idx] = Diagnostico(
        id: diagnosticos[idx].id,
        cultivo: diagnosticos[idx].cultivo,
        fecha: diagnosticos[idx].fecha,
        estado: diagnosticos[idx].estado == 'Pendiente' ? 'Solucionado' : 'Pendiente',
        resultado: diagnosticos[idx].estado == 'Pendiente'
            ? 'Detectado: Plaga resuelta. Recomendación: seguimiento.'
            : 'El análisis está en curso...',
        imagen: diagnosticos[idx].imagen,
        audio: diagnosticos[idx].audio,
      );
    });
  }

  void _verDetalle(Diagnostico diag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalleDiagnosticoPage(diagnostico: diag),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estado de Respuesta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _actualizarLista,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: diagnosticos.length,
        itemBuilder: (context, index) {
          final diag = diagnosticos[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _verDetalle(diag),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${diag.cultivo} - Diagnóstico #${diag.id}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: diag.estado == 'Pendiente' ? Colors.orange[100] : Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                diag.estado == 'Pendiente' ? Icons.timelapse : Icons.check_circle,
                                color: diag.estado == 'Pendiente' ? Colors.orange : Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                diag.estado,
                                style: TextStyle(
                                  color: diag.estado == 'Pendiente' ? Colors.orange : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enviado: ${diag.fecha.day}/${diag.fecha.month}/${diag.fecha.year}, ${diag.fecha.hour.toString().padLeft(2, '0')}:${diag.fecha.minute.toString().padLeft(2, '0')}:${diag.fecha.second.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                    ),
                    const SizedBox(height: 10),
                    Text('Resultado:', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      diag.resultado.length > 40 ? diag.resultado.substring(0, 40) + '...' : diag.resultado,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class DetalleDiagnosticoPage extends StatelessWidget {
  final Diagnostico diagnostico;
  const DetalleDiagnosticoPage({super.key, required this.diagnostico});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Diagnóstico #${diagnostico.id}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              '${diagnostico.cultivo} - Diagnóstico #${diagnostico.id}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: diagnostico.estado == 'Pendiente' ? Colors.orange[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        diagnostico.estado == 'Pendiente' ? Icons.timelapse : Icons.check_circle,
                        color: diagnostico.estado == 'Pendiente' ? Colors.orange : Colors.green,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        diagnostico.estado,
                        style: TextStyle(
                          color: diagnostico.estado == 'Pendiente' ? Colors.orange : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  'Enviado: ${diagnostico.fecha.day}/${diagnostico.fecha.month}/${diagnostico.fecha.year}, ${diagnostico.fecha.hour.toString().padLeft(2, '0')}:${diagnostico.fecha.minute.toString().padLeft(2, '0')}:${diagnostico.fecha.second.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (diagnostico.imagen.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  diagnostico.imagen,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            if (diagnostico.audio != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Audio:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  // Aquí podrías agregar un reproductor de audio real
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Reproductor de audio aquí (simulado)'),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            const Text('Resultado:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text(
              diagnostico.resultado,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
            ),
          ],
        ),
      ),
    );
  }
}
