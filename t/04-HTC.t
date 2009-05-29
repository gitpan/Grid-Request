#!/usr/bin/perl

use strict;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use Log::Log4perl;
use Test::More tests => 22;

# Set up the logger specification through the conf file
Log::Log4perl->init("$Bin/testlogger.conf");

# Can we "use" the module?
BEGIN {
  use_ok('Grid::Request::HTC');
}
my @methods = qw(new debug project);

can_ok( "Grid::Request::HTC", @methods); 

foreach my $method (@methods) {
    can_ok('Grid::Request::HTC', $method);
}

{ # Since Grid::Request::HTC does not implement _init, but leaves it to
  # sub-classes, we jump into the package and override this behavior.
  package Grid::Request::HTC;
  sub _init {
     return 1;
  }
} 

my $h = Grid::Request::HTC->new;

my %levels = ( debug => 5,
               info  => 4,
               warn  => 3,
               error => 2,
               fatal => 1,
             );
my %names = reverse %levels;

# Test the integer debug levels.
foreach my $i ( sort values %levels ) {
    $h->debug($i);
    is($h->debug, $i, "Test numeric debug level $i.");
}

# Test the lower case debug level names.
foreach my $i ( sort keys %names ) {
    $h->debug($names{$i});
    is($h->debug, $i, "Test string debug level $names{$i}.");
}

# Test the upper case debug level names.
foreach my $i ( sort keys %names ) {
    my $name = uc($names{$i});
    $h->debug($name);
    is($h->debug, $i, "Test string debug level $name.");
}

# Test the project method.
$h->project("real_project");
is($h->project, "real_project", "Get project name.");
$h->project("bogus_project");
is($h->project, "bogus_project", "Set project name.");
