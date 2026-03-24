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
    await supabase.from('tbl_condition').delete().eq('id', id);
    fetchData();
  }

  /// EDIT DIALOG (UPGRADED UI)
  void showEditDialog(int id, String oldName) {
    TextEditingController editController =
        TextEditingController(text: oldName);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Edit Condition",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: editController,
                  decoration: InputDecoration(
                    labelText: "Condition Name",
                    filled: true,
                    fillColor: const Color(0xFFF5F7FF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel")),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E6CF6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
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
                )
              ],
            ),
          ),
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
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            const Text(
              "Condition Management",
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage product conditions like New, Used, etc.",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 24),

            /// ADD CONDITION CARD
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "+ Add New Condition",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: conditionController,
                      decoration: InputDecoration(
                        hintText: "Enter condition name...",
                        prefixIcon: const Icon(Icons.rule),
                        filled: true,
                        fillColor: const Color(0xFFF9FAFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty) {
                          return 'Condition name is required';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF2E6CF6),
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () async {
                          if (_formKey.currentState!
                              .validate()) {
                            await insert();
                          }
                        },
                        child: const Text(
                          'Add Condition',
                          style: TextStyle(
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            /// LIST HEADER
            const Text(
              "Conditions List",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            /// LIST
            Expanded(
              child: conditionData.isEmpty
                  ? const Center(
                      child: Text(
                        "📭 No conditions yet\nAdd one above",
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: conditionData.length,
                      itemBuilder: (context, index) {
                        final data = conditionData[index];

                        return Container(
                          margin: const EdgeInsets.only(
                              bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black
                                    .withOpacity(0.03),
                                blurRadius: 8,
                                offset:
                                    const Offset(0, 3),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.rule,
                                  color:
                                      Color(0xFF2E6CF6)),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Text(
                                  data['condition_name'],
                                  style: const TextStyle(
                                      fontWeight:
                                          FontWeight.w600),
                                ),
                              ),

                              /// EDIT
                              IconButton(
                                icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue),
                                onPressed: () {
                                  showEditDialog(
                                      data['id'],
                                      data[
                                          'condition_name']);
                                },
                              ),

                              /// DELETE
                              IconButton(
                                icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  deleteCondition(
                                      data['id']);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            )
          ],
        ),
      ),
    );
  }
}