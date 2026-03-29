import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/subcategory_products_page.dart';

class SubCategoryPage extends StatefulWidget {
  final int categoryId;
  final String categoryName;

  const SubCategoryPage({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<SubCategoryPage> createState() => _SubCategoryPageState();
}

class _SubCategoryPageState extends State<SubCategoryPage> {
  final supabase = Supabase.instance.client;

  List subcategories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchSubCategories();
  }

  Future<void> fetchSubCategories() async {
    try {
      final res = await supabase
          .from('tbl_subcategory')
          .select()
          .eq('category_id', widget.categoryId);

      setState(() {
        subcategories = res;
      });
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : subcategories.isEmpty
              ? const Center(child: Text("No subcategories found"))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: subcategories.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // OLX style
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemBuilder: (context, index) {
                    final sub = subcategories[index];

                    return GestureDetector(
                     onTap: () {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => SubCategoryProductsPage(
        subcategoryId: sub['subcategory_id'],
        subcategoryName: sub['subcategory_name'],
      ),
    ),
  );
},
                      child: Column(
                        children: [
                          /// IMAGE
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.grey.shade200,
                            backgroundImage:
                                sub['subcategory_image'] != null
                                    ? NetworkImage(
                                        sub['subcategory_image'])
                                    : null,
                            child: sub['subcategory_image'] == null
                                ? const Icon(Icons.category)
                                : null,
                          ),

                          const SizedBox(height: 6),

                          /// NAME
                          Text(
                            sub['subcategory_name'] ?? '',
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}