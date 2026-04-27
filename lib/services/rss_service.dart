import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_item.dart';
import '../models/news_source.dart';

class RssService {
  static final List<NewsSource> sources = [
    // 国内
    NewsSource(name: '人民日报', url: 'http://www.people.com.cn/rss/politics.xml', category: '国内'),
    NewsSource(name: '国内资讯', url: 'https://news.google.com/rss/search?q=%E4%B8%AD%E5%9B%BD%E5%9B%BD%E5%86%85%E6%96%B0%E9%97%BB&hl=zh-CN&gl=CN&ceid=CN:zh-Hans', category: '国内'),
    // 国际
    NewsSource(name: 'BBC中文', url: 'https://feeds.bbci.co.uk/zhongwen/simp/rss.xml', category: '国际'),
    NewsSource(name: '国际资讯', url: 'https://news.google.com/rss/search?q=%E5%9B%BD%E9%99%85%E6%96%B0%E9%97%BB&hl=zh-CN&gl=CN&ceid=CN:zh-Hans', category: '国际'),
    // 军事
    NewsSource(name: '军事资讯', url: 'https://news.google.com/rss/search?q=%E5%86%9B%E4%BA%8B&hl=zh-CN&gl=CN&ceid=CN:zh-Hans', category: '军事'),
    // 科技
    NewsSource(name: 'IT之家', url: 'https://www.ithome.com/rss/', category: '科技'),
    NewsSource(name: '少数派', url: 'https://sspai.com/feed', category: '科技'),
    NewsSource(name: '科技资讯', url: 'https://news.google.com/rss/search?q=%E7%A7%91%E6%8A%80%E6%96%B0%E9%97%BB&hl=zh-CN&gl=CN&ceid=CN:zh-Hans', category: '科技'),
    // 财经
    NewsSource(name: '财经资讯', url: 'https://news.google.com/rss/search?q=%E8%B4%A2%E7%BB%8F&hl=zh-CN&gl=CN&ceid=CN:zh-Hans', category: '财经'),
    NewsSource(name: '股市财经', url: 'https://news.google.com/rss/search?q=%E8%82%A1%E5%B8%82%E8%B4%A2%E7%BB%8F&hl=zh-CN&gl=CN&ceid=CN:zh-Hans', category: '财经'),
  ];

  Future<List<NewsItem>> fetchNews(String category) async {
    final filteredSources = category == '全部'
        ? sources
        : sources.where((s) => s.category == category).toList();

    final results = await Future.wait(
      filteredSources.map(_fetchFromSource),
    );

    final allNews = results.expand((items) => items).toList();
    allNews.sort((a, b) => (b.pubDate ?? DateTime.now())
        .compareTo(a.pubDate ?? DateTime.now()));
    return allNews;
  }

  Future<List<NewsItem>> _fetchFromSource(NewsSource source) async {
    try {
      final response = await http.get(Uri.parse(source.url))
          .timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];

      final body = utf8.decode(response.bodyBytes, allowMalformed: true);
      final document = XmlDocument.parse(body);
      final items = document.findAllElements('item');

      return items.map((item) {
        return NewsItem(
          title: item.findElements('title').isNotEmpty
              ? item.findElements('title').first.innerText
              : '无标题',
          link: item.findElements('link').isNotEmpty
              ? item.findElements('link').first.innerText
              : '',
          description: _cleanHtml(
            item.findElements('description').isNotEmpty
                ? item.findElements('description').first.innerText
                : '',
          ),
          pubDate: _parseDate(
            item.findElements('pubDate').isNotEmpty
                ? item.findElements('pubDate').first.innerText
                : null,
          ),
          source: source.name,
          category: source.category,
        );
      }).where((item) => item.link.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .trim();
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      return null;
    }
  }
}