# Third-party licences

`vidp.app` ships prebuilt copies of libmpv, FFmpeg and their dependencies in
`Contents/Frameworks/`, so the app installs and runs without a separate
`brew install mpv`. Those binaries remain the work of their own authors and are
covered by their own licences, reproduced or referenced below.

This file records the third-party licence notices and obligations for the
distributed app. The authoritative licence text for each library is the one
provided by its own source distribution.

The actual GPL-3.0 and LGPL-2.1 texts used by the bundled components are
included in the `licenses/` directory and copied into each app bundle. On every
release, `scripts/build.sh` also copies each bundled Homebrew package's
root-level licence and notice files into
`Contents/Resources/licenses/<package>/` and records the resolved package
versions in `Contents/Resources/licenses/VERSIONS.txt`. The corresponding Vidp
source and build scripts are available from the matching release tag in this
repository. Source for third-party components is available from the upstream
links below and under the written [source offer](SOURCE-OFFER.md) for the GPL-
and LGPL-licensed components.

## Copyleft

These are **copyleft** licences. Bundling them makes the distributed `vidp.app`
a combined work, so the corresponding source for the build must remain
available. `vidp`'s own source is public at <https://github.com/vidplabs/vidp>,
and every bundled library's source is obtainable from its upstream project.

| Library | Licence | Upstream |
|---|---|---|
| rubberband | **GPL-2.0-or-later** | <https://github.com/breakfastquay/rubberband> |
| libplacebo | LGPL-2.1-or-later | <https://code.videolan.org/videolan/libplacebo> |
| libmpv | LGPL-2.1-or-later (client API) | <https://mpv.io> |
| ffmpeg (libav\*, libsw\*) | **GPL-3.0-or-later** (Homebrew build) | <https://ffmpeg.org> |
| libbluray | LGPL-2.1-or-later | <https://code.videolan.org/videolan/libbluray> |
| glib-2.0 | LGPL-2.1-or-later | <https://gitlab.gnome.org/GNOME/glib> |
| libintl (gettext) | LGPL-2.1-or-later | <https://www.gnu.org/software/gettext/> |
| fribidi | LGPL-2.1-or-later | <https://github.com/fribidi/fribidi> |
| uchardet | MPL-1.1 (file-level) | <https://www.freedesktop.org/wiki/Software/uchardet/> |
| x264 | GPL-2.0-or-later | <https://code.videolan.org/videolan/x264> |
| x265 | GPL-2.0-or-later | <https://bitbucket.org/multicoreware/x265_git> |
| mp3lame | LGPL-2.0 | <https://lame.sourceforge.io/> |
| mpg123 | LGPL-2.1 | <https://www.mpg123.de/> |
| libudfread | LGPL-2.1+ | <https://code.videolan.org/videolan/libudfread> |

`ffmpeg` is the binding constraint: the Homebrew build linked here is
GPL-3.0-or-later (`--enable-gpl --enable-version3`), so the distributed app as a
whole is offered under GPL-3.0-or-later. `rubberband`, `x264` and `x265` are
GPL-2.0-or-later, which is compatible with that outcome. `x264` and `x265` are
present because `libavcodec` links the encoders; this app never invokes them.

The GPL terms apply to the distributed combined release build as required by
the GPL. The original Vidp source license in [LICENSE](LICENSE) grants the
corresponding GPL-3.0-or-later permissions for any such combined build; it does
not remove or restrict the rights granted by the third-party licenses.

## Permissive

BSD-3-Clause, ISC, MIT, Zlib and similar — attribution only, no effect on how
you may use or redistribute this app. The full copyright and licence text for
each library is copied into `licenses/<package>/` in the app bundle.

| Library | Licence |
|---|---|
| libarchive | BSD-2-Clause |
| libass | ISC |
| mujs | ISC |
| jpeg-turbo (libjpeg) | BSD-3-Clause / IJG |
| libpng | PNG Reference Library License (libpng) |
| little-cms2 (liblcms2) | MIT |
| luajit | MIT |
| libunibreak | Zlib |
| harfbuzz | MIT (Old Style) |
| freetype | FTL (BSD-style) / GPL-2.0 dual |
| dav1d | BSD-2-Clause |
| libvpx | BSD-3-Clause |
| SvtAv1Enc | BSD-3-Clause |
| libvmaf | BSD-2-Clause-Patent |
| libshaderc | Apache-2.0 |
| vulkan-loader | Apache-2.0 |
| zstd | BSD-3-Clause |
| LZ4 (liblz4) | BSD-2-Clause |
| graphite2 | MIT |
| opus | BSD-3-Clause |
| libsamplerate | BSD-2-Clause |

`zlib` is provided by macOS (`/usr/lib/libz.1.dylib`) and is not bundled.

## Release obligations

The main obligations are:

- **GPL:** preserve the license, provide the corresponding source, and keep the
  GPL freedoms for the combined release build.
- **LGPL:** preserve the license and notices, provide the corresponding source,
  and keep the relinking rights required by the license.
- **MPL:** preserve the license and its file-level terms for covered files, make
  the covered source available, and state where it is available.
- **BSD, ISC, MIT, Zlib, Apache, and similar licenses:** preserve the required
  copyright, license, and notice text. Apache-licensed components also retain
  their applicable NOTICE and patent terms.

The exact license text and obligations for a shipped version are the ones in
the release bundle and the corresponding upstream source distribution.

## Determining what is actually bundled

The tables above list the main components; the complete list of bundled
libraries and their resolved versions is in `licenses/VERSIONS.txt` inside
each app bundle. To regenerate the list from a built app:

```sh
ls vidp.app/Contents/Frameworks/*.dylib | sed 's/.*\/lib//; s/\.dylib//'
```

The exact versions of the bundled libraries are recorded in
`licenses/VERSIONS.txt` inside each app bundle, so the corresponding source can
be identified. If you need the source, use the written offer in
[SOURCE-OFFER.md](SOURCE-OFFER.md).
