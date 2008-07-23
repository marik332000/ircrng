#!/usr/bin/perl

use warnings;
use strict;

use Net::IRC;
use List::Util  qw/ reduce /;
use Time::HiRes qw/ gettimeofday tv_interval /;

# Select servers
my @servers = qw( #ubuntu #gentoo #debian ##linux ##php #bash #math
                  ##c++ ##Perl #python ##c #git #freenode #kde );

# Init RNG
my $last_time = gettimeofday ();
my $last_diff = 0;
my $last_bit = undef;
my @bits = ();

# Setup IRC
warn "Connecting...\n";
my $irc = new Net::IRC;
my $conn = $irc->newconn(Nick => 'Guest24331',
		      Server  => 'irc.freenode.net',
		      Port    =>  6667,
		      Ircname => 'Some witty comment.')
    or die "Cannot connect!\n";

# What to do when the bot successfully connects.
sub on_connect {
    my $self = shift;
    reg_event ();
    for (@servers) {
	warn "Joining $_\n";
	$self->join($_);
	sleep(1);
    }
}

# Register an event
sub reg_event {
    my ($self, $event) = @_;    
    
    my $new_time = gettimeofday();
    my $new_diff = $new_time - $last_time;
    
    if ($last_diff == 0) {
	$last_diff = $new_diff;	
	return;
    }
    
    push_bit(1) if ($last_diff > $new_diff);
    push_bit(0) if ($last_diff < $new_diff);
    
    $last_time = $new_time;
    $last_diff = $new_diff;
}

# Push a bit into the filter. Look at bits in pairs to remove bias.
sub push_bit {
    my $bit = shift;
    
    if (defined $last_bit) {
	if ($last_bit != $bit) {
	    push (@bits, $last_bit);
	    warn "@bits\n";
	    if ($#bits >= 7) {
		no warnings 'once';
		$| = 1;
		#print pack ("B*", join('', @bits));
		print reduce {2*$a+$b} @bits;
		print "\n";
		@bits = ();
	    }
	}
	$last_bit = undef;
    } else {
	$last_bit = $bit;
    }
}

$conn->add_handler('msg',    \&reg_event);
$conn->add_handler('public', \&reg_event);
$conn->add_handler('join',   \&reg_event);
$conn->add_handler('part',   \&reg_event);
$conn->add_global_handler([ 251,252,253,254,302,255 ], \&reg_event);
$conn->add_global_handler('disconnect', \&reg_event);
$conn->add_global_handler(376, \&on_connect);
warn "starting...\n";
$irc->start;
