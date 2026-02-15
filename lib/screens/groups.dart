import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'group_share.dart';
import 'group_members.dart';
import 'add_expense.dart';
import 'edit_expense.dart';

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
  static const double _epsilon = 0.01;
  
  List<dynamic> _expenses = [];
  bool _isLoading = true;
  String? _userId; // Mi ID Global
  late String _groupName;

  // Variables calculadas
  double _groupTotalSpending = 0.0; 
  double _myBalance = 0.0;          

  @override
  void initState() {
    super.initState();
    _groupName = widget.groupName;
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
        _calculateTotals(); // Recalculamos matemÃ¡ticamente
        _isLoading = false;
      });
    }
  }

  // Magia matemÃ¡tica en el frontend para no saturar al backend
  void _calculateTotals() {
    double total = 0.0;
    double myBal = 0.0;

    for (var expense in _expenses) {
      final amount = _toAmount(expense['amount']);
      final category = (expense['category'] ?? 'expense').toString();

      // 1. Sumar al total del grupo (solo consumos)
      if (category != 'payment') {
        total += amount;
      }

      // 2. Calcular mi balance
      // Si yo paguÃ©, SUMO el total (porque puse la plata)
      if (expense['payer_id'] == _userId) {
        myBal += amount;
      }

      // Si yo participÃ© (shares), RESTO mi parte (porque la consumÃ­)
      List<dynamic> shares = expense['shares'] ?? [];
      for (var share in shares) {
        if (share['user_id'] == _userId) {
          myBal -= _toAmount(share['owed_amount']);
        }
      }
    }

    _groupTotalSpending = total;
    _myBalance = myBal;
  }

  double _toAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  void _showMessage(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
    String confirmLabel = 'Confirmar',
    Color confirmColor = Colors.redAccent,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(confirmLabel, style: TextStyle(color: confirmColor)),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<Map<String, dynamic>?> _pickExpense({
    required String title,
  }) async {
    final selectable = _expenses.whereType<Map<String, dynamic>>().toList(growable: false);
    if (selectable.isEmpty) {
      _showMessage('No hay gastos disponibles');
      return null;
    }

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text('${selectable.length}', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: selectable.length,
                  itemBuilder: (_, index) {
                    final expense = selectable[index];
                    final description = (expense['description'] ?? 'Gasto').toString();
                    final amount = _toAmount(expense['amount']);
                    return ListTile(
                      title: Text(description),
                      subtitle: Text('\$${amount.toStringAsFixed(2)}'),
                      onTap: () => Navigator.pop(sheetContext, expense),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editExpense(Map<String, dynamic> expense) async {
    final expenseId = (expense['id'] ?? '').toString();
    if (expenseId.isEmpty) {
      _showMessage('No se pudo identificar el gasto');
      return;
    }

    final currentDescription = (expense['description'] ?? '').toString();
    final currentAmount = _toAmount(expense['amount']);
    final sharesRaw = (expense['shares'] as List<dynamic>? ?? []);
    final participantIds = sharesRaw
        .whereType<Map<String, dynamic>>()
        .map((s) => (s['user_id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    final updated = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditExpenseScreen(
          groupId: widget.groupId,
          groupName: _groupName,
          expenseId: expenseId,
          initialDescription: currentDescription,
          initialAmount: currentAmount,
          category: (expense['category'] ?? 'expense').toString(),
          initialParticipantIds: participantIds,
        ),
      ),
    );

    if (updated == true) {
      await _fetchExpenses();
      _showMessage('Gasto modificado correctamente');
    }
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final userId = _userId;
    if (userId == null) {
      _showMessage('No se encontró tu sesión');
      return;
    }

    final expenseId = (expense['id'] ?? '').toString();
    if (expenseId.isEmpty) {
      _showMessage('No se pudo identificar el gasto');
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Eliminar Gasto',
      message: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      confirmColor: Colors.red,
    );

    if (!confirmed) return;

    final deleted = await _api.deleteExpense(expenseId, userId);
    if (!deleted) {
      _showMessage('No se pudo eliminar el gasto');
      return;
    }

    await _fetchExpenses();
    _showMessage('Gasto eliminado');
  }

  Future<void> _promptEditGroupName() async {
    final userId = _userId;
    if (userId == null) {
      _showMessage('No se encontró tu sesión');
      return;
    }

    final nameCtrl = TextEditingController(text: _groupName);
    var didSave = false;
    String? updatedName;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar Grupo'),
          content: TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(labelText: 'Nombre del grupo'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
                  _showMessage('El nombre no puede estar vacio');
                  return;
                }

                final updated = await _api.updateGroup(widget.groupId, name, userId);
                if (!updated) {
                  _showMessage('No se pudo editar el grupo');
                  return;
                }

                didSave = true;
                updatedName = name;
                if (mounted) Navigator.pop(dialogContext);
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    nameCtrl.dispose();

    if (!didSave) return;
    if (!mounted) return;

    setState(() => _groupName = updatedName ?? _groupName);
    _showMessage('Grupo actualizado');
  }

  Future<void> _leaveGroup() async {
    final userId = _userId;
    if (userId == null) {
      _showMessage('No se encontró tu sesión');
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Abandonar Grupo',
      message: 'Vas a salir de "$_groupName".',
      confirmLabel: 'Abandonar',
      confirmColor: Colors.orange,
    );

    if (!confirmed) return;

    final left = await _api.leaveGroup(widget.groupId, userId);
    if (!left) {
      _showMessage('No se pudo abandonar el grupo');
      return;
    }

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _deleteGroup() async {
    final userId = _userId;
    if (userId == null) {
      _showMessage('No se encontró tu sesión');
      return;
    }

    final confirmed = await _confirmAction(
      title: 'Eliminar Grupo',
      message: 'Se eliminará "$_groupName" para todos.',
      confirmLabel: 'Eliminar',
      confirmColor: Colors.red,
    );

    if (!confirmed) return;

    final deleted = await _api.deleteGroup(widget.groupId, userId);
    if (!deleted) {
      _showMessage('No se pudo eliminar el grupo');
      return;
    }

    if (mounted) Navigator.pop(context, true);
  }
  // --- ACCIONES DEL MENÚ ---
  
  void _showMenuOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              _buildOption(Icons.add_circle, 'Agregar Gasto', Colors.green, () async {
                Navigator.pop(context);
                final created = await Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (_) => AddExpenseScreen(
                      groupId: widget.groupId,
                      groupName: _groupName,
                    ),
                  ),
                );

                if (created == true) {
                  await _fetchExpenses();
                  _showMessage('Gasto agregado correctamente');
                }
              }),
              _buildOption(Icons.edit, 'Modificar Gasto', Colors.orange, () async {
                Navigator.pop(context);
                final picked = await _pickExpense(title: 'Selecciona un gasto para modificar');
                if (picked != null) {
                  await _editExpense(picked);
                }
              }),
              _buildOption(Icons.delete_outline, 'Eliminar Gasto', Colors.redAccent, () async {
                Navigator.pop(context);
                final picked = await _pickExpense(title: 'Selecciona un gasto para eliminar');
                if (picked != null) {
                  await _deleteExpense(picked);
                }
              }),
              const Divider(),
              _buildOption(Icons.person_add_alt_1, 'Invitar', const Color.fromARGB(255, 221, 199, 0), () {
                Navigator.pop(context);
                Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (_) => GroupShareScreen(
                      groupId: widget.groupId,
                      groupName: _groupName,
                    ),
                  ),
                );
              }),
              _buildOption(Icons.settings, 'Editar Grupo', Colors.blue, () async {
                Navigator.pop(context);
                await _promptEditGroupName();
              }),
              _buildOption(Icons.exit_to_app, 'Abandonar Grupo', Colors.grey, () async {
                Navigator.pop(context);
                await _leaveGroup();
              }),
              _buildOption(Icons.delete_forever, 'Eliminar Grupo', Colors.red, () async {
                Navigator.pop(context);
                await _deleteGroup();
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

  Future<void> _showExpenseActions(Map<String, dynamic> expense) async {
    final category = (expense['category'] ?? 'expense').toString();
    final isPayment = category == 'payment';

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orange),
                title: const Text('Modificar Gasto'),
                enabled: !isPayment,
                onTap: !isPayment
                    ? () async {
                        Navigator.pop(sheetContext);
                        await _editExpense(expense);
                      }
                    : null,
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
                title: const Text('Eliminar Gasto'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await _deleteExpense(expense);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_groupName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_outlined),
            tooltip: 'Ver participantes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupMembersScreen(
                    groupId: widget.groupId,
                    groupName: _groupName,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
        : Column(
            children: [
              // --- HEADER CARD ---
              _buildHeaderCard(),

              // --- TÃTULO ---
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
    final hasCredit = _myBalance > _epsilon;
    final hasDebt = _myBalance < -_epsilon;
    final isNeutral = !hasCredit && !hasDebt;

    late final Color color;
    late final List<Color> gradientColors;
    late final String status;

    if (hasCredit) {
      color = const Color(0xFF65D76A);
      gradientColors = [const Color(0xFF65D76A), const Color(0xFF26A69A)];
      status = "Te deben";
    } else if (hasDebt) {
      color = const Color(0xFFE57373);
      gradientColors = [const Color(0xFFEF5350), const Color(0xFFC62828)];
      status = "Debes";
    } else {
      color = const Color(0xFF90A4AE);
      gradientColors = [const Color(0xFF90A4AE), const Color(0xFF607D8B)];
      status = "Estas al dia";
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
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
          Text("\$${_groupTotalSpending.toStringAsFixed(2)}", 
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)
          ),
          const Divider(color: Colors.white24, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("$status: ", style: const TextStyle(color: Colors.white, fontSize: 16)),
              Text(
                isNeutral ? "\$0.00" : "\$${_myBalance.abs().toStringAsFixed(2)}",
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
        myShareAmount = _toAmount(share['owed_amount']);
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
        // Borde ROJO si debo pagar y no fui yo el que pagÃ³
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
        subtitle: Text(iPaid ? "Pagaste tu" : "Pagar otro miembro"),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "\$${_toAmount(expense['amount']).toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            
            // Subtexto inteligente
            if (isPayment)
              const Text("Pago", style: TextStyle(color: Colors.green, fontSize: 12))
            else if (iParticipate && !iPaid)
              Text("Tu parte: -\$${myShareAmount.toStringAsFixed(2)}", style: const TextStyle(color: Colors.red, fontSize: 12))
            else if (iPaid)
              const Text("Te deben", style: TextStyle(color: Colors.green, fontSize: 12))
          ],
        ),
        onTap: () async {
          if (expense is Map<String, dynamic>) {
            await _showExpenseActions(expense);
          }
        },
        onLongPress: () async {
          if (expense is Map<String, dynamic>) {
            await _deleteExpense(expense);
          }
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
          const Text("Aun no hay gastos", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

