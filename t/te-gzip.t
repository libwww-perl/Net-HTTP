use strict;
use warnings;
use Test::More;
use Test::Needs 'Compress::Raw::Zlib', 'IO::Compress::Gzip';

plan tests => 5;

my $CRLF = "\015\012";

# A payload large enough to span many reads and to be split across several
# transfer-encoding chunks.
my $payload = join('', map { "line $_: the quick brown fox jumps over the lazy dog\n" } 1 .. 500);

my $gzipped;
IO::Compress::Gzip::gzip(\$payload, \$gzipped)
    or die "gzip failed: $IO::Compress::Gzip::GzipError";

# Encode the gzip stream as several chunks so decoding must happen
# incrementally across chunk boundaries.
my $chunked = '';
my $offset = 0;
while ($offset < length($gzipped)) {
    my $piece = substr($gzipped, $offset, 7);
    $offset += length($piece);
    $chunked .= sprintf('%x', length($piece)) . $CRLF . $piece . $CRLF;
}
$chunked .= '0' . $CRLF . $CRLF;

our $response =
    "HTTP/1.1 200 OK${CRLF}Transfer-Encoding: gzip, chunked${CRLF}${CRLF}" . $chunked;

{
    package HTTP;
    use base 'Net::HTTP::Methods';

    sub http_connect {
	my ($self, $cnf) = @_;
	${*$self}{out} = $main::response;
	${*$self}{read_chunk_size} = $cnf->{ReadChunkSize};
	return $self;
    }

    sub print { return 1 }

    sub sysread {
	my $self = shift;
	my $length = $_[1];
	my $offset = $_[2] || 0;

	if (my $read_chunk_size = ${*$self}{read_chunk_size}) {
	    $length = $read_chunk_size if $read_chunk_size < $length;
	}

	my $data = substr(${*$self}{out}, 0, $length, '');
	return 0 unless length($data);

	$_[0] = '' unless defined $_[0];
	substr($_[0], $offset) = $data;
	return length($data);
    }
}

my $h = HTTP->new(Host => 'gzip', KeepAlive => 1, ReadChunkSize => 5) || die;
$h->write_request('GET', '/');
my ($code) = $h->read_response_headers;
is($code, 200, 'response parsed');

my $content = '';
my $max_return = 0;
my $length_always_truthful = 1;
my $tmp;
my $n;
# read_entity_body returns -1 as a "read again" sentinel when a decoder has
# consumed input but not yet produced output; only positive returns carry bytes.
while ($n = $h->read_entity_body($tmp, 40)) {
    if ($n > 0) {
	# A body-of-any-size returning a stringified reference (~19 bytes)
	# instead of the real decoded bytes would show up here as a length that
	# does not match the bytes actually appended to the buffer.
	$length_always_truthful = 0 if $n != length($tmp);
	$max_return = $n if $n > $max_return;
	$content .= $tmp;
    }
}

is($content, $payload, 'gzip transfer-encoding decoded correctly');
ok($length_always_truthful, 'returned length matches the decoded bytes on every read');
ok($max_return > 0, 'at least one read produced decoded bytes');

# No single read yielded the whole body: decoding streams incrementally rather
# than buffering the entire response and releasing it in one go.
cmp_ok($max_return, '<', length($payload), 'body delivered incrementally, not all at once');
