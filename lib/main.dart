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
      title: 'Back of House',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}

// =================== DASHBOARD PAGE ===================
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<Map<String, dynamic>> recipes = [];

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString('recipes');
    if (stored != null) {
      setState(() {
        recipes = List<Map<String, dynamic>>.from(jsonDecode(stored));
      });
    }
  }

  Future<void> _navigateToAddRecipe() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddRecipePage()),
    );
    _loadRecipes();
  }

  Future<void> _openRecipe(Map<String, dynamic> recipe) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipeCardPage(recipe: recipe)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Back of House')),
      body: recipes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Add your first recipe',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
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
                        ? Image.memory(
                            base64Decode(r['photo']),
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_not_supported, size: 40),
                    title: Text(r['name'] ?? ''),
                    subtitle: Text(r['description'] ?? ''),
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

// =================== ADD RECIPE PAGE ===================
class AddRecipePage extends StatefulWidget {
  const AddRecipePage({super.key});

  @override
  State<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<Map<String, String>> _ingredients = [];
  final List<String> _steps = [];
  String? _photoBase64;

  // Add a new blank ingredient row
  void _addIngredient() {
    setState(() {
      _ingredients.add({'name': '', 'qty': '', 'unit': ''});
    });
  }

  // Add a new blank method step
  void _addStep() {
    setState(() {
      _steps.add('');
    });
  }

  // Upload image (web-based)
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

  // Save recipe locally
  Future<void> _saveRecipe() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a menu name')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? stored = prefs.getString('recipes');
    final List<Map<String, dynamic>> recipes =
        stored != null ? List<Map<String, dynamic>>.from(jsonDecode(stored)) : [];

    final recipe = {
      'id': const Uuid().v4(),
      'name': _nameController.text.trim(),
      'description': _descController.text.trim(),
      'photo': _photoBase64,
      'ingredients': _ingredients,
      'steps': _steps,
    };

    recipes.add(recipe);
    await prefs.setString('recipes', jsonEncode(recipes));

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Recipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: name and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Menu Name',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                        ),
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Right: image upload
                Column(
                  children: [
                    _photoBase64 == null
                        ? Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.image, size: 60),
                          )
                        : Image.memory(
                            base64Decode(_photoBase64!),
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Upload Photo'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // INGREDIENTS SECTION
            const Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: [
                for (int i = 0; i < _ingredients.length; i++)
                  Row(
                    children: [
                      Expanded(
                        flex: 4,
                        child: TextField(
                          decoration: const InputDecoration(hintText: 'Ingredient'),
                          onChanged: (v) => _ingredients[i]['name'] = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(hintText: 'Qty'),
                          onChanged: (v) => _ingredients[i]['qty'] = v,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: const InputDecoration(hintText: 'Unit'),
                          onChanged: (v) => _ingredients[i]['unit'] = v,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _ingredients.removeAt(i);
                          });
                        },
                      ),
                    ],
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addIngredient,
                    icon: const Icon(Icons.add),
                    label: const Text('Add ingredient'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // METHOD SECTION
            const Text('Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Column(
              children: [
                for (int i = 0; i < _steps.length; i++)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(hintText: 'Step ${i + 1}'),
                          maxLines: null,
                          onChanged: (v) => _steps[i] = v,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            _steps.removeAt(i);
                          });
                        },
                      ),
                    ],
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addStep,
                    icon: const Icon(Icons.add),
                    label: const Text('Add step'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                onPressed: _saveRecipe,
                icon: const Icon(Icons.save),
                label: const Text('Save Recipe'),
              ),
            ),
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
      appBar: AppBar(title: Text(recipe['name'] ?? 'Recipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe['photo'] != null)
              Center(
                child: Image.memory(
                  base64Decode(recipe['photo']),
                  width: 250,
                  height: 250,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 16),
            Text(recipe['name'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(recipe['description'] ?? '', style: const TextStyle(fontSize: 16)),
            const Divider(height: 32),
            const Text('Ingredients', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            for (final ing in ingredients)
              Text('- ${ing['qty'] ?? ''} ${ing['unit'] ?? ''} ${ing['name'] ?? ''}'),
            const Divider(height: 32),
            const Text('Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            for (int i = 0; i < steps.length; i++)
              Text('${i + 1}. ${steps[i]}'),
          ],
        ),
      ),
    );
  }
}
