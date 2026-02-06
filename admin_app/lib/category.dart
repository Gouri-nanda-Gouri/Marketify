import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';

class Categories extends StatefulWidget {
  const Categories({super.key});

  @override
  State<Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<Categories> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController categoryController = TextEditingController();

  List categoryData = [];

  /// INSERT
  Future<void> insertCategory() async {
    final name = categoryController.text.trim();

    await supabase.from('tbl_category').insert({
      'category_name': name,
    });

    categoryController.clear();
    fetchCategories();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Category Added Successfully")),
    );
  }

  /// FETCH
  Future<void> fetchCategories() async {
    final response = await supabase.from('tbl_category').select();

    setState(() {
      categoryData = response;
    });
  }

  /// UPDATE
  Future<void> updateCategory(int id, String name) async {
    await supabase
        .from('tbl_category')
        .update({'category_name': name})
        .eq('category_id', id);

    fetchCategories();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Category Updated")),
    );
  }

  /// DELETE
  Future<void> deleteCategory(int id) async {
    await supabase
        .from('tbl_category')
        .delete()
        .eq('category_id', id);

    fetchCategories();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Category Deleted")),
    );
  }

  /// EDIT DIALOG
  void showEditDialog(int id, String oldName) {
    TextEditingController editController =
        TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Category"),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: "Category Name",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Update"),
            onPressed: () {
              final updatedName = editController.text.trim();

              if (updatedName.isNotEmpty) {
                updateCategory(id, updatedName);
              }

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// DELETE CONFIRMATION
  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Category"),
        content:
            const Text("Are you sure you want to delete this category?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () {
              deleteCategory(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  void dispose() {
    categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Add Category"),
        backgroundColor: const Color(0xFF2E6CF6),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  color: Color(0x11000000),
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [

                /// ICON
                const Icon(
                  Icons.category_outlined,
                  size: 48,
                  color: Color(0xFF2E6CF6),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Create New Category",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 24),

                /// FORM
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: categoryController,
                        validator: (value) =>
                            value!.isEmpty ? "Enter category name" : null,
                        decoration: InputDecoration(
                          labelText: "Category Name",
                          prefixIcon:
                              const Icon(Icons.edit_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              insertCategory();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color(0xFF2E6CF6),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Add Category",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "All Categories",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// LIST
                categoryData.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No Categories Added"),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: categoryData.length,
                        itemBuilder: (context, index) {
                          final data = categoryData[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.folder,
                                color: Color(0xFF2E6CF6),
                              ),
                              title:
                                  Text(data['category_name']),
                              trailing: Row(
                                mainAxisSize:
                                    MainAxisSize.min,
                                children: [

                                  /// EDIT
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.blue,
                                    ),
                                    onPressed: () {
                                      showEditDialog(
                                        data['category_id'],
                                        data['category_name'],
                                      );
                                    },
                                  ),

                                  /// DELETE
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () {
                                      confirmDelete(
                                          data['category_id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
