import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
// import 'add_expense_screen.dart'; // (A futuro)

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final ApiService _api = ApiService();
  
  List<dynamic> _expenses = [];
  bool _isLoading = true;
  String? _userId; // Mi ID Global

  // Variables calculadas
  double _groupTotalSpending = 0.0; // Cuánto gastó el grupo en total
  double _myBalance = 0.0;          // Cuánto debo o me deben

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final session = await SessionService.getSessionData();
    _userId = session['user_id'];

    if (_userId != null) {
      await _fetchExpenses();
    }
  }

  Future<void> _fetchExpenses() async {
    setState(() => _isLoading = true);
    final expenses = await _api.getExpenses(widget.groupId);
    
    if (mounted) {
      setState(() {
        _expenses = expenses;
        _calculateTotals(); // Recalculamos matemáticamente
        _isLoading = false;
      });
    }
  }

  // Magia matemática en el frontend para no saturar al backend
  void _calculateTotals() {
    double total = 0.0;
    double myBal = 0.0;

    for (var expense in _expenses) {
      // 1. Sumar al total del grupo
      double amount = (expense['amount'] ?? 0).toDouble();
      total += amount;

      // 2. Calcular mi balance
      // Si yo pagué, SUMO el total (porque puse la plata)
      if (expense['payer_id'] == _userId) {
        myBal += amount;
      }

      // Si yo participé (shares), RESTO mi parte (porque la consumí)
      List<dynamic> shares = expense['shares'] ?? [];
      for (var share in shares) {
        if (share['user_id'] == _userId) {
          myBal -= (share['owed_amount'] ?? 0).toDouble();
        }
      }
    }

    _groupTotalSpending = total;
    _myBalance = myBal;
  }

  // --- ACCIONES DEL MENÚ ---
  
  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 20),
              
              // 1. Agregar Expensa
              _buildOption(Icons.add_circle, "Agregar Gasto", Colors.green, () {
                Navigator.pop(context);
                // Navigator.push(context, MaterialPageRoute(builder: (_) => AddExpenseScreen(...)));
                print("Ir a Agregar Gasto");
              }),

              // 2. Modificar Expensa
              _buildOption(Icons.edit, "Modificar Gasto", Colors.orange, () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Toca un gasto de la lista para editarlo")));
              }),

              // 3. Eliminar Expensa
              _buildOption(Icons.delete_outline, "Eliminar Gasto", Colors.redAccent, () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Mantén presionado un gasto para borrarlo")));
              }),
              
              const Divider(),

              // 4. Editar Grupo
              _buildOption(Icons.settings, "Editar Grupo", Colors.blue, () {
                Navigator.pop(context);
                // Lógica editar nombre del grupo
              }),

              // 5. Abandonar Grupo
              _buildOption(Icons.exit_to_app, "Abandonar Grupo", Colors.grey, () async {
                 Navigator.pop(context);
                 await _api.leaveGroup(widget.groupId, _userId!);
                 if (mounted) Navigator.pop(context, true); // Volver al home
              }),

              // 6. Eliminar Grupo
              _buildOption(Icons.delete_forever, "Eliminar Grupo", Colors.red, () async {
                 Navigator.pop(context);
                 // Confirmación...
                 await _api.deleteGroup(widget.groupId, _userId!); // Necesitas implementar este endpoint
                 if (mounted) Navigator.pop(context, true);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(IconData icon, String text, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
        child: Icon(icon, color: color),
      ),
      title: Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.groupName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : Column(
            children: [
              // --- HEADER CARD ---
              _buildHeaderCard(),

              // --- TÍTULO ---
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    const Text("Movimientos", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text("${_expenses.length} gastos", style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),

              // --- LISTA DE EXPENSAS ---
              Expanded(
                child: _expenses.isEmpty 
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        return _buildExpenseItem(_expenses[index]);
                      },
                    ),
              ),
            ],
          ),
      
      // --- FAB CON MORE VERTICAL ---
      floatingActionButton: FloatingActionButton(
        onPressed: _showMenuOptions,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.more_vert, color: Colors.white),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeaderCard() {
    bool inFavor = _myBalance >= 0;
    Color color = inFavor ? const Color(0xFF65D76A) : const Color(0xFFE57373);
    String status = inFavor ? "Te deben" : "Debes";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: inFavor 
            ? [const Color(0xFF65D76A), const Color(0xFF26A69A)] 
            : [const Color(0xFFEF5350), const Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        children: [
          const Text("Gasto Total del Grupo", style: TextStyle(color: Colors.white70)),
          Text("\$${_groupTotalSpending.toStringAsFixed(0)}", 
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
          ),
          const Divider(color: Colors.white24, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("$status: ", style: const TextStyle(color: Colors.white, fontSize: 16)),
              Text("\$${_myBalance.abs().toStringAsFixed(0)}", 
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildExpenseItem(dynamic expense) {
    bool iPaid = expense['payer_id'] == _userId;
    
    // Verificar si yo estoy en las shares (si debo pagar algo de esto)
    bool iParticipate = false;
    double myShareAmount = 0.0;
    List<dynamic> shares = expense['shares'] ?? [];
    for (var share in shares) {
      if (share['user_id'] == _userId) {
        iParticipate = true;
        myShareAmount = (share['owed_amount'] ?? 0).toDouble();
        break;
      }
    }

    String category = expense['category'] ?? 'expense';
    bool isPayment = category == 'payment';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        // Borde ROJO si debo pagar y no fui yo el que pagó
        side: BorderSide(
          color: (iParticipate && !iPaid && !isPayment) ? Colors.redAccent.withOpacity(0.5) : Colors.transparent,
          width: 1
        )
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isPayment ? Colors.green.withOpacity(0.1) : Colors.indigo.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPayment ? Icons.attach_money : Icons.shopping_bag_outlined, 
            color: isPayment ? Colors.green : Colors.indigo
          ),
        ),
        title: Text(expense['description'] ?? 'Gasto', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(iPaid ? "Pagaste tú" : "Pagó otro miembro"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("\$${expense['amount']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            
            // Subtexto inteligente
            if (isPayment)
              const Text("Pago", style: TextStyle(color: Colors.green, fontSize: 12))
            else if (iParticipate && !iPaid)
              Text("Tu parte: -\$${myShareAmount.toStringAsFixed(0)}", style: const TextStyle(color: Colors.red, fontSize: 12))
            else if (iPaid)
              const Text("Te deben", style: TextStyle(color: Colors.green, fontSize: 12))
          ],
        ),
        onTap: () {
          // Aquí podríamos ir a editar
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey[300]),
          const SizedBox(height: 10),
          const Text("Aún no hay gastos", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}