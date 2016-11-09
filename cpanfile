requires "Carp" => "0";
requires "Compress::Raw::Zlib" => "0";
requires "IO::Socket" => "0";
requires "IO::Socket::INET" => "0";
requires "IO::Socket::INET6" => "0";
requires "IO::Socket::IP" => "0";
requires "IO::Socket::SSL" => "0";
requires "IO::Uncompress::Gunzip" => "0";
requires "Net::SSL" => "0";
requires "Symbol" => "0";
requires "URI" => "0";
requires "base" => "0";
requires "perl" => "5.006002";
requires "strict" => "0";
requires "vars" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "Data::Dumper" => "0";
  requires "IO::Select" => "0";
  requires "Socket" => "0";
  requires "Test::More" => "0";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'configure' => sub {
  suggests "JSON::PP" => "2.27300";
};

on 'develop' => sub {
  requires "Test::CPAN::Changes" => "0.19";
};
