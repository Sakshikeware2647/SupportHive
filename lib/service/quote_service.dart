import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supporthive1/model/quote.dart';

class QuoteService {
  static const _cachedQuoteKey   = 'daily_quote_text';
  static const _cachedAuthorKey  = 'daily_quote_author';
  static const _cachedDateKey    = 'daily_quote_date';
  static const _seenQuotesKey    = 'seen_quotes';

  // ── Public entry point ───────────────────────────────────────────────────
  /// Returns a fresh daily quote. Caches it for the calendar day so the
  /// same quote persists across hot-reloads / app restarts within the same day.
  static Future<Quote> getDailyQuote() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _todayString();

    // Return cached quote if it's still today's
    if (prefs.getString(_cachedDateKey) == today) {
      final text   = prefs.getString(_cachedQuoteKey)  ?? '';
      final author = prefs.getString(_cachedAuthorKey) ?? '';
      if (text.isNotEmpty) return Quote(text: '"$text"', author: author);
    }

    // Try fetching from ZenQuotes
    try {
      final quote = await _fetchFromZenQuotes(prefs);
      _cacheQuote(prefs, quote, today);
      return quote;
    } catch (_) {
      // Offline fallback — pick from curated list without repeating
      final quote = _pickFallback(prefs);
      _cacheQuote(prefs, quote, today);
      return quote;
    }
  }

  // ── ZenQuotes fetch ──────────────────────────────────────────────────────
  static Future<Quote> _fetchFromZenQuotes(SharedPreferences prefs) async {
    // ZenQuotes /today returns the same quote for the whole UTC day — perfect.
    final response = await http
        .get(Uri.parse('https://zenquotes.io/api/today'))
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) throw Exception('Bad status');

    final List<dynamic> list = jsonDecode(response.body);
    if (list.isEmpty) throw Exception('Empty response');

    final item   = list[0] as Map<String, dynamic>;
    final text   = (item['q'] as String? ?? '').trim();
    final author = (item['a'] as String? ?? '').trim();

    if (text.isEmpty) throw Exception('Empty quote text');

    // Track seen quotes to avoid repeats on fallback
    _markSeen(prefs, text);

    return Quote(text: '"$text"', author: author);
  }

  // ── Seen-quote tracking ──────────────────────────────────────────────────
  static void _markSeen(SharedPreferences prefs, String text) {
    final seen = prefs.getStringList(_seenQuotesKey) ?? [];
    if (!seen.contains(text)) {
      seen.add(text);
      // Keep only the last 60 to avoid unbounded growth
      if (seen.length > 60) seen.removeRange(0, seen.length - 60);
      prefs.setStringList(_seenQuotesKey, seen);
    }
  }

  // ── Cache helpers ────────────────────────────────────────────────────────
  static void _cacheQuote(SharedPreferences prefs, Quote quote, String date) {
    // Strip surrounding quotes before storing so we don't double-wrap
    final raw = quote.text.replaceAll(RegExp(r'^"|"$'), '');
    prefs.setString(_cachedQuoteKey,  raw);
    prefs.setString(_cachedAuthorKey, quote.author);
    prefs.setString(_cachedDateKey,   date);
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  // ── Curated offline fallback (50 unique wellness quotes) ─────────────────
  static Quote _pickFallback(SharedPreferences prefs) {
    final seen = prefs.getStringList(_seenQuotesKey) ?? [];

    final unseen = _fallbackQuotes.where((q) => !seen.contains(q.text.replaceAll(RegExp(r'^"|"$'), ''))).toList();

    // Reset seen list if all have been shown
    final pool = unseen.isNotEmpty ? unseen : _fallbackQuotes;

    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year, 1, 1)).inDays;
    final quote = pool[dayOfYear % pool.length];

    _markSeen(prefs, quote.text.replaceAll(RegExp(r'^"|"$'), ''));
    return quote;
  }

  static final List<Quote> _fallbackQuotes = [
    Quote(text: '"You don\'t have to be positive all the time. It\'s perfectly okay to feel sad, angry, annoyed, or anxious."', author: 'Lori Deschene'),
    Quote(text: '"Mental health is not a destination but a process. It\'s about how you drive, not where you\'re going."', author: 'Noam Shpancer'),
    Quote(text: '"Self-care is not a luxury. It is a necessity."', author: 'Unknown'),
    Quote(text: '"You are allowed to be both a masterpiece and a work in progress simultaneously."', author: 'Sophia Bush'),
    Quote(text: '"Be gentle with yourself. You are a child of the universe, no less than the trees and the stars."', author: 'Max Ehrmann'),
    Quote(text: '"Rest when you\'re weary. Refresh and renew yourself, your body, your mind, your spirit."', author: 'Ralph Marston'),
    Quote(text: '"Healing is not linear."', author: 'Unknown'),
    Quote(text: '"You are enough. A thousand times enough."', author: 'Unknown'),
    Quote(text: '"Sometimes the most important thing in a whole day is the rest we take between two deep breaths."', author: 'Etty Hillesum'),
    Quote(text: '"There is hope, even when your brain tells you there isn\'t."', author: 'John Green'),
    Quote(text: '"Start where you are. Use what you have. Do what you can."', author: 'Arthur Ashe'),
    Quote(text: '"Taking care of yourself doesn\'t mean me first, it means me too."', author: 'L.R. Knost'),
    Quote(text: '"Peace is the result of retraining your mind to process life as it is, rather than as you think it should be."', author: 'Wayne Dyer'),
    Quote(text: '"You have been criticising yourself for years and it hasn\'t worked. Try approving of yourself and see what happens."', author: 'Louise Hay'),
    Quote(text: '"It\'s okay to not be okay — as long as you are not giving up."', author: 'Karen Salmansohn'),
    Quote(text: '"Promise me you\'ll always remember: You\'re braver than you believe, and stronger than you seem."', author: 'A.A. Milne'),
    Quote(text: '"Almost everything will work again if you unplug it for a few minutes, including you."', author: 'Anne Lamott'),
    Quote(text: '"You don\'t have to be great to start, but you have to start to be great."', author: 'Zig Ziglar'),
    Quote(text: '"Happiness is not the absence of problems, it\'s the ability to deal with them."', author: 'Steve Maraboli'),
    Quote(text: '"Your present circumstances don\'t determine where you can go; they merely determine where you start."', author: 'Nido Qubein'),
    Quote(text: '"Even the darkest night will end and the sun will rise."', author: 'Victor Hugo'),
    Quote(text: '"In the middle of every difficulty lies opportunity."', author: 'Albert Einstein'),
    Quote(text: '"Do not let what you cannot do interfere with what you can do."', author: 'John Wooden'),
    Quote(text: '"You must do the thing you think you cannot do."', author: 'Eleanor Roosevelt'),
    Quote(text: '"Fall seven times, stand up eight."', author: 'Japanese Proverb'),
    Quote(text: '"The only way out is through."', author: 'Robert Frost'),
    Quote(text: '"Breathe. It\'s just a bad day, not a bad life."', author: 'Unknown'),
    Quote(text: '"Tough times never last, but tough people do."', author: 'Robert H. Schuller'),
    Quote(text: '"It\'s okay to be a glowstick — sometimes we need to break before we shine."', author: 'Unknown'),
    Quote(text: '"Small steps in the right direction can turn out to be the biggest steps of your life."', author: 'Unknown'),
    Quote(text: '"Believe you can and you\'re halfway there."', author: 'Theodore Roosevelt'),
    Quote(text: '"You\'ve survived 100% of your worst days."', author: 'Unknown'),
    Quote(text: '"Rock bottom became the solid foundation on which I rebuilt my life."', author: 'J.K. Rowling'),
    Quote(text: '"One day or day one. You decide."', author: 'Unknown'),
    Quote(text: '"If you get tired, learn to rest, not to quit."', author: 'Banksy'),
    Quote(text: '"Courage doesn\'t always roar. Sometimes it\'s the quiet voice at the end of the day saying I will try again tomorrow."', author: 'Mary Anne Radmacher'),
    Quote(text: '"You are stronger than you think."', author: 'Unknown'),
    Quote(text: '"Don\'t be pushed around by the fears in your mind. Be led by the dreams in your heart."', author: 'Roy T. Bennett'),
    Quote(text: '"What mental health needs is more sunlight, more candor, and more unashamed conversation."', author: 'Glenn Close'),
    Quote(text: '"Recovery is not one and done. It is a lifelong journey that takes place one day, one step at a time."', author: 'Unknown'),
    Quote(text: '"You are not your illness. You have an individual story to tell. You have a name, a history, a personality."', author: 'Julian Seifter'),
    Quote(text: '"The bravest thing I ever did was continuing my life when I wanted to die."', author: 'Juliette Lewis'),
    Quote(text: '"It\'s not about being happy all the time. It\'s about being real."', author: 'Unknown'),
    Quote(text: '"Nothing is permanent in this wicked world, not even our troubles."', author: 'Charlie Chaplin'),
    Quote(text: '"Happiness can be found even in the darkest of times, if one only remembers to turn on the light."', author: 'Albus Dumbledore'),
    Quote(text: '"Keep going. Everything you need will come to you at the perfect time."', author: 'Unknown'),
    Quote(text: '"You are worthy of the space you take up."', author: 'Unknown'),
    Quote(text: '"Stop a moment, cease your work, look around you."', author: 'Leo Tolstoy'),
    Quote(text: '"The most beautiful people we have known are those who have known defeat, suffering, struggle, loss."', author: 'Elisabeth Kübler-Ross'),
    Quote(text: '"Not all those who wander are lost."', author: 'J.R.R. Tolkien'),
  ];
}