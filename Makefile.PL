#!perl -w

require 5.006002;
use strict;
use ExtUtils::MakeMaker;
use Getopt::Long qw(GetOptions);
GetOptions(\my %opt, 'live-tests',) or warn "Usage: $0 [--live-tests]\n";

my $flag_file = "t/LIVE_TESTS";
if ($opt{"live-tests"}) {
    open(my $fh, ">", $flag_file) || die;
}
else {
    unlink($flag_file);
}

WriteMakefile(
    NAME => 'Net::HTTP',
    VERSION_FROM => 'lib/Net/HTTP.pm',
    ABSTRACT_FROM => 'lib/Net/HTTP.pm',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    LICENSE => "perl",
    MIN_PERL_VERSION => 5.006002,
    PREREQ_PM => {
	'IO::Socket::INET' => 0,
	'IO::Select' => 0,
        'Compress::Raw::Zlib' => 0,
        'IO::Compress::Gzip' => 0,
        'URI' => 0,
    },
    META_MERGE => {
        recommends => {
            'IO::Socket::SSL' => "1.38",
        },
	resources => {
            repository => 'http://github.com/libwww-perl/net-http',
	    MailingList => 'mailto:libwww@perl.org',
        }
    },
);


BEGIN {
    # compatibility with older versions of MakeMaker
    my $developer = -f ".gitignore";
    my %mm_req = (
        LICENCE => 6.31,
        META_MERGE => 6.45,
        META_ADD => 6.45,
        MIN_PERL_VERSION => 6.48,
    );
    undef(*WriteMakefile);
    *WriteMakefile = sub {
        my %arg = @_;
        for (keys %mm_req) {
            unless (eval { ExtUtils::MakeMaker->VERSION($mm_req{$_}) }) {
                warn "$_ $@" if $developer;
                delete $arg{$_};
            }
        }
        ExtUtils::MakeMaker::WriteMakefile(%arg);
    };
}
