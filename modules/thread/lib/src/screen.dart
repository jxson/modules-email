// Copyright 2016 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:email_flux/flux.dart';
import 'package:email_models/models.dart';
import 'package:email_widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_flux/flutter_flux.dart';
import 'package:meta/meta.dart';

/// An email thread screen that shows all the messages in a particular email
/// [Thread], built with the flux pattern.
class EmailThreadScreen extends StoreWatcher {
  /// The Flux StoreToken this screen uses for UI state.
  final StoreToken token;

  /// Creates a new [EmailThreadScreen] instance.
  EmailThreadScreen({
    Key key,
    @required this.token,
  })
      : super(key: key);

  @override
  void initStores(ListenToStore listenToStore) {
    listenToStore(token);
  }

  @override
  Widget build(BuildContext context, Map<StoreToken, Store> stores) {
    EmailFluxStore fluxStore = stores[token];

    if (fluxStore.fetchingThreads) {
      return new CircularProgressIndicator();
    }

    if (fluxStore.errors.isNotEmpty) {
      return new Errors(
        errors: fluxStore.errors,
      );
    }

    String id = fluxStore.focusedThreadId;
    Thread thread = fluxStore.threads[id];
    if (thread == null) {
      // TODO(youngseokyoon): handle this situation better?
      print('[screen_thread.dart] No focused thread. Drawing an empty screen.');
      return new Container();
    }

    return new Center(
      child: new ThreadView(
        thread: thread,
        onSelect: handleSelect,
        onForward: handleForward,
        onReplyAll: handleReplyAll,
        onReply: handleReply,
        onArchive: handleArchive,
        onDelete: handleTrash,
        onMoreActions: toggleMoreMenu,
      ),
    );
  }

  /// Toggle the More action icon.
  void toggleMoreMenu(Thread thread) {
    print('TODO: show a dropdown for the extra actions');
  }

  /// Toggle message expansion.
  void handleSelect(Message message) {
    if (message.expanded) {
      EmailFluxActions.closeMessage(message);
    } else {
      EmailFluxActions.expandMessage(message);
    }
  }

  /// Archive thread.
  void handleArchive(Thread thread) {
    // Add some kind of animation or UI adaptation here?
    EmailFluxActions.archiveThread(thread);
  }

  /// Move thread to trash.
  void handleTrash(Thread thread) {
    // Add some kind of animation or UI adaptation here?
    EmailFluxActions.trashThread(thread);
  }

  /// Respond to the forward button being pressed.
  void handleForward(Message message) {
    print('TODO: handle fowarding messages');
  }

  /// Respond to the forward button being pressed.
  void handleReplyAll(Message message) {
    print('TODO: handle reply all');
  }

  /// Respond to the forward button being pressed.
  void handleReply(Message message) {
    print('TODO: handle reply');
  }
}
