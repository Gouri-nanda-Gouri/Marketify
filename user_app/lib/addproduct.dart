import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/homescreen.dart';
import 'package:user_app/main.dart';
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
  final TextEditingController imageController = TextEditingController();

  int? selectedCategory;
  int? selectedCondition;
  int? selectedDistrict;
  int? selectedPlace;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> conditions = [];
  List<Map<String, dynamic>> districts = [];
  List<Map<String, dynamic>> places = [];

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
    imageController.dispose();
    super.dispose();
  }

  Uint8List? imageBytes;
  file_picker.PlatformFile? pickedImage;

  /// IMAGE PICKER (FIXED)
  Future<void> handleImagePick() async {
    file_picker.FilePickerResult? result = await file_picker.FilePicker.platform.pickFiles(
      type: file_picker.FileType.image,
      withData: true, // IMPORTANT
    );

    if (result == null) return;

    pickedImage = result.files.first;
    imageBytes = pickedImage!.bytes;

    debugPrint("✅ Image picked: ${imageBytes!.length} bytes");
    setState(() {});
  }

  // ================= FETCH DATA =================

  Future<void> fetchCategories() async {
    final response = await supabase.from('tbl_category').select();
    setState(() => categories = List<Map<String, dynamic>>.from(response));
  }

  Future<void> fetchConditions() async {
    final response = await supabase.from('tbl_condition').select();
    setState(() => conditions = List<Map<String, dynamic>>.from(response));
  }

  Future<void> fetchDistricts() async {
    final response = await supabase.from('tbl_district').select();
    setState(() => districts = List<Map<String, dynamic>>.from(response));
  }

  // Fetch places based on district
  Future<void> fetchPlaces(int districtId) async {
    final response = await supabase
        .from('tbl_place')
        .select()
        .eq('district_id', districtId);

    setState(() => places = List<Map<String, dynamic>>.from(response));
  }
  

  // ================= INSERT PRODUCT =================

 // 1. Add a loading variable at the top of your _AddproductState
bool _isLoading = false;

// 2. Updated Photo Upload (Unique filenames)
Future<String?> photoUpload(String uid) async {
  try {
    if (imageBytes == null) return null;

    const bucketName = 'Products';
    // Use timestamp to ensure every product image is unique
    final String uniqueName = DateTime.now().millisecondsSinceEpoch.toString();
    final filePath = "product/${uid}_$uniqueName.${pickedImage!.extension}";

    await supabase.storage.from(bucketName).uploadBinary(
          filePath,
          imageBytes!,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg', // Consider using pickedImage!.mimeType if available
          ),
        );

    return supabase.storage.from(bucketName).getPublicUrl(filePath);
  } catch (e) {
    debugPrint("❌ Upload error: $e");
    return null;
  }
}

// 3. Updated Add Product (With Loading UI)
Future<void> addProduct() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  setState(() => _isLoading = true); // Start loading

  try {
    String? imageUrl = await photoUpload(user.id);

    await supabase.from('tbl_product').insert({
      "product_name": productNameController.text,
      "product_description": descriptionController.text,
      "product_price": double.tryParse(priceController.text) ?? 0, // Store as number
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
        const SnackBar(content: Text("Ad posted successfully ✅")),
      );
    Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(),));
    }
  } catch (e) {
    print("Error adding product: $e");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false); // Stop loading
  }
}

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF002F34); // OLX dark teal

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post your Ad"),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // IMAGE BOX (OLX STYLE)
             GestureDetector(
  onTap: handleImagePick,
  child: Container(
    height: 180,
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade300),
    ),
    child: imageBytes == null
        ? Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.camera_alt_outlined, size: 40),
              SizedBox(height: 10),
              Text("Upload Product Photo")
            ],
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(imageBytes!, fit: BoxFit.cover),
          ),
  ),
),


              const SizedBox(height: 15),

              _field(productNameController, "Product Name"),
              _field(descriptionController, "Description", maxLines: 3),
              _field(priceController, "Price", keyboard: TextInputType.number),
              _field(imageController, "Image URL"),

              const SizedBox(height: 15),

              // CATEGORY
              _dropdown(
                label: "Category",
                value: selectedCategory,
                list: categories,
                textKey: "category_name",
                onChanged: (val) => setState(() => selectedCategory = val),
              ),

              const SizedBox(height: 12),

              // CONDITION
              _dropdown(
                label: "Condition",
                value: selectedCondition,
                list: conditions,
                textKey: "condition_name",
                onChanged: (val) => setState(() => selectedCondition = val),
              ),

              const SizedBox(height: 12),

              // DISTRICT
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
                  fetchPlaces(val!);
                },
              ),

              const SizedBox(height: 12),

              // PLACE
              _dropdown(
                label: "Place",
                value: selectedPlace,
                list: places,
                textKey: "place_name",
                onChanged: (val) => setState(() => selectedPlace = val),
              ),

              const SizedBox(height: 20),

              // BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor),
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      addProduct();
                    }
                  },
                  child: const Text(
                    "POST AD",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= COMMON FIELD =================

  Widget _field(TextEditingController controller, String label,
      {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboard,
        validator: (v) => v == null || v.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  // ================= COMMON DROPDOWN =================

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
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: list
          .map((item) => DropdownMenuItem<int>(
                value: item['id'],
                child: Text(item[textKey]),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}
