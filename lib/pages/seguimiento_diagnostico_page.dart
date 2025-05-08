import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/deteccion_model.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SeguimientoDiagnosticoPage extends StatefulWidget {
  const SeguimientoDiagnosticoPage({Key? key}) : super(key: key);

  @override
  State<SeguimientoDiagnosticoPage> createState() => _SeguimientoDiagnosticoPageState();
}

class _SeguimientoDiagnosticoPageState extends State<SeguimientoDiagnosticoPage> {
  List<Deteccion> _diagnosticosApi = [];
  bool _cargandoDiagnosticos = true;

  @override
  void initState() {
    super.initState();
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
          _diagnosticosApi = lista.map((e) => Deteccion.fromJson(e)).toList();
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de diagnosticos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: const Color(0xFF24D083),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tus solicitudes',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _cargandoDiagnosticos
                    ? const Center(child: CircularProgressIndicator())
                    : (_diagnosticosApi.isNotEmpty
                        ? ListView(
                            children: [
                              ..._diagnosticosApi.map((d) => DiagnosticoCard(
                                    fecha: d.fechaSubida.substring(0, 10),
                                    descripcion: d.descripcion,
                                    estado: _estadoTexto(d.estado),
                                    imagen: d.imagenUrl.startsWith('http') ? d.imagenUrl : 'http://192.168.1.2:3000/' + d.imagenUrl,
                                    isNetwork: true,
                                    cultivo: d.cultivoNombre,
                                  )),
                            ],
                          )
                        : ListView(
                            children: [
                              DiagnosticoCard(
                                fecha: '05/05/2025',
                                descripcion: 'Las hojas tienen manchas...',
                                estado: 'Pendiente',
                                imagen: 'assets/imagenes/planta1.jpg',
                                isNetwork: false,
                                cultivo: 'Papa',
                              ),
                              DiagnosticoCard(
                                fecha: '05/05/2025',
                                descripcion: 'Las hojas tienen manchas...',
                                estado: 'Resuelto',
                                imagen: 'assets/imagenes/planta2.jpg',
                                isNetwork: false,
                                cultivo: 'Papa',
                              ),
                            ],
                          )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _estadoTexto(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'diagnosticado':
      case 'cerrado':
        return 'Resuelto';
      default:
        return estado;
    }
  }
}

class DiagnosticoCard extends StatelessWidget {
  final String fecha;
  final String descripcion;
  final String estado;
  final String imagen;
  final bool isNetwork;
  final String? cultivo;

  const DiagnosticoCard({
    Key? key,
    required this.fecha,
    required this.descripcion,
    required this.estado,
    required this.imagen,
    this.isNetwork = false,
    this.cultivo,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool esPendiente = estado.toLowerCase() == 'pendiente';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: isNetwork
                  ? Image.network(imagen, width: 60, height: 60, fit: BoxFit.cover)
                  : Image.asset(imagen, width: 60, height: 60, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        fecha,
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: esPendiente ? Colors.red[700] : Colors.green[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          estado,
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (cultivo != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      cultivo!,
                      style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    descripcion,
                    style: GoogleFonts.montserrat(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (esPendiente)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.yellow[700],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Diagnostico en curso...',
                        style: GoogleFonts.montserrat(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[400],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        textStyle: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
                      ),
                      child: const Text('Ver resultado'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 