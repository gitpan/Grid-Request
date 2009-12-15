#!/usr/bin/perl

# $Id: 15-times.t 10901 2008-05-01 20:21:28Z victor $

# This script tests the functionality of the times() method

use strict;
use File::Basename;
use FindBin qw($Bin);
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 4;
use Grid::Request;
use Grid::Request::Test;
use File::Temp qw(tempdir);

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $name = basename($0);

# Create a simple shell script
my $config_file = Grid::Request::HTC->config();
unless ( -f $config_file && -r $config_file) {
    print STDERR "No configuation file at $config_file.\n";
    exit 2;
}
my $config = Config::IniFiles->new(-file => $config_file);
my $scratch = $config->val("request", "tempdir");
my $script = "${scratch}/times_count.sh";
my $tempdir = tempdir ( DIR => $scratch );

my $times = 15;
my $shell = <<"    _HERE";
#!/bin/bash

DIR=\$1
echo id:\$SGE_TASK_ID > \$DIR/\$SGE_TASK_ID
    _HERE


# Remove the script in case it's there from a previous run.
eval {
    unlink $script;
};
open(SHELL, ">", $script);
print SHELL $shell;
close(SHELL);
chmod 0755, $script;

ok(-f $script && -x $script, "Shell script created.");

# Submit a request to the DRM to run the script
my $htc = Grid::Request->new( project => $project );
$htc->command($script);
$htc->add_param($tempdir);
$htc->times($times);

my @ids = $htc->submit_and_wait();
is(scalar(@ids), $times, "Got $times ids from submit_and_wait().");

# Test if the output file was created
ok(-d $tempdir, "Temporary directory created for output.");

# Further check if the script really executed by examining the output
# directory and checking if the right number of files are present.
opendir(my $dh, $tempdir) || die "Cannot open directory $tempdir: $!";
my @files = grep { -f "$tempdir/$_" } readdir($dh);
closedir $dh;
is(scalar(@files), $times, "Output directory had output from each task.");
