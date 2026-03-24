import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/homescreen.dart';
import 'package:file_picker/file_picker.dart' as file_picker;
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_app_bar.dart';
import 'package:user_app/widgets/custom_button.dart';
import 'package:user_app/widgets/custom_text_field.dart';

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
  int? selectedCondition;
  int? selectedDistrict;
  int? selectedPlace;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> conditions = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> places = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchConditions();
    fetchDistricts();
  }

  @override
  void dispose() {
    productNameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }

  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;

  bool _isLoading = false;

  Future<void> handleImagePick() async {
    file_picker.FilePickerResult? result = await file_picker.FilePicker.platform.pickFiles(
      type: file_picker.FileType.image,
      withData: true,
    );

    if (result == null) return;

    pickedImage = result.files.first;
    imageBytes = pickedImage!.bytes;
    setState(() {});
  }

  Future<void> fetchCategories() async {
    try {
      final response = await supabase.from('tbl_category').select();
      setState(() => categories = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> fetchConditions() async {
    try {
      final response = await supabase.from('tbl_condition').select();
      setState(() => conditions = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> fetchDistricts() async {
    try {
      final response = await supabase.from('tbl_district').select();
      setState(() => districts = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> fetchPlaces(int districtId) async {
    try {
      final response = await supabase
          .from('tbl_place')
          .select()
          .eq('district_id', districtId);
      setState(() => places = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<String?> photoUpload(String uid) async {
    try {
      if (imageBytes == null) return null;

      const bucketName = 'Products';
      final String uniqueName = DateTime.now().millisecondsSinceEpoch.toString();
      final filePath = "product/${uid}_$uniqueName.${pickedImage!.extension}";

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(
              upsert: true,
            ),
          );

      return supabase.storage.from(bucketName).getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> addProduct() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please upload a product photo"), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = await photoUpload(user.id);

      await supabase.from('tbl_product').insert({
        "product_name": productNameController.text,
        "product_description": descriptionController.text,
        "product_price": double.tryParse(priceController.text) ?? 0,
        "category_id": selectedCategory,
        "condition_id": selectedCondition,
        "district_id": selectedDistrict,
        "place_id": selectedPlace,
        "image_url": imageUrl,
        "user_id": user.id,
        "created_at": DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ad posted successfully"), backgroundColor: AppTheme.success),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
      }
    } catch (e) {
      debugPrint("Error adding product: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(title: "Post your Ad"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IMAGE BOX
              GestureDetector(
                onTap: handleImagePick,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    border: Border.all(color: AppTheme.divider),
                  ),
                  child: imageBytes == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.05),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.add_a_photo_outlined, size: 40, color: AppTheme.primary),
                            ),
                            const SizedBox(height: 16),
                            Text("Upload Product Photo", style: Theme.of(context).textTheme.bodyLarge),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(imageBytes!, fit: BoxFit.cover),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                                    onPressed: handleImagePick,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),

              Text("Product Details", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              CustomTextField(
                controller: productNameController,
                label: "Product Name",
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: descriptionController,
                label: "Description",
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: priceController,
                label: "Price (₹)",
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? "Required" : null,
              ),

              const SizedBox(height: 24),
              Text("Categorization", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              _dropdown(
                label: "Category",
                value: selectedCategory,
                list: categories,
                textKey: "category_name",
                onChanged: (val) => setState(() => selectedCategory = val),
              ),
              const SizedBox(height: 16),

              _dropdown(
                label: "Condition",
                value: selectedCondition,
                list: conditions,
                textKey: "condition_name",
                onChanged: (val) => setState(() => selectedCondition = val),
              ),

              const SizedBox(height: 24),
              Text("Location", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              _dropdown(
                label: "District",
                value: selectedDistrict,
                list: districts,
                textKey: "district_name",
                onChanged: (val) {
                  setState(() {
                    selectedDistrict = val;
                    selectedPlace = null;
                  });
                  if (val != null) fetchPlaces(val);
                },
              ),
              const SizedBox(height: 16),

              _dropdown(
                label: "Place",
                value: selectedPlace,
                list: places,
                textKey: "place_name",
                onChanged: (val) => setState(() => selectedPlace = val),
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: "POST AD",
                isLoading: _isLoading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    addProduct();
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

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
      dropdownColor: AppTheme.card,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppTheme.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          borderSide: const BorderSide(color: AppTheme.error, width: 1),
        ),
      ),
      items: list
          .map((item) => DropdownMenuItem<int>(
                value: item['id'],
                child: Text(item[textKey], style: Theme.of(context).textTheme.bodyLarge),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

