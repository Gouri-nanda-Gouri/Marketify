import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/product_details.dart'; // Ensure this path is correct

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> products = [];
  Set<int> likedProductIds = {}; // Stores IDs as integers

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  /// Fetches all data required for the home screen
  Future<void> loadHomeData() async {
    try {
      await Future.wait([
        fetchCategories(),
        fetchProducts(),
        fetchLikedProducts(),
      ]);
    } catch (e) {
      debugPrint("Error loading home data: $e");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> fetchCategories() async {
    final response = await supabase.from('tbl_category').select();
    categories = List<Map<String, dynamic>>.from(response);
  }

  Future<void> fetchProducts() async {
    final response = await supabase
        .from('tbl_product')
        .select('*, tbl_place(place_name)')
        .order('created_at', ascending: false);

    products = List<Map<String, dynamic>>.from(response);
  }

  Future<void> fetchLikedProducts() async {
  final user = supabase.auth.currentUser;
  if (user == null) return;

  try {
    final response = await supabase
        .from('tbl_favourite')
        .select('product_id')
        .eq('user_id', user.id);

    final Set<int> fetchedIds = (response as List).map<int>((e) {
      // Make sure this matches the column name in tbl_favourite
      final id = e['product_id']; 
      if (id is int) return id;
      return int.tryParse(id.toString()) ?? 0;
    }).where((id) => id != 0).toSet();

    setState(() {
      likedProductIds = fetchedIds;
    });
  } catch (e) {
    debugPrint("Error fetching liked products: $e");
  }
}

Future<void> toggleLike(int productId) async {
  // SAFETY CHECK: If productId is 0, the parsing failed or the key name is wrong.
  if (productId == 0) {
    debugPrint("Error: Attempted to like a product with ID 0. Check your key names.");
    return;
  }

  final user = supabase.auth.currentUser;
  if (user == null) return;

  final wasLiked = likedProductIds.contains(productId);

  setState(() {
    if (wasLiked) {
      likedProductIds.remove(productId);
    } else {
      likedProductIds.add(productId);
    }
  });

  try {
    if (wasLiked) {
      await supabase
          .from('tbl_favourite')
          .delete()
          .match({'user_id': user.id, 'product_id': productId});
    } else {
      await supabase.from('tbl_favourite').insert({
        'user_id': user.id,
        'product_id': productId,
      });
    }
  } catch (e) {
    // Revert on error
    setState(() {
      if (wasLiked) {
        likedProductIds.add(productId);
      } else {
        likedProductIds.remove(productId);
      }
    });
    debugPrint("Database Error: $e");
  }
}

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF2E6CF6);

    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            /// HERO SECTION
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: primaryBlue,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(26),
                    bottomRight: Radius.circular(26),
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

            /// BANNER
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.orange.shade200,
                ),
                child: const Center(
                  child: Text("Post Ads & Sell Faster 🚀",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ),

            /// CATEGORIES
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  itemBuilder: (context, i) {
                    final c = categories[i];
                    return Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          c['category_name'] ?? '',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            /// SECTION TITLE
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text("Fresh Recommendations",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            /// PRODUCT GRID
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid.builder(
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                itemBuilder: (context, i) {
                  final product = products[i];
                  // Ensure ID is treated as int
                  final int productId = int.tryParse(product['id'].toString()) ?? 0;

                  return ProductCard(
                    title: product['product_name'] ?? '',
                    price: "₹${product['product_price'] ?? 0}",
                    location: product['tbl_place']?['place_name'] ?? 'Unknown',
                    imageUrl: product['image_url'] ?? '',
                    isLiked: likedProductIds.contains(productId),
                    onLikeTap: () => toggleLike(productId),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductDetailsPage(product: product),
                        ),
                      );
                    },
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                          )
                        : Container(color: Colors.grey.shade300),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton(
                      icon: Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        color: isLiked ? Colors.red : Colors.grey.shade700,
                      ),
                      onPressed: onLikeTap,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(price,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(location,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}