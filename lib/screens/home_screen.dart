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
              itemBuilder: (context, index) => NewsCard(item: news[index]),
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
