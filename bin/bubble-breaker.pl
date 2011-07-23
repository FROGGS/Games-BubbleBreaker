#!perl

use strict;
use warnings;

use Time::HiRes;

use SDL;
use SDL::Event;
use SDL::Events;
use SDL::Mouse;
use SDL::Video;
use SDL::VideoInfo;
use SDL::RWOps;
use SDL::Surface;
use SDLx::App;
use SDLx::Surface;
use SDLx::SFont;

print STDOUT <<OUT;
**************************** Information **********************************
Click on a bubble to select all contiguous bubbles of same color and double
click to destroy them. The more bubbles you destroy at once the more points
you get.

To quit press ESC.

Have fun!
***************************************************************************
OUT

$ENV{SDL_VIDEO_CENTERED} = 'center';
my $app                  = SDLx::App->new( width => 800, height => 352,
                                           depth => 32, title => "BubbleBreaker", color => 0x000000FF,
                                           flags => SDL_SWSURFACE,
                                           eoq => 1, delay => 20 );
my $HOME                 = "$ENV{HOME}/.bubble-breaker";
mkdir($HOME) unless -d $HOME;
my $last_click           = Time::HiRes::time;
my $font_white           = static::find('share/font_white.png');
my $font_blue            = static::find('share/font_blue.png');
my $sfont_white          = SDLx::SFont->new( SDL::RWOps->new_const_mem( $font_white, length $font_white) );
my $sfont_blue           = SDLx::SFont->new( SDL::RWOps->new_const_mem( $font_blue,  length $font_blue) );

# ingame states
my $points      = 0;
my @controls    = ();
my %balls       = ();
my $neighbours  = {};
my @highscore   = ();

# images
my $background = static::find('share/background.png');
   $background = SDLx::Surface->new( surface => SDL::Image::load_PNG_rw( SDL::RWOps->new_const_mem( $background, length $background ) ) );
my $red        = static::find('share/red.png');
my $green      = static::find('share/green.png');
my $yellow     = static::find('share/yellow.png');
my $pink       = static::find('share/pink.png');
my $blue       = static::find('share/blue.png');
my @balls      = (
    SDLx::Surface->new( surface => SDL::Image::load_PNG_rw( SDL::RWOps->new_const_mem( $red,    length $red ) ) ),
    SDLx::Surface->new( surface => SDL::Image::load_PNG_rw( SDL::RWOps->new_const_mem( $green,  length $green ) ) ),
    SDLx::Surface->new( surface => SDL::Image::load_PNG_rw( SDL::RWOps->new_const_mem( $yellow, length $yellow ) ) ),
    SDLx::Surface->new( surface => SDL::Image::load_PNG_rw( SDL::RWOps->new_const_mem( $pink,   length $pink ) ) ),
    SDLx::Surface->new( surface => SDL::Image::load_PNG_rw( SDL::RWOps->new_const_mem( $blue,   length $blue ) ) )
);

new_round();

$app->add_show_handler(  sub { $app->update } );
$app->add_event_handler( sub {
    my $e = shift;

    if($e->type == SDL_KEYDOWN && $e->key_sym == SDLK_ESCAPE) {
        $app->stop;
    }

    elsif ($e->type == SDL_MOUSEBUTTONDOWN && $e->button_button == SDL_BUTTON_LEFT) {
        my $time = Time::HiRes::time;
        if ($time - $last_click < 0.3) {
            for(@controls) {
                if($_->[0] < $e->button_x && $e->button_x < $_->[2]
                && $_->[1] < $e->button_y && $e->button_y < $_->[3]) {
                    remove_selection($neighbours);
                    $neighbours = {};

                    $background->blit( $app );
                    for my $x (0..14) {
                        for my $y (0..11) {
                            if( defined $balls{$x}{$y} ) {
                                $balls[$balls{$x}{$y}]->blit( $app, undef, [ 280 + $x * 25, 30 + $y * 25, 0, 0] );
                            }
                        }
                    }
                    SDLx::SFont::print_text($app, 250 - SDLx::SFont::SDL_TEXTWIDTH( $points ), 160, $points );
                    draw_highscore();

                    last;
                }
            }
        }
        elsif( 20 < $e->button_x && $e->button_x < 220
           && 235 < $e->button_y && $e->button_y < 280) {
            new_round();
        }
        else {
            $background->blit( $app );
            for my $x (0..14) {
                for my $y (0..11) {
                    if( defined $balls{$x}{$y} ) {
                        $balls[$balls{$x}{$y}]->blit( $app, undef, [ 280 + $x * 25, 30 + $y * 25, 0, 0] );
                    }
                }
            }
            SDLx::SFont::print_text($app, 250 - SDLx::SFont::SDL_TEXTWIDTH( $points ), 160, $points );
            draw_highscore();

            for(@controls) {
                if($_->[0] < $e->button_x && $e->button_x < $_->[2]
                && $_->[1] < $e->button_y && $e->button_y < $_->[3]
                && defined $balls{$_->[4]}{$_->[5]}) {
                    $neighbours = {};
                    neighbours($_->[4], $_->[5], $neighbours);
                    draw_shape($neighbours);
                    last;
                }
            }
        }
        $last_click = $time;
    }
} );

$app->run();

