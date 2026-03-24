import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/product_details.dart';
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_app_bar.dart';
import 'package:user_app/widgets/custom_card.dart';

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

      final response = await supabase
          .from('tbl_favourite')
          .select('*, tbl_product(*, tbl_place(place_name))')
          .eq('user_id', user.id);

      final List<Map<String, dynamic>> fetchedProducts = [];
      
      for (var item in (response as List)) {
        if (item['tbl_product'] != null) {
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

      setState(() {
        favouriteProducts.removeWhere((p) => p['product_id'] == productId);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from favorites'), backgroundColor: AppTheme.primary),
        );
      }
    } catch (e) {
      debugPrint("Error removing favorite: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(title: "My Favourites"),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : favouriteProducts.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding, vertical: 16),
                  itemCount: favouriteProducts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, i) {
                    final product = favouriteProducts[i];
                    return _FavouriteCard(
                      product: product,
                      onRemove: () => removeFromFavourites(product['product_id'] ?? product['id']),
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
          Icon(Icons.favorite_border, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "No favorites yet",
            style: Theme.of(context).textTheme.titleMedium,
          ),
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
      child: CustomCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadius)),
                    child: product['image_url'] != null && String.fromEnvironment('image_url', defaultValue: product['image_url']).isNotEmpty
                        ? Image.network(
                            product['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) =>
                                Container(color: AppTheme.divider, child: const Icon(Icons.image_not_supported, color: AppTheme.textSecondary)),
                          )
                        : Container(color: AppTheme.divider, child: const Icon(Icons.image, color: AppTheme.textSecondary)),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.background,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite, color: AppTheme.error, size: 20),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                        onPressed: onRemove,
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹${product['product_price']}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.primary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product['product_name'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          product['tbl_place']?['place_name'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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