import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primary = const Color(0xFF00863b);
    final Color secondary = const Color(0xFF009239);
    final Color accent = const Color(0xFF0dc161);
    final Color dark = const Color(0xFF003c29);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: const AssetImage('assets/avatar.png'),
                  ).animate().fade().scale(duration: 600.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Usuario Yuravision',
                    style: GoogleFonts.montserrat(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'yura@example.com',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            _buildProfileOption(Icons.edit, 'Editar Perfil', primary),
            _buildProfileOption(Icons.lock, 'Cambiar Contraseña', secondary),
            _buildProfileOption(Icons.settings, 'Configuración', accent),
            _buildProfileOption(Icons.logout, 'Cerrar Sesión', Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileOption(IconData icon, String title, Color color) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Aquí puedes hacer navegación o lógica
        },
      ),
    ).animate().fadeIn(duration: 300.ms).slideX();
  }
}

/*Color(0xFF00863b); // Verde principal
Color(0xFF009239); // Secundario
Color(0xFF0dc161); // Acento
Color(0xFF003c29); // Verde */