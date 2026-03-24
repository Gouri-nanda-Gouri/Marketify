import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/edit_ad_page.dart';
import 'package:user_app/homescreen.dart';
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_app_bar.dart';
import 'package:user_app/widgets/custom_card.dart';

class Myads extends StatefulWidget {
  const Myads({super.key});

  @override
  State<Myads> createState() => _MyadsState();
}

class _MyadsState extends State<Myads> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> myAds = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMyAds();
  }

  Future<void> fetchMyAds() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_product')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        myAds = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error fetching ads: $e");
    }
  }

  Future<void> deleteAd(int productId) async {
    try {
      await supabase.from('tbl_product').delete().eq('id', productId);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } catch (e) {
      debugPrint("Error deleting ad: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(title: "My Ads", showBackButton: false),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : myAds.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text("No ads posted yet", style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding, vertical: 8),
                  itemCount: myAds.length,
                  itemBuilder: (context, index) {
                    final ad = myAds[index];

                    return Dismissible(
                      key: Key(ad['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.error,
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                            ),
                            title: const Text("Delete Ad"),
                            content: const Text("Are you sure you want to delete this ad?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text("Cancel", style: TextStyle(color: AppTheme.textSecondary)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text("Delete", style: TextStyle(color: AppTheme.error)),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (direction) async {
                        final productId = ad['id'];
                        await deleteAd(productId);
                        setState(() {
                          myAds.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Ad deleted"), backgroundColor: AppTheme.primary),
                        );
                      },
                      child: CustomCard(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: ad['image_url'] != null && String.fromEnvironment('image_url', defaultValue: ad['image_url']).isNotEmpty
                                  ? Image.network(
                                      ad['image_url'],
                                      height: 90,
                                      width: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stack) =>
                                          Container(height: 90, width: 90, color: AppTheme.divider, child: const Icon(Icons.image_not_supported, color: AppTheme.textSecondary)),
                                    )
                                  : Container(
                                      height: 90,
                                      width: 90,
                                      color: AppTheme.divider,
                                      child: const Icon(Icons.image, color: AppTheme.textSecondary),
                                    ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ad['product_name'] ?? "",
                                    style: Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ad['product_description'] ?? "",
                                    style: Theme.of(context).textTheme.bodySmall,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "₹ ${ad['product_price']}",
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppTheme.primary,
                                        ),
                                      ),
                                      Container(
                                        height: 32,
                                        width: 32,
                                        decoration: BoxDecoration(
                                          color: AppTheme.background,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textPrimary),
                                          onPressed: () async {
                                            await Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => EditAdPage(ad: ad),
                                              ),
                                            );
                                            fetchMyAds(); // refresh after editing
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

