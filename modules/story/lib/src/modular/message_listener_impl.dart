// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modules.email.services.messages/message.fidl.dart';
import 'package:apps.modules.email.services.messages/message_composer.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart' show InterfaceHandle;
import 'package:meta/meta.dart';

/// Callback with a [Message].
typedef void MessageCallback(Message message);

/// Implementation of [MessageListener] to be notified of email composition
/// module events.
class MessageListenerImpl extends MessageListener {
  final List<MessageListenerBinding> _bindings = <MessageListenerBinding>[];
  MessageCallback _onSubmitted;
  MessageCallback _onChanged;

  /// [MessageListenerImpl] constructor.
  MessageListenerImpl({
    @required MessageCallback onSubmitted,
    @required MessageCallback onChanged,
  }) {
    _onSubmitted = onSubmitted;
    _onChanged = onChanged;
  }

  /// Binds the request with this instance of [MessageListenerImpl].
  InterfaceHandle<MessageListener> getHandle() {
    MessageListenerBinding binding = new MessageListenerBinding();
    _bindings.add(binding);

    return binding.wrap(this);
  }

  /// Close FIDL bindings.
  void close() {
    _bindings.forEach((MessageListenerBinding binding) => binding.close());
  }

  @override
  void onChanged(Message message) {
    _onChanged(message);
  }

  @override
  void onSubmitted(Message message) {
    _onSubmitted(message);
  }
}
