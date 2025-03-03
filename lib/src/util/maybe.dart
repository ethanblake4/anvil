import 'package:anvil/src/util/either.dart';

abstract class Maybe<A> {
  const Maybe();

  A get value;

  R when<R>(R Function() isNothing, R Function(A value) isValue);

  bool get isValue;

  bool get isNothing => !isValue;
}

class Just<A> extends Maybe<A> {
  const Just(this.value);

  @override
  final A value;

  @override
  R when<R>(R Function() isNothing, R Function(A value) isValue) {
    return isValue(value);
  }

  @override
  bool get isValue => true;
}

class Nothing<A> extends Maybe<A> {
  const Nothing();

  @override
  A get value {
    throw ForbiddenAccessError('Cannot access [value] for Nothing instance.');
  }

  @override
  R when<R>(R Function() isNothing, R Function(A value) isValue) {
    return isNothing();
  }

  @override
  bool get isValue => false;
}
