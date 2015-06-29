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

my $developer = -f '.gitignore';

my %WriteMakefileArgs = (
    NAME => 'Net::HTTP',
    VERSION_FROM => 'lib/Net/HTTP.pm',
    ABSTRACT_FROM => 'lib/Net/HTTP.pm',
    AUTHOR => 'Gisle Aas <gisle@activestate.com>',
    LICENSE => 'perl_5',
    MIN_PERL_VERSION => 5.006002,
    PREREQ_PM => {
        'IO::Socket::INET' => 0,
        'IO::Select' => 0,
        'Compress::Raw::Zlib' => 0,
        'IO::Uncompress::Gunzip' => 0,
        'URI' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        dynamic_config => 0,
        prereqs => {
            runtime => {
                recommends => {
                    'IO::Socket::SSL' => "1.38",
                },
            },
        },
        resources => {
            repository => {
                url => 'https://github.com/libwww-perl/net-http.git',
                web => 'https://github.com/libwww-perl/net-http',
                type => 'git',
            },
            bugtracker => {
                 mailto => 'bug-Net-HTTP@rt.cpan.org',
                 web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Net-HTTP',
            },
            x_MailingList => 'mailto:libwww@perl.org',
            x_IRC => 'irc://irc.perl.org/#lwp',
        },
    },
);

WriteMakefile(
    %WriteMakefileArgs,
);

# pod2text is in https://metacpan.org/release/podlators
system("pod2text $WriteMakefileArgs{VERSION_FROM} > README")
     if $developer
        and (not -e 'README' or (stat('README'))[9] < (stat($WriteMakefileArgs{VERSION_FROM}))[9]);

# pod2markdown is in https://metacpan.org/release/Pod-Markdown
system("pod2markdown $WriteMakefileArgs{VERSION_FROM} > README.md")
    if $developer
        and (not -e 'README.md' or (stat('README.md'))[9] < (stat($WriteMakefileArgs{VERSION_FROM}))[9]);



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
