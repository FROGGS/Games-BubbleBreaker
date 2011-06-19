use strict;
use warnings;
use Time::HiRes;
use Test::Most 'bail';

my $time                   = Time::HiRes::time;
$ENV{'BUBBLEBREAKER_TEST'} = 1;

is( system("$^X bin/bubble-breaker.pl"), 0, 'bubble-breaker ran ' . (Time::HiRes::time - $time) . ' seconds' );

pass 'Are we still alive? Checking for segfaults';

done_testing();
