use strict;
use warnings;

use Kanx2tanx3a::Keijibann;
use Test::More tests => 2;
use Plack::Test;
use HTTP::Request::Common;

my $app = Kanx2tanx3a::Keijibann->to_app;
is( ref $app, 'CODE', 'Got app' );

my $test = Plack::Test->create($app);
my $res  = $test->request( GET '/' );

ok( $res->is_success, '[GET /] successful' );
