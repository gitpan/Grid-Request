#!/usr/bin/perl

# $Id: 17-hosts.t 10901 2008-05-01 20:21:28Z victor $

# Test if the API supports specifying the specific host/hosts to run
# the command on.

use strict;
use FindBin qw($Bin);
use File::Basename;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 3;
use Grid::Request;

my $name = basename($0);

Log::Log4perl->init("$Bin/testlogger.conf");

my $output = "/usr/local/scratch/${name}.out";
my $host = "rlx-0-2-1";

cleanup();

my $htc = Grid::Request->new( project => "test" );
$htc->command("/bin/hostname");
$htc->output($output);
$htc->hosts($host);

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got 1 id from submit_and_wait().");

wait_for_out($output);

ok(-f $output, "Output file created.") or
   diag("Might not be visible due to NFS caching issues.");

my $line = read_first_line($output);
is($line, $host, "Job ran on the correct host.");

cleanup();


sub cleanup {
    eval {
        unlink $output;
    };
}

sub read_first_line {
    my $file = shift;
    my $line;
    eval {
        open (FILE, "<", $file) or die "Couldn't open $file for reading.";
        $line = <FILE>;
        close FILE;
    };
    chomp($line) if defined($line);
    return $line;
}

sub wait_for_out {
    my $output = shift;
    my $n=1;
    while (($n < 10 ) && (! -e $output)) {
        last if (-e $output);
        sleep $n*6;
        $n++;
    }
}
