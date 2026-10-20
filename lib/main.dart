import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'data/issue_store.dart';
import 'screens/dashboard_screen.dart';
import 'screens/issues_screen.dart';
import 'screens/personnel_screen.dart';
import 'screens/projects_screen.dart';
import 'services/excel_export.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const IssueTrackerApp());
}

class IssueTrackerApp extends StatelessWidget {
  const IssueTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile App Issue Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B4D3E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final IssueStore _store = IssueStore();
  int _index = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await _store.load();
      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _export() async {
    try {
      final path = await ExcelExportService.export(
        issues: _store.issues,
        projects: _store.projects,
      );
      if (!mounted || path == null) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Exported to $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Failed to load data:\n$_error'),
          ),
        ),
      );
    }

    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        return Scaffold(
          body: Row(
            children: [
              NavigationRail(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                labelType: NavigationRailLabelType.all,
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Icon(
                        Icons.bug_report_outlined,
                        color: Theme.of(context).colorScheme.primary,
                        size: 28,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tracker',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                trailing: Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: IconButton.filledTonal(
                        tooltip: 'Export to Excel',
                        onPressed: _export,
                        icon: const Icon(Icons.file_download_outlined),
                      ),
                    ),
                  ),
                ),
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.list_alt_outlined),
                    selectedIcon: Icon(Icons.list_alt),
                    label: Text('Issues'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard),
                    label: Text('Dashboard'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.folder_outlined),
                    selectedIcon: Icon(Icons.folder),
                    label: Text('Projects'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.people_outline),
                    selectedIcon: Icon(Icons.people),
                    label: Text('Personnel'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: [
                    IssuesScreen(store: _store),
                    DashboardScreen(store: _store),
                    ProjectsScreen(store: _store),
                    PersonnelScreen(store: _store),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
