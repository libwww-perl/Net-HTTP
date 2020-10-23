use strict;
use warnings;

use Test::More;

{
    $Net::HTTP::SOCKET_CLASS = 'Foo';

    require Net::HTTP;

    is $Net::HTTP::SOCKET_CLASS, 'Foo';

    is_deeply \@Net::HTTP::ISA, [qw[Foo Net::HTTP::Methods]];
}

{
    $Net::HTTPS::SSL_SOCKET_CLASS = 'Foo';

    require Net::HTTPS;

    is $Net::HTTPS::SSL_SOCKET_CLASS, 'Foo';

    is_deeply \@Net::HTTPS::ISA, [qw[Foo Net::HTTP::Methods]];
}


done_testing;
