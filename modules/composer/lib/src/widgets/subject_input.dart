// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

/// Input for email subject
class SubjectInput extends StatefulWidget {
  /// Initial text to prepopulate stuff
  final String initialText;

  /// Callback function that is called everytime the subject text is changed
  final ValueChanged<String> onTextChange;

  /// Background color.
  final Color backgroundColor;

  /// Constructor
  SubjectInput({
    Key key,
    this.initialText,
    this.onTextChange,
    this.backgroundColor,
  })
      : super(key: key);

  @override
  _SubjectInputState createState() => new _SubjectInputState();
}

class _SubjectInputState extends State<SubjectInput> {
  TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = new TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(SubjectInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText) {
      _controller.text = widget.initialText;
    }
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextStyle inputStyle = theme.textTheme.subhead;
    TextStyle labelStyle = inputStyle.copyWith(color: Colors.grey[500]);

    // TODO(dayang): Tapping on the entire container should bring focus to the
    // TextField.
    // https://fuchsia.atlassian.net/browse/SO-188
    //
    // This is blocked by Flutter Issue #7985
    // https://github.com/flutter/flutter/issues/7985
    return new Container(
      alignment: FractionalOffset.centerLeft,
      height: 56.0,
      decoration: new BoxDecoration(
        border: new Border(
          bottom: new BorderSide(
            color: Colors.grey[200],
          ),
        ),
        color: widget.backgroundColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: new TextField(
        controller: _controller,
        onChanged: widget.onTextChange,
        style: inputStyle,
        decoration: new InputDecoration.collapsed(
          hintText: 'Subject',
          hintStyle: labelStyle,
        ),
      ),
    );
  }
}
