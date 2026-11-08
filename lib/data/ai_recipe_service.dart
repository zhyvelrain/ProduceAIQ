import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:math' show Random;
import 'package:flutter/foundation.dart' show kDebugMode, debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http show Client, ClientException, Request, Response;
import 'ai_recipe.dart';
import 'produce_item.dart';
import '../ml/freshness_assessor.dart';

/// Debug-only logging: prints nothing in release APKs.
void _log(String message) {
  if (kDebugMode) debugPrint(message);
}

/// Calls the Google Apps Script proxy (see AppsScript_Code.gs) which
/// holds the Gemini API key server-side, on Google's free
/// infrastructure -- no Firebase Blaze plan, no billing account
/// needed.
///
/// IMPORTANT: never call the Gemini API directly from this app with an
/// embedded key. admin_panel_index.html does that, but that file is a
/// local, admin-only HTML page you run yourself -- this app ships as
/// a compiled APK that can be decompiled, trivially exposing any
/// hardcoded key to every user who installs it. This proxy is the one
/// and only thing in this app's chain that is allowed to know the
/// key, and it never sends it to the phone.
class AiRecipeService {
  // Secrets are NOT hardcoded here. They are read at runtime from
  // assets/secrets/secrets.json, which is gitignored; see
  // assets/secrets/secrets.example.json for the expected shape.
  //
  // Note: any value shipped in a mobile app is still extractable from the
  // APK. Keeping it out of source control stops it leaking through the
  // repository and lets each build use a different key -- it is not a
  // substitute for server-side enforcement.
  static const String _configAsset = 'assets/secrets/secrets.json';

  // Kept separate from _endpointUrl so the "did you forget to paste
  // your URL" check below compares against the ORIGINAL placeholder
  // text, not against itself.
  static const String _placeholderUrl = 'PASTE_YOUR_APPS_SCRIPT_URL_HERE';

  /// Deployed Apps Script Web App URL.
  String _endpointUrl = _placeholderUrl;

  /// Shared secret -- must match the APP_SECRET script property in
  /// Apps Script exactly. Stops casual abuse of the proxy (and your
  /// Gemini/Groq quota) by anyone who only has the URL.
  String _appSecret = '';

  bool _configLoaded = false;

  /// Loads the gitignored secrets file once, before the first network call.
  /// A missing/invalid file is non-fatal: the app simply falls back to the
  /// curated local recipes, exactly as it does when the proxy is unreachable.
  Future<void> _ensureConfigLoaded() async {
    if (_configLoaded) return;
    _configLoaded = true;
    try {
      final raw = await rootBundle.loadString(_configAsset);
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final url = (map['appsScriptUrl'] as String?)?.trim() ?? '';
      _endpointUrl =
          (url.isEmpty || url == _placeholderUrl) ? _placeholderUrl : url;
      _appSecret = (map['appSecret'] as String?)?.trim() ?? '';
    } catch (e) {
      _log('[AiRecipeService] could not load $_configAsset: $e');
    }
  }

  // Timeout per attempt (connect + read). Shorter than before because
  // we now retry on transient failures.
  static const Duration _timeout = Duration(seconds: 15);

  // The Groq fallback goes phone -> Apps Script -> Groq (one extra hop), so
  // give it more headroom than a direct call.
  static const Duration _fallbackTimeout = Duration(seconds: 30);

  // Retry config
  static const int _maxRetries = 2;
  static const Duration _baseDelay = Duration(seconds: 2);
  static const Duration _maxDelay = Duration(seconds: 10);

  /// Returns null on ANY failure -- no network, timeout, Apps Script
  /// not deployed yet, malformed Gemini response, wrong recipe count,
  /// unauthorized, etc. -- rather than throwing. This lets RecipeScreen
  /// fall back to ProduceItem's curated recipes/overripeRecipes list
  /// unconditionally, with no special-case error handling needed at the
  /// call site.
  ///
  /// On success, always returns exactly 3 complete recipes -- the Apps
  /// Script proxy validates this server-side (see AppsScript_Code.gs's
  /// validateRecipes) and returns an `error` instead of a
  /// partial/incomplete batch.
  ///
  /// [excludeRecipeNames] lets the caller pass in names of AI recipes
  /// already shown in a previous call this session (e.g. from earlier
  /// Retry taps), so Gemini has a reason to avoid resurfacing the same
  /// dish again.
  Future<List<AiRecipe>?> generate({
    required ProduceItem item,
    required FreshnessGrade? freshnessGrade,
    List<String> excludeRecipeNames = const [],
  }) async {
    await _ensureConfigLoaded();

    final primary = await _generatePrimary(
      item: item,
      freshnessGrade: freshnessGrade,
      excludeRecipeNames: excludeRecipeNames,
    );
    if (primary != null) return primary;

    // Fall back on ANY failure to produce usable recipes -- not just a thrown
    // exception. Previously a non-200 status, an empty "recipes" list, or an
    // incomplete batch returned null to the UI without ever trying Groq.
    _log(
      '[AiRecipeService] primary returned no usable recipes -- '
      'attempting Groq fallback...',
    );
    return _tryGroqFallback(
      item: item,
      freshnessGrade: freshnessGrade,
      excludeRecipeNames: excludeRecipeNames,
    );
  }

