import 'package:flutter/material.dart';
import 'package:user_app/chat.dart';

class ProductDetailsPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final sellerId = product['user_id'];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Product Details"),
        actions: const [
          Icon(Icons.favorite_border),
          SizedBox(width: 12),
          Icon(Icons.share),
          SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// IMAGE SECTION
            Container(
              height: 280,
              width: double.infinity,
              color: Colors.black,
              child: Image.network(
                product['image_url'] ?? '',
                fit: BoxFit.cover,
              ),
            ),

            /// PRICE + TITLE
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "₹ ${product['product_price']}",
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    product['product_name'] ?? '',
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        product['tbl_place']?['place_name'] ?? 'Location',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const Spacer(),
                      const Text("Today",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// MAKE OFFER + CHAT + CALL BUTTONS
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [

                  /// MAKE OFFER
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          builder: (_) => _OfferBottomSheet(
                            productId: product['product_id'],
                          ),
                        );
                      },
                      child: const Text("Make an Offer"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// CHAT WITH SELLER
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.chat),
                      label: const Text("Chat with seller"),
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
                  ),

                  const SizedBox(height: 10),

                  /// CALL SELLER
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.call),
                      label: const Text("Call seller"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () {
                        // add call logic
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// SELLER CARD
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
                    child: Icon(Icons.person),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Seller Name",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text("Member since 2024",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text("View profile"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// DESCRIPTION
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Description",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(product['product_description'] ?? ''),
                ],
              ),
            ),

            const SizedBox(height: 10),

            /// SAFETY TIPS
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Safety Tips",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text("• Meet seller in safe public place"),
                  Text("• Check item before payment"),
                  Text("• Avoid advance payments"),
                ],
              ),
            ),
          ],
        ),
      ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Make an Offer",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: offerController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter your offer price",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // store offer in DB
              Navigator.pop(context);
            },
            child: const Text("Submit Offer"),
          )
        ],
      ),
    );
  }
}
