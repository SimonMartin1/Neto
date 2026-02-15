import 'package:flutter/material.dart';

import '../services/api_service.dart';
import 'expense_form.dart';

class EditExpenseScreen extends StatelessWidget {
  final String groupId;
  final String groupName;
  final String expenseId;
  final String initialDescription;
  final double initialAmount;
  final String category;
  final List<String> initialParticipantIds;
  final ApiService _api = ApiService();

  EditExpenseScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.expenseId,
    required this.initialDescription,
    required this.initialAmount,
    required this.category,
    required this.initialParticipantIds,
  });

  @override
  Widget build(BuildContext context) {
    return ExpenseFormScreen(
      groupId: groupId,
      title: 'Modificar gasto',
      submitLabel: 'Guardar cambios',
      initialDescription: initialDescription,
      initialAmount: initialAmount,
      initialParticipantIds: initialParticipantIds,
      onSubmit: ({
        required String userId,
        required String description,
        required double amount,
        required List<Map<String, dynamic>> shares,
      }) {
        return _api.updateExpense(
          expenseId: expenseId,
          requestingUserId: userId,
          amount: amount,
          description: description,
          shares: shares,
          category: category,
        );
      },
    );
  }
}
