// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:flutter/material.dart';
import 'package:lib.logging/logging.dart';
import 'package:lib.widgets/model.dart';
import 'package:meta/meta.dart';

/// The [ComposerModel] is the class responsible for encapsulating the UI state
/// values and handling requests to mutate its attributes. Platform specific
/// interactions MUST register listeners when constructing new instances of
/// [ComposerModel].
//
/// The [ComposerModel] attributes are derived from a single, private [Message]
/// object. To update the attributes rendered in the UI from async operations
/// (like Link#get(...)) a special setter for [message] is exposed.
class ComposerModel extends Model {
  /// Optional pre-send hook, used to perform final UI validation.
  VoidCallback onPreSend;

  /// Triggered whenever a "Send" affordance is explicitly pressed.
  final VoidCallback onSend;

  /// Triggered whenever a "Close" affordance is explicitly pressed.
  final VoidCallback onClose;

  /// Triggered whenever a "Delete" affordance is explicitly pressed.
  final VoidCallback onDelete;

  /// Triggered anytime the encapsulated [Message] is updated by the user.
  final ValueChanged<Message> onUpdate;

  /// Construct a new instance of [ComposerModel].
  ///
  /// UI Widgets in the composer [Widget] tree expect a parent to contain an
  /// instance of [ComposerModel] to connect thier affordnaces to platform
  /// specific API interactions. Any Widget that uses [ComposerModel.of] to
  /// access the model's event handlers or [ScopedModelDescendant] for update
  /// builders MUST have a [ScopedModel] as a parent [Widget].
  ComposerModel({
    @required this.onClose,
    @required this.onDelete,
    @required this.onSend,
    @required this.onUpdate,
  }) {
    assert(onClose != null);
    assert(onDelete != null);
    assert(onSend != null);
    assert(onUpdate != null);
  }

  /// The unformatted message body.
  String get body => _message.text;

  /// The subject of the message draft.
  String get subject => _message.subject;

  /// The list of recipients in the to field.
  List<Mailbox> get to => _message.recipientList;

  /// Update the message content and triger a UI render.
  set message(Message m) {
    _message = m;
    notifyListeners();
  }

  /// The private [message] value, defaults to an empty message.
  Message _message = new Message();

  /// Wraps [ModelFinder.of] for this [Model]. See [ModelFinder.of] for more
  /// details.
  static ComposerModel of(BuildContext context) {
    ComposerModel model = new ModelFinder<ComposerModel>().of(context);
    assert(model != null, 'No instance of ComposerModel found in tree.');
    return model;
  }

  /// Handle "Send" events from the UI.
  void handleSend() {
    log.fine('"send" pressed');
    onPreSend?.call();
    onSend?.call();
  }

  /// Handle "Close" events from the UI.
  void handleClose() {
    log.fine('"close" pressed');
    onClose?.call();
  }

  /// Handle "Delete" events from the UI.
  void handleDelete() {
    log.fine('"delete" pressed');
    onDelete?.call();
  }

  /// Handle "To:" field updates.
  void handleToChanged(List<Mailbox> mailboxes) {
    log.fine('to: $mailboxes');
    _message.recipientList = mailboxes;
    notifyListeners();
    onUpdate?.call(_message);
  }

  /// Handle "Subject:" field updates.
  void handleSubjectChanged(String string) {
    log.fine('subject: $string');
    _message.subject = string;
    notifyListeners();
    onUpdate?.call(_message);
  }

  /// Handle message body updates.
  void handleBodyChanged(String body) {
    log.fine('body: $body');
    _message.text = body;
    notifyListeners();
    onUpdate?.call(_message);
  }
}