  /// First-choice backend (Gemini through the Apps Script proxy).
  ///
  /// Returns null on ANY failure: bad status, an error payload, an empty or
  /// incomplete recipe batch, or exhausted retries. Deciding whether to fall
  /// back is `generate`'s job, so this method never calls Groq itself.
  Future<List<AiRecipe>?> _generatePrimary({
    required ProduceItem item,
    required FreshnessGrade? freshnessGrade,
    List<String> excludeRecipeNames = const [],
  }) async {
    if (_endpointUrl == _placeholderUrl) {
      _log(
        '[AiRecipeService] _endpointUrl is still the placeholder -- '
        'paste your deployed Apps Script URL in ai_recipe_service.dart.',
      );
      return null;
    }

    var attempt = 0;
    while (true) {
      try {
        final client = http.Client();
        http.Response response;
        try {
          // Both the initial send AND the full response-body read are
          // wrapped in ONE timeout below, so a hung body stream can't
          // hang the whole call forever.
          response = await (() async {
            final request = http.Request('POST', Uri.parse(_endpointUrl))
              ..headers['Content-Type'] = 'application/json'
              ..body = jsonEncode({
                'appSecret': _appSecret,
                'commonName': item.commonName,
                'scientificName': item.scientificName,
                'freshnessLabel': freshnessGrade?.label,
                'curatedRecipes': [
                  ...item.recipes,
                  ...item.overripeRecipes,
                  // Recipes already shown to this user in a previous
                  // Retry within this session.
                  ...excludeRecipeNames,
                ],
              });

            _log('[AiRecipeService] sending request (attempt ${attempt + 1})...');
            final streamed = await client.send(request);
            _log('[AiRecipeService] status ${streamed.statusCode}');

            // dart:io's HTTP client only auto-follows redirects for GET
            // and HEAD -- NEVER for POST. Apps Script's /exec URL always
            // responds with a 302 pointing at a temporary content URL that
            // must be fetched with a plain GET, so we follow it manually.
            if (streamed.statusCode == 301 ||
                streamed.statusCode == 302 ||
                streamed.statusCode == 303) {
              final location = streamed.headers['location'];
              if (location == null) {
                throw StateError(
                  'Got a ${streamed.statusCode} redirect with no Location header.',
                );
              }
              _log('[AiRecipeService] following redirect');
              return client.get(Uri.parse(location));
            }

            return http.Response.fromStream(streamed);
          })().timeout(_timeout);
        } finally {
          client.close();
        }

        _log('[AiRecipeService] HTTP ${response.statusCode}');

        // Retry on transient HTTP errors
        if (_isTransientError(response.statusCode)) {
          if (attempt < _maxRetries) {
            await _delayWithJitter(attempt);
            attempt++;
            continue;
          }
          return null;
        }

        if (response.statusCode != 200) {
          return null;
        }

        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        if (decoded.containsKey('error')) {
          final error = decoded['error'] as String;
          _log('[AiRecipeService] proxy returned an error: $error');
          
          // Retry on transient proxy errors
          if (_isTransientProxyError(error)) {
            if (attempt < _maxRetries) {
              await _delayWithJitter(attempt);
              attempt++;
              continue;
            }
          }
          return null;
        }

        // Proxy returns {"recipes": [ {...}, {...}, {...} ]}.
        final rawRecipes = decoded['recipes'] as List<dynamic>?;
        if (rawRecipes == null || rawRecipes.isEmpty) {
          _log('[AiRecipeService] proxy response had no "recipes" list.');
          return null;
        }

        final recipes = rawRecipes
            .map((r) => AiRecipe.fromMap(r as Map<String, dynamic>))
            .toList();

        // Extra client-side guard on top of the server-side validation --
        // treat the whole batch as unusable if any recipe has no steps or
        // ingredients.
        final allComplete = recipes.every(
          (r) => r.steps.isNotEmpty && r.ingredients.isNotEmpty,
        );
        if (!allComplete) {
          _log(
            '[AiRecipeService] one or more recipes were incomplete '
            '(missing steps/ingredients) -- discarding batch.',
          );
          return null;
        }

        return recipes;
              } catch (e) {
                _log('[AiRecipeService] generate() failed: $e');

                // Retry on transient exceptions (timeout, network, etc.)
                if (_isTransientException(e) && attempt < _maxRetries) {
                  await _delayWithJitter(attempt);
                  attempt++;
                  continue;
                }
                // Retries exhausted or non-retryable: let generate() decide
                // whether to fall back to Groq.
                return null;
              }
            }
          }

