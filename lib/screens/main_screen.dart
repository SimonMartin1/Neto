import 'package:flutter/material.dart';
import 'package:neto/screens/join.dart';
import 'package:neto/screens/home.dart';
import 'package:neto/screens/settings.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {  
  int _selectedIndex = 0;
  int _homeRefreshTick = 0;

  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showJoinModal() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.8, // 70% de la pantalla 
        child: const JoinScreen(),
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _homeRefreshTick++;
        _selectedIndex = 0;
      });
    }
  }

  Widget _buildCurrentScreen() {
    if (_selectedIndex == 0) {
      return HomeScreen(key: ValueKey('home_$_homeRefreshTick'));
    }
    if (_selectedIndex == 2) {
      return const SettingsScreen();
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          body: _buildCurrentScreen(),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) {
              // Si el índice es 1 (centro), abre el modal en lugar de cambiar de pantalla
              if (index == 1) {
                _showJoinModal();
              } else {
                _onItemTapped(index);
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: SizedBox.shrink(), 
                label: '',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: 'Settings',
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.indigo.shade700],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _showJoinModal,
                  borderRadius: BorderRadius.circular(80),
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
