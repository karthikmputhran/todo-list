import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:email_validator/email_validator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const ToDoApp());
}

class ToDoApp extends StatefulWidget {
  const ToDoApp({super.key});
  @override
  State<ToDoApp> createState() => _ToDoAppState();
}

class _ToDoAppState extends State<ToDoApp> {
  ThemeMode _themeMode = ThemeMode.light;
  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'To-Do List',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(brightness: Brightness.light, primarySwatch: Colors.red),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.red,
      ),
      home: LoginPage(onThemeToggle: toggleTheme),
    );
  }
}

class LoginPage extends StatefulWidget {
  final VoidCallback onThemeToggle;
  const LoginPage({super.key, required this.onThemeToggle});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoginMode = true;

  Future<void> _loginOrSignup() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final prefs = await SharedPreferences.getInstance();

    if (!EmailValidator.validate(email)) {
      _showMessage('Enter valid email');
      return;
    }

    if (password.length < 8 ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      _showMessage(
        'Password must be at least 8 characters and include numbers & special characters',
      );
      return;
    }

    if (isLoginMode) {
      final storedPass = prefs.getString('user_$email');
      if (storedPass == null || storedPass != password) {
        _showMessage('Invalid credentials');
        return;
      }
    } else {
      if (prefs.containsKey('user_$email')) {
        _showMessage('User already exists');
        return;
      }
      await prefs.setString('user_$email', password);
    }

    await prefs.setString('logged_in_user', email);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            Dashboard(username: email, onThemeToggle: widget.onThemeToggle),
      ),
    );
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/img/background.jpg',
          fit: BoxFit.cover,
          height: double.infinity,
          width: double.infinity,
        ),
        Scaffold(
          backgroundColor: Colors.black.withAlpha(150),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Text(
                      isLoginMode ? 'Login' : 'Sign Up',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildRoundedField(_emailController, 'Email'),
                    const SizedBox(height: 16),
                    _buildRoundedField(
                      _passwordController,
                      'Password',
                      obscure: true,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loginOrSignup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 14,
                        ),
                      ),
                      child: Text(
                        isLoginMode ? 'Login' : 'Sign Up',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLoginMode = !isLoginMode;
                        });
                      },
                      child: Text(
                        isLoginMode
                            ? "Don't have an account? Sign Up"
                            : "Already have an account? Login",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoundedField(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

class Dashboard extends StatefulWidget {
  final String username;
  final VoidCallback onThemeToggle;
  const Dashboard({
    super.key,
    required this.username,
    required this.onThemeToggle,
  });
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final TextEditingController _listController = TextEditingController();
  List<String> lists = [];

  @override
  void initState() {
    super.initState();
    loadLists();
  }

  Future<void> loadLists() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      lists = prefs.getStringList('${widget.username}_lists') ?? [];
    });
  }

  Future<void> addList() async {
    final prefs = await SharedPreferences.getInstance();
    final newList = _listController.text.trim();
    if (newList.isEmpty) return;
    lists.add(newList);
    await prefs.setStringList('${widget.username}_lists', lists);
    _listController.clear();
    setState(() {});
  }

  Future<void> deleteList(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    lists.remove(listName);
    await prefs.setStringList('${widget.username}_lists', lists);
    await prefs.remove('${widget.username}_${listName}_tasks');
    setState(() {});
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_user');
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LoginPage(onThemeToggle: widget.onThemeToggle),
      ),
    );
  }

  Future<void> shareListsAsPDF() async {
    final pdf = pw.Document();
    final prefs = await SharedPreferences.getInstance();
    for (var list in lists) {
      final tasks =
          prefs.getStringList('${widget.username}_${list}_tasks') ?? [];
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('List: $list', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 5),
              for (var task in tasks)
                pw.Bullet(text: task, style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 16),
            ],
          ),
        ),
      );
    }
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/task_lists.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([
      XFile(file.path),
    ], text: "Here’s my task list PDF");
  }

  Future<void> shareSingleListAsPDF(String listName) async {
    final prefs = await SharedPreferences.getInstance();
    final tasks =
        prefs.getStringList('${widget.username}_${listName}_tasks') ?? [];
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('List: $listName', style: pw.TextStyle(fontSize: 18)),
            pw.SizedBox(height: 5),
            for (var task in tasks)
              pw.Bullet(text: task, style: pw.TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${listName}_tasks.pdf");
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles([
      XFile(file.path),
    ], text: "Tasks for list: $listName");
  }

  void _navigateToTaskPage(String list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskPage(username: widget.username, listName: list),
      ),
    ).then((_) => loadLists());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(widget.username.split('@')[0]),
              accountEmail: Text(widget.username),
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Toggle Theme'),
              onTap: () {
                widget.onThemeToggle();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Lists'),
              onTap: () {
                shareListsAsPDF();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: logout,
            ),
          ],
        ),
      ),
      appBar: AppBar(title: const Text("Your Lists")),
      body: ListView.builder(
        itemCount: lists.length,
        itemBuilder: (context, index) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: ListTile(
              title: Text(lists[index]),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf),
                    onPressed: () => shareSingleListAsPDF(lists[index]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => deleteList(lists[index]),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => _navigateToTaskPage(lists[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addList,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          controller: _listController,
          decoration: const InputDecoration(
            hintText: 'Enter new list name',
            border: OutlineInputBorder(),
          ),
        ),
      ),
    );
  }
}

