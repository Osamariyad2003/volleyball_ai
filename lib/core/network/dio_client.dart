import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioClient {
  final Dio dio;
  final String accessLevel;

  DioClient(this.dio, {this.accessLevel = 'trial'}) {
    dio
      ..options.baseUrl =
          'https://api.sportradar.com/volleyball/$accessLevel/v2'
      ..options.connectTimeout = const Duration(seconds: 10)
      ..options.receiveTimeout = const Duration(seconds: 10)
      ..interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
  }

  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    const retryDelays = <Duration>[
      Duration(milliseconds: 700),
      Duration(milliseconds: 1500),
    ];

    for (var attempt = 0; attempt <= retryDelays.length; attempt++) {
      try {
        final Response response = await dio.get(
          url,
          queryParameters: queryParameters,
          options: options,
          cancelToken: cancelToken,
          onReceiveProgress: onReceiveProgress,
        );
        return response;
      } on DioException catch (error) {
        final isRateLimited = error.response?.statusCode == 429;
        if (!isRateLimited || attempt >= retryDelays.length) {
          rethrow;
        }

        await Future<void>.delayed(retryDelays[attempt]);
      }
    }

    throw StateError('Request failed unexpectedly.');
  }
}