  /// Groq fallback -- goes through the SAME Apps Script proxy as Gemini, so
  /// the Groq key lives only on the server and never ships in the APK.
  ///
  /// The proxy is expected to answer `{"recipes": [...]}` (same shape as the
  /// primary) or `{"error": "..."}`. Returns null on any failure; the caller
  /// then shows the curated local recipes.
  Future<List<AiRecipe>?> _tryGroqFallback({
    required ProduceItem item,
    required FreshnessGrade? freshnessGrade,
    List<String> excludeRecipeNames = const [],
  }) async {
    if (_endpointUrl == _placeholderUrl || _appSecret.isEmpty) {
      _log(
        '[AiRecipeService] proxy not configured -- Groq fallback unavailable',
      );
      return null;
    }

    _log('[AiRecipeService] trying Groq fallback via Apps Script proxy...');

    try {
      final response = await _postToProxy({
        'action': 'groqFallback',
        'appSecret': _appSecret,
        'commonName': item.commonName,
        'scientificName': item.scientificName,
        'freshnessLabel': freshnessGrade?.label,
        'curatedRecipes': [
          ...item.recipes,
          ...item.overripeRecipes,
          ...excludeRecipeNames,
        ],
        'excludeRecipeNames': excludeRecipeNames,
      }).timeout(_fallbackTimeout);

      if (response.statusCode != 200) {
        _log('[AiRecipeService] Groq proxy HTTP ${response.statusCode}');
        return null;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      if (decoded.containsKey('error')) {
        _log('[AiRecipeService] Groq proxy error: ${decoded['error']}');
        return null;
      }

      final rawRecipes = decoded['recipes'] as List<dynamic>?;
      if (rawRecipes == null || rawRecipes.length < 3) {
        _log('[AiRecipeService] Groq proxy returned insufficient recipes');
        return null;
      }

      final recipes = rawRecipes
          .take(3)
          .map((r) => AiRecipe.fromMap(r as Map<String, dynamic>))
          .toList();

      final allComplete = recipes.every(
        (r) => r.steps.isNotEmpty && r.ingredients.isNotEmpty,
      );
      if (!allComplete) {
        _log('[AiRecipeService] Groq recipes incomplete');
        return null;
      }

      _log(
        '[AiRecipeService] Groq fallback succeeded with '
        '${recipes.length} recipes',
      );
      return recipes;
    } catch (e) {
      _log('[AiRecipeService] Groq fallback failed: $e');
      return null;
    }
  }

  /// POSTs JSON to the Apps Script endpoint, following the POST->GET redirect
  /// that Apps Script's /exec URL always returns (dart:io only auto-follows
  /// redirects for GET and HEAD).
  Future<http.Response> _postToProxy(Map<String, dynamic> body) async {
    final client = http.Client();
    try {
      final request = http.Request('POST', Uri.parse(_endpointUrl))
        ..headers['Content-Type'] = 'application/json'
        ..body = jsonEncode(body);

      final streamed = await client.send(request);
      if (streamed.statusCode == 301 ||
          streamed.statusCode == 302 ||
          streamed.statusCode == 303) {
        final location = streamed.headers['location'];
        if (location == null) {
          throw StateError(
            'Got a ${streamed.statusCode} redirect with no Location header.',
          );
        }
        return await client.get(Uri.parse(location));
      }
      return await http.Response.fromStream(streamed);
    } finally {
      client.close();
    }
  }

  /// Exponential backoff with jitter: baseDelay * 2^attempt + random(0-500ms)
  /// Capped at maxDelay.
  Future<void> _delayWithJitter(int attempt) async {
    final baseMs = _baseDelay.inMilliseconds * (1 << attempt);
    final cappedMs = baseMs.clamp(0, _maxDelay.inMilliseconds);
    final jitter = Random().nextInt(500);
    final delayMs = cappedMs + jitter;
    _log('[AiRecipeService] retrying in ${delayMs}ms...');
    await Future.delayed(Duration(milliseconds: delayMs));
  }

  /// HTTP status codes that are worth retrying.
  bool _isTransientError(int statusCode) =>
      statusCode == 429 || statusCode >= 500;

  /// Proxy error messages that indicate transient failures.
  bool _isTransientProxyError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('timeout') ||
           lower.contains('rate limit') ||
           lower.contains('quota') ||
           lower.contains('unavailable') ||
           lower.contains('internal') ||
           lower.contains('overloaded') ||
           lower.contains('temporary');
  }

  /// Exception types that are worth retrying.
  bool _isTransientException(Object e) {
    return e is TimeoutException ||
           e is http.ClientException ||
           e is SocketException ||
           e is FormatException; // malformed JSON from proxy during partial failure
  }
}

final aiRecipeService = AiRecipeService();