// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:apps.modular.services.auth/token_provider.fidl.dart';
import 'package:email_api/email_api.dart';
import 'package:lib.logging/logging.dart';

/// Helper to access and contain an EmailAPI singleton.
class API {
  static EmailAPI _api;

  /// Oauth scopes.
  static final List<String> scopes = <String>[
    'openid',
    'email',
    'https://www.googleapis.com/auth/gmail.modify',
    'https://www.googleapis.com/auth/assistant',
    'https://www.googleapis.com/auth/userinfo.email',
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/contacts',
    'https://www.googleapis.com/auth/plus.login',
  ];

  /// Async getter/loader.
  static Future<EmailAPI> fromTokenProvider(
    TokenProviderProxy tokenProvider,
  ) async {
    Completer<String> _accessTokenCompleter = new Completer<String>();
    AuthErr authErr;
    tokenProvider.getAccessToken((String token, AuthErr err) {
      _accessTokenCompleter.complete(token);
      authErr = err;
    });

    String token = await _accessTokenCompleter.future;
    if (authErr.status != Status.ok) {
      log.severe('Error fetching access token:${authErr.message}');
      return null;
    }

    DateTime expiry = new DateTime.now().add(new Duration(minutes: 50)).toUtc();

    AccessToken accessToken = new AccessToken('Bearer', token, expiry);
    AccessCredentials credentials =
        new AccessCredentials(accessToken, null, scopes);
    Client baseClient = new Client();
    AuthClient client = authenticatedClient(baseClient, credentials);

    if (_api == null) {
      _api = new EmailAPI(client);
    } else {
      _api.client = client;
    }

    return _api;
  }
}
