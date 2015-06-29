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
ExtUtils::MakeMaker->VERSION(6.98) if $developer;

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

my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;

for (qw(configure build test runtime)) {
    my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
    next unless exists $WriteMakefileArgs{META_ADD}{prereqs}{$_}
             or exists $WriteMakefileArgs{$key};
    my $r = $WriteMakefileArgs{$key} = {
        %{$WriteMakefileArgs{META_ADD}{prereqs}{$_}{requires} || {}},
        %{delete $WriteMakefileArgs{$key} || {}},
    };
    defined $r->{$_} or delete $r->{$_} for keys %$r;
}

# dynamic prereqs get added here.

$WriteMakefileArgs{MIN_PERL_VERSION} = delete $WriteMakefileArgs{PREREQ_PM}{perl} || 0;

die 'attention developer: you need to do a sane meta merge here!'
    if keys %{$WriteMakefileArgs{BUILD_REQUIRES}};

$WriteMakefileArgs{BUILD_REQUIRES} = {
    %{$WriteMakefileArgs{BUILD_REQUIRES} || {}},
    %{delete $WriteMakefileArgs{TEST_REQUIRES}}
} if $eumm_version < 6.63_03;

$WriteMakefileArgs{PREREQ_PM} = {
    %{$WriteMakefileArgs{PREREQ_PM}},
    %{delete $WriteMakefileArgs{BUILD_REQUIRES}}
} if $eumm_version < 6.55_01;

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
    if $eumm_version < 6.51_03;

delete $WriteMakefileArgs{MIN_PERL_VERSION}
    if $eumm_version < 6.48;

delete @WriteMakefileArgs{qw(META_ADD META_MERGE)}
    if $eumm_version < 6.46;

delete $WriteMakefileArgs{LICENSE}
    if $eumm_version < 6.31;

WriteMakefile(%WriteMakefileArgs);

# pod2text is in https://metacpan.org/release/podlators
system("pod2text $WriteMakefileArgs{VERSION_FROM} > README")
     if $developer
        and (not -e 'README' or (stat('README'))[9] < (stat($WriteMakefileArgs{VERSION_FROM}))[9]);

# pod2markdown is in https://metacpan.org/release/Pod-Markdown
system("pod2markdown $WriteMakefileArgs{VERSION_FROM} > README.md")
    if $developer
        and (not -e 'README.md' or (stat('README.md'))[9] < (stat($WriteMakefileArgs{VERSION_FROM}))[9]);
