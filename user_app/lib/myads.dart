import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
    await supabase.from('tbl_product').delete().eq('product_id', productId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Ads"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : myAds.isEmpty
              ? const Center(child: Text("No ads posted yet"))
              : ListView.builder(
                  itemCount: myAds.length,
                  itemBuilder: (context, index) {
                    final ad = myAds[index];

                    return Dismissible(
                      key: Key(ad['product_id'].toString()),
                      direction: DismissDirection.endToStart,

                      // Background while sliding
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),

                      confirmDismiss: (direction) async {
                        return await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Delete Ad"),
                            content: const Text(
                                "Are you sure you want to delete this ad?"),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );
                      },

                      onDismissed: (direction) async {
                        final productId = ad['product_id'];

                        await deleteAd(productId);

                        setState(() {
                          myAds.removeAt(index);
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Ad deleted")),
                        );
                      },

                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: ad['image_url'] != null
                                    ? Image.network(
                                        ad['image_url'],
                                        height: 80,
                                        width: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : Container(
                                        height: 80,
                                        width: 80,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image),
                                      ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ad['product_name'] ?? "",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      ad['product_description'] ?? "",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      "₹ ${ad['product_price']}",
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
