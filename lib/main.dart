import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BackOfHouseApp());
}

class BackOfHouseApp extends StatelessWidget {
  const BackOfHouseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Menu Builder',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        scaffoldBackgroundColor: const Color(0xFFF9F6EE),
        useMaterial3: true,
      ),
      home: const MenuListPage(),
    );
  }
}

// =================== MENU LIST PAGE ===================
class MenuListPage extends StatefulWidget {
  const MenuListPage({super.key});

  @override
  State<MenuListPage> createState() => _MenuListPageState();
}

class _MenuListPageState extends State<MenuListPage> {
  List<Map<String, dynamic>> menus = [];

  @override
  void initState() {
    super.initState();
    _loadMenus();
  }

  Future<void> _loadMenus() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString('menus');
    if (stored != null) {
      setState(() {
        menus = List<Map<String, dynamic>>.from(jsonDecode(stored));
      });
    }
  }

  Future<void> _saveMenus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('menus', jsonEncode(menus));
  }

  void _createNewMenu() async {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create New Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Menu name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              final newMenu = {
                'id': const Uuid().v4(),
                'name': nameController.text.trim(),
                'description': descController.text.trim(),
                'recipes': [],
                'thumbnail': null,
              };
              setState(() {
                menus.add(newMenu);
              });
              _saveMenus();
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MenuDashboard(menuId: newMenu['id'] as String),
                ),
              ).then((_) => _loadMenus());
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _editMenu(String id) async {
    final index = menus.indexWhere((m) => (m['id'] as String) == id);
    if (index == -1) return;
    final menu = menus[index];
    final nameController = TextEditingController(text: menu['name'] as String? ?? '');
    final descController = TextEditingController(text: menu['description'] as String? ?? '');
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Menu'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(hintText: 'Menu name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'Description (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              setState(() {
                menus[index]['name'] = nameController.text.trim();
                menus[index]['description'] = descController.text.trim();
              });
              _saveMenus();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _deleteMenu(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Menu?'),
        content: const Text('This will remove the menu and all its recipes.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => menus.removeWhere((m) => (m['id'] as String) == id));
      _saveMenus();
    }
  }

  void _openMenu(String menuId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MenuDashboard(menuId: menuId)),
    );
    _loadMenus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDFBF5),
        elevation: 0,
        title: const Text('Menu Builder v1.0'),
      ),
      body: menus.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No menus yet — start your first one!'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createNewMenu,
                    child: const Text('Start Menu'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: menus.length,
              itemBuilder: (context, i) {
                final m = menus[i];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: m['thumbnail'] != null
                        ? Image.memory(base64Decode(m['thumbnail'] as String), width: 80, height: 80, fit: BoxFit.cover)
                        : Container(
                            width: 80,
                            height: 80,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 40),
                          ),
                    title: Text(m['name'] as String? ?? ''),
                    subtitle: Text(m['description'] as String? ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editMenu(m['id'] as String),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteMenu(m['id'] as String),
                        ),
                      ],
                    ),
                    onTap: () => _openMenu(m['id'] as String),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewMenu,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// =================== MENU DASHBOARD ===================
class MenuDashboard extends StatefulWidget {
  final String menuId;
  const MenuDashboard({super.key, required this.menuId});

  @override
  State<MenuDashboard> createState() => _MenuDashboardState();
}

