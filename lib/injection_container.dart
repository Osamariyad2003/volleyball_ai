import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'core/network/dio_client.dart';
import 'core/network/sportradar_client.dart';
import 'core/config/app_config.dart';
import 'features/matches/data/repositories/matches_repository.dart';
import 'features/tournaments/data/repositories/competition_repository.dart';
import 'features/teams/data/repositories/competitor_repository.dart';
import 'core/config/secret_loader.dart';

final sl = GetIt.instance;

Future<void> init() async {
  debugPrint('Initializing Injection Container...');
  //! Core - Load Secrets
  try {
    final secret = await SecretLoader().load();
    final apiKey = secret.apiKey;
    debugPrint('Secrets loaded successfully');

    //! Features
    // Repository
    sl.registerLazySingleton(() => CompetitionRepository(sl()));
    sl.registerLazySingleton(() => MatchesRepository(sl()));
    sl.registerLazySingleton(() => CompetitorRepository(sl()));

    //! Core
    sl.registerLazySingleton(
      () => DioClient(sl(), accessLevel: AppConfig.sportradarAccessLevel),
    );
    sl.registerLazySingleton(
      () => SportradarClient(
        dioClient: sl(),
        apiKey: apiKey,
        accessLevel: AppConfig.sportradarAccessLevel,
        locale: AppConfig.defaultLocale,
      ),
    );

    //! External
    sl.registerLazySingleton(() => Dio());
  } catch (e) {
    debugPrint('Error during DI initialization: $e');
  }
}
