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

  /// EDIT DIALOG (UPGRADED)
  void showEditDialog(int id, String oldName) {
    TextEditingController editController =
        TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Edit Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: editController,
                decoration: InputDecoration(
                  labelText: "Category Name",
                  filled: true,
                  fillColor: const Color(0xFFF5F7FF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel")),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E6CF6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      final updatedName = editController.text.trim();
                      if (updatedName.isNotEmpty) {
                        updateCategory(id, updatedName);
                      }
                      Navigator.pop(context);
                    },
                    child: const Text("Update"),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  /// DELETE CONFIRMATION (UPGRADED)
  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Delete Category",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text("Are you sure you want to delete this category?"),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel")),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      deleteCategory(id);
                      Navigator.pop(context);
                    },
                    child: const Text("Delete"),
                  ),
                ],
              )
            ],
          ),
        ),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            const Text(
              "Category Management",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage product categories efficiently",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 24),

            /// ADD CATEGORY CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "+ Add New Category",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: categoryController,
                      validator: (value) =>
                          value!.isEmpty ? "Enter category name" : null,
                      decoration: InputDecoration(
                        hintText: "Enter category name...",
                        prefixIcon: const Icon(Icons.category),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            insertCategory();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E6CF6),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Add Category",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// LIST HEADER
            const Text(
              "Categories List",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            /// LIST
            Expanded(
              child: categoryData.isEmpty
                  ? const Center(
                      child: Text(
                        "📭 No categories yet\nAdd one above",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: categoryData.length,
                      itemBuilder: (context, index) {
                        final data = categoryData[index];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.folder,
                                  color: Color(0xFF2E6CF6)),
                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  data['category_name'],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),

                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue),
                                onPressed: () {
                                  showEditDialog(
                                    data['category_id'],
                                    data['category_name'],
                                  );
                                },
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  confirmDelete(data['category_id']);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}