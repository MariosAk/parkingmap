import 'package:get_it/get_it.dart';
import 'package:parkingmap/services/init_service.dart';
import 'package:parkingmap/services/parking_service.dart';
import 'package:parkingmap/services/auth_service.dart';
import 'package:parkingmap/services/points_service.dart';
import 'package:parkingmap/services/sqlite_service.dart';
import 'package:parkingmap/services/user_service.dart';

final getIt = GetIt.instance;

void setupLocator() {
  getIt.registerSingleton(AuthService());
  getIt.registerSingleton(ParkingService());
  getIt.registerSingleton(PointsService());
  getIt.registerSingleton(UserService());
  getIt.registerLazySingleton(() => SqliteService());
  getIt.registerSingleton(InitService());
}
