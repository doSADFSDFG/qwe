import 'package:flutter/material.dart';

import '../sales/sales_page.dart';
import '../settings/settings_page.dart';
import 'main_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calut POS'),
        bottom: TabBar(
          controller: _controller,
          tabs: const [
            Tab(text: '메인'),
            Tab(text: '매출'),
            Tab(text: '설정'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: const [
          MainTab(),
          SalesPage(),
          SettingsPage(),
        ],
      ),
    );
  }
}
