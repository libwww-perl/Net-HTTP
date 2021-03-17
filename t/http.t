use strict;
use warnings;
use Test::More;

plan tests => 38;
#use Data::Dump ();

my $CRLF = "\015\012";
my $LF   = "\012";

{
    package HTTP;
    use base 'Net::HTTP::Methods';

    my %servers = (
      a => { "/" => "HTTP/1.0 200 OK${CRLF}Content-Type: text/plain${CRLF}Content-Length: 6${CRLF}${CRLF}Hello\n",
	     "/bad1" => "HTTP/1.0 200 OK${LF}Server: foo${LF}HTTP/1.0 200 OK${LF}Content-type: text/foo${LF}${LF}abc\n",
	     "/09" => "Hello${CRLF}World!${CRLF}",
	     "/chunked"         => "HTTP/1.1 200 OK${CRLF}Transfer-Encoding: chunked${CRLF}${CRLF}0002; foo=3; bar${CRLF}He${CRLF}1${CRLF}l${CRLF}2${CRLF}lo${CRLF}0000${CRLF}Content-MD5: xxx${CRLF}${CRLF}",
	     "/chunked,chunked" => "HTTP/1.1 200 OK${CRLF}Transfer-Encoding: chunked${CRLF}Transfer-Encoding: chunked${CRLF}${CRLF}0002; foo=3; bar${CRLF}He${CRLF}1${CRLF}l${CRLF}2${CRLF}lo${CRLF}0000${CRLF}Content-MD5: xxx${CRLF}${CRLF}",
	     "/head" => "HTTP/1.1 200 OK${CRLF}Content-Length: 16${CRLF}Content-Type: text/plain${CRLF}${CRLF}",
	     "/colon-header" => "HTTP/1.1 200 OK${CRLF}Content-Type: text/plain${CRLF}Content-Length: 6${CRLF}Bad-Header: :foo${CRLF}${CRLF}Hello\n",
	   },
    );

    sub http_connect {
	my($self, $cnf) = @_;
	my $server = $servers{$cnf->{PeerAddr}} || return undef;
	${*$self}{server} = $server;
	${*$self}{read_chunk_size} = $cnf->{ReadChunkSize};
	return $self;
    }

    sub print {
	my $self = shift;
	#Data::Dump::dump("PRINT", @_);
	my $in = shift;
	my($method, $uri) = split(' ', $in);

	my $out;
	if ($method eq "TRACE") {
	    my $len = length($in);
	    $out = "HTTP/1.0 200 OK${CRLF}Content-Length: $len${CRLF}" .
                   "Content-Type: message/http${CRLF}${CRLF}" .
                   $in;
	}
        else {
	    $out = ${*$self}{server}{$uri};
	    $out = "HTTP/1.0 404 Not found${CRLF}${CRLF}" unless defined $out;
	}

	${*$self}{out} .= $out;
	return 1;
    }

    sub sysread {
	my $self = shift;
	#Data::Dump::dump("SYSREAD", @_);
	my $length = $_[1];
	my $offset = $_[2] || 0;

	if (my $read_chunk_size = ${*$self}{read_chunk_size}) {
	    $length = $read_chunk_size if $read_chunk_size < $length;
	}

	my $data = substr(${*$self}{out}, 0, $length, "");
	return 0 unless length($data);

	$_[0] = "" unless defined $_[0];
	substr($_[0], $offset) = $data;
	return length($data);
    }

    # ----------------

    sub request {
	my($self, $method, $uri, $headers, $opt) = @_;
	$headers ||= [];
	$opt ||= {};

	my($code, $message, @h);
	my $buf = "";
	eval {
	    $self->write_request($method, $uri, @$headers) || die "Can't write request";
	    ($code, $message, @h) = $self->read_response_headers(%$opt);

	    my $tmp;
	    my $n;
	    while ($n = $self->read_entity_body($tmp, 32)) {
		#Data::Dump::dump($tmp, $n);
		$buf .= $tmp;
	    }

	    push(@h, $self->get_trailers);

	};

	my %res = ( code => $code,
		    message => $message,
		    headers => \@h,
		    content => $buf,
		  );

	if ($@) {
	    $res{error} = $@;
	}

	return \%res;
    }
}

