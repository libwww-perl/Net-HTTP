BEGIN {
    if ( $ENV{NO_NETWORK_TESTING} ) {
        print "1..0 # SKIP Live tests disabled due to NO_NETWORK_TESTING\n";
        exit;
    }
    eval {
        require IO::Socket::INET;
        my $s = IO::Socket::INET->new(
            PeerHost => "www.neverssl.com:80",
            Timeout  => 5,
        );
        die "Can't connect: $@" unless $s;
    };
    if ($@) {
        print "1..0 # SKIP Can't connect to www.neverssl.com\n";
        print $@;
        exit;
    }
}

use strict;
use warnings;
use Test::More;
plan tests => 6;

use Net::HTTP;

my $s = Net::HTTP->new(
    Host            => "www.neverssl.com",
    KeepAlive       => 1,
    Timeout         => 15,
    PeerHTTPVersion => "1.1",
    MaxLineLength   => 512
) || die "$@";

for ( 1 .. 2 ) {
    $s->write_request(
        GET               => "/",
        'User-Agent'      => 'Mozilla/5.0',
        'Accept-Language' => 'no,en',
        Accept            => '*/*'
    );

    my ( $code, $mess, %h ) = $s->read_response_headers;
    print "# ----------------------------\n";
    print "# $code $mess\n";
    for ( sort keys %h ) {
        print "# $_: $h{$_}\n";
    }
    print "#\n";

    my $buf;
    while (1) {
        my $tmp;
        my $n = $s->read_entity_body( $tmp, 20 );
        last unless $n;
        $buf .= $tmp;
    }
    $buf =~ s/\r//g;

    ok( $code == 302 || $code == 200, 'success' );
    like( $h{'Content-Type'}, qr{text/html} );
    like( $buf, qr{</html>}i );
}
