import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
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

  Uint8List? selectedImageBytes;

  /// PICK IMAGE (WEB SAFE)
  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true, // IMPORTANT
    );

    if (result != null) {
      setState(() {
        selectedImageBytes = result.files.single.bytes;
      });
    }
  }

  /// UPLOAD IMAGE
  Future<String?> uploadImage(Uint8List imageBytes) async {
    final fileName =
        "cat_${DateTime.now().millisecondsSinceEpoch}.jpg";

    await supabase.storage
        .from('category_images')
        .uploadBinary(fileName, imageBytes);

    return supabase.storage
        .from('category_images')
        .getPublicUrl(fileName);
  }

  /// INSERT
  Future<void> insertCategory() async {
    final name = categoryController.text.trim();

    String? imageUrl;

    if (selectedImageBytes != null) {
      imageUrl = await uploadImage(selectedImageBytes!);
    }

    await supabase.from('tbl_category').insert({
      'category_name': name,
      'category_image': imageUrl,
    });

    categoryController.clear();
    selectedImageBytes = null;

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
  Future<void> updateCategory(
      int id, String name, Uint8List? newImage) async {
    try {
      String? imageUrl;

      if (newImage != null) {
        imageUrl = await uploadImage(newImage);
      }

      Map<String, dynamic> updateData = {
        'category_name': name,
      };

      if (imageUrl != null) {
        updateData['category_image'] = imageUrl;
      }

      await supabase
          .from('tbl_category')
          .update(updateData)
          .eq('id', id); // FIXED

      fetchCategories();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category Updated")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Update failed")),
      );
    }
  }

  /// DELETE
  Future<void> deleteCategory(int id) async {
    await supabase
        .from('tbl_category')
        .delete()
        .eq('id', id); // FIXED

    fetchCategories();
  }

  /// EDIT DIALOG
  void showEditDialog(int id, String oldName, String? oldImage) {
    TextEditingController editController =
        TextEditingController(text: oldName);

    Uint8List? editImageBytes;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          Future<void> pickEditImage() async {
            FilePickerResult? result =
                await FilePicker.platform.pickFiles(
              type: FileType.image,
              withData: true,
            );

            if (result != null) {
              setState(() {
                editImageBytes = result.files.single.bytes;
              });
            }
          }

          return Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Edit Category"),

                  const SizedBox(height: 10),

                  TextField(controller: editController),

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: pickEditImage,
                    child: Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child: editImageBytes != null
                          ? Image.memory(editImageBytes!,
                              fit: BoxFit.cover)
                          : oldImage != null
                              ? Image.network(oldImage,
                                  fit: BoxFit.cover)
                              : const Center(
                                  child: Text("Select Image")),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      updateCategory(
                          id,
                          editController.text.trim(),
                          editImageBytes);
                      Navigator.pop(context);
                    },
                    child: const Text("Update"),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// FORM
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: categoryController,
                    validator: (value) =>
                        value!.isEmpty ? "Enter name" : null,
                  ),

                  const SizedBox(height: 10),

                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child: selectedImageBytes != null
                          ? Image.memory(selectedImageBytes!,
                              fit: BoxFit.cover)
                          : const Center(
                              child: Text("Select Image")),
                    ),
                  ),

                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        insertCategory();
                      }
                    },
                    child: const Text("Add"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// LIST
            Expanded(
              child: ListView.builder(
                itemCount: categoryData.length,
                itemBuilder: (context, index) {
                  final data = categoryData[index];

                  return ListTile(
                    leading: data['category_image'] != null
                        ? Image.network(
                            data['category_image'],
                            width: 40,
                            height: 40,
                          )
                        : const Icon(Icons.folder),

                    title: Text(data['category_name']),

                    trailing: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        showEditDialog(
                          data['id'], // FIXED
                          data['category_name'],
                          data['category_image'],
                        );
                      },
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