import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user_app/theme.dart';
import 'package:user_app/widgets/custom_app_bar.dart';
import 'package:user_app/widgets/custom_button.dart';
import 'package:user_app/widgets/custom_card.dart';
import 'package:user_app/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await supabase
          .from('tbl_complaint')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        _complaints = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching complaints: $e");
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final dt = DateTime.parse(dateString).toLocal();
      return DateFormat('MMM dd, yyyy').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(title: "My Complaints"),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
          : _complaints.isEmpty
              ? _buildEmptyState()
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding, vertical: 16),
                  itemCount: _complaints.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final complaint = _complaints[index];
                    final isResolved = (complaint['complaint_status'] == 1 || 
                                        complaint['complaint_status'] == 'Resolved' ||
                                        complaint['complaint_status'] == true);

                    return CustomCard(
                      padding: const EdgeInsets.all(16),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ComplaintDetailScreen(complaint: complaint),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    complaint['complaint_title'] ?? 'Complaint',
                                    style: Theme.of(context).textTheme.titleMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isResolved 
                                        ? AppTheme.success.withOpacity(0.1) 
                                        : AppTheme.warning.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isResolved ? "Resolved" : "Pending",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isResolved ? AppTheme.success : AppTheme.warning,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              complaint['complaint_content'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatDate(complaint['created_at']),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.divider,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RaiseComplaintScreen()),
          ).then((_) => _fetchComplaints());
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Raise Complaint", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent_outlined, size: 64, color: AppTheme.primary.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text("No Complaints", style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            "You haven't raised any complaints yet.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}

class RaiseComplaintScreen extends StatefulWidget {
  const RaiseComplaintScreen({super.key});

  @override
  State<RaiseComplaintScreen> createState() => _RaiseComplaintScreenState();
}

class _RaiseComplaintScreenState extends State<RaiseComplaintScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final supabase = Supabase.instance.client;
  
  bool _isLoading = false;
  String? _selectedType;

  final List<String> _complaintTypes = [
    'Spam or Scam',
    'Offensive Content',
    'App Issue',
    'Payment Issue',
    'Other'
  ];

  Future<void> _submitComplaint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a complaint type'), backgroundColor: AppTheme.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = supabase.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      await supabase.from('tbl_complaint').insert({
        'user_id': user.id,
        'complaint_title': _selectedType! + " - " + _titleController.text.trim(),
        'complaint_content': _descController.text.trim(),
        'complaint_status': 0, // 0 for pending
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complaint submitted successfully'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(title: "Raise Complaint"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "We are here to help",
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                "Please provide details about your issue so we can assist you better.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
              
              const SizedBox(height: 32),
              
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  labelText: "Complaint Type",
                  filled: true,
                  fillColor: AppTheme.card,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _complaintTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val),
              ),
              
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _titleController,
                label: "Short Title",
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              
              const SizedBox(height: 16),
              
              CustomTextField(
                controller: _descController,
                label: "Detailed Description",
                maxLines: 5,
                validator: (val) => val == null || val.isEmpty ? "Required" : null,
              ),
              
              const SizedBox(height: 32),
              
              CustomButton(
                text: "Submit Complaint",
                isLoading: _isLoading,
                onPressed: _submitComplaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ComplaintDetailScreen extends StatelessWidget {
  final Map<String, dynamic> complaint;

  const ComplaintDetailScreen({super.key, required this.complaint});

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final dt = DateTime.parse(dateString).toLocal();
      return DateFormat('MMMM dd, yyyy - hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = (complaint['complaint_status'] == 1 || 
                        complaint['complaint_status'] == 'Resolved' ||
                        complaint['complaint_status'] == true);
                        
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const CustomAppBar(title: "Complaint Details"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Status",
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isResolved 
                        ? AppTheme.success.withOpacity(0.1) 
                        : AppTheme.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isResolved ? "Resolved" : "Pending",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isResolved ? AppTheme.success : AppTheme.warning,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            CustomCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    complaint['complaint_title'] ?? 'Complaint',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(complaint['created_at']),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Divider(color: AppTheme.divider),
                  ),
                  Text(
                    "Description",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    complaint['complaint_content'] ?? 'No description provided.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            if (complaint['complaint_reply'] != null && complaint['complaint_reply'].toString().isNotEmpty)
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.admin_panel_settings, color: AppTheme.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          "Admin Response",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: AppTheme.divider),
                    ),
                    Text(
                      complaint['complaint_reply'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
