import 'package:flutter/material.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/avatar.png'), // Cambia si no tienes imagen
          ),
          const SizedBox(height: 10),
          const Text('Usuario Yuravision', style: TextStyle(fontSize: 18)),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Editar Perfil'),
          ),
        ],
      ),
    );
  }
}
