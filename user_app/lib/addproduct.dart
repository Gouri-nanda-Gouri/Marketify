import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/mainbottom.dart';
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_app_bar.dart';
import 'package:user_app/widgets/custom_button.dart';
import 'package:user_app/widgets/custom_text_field.dart';
import 'package:file_picker/file_picker.dart' as file_picker;

class Addproduct extends StatefulWidget {
  const Addproduct({super.key});

  @override
  State<Addproduct> createState() => _AddproductState();
}

class _AddproductState extends State<Addproduct> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController productNameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  int? selectedCategory;
  int? selectedSubCategory; // ✅ NEW
  int? selectedCondition;
  int? selectedDistrict;
  int? selectedPlace;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subcategories = []; // ✅ NEW
  List<Map<String, dynamic>> conditions = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> places = [];

  final supabase = Supabase.instance.client;

  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchConditions();
    fetchDistricts();
  }

  /// IMAGE PICK
  Future<void> handleImagePick() async {
    final result = await file_picker.FilePicker.platform.pickFiles(
      type: file_picker.FileType.image,
      withData: true,
    );

    if (result == null) return;

    pickedImage = result.files.first;
    imageBytes = pickedImage!.bytes;
    setState(() {});
  }

  /// FETCH CATEGORY
  Future<void> fetchCategories() async {
    final res = await supabase.from('tbl_category').select();
    setState(() => categories = List<Map<String, dynamic>>.from(res));
  }

  /// FETCH SUBCATEGORY (BASED ON CATEGORY)
  Future<void> fetchSubCategories(int categoryId) async {
    final res = await supabase
        .from('tbl_subcategory')
        .select()
        .eq('category_id', categoryId);

    setState(() {
      subcategories = List<Map<String, dynamic>>.from(res);
    });
  }

  Future<void> fetchConditions() async {
    final res = await supabase.from('tbl_condition').select();
    setState(() => conditions = List<Map<String, dynamic>>.from(res));
  }

  Future<void> fetchDistricts() async {
    final res = await supabase.from('tbl_district').select();
    setState(() => districts = List<Map<String, dynamic>>.from(res));
  }

  Future<void> fetchPlaces(int districtId) async {
    final res = await supabase
        .from('tbl_place')
        .select()
        .eq('district_id', districtId);

    setState(() => places = List<Map<String, dynamic>>.from(res));
  }

  /// UPLOAD IMAGE
  Future<String?> photoUpload(String uid) async {
    if (imageBytes == null) return null;

    final filePath =
        "product/${uid}_${DateTime.now().millisecondsSinceEpoch}.${pickedImage!.extension}";

    await supabase.storage.from('Products').uploadBinary(filePath, imageBytes!);

    return supabase.storage.from('Products').getPublicUrl(filePath);
  }

  /// ADD PRODUCT
  Future<void> addProduct() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (_formKey.currentState!.validate() == false) return;

    setState(() => _isLoading = true);

    try {
      final imageUrl = await photoUpload(user.id);

      await supabase.from('tbl_product').insert({
        "product_name": productNameController.text,
        "product_description": descriptionController.text,
        "product_price": double.tryParse(priceController.text) ?? 0,
        "category_id": selectedCategory,
        "subcategory_id": selectedSubCategory, // ✅ NEW
        "condition_id": selectedCondition,
        "district_id": selectedDistrict,
        "place_id": selectedPlace,
        "image_url": imageUrl,
        "user_id": user.id,
        "created_at": DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ad posted successfully"),
          backgroundColor: AppTheme.success,
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainBottomNav()),
      );
    } catch (e) {
      debugPrint("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// DROPDOWN WIDGET
  Widget _dropdown({
    required String label,
    required int? value,
    required List<Map<String, dynamic>> list,
    required String textKey,
    required Function(int?) onChanged,
  }) {
    return DropdownButtonFormField<int>(
      value: value,
      validator: (v) => v == null ? "Required" : null,
      decoration: InputDecoration(labelText: label),
      items: list.map((item) {
        return DropdownMenuItem<int>(
          value: item['subcategory_id'] ?? item['id'], // ✅ FIXED
          child: Text(item[textKey]),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: "Post your Ad"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              /// IMAGE
              GestureDetector(
                onTap: handleImagePick,
                child: Container(
                  height: 200,
                  color: Colors.grey.shade200,
                  child: imageBytes == null
                      ? const Center(child: Text("Upload Image"))
                      : Image.memory(imageBytes!, fit: BoxFit.cover),
                ),
              ),

              const SizedBox(height: 20),

              CustomTextField(
                controller: productNameController,
                label: "Product Name",
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: descriptionController,
                label: "Description",
              ),

              const SizedBox(height: 16),

              CustomTextField(
                controller: priceController,
                label: "Price",
              ),

              const SizedBox(height: 20),

              /// CATEGORY
              _dropdown(
                label: "Category",
                value: selectedCategory,
                list: categories,
                textKey: "category_name",
                onChanged: (val) {
                  setState(() {
                    selectedCategory = val;
                    selectedSubCategory = null;
                    subcategories = [];
                  });

                  if (val != null) {
                    fetchSubCategories(val); // 🔥 LOAD
                  }
                },
              ),

              const SizedBox(height: 16),

              /// SUBCATEGORY
              _dropdown(
                label: "Subcategory",
                value: selectedSubCategory,
                list: subcategories,
                textKey: "subcategory_name",
                onChanged: (val) =>
                    setState(() => selectedSubCategory = val),
              ),

              const SizedBox(height: 16),

              _dropdown(
                label: "Condition",
                value: selectedCondition,
                list: conditions,
                textKey: "condition_name",
                onChanged: (val) =>
                    setState(() => selectedCondition = val),
              ),

              const SizedBox(height: 20),

              CustomButton(
                text: "POST AD",
                isLoading: _isLoading,
                onPressed: addProduct,
              ),
            ],
          ),
        ),
      ),
    );
  }
}