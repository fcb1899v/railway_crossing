// A ticket photo is shown and costs a ticket only when at least two of the three images return.
// Fewer than two asks once more for the missing images.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:railroad_crossing/photo_manager.dart';

PhotoResult images(int n) => PhotoResult.images(List.generate(n, (i) => Uint8List.fromList([i])));

/// Answers each request in turn and records the count it was asked for
class Requests {
  final List<PhotoResult> answers;
  final calls = <int>[];
  Requests(this.answers);

  Future<PhotoResult> call(int count) async {
    calls.add(count);
    return answers[calls.length - 1];
  }
}

void main() {
  test('fewer than two images is a failed capture', () {
    expect(ticketPhotoCounts(0), isFalse);
    expect(ticketPhotoCounts(1), isFalse);
  });

  test('two or three images count', () {
    expect(ticketPhotoCounts(2), isTrue);
    expect(ticketPhotoCounts(3), isTrue);
  });

  test('three images need no second request', () async {
    final r = Requests([images(3)]);
    final result = await topUpTicketPhoto(r.call);
    expect(result.images.length, 3);
    expect(r.calls, [3]);
  });

  test('two images are kept without a second request', () async {
    final r = Requests([images(2)]);
    final result = await topUpTicketPhoto(r.call);
    expect(result.images.length, 2);
    expect(r.calls.length, 1);
  });

  test('one image asks for the missing two and keeps all three', () async {
    final r = Requests([images(1), images(2)]);
    final result = await topUpTicketPhoto(r.call);
    expect(result.images.length, 3);
    expect(r.calls, [3, 2]);
  });

  test('no image asks again for three', () async {
    final r = Requests([const PhotoResult.failed('error'), images(3)]);
    final result = await topUpTicketPhoto(r.call);
    expect(result.images.length, 3);
    expect(r.calls, [3, 3]);
  });

  test('no image twice is a failure with its reason', () async {
    final r = Requests([const PhotoResult.failed('error'), const PhotoResult.failed('empty')]);
    final result = await topUpTicketPhoto(r.call);
    expect(result.images, isEmpty);
    expect(result.failureReason, 'empty');
  });

  test('one image and a failed second request stays below the threshold', () async {
    final r = Requests([images(1), const PhotoResult.failed('error')]);
    final result = await topUpTicketPhoto(r.call);
    expect(ticketPhotoCounts(result.images.length), isFalse);
  });

  test('no image then one image stays below the threshold', () async {
    final r = Requests([const PhotoResult.failed('error'), images(1)]);
    final result = await topUpTicketPhoto(r.call);
    expect(result.images.length, 1);
    expect(ticketPhotoCounts(result.images.length), isFalse);
  });

  test('more images than asked are cut to three', () async {
    final r = Requests([images(1), images(3)]);
    final result = await topUpTicketPhoto(r.call);
    expect(result.images.length, 3);
  });
}
