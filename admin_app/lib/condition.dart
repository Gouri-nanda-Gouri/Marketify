import 'package:admin_app/main.dart';
import 'package:flutter/material.dart';

class Condition extends StatefulWidget {
  const Condition({super.key});

  @override
  State<Condition> createState() => _ConditionState();
}

class _ConditionState extends State<Condition> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController conditionController = TextEditingController();

  List conditionData = [];

  /// INSERT
  Future<void> insert() async {
    final conditionName = conditionController.text.trim();

    await supabase.from('tbl_condition').insert({
      'condition_name': conditionName,
    });

    conditionController.clear();
    fetchData();
  }

  /// FETCH
  Future<void> fetchData() async {
    final response = await supabase.from('tbl_condition').select();

    setState(() {
      conditionData = response;
    });
  }

  /// UPDATE
  Future<void> updateCondition(int id, String name) async {
    await supabase
        .from('tbl_condition')
        .update({'condition_name': name})
        .eq('id', id);

    fetchData();
  }

  /// DELETE
  Future<void> deleteCondition(int id) async {
    await supabase
        .from('tbl_condition')
        .delete()
        .eq('id', id);

    fetchData();
  }

  /// EDIT DIALOG
  void showEditDialog(int id, String oldName) {
    TextEditingController editController =
        TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Condition"),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              labelText: "Condition Name",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final updatedName = editController.text.trim();

                if (updatedName.isNotEmpty) {
                  updateCondition(id, updatedName);
                }

                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text("Add Condition"),
        backgroundColor: const Color(0xFF2E6CF6),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Condition Details",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Enter a new condition name",
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(height: 20),

                    /// TEXTFIELD
                    TextFormField(
                      controller: conditionController,
                      decoration: InputDecoration(
                        labelText: 'Condition Name',
                        prefixIcon: const Icon(Icons.rule),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Condition name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    /// BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E6CF6),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!.validate()) {
                            await insert();
                          }
                        },
                        child: const Text(
                          'Add Condition',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Divider(),

                    const SizedBox(height: 10),

                    const Text(
                      "Added Conditions",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    /// LIST VIEW
                    conditionData.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(
                              child: Text("No Conditions Added"),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            itemCount: conditionData.length,
                            itemBuilder: (context, index) {
                              final data = conditionData[index];

                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  title:
                                      Text(data['condition_name']),
                                  leading: const Icon(
                                    Icons.rule,
                                    color: Color(0xFF2E6CF6),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      /// EDIT
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.blue),
                                        onPressed: () {
                                          showEditDialog(
                                            data['id'], // <-- change if PK name differs
                                            data['condition_name'],
                                          );
                                        },
                                      ),

                                      /// DELETE
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () {
                                          deleteCondition(
                                            data['id'], // <-- change if PK name differs
                                          );
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
        ),
      ),
    );
  }
}
