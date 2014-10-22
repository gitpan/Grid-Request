#!/usr/bin/perl

# $Id: 23-multi-cmd-async.t 10901 2008-05-01 20:21:28Z victor $

use strict;
use File::Basename;
use FindBin qw($Bin);
use Log::Log4perl qw(:easy);
use lib "$Bin/../lib";
use Test::More tests => 7;
use Grid::Request;

Log::Log4perl->init("$Bin/testlogger.conf");

my $base = basename($0);
my $project = "test";
my $outdir = "/usr/local/scratch";
my $output1 = $outdir . "/${base}.1.out";
my $output2 = $outdir . "/${base}.2.out";

eval {
    unlink $output1;
    unlink $output2;
};
ok(! -e $output1, "Output file 1 does not exist.");
ok(! -e $output2, "Output file 2 does not exist.");


my $htc = Grid::Request->new(project => $project);
$htc->command("/bin/uname");
$htc->output($output1);
$htc->opsys("Solaris");

$htc->new_command();

$htc->command("/bin/uname");
$htc->output($output2);
$htc->opsys("Linux");

my @ids = $htc->submit_and_wait();

is(scalar(@ids), 2, "Correct number of ids from submit().");

wait_for_out($output1);
ok(-f $output1, "Output file from 1st command created.") or
    diag("Might not be visible due to NFS caching issues.");

wait_for_out($output2);
ok(-f $output2, "Output file from 2nd command created.") or
    diag("Might not be visible due to NFS caching issues.");

my $result1 = read_first_line($output1);
my $result2 = read_first_line($output2);
is($result1, "SunOS", "1st command ran on the correct architecture.");
is($result2, "Linux", "2nd command ran on the correct architecture.");

sub read_first_line {
    my $file = shift;
    my $line;
    eval {
        open (FILE, "<", $file) or die "Could not open $file for reading.";
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
