#!/usr/bin/env/perl

use strict;
use DBI;

my $dbh = DBI->connect("dbi:SQLite:dbname=harmonies.db", "","",{ RaiseError => 1 },) or die $DBI::errstr;

my $val1 = "def";
my $val2 = "abc";
my $val3 = 14;
my $sql1 = 'select name, password from users where name = ?';
my $sql2 = 'select * from users where name = ?';
my $sql3 = "select * from users";
my $sql4 = "select * from noises where username = ?";
my $sql5 = "update noises set title = ?, text = ? where nid = ?";
my $newtitle = "newtitle";
my $newtext = "newtext";

print "before updating:\n";
my $sth = $dbh->prepare($sql3);
$sth->execute();

my @row;
while (@row = $sth->fetchrow_array) { # retrieve one row
    print join(", ", @row), "\n";
}

# # do update
# my $sth = $dbh->prepare($sql5);
# $sth->execute($newtitle, $newtext, $val3);

# print "after updating:\n";
# my $sth = $dbh->prepare($sql4);
# $sth->execute($val2);

# my @row;
# while (@row = $sth->fetchrow_array) { # retrieve one row
#     print join(", ", @row), "\n";
# }

# my $rows = $sth->rows();
# print $rows . "\n";


$dbh->disconnect();