import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_item.dart';
import '../models/news_source.dart';

class RssService {
  static final List<NewsSource> sources = [
    NewsSource(name: '新华社', url: 'http://www.news.cn/rss/world.xml', category: '国际'),
    NewsSource(name: '人民日报', url: 'http://www.people.com.cn/rss/politics.xml', category: '国内'),
    NewsSource(name: 'BBC中文', url: 'https://feeds.bbci.co.uk/zhongwen/simp/rss.xml', category: '国际'),
    NewsSource(name: '环球网军事', url: 'https://mil.huanqiu.com/rss/military.xml', category: '军事'),
    NewsSource(name: '36氪', url: 'https://36kr.com/feed', category: '科技'),
    NewsSource(name: '财联社', url: 'https://www.cls.cn/rss', category: '财经'),
  ];

  Future<List<NewsItem>> fetchNews(String category) async {
    List<NewsItem> allNews = [];

    var filteredSources = category == '全部'
        ? sources
        : sources.where((s) => s.category == category).toList();

    for (var source in filteredSources) {
      try {
        final response = await http.get(Uri.parse(source.url))
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final document = XmlDocument.parse(response.body);
          final items = document.findAllElements('item');

          for (var item in items) {
            allNews.add(NewsItem(
              title: item.findElements('title').first.innerText,
              link: item.findElements('link').first.innerText,
              description: _cleanHtml(
                item.findElements('description').isNotEmpty
                    ? item.findElements('description').first.innerText
                    : ''
              ),
              pubDate: _parseDate(
                item.findElements('pubDate').isNotEmpty
                    ? item.findElements('pubDate').first.innerText
                    : null
              ),
              source: source.name,
              category: source.category,
            ));
          }
        }
      } catch (e) {
        print('获取 ${source.name} 失败: $e');
      }
    }

    allNews.sort((a, b) => (b.pubDate ?? DateTime.now())
        .compareTo(a.pubDate ?? DateTime.now()));
    return allNews;
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