# Start testing
my $h;
my $res;

$h = HTTP->new(Host => "a", KeepAlive => 1) || die;
$res = $h->request(GET => "/");

#Data::Dump::dump($res);

is($res->{code}, 200);
is($res->{content}, "Hello\n");

$res = $h->request(GET => "/404");
is($res->{code}, 404);

$res = $h->request(TRACE => "/foo");
is($res->{code}, 200);
is($res->{content}, "TRACE /foo HTTP/1.1${CRLF}Keep-Alive: 300${CRLF}Connection: Keep-Alive${CRLF}Host: a${CRLF}${CRLF}");

# try to turn off keep alive
$h->keep_alive(0);
$res = $h->request(TRACE => "/foo");
is($res->{code}, "200");
is($res->{content}, "TRACE /foo HTTP/1.1${CRLF}Connection: close${CRLF}Host: a${CRLF}${CRLF}");

# try a bad one
# It's bad because 2nd 'HTTP/1.0 200' is illegal. But passes anyway if laxed => 1.
$res = $h->request(GET => "/bad1", [], {laxed => 1});
is($res->{code}, "200");
is($res->{message}, "OK");
is("@{$res->{headers}}", "Server foo Content-type text/foo");
is($res->{content}, "abc\n");

$res = $h->request(GET => "/bad1");
like($res->{error}, qr/Bad header/);
ok(!$res->{code});
$h = undef;  # it is in a bad state now

$h = HTTP->new("a") || die;  # reconnect
$res = $h->request(GET => "/09", [], {laxed => 1});
is($res->{code}, "200");
is($res->{message}, "Assumed OK");
is($res->{content}, "Hello${CRLF}World!${CRLF}");
is($h->peer_http_version, "0.9");

$res = $h->request(GET => "/09");
like($res->{error}, qr/^Bad response status line: 'Hello'/);
$h = undef;  # it's in a bad state again

$h = HTTP->new(Host => "a", KeepAlive => 1, ReadChunkSize => 1) || die;  # reconnect
$res = $h->request(GET => "/chunked");
is($res->{code}, 200);
is($res->{content}, "Hello");
is("@{$res->{headers}}", "Transfer-Encoding chunked Content-MD5 xxx");

# once more
$res = $h->request(GET => "/chunked");
is($res->{code}, "200");
is($res->{content}, "Hello");
is("@{$res->{headers}}", "Transfer-Encoding chunked Content-MD5 xxx");

# Test bogus headers. Chunked appearing twice is illegal, but happens anyway sometimes. [RT#77240]
$res = $h->request(GET => "/chunked,chunked");
is($res->{code}, "200");
is($res->{content}, "Hello");
is("@{$res->{headers}}", "Transfer-Encoding chunked Transfer-Encoding chunked Content-MD5 xxx");

# test head
$res = $h->request(HEAD => "/head");
is($res->{code}, "200");
is($res->{content}, "");
is("@{$res->{headers}}", "Content-Length 16 Content-Type text/plain");

$res = $h->request(GET => "/");
is($res->{code}, "200");
is($res->{content}, "Hello\n");

$h = HTTP->new(Host => undef, PeerAddr => "a", );
$h->http_version("1.0");
ok(!defined $h->host);
$res = $h->request(TRACE => "/");
is($res->{code}, "200");
is($res->{content}, "TRACE / HTTP/1.0\r\n\r\n");

# check that headers with colons at the start of values don't break
$res = $h->request(GET => '/colon-header');
is("@{$res->{headers}}", "Content-Type text/plain Content-Length 6 Bad-Header :foo");

require Net::HTTP;
eval {
    $h = Net::HTTP->new;
};
print "# $@";
ok($@);

$@ = '';
eval {
    $h = HTTP->new(
	PeerAddr	=> 0,
	PeerPort	=> 5000,
	Proto		=> 'tcp',
    );
};
print '# $@ is ', $@ ? $@ : "''\n";
ok(!$@);
