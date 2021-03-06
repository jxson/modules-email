// Copyright 2017 The Fuchsia Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:models/fixtures.dart';
import 'package:models/user.dart';

import 'models.dart';

/// [Fixtures] extension class for FX models.
class EmailFixtures extends ModelFixtures {
  /// Me.
  User me() {
    return user(
      name: 'Aparna Nielsen',
      email: 'aparna@example.org',
    );
  }

  /// Create a random [Label].
  Label label({
    String id,
    String name,
    int unread,
    String type,
  }) {
    return new Label(
      id: id ?? 'INBOX',
      name: name ?? 'Inbox',
      unread: unread ?? number(800),
      type: type ?? 'system',
    );
  }

  /// Create a [List] of [Label] objects for use in testing and demos.
  Map<String, Label> labels() {
    Map<String, Label> map = <String, Label>{};
    List<String> names = <String>[
      'Inbox',
      'Starred',
      'Drafts',
      'Trash',
    ];

    names.forEach((String name) {
      String id = name.toUpperCase();

      map[id] = label(
        id: id,
        name: name,
        type: 'system',
      );
    });

    return map;
  }

  /// Generate [Attachment] objects.
  Attachment attachment({
    String id,
    AttachmentType type,
    String value,
  }) {
    switch (type) {
      case AttachmentType.youtubeVideo:
        value ??= '0pfUC55a3Jc';
        break;
      case AttachmentType.uspsShipping:
        value ??= '9374889676090175041871';
        break;
      case AttachmentType.orderReceipt:
        value ??= 'order-123';
        break;
    }

    return new Attachment(
      id: id ?? this.id('attachment'),
      value: value ?? 'example-value',
      type: type ?? AttachmentType.youtubeVideo,
    );
  }

  /// Generate a [Message].
  Message message({
    User sender,
    String subject,
    String text,
    bool isRead,
    List<User> to,
    List<User> cc,
    int timestamp,
    List<Attachment> attachments,
    bool expanded: false,
  }) {
    sender ??= user();

    if (to == null || to.isEmpty) {
      to = <User>[user()];
    }

    return new Message(
      id: id('message'),
      sender: new Mailbox(
        address: sender.email,
        displayName: sender.name,
      ),
      senderProfileUrl: null,
      recipientList: to?.map(Mailbox.createFromUser)?.toList(),
      ccList: cc?.map(Mailbox.createFromUser)?.toList(),
      subject: subject,
      text: text ?? lorem.createText(),
      timestamp: timestamp ?? this.timestamp(),
      isRead: isRead ?? false,
      attachments: attachments,
      expanded: expanded,
    );
  }

  /// Generate a [Thread].
  Thread thread([List<Message> list]) {
    list ??= new List<Message>.generate(
      rng.nextInt(3) + 1,
      (int _) => message(),
    );

    Map<String, Message> messages = new Map<String, Message>.fromIterable(
      list,
      key: (Message m) => m.id,
      value: (Message m) => m,
    );

    return new Thread(
      id: id('thread'),
      historyId: id('history'),
      snippet: 'Example snippet',
      messages: messages,
    );
  }

  /// TODO(jasoncampbell): document this.
  Map<String, Thread> threads({
    String labelId: 'INBOX',
  }) {
    List<Thread> threads;
    Map<String, Thread> results = <String, Thread>{};

    switch (labelId) {
      case 'INBOX':
        threads = _inbox();
        break;
      case 'STARRED':
        threads = _starred();
        break;
      case 'DRAFTS':
        threads = _drafts();
        break;
      case 'TRASH':
        threads = _trash();
        break;
      default:
        threads = <Thread>[];
    }

    threads.forEach((Thread thread) => results[thread.id] = thread);

    return results;
  }

  List<Thread> _starred() {
    User me = this.me();
    User dad = user(name: 'Ian Nielsen');
    return <Thread>[
      thread(<Message>[
        message(
          sender: dad,
          to: <User>[me],
          timestamp:
              DateTime.parse('2016-11-29T18:14-0600').millisecondsSinceEpoch,
          subject: 'Don\'t forget to call your mom.',
          text: 'It\'s her birthday too. You know how she gets. ;-)',
          isRead: true,
        )
      ])
    ];
  }

  List<Thread> _drafts() {
    return <Thread>[];
  }

