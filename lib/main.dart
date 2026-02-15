import 'package:flutter/material.dart';
import 'services/session_service.dart'; // Tu servicio de sesión
import 'screens/welcome_screen.dart';   // Tu pantalla de bienvenida
import 'screens/main_screen.dart';      // Tu pantalla principal
import 'package:neto/core/app_theme.dart';          // Tu tema (si lo tienes en otro archivo)

void main() async {
  // 1. Necesario para usar SharedPreferences antes de arrancar la UI
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Verificamos la sesión (esperamos la respuesta)
  final bool hasSession = await SessionService.hasSession();

  // 3. Arrancamos la App pasándole la variable
  runApp(MyApp(hasSession: hasSession));
}

class MyApp extends StatelessWidget {
  final bool hasSession; // Recibimos el estado de la sesión

  // Constructor que obliga a recibir el booleano
  const MyApp({super.key, required this.hasSession});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neto',
      debugShowCheckedModeBanner: false, // Quitamos la etiqueta 'Debug'
      
      // Aquí aplicas tu tema globalmente
      theme: AppTheme.lightTheme, 
      
      // 4. Aquí usamos la variable para decidir qué pantalla mostrar
      home: hasSession ? const MainScreen() : const WelcomeScreen(),
    );
  }
}