class _MenuDashboardState extends State<MenuDashboard> {
  Map<String, dynamic>? menu;
  List<Map<String, dynamic>> recipes = [];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString('menus');
    if (stored == null) return;
    final menusList = List<Map<String, dynamic>>.from(jsonDecode(stored));
    final foundMenu = menusList.firstWhere(
      (m) => (m['id'] as String) == widget.menuId,
      orElse: () => <String, dynamic>{},
    );
    if (foundMenu.isEmpty) return;
    setState(() {
      menu = foundMenu;
      recipes = List<Map<String, dynamic>>.from(menu?['recipes'] ?? []);
    });
  }

  Future<void> _saveMenu() async {
    if (menu == null || (menu!['id'] as String?) == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString('menus');
    if (stored == null) return;
    final menusList = List<Map<String, dynamic>>.from(jsonDecode(stored));
    final index = menusList.indexWhere((m) => (m['id'] as String) == widget.menuId);
    if (index != -1) {
      menusList[index] = {
        ...menu!,
        'recipes': recipes,
        'thumbnail': menu!['thumbnail'],
      };
      await prefs.setString('menus', jsonEncode(menusList));
    }
  }

  Future<void> _navigateToAddRecipe() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRecipePage()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        recipes.add(result);
      });
      await _saveMenu();
    }
  }

  Future<void> _navigateToEditRecipe(Map<String, dynamic> recipe) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddRecipePage(recipe: recipe)),
    );
    if (result != null && result is Map<String, dynamic>) {
      final index = recipes.indexWhere((r) => (r['id'] as String) == (recipe['id'] as String));
      if (index != -1) {
        setState(() {
          recipes[index] = result;
        });
        await _saveMenu();
      }
    }
  }

  Future<void> _deleteRecipe(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Recipe?'),
        content: Text('This will remove "${recipes[index]['name']}" from the menu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      setState(() {
        recipes.removeAt(index);
      });
      await _saveMenu();
    }
  }

  Future<void> _uploadMenuPhoto() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((event) async {
      final file = uploadInput.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((event) async {
        final photoBase64 = (reader.result as String).split(',').last;
        setState(() {
          menu?['thumbnail'] = photoBase64;
        });
        await _saveMenu();
      });
    });
  }

  Future<void> _openRecipe(Map<String, dynamic> recipe) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipeCardPage(recipe: recipe)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (menu == null || (menu!['id'] as String?) == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(menu!['name'] as String? ?? ''),
        actions: [
          IconButton(
            onPressed: _uploadMenuPhoto,
            icon: const Icon(Icons.image),
            tooltip: 'Upload menu photo',
          ),
        ],
      ),
      body: recipes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No recipes in this menu yet'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _navigateToAddRecipe,
                    child: const Text('Add Recipe'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: recipes.length,
              itemBuilder: (context, i) {
                final r = recipes[i];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: r['photo'] != null
                        ? Image.memory(base64Decode(r['photo'] as String), width: 60, height: 60, fit: BoxFit.cover)
                        : const Icon(Icons.image_not_supported, size: 40),
                    title: Text(r['name'] as String? ?? ''),
                    subtitle: Text(r['description'] as String? ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _navigateToEditRecipe(r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteRecipe(i),
                        ),
                      ],
                    ),
                    onTap: () => _openRecipe(r),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddRecipe,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// =================== ADD/EDIT RECIPE PAGE ===================
class AddRecipePage extends StatefulWidget {
  final Map<String, dynamic>? recipe;
  const AddRecipePage({super.key, this.recipe});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _servingsController;
  late final TextEditingController _notesController;

  late List<Map<String, String>> _ingredients;
  late List<String> _steps;
  late String? _photoBase64;

  late List<TextEditingController> _ingNameControllers;
  late List<TextEditingController> _ingQtyControllers;
  late List<TextEditingController> _ingUnitControllers;
  late List<TextEditingController> _stepControllers;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe?['name'] as String? ?? '');
    _descController = TextEditingController(text: widget.recipe?['description'] as String? ?? '');
    _servingsController = TextEditingController(text: widget.recipe?['servings'] as String? ?? '1');
    _notesController = TextEditingController(text: widget.recipe?['notes'] as String? ?? '');

    _ingredients = List<Map<String, String>>.from(widget.recipe?['ingredients'] ?? []);
    _steps = List<String>.from(widget.recipe?['steps'] ?? []);
    _photoBase64 = widget.recipe?['photo'] as String?;

    _ingNameControllers = _ingredients.map((ing) => TextEditingController(text: ing['name'] ?? '')).toList();
    _ingQtyControllers = _ingredients.map((ing) => TextEditingController(text: ing['qty'] ?? '')).toList();
    _ingUnitControllers = _ingredients.map((ing) => TextEditingController(text: ing['unit'] ?? '')).toList();
    _stepControllers = _steps.map((s) => TextEditingController(text: s)).toList();

    // Ensure controllers lists match ingredients length
    while (_ingNameControllers.length < _ingredients.length) {
      _ingNameControllers.add(TextEditingController());
      _ingQtyControllers.add(TextEditingController());
      _ingUnitControllers.add(TextEditingController());
    }
    while (_stepControllers.length < _steps.length) {
      _stepControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _servingsController.dispose();
    _notesController.dispose();
    for (final controller in _ingNameControllers) controller.dispose();
    for (final controller in _ingQtyControllers) controller.dispose();
    for (final controller in _ingUnitControllers) controller.dispose();
    for (final controller in _stepControllers) controller.dispose();
    super.dispose();
  }

  void _addIngredient() {
    setState(() {
      _ingredients.add({'name': '', 'qty': '', 'unit': ''});
      _ingNameControllers.add(TextEditingController());
      _ingQtyControllers.add(TextEditingController());
      _ingUnitControllers.add(TextEditingController());
    });
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
      _ingNameControllers.removeAt(index);
      _ingQtyControllers.removeAt(index);
      _ingUnitControllers.removeAt(index);
    });
  }

  void _addStep() {
    setState(() {
      _steps.add('');
      _stepControllers.add(TextEditingController());
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
      _stepControllers.removeAt(index);
    });
  }

  Future<void> _pickImage() async {
    final uploadInput = html.FileUploadInputElement()..accept = 'image/*';
    uploadInput.click();
    uploadInput.onChange.listen((event) async {
      final file = uploadInput.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoadEnd.listen((event) {
        setState(() {
          _photoBase64 = (reader.result as String).split(',').last;
        });
      });
    });
  }

  void _saveRecipe() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a recipe name')),
      );
      return;
    }

    // Sync data from controllers to lists
    for (int j = 0; j < _ingredients.length; j++) {
      _ingredients[j]['name'] = _ingNameControllers[j].text.trim();
      _ingredients[j]['qty'] = _ingQtyControllers[j].text.trim();
      _ingredients[j]['unit'] = _ingUnitControllers[j].text.trim();
    }
    for (int j = 0; j < _steps.length; j++) {
      _steps[j] = _stepControllers[j].text.trim();
    }

    // Remove empty ingredients and steps
    _ingredients.removeWhere((ing) => (ing['name'] as String?)?.isEmpty ?? true);
    _steps.removeWhere((s) => s.isEmpty);

    final updatedRecipe = {
      'id': widget.recipe?['id'] ?? const Uuid().v4(),
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'photo': _photoBase64,
      'ingredients': _ingredients,
      'steps': _steps,
      'servings': _servingsController.text.trim(),
      'notes': _notesController.text.trim(),
    };

    Navigator.pop(context, updatedRecipe);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.recipe != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Recipe' : 'Add Recipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Recipe Name')),
                      const SizedBox(height: 8),
                      TextField(controller: _descController, decoration: const InputDecoration(labelText: 'Description')),
                      const SizedBox(height: 8),
                      TextField(controller: _servingsController, decoration: const InputDecoration(labelText: 'Servings'), keyboardType: TextInputType.number),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    _photoBase64 == null
                        ? Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 60),
                          )
                        : Image.memory(base64Decode(_photoBase64!), width: 120, height: 120, fit: BoxFit.cover),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _pickImage, child: Text(isEdit ? 'Change Photo' : 'Upload Photo')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...List.generate(_ingredients.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(flex: 4, child: TextField(
                    controller: _ingNameControllers[i],
                    decoration: const InputDecoration(hintText: 'Ingredient'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: TextField(
                    controller: _ingQtyControllers[i],
                    decoration: const InputDecoration(hintText: 'Qty'),
                    keyboardType: TextInputType.number,
                  )),
                  const SizedBox(width: 8),
                  Expanded(flex: 2, child: TextField(
                    controller: _ingUnitControllers[i],
                    decoration: const InputDecoration(hintText: 'Unit'),
                  )),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeIngredient(i)),
                ],
              ),
            )),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(onPressed: _addIngredient, icon: const Icon(Icons.add), label: const Text('Add Ingredient')),
            ),
            const SizedBox(height: 20),
            const Text('Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...List.generate(_steps.length, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(child: TextField(
                    controller: _stepControllers[i],
                    decoration: InputDecoration(hintText: 'Step ${i + 1}'),
                    maxLines: null,
                  )),
                  IconButton(icon: const Icon(Icons.delete), onPressed: () => _removeStep(i)),
                ],
              ),
            )),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(onPressed: _addStep, icon: const Icon(Icons.add), label: const Text('Add Step')),
            ),
            const SizedBox(height: 16),
            TextField(controller: _notesController, maxLines: 3, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 20),
            Center(child: ElevatedButton.icon(onPressed: _saveRecipe, icon: const Icon(Icons.save), label: const Text('Save Recipe'))),
          ],
        ),
      ),
    );
  }
}

