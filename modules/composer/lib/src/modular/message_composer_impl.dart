// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:apps.modules.email.services.messages/message.fidl.dart';
import 'package:apps.modules.email.services.messages/message_composer.fidl.dart';
import 'package:lib.fidl.dart/bindings.dart'
    show InterfaceHandle, InterfaceRequest;

/// Callback with a [Message].
typedef void MessageCallback(Message message);

/// A concrete implementation of the [MessageComposer] FIDL interface.
class MessageComposerImpl extends MessageComposer {
  final List<MessageListenerProxy> _listeners = <MessageListenerProxy>[];
  final List<MessageComposerBinding> _bindings = <MessageComposerBinding>[];

  /// Binds the request with this instance of [MessageComposerImpl].
  void bind(InterfaceRequest<MessageComposer> request) {
    MessageComposerBinding binding = new MessageComposerBinding();
    binding.bind(this, request);
    _bindings.add(binding);
  }

  /// Close FIDL bindings.
  void close() {
    _bindings.forEach((MessageComposerBinding binding) => binding.close());
    _listeners
        .forEach((MessageListenerProxy listener) => listener.ctrl.close());
  }

  @override
  void addMessageListener(InterfaceHandle<MessageListener> interfaceHandle) {
    MessageListenerProxy listener = new MessageListenerProxy();
    listener.ctrl.bind(interfaceHandle);

    _listeners.add(listener);
  }

  /// Trigger listeners with converted Message.
  void handleSubmit(Message message) {
    _listeners.forEach((MessageListenerProxy listener) {
      listener.onSubmitted(message);
    });
  }
}
