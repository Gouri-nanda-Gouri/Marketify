import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';

class District extends StatefulWidget {
  const District({super.key});

  @override
  State<District> createState() => _DistrictState();
}

class _DistrictState extends State<District> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController districtController = TextEditingController();

  List districtData = [];

  /// INSERT
  Future<void> insertDistrict() async {
    final name = districtController.text.trim();

    await supabase.from('tbl_district').insert({
      'district_name': name,
    });

    districtController.clear();
    fetchDistricts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("District Added Successfully")),
    );
  }

  /// FETCH
  Future<void> fetchDistricts() async {
    final response = await supabase.from('tbl_district').select();

    setState(() {
      districtData = response;
    });
  }

  /// UPDATE
  Future<void> updateDistrict(int id, String name) async {
    await supabase
        .from('tbl_district')
        .update({'district_name': name})
        .eq('id', id);

    fetchDistricts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("District Updated")),
    );
  }

  /// DELETE
  Future<void> deleteDistrict(int id) async {
    await supabase
        .from('tbl_district')
        .delete()
        .eq('id', id);

    fetchDistricts();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("District Deleted")),
    );
  }

  /// EDIT DIALOG
  void showEditDialog(int id, String oldName) {
    TextEditingController editController =
        TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit District"),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(
            labelText: "District Name",
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Update"),
            onPressed: () {
              final updatedName = editController.text.trim();

              if (updatedName.isNotEmpty) {
                updateDistrict(id, updatedName);
              }

              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  /// DELETE CONFIRM
  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete District"),
        content:
            const Text("Are you sure you want to delete this district?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () {
              deleteDistrict(id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchDistricts();
  }

  @override
  void dispose() {
    districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Add District"),
        backgroundColor: const Color(0xFF2E6CF6),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 18,
                  color: Color(0x11000000),
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [

                /// ICON
                const Icon(
                  Icons.location_city_outlined,
                  size: 48,
                  color: Color(0xFF2E6CF6),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Create New District",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 24),

                /// FORM
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: districtController,
                        validator: (value) =>
                            value!.isEmpty ? "Enter district name" : null,
                        decoration: InputDecoration(
                          labelText: "District Name",
                          prefixIcon: const Icon(Icons.edit_location_alt),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              insertDistrict();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E6CF6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Add District",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
                const Divider(),
                const SizedBox(height: 10),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "All Districts",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                /// LIST
                districtData.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No Districts Added"),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: districtData.length,
                        itemBuilder: (context, index) {
                          final data = districtData[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(
                                Icons.location_city,
                                color: Color(0xFF2E6CF6),
                              ),
                              title: Text(data['district_name']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  /// EDIT
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      showEditDialog(
                                        data['id'],
                                        data['district_name'],
                                      );
                                    },
                                  ),

                                  /// DELETE
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      confirmDelete(
                                          data['id']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
