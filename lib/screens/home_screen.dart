import 'package:flutter/material.dart';
import '../models/news_item.dart';
import '../services/rss_service.dart';
import '../widgets/news_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final RssService _rssService = RssService();
  final List<String> _categories = ['全部', '国内', '国际', '军事', '科技', '财经'];
  final Map<String, List<NewsItem>> _newsCache = {};
  final Map<String, bool> _loadingState = {};
  String _sortMode = '最新';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadNews(_categories[_tabController.index]);
      }
    });
    _loadNews('全部');
  }

  Future<void> _loadNews(String category) async {
    if (_loadingState[category] == true) return;
    setState(() => _loadingState[category] = true);
    try {
      final news = await _rssService.fetchNews(category);
      setState(() {
        _newsCache[category] = news;
        _loadingState[category] = false;
      });
    } catch (e) {
      setState(() => _loadingState[category] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('新闻速递', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          // 排序切换
          GestureDetector(
            onTap: () {
              setState(() {
                _sortMode = _sortMode == '最新' ? '最热' : '最新';
              });
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    _sortMode == '最新' ? Icons.access_time : Icons.local_fire_department,
                    size: 14, color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(_sortMode, style: const TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final cat = _categories[_tabController.index];
              _newsCache.remove(cat);
              _loadNews(cat);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: _categories.map((c) => Tab(text: c)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          final isLoading = _loadingState[category] == true;
          final news = _newsCache[category] ?? [];

          if (isLoading && news.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (news.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.newspaper, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('暂无新闻，点击刷新', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _loadNews(category),
                    child: const Text('刷新'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _newsCache.remove(category);
              await _loadNews(category);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: news.length,
              itemBuilder: (context, index) {
                final sorted = _sortedNews(news);
                return NewsCard(item: sorted[index]);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  List<NewsItem> _sortedNews(List<NewsItem> news) {
    final sorted = List<NewsItem>.from(news);
    if (_sortMode == '最新') {
      sorted.sort((a, b) => (b.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0))
          .compareTo(a.pubDate ?? DateTime.fromMillisecondsSinceEpoch(0)));
      return sorted;
    }

    int hotScore(NewsItem item) {
      final recency = item.pubDate == null
          ? 0
          : (72 - DateTime.now().difference(item.pubDate!).inHours).clamp(0, 72) as int;
      final sourceBoost = item.source.contains('BBC') || item.source.contains('人民日报') ? 15 : 5;
      final titleBoost = item.title.length > 28 ? 8 : 3;
      return recency + sourceBoost + titleBoost;
    }

    sorted.sort((a, b) => hotScore(b).compareTo(hotScore(a)));
    return sorted;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
