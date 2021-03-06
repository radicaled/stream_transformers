library scan_test;

import 'dart:async';
import 'package:guinness/guinness.dart';
import 'package:stream_transformers/stream_transformers.dart';
import 'package:unittest/unittest.dart' show expectAsync;
import 'util.dart';

void main() => describe("Scan", () {
  describe("with single subscription stream", () {
    testWithStreamController(() => new StreamController());
  });

  describe("with broadcast stream", () {
    testWithStreamController(() => new StreamController.broadcast());
  });
});

void testWithStreamController(StreamController provider()) {
  StreamController controller;

  beforeEach(() {
    controller = provider();
  });

  afterEach(() {
    controller.close();
  });

  it("calls combine for each event", () {
    return testStream(controller.stream.transform(new Scan(0, (a, b) => a + b)),
        behavior: () {
          controller.add(1);
          controller.add(2);
        },
        expectation: (values) => expect(values).toEqual([0, 1, 3]));
  });

  it("closes transformed stream when source stream is done", () {
    var stream = controller.stream.transform(new Scan(0, (a, b) => a + b));
    controller..close();
    return stream.toList().then((values) => expect(values).toEqual([0]));
  });

  it("cancels source listener when transformed stream is cancelled", () {
    var complete = new Completer();
    var controller = new StreamController(onCancel: complete.complete);

    return testStream(
        controller.stream.transform(new Scan(0, (a, b) => a + b)),
        expectation: (_) => complete.future);
  });

  it("forwards errors from source stream", () {
    return testErrorsAreForwarded(
        controller.stream.transform(new Scan(0, (a, b) => a + b)),
        behavior: () {
          controller..addError(1)..close();
        },
        expectation: (errors) => expect(errors).toEqual([1]));
  });

  it("returns a stream of the same type", () {
    var stream = controller.stream.transform(new Scan(0, (a, b) => a + b));
    expect(stream.isBroadcast).toBe(controller.stream.isBroadcast);
  });
}