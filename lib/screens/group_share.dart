import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../services/api_service.dart';

class GroupShareScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String? groupCode; // Código del grupo (si es diferente del ID)

  const GroupShareScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    this.groupCode,
  });

  @override
  State<GroupShareScreen> createState() => _GroupShareScreenState();
}

class _GroupShareScreenState extends State<GroupShareScreen> {
  late String _codeToDisplay;
  bool _isLoading = true;
  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadGroupData();
  }

  Future<void> _loadGroupData() async {
    final groupData = await _api.getGroup(widget.groupId);
    
    if (mounted) {
      if (groupData != null && groupData['code'] != null) {
        setState(() {
          _codeToDisplay = groupData['code'];
          _isLoading = false;
        });
      } else {
        // Si la API falla, usar el groupId como fallback
        setState(() {
          _codeToDisplay = widget.groupCode ?? widget.groupId;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _shareInvitation() async {
    final link = "https://neto.galpondelarte.com.ar/invite/$_codeToDisplay";
    final message = "¡Sumate a mi mesa en Neto para dividir gastos!\n"
        "Grupo: ${widget.groupName}\n"
        "Accede aquí: $link";

    await Share.share(
      message,
      subject: "Invitación a Neto - ${widget.groupName}",
    );
  }

  void _copyToClipboard() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Código copiado al portapapeles")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          "Invitar al Grupo",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),

              // --- TÍTULO Y DESCRIPCIÓN ---
              Text(
                widget.groupName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Comparte este código con tus amigos para que se unan al grupo",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // --- CÓDIGO DEL GRUPO ---
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  border: Border.all(color: Colors.indigo, width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Código del Grupo",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _codeToDisplay,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _copyToClipboard,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.copy, size: 16, color: Colors.indigo),
                          const SizedBox(width: 6),
                          const Text(
                            "Copiar código",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.indigo,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- QR CODE ---
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: "https://neto.galpondelarte.com.ar/invite/$_codeToDisplay",
                      version: QrVersions.auto,
                      size: 250,
                      gapless: false,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                      embeddedImage: null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Escanea este código",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // --- BOTÓN DE COMPARTIR ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareInvitation,
                  icon: const Icon(Icons.share, size: 20),
                  label: const Text(
                    "Compartir Invitación",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- INFORMACIÓN ADICIONAL ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Cómo funciona",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "1. Comparte el código o el QR con tus amigos\n"
                      "2. Ellos ingresarán el código en la app\n"
                      "3. Se unirán automáticamente al grupo\n"
                      "4. Podrán ver y dividir gastos contigo",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
