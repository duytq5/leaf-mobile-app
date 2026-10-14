import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One canned answer of [FakeHttpAdapter].
class FakeResponse {
  const FakeResponse(this.status, this.body, {this.headers = const {}});

  factory FakeResponse.json(int status, Object body) => FakeResponse(
    status,
    utf8.encode(jsonEncode(body)),
    headers: const {
      'content-type': ['application/json'],
    },
  );

  final int status;
  final List<int> body;
  final Map<String, List<String>> headers;
}

/// Answers each request from a map of `METHOD url` to a response, and records
/// every request it sees. A request with no entry fails as a lost connection.
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.routes);

  final Map<String, FakeResponse> routes;
  final List<RequestOptions> requests = [];
  final List<List<int>> bodies = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final sent = <int>[];
    if (requestStream != null) {
      await for (final chunk in requestStream) {
        sent.addAll(chunk);
      }
    }
    bodies.add(sent);

    final answer = routes['${options.method} ${options.uri}'];
    if (answer == null) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'no route for ${options.method} ${options.uri}',
      );
    }
    return ResponseBody.fromBytes(
      answer.body,
      answer.status,
      headers: answer.headers,
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A [Dio] that sends every request to [adapter].
Dio fakeDio(FakeHttpAdapter adapter, {String baseUrl = 'https://api.test'}) =>
    Dio(BaseOptions(baseUrl: baseUrl))..httpClientAdapter = adapter;
