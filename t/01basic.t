#! perl -w

use Test::More tests => 9;

use FindBin;
use File::Spec;

my $instance;
BEGIN { 
    $instance = $ENV{DB2INSTANCE};
}

# first thing's first - is the instance set up properly?
my $uid = getpwnam($instance);

ok($uid, "Instance probably exists");

my $options = { Database => 'csd_test' };

SKIP: {
    skip "No instance - can't do anything", 8 unless $uid;

    require CGI::Session::DB2;
    ok(1);

    # check if database exists ...
    ok(CGI::Session::DB2->create($options));

    my $s = new CGI::Session::DB2(undef, $options);
    ok($s);
    ok($s->id());
    $s->param(
              author => 'Darin McBride',
              name => 'CGI::Session::DB2',
              version => 1
             );
    ok($s->param('author'));
    ok(!$s->expires());
    my $sid = $s->id();
    $s->flush();
    
    my $s2 = new CGI::Session::DB2($sid, $options);
    ok($s2);
    ok($s2->id() eq $sid);

    # done testing!
    system "db2 drop db " . $options->{Database};
}
