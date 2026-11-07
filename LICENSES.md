# Third-party licences

`vidp.app` ships prebuilt copies of libmpv, FFmpeg and their dependencies in
`Contents/Frameworks/`, so the app installs and runs without a separate
`brew install mpv`. Those binaries remain the work of their own authors and are
covered by their own licences, reproduced or referenced below.

This file is informational. The authoritative licence text for each library is
the one shipped in its own source distribution.

## Copyleft

These are **copyleft** licences. Bundling them makes the distributed `vidp.app`
a combined work, so the corresponding source for the build must remain
available. `vidp`'s own source is public at <https://github.com/vidp-labs/vidp>,
and every bundled library's source is obtainable from its upstream project.

| Library | Licence | Upstream |
|---|---|---|
| rubberband | **GPL-2.0-or-later** | <https://github.com/breakfastquay/rubberband> |
| libplacebo | LGPL-2.1-or-later | <https://code.videolan.org/videolan/libplacebo> |
| libmpv | LGPL-2.1-or-later (client API) | <https://mpv.io> |
| ffmpeg (libav\*, libsw\*) | LGPL-2.1-or-later (this build) | <https://ffmpeg.org> |
| libbluray | LGPL-2.1-or-later | <https://code.videolan.org/videolan/libbluray> |
| glib-2.0 | LGPL-2.1-or-later | <https://gitlab.gnome.org/GNOME/glib> |
| fribidi | LGPL-2.1-or-later | <https://github.com/fribidi/fribidi> |
| x264 | GPL-2.0-or-later (see note) | <https://code.videolan.org/videolan/x264> |
| x265 | GPL-2.0-or-later | <https://bitbucket.org/multicoreware/x265_git> |
| mp3lame | LGPL-2.0 | <https://lame.sourceforge.io/> |
| mpg123 | LGPL-2.1 | <https://www.mpg123.de/> |
| libudfread | LGPL-2.1+ | <https://code.videolan.org/videolan/libudfread> |
| libunibreak | LGPL-2.1+ | <https://github.com/adah1972/libunibreak> |

`rubberband` is the binding constraint: GPL-2.0-or-later in the closure means
the distributed app as a whole is offered under GPL terms. The Homebrew `ffmpeg`
build linked here is the LGPL configuration, so it adds no further restriction
beyond rubberband's.

Note: `x264` and `x265` are GPL-2.0-or-later, which independently places this
bundle under GPL terms regardless of the FFmpeg build's configuration. They are
present because `libavcodec` links the encoders; this app never invokes them.

## Permissive

BSD-3-Clause, ISC, MIT, Zlib and similar — attribution only, no effect on how
you may use or redistribute this app.

| Library | Licence |
|---|---|
| libarchive | BSD-2-Clause |
| libass | ISC |
| mujs | ISC |
| jpeg-turbo (libjpeg) | BSD-3-Clause / IJG |
| libpng | PNG Reference Library License (libpng) |
| little-cms2 (liblcms2) | MIT |
| luajit | MIT |
| uchardet | MIT |
| harfbuzz | MIT (Old Style) |
| freetype | FTL (BSD-style) / GPL-2.0 dual |
| dav1d | BSD-2-Clause |
| libvpx | BSD-3-Clause |
| SvtAv1Enc | BSD-3-Clause |
| libvmaf | BSD-3-Clause |
| libshaderc | Apache-2.0 |
| vulkan-loader | Apache-2.0 |
| zlib | zlib |
| zstd | BSD-3-Clause |
| LZ4 (liblz4) | BSD-2-Clause |
| graphite2 | MIT |
| opus | BSD-3-Clause |
| libsamplerate | BSD-2-Clause |

## Determining what is actually bundled

The list above covers the known closure. To regenerate it from a built app:

```sh
ls vidp.app/Contents/Frameworks/*.dylib | sed 's/.*\/lib//; s/\.dylib//'
```

Exact versions are those resolved by `brew --prefix mpv` at build time and
recorded in the release tag for a given `vidp` version.
