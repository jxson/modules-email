# Email

> Status: Experimental

# Structure

This repo contains code for running a vanilla [Flutter][flutter] application (iOS & Android) and a [Fuchsia][fuchsia] specific set of [modules][modular].

* **agents**: Fuchsia agents (background services) using Modular APIs.
    * **content_provider**: The email content provider agent which communicates with the cloud email services.
* **modules**: Fuchsia application code using Modular APIs.
    * **composer**: Email composition module, can be launched outside of the email/story flow, instructions [here](https://fuchsia.googlesource.com/modules/email/+/master/modules/composer/).
    * **nav**: Navigation module.
    * **story**: The top-level email "Story" and primary entry point for the full Email experience.
    * **thread_list**: The list of Threads.
    * **thread**: A single Email Thread.
* **packages**: Common Dart packages used by email agents / modules.
* **services**: [FIDL][fidl] service definitions.

# Setup

## Checkout

This repo is already part of the default jiri manifest.

Follow the instructions for setting up a fresh Fuchsia checkout.  Once you have the `jiri` tool installed and have imported the default manifest and updated return to these instructions.

It is recommended you set up the [Fuchsia environment helpers][fuchsia-env] in `scripts/env.sh`:

    source scripts/env.sh

## Device Setup

The series of modules that compose Email share data through [Links][link]. Links allow the shared state between Modules to be persisted between between device reboots and across devices.

In order to enable the desired behavior some configuration is required for the device that the Email modules will be running on. The best way to set up persistent device storage is to use the Fuchsia installer.

1. [Setup an Acer][setup-acer].
* Ensure you can netboot.
    * `cd $FUCHSIA_DIR # Or fgo`
    * `fset x86-64 --modules default`
    * `fbuild`
    * `fboot`
* [Setup the Fuchsia Installer][install-fuchsia], this will setup data partitions on the device.
* Ensure that data persists between device reboots, in the Acer's terminal:
    * `touch /data/foobar`
    * `dm reboot`
    * Wait for the device to reboot.
    * `ls /data`
    * If everything went well you will see `/data/foobar`!
    * See the [MinFS document][minfs] to learn more about the filesystem.
* [Enable Ledger's Cloud Sync][ledger-config]. **NOTE:** Ledger data syncing is not secure, only login with test accounts.

[ledger-config]: https://fuchsia.googlesource.com/ledger/+/HEAD/docs/user_guide.md
[minfs]: https://fuchsia.googlesource.com/magenta/+/master/docs/minfs.md
[setup-acer]: https://fuchsia.googlesource.com/magenta/+/HEAD/docs/targets/acer12.md
[install-fuchsia]: https://fuchsia.googlesource.com/install-fuchsia/+/master/README.md#Fuchsia-Installer
[link]: https://fuchsia.googlesource.com/modular/+/master/services/story/link.fidl

# Workflow

There are Makefile tasks setup to help simplify common development tasks. Use `make help` to see what they are.

When you have changes you are ready to see in action you can build with:

    make build # or fset x86-64 --modules default && fbuild

Once the system has been built you will need to run a bootserver to get it
over to a connected Acer. You can use the `env.sh` helper to move the build from your host to the target device with:

    freboot

Once that is done (it takes a while) you can run the application with:

    make run

You can run on a connected android device with:

    make flutter-run

Optional: In another terminal you can tail the logs

    ${FUCHSIA_DIR}/out/build-magenta/tools/loglistener

[flutter]: https://flutter.io/
[fuchsia]: https://fuchsia.googlesource.com/fuchsia/
[modular]: https://fuchsia.googlesource.com/modular/
[pub]: https://www.dartlang.org/tools/pub/get-started
[dart]: https://www.dartlang.org/
[fidl]: https://fuchsia.googlesource.com/fidl/
[widgets-intro]: https://flutter.io/widgets-intro/
[fuchsia-setup]: https://fuchsia.googlesource.com/fuchsia/+/HEAD/README.md
[fuchsia-env]: https://fuchsia.googlesource.com/fuchsia/+/HEAD/README.md#Setup-Build-Environment
[clang-wrapper]: https://fuchsia.googlesource.com/magenta-rs/+/HEAD/tools
