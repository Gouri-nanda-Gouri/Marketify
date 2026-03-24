import 'package:flutter/material.dart';
import 'package:user_app/chat.dart';
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_button.dart';
import 'package:user_app/widgets/custom_card.dart';
import 'package:user_app/widgets/custom_app_bar.dart';
import 'package:user_app/widgets/custom_text_field.dart';

class ProductDetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final sellerId = product['user_id'];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(
        title: "Product Details",
        actions: [
          Icon(Icons.favorite_border),
          SizedBox(width: 16),
          Icon(Icons.share_outlined),
          SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGE SECTION
            Container(
              height: 320,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.card,
                image: DecorationImage(
                  image: NetworkImage(product['image_url'] ?? ''),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            const SizedBox(height: AppTheme.spacing),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// PRICE + TITLE
                  CustomCard(
                    padding: const EdgeInsets.all(AppTheme.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "₹ ${product['product_price']}",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product['product_name'] ?? '',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18, color: AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              product['tbl_place']?['place_name'] ?? 'Location',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                            ),
                            const Spacer(),
                            Text("Today", style: Theme.of(context).textTheme.bodySmall),
                          ],
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.padding),

                  /// SELLER CARD
                  CustomCard(
                    padding: const EdgeInsets.all(AppTheme.padding),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.background,
                          child: Icon(Icons.person, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Seller Name",
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Member since 2024",
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textSecondary),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.padding),

                  /// DESCRIPTION
                  CustomCard(
                    padding: const EdgeInsets.all(AppTheme.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          product['product_description'] ?? 'No description provided.',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppTheme.padding),

                  /// SAFETY TIPS
                  CustomCard(
                    padding: const EdgeInsets.all(AppTheme.padding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security, color: AppTheme.success, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              "Safety Tips",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSafetyTip("Meet seller in a safe public place"),
                        const SizedBox(height: 8),
                        _buildSafetyTip("Check the item before payment"),
                        const SizedBox(height: 8),
                        _buildSafetyTip("Avoid advance payments"),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      
      /// STICKY BOTTOM ACTIONS
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppTheme.padding),
        decoration: BoxDecoration(
          color: AppTheme.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomButton(
                text: "Chat with seller",
                icon: const Icon(Icons.chat_bubble_outline, size: 20),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        peerId: sellerId,
                        productId: product['product_id'],
                        productName: product['product_name'],
                        productImage: product['image_url'],
                        price: product['product_price'].toString(),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "Make Offer",
                      isSecondary: true,
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.borderRadiusLarge)),
                          ),
                          builder: (_) => _OfferBottomSheet(
                            productId: product['product_id'],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomButton(
                      text: "Call",
                      isSecondary: true,
                      icon: const Icon(Icons.phone_outlined, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyTip(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("• ", style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class _OfferBottomSheet extends StatelessWidget {
  final int productId;

  const _OfferBottomSheet({required this.productId});

  @override
  Widget build(BuildContext context) {
    final TextEditingController offerController = TextEditingController();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AppTheme.padding,
        right: AppTheme.padding,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Make an Offer", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          CustomTextField(
            label: "Your Offer Price",
            hint: "e.g. 500",
            controller: offerController,
            keyboardType: TextInputType.number,
            prefixIcon: const Icon(Icons.currency_rupee, size: 18),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: "Submit Offer",
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
