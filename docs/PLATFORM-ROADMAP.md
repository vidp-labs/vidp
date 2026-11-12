# Platform Shell Roadmap

Vidp currently ships as a native macOS application. Future platform support
should add native application shells around the shared `VidpEngine` package in
the Vingine repository.

## Shared layer

Vingine remains platform-neutral and owns the playback contract through its
`VidpEngine` package:

- playback commands and state;
- media metadata and track selection;
- backend events; and
- behavior that must stay consistent across applications.

Each shell pins an exact engine release. A shell upgrade to a newer engine
release is an intentional dependency change and is tested before release.

Non-Swift shells need a C-compatible engine surface, meaning a C ABI and
generated bindings, before they can consume an engine release. That surface is
engine work, not shell work.

## Application shells

| Platform | Shell technology | Owns |
|---|---|---|
| macOS | Swift and AppKit | Current official Vidp app, menus, settings, packaging, and native rendering |
| Windows | C# and WinUI 3 (candidate) | Windows windowing, menus, settings, packaging, and native rendering |
| Linux | GTK or Qt (candidates) | Linux windowing, menus, settings, packaging, and native rendering |

The exact Windows and Linux UI frameworks are not selected yet. They should be
chosen when implementation starts, based on the supported desktop versions,
video rendering integration, packaging, and maintenance cost.

## Rules for new shells

- Keep UI, branding, navigation, settings, update logic, signing, and packaging
  in the shell repository.
- Keep playback behavior behind the engine API.
- Use the platform's native windowing and accessibility conventions.
- Add CI for the supported OS and test the shell against its pinned engine
  release.
- Ship each platform independently; one platform's release must not block the
  others.

## Planned sequence

1. Keep macOS as the reference shell while the engine API stabilizes.
2. Define the minimum supported OS versions and packaging format for Windows
   and Linux.
3. Add a C-compatible engine surface (C ABI and generated bindings) so
   non-Swift shells can consume an engine release.
4. Add a Windows shell that consumes a released engine version.
5. Add a Linux shell after the backend and distribution requirements are clear.
6. Keep shared playback behavior in Vingine instead of copying it into a
   shell.

This roadmap does not claim that Windows or Linux support is available today.