class TaskPage extends StatefulWidget {
  final String username;
  final String listName;
  const TaskPage({super.key, required this.username, required this.listName});
  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  final TextEditingController _taskController = TextEditingController();
  DateTime? _selectedDeadline;
  List<String> tasks = [];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  Future<void> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      tasks =
          prefs.getStringList('${widget.username}_${widget.listName}_tasks') ??
              [];
    });
  }

  Future<void> addTask() async {
    final task = _taskController.text.trim();
    if (task.isEmpty) return;
    final deadline = _selectedDeadline != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDeadline!)
        : "No deadline";
    final taskWithDeadline = "$task (Due: $deadline)";
    final prefs = await SharedPreferences.getInstance();
    tasks.add(taskWithDeadline);
    await prefs.setStringList(
      '${widget.username}_${widget.listName}_tasks',
      tasks,
    );
    _taskController.clear();
    _selectedDeadline = null;
    setState(() {});
  }

  Future<void> deleteTask(int index) async {
    final prefs = await SharedPreferences.getInstance();
    tasks.removeAt(index);
    await prefs.setStringList(
      '${widget.username}_${widget.listName}_tasks',
      tasks,
    );
    setState(() {});
  }

  Future<void> _pickDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.listName)),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (_, i) => Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            title: Text(
              tasks[i],
              style: TextStyle(
                decoration: tasks[i].startsWith('[x] ')
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            leading: Checkbox(
              value: tasks[i].startsWith('[x] '),
              onChanged: (val) async {
                final prefs = await SharedPreferences.getInstance();
                setState(() {
                  if (val == true && !tasks[i].startsWith('[x] ')) {
                    tasks[i] = '[x] ${tasks[i]}';
                  } else if (val == false && tasks[i].startsWith('[x] ')) {
                    tasks[i] = tasks[i].replaceFirst('[x] ', '');
                  }
                });
                await prefs.setStringList(
                  '${widget.username}_${widget.listName}_tasks',
                  tasks,
                );
              },
            ),
            trailing: Wrap(
              spacing: 8,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    final edited = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        final editController = TextEditingController(
                          text: tasks[i].replaceFirst('[x] ', ''),
                        );
                        return AlertDialog(
                          title: const Text('Edit Task'),
                          content: TextField(controller: editController),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, editController.text),
                              child: const Text('Save'),
                            ),
                          ],
                        );
                      },
                    );
                    if (edited != null && edited.trim().isNotEmpty) {
                      final isDone = tasks[i].startsWith('[x] ');
                      tasks[i] =
                          isDone ? '[x] ${edited.trim()}' : edited.trim();
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setStringList(
                        '${widget.username}_${widget.listName}_tasks',
                        tasks,
                      );
                      setState(() {});
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => deleteTask(i),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: addTask,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _taskController,
              decoration: const InputDecoration(
                hintText: 'Enter new task',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.date_range),
              label: Text(
                _selectedDeadline == null
                    ? 'Pick Deadline (Optional)'
                    : 'Deadline: ${DateFormat('yyyy-MM-dd').format(_selectedDeadline!)}',
              ),
              onPressed: _pickDeadline,
            ),
          ],
        ),
      ),
    );
  }
}
