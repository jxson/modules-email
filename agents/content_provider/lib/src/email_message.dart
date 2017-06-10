// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert';
import 'dart:math';

/// Maximum header line length per RFC822.
const int _headerLineLength = 78;

/// Prefix for BASE64 encoded UTF8 header value.
final String _utf8HeaderPrefix = ' =?utf-8?b?';

/// Suffix for BASE64 encoded UTF8 header value.
final String _utf8HeaderSuffix = '?=';

/// Encode UTF8 bytes into a header value.
String _encode(List<int> value) {
  StringBuffer buffer = new StringBuffer();
  buffer.write(_utf8HeaderPrefix);
  buffer.write(BASE64.encode(value));
  buffer.write(_utf8HeaderSuffix);
  return buffer.toString();
}

/// An email header with [name] and [value].
class Header {
  /// The header's name.
  final String name;

  /// The header's value.
  final String value;

  /// Creates a [Header] with the given [name] and [value].
  Header(this.name, this.value);
}

/// An exception thrown if an email can't be encoded.
class EmailEncodingException implements Exception {
  /// A human-readable description of the error.
  final String message;

  /// Creates an [EmailEncodingException] with the given [message].
  EmailEncodingException(this.message);
}

/// Tests if a [string] contains only US-ASCII characters.
bool _isASCII(String string) {
  try {
    ASCII.encode(string);
  } on ArgumentError catch (_) {
    return false;
  }
  return true;
}

/// A class that produces valid encoded pieces of an email header value.
class _HeaderValueProducer {
  final RegExp _whitespace = new RegExp(r'[ \t]');
  String value;
  List<int> utf8value;
  _HeaderValueProducer(this.value) {
    if (!_isASCII(this.value)) {
      utf8value = UTF8.encode(value);
    }
  }

  /// Is there more value available.
  bool get hasMore {
    if (utf8value != null) {
      return utf8value.length > 0;
    } else {
      return value.length > 0;
    }
  }

  /// Take more of the header value, up to [maxLength] bytes.
  String take(int maxLength) {
    if (utf8value != null) {
      final int bytesToTake = min(
          utf8value.length,
          ((maxLength - _utf8HeaderPrefix.length - _utf8HeaderSuffix.length) *
                  3 /
                  4)
              .floor());
      final String taken = _encode(utf8value.sublist(0, bytesToTake));
      utf8value = utf8value.sublist(bytesToTake);
      return taken;
    } else {
      if (value.length <= maxLength) {
        // The rest of the value fits in [maxLength].
        final String taken = value;
        value = '';
        return taken;
      }
      // Look for whitespace.
      final int index = value.lastIndexOf(_whitespace, maxLength);
      if (index < 0) {
        // No whitespace found. A better implementation would encode the rest
        // of this header value to allow breaking.
        final String taken = value;
        value = '';
        return taken;
      }
      final String taken = value.substring(0, index);
      value = value.substring(index);
      return taken;
    }
  }
}

/// Encode a [Header] onto a [StringBuffer].
void _encodeHeader(Header header, StringBuffer buffer) {
  if (!_isASCII(header.name)) {
    throw new EmailEncodingException(
        "Header name '${header.name}' is not ASCII.");
  }
  buffer.writeAll(<String>[header.name, ':']);
  final _HeaderValueProducer producer = new _HeaderValueProducer(header.value);
  buffer.writeAll(<String>[
    producer.take(_headerLineLength - header.name.length - 1),
    '\r\n'
  ]);
  while (producer.hasMore) {
    buffer.writeAll(<String>[producer.take(_headerLineLength), '\r\n']);
  }
}

/// Encode a plain-text email message.
/// This will add the appropriate mime headers to the one supplied by the caller.
String encodePlainTextEmailMessage(List<Header> headers, String body) {
  final List<Header> fullHeaders =
      new List<Header>.from(headers, growable: true);
  fullHeaders.add(new Header('Content-Transfer-Encoding', 'base64'));
  fullHeaders.add(new Header('Content-Type', 'text/plain; charset=\"utf-8\"'));
  fullHeaders.add(new Header('MIME-Version', '1.0'));

  StringBuffer message = new StringBuffer();
  for (final Header header in fullHeaders) {
    _encodeHeader(header, message);
  }
  message.write('\r\n'); // End of headers marker.
  message.write(BASE64.encode(UTF8.encode(body)));

  return message.toString();
}
