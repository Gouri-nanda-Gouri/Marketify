import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/theme.dart';
import 'package:admin_app/widgets/custom_card.dart';
import 'package:admin_app/widgets/custom_button.dart';
import 'package:admin_app/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';

class ComplaintManagementScreen extends StatefulWidget {
  const ComplaintManagementScreen({super.key});

  @override
  State<ComplaintManagementScreen> createState() => _ComplaintManagementScreenState();
}

class _ComplaintManagementScreenState extends State<ComplaintManagementScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _complaints = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchComplaints();
  }

  Future<void> _fetchComplaints() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('tbl_complaint')
          .select('*, tbl_user(user_name, user_email)')
          .order('created_at', ascending: false);

      setState(() {
        _complaints = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint("Error fetching complaints: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final dt = DateTime.parse(dateString).toLocal();
      return DateFormat('MMM dd, yyyy - hh:mm a').format(dt);
    } catch (e) {
      return '';
    }
  }

  void _showComplaintDetails(Map<String, dynamic> complaint) {
    showDialog(
      context: context,
      builder: (context) => _ComplaintDetailDialog(
        complaint: complaint,
        onResolved: (reply) async {
          await _resolveComplaint(complaint['id'].toString(), reply);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _resolveComplaint(String id, String reply) async {
    try {
      await supabase
          .from('tbl_complaint')
          .update({
            'complaint_status': 1, // 1 = Resolved
            'complaint_reply': reply,
          })
          .eq('id', id);

      setState(() {
        final index = _complaints.indexWhere((c) => c['id'].toString() == id);
        if (index != -1) {
          _complaints[index]['complaint_status'] = 1;
          _complaints[index]['complaint_reply'] = reply;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint marked as resolved'), backgroundColor: AppTheme.success),
      );
    } catch (e) {
      debugPrint("Error resolving complaint: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to resolve complaint'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.padding * 2),
          child: Text("Complaint Management", style: Theme.of(context).textTheme.headlineMedium),
        ),
        
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _complaints.isEmpty
                ? const Center(child: Text("No complaints found", style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding * 2, vertical: AppTheme.padding),
                    itemCount: _complaints.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final complaint = _complaints[index];
                      final isResolved = complaint['complaint_status'] == 1 || complaint['complaint_status'] == 'Resolved';
                      final user = complaint['tbl_user'] ?? {};
                      
                      return CustomCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isResolved ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isResolved ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                                color: isResolved ? AppTheme.success : AppTheme.warning,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          complaint['complaint_title'] ?? 'Untitled',
                                          style: Theme.of(context).textTheme.titleLarge,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isResolved ? AppTheme.success.withOpacity(0.1) : AppTheme.warning.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          isResolved ? "Resolved" : "Pending",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isResolved ? AppTheme.success : AppTheme.warning,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "From: ${user['user_name'] ?? 'Unknown'} (${user['user_email'] ?? 'No email'})",
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    complaint['complaint_content'] ?? 'No description provided.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _formatDate(complaint['created_at']),
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.divider),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            CustomButton(
                              text: "View Details",
                              isSecondary: true,
                              width: 120,
                              onPressed: () => _showComplaintDetails(complaint),
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

class _ComplaintDetailDialog extends StatefulWidget {
  final Map<String, dynamic> complaint;
  final Function(String) onResolved;

  const _ComplaintDetailDialog({required this.complaint, required this.onResolved});

  @override
  State<_ComplaintDetailDialog> createState() => _ComplaintDetailDialogState();
}

class _ComplaintDetailDialogState extends State<_ComplaintDetailDialog> {
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.complaint['complaint_reply'] != null) {
      _replyController.text = widget.complaint['complaint_reply'];
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final complaint = widget.complaint;
    final isResolved = complaint['complaint_status'] == 1 || complaint['complaint_status'] == 'Resolved';
    final user = complaint['tbl_user'] ?? {};

    return AlertDialog(
      backgroundColor: AppTheme.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("Complaint Details"),
          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ],
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("User Info", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text("Name: ${user['user_name'] ?? 'Unknown'}"),
                    Text("Email: ${user['user_email'] ?? 'No email'}"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Issue", style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      complaint['complaint_title'] ?? 'Untitled',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(complaint['complaint_content'] ?? 'No content'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              isResolved
                  ? CustomCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
                              const SizedBox(width: 8),
                              Text("Resolved", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppTheme.success)),
                            ],
                          ),
                          const Divider(height: 24),
                          Text(complaint['complaint_reply'] ?? 'Marked as resolved with no comments.'),
                        ],
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Admin Reply", style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        CustomTextField(
                          controller: _replyController,
                          label: '',
                          hint: "Type the resolution message here...",
                          maxLines: 4,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
      actions: [
        if (!isResolved)
          CustomButton(
            text: "Mark as Resolved",
            onPressed: () {
              if (_replyController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a reply text.'), backgroundColor: AppTheme.error));
                return;
              }
              widget.onResolved(_replyController.text.trim());
            },
          ),
      ],
    );
  }
}
