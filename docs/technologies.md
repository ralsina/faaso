# Technologies Used in FaaSO

FaaSO itself is pretty small, and that's because it uses
a ton of stuff that already exists. This page documents
what some of those things are, and why.

## Language

I used [Crystal](https://crystal-lang.org) because it's nice,
fast, has a good standard library, and is statically typed.

## Website

It's done using [Nicolino](https://github.com/ralsina/nicolino)
because I wrote it and wanted to use it. It's a static site
generator.

The theme uses [Pico CSS](https://picocss.com) which is awesome
and understandable for a non-frontender like me and *a ton* of
other things, like [Highlight.js](https://highlightjs.org/)
and [Discount](https://github.com/Orc/discount).

The videos would not be possible without [Asciinema](https://asciinema.org) and [Doitlive.](https://doitlive.readthedocs.io/)

## Platform

* Docker everywhere, because it's what I know.
* Linux, because it's really what Docker runs on.
* Alpine Linux to build the containers, because they are small.
* GitHub, for hosting the code, and building stuff, and
  the container registry, and the issue manager, and ...
* QEmu: to build cross-platform stuff.
* Caddy for the reverse proxy.
* TtyD for the terminal on a website.
* HTMX for making the frontend possible at all.

Too many things, really. It's a miracle to live in a moment where
all these cool things are there, ready to be used. I used to live
in a world where NONE OF THIS EXISTED (it was called the 80s) and
it was extremely boring.
