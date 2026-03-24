import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditAdPage extends StatefulWidget {
  final Map<String, dynamic> ad;

  const EditAdPage({super.key, required this.ad});

  @override
  State<EditAdPage> createState() => _EditAdPageState();
}

class _EditAdPageState extends State<EditAdPage> {
  final supabase = Supabase.instance.client;

  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController priceController;

  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController =
        TextEditingController(text: widget.ad['product_name']);
    descController =
        TextEditingController(text: widget.ad['product_description']);
    priceController =
        TextEditingController(text: widget.ad['product_price'].toString());
  }
Future<void> updateAd() async {
  if (priceController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Price cannot be empty")),
    );
    return;
  }

  setState(() => isLoading = true);

  try {
    final productId = widget.ad['id'];

    if (productId == null) {
      throw Exception("Product ID is NULL");
      
    }

    await supabase.from('tbl_product').update({
      'product_name': nameController.text.trim(),
      'product_description': descController.text.trim(),
      'product_price': double.tryParse(priceController.text) ?? 0,
    }).eq('id', productId);

    if (mounted) {
      Navigator.pop(context, true); // return success
    }

  } catch (e) {
    debugPrint("Error updating ad: $e");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  } finally {
    if (mounted) {
      setState(() => isLoading = false);  // ✅ ALWAYS stops loading
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Ad")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Product Name"),
            ),
            TextField(
              controller: descController,
              decoration:
                  const InputDecoration(labelText: "Product Description"),
            ),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Price"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : updateAd,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Update"),
            )
          ],
        ),
      ),
    );
  }
}