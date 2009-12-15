#!/usr/bin/perl

# $Id: 19-name.t 10901 2008-05-01 20:21:28Z victor $

# Test if the API supports the naming of commands.

use strict;
use FindBin qw($Bin);
use File::Basename;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 3;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $name = "drmaaname";

my $htc = Grid::Request->new( project => $project );
$htc->command("/bin/echo");
$htc->name($name);

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got a single id from submit_and_wait().");

my $id = $ids[0];

# TODO: From here down, the logic to determine if setting the
# name really worked, is DRM dependent, specifically SGE dependent.
# Skip the tests if we are not using SGE.
my $config_file = Grid::Request::HTC->config();
my $config = Config::IniFiles->new(-file => $config_file);
my $grid_type = $config->val("request", "drm");

SKIP: {
    my $why = "The configured grid type is NOT 'SGE'.";
    my $skip = lc($grid_type) ne "sge";
    skip $why, 2 if $skip;

    # SGE exhibits a lag between the time the job finishes (per drmaa)
    # and the time the data about the job is available to qacct. We
    # therefore poll and wait for the results to be available.
    my $ready = wait_for_qacct($id);

    if ($ready) {
        my $qacct = `qacct -j $id`;
        my @q_output = split(/\n/, $qacct);
        my @name = grep { m/jobname/ } @q_output;
        ok(scalar(@name) == 1, "Got only one line with job name.");
        my $qacct_name_line = $name[0];
        chomp($qacct_name_line);
        my @out = split(/\s/, $qacct_name_line);
        my $out_name = $out[-1];
        is($out_name, $name, "Job got the correct name.");
    } else {
        print STDERR "Unable to query results of job using qacct.\n";
        exit 1;
    }
}

sub wait_for_qacct {
    my $id = shift;
    sleep 1;
    my $ready = 0;
    for my $attempt qw(1 2 3 4) {
        sleep $attempt;
        system("qacct -j $id 1>/dev/null 2>/dev/null");

        my $exit_value = $? >> 8;
        if ($exit_value == 0) {
            $ready = 1;
            last;
        }
    }
    return $ready;
}
