// lib/screens/welcome_screen.dart
import 'package:flutter/material.dart';
import '../services/session_service.dart';
import '../services/api_service.dart'; // <--- Importante: Necesitamos llamar a la API
import 'main_screen.dart'; 

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ApiService _api = ApiService(); // Instancia de la API

  bool _isLoading = false; // Para mostrar spinner en el botón

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 1. Obtenemos (o generamos) el ID del dispositivo local
      final String deviceId = await SessionService.getOrGenerateDeviceId();
      final String name = _nameController.text.trim();
      final String? email = _emailController.text.isEmpty ? null : _emailController.text.trim();

      // 2. Llamamos al Backend para Autenticar/Registrar
      // Esto nos devolverá el usuario real con su ID Global de base de datos
      final userData = await _api.authenticate(deviceId, name, email);

      if (userData != null) {
        // 3. ¡Éxito! Guardamos la sesión con el ID REAL del backend
        await SessionService.saveSession(
          backendId: userData['id'], // El UUID que usaremos para todo
          name: userData['name'],
          email: userData['email'],
        );

        if (mounted) {
          // 4. Navegar al Home
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        }
      } else {
        // Error de API (probablemente conexión)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error de conexión. Intenta nuevamente.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ocurrió un error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "¡Bienvenido!",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text("Antes de empezar, dinos quién eres."),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words, // Capitalizar nombres
                      decoration: const InputDecoration(
                        labelText: "Tu Nombre (Obligatorio)", 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person)
                      ),
                      validator: (v) => v!.isEmpty ? "El nombre es requerido" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: "Email (Opcional)", 
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email)
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveAndContinue, // Deshabilitar si carga
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                        child: _isLoading 
                          ? const SizedBox(
                              height: 20, width: 20, 
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            )
                          : const Text("Comenzar", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}