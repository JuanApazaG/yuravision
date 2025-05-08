class Deteccion {
  final int id;
  final String imagenUrl;
  final String descripcion;
  final String estado;
  final String fechaSubida;
  final String cultivoNombre;

  Deteccion({
    required this.id,
    required this.imagenUrl,
    required this.descripcion,
    required this.estado,
    required this.fechaSubida,
    required this.cultivoNombre,
  });

  factory Deteccion.fromJson(Map<String, dynamic> json) {
    return Deteccion(
      id: json['id'],
      imagenUrl: json['imagenUrl'],
      descripcion: json['descripcion'],
      estado: json['estado'],
      fechaSubida: json['fechaSubida'],
      cultivoNombre: json['cultivo']['nombre'],
    );
  }
} 