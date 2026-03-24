import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:admin_app/theme.dart';
import 'package:admin_app/widgets/custom_card.dart';

class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;

  // Metrics
  int _totalUsers = 0;
  int _totalListings = 0;
  int _activeListings = 0;
  int _blockedListings = 0;
  int _totalComplaints = 0;
  int _pendingComplaints = 0;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      // Note: Using estimated generic count queries based on the project structure
      
      // Total Users
      final usersRes = await supabase.from('tbl_user').select('id');
      _totalUsers = usersRes.length;

      // Listings
      final listingsRes = await supabase.from('tbl_product').select('id, product_status');
      _totalListings = listingsRes.length;
      _activeListings = listingsRes.where((p) => p['product_status'] == 1 || p['product_status'] == 'Active').length;
      _blockedListings = _totalListings - _activeListings;

      // Complaints
      final compRes = await supabase.from('tbl_complaint').select('id, complaint_status');
      _totalComplaints = compRes.length;
      _pendingComplaints = compRes.where((c) => c['complaint_status'] == 0 || c['complaint_status'] == 'Pending').length;

    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.padding * 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Overview",
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 24),
          
          // Metrics Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth < 600 ? 2 : (constraints.maxWidth < 900 ? 3 : 4);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _MetricCard(title: "Total Users", value: _totalUsers.toString(), icon: Icons.people_outline, color: Colors.blue),
                  _MetricCard(title: "Total Listings", value: _totalListings.toString(), icon: Icons.shopping_bag_outlined, color: Colors.indigo),
                  _MetricCard(title: "Active Listings", value: _activeListings.toString(), icon: Icons.check_circle_outline, color: AppTheme.success),
                  _MetricCard(title: "Blocked Listings", value: _blockedListings.toString(), icon: Icons.block, color: AppTheme.error),
                  _MetricCard(title: "Total Complaints", value: _totalComplaints.toString(), icon: Icons.warning_amber_rounded, color: Colors.orange),
                  _MetricCard(title: "Pending Complaints", value: _pendingComplaints.toString(), icon: Icons.hourglass_empty, color: AppTheme.warning),
                ],
              );
            }
          ),

          const SizedBox(height: 32),
          
          // Charts Section
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 800;
              return isDesktop 
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _UserGrowthChart()),
                        const SizedBox(width: 24),
                        Expanded(flex: 1, child: _ComplaintStatusChart(total: _totalComplaints, pending: _pendingComplaints)),
                      ],
                    )
                  : Column(
                      children: [
                        _UserGrowthChart(),
                        const SizedBox(height: 24),
                        _ComplaintStatusChart(total: _totalComplaints, pending: _pendingComplaints),
                      ],
                    );
            } // end builder
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserGrowthChart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "User Growth (Last 6 Months)",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(color: AppTheme.divider, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                        if (value.toInt() >= 0 && value.toInt() < months.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(months[value.toInt()], style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 3),
                      FlSpot(1, 4.5),
                      FlSpot(2, 4),
                      FlSpot(3, 6),
                      FlSpot(4, 5.5),
                      FlSpot(5, 8),
                    ],
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintStatusChart extends StatelessWidget {
  final int total;
  final int pending;

  const _ComplaintStatusChart({required this.total, required this.pending});

  @override
  Widget build(BuildContext context) {
    final resolved = total - pending;
    
    return CustomCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Complaints Status",
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 250,
            child: total == 0 
              ? const Center(child: Text("No data available"))
              : PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(
                        color: AppTheme.success,
                        value: resolved > 0 ? resolved.toDouble() : 1,
                        title: '${resolved > 0 ? ((resolved/total)*100).round() : 0}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      PieChartSectionData(
                        color: AppTheme.warning,
                        value: pending > 0 ? pending.toDouble() : 1,
                        title: '${pending > 0 ? ((pending/total)*100).round() : 0}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Legend(color: AppTheme.success, text: "Resolved"),
              const SizedBox(width: 16),
              _Legend(color: AppTheme.warning, text: "Pending"),
            ],
          )
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String text;

  const _Legend({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }
}
