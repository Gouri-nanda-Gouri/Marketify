import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/theme.dart';
import 'package:admin_app/widgets/custom_card.dart';
import 'package:admin_app/widgets/custom_button.dart';
import 'package:admin_app/widgets/custom_text_field.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('tbl_user')
          .select()
          .order('id', ascending: false);
          
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
        _filteredUsers = _users;
      });
    } catch (e) {
      debugPrint("Error fetching users: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterUsers(String query) {
    if (query.isEmpty) {
      setState(() => _filteredUsers = _users);
      return;
    }
    setState(() {
      _filteredUsers = _users.where((user) {
        final name = (user['user_name'] ?? '').toString().toLowerCase();
        final email = (user['user_email'] ?? '').toString().toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower) || email.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _toggleUserBlock(String userId, int currentStatus) async {
    final newStatus = currentStatus == 1 ? 0 : 1; // 1 = Active, 0 = Blocked
    try {
      await supabase
          .from('tbl_user')
          .update({'user_status': newStatus})
          .eq('id', userId);
          
      // Update local state to immediately reflect the change
      setState(() {
        final index = _users.indexWhere((u) => u['id'] == userId);
        if (index != -1) {
          _users[index]['user_status'] = newStatus;
        }
        _filterUsers(_searchController.text);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus == 0 ? 'User Blocked' : 'User Unblocked'),
          backgroundColor: newStatus == 0 ? AppTheme.warning : AppTheme.success,
        ),
      );
    } catch (e) {
      debugPrint("Error updating user status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update status'), backgroundColor: AppTheme.error),
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppTheme.padding * 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("User Management", style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _searchController,
                      label: '',
                      hint: "Search user by name or email...",
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  CustomButton(
                    text: 'Search',
                    onPressed: () => _filterUsers(_searchController.text),
                    width: 120,
                  ),
                ],
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _filteredUsers.isEmpty
                ? const Center(child: Text("No users found", style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding * 2, vertical: AppTheme.padding),
                    itemCount: _filteredUsers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final user = _filteredUsers[index];
                      // Assume: user_status == 1 means Active, anything else (0 or null) is blocked
                      // If user_status field is completely absent, we assume active for legacy reasons
                      final int status = (user['user_status'] ?? 1) as int; 
                      final bool isBlocked = status == 0;
                      
                      return CustomCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: AppTheme.primary.withOpacity(0.1),
                              backgroundImage: user['user_photo'] != null ? NetworkImage(user['user_photo']) : null,
                              child: user['user_photo'] == null 
                                ? Text((user['user_name'] ?? 'U')[0].toUpperCase(), style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 24))
                                : null,
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user['user_name'] ?? 'Unknown User',
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user['user_email'] ?? 'No email',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isBlocked ? AppTheme.error.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      isBlocked ? "Blocked" : "Active",
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isBlocked ? AppTheme.error : AppTheme.success,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            CustomButton(
                              text: isBlocked ? "Unblock" : "Block",
                              isSecondary: !isBlocked,
                              width: 110,
                              onPressed: () => _toggleUserBlock(user['id'].toString(), status),
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
