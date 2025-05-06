class Cultivo {
  final int id;
  final String nombre;

  Cultivo({required this.id, required this.nombre});

  factory Cultivo.fromJson(Map<String, dynamic> json) {
    return Cultivo(
      id: json['id'],
      nombre: json['nombre'],
    );
  }
}
