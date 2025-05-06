class Diagnostico {
  final String imagePath;
  final String cultivo;
  final String descripcion;
  final String estado; // 'pendiente' o 'completado'

  Diagnostico({
    required this.imagePath,
    required this.cultivo,
    required this.descripcion,
    this.estado = 'pendiente',
  });

  Map<String, dynamic> toJson() => {
    'imagePath': imagePath,
    'cultivo': cultivo,
    'descripcion': descripcion,
    'estado': estado,
  };

  factory Diagnostico.fromJson(Map<String, dynamic> json) => Diagnostico(
    imagePath: json['imagePath'],
    cultivo: json['cultivo'],
    descripcion: json['descripcion'],
    estado: json['estado'],
  );
}
