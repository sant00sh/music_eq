import 'package:dartz/dartz.dart';
import 'package:music_eq/core/error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

class NoParams {}
