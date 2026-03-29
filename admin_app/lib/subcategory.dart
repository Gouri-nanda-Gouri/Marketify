import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';

class SubCategories extends StatefulWidget {
  const SubCategories({super.key});

  @override
  State<SubCategories> createState() => _SubCategoriesState();
}

class _SubCategoriesState extends State<SubCategories> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController subcategoryController = TextEditingController();

  List categoryData = [];
  List subcategoryData = [];

  int? selectedCategoryId;
  Uint8List? selectedImageBytes;

  /// FETCH CATEGORIES
  Future<void> fetchCategories() async {
    final response = await supabase.from('tbl_category').select();
    setState(() {
      categoryData = response;
    });
  }

  /// FETCH SUBCATEGORIES
  Future<void> fetchSubCategories() async {
    final response = await supabase
        .from('tbl_subcategory')
        .select('*, tbl_category(category_name)');

    setState(() {
      subcategoryData = response;
    });
  }

  /// PICK IMAGE (WEB SAFE)
  Future<void> pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null) {
      setState(() {
        selectedImageBytes = result.files.single.bytes;
      });
    }
  }

  /// UPLOAD IMAGE
  Future<String?> uploadImage(Uint8List bytes) async {
    final fileName = "sub_${DateTime.now().millisecondsSinceEpoch}.jpg";

    await supabase.storage
        .from('subcategory_images')
        .uploadBinary(fileName, bytes);

    return supabase.storage.from('subcategory_images').getPublicUrl(fileName);
  }

  /// INSERT
 Future<void> insertSubCategory() async {
  try {
    if (selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select category first")),
      );
      return;
    }

    String? imageUrl;

    if (selectedImageBytes != null) {
      imageUrl = await uploadImage(selectedImageBytes!);
    }

    await supabase.from('tbl_subcategory').insert({
      'subcategory_name': subcategoryController.text.trim(),
      'category_id': selectedCategoryId, // matches tbl_category.id
      'subcategory_image': imageUrl,
    });

    fetchSubCategories();

    subcategoryController.clear();
    selectedImageBytes = null;
    selectedCategoryId = null;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subcategory Added")),
    );
  } catch (e) {
    print("ERROR: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}

  /// DELETE
  Future<void> deleteSubCategory(int id) async {
    await supabase.from('tbl_subcategory').delete().eq('subcategory_id', id);

    fetchSubCategories();
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchSubCategories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subcategory Management")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// FORM
            Form(
              key: _formKey,
              child: Column(
                children: [
                  /// CATEGORY DROPDOWN
                  DropdownButtonFormField<int>(
                    value: selectedCategoryId,
                    hint: const Text("Select Category"),
                    items: categoryData.map<DropdownMenuItem<int>>((cat) {
                      return DropdownMenuItem(
                        value: cat['id'], // FIXED
                        child: Text(cat['category_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedCategoryId = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? "Select category" : null,
                  ),

                  const SizedBox(height: 10),

                  /// SUBCATEGORY NAME
                  TextFormField(
                    controller: subcategoryController,
                    validator: (value) =>
                        value!.isEmpty ? "Enter subcategory name" : null,
                    decoration: const InputDecoration(
                      hintText: "Subcategory Name",
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// IMAGE PICKER
                  GestureDetector(
                    onTap: pickImage,
                    child: Container(
                      height: 100,
                      color: Colors.grey.shade200,
                      child: selectedImageBytes != null
                          ? Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                          : const Center(child: Text("Select Image")),
                    ),
                  ),

                  const SizedBox(height: 10),

                  ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        insertSubCategory();
                      }
                    },
                    child: const Text("Add Subcategory"),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// LIST
            Expanded(
              child: ListView.builder(
                itemCount: subcategoryData.length,
                itemBuilder: (context, index) {
                  final data = subcategoryData[index];

                  return ListTile(
                    leading: data['subcategory_image'] != null
                        ? Image.network(
                            data['subcategory_image'],
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.folder),

                    title: Text(data['subcategory_name']),
                    subtitle: Text(
                      data['tbl_category']?['category_name'] ?? "",
                    ),

                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        deleteSubCategory(data['subcategory_id']);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
