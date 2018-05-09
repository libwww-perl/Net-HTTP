BEGIN {
  if ( $ENV{NO_NETWORK_TESTING} ) {
    print "1..0 # SKIP Live tests disabled due to NO_NETWORK_TESTING\n";
    exit;
  }
  eval {
        require IO::Socket::INET;
        my $s = IO::Socket::INET->new(
            PeerHost => "httpbin.org:80",
            Timeout  => 5,
        );
        die "Can't connect: $@" unless $s;
  };
  if ($@) {
        print "1..0 # SKIP Can't connect to httpbin.org\n";
        print $@;
        exit;
  }
}

use strict;
use warnings;
use Test::More;
use Net::HTTP;

# Attempt to verify that RT#112313 (Hang in my_readline() when keep-alive => 1 and $reponse_size % 1024 == 0) is fixed

# To do that, we need responses (headers + body) that are even multiples of 1024 bytes. So we
# iterate over the same URL, trying to grow the response size incrementally...

# There's a chance this test won't work if, for example, the response body grows by one byte while
# the Content-Length also rolls over to one more digit, thus increasing the total response by two
# bytes.

# So, we check that the reponse growth is only one byte after each iteration and also test multiple
# times across the 1024, 2048 and 3072 boundaries...


sub try
{
    my $n = shift;

    # Need a new socket every time because we're testing with Keep-Alive...
    my $s = Net::HTTP->new(
        Host            => "httpbin.org",
        KeepAlive       => 1,
        PeerHTTPVersion => "1.1",
    ) or die "$@";

    $s->write_request(GET => '/headers',
        'User-Agent' => "Net::HTTP - $0",
        'X-Foo'      => ('x' x $n),
    );

    # Wait until all data is probably available on the socket...
    sleep 1;

    my ($code, $mess, @headers) = $s->read_response_headers();

    # XXX remove X-Processed-Time header
    for my $i (0..$#headers) {
        if ($headers[$i] eq 'X-Processed-Time') {
            splice @headers, $i, 2;
            last;
        }
    }

    my $body = '';
    while ($s->read_entity_body(my $buf, 1024))
    {
        $body .= $buf;
    }

    # Compute what is probably the total response length...
    my $total_len = length(join "\r\n", 'HTTP/1.1', "$code $mess", @headers, '', $body) - 1;

    # diag("$n - $code $mess => $total_len");
    # diag(join "\r\n", 'HTTP/1.1', "$code $mess", @headers, '', $body);

    $code == 200
        or die "$code $mess";

    return $total_len;
}

my $timeout = 15;
my $wiggle_room = 3;

local $SIG{ALRM} = sub { die 'timeout' };

my $base_len = try(1);
ok($base_len < 1024, "base response length is less than 1024: $base_len");

for my $kb (1024, 2048, 3072)
{
    my $last;

    # Calculate range that will take us across the 1024 boundary...
    for my $n (($kb - $base_len - $wiggle_room) .. ($kb - $base_len + $wiggle_room))
    {
        my $len = -1;

        eval {
            alarm $timeout;
            $len = try($n);
        };

        ok(!$@, "ok for n $n -> response length $len")
            or diag("error: $@");

        # Verify that response length only increased by one since the whole test rests on that assumption...
        is($len - $last, 1, 'reponse length increased by 1') if $last;

        $last = $len;
    }
}

done_testing();
