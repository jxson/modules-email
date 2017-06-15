// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:flutter/material.dart';

import 'editor_action_bar_header.dart';
import 'message_text_input.dart';
import 'recipient_input.dart';
import 'subject_input.dart';
import 'type_defs.dart';

// Hack(dayang): The value in Colors.grey[500] is technically a const, but it
// isn't considered const because its in a Map
//
// See Flutter issue #8009
// https://github.com/flutter/flutter/issues/8009
final TextStyle _kLabelStyle = new TextStyle(
  fontSize: 14.0,
  color: Colors.grey[700],
);

final TextStyle _kInputStyle = new TextStyle(
  fontSize: 16.0,
  color: Colors.black,
);

/// Email Editor Screen
class EditorScreen extends StatefulWidget {
  /// Callback that gets fired any time the message draft is changed
  final MessageCallback onDraftChanged;

  /// Optional initial message draft to start out with
  final Message draft;

  /// Flag on whether to 'enable' send button.
  final bool enableSend;

  /// Callback for 'close' affordance
  final VoidCallback onClose;

  /// Callback for sending message
  final MessageCallback onSend;

  /// Callback for 'attach file' affordance
  final VoidCallback onAttach;

  /// Constructor
  EditorScreen({
    Key key,
    this.draft,
    this.enableSend: false,
    this.onDraftChanged,
    this.onAttach,
    this.onClose,
    this.onSend,
  })
      : super(key: key);

  @override
  _EditorScreenState createState() => new _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  List<Mailbox> _recipientList = <Mailbox>[];

  String _subject = '';

  String _text = '';

  @override
  void initState() {
    super.initState();
    _recipientList = widget.draft?.recipientList ?? <Mailbox>[];
    _subject = widget.draft?.subject ?? '';
    _text = widget.draft?.text ?? '';
  }

  void _handleSend() {
    if (widget.onSend != null) {
      Message message = new Message(
        recipientList: _recipientList,
        subject: _subject,
        text: _text,
      );
      widget.onSend(message);
    }
  }

  void _handleDraftUpdate() {
    if (widget.onDraftChanged != null) {
      Message message = new Message(
        recipientList: _recipientList,
        subject: _subject,
        text: _text,
      );
      widget.onDraftChanged(message);
    }
  }

  @override
  void didUpdateWidget(EditorScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recipientList = widget.draft.recipientList;
    _subject = widget.draft.subject;
    _text = widget.draft.text;
  }

  void _handleRecipientChange(List<Mailbox> recipientList) {
    _recipientList = recipientList;
    _handleDraftUpdate();
  }

  void _handleSubjectChange(String subject) {
    _subject = subject;
    _handleDraftUpdate();
  }

  void _handleTextChange(String text) {
    _text = text;
    _handleDraftUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return new Material(
      child: new Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          new EditorActionBarHeader(
            enableSend: widget.enableSend,
            onAttach: widget.onAttach,
            onClose: widget.onClose,
            onSend: _handleSend,
          ),
          new RecipientInput(
            inputLabel: 'To',
            recipientList: _recipientList,
            onRecipientsChanged: _handleRecipientChange,
            inputStyle: _kInputStyle,
            labelStyle: _kLabelStyle,
          ),
          new SubjectInput(
            initialText: _subject,
            onTextChange: _handleSubjectChange,
            inputStyle: _kInputStyle,
            labelStyle: _kLabelStyle,
          ),
          new MessageTextInput(
            initialText: _text,
            onTextChange: _handleTextChange,
            inputStyle: _kInputStyle,
            labelStyle: _kLabelStyle,
          ),
        ],
      ),
    );
  }
}
