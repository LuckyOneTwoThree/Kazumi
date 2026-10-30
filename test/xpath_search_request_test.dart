import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/plugins/anti_crawler_config.dart';
import 'package:kazumi/plugins/api_rule_config.dart';
import 'package:kazumi/services/plugin/rule_engine_models.dart';
import 'package:kazumi/services/plugin/xpath_rule_strategy.dart';

void main() {
  const strategy = XPathRuleStrategy();

  test('POST search moves the query fields into the form body', () {
    final request = strategy.prepareSearchRequest(
      _config(
        usePost: true,
        searchUrl: 'https://example.com/vodsearch?do=search&keyword=@keyword',
      ),
      '进击的巨人',
    );

    expect(request.method, 'POST');
    expect(request.bodyType, 'form');
    expect(request.url, 'https://example.com/vodsearch');
    expect(Uri.parse(request.url).hasQuery, isFalse);
    expect(request.body, {'do': 'search', 'keyword': '进击的巨人'});
  });

  test('POST search decodes reserved characters exactly once', () {
    final request = strategy.prepareSearchRequest(
      _config(
        usePost: true,
        searchUrl: 'https://example.com/search?keyword=@keyword',
      ),
      'a&b c',
    );

    expect(request.url, 'https://example.com/search');
    expect(request.body, {'keyword': 'a&b c'});
  });

  test('GET search keeps the full query in the URL', () {
    final request = strategy.prepareSearchRequest(
      _config(
        usePost: false,
        searchUrl: 'https://example.com/vodsearch?do=search&keyword=@keyword',
      ),
      '进击的巨人',
    );

    expect(request.method, 'GET');
    expect(request.bodyType, ApiBodyType.none);
    expect(request.body, isNull);
    expect(
      request.url,
      'https://example.com/vodsearch?do=search&keyword=%E8%BF%9B%E5%87'
      '%BB%E7%9A%84%E5%B7%A8%E4%BA%BA',
    );
  });

  test('POST search keeps an explicit port and path', () {
    final request = strategy.prepareSearchRequest(
      _config(
        usePost: true,
        searchUrl: 'http://example.com:8080/index.php/search?wd=@keyword',
      ),
      'alpha',
    );

    expect(request.url, 'http://example.com:8080/index.php/search');
    expect(request.body, {'wd': 'alpha'});
  });

  test('POST search without a query string still posts', () {
    final request = strategy.prepareSearchRequest(
      _config(usePost: true, searchUrl: 'https://example.com/search'),
      'alpha',
    );

    expect(request.method, 'POST');
    expect(request.url, 'https://example.com/search');
    expect(request.body, isEmpty);
  });
}

RuleExecutionConfig _config({
  required bool usePost,
  required String searchUrl,
}) {
  return RuleExecutionConfig(
    pluginName: 'post-search-test',
    baseUrl: 'https://example.com/',
    usePost: usePost,
    searchMode: RuleMode.xpath,
    chapterMode: RuleMode.xpath,
    searchUrl: searchUrl,
    searchList: '//article[@class="result"]',
    searchName: '//h2/a',
    searchResult: '//h2/a',
    chapterRoads: '//div[@class="road"]',
    chapterResult: '//a',
    searchApiConfig: ApiSearchConfig(
      request: ApiRequestConfig(
        url: 'https://example.com/api/search',
        query: {'q': '@keyword'},
      ),
      listPath: r'$.data[*]',
      namePath: r'$.name',
      sourcePath: r'$.id',
    ),
    chapterApiConfig: ApiChapterConfig(
      request: ApiRequestConfig(url: 'https://example.com/api/videos/@source'),
      roadsPath: r'$.data.roads[*]',
      roadNamePath: r'$.name',
      episodesPath: r'$.episodes[*]',
      episodeNamePath: r'$.name',
      episodeUrlPath: r'$.url',
    ),
    antiCrawlerConfig: AntiCrawlerConfig.empty(),
  );
}