// =================== RECIPE CARD PAGE ===================
class RecipeCardPage extends StatelessWidget {
  final Map<String, dynamic> recipe;
  const RecipeCardPage({super.key, required this.recipe});

  @override
  Widget build(BuildContext context) {
    final ingredients = List<Map<String, dynamic>>.from(recipe['ingredients'] ?? []);
    final steps = List<String>.from(recipe['steps'] ?? []);

    return Scaffold(
      appBar: AppBar(title: Text(recipe['name'] as String? ?? 'Recipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe['photo'] != null)
              Center(child: Image.memory(base64Decode(recipe['photo'] as String), width: 250, height: 250, fit: BoxFit.cover)),
            const SizedBox(height: 16),
            Text(recipe['name'] as String? ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Servings: ${recipe['servings'] ?? "1"}'),
            const SizedBox(height: 8),
            if (recipe['description'] != null && (recipe['description'] as String).isNotEmpty)
              Text(recipe['description'] as String? ?? '', style: const TextStyle(fontSize: 16)),
            const Divider(height: 32),
            const Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...ingredients.map((ing) => Text('- ${(ing['qty'] as String?) ?? ''} ${(ing['unit'] as String?) ?? ''} ${(ing['name'] as String?) ?? ''}')),
            const Divider(height: 32),
            const Text('Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...steps.asMap().entries.map((entry) => Text('${entry.key + 1}. ${entry.value}')),
            if ((recipe['notes'] ?? '').toString().isNotEmpty) ...[
              const Divider(height: 32),
              const Text('Notes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(recipe['notes'] as String? ?? ''),
            ],
          ],
        ),
      ),
    );
  }
}