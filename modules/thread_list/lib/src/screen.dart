// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_flux/flux.dart';
import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flux/flutter_flux.dart';

// Inbox header height needs to line up with the ThreadView header
const double _kInboxHeaderHeight = 73.0;

/// An email inbox screen that shows a list of email threads, built with the
/// flux pattern.
class EmailThreadListScreen extends StoreWatcher {
  /// The Flux StoreToken this screen uses for UI state.
  final StoreToken token;

  /// Create a new [EmailThreadListScreen] instance.
  EmailThreadListScreen({
    Key key,
    this.token,
  });

  @override
  void initStores(ListenToStore listenToStore) {
    listenToStore(token);
  }

  /// When the FAB is pressed notify Flux listeners to compose a new, empty
  /// message.
  void handleFabPressed() {
    EmailFluxActions.composeMessage(new Message());
  }

  @override
  Widget build(BuildContext context, Map<StoreToken, Store> stores) {
    final EmailFluxStore fluxStore = stores[token];

    return new Scaffold(
      // TODO(SO-424): Use email spec compliant colors and sizing.
      appBar: new AppBar(
        title: new Text(
          fluxStore.focusedLabel?.name ?? '',
          style: new TextStyle(color: Colors.black),
        ),
        backgroundColor: Colors.white,
      ),
      body: buildBody(context, fluxStore),
      floatingActionButton: new FloatingActionButton(
        onPressed: handleFabPressed,
        tooltip: 'Draft a new message.',
        child: new Icon(Icons.create),
      ),
    );
  }

  /// Build the body of the thread list view.
  Widget buildBody(BuildContext context, EmailFluxStore fluxStore) {
    if (fluxStore.fetchingThreads) {
      return new Center(child: new CircularProgressIndicator());
    }

    if (fluxStore.errors.isNotEmpty) {
      return new Errors(
        errors: fluxStore.errors,
      );
    }

    List<Thread> threads = fluxStore.threads.values.toList();

    threads.sort((Thread a, Thread b) {
      Message lastA = a.lastMessage;
      Message lastB = b.lastMessage;

      return lastB.timestamp.compareTo(lastA.timestamp);
    });

    return new ListView(
      children: threads.map((Thread t) => buildListItem(t, fluxStore)).toList(),
    );
  }

  /// Create the list item view for the given thread.
  Widget buildListItem(Thread thread, EmailFluxStore fluxStore) {
    Key key = new ObjectKey(thread);

    return new ThreadListItem(
      key: key,
      thread: thread,
      onSelect: EmailFluxActions.selectThread.call,
      isSelected: fluxStore.focusedThreadId == thread.id,
      onArchive: EmailFluxActions.archiveThread.call,
    );
  }
}
