import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'product_details.dart';

class SubCategoryProductsPage extends StatefulWidget {
  final int subcategoryId;
  final String subcategoryName;

  const SubCategoryProductsPage({
    super.key,
    required this.subcategoryId,
    required this.subcategoryName,
  });

  @override
  State<SubCategoryProductsPage> createState() =>
      _SubCategoryProductsPageState();
}

class _SubCategoryProductsPageState
    extends State<SubCategoryProductsPage> {
  final supabase = Supabase.instance.client;

  List products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    print("Selected Subcategory ID: ${widget.subcategoryId}");
  }

  Future<void> fetchProducts() async {
    try {
     final res = await supabase
    .from('tbl_product')
    .select('*, tbl_place(place_name)')
    .eq('subcategory_id', widget.subcategoryId);

      setState(() {
        products = res;
      });
      print("Products: $products");
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
        title: Text(widget.subcategoryName),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : products.isEmpty
              ? const Center(child: Text("No products found"))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: products.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, index) {
                    final product = products[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailsPage(product: product),
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// IMAGE
                            Expanded(
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: product['image_url'] != null
                                    ? Image.network(
                                        product['image_url'],
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      )
                                    : Container(color: Colors.grey.shade300),
                              ),
                            ),

                            /// DETAILS
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "₹${product['product_price'] ?? 0}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    product['product_name'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    product['tbl_place']?['place_name'] ?? '',
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}