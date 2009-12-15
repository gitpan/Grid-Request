#!/usr/bin/perl

# $Id: 20-class.t 10901 2008-05-01 20:21:28Z victor $

# Test if the API supports the class method.

use strict;
use FindBin qw($Bin);
use File::Basename;
use lib ("$Bin/../lib");
use Log::Log4perl qw(:easy);
use Test::More tests => 2;
use Grid::Request;
use Grid::Request::Test;

Log::Log4perl->init("$Bin/testlogger.conf");
my $project = Grid::Request::Test->get_test_project();

my $class = "myclass";

my $htc = Grid::Request->new( project => $project );
$htc->command("/bin/echo");
$htc->class($class);

is($htc->class(), $class, "Getter got the set value.");

my @ids = $htc->submit_and_wait();
is(scalar(@ids), 1, "Got an 1 id from submit_and_wait().");

my $id = $ids[0];