sub new_round {
    $points     = 0;
    @controls   = ();
    %balls      = ();
    $neighbours = {};
    @highscore  = ();

    $background->blit( $app );
    SDLx::SFont::print_text($app, 250 - SDLx::SFont::SDL_TEXTWIDTH( $points ), 160, $points );
    draw_highscore();

    for my $x (0..14) {
        for my $y (0..11) {
            my $color = int(rand(5));
            $balls[$color]->blit( $app, undef, [ 280 + $x * 25, 30 + $y * 25, 0, 0] );
            push(@controls, [ 278 + $x * 25, 28 + $y * 25, 303 + $x * 25, 53 + $y * 25, $x, $y]);
            $balls{$x}{$y} = $color;
        }
    }
}

sub draw_highscore {
    unless( scalar @highscore ) {
        if(!-e "$HOME/highscore.dat" && open(FH, ">$HOME/highscore.dat")) {
            print(FH "42\n");
            close(FH);
        }

        if(open(FH, "<$HOME/highscore.dat")) {
            @highscore = map{/(\d+)/; $1} <FH>;
            close(FH);
        }
    }

    my $line         = 0;
    my @score        = reverse sort {$a <=> $b} (@highscore, $points);
    my $points_drawn = 0;
    while($line < 10 && $score[$line]) {
        if($score[$line] == $points && !$points_drawn) {
            $sfont_white->use;
            $points_drawn = 1;
        }
        SDLx::SFont::print_text($app, 780 - SDLx::SFont::SDL_TEXTWIDTH( $score[$line] ), 60 + 25 * $line, $score[$line++] );
        $sfont_blue->use;
    }

    if(open(FH, ">$HOME/highscore.dat")) {
        print(FH "$_\n") for @score;
        close(FH);
    }
}

sub remove_selection {
    my $n = shift;

    my $count = 0;
    for my $x (keys %$n) {
        for my $y (keys %{$n->{$x}}) {
            $balls{$x}{$y} = undef;
            $count++;
        }
    }

    return unless $count > 1;

    $points += int(5 * $count + 1.5**$count);

    for my $x (0..14) {
        for my $y (0..11) {
            $y = 11 - $y;
            unless( defined $balls{$x}{$y} ) {
                my $above = $y - 1;
                while(!defined $balls{$x}{$above} && $above > 0) {
                    $above--;
                }

                $balls{$x}{$y}     = $balls{$x}{$above};
                $balls{$x}{$above} = undef;
            }
        }
    }

    for my $x (0..7) {
        $x = 7 - $x;
        my $y = 11;
        unless( defined $balls{$x}{11} ) {
            my $left = $x - 1;
            while(!defined $balls{$left}{11} && $left > 0) {
                $left--;
            }

            for $y (0..11) {
                $y = 11 - $y;
                $balls{$x}{$y}    = $balls{$left}{$y};
                $balls{$left}{$y} = undef;
            }
        }
    }

    for my $x (7..14) {
        my $y = 11;
        unless( defined $balls{$x}{11} ) {
            my $right = $x + 1;
            while(!defined $balls{$right}{11} && $right < 14) {
                $right++;
            }

            for $y (0..11) {
                $y = 11 - $y;
                $balls{$x}{$y}     = $balls{$right}{$y};
                $balls{$right}{$y} = undef;
            }
        }
    }
}

sub draw_shape {
    my $n     = shift;
    my %lines = ();

    for my $x (keys %$n) {
        for my $y (keys %{$n->{$x}}) {
            $lines{278 + $x * 25}{28 + $y * 25}{303 + $x * 25}{28 + $y * 25}++;
            $lines{278 + $x * 25}{53 + $y * 25}{303 + $x * 25}{53 + $y * 25}++;
            $lines{278 + $x * 25}{28 + $y * 25}{278 + $x * 25}{53 + $y * 25}++;
            $lines{303 + $x * 25}{28 + $y * 25}{303 + $x * 25}{53 + $y * 25}++;
        }
    }

    for my $x1 (keys %lines) {
        for my $y1 (keys %{$lines{$x1}}) {
            for my $x2 (keys %{$lines{$x1}{$y1}}) {
                for my $y2 (keys %{$lines{$x1}{$y1}{$x2}}) {
                    if($lines{$x1}{$y1}{$x2}{$y2} == 1) {
                        $app->draw_line([$x1, $y1], [$x2, $y2], 0x153C99FF);
                    }
                }
            }
        }
    }
}

sub neighbours {
    my ($x, $y, $n) = @_;

    if(defined $balls{$x}{$y - 1} && $balls{$x}{$y - 1} == $balls{$x}{$y} && !$n->{$x}->{$y - 1}) {
        $n->{$x}->{$y}     = 1;
        $n->{$x}->{$y - 1} = 1;
        neighbours($x, $y - 1, $n);
    }
    
    if(defined $balls{$x}{$y + 1} && $balls{$x}{$y + 1} == $balls{$x}{$y} && !$n->{$x}->{$y + 1}) {
        $n->{$x}->{$y}     = 1;
        $n->{$x}->{$y + 1} = 1;
        neighbours($x, $y + 1, $n);
    }
    
    if(defined $balls{$x - 1}{$y} && $balls{$x - 1}{$y} == $balls{$x}{$y} && !$n->{$x - 1}->{$y}) {
        $n->{$x}->{$y}     = 1;
        $n->{$x - 1}->{$y} = 1;
        neighbours($x - 1, $y, $n);
    }
    
    if(defined $balls{$x + 1}{$y} && $balls{$x + 1}{$y} == $balls{$x}{$y} && !$n->{$x + 1}->{$y}) {
        $n->{$x}->{$y}     = 1;
        $n->{$x + 1}->{$y} = 1;
        neighbours($x + 1, $y, $n);
    }
}

exit 0;