  List<Thread> _trash() {
    User me = this.me();
    return <Thread>[
      thread(<Message>[
        message(
          sender: user(name: 'Traveling Salesman'),
          to: <User>[me],
          timestamp:
              DateTime.parse('2016-11-22T06:22-0600').millisecondsSinceEpoch,
          subject: '90% off for a limited time!!!',
          text: '''90% off for a limited time!

If you want to change your life, click here and get 90% stuff you really need.
---> CLICK HERE <----
''',
          isRead: true,
        )
      ]),
      thread(<Message>[
        message(
          sender: user(name: 'Gym'),
          to: <User>[me],
          timestamp:
              DateTime.parse('2016-11-21T05:02-0600').millisecondsSinceEpoch,
          subject: 'New Years Resolution Time',
          text: '''

A new year is coming up. Time to commit again to those new years resolutions and sign up for a gym membership.

Sign up now!
''',
          isRead: true,
        )
      ])
    ];
  }

  List<Thread> _inbox() {
    User me = this.me();
    User dad = user(name: 'Ian Nielsen');
    User store = user(
      name: 'Bedford Mobile Outlet',
      email: 'store@example.org',
    );
    User miguel = user(name: 'Miguel Entorre');
    User sophie = user(name: 'Sophie Chua');
    User danielle = user(name: 'Danielle Kazlowski');

    return <Thread>[
      thread(<Message>[
        message(
            sender: store,
            to: <User>[me],
            timestamp:
                DateTime.parse('2016-11-29T18:14-0600').millisecondsSinceEpoch,
            subject: 'Your order from Bedford Mobile',
            text: 'http://www.aplusmobile.com/yourorder',
            isRead: false,
            attachments: <Attachment>[
              attachment(
                type: AttachmentType.orderReceipt,
              ),
            ]),
        message(
          sender: store,
          to: <User>[me],
          timestamp:
              DateTime.parse('2016-11-29T19:14-0600').millisecondsSinceEpoch,
          subject: 'Your order from Bedford Mobile Outlet is on its way! ',
          text: '''Hello Aparna Nielsen,

We’re writing to inform you that your order (#S000242323) has recently shipped!

If you would like to track the progress of your package, please visit the USPS website:

https://tools.usps.com/go/TrackConfirmAction?qtc_tLabels1=9341989676090046890941

Thank you very much,
Sam Lefferts
Bedford Mobile Outlet
          ''',
          attachments: <Attachment>[
            attachment(
              value: '9341989676090046890941',
              type: AttachmentType.uspsShipping,
            ),
          ],
        ),
      ]),
      thread(<Message>[
        message(
          sender: me,
          to: <User>[dad],
          timestamp:
              DateTime.parse('2016-11-28T22:57:00-0600').millisecondsSinceEpoch,
          subject: 'India trip planning',
          text: '''Hey Dad,


Can you send over the doc that has Nani's birthday plans? Just want to make sure I have the dates right!


Love, Aparna
          ''',
        ),
        message(
          sender: dad,
          to: <User>[me],
          timestamp:
              DateTime.parse('2016-11-29T01:12:00-0600').millisecondsSinceEpoch,
          subject: 're: India trip planning',
          text: '''Hi pumpkin-

I actually haven't started putting a doc together yet. Maybe we can work on it together later this week.

But the dates are still the same - your mother and I will be leaving from EWR on Sunday 5/14 at 7:00am, so we'll be at Vadodara around Tuesday morning.

And we're planning to depart BDQ on 5/31 at 5:00pm.

-Dad
          ''',
        ),
        message(
          sender: me,
          to: <User>[dad],
          timestamp:
              DateTime.parse('2016-11-29T03:12:00-0600').millisecondsSinceEpoch,
          subject: 'India trip planning',
          text: '''Ahhh ok. My mistake. :)


Yes, I should be free to work on putting one together after this Thursday!

          ''',
        ),
        message(
          sender: dad,
          to: <User>[me],
          timestamp:
              DateTime.parse('2016-11-29T16:31:00-0600').millisecondsSinceEpoch,
          subject: 're: India trip planning',
          text:
              '''Great, I'll give you a call once I can dig up all my files. Lots of old itineraries lying around that we never quite got around to.


By the way, do you have enough suitcases for your stuff? Your mother and I have a couple extra.

          ''',
        ),
        message(
          sender: me,
          to: <User>[dad],
          timestamp:
              DateTime.parse('2016-11-29T17:35:00-0600').millisecondsSinceEpoch,
          subject: 're: India trip planning',
          text:
              '''I'll be getting some new luggage delivered, so I should be ready. Do you have my immunization history available by chance? I think it's over in the top drawer of my old dresser.


By the way, I came across this awesome video. Maybe we can do this on a future trip. :)
https://www.youtube.com/watch?v=KbtZfzxX44o


-Aparna
          ''',
          attachments: <Attachment>[
            attachment(
              value: 'KbtZfzxX44o',
              type: AttachmentType.youtubeVideo,
            ),
          ],
        ),
      ]),
      thread(<Message>[
        message(
          sender: miguel,
          to: <User>[me],
          timestamp:
              DateTime.parse('2016-11-28T23:45:00-0600').millisecondsSinceEpoch,
          subject: 'Toe the Line followup',
          text:
              '''Hey, I have a couple thoughts on how we can update the Silver Toe lineup. Bear with me here, these ideas are amazing.


1) We enlist an A-list celebrity to promote the line. As I understand, Shamra is in town, so we might be able to convince her to pitch this line of socks if we're sufficiently compelling.


2) We create a cartoon series about anthropomorphic socks.


What do you think?


-Miguel

          ''',
        ),
        message(
          sender: me,
          to: <User>[miguel],
          subject: 're: Toe the Line followup',
          timestamp:
              DateTime.parse('2016-11-29T15:02:00-0600').millisecondsSinceEpoch,
          text: '''Sounds good. Want to meet up later this afternoon?


-A
''',
        ),
        message(
          sender: miguel,
          to: <User>[me],
          subject: 're: Toe the Line followup',
          timestamp:
              DateTime.parse('2016-11-29T17:01:00-0600').millisecondsSinceEpoch,
          text:
              '''Yeah, I'm free for the rest of the afternoon. Want to just stop by my desk when you have a spare moment? It might be better if I can draw it out in person.
              ''',
        ),
      ]),
      thread(<Message>[
        message(
          sender: me,
          to: <User>[sophie],
          subject: 'Plans for Miguel’s birthday',
          timestamp:
              DateTime.parse('2016-11-29T15:20:00-0600').millisecondsSinceEpoch,
          text: '''Hey Sophie,


Any thoughts on what to do for Miguel's birthday? It's coming up!


I was thinking that maybe we could bring in a delicious snack that he might like. But I'm open to other ideas!


-Aparna''',
        ),
        message(
          sender: sophie,
          to: <User>[me],
          subject: 're: Plans for Miguel’s birthday',
          timestamp:
              DateTime.parse('2016-11-29T15:28:00-0600').millisecondsSinceEpoch,
          text:
              '''I heard that Miguel likes Pavlova! Let's make one for him. I was looking for tutorials online, and just found this one...
https://www.youtube.com/watch?v=NS4yqgNjl9Y


-Sophie''',
          attachments: <Attachment>[
            attachment(
              type: AttachmentType.youtubeVideo,
              value: 'NS4yqgNjl9Y',
            ),
          ],
        ),
        message(
          sender: me,
          to: <User>[sophie],
          subject: 're: Plans for Miguel’s birthday',
          timestamp:
              DateTime.parse('2016-11-29T16:54:00-0600').millisecondsSinceEpoch,
          text:
              '''Oh wow, that Pavlova recipe looks a bit complicated. But I might be able to pull something like that off.


I started looking around some more myself, and came across this one:
https://www.youtube.com/watch?v=KkHLj9QLYck


I see this chef on that show on TV pretty often. So if it's easy enough for her to make a Pavlova in 30 minutes, I should have no problem making one by the end of this week…


-Aparna''',
        ),
      ]),
      thread(<Message>[
        message(
          sender: me,
          to: <User>[danielle],
          subject: 'Concert on Friday?',
          timestamp:
              DateTime.parse('2016-11-28T23:56:00-0600').millisecondsSinceEpoch,
          text: '''Hey!


Interested in seeing Chvrches next month? They have a new album that's supposed to be pretty good. I think they’re playing on the 30th at the Chicago Regal, just before the New Year.


-Aparna''',
        ),
        message(
          sender: danielle,
          to: <User>[me],
          subject: 're: Concert on Friday?',
          timestamp:
              DateTime.parse('2016-11-29T14:05:00-0600').millisecondsSinceEpoch,
          text:
              '''Oh, I was just about to ask you about seeing Chvrches! I was listening to their album non-stop, as a matter of fact. I’m going to check to see if I can get a sitter for the kids that weekend. Fingers crossed!


In the meantime, take a look at one of their videos:
https://www.youtube.com/watch?v=4Eo84jDIMKI


-Danielle''',
          attachments: <Attachment>[
            attachment(
              value: '4Eo84jDIMKI',
              type: AttachmentType.youtubeVideo,
            ),
          ],
        ),
      ]),
    ];
  }
}
