import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/theme.dart';
import 'package:admin_app/widgets/custom_card.dart';
import 'package:admin_app/widgets/custom_button.dart';
import 'package:admin_app/widgets/custom_text_field.dart';

class ListingManagementScreen extends StatefulWidget {
  const ListingManagementScreen({super.key});

  @override
  State<ListingManagementScreen> createState() => _ListingManagementScreenState();
}

class _ListingManagementScreenState extends State<ListingManagementScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _listings = [];
  List<Map<String, dynamic>> _filteredListings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchListings();
  }

  Future<void> _fetchListings() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('tbl_product')
          .select()
          .order('id', ascending: false);
          
      setState(() {
        _listings = List<Map<String, dynamic>>.from(response);
        _filteredListings = _listings;
      });
    } catch (e) {
      debugPrint("Error fetching listings: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterListings(String query) {
    if (query.isEmpty) {
      setState(() => _filteredListings = _listings);
      return;
    }
    setState(() {
      _filteredListings = _listings.where((listing) {
        final title = (listing['product_name'] ?? '').toString().toLowerCase();
        final desc = (listing['product_description'] ?? '').toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return title.contains(searchLower) || desc.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _toggleListingStatus(String listingId, int currentStatus) async {
    final newStatus = currentStatus == 1 ? 0 : 1; // 1 = Active/Approved, 0 = Blocked/Rejected
    try {
      await supabase
          .from('tbl_product')
          .update({'product_status': newStatus})
          .eq('id', listingId);
          
      // Update local state to immediately reflect the change
      setState(() {
        final index = _listings.indexWhere((l) => l['id'] == listingId);
        if (index != -1) {
          _listings[index]['product_status'] = newStatus;
        }
        _filterListings(_searchController.text);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 0 ? 'Listing Blocked' : 'Listing Approved'),
          backgroundColor: newStatus == 0 ? AppTheme.warning : AppTheme.success,
        ),
      );
    } catch (e) {
      debugPrint("Error updating listing status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: AppTheme.error),
      );
    }
  }

  Future<void> _deleteListing(String listingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Listing"),
        content: const Text("Are you sure you want to permanently delete this listing?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text("Delete", style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('tbl_product').delete().eq('id', listingId);
      
      setState(() {
        _listings.removeWhere((l) => l['id'] == listingId);
        _filterListings(_searchController.text);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Listing deleted successfully"), backgroundColor: AppTheme.success),
        );
      }
    } catch (e) {
      debugPrint("Error deleting listing: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete listing"), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.padding * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Listing Management", style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _searchController,
                      label: '',
                      hint: "Search listings by name...",
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: 'Search',
                    onPressed: () => _filterListings(_searchController.text),
                    width: 120,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _filteredListings.isEmpty
                ? const Center(child: Text("No listings found", style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding * 2, vertical: AppTheme.padding),
                    itemCount: _filteredListings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final listing = _filteredListings[index];
                      // Assume: product_status == 1 means Active, 0 means blocked/rejected
                      final int status = int.tryParse(listing['product_status'].toString()) ?? 1; 
                      final bool isBlocked = status == 0;
                      
                      return CustomCard(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 80,
                                height: 80,
                                color: AppTheme.primary.withOpacity(0.1),
                                child: listing['product_image'] != null && listing['product_image'].toString().isNotEmpty
                                    ? Image.network(
                                        listing['product_image'], 
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported, color: AppTheme.textSecondary),
                                      )
                                    : const Icon(Icons.shopping_bag_outlined, color: AppTheme.primary, size: 32),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          listing['product_name'] ?? 'Unnamed Product',
                                          style: Theme.of(context).textTheme.titleMedium,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isBlocked ? AppTheme.error.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isBlocked ? "Blocked" : "Active",
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isBlocked ? AppTheme.error : AppTheme.success,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "₹${listing['product_price'] ?? '0'}",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    listing['product_description'] ?? 'No description',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CustomButton(
                                  text: isBlocked ? "Approve" : "Block",
                                  isSecondary: !isBlocked,
                                  width: 100,
                                  onPressed: () => _toggleListingStatus(listing['id'].toString(), status),
                                ),
                                const SizedBox(height: 8),
                                CustomButton(
                                  text: "Delete",
                                  isSecondary: true,
                                  width: 100,
                                  onPressed: () => _deleteListing(listing['id'].toString()),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
        ),
      ],
    );
  }
}
