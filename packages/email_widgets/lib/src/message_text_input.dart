// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'type_defs.dart';

/// Input for email message text
class MessageTextInput extends StatefulWidget {
  /// Initial text to prepopulate the input
  final String initialText;

  /// Callback function that is called everytime the subject text is changed
  final StringCallback onTextChange;

  /// TextStyle used for the input and recipient chips
  ///
  /// Defaults to the subhead style of the theme
  final TextStyle inputStyle;

  /// TextStyle used for the label
  ///
  /// Defaults to the inputStyle with a grey-500 color
  final TextStyle labelStyle;

  /// Constructor
  MessageTextInput({
    Key key,
    this.initialText,
    this.onTextChange,
    this.inputStyle,
    this.labelStyle,
  })
      : super(key: key);

  @override
  _MessageTextInputState createState() => new _MessageTextInputState();
}

class _MessageTextInputState extends State<MessageTextInput> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(MessageTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText) {
      _controller.text = widget.initialText;
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextStyle inputStyle = widget.inputStyle ?? theme.textTheme.subhead;
    TextStyle labelStyle =
        widget.labelStyle ?? inputStyle.copyWith(color: Colors.grey[500]);

    // TODO(dayang): Tapping on the entire container should bring focus to the
    // TextField.
    // https://fuchsia.atlassian.net/browse/SO-188
    //
    // This is blocked by Flutter Issue #7985
    // https://github.com/flutter/flutter/issues/7985
    return new Container(
      padding: const EdgeInsets.all(16.0),
      child: new TextField(
        controller: _controller,
        onChanged: widget.onTextChange,
        style: inputStyle,
        decoration: new InputDecoration.collapsed(
          hintText: 'Compose email',
          hintStyle: labelStyle,
        ),
        maxLines: null,
      ),
    );
  }
}
