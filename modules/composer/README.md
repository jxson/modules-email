# Email Composer Module

> Status: Experimental

This is an implementation of a [module][fidl-module] that can be used to
instantiate a UI for drafting or editing email messages and listen to updates
triggered by user interactions. This module is part of the larger
constellation of interoperable email related modules ([//apps/modules/email]).

The email composer module, referenced as "`email/composer` module" in the rest
of this doc, is implemented in Dart and has a few key features:

* UI: A [Flutter][flutter] based input [screen][composer-screen] exposing affordances to modify and submit [`Message`] content.
* Module service: The [`MessageComposer`] interface allows client modules to be notified of change and submission events triggered in the UI.
* [`Link`] contract: Defined in the [`EmailComposerDocument`] Dart library.

**NOTE:** *This module does not send emails*. It is up to the parent module to
listen for message updates and manage what happens to the message when the
user is done.

# Motivation

This `email/composer` module is maintained to:

* Afford users the ability to draft, edit, and send email messages.
* Enable the launching of the message composition view through various mechanisms with pre-defined values.
* Provide a UI surface area to explore rich text editing features.

# Installation

With a default build of Fuchsia this module is available at the url:

    file:///system/apps/email/composer

# Examples

Examples are Dart based, other languages have bindings that expose similar
interfaces.

**WARNING:** In Dart code proxy objects **MUST** be defined as class fields to
avoid the garbage collection of bound FIDL channels. Additionally, channels
**SHOULD** be closed when they are no longer needed. This warning applies to
all proxy objects in that appear the [examples] below.

## Start Module

The `email/composer` module should be started with the
[`ModuleContext`] `StartModule` method. A Mozart
[`ViewOwner`] is required to render the UI.

```dart

ServiceProviderProxy incomingServices = new ServiceProviderProxy();
ModuleControllerProxy moduleController = new ModuleControllerProxy();
InterfacePair<ViewOwner> viewOwnerPair = new InterfacePair<ViewOwner>();

// Start the module.
moduleContext.startModule(
  'email-composer',                      // Module name.
  'file:///system/apps/email/composer',  // Module url.
  'email-composer-link',                 // Module's Link name.
  null,                                  // Outgoing service provider.
  incomingServices.ctrl.request(),       // Incoming service provider.
  moduleControllerPair.passRequest(),    // Module controller.
  viewOwnerPair.passRequest(),           // For the Mozart ViewOwner.
);

```

## Render UI

The `email/composer` module can be rendered using Mozart's [`ChildView`].

```dart

// Create a connection object using the viewOwnerPair defined above.
ChildViewConnection connection = new ChildViewConnection(viewOwnerPair.passHandle());

// In a Flutter widget, build a ChildView with the connection.
class ExampleWidget extends StatelessWidget {
  final ChildViewConnection connection;

  ExampleWidget({
    Key key,
    this.connection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (connection != null) {
      child = new ChildView(connection: connection);
    } else {
      // Do something when the connection is null.
      child = new Container();
    }

    return new Expanded(
      flex: 4,
      child: child,
    );
  }
}

```

## Initial State

The `email/composer` module will read [`Link`] content on startup to populate
default values in the UI. To populate the composition screen with a
pre-defined set of values for fields like to, cc, message, subject, etc. use a
`Link` and populate it with the desired state.

### Link - JSON Schema

Currently the `Link` content used by the composition module:

* **MUST** use a compatible docroot, exposed by `EmailComposerDocument.docroot`, see below for details.
* **MUST** contain a single object key "message".
* The "message" value SHOULD be a JSON serialized [`Message` model][message-model] object or a `null` value.

```javascript

{
  // Docroot.
  "email-composer": {
    // Message key, value can be null.
    "message": { ... }
  }
}

```

See [`Message#toJson()`][message-model] for details about the message's JSON
structure.

### EmailComposerDocument

Code for working with the `Link` content for the `email/composer` module is
exposed through the [`EmailComposerDocument`] Dart library. It enables clients
to easily interact with the Link content without needing explicit knowledge of
the complex JSON structure it wraps.

**NOTE:** The structure of the Link content is expected to change,
specifically the "message" object's structure. It is highly recommended to
use the `EmailComposerDocument` APIs to avoid having to manually update
serialization code when the JSON eventually schema changes.

```dart

// Use the EmailComposerDocument to manage the Link's content.
EmailComposerDocument doc = new EmailComposerDocument();
// Encode the document into a JSON string.
String data = JSON.encode(doc);

```

### Start the Module With a Link

```dart

LinkProxy link = new LinkProxy();

// Get the link for the specific doc (based on message id).
moduleContext.getLink(doc.linkName, link.ctrl.request());

// Set the Link content using the EmailComposerDocument.path helper.
link.set(EmailComposerDocument.path, data);

// Pass the Link into the context.startModule call.
moduleContext.startModule(
  'email-composer',                      // Module name.
  'file:///system/apps/email/composer',  // Module url.
  doc.linkName,                          // Module's Link name.
  null,                                  // Outgoing service provider.
  incomingServices.ctrl.request(),       // Incoming service provider.
  moduleControllerPair.passRequest(),    // Module controller.
  viewOwnerPair.passRequest(),           // For the Mozart ViewOwner.
);

```

## Listen to Events

As a user interact's with the UI, two events can be listened to. Clients will
need to implement an interface to a [`MessageListener`] to be notified when
the form is:

* Submitted: The user is done composing a message.
* Changed: Frequent updates signaled when a message is updated by the user.

```dart

// Create a proxy to the email composer's service.
MessageComposerProxy composerService = new MessageComposerProxy();

// Create an instance of an interface that implementing `MessageListener`.
MessageListenerImpl listenerImpl = new MessageListenerImpl();

// Connect to the service using the same incomingServices used in the
// startModule call.
connectToService(incomingServices, composerService.ctrl);

// Call the service to add the listener.
composerService.addMessageListener(listenerImpl.getHandle());

```

See the email story module's [`MessageListenerImpl`] for a more complete reference implementation.

# API

* Link contracts:
	* Dart library: [`EmailComposerDocument`].
* FIDL definitions:
  * [`Message`]: struct.
  * [`MessageComposer`]: service interface.
  * [`MessageListener`]: client interface.

# Tests

Module integration do not exist yet.

Dart library and Flutter Widget tests are managed by the make tasks in [//apps/modules/email]. These unit style tests can be run from any directory with:

```shell
make -c "${FUCHSIA_DIR}/apps/modules/email" test
```

# License

Copyright 2017 The Fuchsia Authors. All rights reserved.

Use of this source code is governed by a BSD-style license that can be
found in the [LICENSE] file.

[//apps/modules/email]: https://fuchsia.googlesource.com/modules/email/
[LICENSE]: https://fuchsia.googlesource.com/modules/email/+/master/LICENSE
[`ChildView`]: https://fuchsia.googlesource.com/mozart/+/master/lib/flutter/child_view.dart
[`EmailComposerDocument`]: https://fuchsia.googlesource.com/modules/email/+/master/packages/email_composer/lib/document.dart
[`Link`]: https://fuchsia.googlesource.com/modular/+/master/services/story/link.fidl
[`MessageComposer`]: https://fuchsia.googlesource.com/modules/email/+/master/services/messages/message_composer.fidl
[`MessageListenerImpl`]: https://fuchsia.googlesource.com/modules/email/+/master/modules/story/lib/src/modular/message_listener_impl.dart
[`MessageListener`]: https://fuchsia.googlesource.com/modules/email/+/master/services/messages/message_composer.fidl
[`Message`]: https://fuchsia.googlesource.com/modules/email/+/master/services/messages/message.fidl
[`ModuleContext`]: https://fuchsia.googlesource.com/modular/+/master/services/module/module_context.fidl
[`ViewOwner`]: https://fuchsia.googlesource.com/mozart/+/master/services/views/view_token.fidl
[composer-screen]: https://fuchsia.googlesource.com/modules/email/+/master/modules/composer/lib/src/screen.dart
[flutter]: https://flutter.io
[message-model]: https://fuchsia.googlesource.com/modules/email/+/master/packages/email_models/lib/src/message.dart
