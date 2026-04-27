import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_item.dart';
import '../models/news_source.dart';

class RssService {
  static final List<NewsSource> sources = [
    // 国内
    NewsSource(name: '中国日报', url: 'https://www.chinadaily.com.cn/rss/china_rss.xml', category: '国内'),
    // 国际
    NewsSource(name: 'BBC中文', url: 'https://feeds.bbci.co.uk/zhongwen/simp/rss.xml', category: '国际'),
    NewsSource(name: '德国之声', url: 'https://feedx.net/rss/dw.xml', category: '国际'),
    NewsSource(name: 'RFI法广', url: 'https://feedx.net/rss/rfi.xml', category: '国际'),
    NewsSource(name: '环球时报', url: 'https://www.globaltimes.cn/rss/outbrain.xml', category: '国际'),
    // 军事
    NewsSource(name: 'BBC中文', url: 'https://feeds.bbci.co.uk/zhongwen/simp/rss.xml', category: '军事'),
    // 科技
    NewsSource(name: 'IT之家', url: 'https://www.ithome.com/rss/', category: '科技'),
    NewsSource(name: '少数派', url: 'https://sspai.com/feed', category: '科技'),
    NewsSource(name: 'Solidot', url: 'http://feeds.feedburner.com/solidot', category: '科技'),
    // 财经
    NewsSource(name: '中国日报财经', url: 'https://www.chinadaily.com.cn/rss/bizchina_rss.xml', category: '财经'),
    // 吃瓜
    NewsSource(name: '中国日报娱乐', url: 'https://www.chinadaily.com.cn/rss/entertainment_rss.xml', category: '吃瓜'),
    NewsSource(name: '豆瓣新片', url: 'https://www.douban.com/feed/review/movie', category: '吃瓜'),
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
      }).where((item) {
        if (item.link.isEmpty) return false;
        if (item.pubDate == null) return true;
        final age = DateTime.now().difference(item.pubDate!).inDays;
        return age <= 90;
      }).toList();
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
    } catch (_) {}
    try {
      // RFC 822: Mon, 27 Apr 2026 04:14:30 GMT
      final months = {'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,
                      'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12};
      final parts = dateStr.trim().split(RegExp(r'[\s,]+'));
      if (parts.length >= 5) {
        final day = int.parse(parts[1]);
        final month = months[parts[2]] ?? 1;
        final year = int.parse(parts[3]);
        final time = parts[4].split(':');
        return DateTime.utc(year, month, day,
            int.parse(time[0]), int.parse(time[1]));
      }
    } catch (_) {}
    return null;
  }
}