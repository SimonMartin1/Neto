import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();
  
  // Controladores
  final TextEditingController _mesaNameController = TextEditingController();
  final TextEditingController _joinCodeController = TextEditingController();
  
  // Datos del usuario
  String? _userName;
  String? _userId; // EL ID GLOBAL (Backend)

  // Estado UI
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  // Cargar datos de la sesión (Ahora incluye el ID Global)
  Future<void> _loadUserData() async {
    final sessionData = await SessionService.getSessionData();
    setState(() {
      _userName = sessionData['name'];
      _userId = sessionData['user_id']; // Recuperamos el ID que nos dio /auth
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _mesaNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  // --- LÓGICA: CREAR GRUPO ---
  void _createGroup() async {
    if (_mesaNameController.text.trim().isEmpty) return;
    if (_userId == null) {
      _showError("Error de sesión. Reinicia la app.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Llamamos a la API enviando el ID Global
      final result = await _api.createGroup(_mesaNameController.text.trim(), _userId!);

      if (result != null && mounted) {
        final code = result['code'];
        
        // Cerramos el teclado
        FocusScope.of(context).unfocus();

        // Mostrar el código generado
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('¡Grupo Creado! 🎉'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Comparte este código con tus amigos:'),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Text(
                    code, 
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.indigo),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo
                  Navigator.pop(context, true); // Cerrar pantalla Join y recargar lista
                },
                child: const Text('Ir al Grupo'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      _showError("Error al crear grupo");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- LÓGICA: UNIRSE ---
  void _joinGroup(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return;
    if (_userId == null) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    try {
      // Llamamos a la API
      final result = await _api.joinGroup(cleanCode, _userId!);
      
      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Te uniste a ${result['group_name']}! 🚀')),
        );
        // Volvemos atrás con "true" para que MainScreen sepa que debe actualizarse
        Navigator.pop(context, true); 
      }
    } catch (e) {
      _showError(e.toString()); // El API Service lanza errores legibles ahora
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
    ));
  }

  // --- LÓGICA: ABRIR CÁMARA QR ---
  void _openQRScanner() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Escanear Código")),
          body: MobileScanner(
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  final code = barcode.rawValue!;
                  Navigator.pop(context, code); // Volver con el código
                  break; 
                }
              }
            },
          ),
        ),
      ),
    ).then((code) {
      if (code != null && code is String) {
        _joinCodeController.text = code;
        _joinGroup(code); // Intentar unirse automáticamente
      }
    });
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    return Container(
       decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          const SizedBox(height: 20),
          TabBar(
            controller: _tabController,
            labelColor: Colors.indigo,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.indigo,
            tabs: const [
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_circle_outline), SizedBox(width: 8), Text('Crear Mesa')])),
              Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search), SizedBox(width: 8), Text('Unirse')])),
            ],
          ),
          const SizedBox(height: 20),
          // Usamos un SizedBox con altura fija o Expanded si está en un layout completo
          // Como es un bottomSheet, mejor dejar que el contenido defina el alto o usar un alto fijo seguro
          SizedBox(
            height: 400, 
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCrearMesaTab(),
                _buildUnirseTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrearMesaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_userName != null) 
            Text('Hola, $_userName', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          const SizedBox(height: 10),
          const Text('Nuevo Grupo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          _buildInputField(
            controller: _mesaNameController,
            label: 'Nombre del Grupo',
            hint: 'Ej. Asado del Viernes',
            icon: Icons.edit,
          ),
          
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
              ),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Crear Grupo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnirseTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Unirse a un Grupo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          _buildInputField(
            controller: _joinCodeController,
            label: 'Código de Invitación',
            hint: 'Ej. XJ9-LM2',
            icon: Icons.key,
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity, 
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : () => _joinGroup(_joinCodeController.text),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Unirse', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          
          const SizedBox(height: 16),
          const Center(child: Text("- O -", style: TextStyle(color: Colors.grey))),
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _openQRScanner,
              icon: const Icon(Icons.qr_code_scanner, color: Colors.black87),
              label: const Text('Escanear QR', style: TextStyle(color: Colors.black87)),
              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.black87)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required IconData icon,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.indigo),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.indigo, width: 2)),
          ),
        ),
      ],
    );
  }
}