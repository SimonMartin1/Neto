import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'expense_form.dart';

class AddExpenseScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final ApiService _api = ApiService();

  AddExpenseScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseFormScreen(
      groupId: groupId,
      title: 'Agregar gasto',
      submitLabel: 'Guardar gasto',
      onSubmit: ({
        required String userId,
        required String description,
        required double amount,
        required List<Map<String, dynamic>> shares,
      }) {
        return _api.createExpense(
          groupId: groupId,
          payerId: userId,
          amount: amount,
          description: description,
          shares: shares,
        );
      },
    );
  }
}
