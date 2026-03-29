import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/product_details.dart';
import 'package:user_app/subcategory_page.dart';
import 'package:user_app/theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  Set<int> likedProductIds = {};

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      await Future.wait([
        fetchCategories(),
        fetchProducts(),
        fetchLikedProducts(),
      ]);
    } catch (e) {
      debugPrint("Load Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  /// 🔥 FETCH ALL PRODUCTS (NO FILTER ISSUE)
  Future<void> fetchProducts() async {
    try {
      final response = await supabase
          .from('tbl_product')
          .select('*, tbl_place(place_name)')
          .order('created_at', ascending: false);

      print("🔥 PRODUCTS: $response");

      products = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Product Error: $e");
    }
  }

  /// 🔥 FETCH CATEGORIES
  Future<void> fetchCategories() async {
    final response = await supabase.from('tbl_category').select();
    categories = List<Map<String, dynamic>>.from(response);
  }

  /// 🔥 FETCH LIKED
  Future<void> fetchLikedProducts() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('tbl_favourite')
          .select('product_id')
          .eq('user_id', user.id);

      likedProductIds = (response as List)
          .map<int>((e) =>
              int.tryParse(e['product_id'].toString()) ?? 0)
          .where((id) => id != 0)
          .toSet();
    } catch (e) {
      debugPrint("Like Error: $e");
    }
  }

  /// 🔥 TOGGLE LIKE
  Future<void> toggleLike(int productId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final isLiked = likedProductIds.contains(productId);

    setState(() {
      if (isLiked) {
        likedProductIds.remove(productId);
      } else {
        likedProductIds.add(productId);
      }
    });

    try {
      if (isLiked) {
        await supabase.from('tbl_favourite').delete().match({
          'user_id': user.id,
          'product_id': productId,
        });
      } else {
        await supabase.from('tbl_favourite').insert({
          'user_id': user.id,
          'product_id': productId,
        });
      }
    } catch (e) {
      debugPrint("Toggle Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [

            /// 🔥 HEADER
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(AppTheme.padding),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.white),
                        SizedBox(width: 6),
                        Text("Kerala",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search products...",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 🔥 CATEGORY GRID
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: categories.length,
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.8,
                  ),
                  itemBuilder: (context, index) {
                    final c = categories[index];

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubCategoryPage(
                              categoryId: c['id'],
                              categoryName: c['category_name'],
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: c['category_image'] != null
                                ? NetworkImage(c['category_image'])
                                : null,
                            child: c['category_image'] == null
                                ? const Icon(Icons.category)
                                : null,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            c['category_name'] ?? '',
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
              ),
            ),

            /// 🔥 TITLE
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "All Products",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),

            /// 🔥 PRODUCTS GRID
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: products.isEmpty
                  ? const SliverToBoxAdapter(
                      child: Center(child: Text("No products available")),
                    )
                  : SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final p = products[i];
                          final int productId =
                              int.tryParse(p['id'].toString()) ?? 0;

                          return ProductCard(
                            title: p['product_name'] ?? '',
                            price: "₹${p['product_price'] ?? 0}",
                            location:
                                p['tbl_place']?['place_name'] ?? '',
                            imageUrl: p['image_url'] ?? '',
                            isLiked:
                                likedProductIds.contains(productId),
                            onLikeTap: () => toggleLike(productId),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ProductDetailsPage(product: p),
                                ),
                              );
                            },
                          );
                        },
                        childCount: products.length,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 🔥 PRODUCT CARD
class ProductCard extends StatelessWidget {
  final String title;
  final String price;
  final String location;
  final String imageUrl;
  final bool isLiked;
  final VoidCallback onLikeTap;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.title,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.isLiked,
    required this.onLikeTap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// IMAGE
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Container(color: Colors.grey.shade300),
                  ),
                  Positioned(
                    right: 5,
                    top: 5,
                    child: IconButton(
                      icon: Icon(
                        isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey,
                      ),
                      onPressed: onLikeTap,
                    ),
                  )
                ],
              ),
            ),

            /// DETAILS
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(price,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(location,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}