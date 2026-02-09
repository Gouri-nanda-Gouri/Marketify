import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/product_details.dart';

class MyFavourites extends StatefulWidget {
  const MyFavourites({super.key});

  @override
  State<MyFavourites> createState() => _MyFavouritesState();
}

class _MyFavouritesState extends State<MyFavourites> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> favouriteProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFavourites();
  }

 Future<void> fetchFavourites() async {
  try {
    final user = supabase.auth.currentUser;
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    // 1. Fetch the data
    // Note: Ensure 'product_id' is the correct column name in tbl_favourite
    final response = await supabase
        .from('tbl_favourite')
        .select('*, tbl_product(*, tbl_place(place_name))')
        .eq('user_id', user.id);

    debugPrint("Raw Favourite Response: $response");

    // 2. Safely parse the nested data
    final List<Map<String, dynamic>> fetchedProducts = [];
    
    for (var item in (response as List)) {
      if (item['tbl_product'] != null) {
        // We take the product data and add it to our list
        fetchedProducts.add(item['tbl_product'] as Map<String, dynamic>);
      }
    }

    setState(() {
      favouriteProducts = fetchedProducts;
      isLoading = false;
    });
  } catch (e) {
    debugPrint("Error fetching favourites: $e");
    setState(() => isLoading = false);
  }
}

  Future<void> removeFromFavourites(int productId) async {
    try {
      final user = supabase.auth.currentUser;
      await supabase
          .from('tbl_favourite')
          .delete()
          .match({'user_id': user!.id, 'product_id': productId});

      // Refresh the list locally
      setState(() {
        favouriteProducts.removeWhere((p) => p['product_id'] == productId);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
    } catch (e) {
      debugPrint("Error removing favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("My Favourites", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : favouriteProducts.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: favouriteProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  itemBuilder: (context, i) {
                    final product = favouriteProducts[i];
                    return _FavouriteCard(
                      product: product,
                      onRemove: () => removeFromFavourites(product['product_id']),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("No favorites yet",
              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _FavouriteCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onRemove;

  const _FavouriteCard({required this.product, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ProductDetailsPage(product: product)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Image.network(
                      product['image_url'] ?? '',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: onRemove,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("₹${product['product_price']}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(product['product_name'] ?? '',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(product['tbl_place']?['place_name'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 11, color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}