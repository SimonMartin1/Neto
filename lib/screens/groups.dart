import 'package:flutter/material.dart';
import 'package:neto/core/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> listaMesas = [
      {'titulo': 'Asaditooo', 'monto': 1500, 'icono': Icons.local_fire_department},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Neto')),
      body: Column( 
        children: [
          const SizedBox(height: 30),
          
          SizedBox(
            width: 350,
            height: 180,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF65D76A), Color(0xFF329E7C)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Balance Total',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    const Text('Te deben \$12.500',
                        style: TextStyle(fontSize: 20, color: Colors.white)),
                    const Text('Repartido en ' + 'mesas activas',
                        style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
            child: const Text(
              'Mesas Activas',
              style: TextStyle(
                fontSize: 22.0,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 0, 0, 0),
                letterSpacing: 1.2,
              ),
            ),
          ),

          
          Expanded(
            child: ListView.builder(
              itemCount: listaMesas.length, 
              padding: const EdgeInsets.symmetric(horizontal: 20), 
              itemBuilder: (context, index) {
                final mesa = listaMesas[index]; 
                
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 12), 
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(10),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(mesa['icono'], color: Colors.green),
                    ),
                    title: Text(mesa['titulo'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('Último gasto: Ayer'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Debes \$${mesa['monto']}',
                          style: const TextStyle(
                            color: Colors.redAccent, 
                            fontWeight: FontWeight.bold
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      print('Tocaste la mesa: ${mesa['titulo']}');
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}











