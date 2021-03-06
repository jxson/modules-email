// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_models/models.dart';
import 'package:flutter/material.dart';
import 'package:meta/meta.dart';

import '../../models.dart';

/// Callback type for updating the recipients of a new message
typedef void RecipientsChangedCallback(List<Mailbox> recipientList);

/// Google Inbox style 'recipient' field input.
class RecipientInput extends StatefulWidget {
  /// Composer model to use for this recipient list
  final ComposerModel model;

  /// Background color.
  final Color backgroundColor;

  /// Creates a [RecipientInput] instance
  RecipientInput({
    Key key,
    @required this.model,
    this.backgroundColor,
  })
      : super(key: key) {
    assert(this.model != null);
  }

  @override
  _RecipientInputState createState() => new _RecipientInputState();
}

class _RecipientInputState extends State<RecipientInput> {
  /// 'Working copy' of the recipient list.
  /// This is what is passed through in the onRecipientsChanged callback
  List<Mailbox> _recipientList;

  /// The 'in progress' text of the new recipient being composed in the input
  final TextEditingController _controller = new TextEditingController();

  /// The [FocusNode] for the [TextField].
  final FocusNode _textFocus = new FocusNode();

  @override
  void initState() {
    super.initState();
    _recipientList = new List<Mailbox>.from(widget.model.to);
    _textFocus.addListener(() {
      if (!_textFocus.hasFocus) {
        // Text input lost focus.
        _checkForRecipient(_controller.text);
      }
    });
    widget.model.onPreSend = _handlePreSend;
  }

  // Hook to check for valid recipients in the text input field
  // when the message is about to be sent
  void _handlePreSend() {
    _checkForRecipient(_controller.text);
  }

  void _notifyRecipientsChanged() {
    if (widget.model.handleToChanged != null) {
      widget.model
          .handleToChanged(new List<Mailbox>.unmodifiable(_recipientList));
    }
  }

  void _checkForRecipient(String value) {
    // See
    // https://html.spec.whatwg.org/multipage/forms.html#e-mail-state-(type%3Demail)
    // Note the use of raw string notation to avoid interpolation
    String regEx =
        r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$";
    if (new RegExp(regEx).hasMatch(value)) {
      setState(() {
        _recipientList.add(new Mailbox(
          address: value,
        ));
        _controller.clear();
        _notifyRecipientsChanged();
      });
    }
  }

  void _handleInputChange(String value) {
    if (value.endsWith(',') || value.endsWith(' ')) {
      _checkForRecipient(value.substring(0, value.length - 1));
    }
  }

  void _handleInputSubmit(String value) {
    _checkForRecipient(value);
  }

  void _removeRecipient(Mailbox recipient) {
    setState(() {
      _recipientList.remove(recipient);
      _notifyRecipientsChanged();
    });
  }

  @override
  void didUpdateWidget(RecipientInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recipientList = new List<Mailbox>.from(widget.model.to);
  }

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextStyle inputStyle = theme.textTheme.subhead;
    TextStyle labelStyle = inputStyle.copyWith(color: Colors.grey[500]);

    // Render Label
    List<Widget> rowChildren = <Widget>[
      new Container(
        margin: const EdgeInsets.only(right: 4.0),
        child: new Text('To:', style: labelStyle),
      ),
    ];

    //render pre-existing recipients
    _recipientList.forEach((Mailbox recipient) {
      rowChildren.add(new Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        child: new Chip(
          label: new Text(
            recipient.displayText,
            style: inputStyle,
          ),
          onDeleted: () {
            _removeRecipient(recipient);
          },
        ),
      ));
    });

    //add text input
    rowChildren.add(new Expanded(
      child: new Container(
        child: new TextField(
          controller: _controller,
          focusNode: _textFocus,
          onChanged: _handleInputChange,
          onSubmitted: _handleInputSubmit,
          style: inputStyle,
          decoration: null,
        ),
      ),
    ));

    // TODO(dayang): Tapping on the entire container should bring focus to the
    // TextField.
    // https://fuchsia.atlassian.net/browse/SO-188
    //
    // This is blocked by Flutter Issue #7985
    // https://github.com/flutter/flutter/issues/7985
    return new Container(
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
      child: new Row(
        children: rowChildren,
      ),
    );
  }
}
