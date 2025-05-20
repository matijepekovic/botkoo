// lib/ui/screens/content_analytics_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:botko/core/models/content_type.dart';
import 'package:botko/core/providers/schedule_provider.dart';
import 'package:botko/ui/utils/content_type_helper.dart';

class ContentAnalyticsScreen extends StatefulWidget {
  const ContentAnalyticsScreen({super.key});

  @override
  State<ContentAnalyticsScreen> createState() => _ContentAnalyticsScreenState();
}

class _ContentAnalyticsScreenState extends State<ContentAnalyticsScreen> {
  String _selectedMetric = 'published';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Content Analytics'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Metric selector
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Metric',
                border: OutlineInputBorder(),
              ),
              value: _selectedMetric,
              items: const [
                DropdownMenuItem(value: 'published', child: Text('Published Posts')),
                DropdownMenuItem(value: 'scheduled', child: Text('Scheduled Posts')),
                DropdownMenuItem(value: 'failed', child: Text('Failed Posts')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedMetric = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Content type distribution chart
            Consumer<ScheduleProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Group posts by content type and status
                final Map<ContentType, int> typeDistribution = {};

                for (var post in provider.scheduledPosts) {
                  if (post.status == _selectedMetric) {
                    final content = provider.getContentForPost(post.contentItemId);
                    if (content != null && content.contentType != null) {
                      final type = content.contentType;
                      typeDistribution[type] = (typeDistribution[type] ?? 0) + 1;
                    }
                  }
                }

                if (typeDistribution.isEmpty) {
                  return Center(
                    child: Text(
                      'No $_selectedMetric posts to analyze',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content Type Distribution',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 300,
                      child: PieChart(
                        PieChartData(
                          sections: typeDistribution.entries.map((entry) {
                            return PieChartSectionData(
                              value: entry.value.toDouble(),
                              title: '${entry.value}',
                              color: ContentTypeHelper.getColor(entry.key),
                              radius: 100,
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList(),
                          centerSpaceRadius: 40,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Legend
                    ...typeDistribution.keys.map((type) =>
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                color: ContentTypeHelper.getColor(type),
                              ),
                              const SizedBox(width: 8),
                              Text(type.displayName),
                              const Spacer(),
                              Text('${typeDistribution[type]} posts'),
                            ],
                          ),
                        )
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}