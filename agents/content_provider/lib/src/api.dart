// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:apps.modular.services.auth/token_provider.fidl.dart';
import 'package:email_api/email_api.dart';
import 'package:lib.logging/logging.dart';

/// Helper to access and contain an EmailAPI singleton.
class API {
  /// Async getter/loader.
  static Future<EmailAPI> fromTokenProvider(
    TokenProviderProxy tokenProvider,
  ) async {
    Completer<String> _clientIdCompleter = new Completer<String>();
    tokenProvider.getClientId(_clientIdCompleter.complete);

    Completer<String> _accessTokenCompleter = new Completer<String>();
    AuthErr authErr;
    tokenProvider.getAccessToken((String token, AuthErr err) {
      _accessTokenCompleter.complete(token);
      authErr = err;
    });

    String accessToken = await _accessTokenCompleter.future;
    log.fine('Access token:$accessToken');
    if (authErr.status != Status.ok) {
      log.warning('Error fetching access token:${authErr.message}');
    }

    return new EmailAPI(
      id: await _clientIdCompleter.future,
      token: accessToken,
      // TODO: expiry time should be retrieved from GetAccessToken api, if
      // needed.
      expiry: new DateTime.now().add(new Duration(minutes: 50)).toUtc(),
      scopes: <String>[
        'openid',
        'email',
        'https://www.googleapis.com/auth/gmail.modify',
        'https://www.googleapis.com/auth/assistant',
        'https://www.googleapis.com/auth/userinfo.email',
        'https://www.googleapis.com/auth/userinfo.profile',
        'https://www.googleapis.com/auth/contacts',
        'https://www.googleapis.com/auth/plus.login',
      ],
    );
  }
}
