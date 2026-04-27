import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_item.dart';
import '../models/news_source.dart';

class RssService {
  static final List<NewsSource> sources = [
    // 国内
    NewsSource(name: '人民日报-政治', url: 'http://www.people.com.cn/rss/politics.xml', category: '国内'),
    NewsSource(name: '人民日报-社会', url: 'http://www.people.com.cn/rss/society.xml', category: '国内'),
    // 国际
    NewsSource(name: 'BBC中文', url: 'https://feeds.bbci.co.uk/zhongwen/simp/rss.xml', category: '国际'),
    NewsSource(name: '人民日报-国际', url: 'http://www.people.com.cn/rss/world.xml', category: '国际'),
    // 军事
    NewsSource(name: '人民日报-军事', url: 'http://www.people.com.cn/rss/military.xml', category: '军事'),
    // 科技
    NewsSource(name: 'IT之家', url: 'https://www.ithome.com/rss/', category: '科技'),
    NewsSource(name: '少数派', url: 'https://sspai.com/feed', category: '科技'),
    NewsSource(name: '人民日报-科技', url: 'http://www.people.com.cn/rss/it.xml', category: '科技'),
    // 财经
    NewsSource(name: '人民日报-财经', url: 'http://www.people.com.cn/rss/finance.xml', category: '财经'),
    // 吃瓜
    NewsSource(name: '人民日报-娱乐', url: 'http://www.people.com.cn/rss/ent.xml', category: '吃瓜'),
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