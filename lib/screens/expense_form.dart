import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/session_service.dart';

typedef ExpenseSubmitHandler = Future<bool> Function({
  required String userId,
  required String description,
  required double amount,
  required List<Map<String, dynamic>> shares,
});

class ExpenseFormScreen extends StatefulWidget {
  final String groupId;
  final String title;
  final String submitLabel;
  final String? initialDescription;
  final double? initialAmount;
  final List<String>? initialParticipantIds;
  final ExpenseSubmitHandler onSubmit;

  const ExpenseFormScreen({
    super.key,
    required this.groupId,
    required this.title,
    required this.submitLabel,
    required this.onSubmit,
    this.initialDescription,
    this.initialAmount,
    this.initialParticipantIds,
  });

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final ApiService _api = ApiService();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String? _userId;
  String _userName = 'Tu';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  List<Map<String, dynamic>> _members = [];
  final Set<String> _selectedMemberIds = <String>{};

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.initialDescription ?? '';
    if (widget.initialAmount != null) {
      _amountController.text = widget.initialAmount!.toStringAsFixed(2);
    }
    _loadData();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final session = await SessionService.getSessionData();
    final userId = session['user_id'];

    if (userId == null || userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'No se encontro tu sesion';
        _isLoading = false;
      });
      return;
    }

    final membersRaw = await _api.getGroupMembers(widget.groupId);
    final members = membersRaw.whereType<Map<String, dynamic>>().toList(growable: false);

    if (!mounted) return;

    final validMemberIds = members
        .map((m) => (m['id'] ?? '').toString())
        .where((id) => id.isNotEmpty)
        .toSet();

    final initialIds = (widget.initialParticipantIds ?? const <String>[])
        .where(validMemberIds.contains)
        .toSet();

    setState(() {
      _userId = userId;
      _userName = (session['name'] ?? 'Tu').toString();
      _members = members;

      _selectedMemberIds
        ..clear()
        ..addAll(initialIds.isNotEmpty ? initialIds : validMemberIds);

      _isLoading = false;
    });
  }

  double get _amountValue {
    final normalized = _amountController.text.replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0.0;
  }

  List<Map<String, dynamic>> _buildShares({
    required double amount,
    required List<String> participantIds,
  }) {
    final totalCents = (amount * 100).round();
    final count = participantIds.length;
    final base = totalCents ~/ count;
    final remainder = totalCents % count;

    final shares = <Map<String, dynamic>>[];
    for (var i = 0; i < participantIds.length; i++) {
      final owedCents = base + (i < remainder ? 1 : 0);
      shares.add({
        'user_id': participantIds[i],
        'owed_amount': owedCents / 100,
      });
    }
    return shares;
  }

  Future<void> _saveExpense() async {
    final userId = _userId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontro tu usuario')),
      );
      return;
    }

    final description = _descriptionController.text.trim();
    final amount = _amountValue;
    final participantIds = _members
        .map((m) => (m['id'] ?? '').toString())
        .where((id) => _selectedMemberIds.contains(id))
        .toList(growable: false);

    if (description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un nombre para el gasto')),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto valido')),
      );
      return;
    }

    if (participantIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un participante')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final shares = _buildShares(amount: amount, participantIds: participantIds);

    final ok = await widget.onSubmit(
      userId: userId,
      description: description,
      amount: amount,
      shares: shares,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el gasto')),
      );
      return;
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amountValue;
    final selectedCount = _selectedMemberIds.length;
    final split = (amount > 0 && selectedCount > 0) ? (amount / selectedCount) : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TextField(
                                    controller: _descriptionController,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre del gasto',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    controller: _amountController,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                      labelText: 'Monto total',
                                      prefixText: '\$',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Pagador: $_userName',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Participantes',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Selecciona entre quienes se reparte el gasto',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 10),
                                  ..._members.map((member) {
                                    final id = (member['id'] ?? '').toString();
                                    final name = (member['name'] ?? 'Sin nombre').toString();
                                    final email = (member['email'] ?? '').toString();
                                    final checked = _selectedMemberIds.contains(id);

                                    return CheckboxListTile(
                                      dense: true,
                                      value: checked,
                                      contentPadding: EdgeInsets.zero,
                                      activeColor: Colors.indigo,
                                      title: Text(name),
                                      subtitle: email.isNotEmpty ? Text(email) : null,
                                      onChanged: (value) {
                                        setState(() {
                                          if ((value ?? false) == true) {
                                            _selectedMemberIds.add(id);
                                          } else {
                                            _selectedMemberIds.remove(id);
                                          }
                                        });
                                      },
                                    );
                                  }),
                                  const Divider(height: 20),
                                  Row(
                                    children: [
                                      const Icon(Icons.calculate_outlined, size: 18, color: Colors.indigo),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          selectedCount > 0
                                              ? 'Cada participante paga: \$${split.toStringAsFixed(2)}'
                                              : 'Selecciona participantes para calcular el reparto',
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveExpense,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Text(
                                    widget.submitLabel,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
