part of stream_transformers;

/// Combines the events from two streams into a single stream. Errors occurring
/// on a source stream will be forwarded to the transformed stream. If the
/// source stream is a broadcast stream, then the transformed stream will also
/// be a broadcast stream.
///
/// **Example:**
///
///   var controller1 = new StreamController();
///   var controller2 = new StreamController();
///
///   var merged = controller1.stream.transform(new Merge(controller2.stream));
///
///   merged.listen(print);
///
///   controller1.add(1); // Prints: 1
///   controller2.add(2); // Prints: 2
///   controller1.add(3); // Prints: 3
///   controller2.add(4); // Prints: 4
class Merge<S, T> implements StreamTransformer {
  /// Returns a stream that contains the events from a list of streams.
  static Stream all(Iterable<Stream> streams) {
    return streams.skip(1).fold(streams.first, (Stream previous, current) {
      return previous.transform(new Merge(current));
    });
  }

  final Stream<T> _other;

  Merge(Stream<T> other) : _other = other;

  Stream bind(Stream<S> stream) {
    StreamSubscription<S> subscriptionA;
    StreamSubscription<T> subscriptionB;
    var completerA = new Completer();
    var completerB = new Completer();
    StreamController controller;

    void onListen() {
      subscriptionA = stream.listen(controller.add, onError: controller.addError, onDone: completerA.complete);
      subscriptionB = _other.listen(controller.add, onError: controller.addError, onDone: completerB.complete);
    }

    void onPause() {
      subscriptionA.pause();
      subscriptionB.pause();
    }

    void onResume() {
      subscriptionA.resume();
      subscriptionB.resume();
    }

    controller = _createControllerLikeStream(stream: stream, onListen: onListen, onPause: onPause, onResume: onResume);

    Future.wait([completerA.future, completerB.future]).then((_) => controller.close());

    return controller.stream;
  }
}