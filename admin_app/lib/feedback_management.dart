import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:admin_app/theme.dart';
import 'package:admin_app/widgets/custom_card.dart';
import 'package:admin_app/widgets/custom_text_field.dart';
import 'package:intl/intl.dart';

class FeedbackManagementScreen extends StatefulWidget {
  const FeedbackManagementScreen({super.key});

  @override
  State<FeedbackManagementScreen> createState() => _FeedbackManagementScreenState();
}

class _FeedbackManagementScreenState extends State<FeedbackManagementScreen> {
  final supabase = Supabase.instance.client;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _feedbacks = [];
  List<Map<String, dynamic>> _filteredFeedbacks = [];
  bool _isLoading = true;
  String _sortMode = 'Recent';

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('tbl_feedback')
          .select('*, tbl_user(user_name, user_email)')
          .order('created_at', ascending: false);
          
      setState(() {
        _feedbacks = List<Map<String, dynamic>>.from(response);
        _applySortAndFilter();
      });
    } catch (e) {
      debugPrint("Error fetching feedbacks: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySortAndFilter() {
    List<Map<String, dynamic>> result = List.from(_feedbacks);
    
    // Search
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((f) {
        final comment = (f['feedback_content'] ?? '').toString().toLowerCase();
        final name = (f['tbl_user']?['user_name'] ?? '').toString().toLowerCase();
        return comment.contains(query) || name.contains(query);
      }).toList();
    }

    // Sort
    if (_sortMode == 'Recent') {
      result.sort((a, b) => b['created_at'].toString().compareTo(a['created_at'].toString()));
    } else if (_sortMode == 'Highest Rating') {
      result.sort((a, b) => (b['feedback_rating'] ?? 0).compareTo(a['feedback_rating'] ?? 0));
    } else if (_sortMode == 'Lowest Rating') {
      result.sort((a, b) => (a['feedback_rating'] ?? 0).compareTo(b['feedback_rating'] ?? 0));
    }

    setState(() {
      _filteredFeedbacks = result;
    });
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
              Text("Feedback Management", style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _searchController,
                      label: '',
                      hint: "Search feedback content or user...",
                      prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      border: Border.all(color: AppTheme.divider),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortMode,
                        items: ['Recent', 'Highest Rating', 'Lowest Rating'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              _sortMode = newValue;
                              _applySortAndFilter();
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : _filteredFeedbacks.isEmpty
                ? const Center(child: Text("No feedback found", style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.padding * 2, vertical: AppTheme.padding),
                    itemCount: _filteredFeedbacks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final feedback = _filteredFeedbacks[index];
                      final rating = double.tryParse(feedback['feedback_rating'].toString()) ?? 0.0;
                      final user = feedback['tbl_user'] ?? {};
                      
                      // Highlight negative feedback (<= 2 stars)
                      final isNegative = rating <= 2;
                      
                      return CustomCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isNegative ? AppTheme.error.withOpacity(0.1) : AppTheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isNegative ? AppTheme.error : AppTheme.primary,
                                        ),
                                      ),
                                      Icon(Icons.star, size: 16, color: isNegative ? AppTheme.error : AppTheme.primary),
                                    ],
                                  ),
                                ],
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
                                          user['user_name'] ?? 'Unknown User',
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(feedback['created_at']),
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    feedback['feedback_content'] ?? 'No written feedback provided.',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
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
