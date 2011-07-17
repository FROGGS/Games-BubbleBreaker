#!/bin/bash

/root/staticperl mkapp BubbleBreaker-X11 --boot /root/.staticperl/perl/bin/bubble-breaker.pl --incglob 'SDL*' --strip \
-Mstrict -Mwarnings -MCwd -MTime::HiRes -MAlien::SDL -MTie::Simple -MGames::BubbleBreaker -MData::Dumper \
--add share/background.png --add share/red.png --add share/green.png --add share/yellow.png --add share/pink.png --add share/blue.png \
--staticlib aa --staticlib artsc --staticlib asound --staticlib asyncns --staticlib audio --staticlib direct --staticlib directfb \
--staticlib esd --staticlib fusion --staticlib gpm --staticlib ncurses --staticlib resolv --staticlib rt --staticlib slang \
--staticlib vga --staticlib x86 \
--staticlib SDL --staticlib SDLmain \
--staticlib z --staticlib png --staticlib tiff --staticlib jpeg --staticlib SDL_image \
--staticlib ogg --staticlib vorbis --staticlib vorbisfile --staticlib smpeg --staticlib mikmod --staticlib pulse --staticlib pulse-simple --staticlib SDL_mixer \
--staticlib freetype --staticlib SDL_ttf --staticlib freetype \
--staticlib SDL_gfx \
--staticlib m --staticlib crypt --staticlib stdc++

#--staticlib xcb --staticlib xcb-xlib --staticlib Xau --staticlib Xdmcp --staticlib Xi --staticlib X11 \
