import 'package:flutter/material.dart';

class ComunidadPage extends StatelessWidget {
  const ComunidadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton(
            onPressed: () {},
            child: const Text('Explorar Comunidad'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Publicar Algo'),
          ),
        ],
      ),
    );
  }
}
