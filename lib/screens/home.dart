import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/session_service.dart';
import 'package:neto/screens/groups.dart';
import 'package:neto/services/deep_links_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _api = ApiService();
  static const double _epsilon = 0.01;

  List<dynamic> _groups = [];
  double _totalBalance = 0.0;
  bool _isLoading = true;
  String? _userId;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    DeepLinkService().initDeepLinks(context);
  }

  @override
  void dispose() {
    DeepLinkService().dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final session = await SessionService.getSessionData();
    _userId = session['user_id'];
    _userName = session['name'] ?? 'Usuario';

    if (_userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final dashboardData = await _api.getDashboard(_userId!);
      if (mounted && dashboardData != null) {
        setState(() {
          _groups = dashboardData['groups'] ?? [];
          final rawBalance = dashboardData['total_balance'];
          _totalBalance = rawBalance is num ? rawBalance.toDouble() : 0.0;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      debugPrint('Error cargando dashboard: $e');
    }
  }

  double _toAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          'Neto',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF65D76A)))
          : RefreshIndicator(
              onRefresh: _loadData,
              color: const Color(0xFF65D76A),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildBalanceCard(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mesas Activas',
                            style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            '${_groups.length}',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    if (_groups.isEmpty)
                      _buildEmptyState()
                    else
                      ListView.builder(
                        itemCount: _groups.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemBuilder: (context, index) {
                          return _buildGroupCard(_groups[index]);
                        },
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBalanceCard() {
    String statusText = 'Estas al dia';
    if (_totalBalance > _epsilon) statusText = 'Te deben';
    if (_totalBalance < -_epsilon) statusText = 'Debes en total';

    final amountText = _totalBalance.abs().toStringAsFixed(2);

    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: 180,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF65D76A), Color(0xFF26A69A)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF65D76A).withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                statusText,
                style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 5),
              Text(
                '\$$amountText',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text(
                  'En ${_groups.length} mesas activas',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(dynamic group) {
    final userBalance = _toAmount(group['user_balance']);
    final hasCredit = userBalance > _epsilon;
    final hasDebt = userBalance < -_epsilon;

    Color balanceColor = Colors.grey;
    String balanceLabel = 'Al dia';
    String balanceAmount = '\$0.00';

    if (hasCredit) {
      balanceColor = Colors.green;
      balanceLabel = 'Te deben';
      balanceAmount = '\$${userBalance.abs().toStringAsFixed(2)}';
    } else if (hasDebt) {
      balanceColor = Colors.redAccent;
      balanceLabel = 'Debes';
      balanceAmount = '\$${userBalance.abs().toStringAsFixed(2)}';
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => GroupDetailScreen(
                groupId: group['id'],
                groupName: group['name'] ?? 'Mesa',
              ),
            ),
          );

          _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.table_restaurant_rounded, color: Colors.indigo),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group['name'] ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Codigo: ${group['code']}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    balanceAmount,
                    style: TextStyle(fontWeight: FontWeight.bold, color: balanceColor, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    balanceLabel,
                    style: TextStyle(fontWeight: FontWeight.bold, color: balanceColor, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.chevron_right, color: Colors.grey[300], size: 18),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Icon(Icons.layers_clear, size: 60, color: Colors.grey[300]),
        const SizedBox(height: 10),
        const Text('No tienes mesas activas', style: TextStyle(color: Colors.grey)),
      ],
    );
  }
}
