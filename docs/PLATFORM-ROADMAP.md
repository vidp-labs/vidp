# Platform Shell Roadmap

Vidp currently ships as a native macOS application. Future platform support
should add native application shells around the shared `vidp-engine` package.

## Shared layer

`vidp-engine` remains platform-neutral and owns the playback contract:

- playback commands and state;
- media metadata and track selection;
- backend events; and
- behavior that must stay consistent across applications.

Each shell pins an exact engine release. A shell upgrade to a newer engine
release is an intentional dependency change and is tested before release.

## Application shells

| Platform | Shell technology | Owns |
|---|---|---|
| macOS | Swift and AppKit | Current official Vidp app, menus, settings, packaging, and native rendering |
| Windows | C# and WinUI 3 | Windows windowing, menus, settings, packaging, and native rendering |
| Linux | GTK or Qt | Linux windowing, menus, settings, packaging, and native rendering |

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
3. Add a Windows shell that consumes a released engine version.
4. Add a Linux shell after the backend and distribution requirements are clear.
5. Keep shared playback behavior in `vidp-engine` instead of copying it into a
   shell.

This roadmap does not claim that Windows or Linux support is available today.
