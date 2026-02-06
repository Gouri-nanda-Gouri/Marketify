import 'package:flutter/material.dart';
import 'package:admin_app/main.dart';

class Place extends StatefulWidget {
  const Place({super.key});

  @override
  State<Place> createState() => _PlaceState();
}

class _PlaceState extends State<Place> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController placeController = TextEditingController();

  List placeData = [];
  List districtList = [];

  int? selectedDistrict;

  /// FETCH DISTRICT FOR DROPDOWN
  Future<void> fetchDistricts() async {
    final response = await supabase.from('tbl_district').select();

    setState(() {
      districtList = response;
    });
  }

  /// INSERT
  Future<void> insertPlace() async {
    final name = placeController.text.trim();

    await supabase.from('tbl_place').insert({
      'place_name': name,
      'district_id': selectedDistrict,
    });

    placeController.clear();
    selectedDistrict = null;

    fetchPlaces();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Place Added Successfully")),
    );
  }

  /// FETCH PLACE WITH DISTRICT NAME
  Future<void> fetchPlaces() async {
    final response = await supabase
        .from('tbl_place')
        .select('*, tbl_district(district_name)');

    setState(() {
      placeData = response;
    });
  }

  /// UPDATE
  Future<void> updatePlace(int id, String name, int districtId) async {
    await supabase.from('tbl_place').update({
      'place_name': name,
      'district_id': districtId,
    }).eq('place_id', id);

    fetchPlaces();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Place Updated")),
    );
  }

  /// DELETE
  Future<void> deletePlace(int id) async {
    await supabase.from('tbl_place').delete().eq('place_id', id);

    fetchPlaces();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Place Deleted")),
    );
  }

  /// EDIT DIALOG
  void showEditDialog(int id, String oldName, int oldDistrict) {
    TextEditingController editController =
        TextEditingController(text: oldName);

    int? editDistrict = oldDistrict;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Edit Place"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// NAME
              TextField(
                controller: editController,
                decoration: const InputDecoration(
                  labelText: "Place Name",
                ),
              ),

              const SizedBox(height: 15),

              /// DISTRICT DROPDOWN
              DropdownButtonFormField<int>(
                value: editDistrict,
                items: districtList.map<DropdownMenuItem<int>>((district) {
                  return DropdownMenuItem(
                    value: district['id'],
                    child: Text(district['district_name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setStateDialog(() {
                    editDistrict = value;
                  });
                },
                decoration: const InputDecoration(
                  labelText: "Select District",
                ),
              ),
            ],
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

                if (updatedName.isNotEmpty && editDistrict != null) {
                  updatePlace(id, updatedName, editDistrict!);
                }

                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// DELETE CONFIRM
  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Place"),
        content: const Text("Are you sure you want to delete this place?"),
        actions: [
          TextButton(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: const Text("Delete"),
            onPressed: () {
              deletePlace(id);
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
    fetchPlaces();
  }

  @override
  void dispose() {
    placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Add Place"),
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

                const Icon(Icons.place_outlined,
                    size: 48, color: Color(0xFF2E6CF6)),

                const SizedBox(height: 10),

                const Text(
                  "Create New Place",
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w900),
                ),

                const SizedBox(height: 24),

                /// FORM
                Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      /// PLACE NAME
                      TextFormField(
                        controller: placeController,
                        validator: (value) =>
                            value!.isEmpty ? "Enter place name" : null,
                        decoration: InputDecoration(
                          labelText: "Place Name",
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      /// DISTRICT DROPDOWN
                      DropdownButtonFormField<int>(
                        value: selectedDistrict,
                        hint: const Text("Select District"),
                        items:
                            districtList.map<DropdownMenuItem<int>>((district) {
                          return DropdownMenuItem(
                            value: district['id'],
                            child: Text(district['district_name']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedDistrict = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? "Select district" : null,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.map),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      /// BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              insertPlace();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E6CF6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Add Place",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w800),
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
                    "All Places",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 10),

                /// LIST
                placeData.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text("No Places Added"),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        itemCount: placeData.length,
                        itemBuilder: (context, index) {
                          final data = placeData[index];

                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.place,
                                  color: Color(0xFF2E6CF6)),
                              title: Text(data['place_name']),
                              subtitle: Text(
                                  data['tbl_district']['district_name']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  /// EDIT
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () {
                                      showEditDialog(
                                        data['place_id'],
                                        data['place_name'],
                                        data['id'],
                                      );
                                    },
                                  ),

                                  /// DELETE
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () {
                                      confirmDelete(data['place_id']);
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
